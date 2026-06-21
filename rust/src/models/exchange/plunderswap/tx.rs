use std::str::FromStr;
use std::time::{SystemTime, UNIX_EPOCH};

use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{aliases::U160, aliases::U24, Address, U256};
use zilpay::alloy::sol_types::SolCall;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::crypto::slip44;
use zilpay::proto::tx::{ETHTransactionRequest, TransactionMetadata, TransactionRequest};
use zilpay::proto::AlloyTxKind;
use zilpay::rpc::{
    common::JsonRPC, methods::EvmMethods, network_config::ChainConfig, provider::RpcProvider,
    zil_interfaces::ResultRes,
};
use zilpay::serde_json::{json, Value};

use super::abi::{swapV2Call, swapV3ExactInputCall, swapV3ExactInputSingleCall, IERC20, IWZIL};
use super::math::amount_out_min;
use super::{PlunderConfig, QuoteBlob, RouteKind, APPROVE_GAS, SWAP_GAS};
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::utils::errors::ServiceError;
use crate::utils::helpers::with_service;

const DEADLINE_WINDOW_SECS: u64 = 20 * 60;

/// Max "infinite" approval per chain family. Zilliqa-bridged tokens (zUSDT/zUSDC) store
/// allowances as `uint128` and revert on any value above `u128::MAX`; other EVM chains
/// accept `U256::MAX`.
const fn max_approval_amount(coin_type: u32) -> U256 {
    match coin_type {
        slip44::ZILLIQA => U256::from_limbs([u64::MAX, u64::MAX, 0, 0]), // u128::MAX = 2^128 - 1
        _ => U256::MAX,
    }
}

fn decode_erc20_allowance(data: &[u8]) -> Option<U256> {
    IERC20::allowanceCall::abi_decode_returns(data).ok()
}

fn parse_route_path(path: &[String]) -> Result<Vec<Address>, String> {
    path.iter()
        .map(|item| Address::from_str(item).map_err(|e| e.to_string()))
        .collect()
}

#[frb(ignore)]
pub(super) fn encode_swap_v2(
    amount_in: U256,
    amount_out_min: U256,
    path: Vec<Address>,
    deadline: u64,
    native_in: bool,
    native_out: bool,
) -> Vec<u8> {
    swapV2Call {
        amountIn: amount_in,
        amountOutMin: amount_out_min,
        path,
        deadline: U256::from(deadline),
        nativeIn: native_in,
        nativeOut: native_out,
        supportingFeeOnTransfer: false,
    }
    .abi_encode()
}

#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub(super) fn encode_swap_v3(
    token_in: Address,
    token_out: Address,
    fee_tier: u32,
    amount_in: U256,
    amount_out_min: U256,
    deadline: u64,
    native_in: bool,
    native_out: bool,
) -> Vec<u8> {
    swapV3ExactInputSingleCall {
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
    token_in: Address,
    token_out: Address,
    amount_in: U256,
    amount_out_min: U256,
    deadline: u64,
    native_in: bool,
    native_out: bool,
) -> Vec<u8> {
    swapV3ExactInputCall {
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
    eprintln!(
        "[plunderswap-finalize] route={route:?} amount_in={amount_in} amount_out={amount_out} \
         min_out={min_out} slippage_bps={slippage_bps} deadline={deadline} \
         native_in={native_in} native_out={native_out}"
    );
    match route {
        RouteKind::V2 { path } => Ok(encode_swap_v2(
            amount_in,
            min_out,
            parse_route_path(path)?,
            deadline,
            native_in,
            native_out,
        )),
        RouteKind::V3 {
            token_in,
            token_out,
            fee_tier,
        } => {
            let token_in_addr = Address::from_str(token_in).map_err(|e| e.to_string())?;
            let token_out_addr = Address::from_str(token_out).map_err(|e| e.to_string())?;
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
            // Packed path: addr(20) ‖ fee(3) ‖ … ‖ addr(20). The first/last 20
            // bytes are the endpoints the fee-router's `_prepareV3Input` needs
            // for pull/approve/wrap assertions (nativeIn → tokenIn==WZIL, etc).
            let token_in = packed
                .get(..20)
                .map(Address::from_slice)
                .ok_or_else(|| "v3 path too short for token_in".to_string())?;
            let out_start = packed
                .len()
                .checked_sub(20)
                .ok_or_else(|| "v3 path too short for token_out".to_string())?;
            let token_out = packed
                .get(out_start..)
                .map(Address::from_slice)
                .ok_or_else(|| "v3 path too short for token_out".to_string())?;
            Ok(encode_swap_v3_path(
                &packed, token_in, token_out, amount_in, min_out, deadline, native_in, native_out,
            ))
        }
        RouteKind::Wrap { .. } => Err("wrap route has no fee-router calldata".to_string()),
    }
}

fn build_fee_router_tx(
    fee_router: Address,
    chain_id: u64,
    chain_hash: u64,
    from: Address,
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
    let value = if blob.is_native_in {
        amount_in
    } else {
        U256::ZERO
    };

    let mut tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(fee_router)),
        from: Some(from),
        value: Some(value),
        input: data.into(),
        gas: Some(SWAP_GAS),
        ..Default::default()
    };
    tx.chain_id = Some(chain_id);

    Ok(TransactionRequest::Ethereum((
        tx,
        TransactionMetadata {
            chain_hash,
            broadcast: true,
            ..Default::default()
        },
    )))
}

fn build_wrap_tx(
    wzil: Address,
    chain_id: u64,
    chain_hash: u64,
    from: Address,
    amount: &str,
    is_native_in: bool,
) -> Result<TransactionRequest, String> {
    let amount_in = U256::from_str(amount).map_err(|e| e.to_string())?;
    let (data, value) = if is_native_in {
        (IWZIL::depositCall {}.abi_encode(), amount_in)
    } else {
        (
            IWZIL::withdrawCall { amount: amount_in }.abi_encode(),
            U256::ZERO,
        )
    };

    let mut tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(wzil)),
        from: Some(from),
        value: Some(value),
        input: data.into(),
        gas: Some(APPROVE_GAS),
        ..Default::default()
    };
    tx.chain_id = Some(chain_id);

    Ok(TransactionRequest::Ethereum((
        tx,
        TransactionMetadata {
            chain_hash,
            broadcast: true,
            ..Default::default()
        },
    )))
}

fn deadline_timestamp() -> Result<u64, String> {
    Ok(SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|e| e.to_string())?
        .as_secs()
        .saturating_add(DEADLINE_WINDOW_SECS))
}

fn lift_with_metadata(
    tx: TransactionRequest,
    chain_hash: u64,
    title: String,
    info: String,
    icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let TransactionRequest::Ethereum((eth_tx, _)) = tx else {
        return Err("expected Ethereum tx".to_string());
    };
    let token_info = out_token.map(|token| {
        let value = U256::from_str(&token.value).unwrap_or(U256::ZERO);
        (value, token.decimals, token.symbol)
    });

    TransactionRequest::Ethereum((
        eth_tx,
        TransactionMetadata {
            chain_hash,
            broadcast: true,
            title: Some(title),
            info: Some(info),
            icon: Some(icon),
            token_info,
            ..Default::default()
        },
    ))
    .try_into()
    .map_err(|e: zilpay::errors::tx::TransactionErrors| e.to_string())
}

#[frb(ignore)]
pub(super) fn build_finalized_swap(
    blob: &QuoteBlob,
    chain_hash: u64,
    swapper: Address,
    title: String,
    info: String,
    icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let tx = match &blob.route {
        RouteKind::Wrap { token } => build_wrap_tx(
            Address::from_str(token).map_err(|e| e.to_string())?,
            blob.chain_id,
            chain_hash,
            swapper,
            &blob.amount_in,
            blob.is_native_in,
        )?,
        RouteKind::V2 { .. } | RouteKind::V3 { .. } | RouteKind::V3Path { .. } => {
            build_fee_router_tx(
                Address::from_str(&blob.fee_router).map_err(|e| e.to_string())?,
                blob.chain_id,
                chain_hash,
                swapper,
                blob,
                deadline_timestamp()?,
            )?
        }
    };

    lift_with_metadata(tx, chain_hash, title, info, icon, out_token)
}

#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub(super) async fn build_approval_if_needed(
    cfg: &PlunderConfig,
    owner: Address,
    chain_hash: u64,
    slip44: u32,
    token: &str,
    amount: &str,
    approve_title: String,
    provider_icon: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    let chain_config = with_service(|core| {
        Ok(core
            .get_provider(chain_hash)
            .map_err(ServiceError::BackgroundError)?
            .config
            .clone())
    })
    .await
    .map_err(|e: ServiceError| e.to_string())?;

    let token_addr = Address::from_str(token).map_err(|e| e.to_string())?;
    let call = IERC20::allowanceCall {
        owner,
        spender: cfg.addrs.fee_router,
    }
    .abi_encode();

    let payload = RpcProvider::<ChainConfig>::build_payload(
        json!([{ "to": token_addr.to_string(), "data": hex::encode_prefixed(&call) }, "latest"]),
        EvmMethods::Call,
    );

    let provider: RpcProvider<ChainConfig> = RpcProvider::new(&chain_config);
    let res = provider
        .req::<ResultRes<Value>>(payload)
        .await
        .map_err(|e| e.to_string())?;

    let current = res
        .result
        .as_ref()
        .and_then(|value| value.as_str())
        .and_then(|hex_value| hex::decode(hex_value).ok())
        .and_then(|bytes| decode_erc20_allowance(&bytes))
        .unwrap_or(U256::ZERO);
    let needed = U256::from_str(amount).map_err(|e| e.to_string())?;
    if current >= needed {
        eprintln!("[plunderswap-approve] allowance already sufficient, skipping");
        return Ok(None);
    }

    let approve_amount = max_approval_amount(slip44);
    eprintln!(
        "[plunderswap-approve] token={token} spender={} owner={owner} slip44={slip44} \
         current_allowance={current} needed={needed} approve_amount={approve_amount}",
        cfg.addrs.fee_router,
    );
    let data = IERC20::approveCall {
        spender: cfg.addrs.fee_router,
        amount: approve_amount,
    }
    .abi_encode();
    let mut tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(token_addr)),
        from: Some(owner),
        value: Some(U256::ZERO),
        input: data.into(),
        gas: Some(APPROVE_GAS),
        ..Default::default()
    };
    tx.chain_id = Some(cfg.addrs.chain_id);

    Ok(Some(
        TransactionRequest::Ethereum((
            tx,
            TransactionMetadata {
                chain_hash,
                broadcast: true,
                title: Some(approve_title),
                icon: Some(provider_icon),
                ..Default::default()
            },
        ))
        .try_into()
        .map_err(|e: zilpay::errors::tx::TransactionErrors| e.to_string())?,
    ))
}

#[cfg(test)]
mod tests {
    use super::*;
    use zilpay::alloy::sol_types::SolCall;

    fn addr(byte: u8) -> Address {
        Address::from([byte; 20])
    }

    #[test]
    fn swap_v2_calldata_selector_and_args() -> Result<(), String> {
        let path = vec![addr(0x11), addr(0x22)];
        let data = encode_swap_v2(
            U256::from(1_000u64),
            U256::from(900u64),
            path.clone(),
            123,
            true,
            false,
        );
        assert_eq!(data.get(..4), Some(swapV2Call::SELECTOR.as_slice()));
        let decoded = swapV2Call::abi_decode(&data).map_err(|e| e.to_string())?;
        assert_eq!(decoded.amountIn, U256::from(1_000u64));
        assert_eq!(decoded.amountOutMin, U256::from(900u64));
        assert_eq!(decoded.path, path);
        assert_eq!(decoded.deadline, U256::from(123u64));
        assert!(decoded.nativeIn);
        assert!(!decoded.nativeOut);
        assert!(!decoded.supportingFeeOnTransfer);
        Ok(())
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
            Some(swapV3ExactInputSingleCall::SELECTOR.as_slice())
        );
        let decoded = swapV3ExactInputSingleCall::abi_decode(&data).map_err(|e| e.to_string())?;
        assert_eq!(decoded.fee, U24::from(2_500u64));
        assert_eq!(decoded.amountIn, U256::from(1_000u64));
        assert_eq!(decoded.amountOutMin, U256::from(900u64));
        assert_eq!(decoded.deadline, U256::from(456u64));
        assert!(!decoded.nativeIn);
        assert!(decoded.nativeOut);
        Ok(())
    }

    #[test]
    fn wrap_tx_encodes_deposit_with_value() -> Result<(), String> {
        let tx = build_wrap_tx(addr(0x94), 32_769, 42, addr(0xaa), "1000", true)?;
        let TransactionRequest::Ethereum((eth, _)) = tx else {
            return Err("expected ethereum tx".to_string());
        };
        let data = eth
            .input
            .input
            .ok_or_else(|| "missing calldata".to_string())?;
        assert_eq!(eth.value, Some(U256::from(1_000u64)));
        assert_eq!(data.get(..4), Some(IWZIL::depositCall::SELECTOR.as_slice()));
        Ok(())
    }

    #[test]
    fn wrap_tx_encodes_withdraw_zero_value() -> Result<(), String> {
        let tx = build_wrap_tx(addr(0x94), 32_769, 42, addr(0xaa), "1000", false)?;
        let TransactionRequest::Ethereum((eth, _)) = tx else {
            return Err("expected ethereum tx".to_string());
        };
        let data = eth
            .input
            .input
            .ok_or_else(|| "missing calldata".to_string())?;
        assert_eq!(eth.value, Some(U256::ZERO));
        assert_eq!(
            data.get(..4),
            Some(IWZIL::withdrawCall::SELECTOR.as_slice())
        );
        let decoded = IWZIL::withdrawCall::abi_decode(&data).map_err(|e| e.to_string())?;
        assert_eq!(decoded.amount, U256::from(1_000u64));
        Ok(())
    }

    #[test]
    fn swap_v3_path_calldata_selector_and_args() -> Result<(), String> {
        // Packed 2-hop V3 path: addr ‖ fee ‖ addr ‖ fee ‖ addr (66 bytes).
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
        assert_eq!(
            data.get(..4),
            Some(swapV3ExactInputCall::SELECTOR.as_slice())
        );
        let decoded = swapV3ExactInputCall::abi_decode(&data).map_err(|e| e.to_string())?;
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
        // Packed path: addr(0x11) ‖ fee(500) ‖ addr(0x55) ‖ fee(3000) ‖ addr(0x22).
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
        let decoded = swapV3ExactInputCall::abi_decode(&data).map_err(|e| e.to_string())?;
        // Endpoints derived from the packed path's first/last 20 bytes.
        assert_eq!(decoded.tokenIn, addr(0x11));
        assert_eq!(decoded.tokenOut, addr(0x22));
        assert_eq!(decoded.path.as_ref(), &packed);
        Ok(())
    }

    #[test]
    fn max_approval_amount_caps_zilliqa_at_u128() {
        assert_eq!(max_approval_amount(slip44::ZILLIQA), U256::from(u128::MAX));
        assert_eq!(max_approval_amount(slip44::ETHEREUM), U256::MAX);
    }
}
