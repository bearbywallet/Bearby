//! Internal alloy layer for Uniswap V3 on-chain quoting (QuoterV2) and swapping
//! (Universal Router `execute`). Nothing here crosses the flutter_rust_bridge
//! boundary: every item is `#[frb(ignore)]` and freely uses alloy types. The public
//! FFI surface lives in `crate::api::exchange`, which carries big numbers/addresses
//! as hex `String` and parses them into these alloy types exactly once.

use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{
    address,
    aliases::{U160, U24, U48},
    Address, Bytes, U256,
};
use zilpay::alloy::sol;
use zilpay::alloy::sol_types::{SolCall, SolValue};
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_wallet::WalletManagement;
use zilpay::proto::tx::{ETHTransactionRequest, TransactionMetadata, TransactionRequest};
use zilpay::proto::AlloyTxKind;
use zilpay::rpc::{
    common::JsonRPC, methods::EvmMethods, network_config::ChainConfig, provider::RpcProvider,
    zil_interfaces::ResultRes,
};
use zilpay::serde_json::{json, Value};
use zilpay::wallet::wallet_storage::StorageOperations;

use super::{ExchangeAsset, ExchangeQuoteInfo, ExchangeProvider, UniswapMeta};
use crate::models::transactions::request::TransactionRequestInfo;
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;
use crate::utils::helpers::with_service;

// Universal Router command bytes (Commands.sol).
const CMD_V3_SWAP_EXACT_IN: u8 = 0x00;
const CMD_SWEEP: u8 = 0x04;
const CMD_PAY_PORTION: u8 = 0x06;
const CMD_PERMIT2_PERMIT: u8 = 0x0a;
const CMD_WRAP_ETH: u8 = 0x0b;

// Router recipient sentinel: address(2) routes funds to the router itself so that the
// subsequent PAY_PORTION / SWEEP commands can split the swap output.
const ADDRESS_THIS: Address = Address::with_last_byte(2);

/// Platform fee taken from the swap *output* by PAY_PORTION, in basis points.
pub const FEE_BIPS: u32 = 50;
const FEE_RECIPIENT: Address = address!("0x74d35b31eD6b31818331Bc28fe343669126f152F");

/// V3 fee tiers probed by the quoter; the tier with the best output wins.
pub const V3_FEE_TIERS: &[u32] = &[100, 500, 3000, 10000];

// Permit2 allowance is granted "max amount / no time expiry"; single-use is still
// enforced by the per-token nonce. These are constant so the typed-data JSON signed at
// quote time and the `PermitSingle` rebuilt at tx-build time are byte-identical.
const PERMIT_AMOUNT: U160 = U160::MAX;
const PERMIT_EXPIRATION: U48 = U48::MAX;
const PERMIT_SIG_DEADLINE: u64 = 281_474_976_710_655; // type(uint48).max

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

    function allowance(address owner, address token, address spender)
        external view returns (uint160 amount, uint48 expiration, uint48 nonce);

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

/// `Copy` bundle of parsed deployment addresses — parse the FFI hex once, then reuse.
#[frb(ignore)]
#[derive(Clone, Copy)]
pub struct UniswapAddrs {
    pub chain_id: u64,
    pub universal_router: Address,
    pub quoter_v2: Address,
    pub permit2: Address,
    pub weth: Address,
}

impl UniswapMeta {
    /// Per-chain deployment table. `None` for unsupported chains, which is what gates
    /// Uniswap support in `ExchangeProvider::is_support`.
    #[frb(ignore)]
    pub fn for_chain(chain_id: u64) -> Option<Self> {
        const PERMIT2: &str = "0x000000000022D473030F116dDEE9F6B43aC78BA3";
        let (universal_router, quoter_v2, weth) = match chain_id {
            // Ethereum mainnet
            1 => (
                "0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af",
                "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
                "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            ),
            // Optimism
            10 => (
                "0x851116D9223fabED8E56C0E6b8Ad0c31d98b3507",
                "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
                "0x4200000000000000000000000000000000000006",
            ),
            // Polygon PoS (wrapped native = WMATIC)
            137 => (
                "0x1095692A6237d83C6a72F3F5eFEdb9A670C49223",
                "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
                "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
            ),
            // Base
            8453 => (
                "0x6fF5693b99212Da76ad316178A184AB56D299b43",
                "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a",
                "0x4200000000000000000000000000000000000006",
            ),
            // Arbitrum One
            42161 => (
                "0xA51afAFe0263b40EdaEf0Df8781eA9aa03E381a3",
                "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
                "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
            ),
            // Ethereum Sepolia (testnet)
            11155111 => (
                "0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b",
                "0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3",
                "0xfff9976782d46cc05630d1f6ebab18b2324d6b14",
            ),
            // Optimism Sepolia (testnet)
            11155420 => (
                "0xD5bBa708b39537d33F2812E5Ea032622456F1A95",
                "0xC5290058841028F1614F3A6F0F5816cAd0df5E27",
                "0x4200000000000000000000000000000000000006",
            ),
            // Base Sepolia (testnet)
            84532 => (
                "0x492E6456D9528771018DeB9E87ef7750EF184104",
                "0xC5290058841028F1614F3A6F0F5816cAd0df5E27",
                "0x4200000000000000000000000000000000000006",
            ),
            // Arbitrum Sepolia (testnet)
            421614 => (
                "0x4A7b5Da61326A6379179b40d00F57E5bbDC962c2",
                "0x2779a0CC1c3e0E44D2542EC3e79e3864Ae93Ef0B",
                "0x980B62Da83eFf3D4576C647993b0c1D7faf17c73",
            ),
            _ => return None,
        };

        Some(Self {
            chain_id,
            universal_router: universal_router.into(),
            quoter_v2: quoter_v2.into(),
            permit2: PERMIT2.into(),
            weth: weth.into(),
        })
    }

    /// Parse the FFI hex addresses into a `Copy` alloy bundle once.
    #[frb(ignore)]
    pub fn resolve(&self) -> Result<UniswapAddrs, String> {
        let p = |s: &str| Address::from_str(s).map_err(|e| e.to_string());
        Ok(UniswapAddrs {
            chain_id: self.chain_id,
            universal_router: p(&self.universal_router)?,
            quoter_v2: p(&self.quoter_v2)?,
            permit2: p(&self.permit2)?,
            weth: p(&self.weth)?,
        })
    }
}

/// Best quote across the probed fee tiers, plus the Permit2 nonce for ERC20 inputs.
#[frb(ignore)]
pub struct UniswapQuote {
    pub amount_out: U256,
    pub fee_tier: u32,
    pub nonce: Option<u64>,
}

#[frb(ignore)]
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

#[frb(ignore)]
fn decode_quote(data: &[u8]) -> Option<U256> {
    quoteExactInputSingleCall::abi_decode_returns(data)
        .ok()
        .map(|r| r.amountOut)
}

#[frb(ignore)]
fn encode_allowance(owner: Address, token: Address, spender: Address) -> Vec<u8> {
    allowanceCall {
        owner,
        token,
        spender,
    }
    .abi_encode()
}

#[frb(ignore)]
fn decode_allowance_nonce(data: &[u8]) -> Option<u64> {
    allowanceCall::abi_decode_returns(data)
        .ok()
        .map(|r| r.nonce.to::<u64>())
}

/// Packed V3 single-hop path: `tokenIn (20) | fee (uint24, 3) | tokenOut (20)` = 43 bytes.
#[frb(ignore)]
fn v3_path(tin: &Address, fee: u32, tout: &Address) -> Vec<u8> {
    let mut p = Vec::with_capacity(20 + 3 + 20);
    p.extend_from_slice(tin.as_slice());
    p.extend_from_slice(&fee.to_be_bytes()[1..]); // low 3 bytes -> uint24
    p.extend_from_slice(tout.as_slice());
    p
}

#[frb(ignore)]
pub enum SwapInput {
    /// Native input: `WRAP_ETH` funds the router; no approval / no permit.
    NativeEth,
    /// ERC20 input: `PERMIT2_PERMIT` with an EIP-712 signature; the user pays.
    Erc20 {
        permit: PermitSingle,
        signature: Vec<u8>,
    },
}

#[frb(ignore)]
pub struct SwapPlan {
    pub token_in: Address,
    pub token_out: Address,
    pub amount_in: U256,
    pub amount_out_min: U256,
    pub fee_tier: u32,
    pub recipient: Address,
    pub input: SwapInput,
}

/// Encode the Universal Router `execute(commands, inputs, deadline)` calldata for a
/// single-hop V3 swap that takes our platform fee from the output:
/// `[WRAP_ETH|PERMIT2_PERMIT] -> V3_SWAP_EXACT_IN -> PAY_PORTION -> SWEEP`.
#[frb(ignore)]
pub fn build_execute_calldata(plan: SwapPlan, deadline: U256) -> Vec<u8> {
    let SwapPlan {
        token_in,
        token_out,
        amount_in,
        amount_out_min,
        fee_tier,
        recipient,
        input,
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

    commands.push(CMD_SWEEP);
    inputs.push(
        (token_out, recipient, amount_out_min)
            .abi_encode_params()
            .into(),
    );

    executeCall {
        commands: Bytes::from(commands),
        inputs,
        deadline,
    }
    .abi_encode()
}

/// Standard EIP-712 typed-data JSON for a Permit2 `PermitSingle`, consumed by the
/// existing `sign_typed_data_eip712` FFI. The Permit2 domain has no `version` field.
#[frb(ignore)]
pub fn permit2_typed_data_json(addrs: &UniswapAddrs, token_hex: &str, nonce: u64) -> String {
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

/// Read-only quote: probe every fee tier (and the Permit2 nonce for ERC20 inputs) in a
/// single batched `eth_call`, then keep the tier with the largest output. `token_in` is
/// already WETH for native inputs.
#[frb(ignore)]
pub async fn uniswap_quote(
    addrs: &UniswapAddrs,
    config: &ChainConfig,
    token_in: &str,
    token_out: &str,
    amount: &str,
    owner: &str,
    is_native_in: bool,
) -> Result<UniswapQuote, String> {
    let tin = Address::from_str(token_in).map_err(|e| e.to_string())?;
    let tout = Address::from_str(token_out).map_err(|e| e.to_string())?;
    let amt = U256::from_str(amount).map_err(|e| e.to_string())?;

    let mut calls: Vec<Value> = Vec::with_capacity(V3_FEE_TIERS.len() + 1);
    for &fee in V3_FEE_TIERS {
        let data = encode_quote(tin, tout, amt, fee);
        calls.push(RpcProvider::<ChainConfig>::build_payload(
            json!([{ "to": addrs.quoter_v2.to_string(), "data": hex::encode_prefixed(&data) }, "latest"]),
            EvmMethods::Call,
        ));
    }
    if !is_native_in {
        let owner_addr = Address::from_str(owner).map_err(|e| e.to_string())?;
        let data = encode_allowance(owner_addr, tin, addrs.universal_router);
        calls.push(RpcProvider::<ChainConfig>::build_payload(
            json!([{ "to": addrs.permit2.to_string(), "data": hex::encode_prefixed(&data) }, "latest"]),
            EvmMethods::Call,
        ));
    }

    let provider: RpcProvider<ChainConfig> = RpcProvider::new(config);
    let res = provider
        .req::<Vec<ResultRes<Value>>>(calls.into())
        .await
        .map_err(|e| e.to_string())?;

    let mut best: Option<(U256, u32)> = None;
    for (i, &fee) in V3_FEE_TIERS.iter().enumerate() {
        let Some(r) = res.get(i) else { continue };
        if r.error.is_some() {
            continue; // tier has no pool -> the call reverts; just skip it
        }
        let out = r
            .result
            .as_ref()
            .and_then(|v| v.as_str())
            .and_then(|s| hex::decode(s).ok())
            .and_then(|b| decode_quote(&b));
        if let Some(out) = out {
            if out > U256::ZERO && best.map_or(true, |(b, _)| out > b) {
                best = Some((out, fee));
            }
        }
    }
    let (amount_out, fee_tier) = best.ok_or_else(|| "no liquidity for pair".to_string())?;

    let nonce = if is_native_in {
        None
    } else {
        res.get(V3_FEE_TIERS.len())
            .filter(|r| r.error.is_none())
            .and_then(|r| r.result.as_ref())
            .and_then(|v| v.as_str())
            .and_then(|s| hex::decode(s).ok())
            .and_then(|b| decode_allowance_nonce(&b))
    };

    Ok(UniswapQuote {
        amount_out,
        fee_tier,
        nonce,
    })
}

/// Build the unsigned Universal Router swap transaction. `amount_out_min` floors the
/// output after both slippage and our fee. ERC20 inputs require `permit_nonce` (from the
/// quote) and `permit_signature` (the user's EIP-712 signature over the permit JSON).
#[frb(ignore)]
#[allow(clippy::too_many_arguments)]
pub fn build_uniswap_tx(
    addrs: &UniswapAddrs,
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
    let amount_out_min = amount_out_u256 * slip / bps * fee / bps;

    let input = if is_native_in {
        SwapInput::NativeEth
    } else {
        let nonce =
            permit_nonce.ok_or_else(|| "missing permit nonce for ERC20 input".to_string())?;
        let sig_hex = permit_signature
            .ok_or_else(|| "missing permit signature for ERC20 input".to_string())?;
        let signature = hex::decode(sig_hex.strip_prefix("0x").unwrap_or(sig_hex))
            .map_err(|e| e.to_string())?;
        let permit = PermitSingle {
            details: PermitDetails {
                token: tin,
                amount: PERMIT_AMOUNT,
                expiration: PERMIT_EXPIRATION,
                nonce: U48::from(nonce),
            },
            spender: addrs.universal_router,
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
    };
    let data = build_execute_calldata(plan, U256::from(deadline));

    let value = if is_native_in {
        amount_in_u256
    } else {
        U256::ZERO
    };
    let mut tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(addrs.universal_router)),
        from: Some(from),
        value: Some(value),
        input: data.into(),
        ..Default::default()
    };
    tx.chain_id = Some(addrs.chain_id);

    Ok(TransactionRequest::Ethereum((
        tx,
        TransactionMetadata {
            chain_hash,
            broadcast: true,
            ..Default::default()
        },
    )))
}

/// Quote orchestration for the `ExchangeProvider::Uniswap` arm of
/// `crate::api::exchange::fetch_exchange_quote`: resolve the deployment, pull the chain
/// config, run the on-chain quote and (for ERC20 inputs) attach the Permit2 JSON to sign.
#[frb(ignore)]
pub async fn uniswap_quote_info(
    meta: &UniswapMeta,
    asset: &ExchangeAsset,
    from_asset: &str,
    to_asset: &str,
    amount: &str,
    destination: &str,
) -> Result<ExchangeQuoteInfo, String> {
    let addrs = meta.resolve()?;
    let is_native_in = asset.token.native;
    let token_in = if is_native_in {
        meta.weth.as_str()
    } else {
        from_asset
    };

    let config = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        service
            .core
            .get_provider(asset.token.chain_hash)
            .map_err(ServiceError::BackgroundError)?
            .config
    };

    let quote = uniswap_quote(
        &addrs,
        &config,
        token_in,
        to_asset,
        amount,
        destination,
        is_native_in,
    )
    .await?;

    let permit_typed_data_json = if is_native_in {
        None
    } else {
        quote
            .nonce
            .map(|nonce| permit2_typed_data_json(&addrs, token_in, nonce))
    };

    Ok(ExchangeQuoteInfo {
        provider: ExchangeProvider::Uniswap(meta.clone()),
        amount_out: quote.amount_out.to_string(),
        fee_tier: Some(quote.fee_tier),
        permit_typed_data_json,
        permit_nonce: quote.nonce,
    })
}

/// Tx-build orchestration for the `ExchangeProvider::Uniswap` arm of
/// `crate::api::exchange::build_exchange_tx`: resolve the deployment, (for ERC20 inputs)
/// sign the Permit2 typed data internally, look up the signer account, build the unsigned
/// Universal Router tx and lift it into the FFI type.
#[frb(ignore)]
#[allow(clippy::too_many_arguments)]
pub async fn build_uniswap_tx_info(
    wallet_index: usize,
    account_index: usize,
    meta: &UniswapMeta,
    token_in: String,
    token_out: String,
    amount_in: String,
    amount_out: String,
    fee_tier: u32,
    slippage_bps: u32,
    deadline: u64,
    is_native_in: bool,
    permit_nonce: Option<u64>,
    password: Option<String>,
    passphrase: Option<String>,
) -> Result<TransactionRequestInfo, String> {
    let addrs = meta.resolve()?;

    // ERC20 inputs need a Permit2 EIP-712 signature. Rebuild the exact typed data signed at
    // quote time from the nonce and sign it here, reusing the shared EIP-712 signer so the
    // permit logic lives in one place. Native inputs use WRAP_ETH and need no permit.
    let permit_signature: Option<String> = if is_native_in {
        None
    } else {
        let nonce =
            permit_nonce.ok_or_else(|| "missing permit nonce for ERC20 input".to_string())?;
        let typed_data_json = permit2_typed_data_json(&addrs, &token_in, nonce);
        let (_pubkey, signature) = crate::api::transaction::sign_typed_data_eip712(
            wallet_index,
            account_index,
            password,
            passphrase,
            typed_data_json,
            None,
            None,
        )
        .await?;
        Some(signature)
    };

    with_service(|core| {
        let wallet = core
            .get_wallet_by_index(wallet_index)
            .map_err(ServiceError::BackgroundError)?;
        let data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let account = data
            .get_account(account_index)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let from = account.addr.to_alloy_addr();

        let tx = build_uniswap_tx(
            &addrs,
            data.chain_hash,
            from,
            &token_in,
            &token_out,
            &amount_in,
            &amount_out,
            fee_tier,
            slippage_bps,
            deadline,
            is_native_in,
            permit_nonce,
            permit_signature.as_deref(),
        )
        .map_err(|e| ServiceError::ParseError("uniswap tx".to_string(), e))?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}

#[cfg(test)]
mod uniswap_calldata_tests {
    use super::*;
    use zilpay::alloy::sol_types::SolCall;

    fn addr(b: u8) -> Address {
        Address::from([b; 20])
    }

    #[test]
    fn v3_path_layout() {
        let tin = addr(0x11);
        let tout = addr(0x22);
        let path = v3_path(&tin, 3000, &tout);

        assert_eq!(path.len(), 43);
        assert_eq!(&path[..20], tin.as_slice());
        assert_eq!(&path[20..23], &[0x00, 0x0b, 0xb8]); // 3000 as uint24
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
        };
        let data = build_execute_calldata(plan, U256::from(123u64));

        assert_eq!(&data[..4], executeCall::SELECTOR.as_slice());
        let decoded = executeCall::abi_decode(&data).unwrap();
        // WRAP_ETH -> V3_SWAP_EXACT_IN -> PAY_PORTION -> SWEEP
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
        };
        let data = build_execute_calldata(plan, U256::from(456u64));

        assert_eq!(&data[..4], executeCall::SELECTOR.as_slice());
        let decoded = executeCall::abi_decode(&data).unwrap();
        // PERMIT2_PERMIT -> V3_SWAP_EXACT_IN -> PAY_PORTION -> SWEEP
        assert_eq!(decoded.commands.as_ref(), &[0x0a, 0x00, 0x06, 0x04]);
        assert_eq!(decoded.inputs.len(), 4);
        assert_eq!(decoded.deadline, U256::from(456u64));
    }
}
