use std::str::FromStr;
use std::time::{SystemTime, UNIX_EPOCH};

use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{aliases::U160, aliases::U24, Address as AlloyAddress, U256};
use zilpay::alloy::sol_types::SolCall;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::network::tron::TronOperations;
use zilpay::proto::address::Address;
use zilpay::proto::tron_tx::TronTransaction;
use zilpay::proto::tx::{TransactionMetadata, TransactionRequest};

use super::abi::{swapExactInputCall, swapExactInputSingleCall, IERC20, IWTRX};
use super::math::amount_out_min;
use super::{QuoteBlob, RouteKind, SunConfig};
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::models::transactions::transaction_metadata::TransactionMetadataInfo;
use crate::models::transactions::tron::TransactionRequestTron;
use crate::utils::errors::ServiceError;
use crate::utils::helpers::with_service;

const DEADLINE_WINDOW_SECS: u64 = 20 * 60;

/// TRC20 allowances are standard `uint256` (no Zilliqa u128 cap).
const MAX_ALLOWANCE: U256 = U256::MAX;

fn decode_erc20_allowance(data: &[u8]) -> Option<U256> {
    IERC20::allowanceCall::abi_decode_returns(data).ok()
}

#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub(super) fn encode_swap_v3(
    token_in: AlloyAddress,
    token_out: AlloyAddress,
    fee_tier: u32,
    amount_in: U256,
    amount_out_min: U256,
    deadline: u64,
    native_in: bool,
    native_out: bool,
) -> Vec<u8> {
    swapExactInputSingleCall {
        tokenIn: token_in,
        tokenOut: token_out,
        fee: U24::from(fee_tier),
        amountIn: amount_in,
        amountOutMin: amount_out_min,
        sqrtPriceLimitX96: U160::ZERO,
        deadline: U256::from(deadline),
        nativeIn: native_in,
        nativeOut: native_out,
    }
    .abi_encode()
}

#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub(super) fn encode_swap_v3_path(
    path: &[u8],
    token_in: AlloyAddress,
    token_out: AlloyAddress,
    amount_in: U256,
    amount_out_min: U256,
    deadline: u64,
    native_in: bool,
    native_out: bool,
) -> Vec<u8> {
    swapExactInputCall {
        path: path.to_vec().into(),
        tokenIn: token_in,
        tokenOut: token_out,
        amountIn: amount_in,
        amountOutMin: amount_out_min,
        deadline: U256::from(deadline),
        nativeIn: native_in,
        nativeOut: native_out,
    }
    .abi_encode()
}

fn encode_route_calldata(
    route: &RouteKind,
    amount_in: U256,
    amount_out: U256,
    slippage_bps: u32,
    deadline: u64,
    native_in: bool,
    native_out: bool,
) -> Result<Vec<u8>, String> {
    let min_out = amount_out_min(amount_out, slippage_bps);
    if cfg!(debug_assertions) {
        eprintln!(
            "[sunswap-finalize] route={route:?} amount_in={amount_in} amount_out={amount_out} \
             min_out={min_out} slippage_bps={slippage_bps} deadline={deadline} \
             native_in={native_in} native_out={native_out}"
        );
    }
    match route {
        RouteKind::V3 {
            token_in,
            token_out,
            fee_tier,
        } => {
            let token_in_addr = AlloyAddress::from_str(token_in).map_err(|e| e.to_string())?;
            let token_out_addr = AlloyAddress::from_str(token_out).map_err(|e| e.to_string())?;
            Ok(encode_swap_v3(
                token_in_addr,
                token_out_addr,
                *fee_tier,
                amount_in,
                min_out,
                deadline,
                native_in,
                native_out,
            ))
        }
        RouteKind::V3Path { path } => {
            let hex_path = path.strip_prefix("0x").unwrap_or(path);
            let packed = hex::decode(hex_path).map_err(|e| e.to_string())?;
            let token_in = packed
                .get(..20)
                .map(AlloyAddress::from_slice)
                .ok_or_else(|| "v3 path too short for token_in".to_string())?;
            let out_start = packed
                .len()
                .checked_sub(20)
                .ok_or_else(|| "v3 path too short for token_out".to_string())?;
            let token_out = packed
                .get(out_start..)
                .map(AlloyAddress::from_slice)
                .ok_or_else(|| "v3 path too short for token_out".to_string())?;
            Ok(encode_swap_v3_path(
                &packed, token_in, token_out, amount_in, min_out, deadline, native_in, native_out,
            ))
        }
        RouteKind::Wrap => Err("wrap route has no fee-router calldata".to_string()),
    }
}

fn deadline_timestamp() -> Result<u64, String> {
    Ok(SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|e| e.to_string())?
        .as_secs()
        .saturating_add(DEADLINE_WINDOW_SECS))
}

fn parse_tron_call_value(value: U256) -> Result<i64, String> {
    value
        .try_into()
        .map_err(|_| format!("native TRX amount {value} exceeds i64 range"))
}

/// Build a TRON `TriggerSmartContract` against `contract`, fill its block ref,
/// estimate energy/bandwidth, and set the fee limit. The single shared TRON
/// tx-build pipeline for SunFeeRouter swaps, WTRX wrap/unwrap, and approvals.
async fn build_trigger_request(
    chain_hash: u64,
    owner: &Address,
    contract: &Address,
    call_value: i64,
    data: Vec<u8>,
) -> Result<TransactionRequest, String> {
    let provider = with_service(|core| {
        core.get_provider(chain_hash).map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(|e: ServiceError| e.to_string())?;

    let mut tron_tx = TronTransaction::builder()
        .ref_block(Vec::new(), Vec::new())
        .expiration(0)
        .timestamp(0)
        .fee_limit(0)
        .trigger_smart_contract(owner, contract, call_value, data, 0, 0)
        .build()
        .map_err(|e| e.to_string())?;
    provider
        .tron_fill_block_ref(&mut tron_tx)
        .await
        .map_err(|e| e.to_string())?;

    let mut req = TransactionRequest::Tron((tron_tx, TransactionMetadata::default()));
    let params = provider
        .tron_estimate_params_batch(&req, owner)
        .await
        .map_err(|e| e.to_string())?;

    let TransactionRequest::Tron((ref mut tron_tx, _)) = req else {
        return Err("internal: unexpected transaction variant".to_string());
    };
    let fee_limit_sun: i64 = params
        .current
        .try_into()
        .map_err(|_| format!("Tron fee estimate {} exceeds i64 range", params.current))?;
    tron_tx.set_fee_limit(fee_limit_sun);

    Ok(req)
}

fn lift_with_metadata(
    tx: TransactionRequest,
    chain_hash: u64,
    title: Option<String>,
    info: Option<String>,
    icon: Option<String>,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let TransactionRequest::Tron((tron_tx, _)) = tx else {
        return Err("expected Tron tx".to_string());
    };
    let tron_web = tron_tx.to_tron_web().map_err(|e| e.to_string())?;
    let tron_info = TransactionRequestTron::from(tron_web);

    Ok(TransactionRequestInfo {
        metadata: TransactionMetadataInfo {
            chain_hash,
            hash: None,
            info,
            icon,
            title,
            signer: None,
            token_info: out_token,
            broadcast: true,
        },
        scilla: None,
        evm: None,
        btc: None,
        tron: Some(tron_info),
        solana: None,
    })
}

/// Build the `SunFeeRouter` swap as a TRON `TriggerSmartContract`.
async fn build_fee_router_tx(
    cfg: &SunConfig,
    owner_tron: &Address,
    chain_hash: u64,
    blob: &QuoteBlob,
    deadline: u64,
) -> Result<TransactionRequest, String> {
    let amount_in = U256::from_str(&blob.amount_in).map_err(|e| e.to_string())?;
    let amount_out = U256::from_str(&blob.amount_out).map_err(|e| e.to_string())?;
    let data = encode_route_calldata(
        &blob.route,
        amount_in,
        amount_out,
        blob.slippage_bps,
        deadline,
        blob.is_native_in,
        blob.is_native_out,
    )?;
    let call_value = if blob.is_native_in {
        parse_tron_call_value(amount_in)?
    } else {
        0
    };
    build_trigger_request(
        chain_hash,
        owner_tron,
        &cfg.addrs.fee_router,
        call_value,
        data,
    )
    .await
}

/// Wrap/unwrap TRX↔WTRX via `IWTRX.deposit()/withdraw()`.
async fn build_wrap_tx(
    cfg: &SunConfig,
    owner_tron: &Address,
    chain_hash: u64,
    amount: &str,
    is_native_in: bool,
) -> Result<TransactionRequest, String> {
    let amount_in = U256::from_str(amount).map_err(|e| e.to_string())?;
    let (data, call_value) = if is_native_in {
        (IWTRX::depositCall {}.abi_encode(), parse_tron_call_value(amount_in)?)
    } else {
        (IWTRX::withdrawCall { amount: amount_in }.abi_encode(), 0)
    };
    build_trigger_request(chain_hash, owner_tron, &cfg.addrs.wtrx, call_value, data).await
}

#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub(super) async fn build_finalized_swap(
    cfg: &SunConfig,
    blob: &QuoteBlob,
    chain_hash: u64,
    swapper_tron: &Address,
    title: String,
    info: String,
    icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let tx = match &blob.route {
        RouteKind::Wrap => {
            build_wrap_tx(
                cfg,
                swapper_tron,
                chain_hash,
                &blob.amount_in,
                blob.is_native_in,
            )
            .await?
        }
        RouteKind::V3 { .. } | RouteKind::V3Path { .. } => {
            build_fee_router_tx(cfg, swapper_tron, chain_hash, blob, deadline_timestamp()?).await?
        }
    };

    lift_with_metadata(
        tx,
        chain_hash,
        Some(title),
        Some(info),
        Some(icon),
        out_token,
    )
}

#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub(super) async fn build_approval_if_needed(
    cfg: &SunConfig,
    owner_tron: &Address,
    chain_hash: u64,
    token: &str,
    amount: &str,
    approve_title: String,
    provider_icon: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    let token_tron = Address::from_str_hex(token).map_err(|e| e.to_string())?;
    let call = IERC20::allowanceCall {
        owner: owner_tron.to_alloy_addr(),
        spender: cfg.addrs.fee_router.to_alloy_addr(),
    }
    .abi_encode();

    let provider = with_service(|core| {
        core.get_provider(chain_hash).map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(|e: ServiceError| e.to_string())?;

    let raw = provider
        .tron_constant_call(owner_tron, &token_tron, call)
        .await
        .map_err(|e| e.to_string())?;
    let current = decode_erc20_allowance(&raw).unwrap_or(U256::ZERO);
    let needed = U256::from_str(amount).map_err(|e| e.to_string())?;
    if current >= needed {
        if cfg!(debug_assertions) {
            eprintln!("[sunswap-approve] allowance already sufficient, skipping");
        }
        return Ok(None);
    }

    if cfg!(debug_assertions) {
        eprintln!(
            "[sunswap-approve] token={token} spender={} owner={} current_allowance={current} \
             needed={needed} approve_amount={MAX_ALLOWANCE}",
            cfg.addrs.fee_router.auto_format(),
            owner_tron.auto_format(),
        );
    }

    let data = IERC20::approveCall {
        spender: cfg.addrs.fee_router.to_alloy_addr(),
        amount: MAX_ALLOWANCE,
    }
    .abi_encode();

    let req = build_trigger_request(chain_hash, owner_tron, &token_tron, 0, data).await?;
    lift_with_metadata(req, chain_hash, Some(approve_title), None, Some(provider_icon), None)
        .map(Some)
}

#[cfg(test)]
mod tests {
    use super::*;
    use zilpay::alloy::sol_types::SolCall;

    fn addr(byte: u8) -> AlloyAddress {
        AlloyAddress::from([byte; 20])
    }

    #[test]
    fn swap_v3_calldata_selector_and_args() -> Result<(), String> {
        let data = encode_swap_v3(
            addr(0x11),
            addr(0x22),
            2_500,
            U256::from(1_000u64),
            U256::from(900u64),
            456,
            false,
            true,
        );
        assert_eq!(
            data.get(..4),
            Some(swapExactInputSingleCall::SELECTOR.as_slice())
        );
        let decoded = swapExactInputSingleCall::abi_decode(&data).map_err(|e| e.to_string())?;
        assert_eq!(decoded.fee, U24::from(2_500u64));
        assert_eq!(decoded.amountIn, U256::from(1_000u64));
        assert_eq!(decoded.amountOutMin, U256::from(900u64));
        assert_eq!(decoded.deadline, U256::from(456u64));
        assert!(!decoded.nativeIn);
        assert!(decoded.nativeOut);
        Ok(())
    }

    #[test]
    fn swap_v3_path_calldata_selector_and_args() -> Result<(), String> {
        let mut packed = Vec::with_capacity(66);
        packed.extend_from_slice(addr(0x11).as_slice());
        packed.extend_from_slice(&500u32.to_be_bytes()[1..]);
        packed.extend_from_slice(addr(0x55).as_slice());
        packed.extend_from_slice(&3_000u32.to_be_bytes()[1..]);
        packed.extend_from_slice(addr(0x22).as_slice());

        let data = encode_swap_v3_path(
            &packed,
            addr(0x11),
            addr(0x22),
            U256::from(1_000u64),
            U256::from(900u64),
            789,
            true,
            false,
        );
        assert_eq!(data.get(..4), Some(swapExactInputCall::SELECTOR.as_slice()));
        let decoded = swapExactInputCall::abi_decode(&data).map_err(|e| e.to_string())?;
        assert_eq!(decoded.tokenIn, addr(0x11));
        assert_eq!(decoded.tokenOut, addr(0x22));
        assert_eq!(decoded.amountIn, U256::from(1_000u64));
        assert_eq!(decoded.amountOutMin, U256::from(900u64));
        assert_eq!(decoded.deadline, U256::from(789u64));
        assert!(decoded.nativeIn);
        assert!(!decoded.nativeOut);
        assert_eq!(decoded.path.as_ref(), &packed);
        Ok(())
    }

    #[test]
    fn encode_route_calldata_v3path_derives_endpoints() -> Result<(), String> {
        let mut packed = Vec::with_capacity(66);
        packed.extend_from_slice(addr(0x11).as_slice());
        packed.extend_from_slice(&500u32.to_be_bytes()[1..]);
        packed.extend_from_slice(addr(0x55).as_slice());
        packed.extend_from_slice(&3_000u32.to_be_bytes()[1..]);
        packed.extend_from_slice(addr(0x22).as_slice());
        let route = RouteKind::V3Path {
            path: hex::encode_prefixed(&packed),
        };
        let data = encode_route_calldata(
            &route,
            U256::from(1_000u64),
            U256::from(900u64),
            50,
            123,
            false,
            false,
        )?;
        let decoded = swapExactInputCall::abi_decode(&data).map_err(|e| e.to_string())?;
        assert_eq!(decoded.tokenIn, addr(0x11));
        assert_eq!(decoded.tokenOut, addr(0x22));
        assert_eq!(decoded.path.as_ref(), &packed);
        Ok(())
    }
}
