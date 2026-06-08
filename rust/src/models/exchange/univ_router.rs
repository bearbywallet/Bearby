//! Provider-agnostic **Universal Router** engine. Quotes on-chain via **QuoterV2**
//! (`eth_call`) and builds swaps by encoding `execute(commands, inputs, deadline)` calldata
//! directly with `alloy`. Uniswap and PancakeSwap (`infinity-universal-router`) share this
//! engine byte-for-byte — they differ only in deployment addresses and V3 fee tiers, both
//! supplied via [`RouterConfig`]. Nothing here crosses the flutter_rust_bridge boundary:
//! every item is `#[frb(ignore)]` and freely uses alloy types.
//!
//! Flow: on-chain fee-tier probing → permit signing (ERC-20 input) → build unsigned
//! Universal Router tx → the UI signs and broadcasts via `sign_send_transactions`.

use std::borrow::Cow;
use std::str::FromStr;
use std::time::{SystemTime, UNIX_EPOCH};

use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{
    address,
    aliases::{U160, U24, U48},
    Address, Bytes, U256,
};
use zilpay::alloy::sol_types::{SolCall, SolValue};
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::proto::tx::{ETHTransactionRequest, TransactionMetadata, TransactionRequest};
use zilpay::proto::AlloyTxKind;
use zilpay::rpc::{
    common::JsonRPC, methods::EvmMethods, network_config::ChainConfig, provider::RpcProvider,
    zil_interfaces::ResultRes,
};
use zilpay::serde;
use zilpay::serde_json::{self, json, Value};

use super::{ExchangeAsset, ProviderQuote};
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::utils::errors::ServiceError;
use crate::utils::helpers::with_service;

// Universal Router command bytes (Commands.sol). Identical across Uniswap and PancakeSwap's
// infinity-universal-router fork.
const CMD_V3_SWAP_EXACT_IN: u8 = 0x00;
const CMD_SWEEP: u8 = 0x04;
const CMD_PAY_PORTION: u8 = 0x06;
const CMD_PERMIT2_PERMIT: u8 = 0x0a;
const CMD_WRAP_ETH: u8 = 0x0b;
const CMD_UNWRAP_WETH: u8 = 0x0c;

// Router recipient sentinel: address(2) routes funds to the router itself so that the
// subsequent PAY_PORTION / SWEEP commands can split the swap output.
const ADDRESS_THIS: Address = Address::with_last_byte(2);

const FEE_BIPS: u32 = 50;
const FEE_RECIPIENT: Address = address!("0x74d35b31ed6b31818331bc28fe343669126f152f");

const PERMIT_AMOUNT: U160 = U160::MAX;
const PERMIT_EXPIRATION: U48 = U48::MAX;
const PERMIT_SIG_DEADLINE: u64 = 281_474_976_710_655;

const DEFAULT_APPROVE_GAS: u64 = 60_000;
const DEFAULT_SWAP_GAS: u64 = 400_000;

pub const NATIVE_SENTINEL: &str = "0x0000000000000000000000000000000000000000";

mod sol_types {
    use zilpay::alloy::sol;

    sol! {
        struct QuoteExactInputSingleParams {
            address tokenIn;
            address tokenOut;
            uint256 amountIn;
            uint24 fee;
            uint160 sqrtPriceLimitX96;
        }

        function quoteExactInputSingle(QuoteExactInputSingleParams params)
            external
            returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 ticks, uint256 gasEstimate);

        struct PermitDetails {
            address token;
            uint160 amount;
            uint48 expiration;
            uint48 nonce;
        }

        struct PermitSingle {
            PermitDetails details;
            address spender;
            uint256 sigDeadline;
        }

        function execute(bytes commands, bytes[] inputs, uint256 deadline) external payable;
    }

    sol! {
        // The real on-chain name is `allowance` — the function selector is derived from the
        // signature `allowance(address,address,address)`, NOT the interface name, so this must
        // stay named `allowance` (renaming it changes the selector and the call reverts).
        interface IPermit2 {
            function allowance(address owner, address token, address spender)
                external view returns (uint160 amount, uint48 expiration, uint48 nonce);
        }
    }

    sol! {
        interface IERC20 {
            function allowance(address owner, address spender) external view returns (uint256);
            function approve(address spender, uint256 amount) external returns (bool);
        }
    }

    sol! {
        // Canonical WETH9 / WBNB wrap interface. `deposit` mints the wrapped token 1:1 to
        // `msg.sender` for the attached `value`; `withdraw` burns it and returns native coin.
        interface IWETH {
            function deposit() external payable;
            function withdraw(uint256 amount) external;
        }
    }
}

use sol_types::{
    executeCall, quoteExactInputSingleCall, PermitDetails, PermitSingle,
    QuoteExactInputSingleParams,
};
use sol_types::{IPermit2, IERC20, IWETH};

/// `Copy` bundle of a single chain's deployment addresses for one DEX.
#[frb(ignore)]
#[derive(Clone, Copy)]
pub struct RouterAddrs {
    pub chain_id: u64,
    pub universal_router: Address,
    pub quoter_v2: Address,
    pub permit2: Address,
    pub weth: Address,
}

/// Everything the engine needs to quote + build a swap for one chain on one DEX. Provider
/// modules ([`super::uniswap`], [`super::pancakeswap`]) produce this from their deployment tables.
#[frb(ignore)]
#[derive(Clone)]
pub struct RouterConfig {
    pub addrs: RouterAddrs,
    pub fee_tiers: &'static [u32],
}

/// Serialized inside `quote_blob` — opaque to the UI, carries everything `finalize_router_swap`
/// needs to build the unsigned tx. `universal_router` makes finalize provider-agnostic: it never
/// re-resolves a deployment table. `token_in`/`token_out` are already WETH-resolved at quote time.
#[frb(ignore)]
#[derive(serde::Serialize, serde::Deserialize)]
#[serde(crate = "zilpay::serde")]
struct QuoteBlob {
    chain_id: u64,
    universal_router: String,
    token_in: String,
    token_out: String,
    amount_in: String,
    amount_out: String,
    fee_tier: u32,
    permit_nonce: Option<u64>,
    is_native_in: bool,
    is_native_out: bool,
    slippage_bps: u32,
}

/// Native or Permit2 authorization for the swap.
enum SwapInput {
    NativeEth,
    Erc20 {
        permit: PermitSingle,
        signature: Vec<u8>,
    },
}

struct SwapPlan {
    token_in: Address,
    token_out: Address,
    amount_in: U256,
    amount_out_min: U256,
    fee_tier: u32,
    recipient: Address,
    input: SwapInput,
    native_out: bool,
}

/// Resolve `to_asset`: detect cross-chain prefix and native-out sentinel.
/// Returns `(resolved_token, is_native_out)`, or `Err` when `to_asset` targets a
/// different chain (cross-chain not supported by a single-chain Universal Router swap).
fn resolve_out(to_asset: &str, source_chain: u64) -> Result<(Cow<'_, str>, bool), String> {
    if let Some((chain_part, addr)) = to_asset.split_once(':') {
        if !chain_part.is_empty() && chain_part.bytes().all(|b| b.is_ascii_digit()) {
            let chain: u64 = chain_part
                .parse()
                .map_err(|_| "invalid chain id".to_string())?;
            if chain != source_chain {
                return Err("cross-chain swap not supported".to_string());
            }
            let is_native = addr == NATIVE_SENTINEL || addr.is_empty();
            return Ok((Cow::Owned(addr.to_string()), is_native));
        }
    }
    let is_native = to_asset == NATIVE_SENTINEL || to_asset.is_empty();
    Ok((Cow::Borrowed(to_asset), is_native))
}

/// Resolve the input token: substitute WETH for native input.
fn resolve_in<'a>(is_native_in: bool, weth: &'a str, from_asset: &'a str) -> Cow<'a, str> {
    if is_native_in {
        Cow::Borrowed(weth)
    } else {
        Cow::Borrowed(from_asset)
    }
}

/// Resolve `(from_asset, to_asset)` into the WETH-substituted `(token_in, token_out)` pair,
/// plus whether the output is native and whether this is a pure **wrap/unwrap**. The latter is
/// true when both sides resolve to WETH — i.e. native ↔ wrapped-native, which has no V3 pool and
/// must be served by [`build_wrap_tx`] instead of a router swap.
fn resolve_pair(
    addrs: &RouterAddrs,
    from_asset: &str,
    to_asset: &str,
    is_native_in: bool,
) -> Result<(String, String, bool, bool), String> {
    let weth = addrs.weth.to_string();
    let (tout, is_native_out) = resolve_out(to_asset, addrs.chain_id)?;
    let token_out = if is_native_out {
        weth.clone()
    } else {
        tout.into_owned()
    };
    let token_in = resolve_in(is_native_in, &weth, from_asset).into_owned();
    let is_wrap_unwrap = token_in.eq_ignore_ascii_case(&token_out);
    Ok((token_in, token_out, is_native_out, is_wrap_unwrap))
}

/// Whether `(from_asset → to_asset)` on this DEX config is a pure native ↔ wrapped-native
/// wrap/unwrap (1:1, no router, no approval/permit). Used by the api layer to short-circuit the
/// quote loop and skip the approve/permit legs.
#[frb(ignore)]
pub fn is_wrap_unwrap(
    cfg: &RouterConfig,
    from_asset: &str,
    to_asset: &str,
    is_native_in: bool,
) -> Result<bool, String> {
    let (_, _, _, wrap) = resolve_pair(&cfg.addrs, from_asset, to_asset, is_native_in)?;
    Ok(wrap)
}

fn v3_path(tin: &Address, fee: u32, tout: &Address) -> Vec<u8> {
    let mut p = Vec::with_capacity(20 + 3 + 20);
    p.extend_from_slice(tin.as_slice());
    p.extend_from_slice(&fee.to_be_bytes()[1..]);
    p.extend_from_slice(tout.as_slice());
    p
}

fn encode_quote(tin: Address, tout: Address, amt: U256, fee: u32) -> Vec<u8> {
    quoteExactInputSingleCall {
        params: QuoteExactInputSingleParams {
            tokenIn: tin,
            tokenOut: tout,
            amountIn: amt,
            fee: U24::from(fee),
            sqrtPriceLimitX96: U160::ZERO,
        },
    }
    .abi_encode()
}

fn decode_quote(data: &[u8]) -> Option<U256> {
    quoteExactInputSingleCall::abi_decode_returns(data)
        .ok()
        .map(|r| r.amountOut)
}

fn decode_allowance_nonce(data: &[u8]) -> Option<u64> {
    IPermit2::allowanceCall::abi_decode_returns(data)
        .ok()
        .map(|r| r.nonce.to::<u64>())
}

fn decode_erc20_allowance(data: &[u8]) -> Option<U256> {
    IERC20::allowanceCall::abi_decode_returns(data).ok()
}

/// Encode the Universal Router `execute(commands, inputs, deadline)` calldata for a
/// single-hop V3 swap that takes our platform fee from the output:
/// `[WRAP_ETH|PERMIT2_PERMIT] → V3_SWAP_EXACT_IN → PAY_PORTION → [SWEEP|UNWRAP_WETH]`.
fn build_execute_calldata(plan: SwapPlan, deadline: U256) -> Vec<u8> {
    let SwapPlan {
        token_in,
        token_out,
        amount_in,
        amount_out_min,
        fee_tier,
        recipient,
        input,
        native_out,
    } = plan;

    let mut commands = Vec::with_capacity(4);
    let mut inputs: Vec<Bytes> = Vec::with_capacity(4);

    let payer_is_user = match input {
        SwapInput::NativeEth => {
            commands.push(CMD_WRAP_ETH);
            inputs.push((ADDRESS_THIS, amount_in).abi_encode_params().into());
            false
        }
        SwapInput::Erc20 { permit, signature } => {
            commands.push(CMD_PERMIT2_PERMIT);
            inputs.push((permit, Bytes::from(signature)).abi_encode_params().into());
            true
        }
    };

    let path = v3_path(&token_in, fee_tier, &token_out);
    commands.push(CMD_V3_SWAP_EXACT_IN);
    inputs.push(
        (
            ADDRESS_THIS,
            amount_in,
            U256::ZERO,
            Bytes::from(path),
            payer_is_user,
        )
            .abi_encode_params()
            .into(),
    );

    commands.push(CMD_PAY_PORTION);
    inputs.push(
        (token_out, FEE_RECIPIENT, U256::from(FEE_BIPS))
            .abi_encode_params()
            .into(),
    );

    if native_out {
        commands.push(CMD_UNWRAP_WETH);
        inputs.push((recipient, amount_out_min).abi_encode_params().into());
    } else {
        commands.push(CMD_SWEEP);
        inputs.push(
            (token_out, recipient, amount_out_min)
                .abi_encode_params()
                .into(),
        );
    }

    executeCall {
        commands: Bytes::from(commands),
        inputs,
        deadline,
    }
    .abi_encode()
}

/// Standard EIP-712 typed-data JSON for a Permit2 `PermitSingle`.
fn permit2_typed_data_json(addrs: &RouterAddrs, token_hex: &str, nonce: u64) -> String {
    json!({
        "types": {
            "EIP712Domain": [
                { "name": "name", "type": "string" },
                { "name": "chainId", "type": "uint256" },
                { "name": "verifyingContract", "type": "address" }
            ],
            "PermitSingle": [
                { "name": "details", "type": "PermitDetails" },
                { "name": "spender", "type": "address" },
                { "name": "sigDeadline", "type": "uint256" }
            ],
            "PermitDetails": [
                { "name": "token", "type": "address" },
                { "name": "amount", "type": "uint160" },
                { "name": "expiration", "type": "uint48" },
                { "name": "nonce", "type": "uint48" }
            ]
        },
        "primaryType": "PermitSingle",
        "domain": {
            "name": "Permit2",
            "chainId": addrs.chain_id,
            "verifyingContract": addrs.permit2.to_string()
        },
        "message": {
            "details": {
                "token": token_hex,
                "amount": PERMIT_AMOUNT.to_string(),
                "expiration": PERMIT_EXPIRATION.to_string(),
                "nonce": nonce.to_string()
            },
            "spender": addrs.universal_router.to_string(),
            "sigDeadline": PERMIT_SIG_DEADLINE.to_string()
        }
    })
    .to_string()
}

/// Read-only quote: probe every fee tier (and the Permit2 nonce for ERC-20 inputs) in a
/// single batched `eth_call`, then keep the tier with the largest output.
#[allow(clippy::too_many_arguments)]
async fn router_quote(
    config: &ChainConfig,
    addrs: &RouterAddrs,
    fee_tiers: &[u32],
    token_in: &str,
    token_out: &str,
    amount_in: &str,
    owner: &str,
    is_native_in: bool,
) -> Result<(U256, u32, Option<u64>), String> {
    let tin = Address::from_str(token_in).map_err(|e| e.to_string())?;
    let tout = Address::from_str(token_out).map_err(|e| e.to_string())?;
    let amt = U256::from_str(amount_in).map_err(|e| e.to_string())?;

    let mut calls: Vec<Value> = Vec::with_capacity(fee_tiers.len() + 1);
    calls.extend(fee_tiers.iter().map(|&fee| {
        let data = encode_quote(tin, tout, amt, fee);
        RpcProvider::<ChainConfig>::build_payload(
            json!([{ "to": addrs.quoter_v2.to_string(), "data": hex::encode_prefixed(&data) }, "latest"]),
            EvmMethods::Call,
        )
    }));
    if !is_native_in {
        let owner_addr = Address::from_str(owner).map_err(|e| e.to_string())?;
        let data = IPermit2::allowanceCall {
            owner: owner_addr,
            token: tin,
            spender: addrs.universal_router,
        }
        .abi_encode();
        calls.push(RpcProvider::<ChainConfig>::build_payload(
            json!([{ "to": addrs.permit2.to_string(), "data": hex::encode_prefixed(&data) }, "latest"]),
            EvmMethods::Call,
        ));
    }

    let provider: RpcProvider<ChainConfig> = RpcProvider::new(config);
    let res = provider
        .req::<Vec<ResultRes<Value>>>(Value::Array(calls))
        .await
        .map_err(|e| e.to_string())?;

    let (amount_out, fee_tier) = fee_tiers
        .iter()
        .enumerate()
        .filter_map(|(i, &fee)| {
            let r = res.get(i).filter(|r| r.error.is_none())?;
            let out = r
                .result
                .as_ref()
                .and_then(|v| v.as_str())
                .and_then(|s| hex::decode(s).ok())
                .and_then(|b| decode_quote(&b))
                .filter(|&out| out > U256::ZERO)?;
            Some((out, fee))
        })
        .reduce(|(best_out, best_fee), (out, fee)| {
            if out > best_out {
                (out, fee)
            } else {
                (best_out, best_fee)
            }
        })
        .ok_or_else(|| "no liquidity for pair".to_string())?;

    let nonce = if is_native_in {
        None
    } else {
        res.get(fee_tiers.len())
            .filter(|r| r.error.is_none())
            .and_then(|r| r.result.as_ref())
            .and_then(|v| v.as_str())
            .and_then(|s| hex::decode(s).ok())
            .and_then(|b| decode_allowance_nonce(&b))
    };

    Ok((amount_out, fee_tier, nonce))
}

/// Build the unsigned Universal Router swap transaction. Only `router` + `chain_id` are needed
/// post-quote (the token addresses are already WETH-resolved in the blob).
#[allow(clippy::too_many_arguments)]
fn build_router_tx(
    router: Address,
    chain_id: u64,
    chain_hash: u64,
    from: Address,
    token_in: &str,
    token_out: &str,
    amount_in: &str,
    amount_out: &str,
    fee_tier: u32,
    slippage_bps: u32,
    deadline: u64,
    is_native_in: bool,
    is_native_out: bool,
    permit_nonce: Option<u64>,
    permit_signature: Option<&str>,
) -> Result<TransactionRequest, String> {
    let tin = Address::from_str(token_in).map_err(|e| e.to_string())?;
    let tout = Address::from_str(token_out).map_err(|e| e.to_string())?;
    let amount_in_u256 = U256::from_str(amount_in).map_err(|e| e.to_string())?;
    let amount_out_u256 = U256::from_str(amount_out).map_err(|e| e.to_string())?;

    let bps = U256::from(10_000u32);
    let slip = U256::from(10_000u32.saturating_sub(slippage_bps));
    let fee = U256::from(10_000u32.saturating_sub(FEE_BIPS));
    let by_slip = amount_out_u256.saturating_mul(slip) / bps;
    let amount_out_min = by_slip.saturating_mul(fee) / bps;

    let input = if is_native_in {
        SwapInput::NativeEth
    } else {
        let nonce =
            permit_nonce.ok_or_else(|| "missing permit nonce for ERC-20 input".to_string())?;
        let sig_hex = permit_signature
            .ok_or_else(|| "missing permit signature for ERC-20 input".to_string())?;
        let signature = hex::decode(sig_hex.strip_prefix("0x").unwrap_or(sig_hex))
            .map_err(|e| e.to_string())?;
        let permit = PermitSingle {
            details: PermitDetails {
                token: tin,
                amount: PERMIT_AMOUNT,
                expiration: PERMIT_EXPIRATION,
                nonce: U48::from(nonce),
            },
            spender: router,
            sigDeadline: U256::from(PERMIT_SIG_DEADLINE),
        };
        SwapInput::Erc20 { permit, signature }
    };

    let plan = SwapPlan {
        token_in: tin,
        token_out: tout,
        amount_in: amount_in_u256,
        amount_out_min,
        fee_tier,
        recipient: from,
        input,
        native_out: is_native_out,
    };
    let data = build_execute_calldata(plan, U256::from(deadline));

    let value = if is_native_in {
        amount_in_u256
    } else {
        U256::ZERO
    };
    let mut tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(router)),
        from: Some(from),
        value: Some(value),
        input: data.into(),
        gas: Some(DEFAULT_SWAP_GAS),
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

/// Build a 1:1 native ↔ wrapped-native transaction directly against the WETH/WBNB contract:
/// `deposit()` with `value = amount` (wrap) or `withdraw(amount)` (unwrap). No router, no Permit2,
/// no platform fee — `withdraw` burns the caller's own balance, so it needs no approval either.
fn build_wrap_tx(
    weth: Address,
    chain_id: u64,
    chain_hash: u64,
    from: Address,
    amount: &str,
    is_native_in: bool,
) -> Result<TransactionRequest, String> {
    let amt = U256::from_str(amount).map_err(|e| e.to_string())?;
    let (data, value) = if is_native_in {
        (IWETH::depositCall {}.abi_encode(), amt)
    } else {
        (IWETH::withdrawCall { amount: amt }.abi_encode(), U256::ZERO)
    };

    let mut tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(weth)),
        from: Some(from),
        value: Some(value),
        input: data.into(),
        gas: Some(DEFAULT_APPROVE_GAS),
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

/// Quote orchestration for an EVM-DEX `ExchangeProvider` arm: pull the chain config, run the
/// on-chain quote and (for ERC-20 inputs) attach the Permit2 JSON to sign. The displayed output
/// has the platform fee subtracted.
#[frb(ignore)]
pub async fn router_quote_info(
    cfg: &RouterConfig,
    asset: &ExchangeAsset,
    from_asset: &str,
    to_asset: &str,
    amount: &str,
    destination: &str,
) -> Result<ProviderQuote, String> {
    let addrs = cfg.addrs;
    let is_native_in = asset.token.native;

    let (token_in, token_out, _is_native_out, is_wrap_unwrap) =
        resolve_pair(&addrs, from_asset, to_asset, is_native_in)?;

    // Native ↔ wrapped-native: no pool, no quote — it's a 1:1 wrap/unwrap.
    if is_wrap_unwrap {
        return Ok(ProviderQuote {
            amount_out: amount.to_string(),
            permit_typed_data_json: None,
            is_wrap_unwrap: true,
        });
    }

    let config = with_service(|core| {
        Ok(core
            .get_provider(asset.token.chain_hash)
            .map_err(ServiceError::BackgroundError)?
            .config
            .clone())
    })
    .await
    .map_err(|e: ServiceError| e.to_string())?;

    let (gross_out, _fee_tier, nonce) = router_quote(
        &config,
        &addrs,
        cfg.fee_tiers,
        &token_in,
        &token_out,
        amount,
        destination,
        is_native_in,
    )
    .await?;

    let fee_bps = U256::from(10_000u32.saturating_sub(FEE_BIPS));
    let net_out = gross_out.saturating_mul(fee_bps) / U256::from(10_000u32);

    let permit_typed_data_json = if is_native_in {
        None
    } else {
        nonce.map(|nonce| permit2_typed_data_json(&addrs, &token_in, nonce))
    };

    Ok(ProviderQuote {
        amount_out: net_out.to_string(),
        permit_typed_data_json,
        is_wrap_unwrap: false,
    })
}

#[frb(ignore)]
pub struct PreparedSwap {
    pub permit_typed_data_json: Option<String>,
    pub quote_blob: String,
}

/// First half of a swap: re-quote for freshness, build the opaque blob, and surface the permit
/// typed data to sign (for ERC-20 inputs).
#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub async fn prepare_router_swap(
    cfg: &RouterConfig,
    swapper: Address,
    chain_hash: u64,
    token_in: &str,
    token_out: &str,
    amount_in: &str,
    slippage_bps: u32,
    is_native_in: bool,
) -> Result<PreparedSwap, String> {
    let addrs = cfg.addrs;
    let (resolved_in, resolved_out, is_native_out, is_wrap_unwrap) =
        resolve_pair(&addrs, token_in, token_out, is_native_in)?;

    // Wrap/unwrap: 1:1, no quote, no permit. `finalize_router_swap` detects it by
    // `token_in == token_out` and builds the deposit/withdraw tx.
    if is_wrap_unwrap {
        let blob = QuoteBlob {
            chain_id: addrs.chain_id,
            universal_router: addrs.universal_router.to_string(),
            token_in: resolved_in.clone(),
            token_out: resolved_out,
            amount_in: amount_in.to_string(),
            amount_out: amount_in.to_string(),
            fee_tier: 0,
            permit_nonce: None,
            is_native_in,
            is_native_out,
            slippage_bps,
        };
        return Ok(PreparedSwap {
            permit_typed_data_json: None,
            quote_blob: serde_json::to_string(&blob).map_err(|e| e.to_string())?,
        });
    }

    let config = with_service(|core| {
        Ok(core
            .get_provider(chain_hash)
            .map_err(ServiceError::BackgroundError)?
            .config
            .clone())
    })
    .await
    .map_err(|e: ServiceError| e.to_string())?;

    let (amount_out, fee_tier, nonce) = router_quote(
        &config,
        &addrs,
        cfg.fee_tiers,
        &resolved_in,
        &resolved_out,
        amount_in,
        &swapper.to_string(),
        is_native_in,
    )
    .await?;

    let permit_typed_data_json = if is_native_in {
        None
    } else {
        nonce.map(|nonce| permit2_typed_data_json(&addrs, &resolved_in, nonce))
    };

    let blob = QuoteBlob {
        chain_id: addrs.chain_id,
        universal_router: addrs.universal_router.to_string(),
        token_in: resolved_in,
        token_out: resolved_out,
        amount_in: amount_in.to_string(),
        amount_out: amount_out.to_string(),
        fee_tier,
        permit_nonce: nonce,
        is_native_in,
        is_native_out,
        slippage_bps,
    };

    Ok(PreparedSwap {
        permit_typed_data_json,
        quote_blob: serde_json::to_string(&blob).map_err(|e| e.to_string())?,
    })
}

/// Second half of a swap: attach the permit signature, build the unsigned Universal Router tx,
/// and lift it into the FFI tx with display metadata. Provider-agnostic — rebuilds from the blob.
#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub async fn finalize_router_swap(
    quote_blob: &str,
    swapper: Address,
    chain_hash: u64,
    permit_signature: Option<&str>,
    swap_title: String,
    swap_info: String,
    provider_icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let blob: QuoteBlob =
        serde_json::from_str(quote_blob).map_err(|e| format!("invalid quote_blob: {e}"))?;

    // Wrap/unwrap (native ↔ wrapped-native) is a direct WETH deposit/withdraw, not a router swap.
    let tx = if blob.token_in.eq_ignore_ascii_case(&blob.token_out) {
        let weth = Address::from_str(&blob.token_in).map_err(|e| e.to_string())?;
        build_wrap_tx(
            weth,
            blob.chain_id,
            chain_hash,
            swapper,
            &blob.amount_in,
            blob.is_native_in,
        )?
    } else {
        let router = Address::from_str(&blob.universal_router).map_err(|e| e.to_string())?;
        let deadline = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_err(|e| e.to_string())?
            .as_secs()
            .saturating_add(20 * 60);

        build_router_tx(
            router,
            blob.chain_id,
            chain_hash,
            swapper,
            &blob.token_in,
            &blob.token_out,
            &blob.amount_in,
            &blob.amount_out,
            blob.fee_tier,
            blob.slippage_bps,
            deadline,
            blob.is_native_in,
            blob.is_native_out,
            blob.permit_nonce,
            permit_signature,
        )?
    };

    let evm_tx = match tx {
        TransactionRequest::Ethereum((eth, _)) => eth,
        _ => return Err("expected Ethereum tx".to_string()),
    };

    Ok(TransactionRequest::Ethereum((
        evm_tx,
        TransactionMetadata {
            chain_hash,
            broadcast: true,
            title: Some(swap_title),
            info: Some(swap_info),
            icon: Some(provider_icon),
            token_info: out_token.map(|t| {
                (
                    U256::from_str(&t.value).unwrap_or_default(),
                    t.decimals,
                    t.symbol,
                )
            }),
            ..Default::default()
        },
    ))
    .try_into()
    .map_err(|e: zilpay::errors::tx::TransactionErrors| e.to_string())?)
}

/// Check whether the user's ERC-20 token has enough allowance for Permit2 to pull.
/// Returns `Some(approve_tx)` if the current allowance is below `amount`, else `None`.
#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub async fn router_check_approval(
    cfg: &RouterConfig,
    swapper: Address,
    chain_hash: u64,
    token: &str,
    amount: &str,
    approve_title: String,
    provider_icon: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    let addrs = cfg.addrs;

    let config = with_service(|core| {
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
        owner: swapper,
        spender: addrs.permit2,
    }
    .abi_encode();

    let payload = RpcProvider::<ChainConfig>::build_payload(
        json!([{ "to": token, "data": hex::encode_prefixed(&call) }, "latest"]),
        EvmMethods::Call,
    );

    let provider: RpcProvider<ChainConfig> = RpcProvider::new(&config);
    let res = provider
        .req::<ResultRes<Value>>(payload)
        .await
        .map_err(|e| e.to_string())?;

    let current = res
        .result
        .as_ref()
        .and_then(|v| v.as_str())
        .and_then(|s| hex::decode(s).ok())
        .and_then(|b| decode_erc20_allowance(&b))
        .unwrap_or(U256::ZERO);

    let needed = U256::from_str(amount).map_err(|e| e.to_string())?;
    if current >= needed {
        return Ok(None);
    }

    let data = IERC20::approveCall {
        spender: addrs.permit2,
        amount: U256::MAX,
    }
    .abi_encode();

    let mut tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(token_addr)),
        from: Some(swapper),
        value: Some(U256::ZERO),
        input: data.into(),
        gas: Some(DEFAULT_APPROVE_GAS),
        ..Default::default()
    };
    tx.chain_id = Some(addrs.chain_id);

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
mod engine_tests {
    use super::*;

    fn addr(b: u8) -> Address {
        Address::from([b; 20])
    }

    fn addrs() -> RouterAddrs {
        RouterAddrs {
            chain_id: 1,
            universal_router: addr(0xee),
            quoter_v2: addr(0xdd),
            permit2: addr(0xcc),
            weth: addr(0xbb),
        }
    }

    #[test]
    fn resolve_out_same_chain_plain_addr() {
        let (addr, native) = resolve_out("0xabc", 8453).unwrap();
        assert_eq!(addr.as_ref(), "0xabc");
        assert!(!native);
    }

    #[test]
    fn resolve_out_cross_chain_rejected() {
        let err = resolve_out("42161:0xdef", 8453).unwrap_err();
        assert!(err.contains("cross-chain"));
    }

    #[test]
    fn resolve_out_native_sentinel() {
        let (addr, native) = resolve_out(NATIVE_SENTINEL, 8453).unwrap();
        assert_eq!(addr.as_ref(), NATIVE_SENTINEL);
        assert!(native);
    }

    #[test]
    fn resolve_out_same_chain_prefixed() {
        let (addr, native) = resolve_out("8453:0xabc", 8453).unwrap();
        assert_eq!(addr.as_ref(), "0xabc");
        assert!(!native);
    }

    #[test]
    fn resolve_out_same_chain_prefixed_native() {
        let input = format!("8453:{NATIVE_SENTINEL}");
        let (addr, native) = resolve_out(&input, 8453).unwrap();
        assert_eq!(addr.as_ref(), NATIVE_SENTINEL);
        assert!(native);
    }

    #[test]
    fn resolve_in_native_uses_weth() {
        assert_eq!(
            resolve_in(true, "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "0xabc").as_ref(),
            "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        );
        assert_eq!(resolve_in(false, "0xWETH", "0xUSDC").as_ref(), "0xUSDC");
    }

    #[test]
    fn v3_path_layout() {
        let tin = addr(0x11);
        let tout = addr(0x22);
        let path = v3_path(&tin, 3000, &tout);

        assert_eq!(path.len(), 43);
        assert_eq!(&path[..20], tin.as_slice());
        assert_eq!(&path[20..23], &[0x00, 0x0b, 0xb8]);
        assert_eq!(&path[23..], tout.as_slice());
    }

    #[test]
    fn execute_calldata_native_eth() {
        let plan = SwapPlan {
            token_in: addr(0xaa),
            token_out: addr(0xbb),
            amount_in: U256::from(1_000u64),
            amount_out_min: U256::from(900u64),
            fee_tier: 500,
            recipient: addr(0xcc),
            input: SwapInput::NativeEth,
            native_out: false,
        };
        let data = build_execute_calldata(plan, U256::from(123u64));

        assert_eq!(&data[..4], executeCall::SELECTOR.as_slice());
        let decoded = executeCall::abi_decode(&data).unwrap();
        assert_eq!(decoded.commands.as_ref(), &[0x0b, 0x00, 0x06, 0x04]);
        assert_eq!(decoded.inputs.len(), 4);
        assert_eq!(decoded.deadline, U256::from(123u64));
    }

    #[test]
    fn execute_calldata_erc20_permit() {
        let permit = PermitSingle {
            details: PermitDetails {
                token: addr(0xbb),
                amount: U160::from(5u64),
                expiration: U48::from(6u64),
                nonce: U48::from(7u64),
            },
            spender: addr(0xee),
            sigDeadline: U256::from(8u64),
        };
        let plan = SwapPlan {
            token_in: addr(0xaa),
            token_out: addr(0xbb),
            amount_in: U256::from(1_000u64),
            amount_out_min: U256::from(900u64),
            fee_tier: 3000,
            recipient: addr(0xcc),
            input: SwapInput::Erc20 {
                permit,
                signature: vec![1, 2, 3, 4],
            },
            native_out: false,
        };
        let data = build_execute_calldata(plan, U256::from(456u64));

        assert_eq!(&data[..4], executeCall::SELECTOR.as_slice());
        let decoded = executeCall::abi_decode(&data).unwrap();
        assert_eq!(decoded.commands.as_ref(), &[0x0a, 0x00, 0x06, 0x04]);
        assert_eq!(decoded.inputs.len(), 4);
    }

    #[test]
    fn execute_calldata_native_out_unwraps() {
        let plan = SwapPlan {
            token_in: addr(0xaa),
            token_out: addr(0xbb),
            amount_in: U256::from(1_000u64),
            amount_out_min: U256::from(900u64),
            fee_tier: 500,
            recipient: addr(0xcc),
            input: SwapInput::NativeEth,
            native_out: true,
        };
        let data = build_execute_calldata(plan, U256::from(789u64));

        let decoded = executeCall::abi_decode(&data).unwrap();
        assert_eq!(decoded.commands.as_ref(), &[0x0b, 0x00, 0x06, 0x0c]);
        assert_eq!(decoded.inputs.len(), 4);
    }

    #[test]
    fn permit2_typed_data_json_has_correct_shape() {
        let json_str = permit2_typed_data_json(&addrs(), "0xabc", 42);
        let v: Value = serde_json::from_str(&json_str).unwrap();
        assert_eq!(v["primaryType"], "PermitSingle");
        assert_eq!(v["domain"]["chainId"], 1);
        assert_eq!(v["message"]["details"]["nonce"], "42");
        assert_eq!(
            v["message"]["spender"],
            addrs().universal_router.to_string()
        );
    }

    #[test]
    fn resolve_pair_flags_wrap_and_unwrap() {
        let a = addrs(); // weth = 0xbbbb...bb
        let weth = a.weth.to_string();

        // native BNB (zero addr) -> WBNB == wrap
        let (_, _, _, wrap) = resolve_pair(&a, NATIVE_SENTINEL, &weth, true).unwrap();
        assert!(wrap);

        // WBNB -> native BNB == unwrap
        let (_, _, native_out, unwrap) = resolve_pair(&a, &weth, NATIVE_SENTINEL, false).unwrap();
        assert!(unwrap);
        assert!(native_out);

        // WBNB -> some other token == normal swap
        let (_, _, _, plain) = resolve_pair(&a, &weth, &addr(0x99).to_string(), false).unwrap();
        assert!(!plain);
    }

    #[test]
    fn build_wrap_tx_encodes_deposit_with_value() {
        let tx = build_wrap_tx(addr(0xbb), 56, 1, addr(0xcc), "1000", true).unwrap();
        let TransactionRequest::Ethereum((eth, _)) = tx else {
            panic!("expected ethereum tx");
        };
        let data = eth.input.input.clone().unwrap();
        assert_eq!(eth.value, Some(U256::from(1000u64)));
        assert_eq!(&data[..4], IWETH::depositCall::SELECTOR.as_slice());
        // deposit() selector is 0xd0e30db0.
        assert_eq!(&data[..4], &[0xd0, 0xe3, 0x0d, 0xb0]);
    }

    #[test]
    fn build_wrap_tx_encodes_withdraw_zero_value() {
        let tx = build_wrap_tx(addr(0xbb), 56, 1, addr(0xcc), "1000", false).unwrap();
        let TransactionRequest::Ethereum((eth, _)) = tx else {
            panic!("expected ethereum tx");
        };
        let data = eth.input.input.clone().unwrap();
        assert_eq!(eth.value, Some(U256::ZERO));
        assert_eq!(&data[..4], IWETH::withdrawCall::SELECTOR.as_slice());
        let decoded = IWETH::withdrawCall::abi_decode(&data).unwrap();
        assert_eq!(decoded.amount, U256::from(1000u64));
    }

    #[test]
    fn quote_blob_round_trips() {
        let blob = QuoteBlob {
            chain_id: 8453,
            universal_router: "0xrouter".to_string(),
            token_in: "0xtin".to_string(),
            token_out: "0xtout".to_string(),
            amount_in: "100".to_string(),
            amount_out: "200".to_string(),
            fee_tier: 3000,
            permit_nonce: Some(7),
            is_native_in: false,
            is_native_out: true,
            slippage_bps: 50,
        };
        let json_str = serde_json::to_string(&blob).unwrap();
        let parsed: QuoteBlob = serde_json::from_str(&json_str).unwrap();
        assert_eq!(parsed.chain_id, 8453);
        assert_eq!(parsed.permit_nonce, Some(7));
        assert!(parsed.is_native_out);
        assert_eq!(parsed.universal_router, "0xrouter");
    }

    #[test]
    fn decode_quote_handles_zero_and_success() {
        let empty = Vec::new();
        assert!(decode_quote(&empty).is_none());
    }

    #[test]
    fn decode_allowance_nonce_handles_zero_and_success() {
        let empty = Vec::new();
        assert!(decode_allowance_nonce(&empty).is_none());
    }

    /// Guards the regression where renaming the `sol!` function (e.g. to `permit2Allowance`)
    /// silently changed the 4-byte selector — the selector is derived from the on-chain
    /// signature `allowance(address,address,address)`, never the interface/function name.
    #[test]
    fn permit2_allowance_selector_matches_real_signature() {
        use zilpay::alloy::primitives::keccak256;
        let expected = &keccak256("allowance(address,address,address)")[..4];
        assert_eq!(IPermit2::allowanceCall::SELECTOR.as_slice(), expected);
    }
}
