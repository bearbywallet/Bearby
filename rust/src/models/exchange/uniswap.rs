//! Internal Uniswap layer backed by the Uniswap **Trading API**
//! (`https://trade-api.gateway.uniswap.org/v1`). Nothing here crosses the
//! flutter_rust_bridge boundary: every item is `#[frb(ignore)]`. The API gives full
//! v2/v3/v4 routing on every Uniswap-supported chain plus cross-chain `BRIDGE` routing.
//!
//! Flow: `/quote` (routing + optional Permit2 `permitData`) → sign the permit EIP-712
//! internally → `/swap` (unsigned router/bridge calldata) → lift into the FFI tx, which
//! the UI signs and broadcasts via the existing `sign_send_transactions`.

use std::borrow::Cow;
use std::collections::HashSet;
use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{Address, U256};
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_wallet::WalletManagement;
use zilpay::proto::tx::{ETHTransactionRequest, TransactionMetadata, TransactionRequest};
use zilpay::proto::AlloyTxKind;
use zilpay::reqwest::Client;
use zilpay::serde_json::{json, Map, Value};
use zilpay::wallet::wallet_storage::StorageOperations;

use super::{ExchangeAsset, ExchangeProvider, ExchangeQuoteInfo};
use crate::models::transactions::request::TransactionRequestInfo;
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;

const TRADING_API_BASE: &str = "https://trade-api.gateway.uniswap.org/v1";
// Temporary shared test key — to be replaced by our hosted backend so the key is never
// shipped in the binary (the backend injects it and can also enable the platform fee).
const TRADING_API_KEY: &str = "UnUgzBC9Jsu3ulMJGnIn_enFSPKRj-VReeNCf9HlV-U";
const ROUTER_VERSION: &str = "2.0";

/// Native-input sentinel: the API recommends the zero address for native ETH input — it
/// returns `permitData: null` (no Permit2 signing) and carries the amount as `swap.value`.
const NATIVE_SENTINEL: &str = "0x0000000000000000000000000000000000000000";

/// Chains the Trading API can swap on (Universal Router deployments) plus the testnets the
/// app exercises. The API is the source of truth and rejects anything else; this only
/// gates whether the UI offers a Uniswap provider for an asset.
const SUPPORTED_CHAINS: &[u64] = &[
    1, 10, 56, 130, 137, 480, 1868, 8453, 42161, 42220, 43114, 57073, 81457, 7777777,
    // testnets:
    11155111, 11155420, 84532, 421614,
];

#[frb(ignore)]
pub fn is_supported_chain(chain_id: u64) -> bool {
    SUPPORTED_CHAINS.contains(&chain_id)
}

/// FFI-safe Uniswap marker. Only the source chain id is needed — the Trading API resolves
/// routers, pools and routing itself. Carried inside [`ExchangeProvider::Uniswap`].
#[derive(Debug, Default, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct UniswapMeta {
    pub chain_id: u64,
}

impl UniswapMeta {
    /// `Some` iff the Trading API supports `chain_id`. Gates `ExchangeProvider::is_support`.
    #[frb(ignore)]
    pub fn for_chain(chain_id: u64) -> Option<Self> {
        is_supported_chain(chain_id).then_some(Self { chain_id })
    }
}

/// Single POST against the Trading API — the one place request headers/error handling live.
#[frb(ignore)]
async fn trading_api_post(client: &Client, path: &str, body: &Value) -> Result<Value, String> {
    let resp = client
        .post(format!("{TRADING_API_BASE}{path}"))
        .header("Content-Type", "application/json")
        .header("x-api-key", TRADING_API_KEY)
        .header("x-universal-router-version", ROUTER_VERSION)
        .json(body)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    let status = resp.status();
    let text = resp.text().await.map_err(|e| e.to_string())?;
    if !status.is_success() {
        return Err(format!("trading-api {path} {status}: {text}"));
    }
    zilpay::serde_json::from_str(&text).map_err(|e| e.to_string())
}

/// Parse the output side of a quote: `"<chainId>:0xaddr"` carries a bridge target chain,
/// plain `"0xaddr"` stays on the source chain. Borrowed → no extra allocation.
#[frb(ignore)]
fn parse_out<'a>(to_asset: &'a str, source_chain: u64) -> (u64, Cow<'a, str>) {
    match to_asset.split_once(':') {
        Some((chain, addr)) if !chain.is_empty() && chain.bytes().all(|b| b.is_ascii_digit()) => {
            (chain.parse().unwrap_or(source_chain), Cow::Borrowed(addr))
        }
        _ => (source_chain, Cow::Borrowed(to_asset)),
    }
}

/// The input token as the API wants it: zero sentinel for native, else the ERC-20 address.
#[frb(ignore)]
fn input_token(is_native_in: bool, token: &str) -> Cow<'_, str> {
    if is_native_in {
        Cow::Borrowed(NATIVE_SENTINEL)
    } else {
        Cow::Borrowed(token)
    }
}

/// `/quote` body. `protocols` (no `routingPreference`) keeps routing on-chain: `CLASSIC`
/// same-chain, `BRIDGE` cross-chain — both return broadcastable calldata. Gasless UniswapX
/// (DUTCH/PRIORITY) is intentionally excluded since it has no on-chain tx to broadcast.
//
// Platform fee: the documented `portionBips`/`portionRecipient` are silently ignored by the
// shared test key, so no fee is taken here. The hosted backend will apply it server-side.
#[frb(ignore)]
fn quote_body(
    swapper: &str,
    token_in: &str,
    token_out: &str,
    in_chain: u64,
    out_chain: u64,
    amount: &str,
    slippage_bps: u32,
) -> Value {
    json!({
        "swapper": swapper,
        "tokenIn": token_in,
        "tokenOut": token_out,
        "tokenInChainId": in_chain,
        "tokenOutChainId": out_chain,
        "amount": amount,
        "type": "EXACT_INPUT",
        "slippageTolerance": f64::from(slippage_bps) / 100.0,
        "protocols": ["V2", "V3", "V4"],
    })
}

/// `quote.output.amount` (present for CLASSIC and BRIDGE routings alike).
#[frb(ignore)]
fn output_amount(resp: &Value) -> Result<String, String> {
    resp.get("quote")
        .and_then(|q| q.get("output"))
        .and_then(|o| o.get("amount"))
        .and_then(Value::as_str)
        .map(str::to_owned)
        .ok_or_else(|| "quote.output.amount missing".to_string())
}

/// Borrow the non-null `permitData` from a quote response, if any.
#[frb(ignore)]
fn permit_value(resp: &Value) -> Option<&Value> {
    resp.get("permitData").filter(|v| !v.is_null())
}

/// Convert the API `permitData` (`{domain, types, values}`) into the standard EIP-712
/// typed-data JSON our signer consumes (`{types(+EIP712Domain), primaryType, domain,
/// message}`). `primaryType` is inferred as the root struct (the one no field references),
/// so this stays generic over the permit shape.
#[frb(ignore)]
fn permit_to_typed_data(permit: &Value) -> Result<String, String> {
    let obj = permit.as_object().ok_or("permitData is not an object")?;
    let domain = obj.get("domain").ok_or("permitData.domain missing")?;
    let types = obj
        .get("types")
        .and_then(Value::as_object)
        .ok_or("permitData.types missing")?;
    let message = obj.get("values").ok_or("permitData.values missing")?;

    let mut referenced: HashSet<&str> = HashSet::with_capacity(types.len());
    for fields in types.values() {
        let Some(arr) = fields.as_array() else { continue };
        for f in arr {
            if let Some(t) = f.get("type").and_then(Value::as_str) {
                referenced.insert(t.trim_end_matches("[]"));
            }
        }
    }
    let primary = types
        .keys()
        .map(String::as_str)
        .find(|k| *k != "EIP712Domain" && !referenced.contains(k))
        .ok_or("cannot infer primaryType")?;

    // Match the EIP-712 shape the signer already accepts: inject EIP712Domain in canonical
    // field order from whichever domain keys are present.
    let mut types_out = types.clone();
    if !types_out.contains_key("EIP712Domain") {
        if let Some(dom) = domain.as_object() {
            let mut entries: Vec<Value> = Vec::with_capacity(dom.len());
            for (key, ty) in [
                ("name", "string"),
                ("version", "string"),
                ("chainId", "uint256"),
                ("verifyingContract", "address"),
                ("salt", "bytes32"),
            ] {
                if dom.contains_key(key) {
                    entries.push(json!({ "name": key, "type": ty }));
                }
            }
            types_out.insert("EIP712Domain".to_string(), Value::Array(entries));
        }
    }

    Ok(json!({
        "types": Value::Object(types_out),
        "primaryType": primary,
        "domain": domain,
        "message": message,
    })
    .to_string())
}

/// Build the `/swap` body: spread the quote response, stripping `permitData`/
/// `permitTransaction`, and (for routings that carry a Permit2 authorization) re-attach the
/// **original** `permitData` together with its `signature` — both present or both absent.
#[frb(ignore)]
fn build_swap_body(quote_resp: &Value, signature: Option<&str>) -> Result<Value, String> {
    let mut obj: Map<String, Value> = quote_resp
        .as_object()
        .ok_or("quote response is not an object")?
        .clone();
    let permit = obj.remove("permitData");
    obj.remove("permitTransaction");
    obj.remove("requestId");

    if let (Some(sig), Some(pd)) = (signature, permit) {
        if !pd.is_null() {
            obj.insert("signature".to_string(), Value::String(sig.to_owned()));
            obj.insert("permitData".to_string(), pd);
        }
    }
    Ok(Value::Object(obj))
}

/// Decimal-or-hex u64 (`gasLimit` is a JSON number; tolerate a hex string too).
#[frb(ignore)]
fn as_u64(v: &Value) -> Option<u64> {
    v.as_u64()
        .or_else(|| v.as_str().and_then(|s| s.parse().ok()))
        .or_else(|| {
            v.as_str()
                .and_then(|s| u64::from_str_radix(s.strip_prefix("0x")?, 16).ok())
        })
}

/// `swap.value` arrives as a `0x` hex string; everything else is a decimal amount string.
#[frb(ignore)]
fn parse_hex_u256(s: &str) -> Result<U256, String> {
    let t = s.strip_prefix("0x").unwrap_or(s);
    if t.is_empty() {
        return Ok(U256::ZERO);
    }
    U256::from_str_radix(t, 16).map_err(|e| e.to_string())
}

/// Validate the `/swap` response and lift it into the FFI tx. `chain_hash` is the source
/// chain that signs and broadcasts; `broadcast: true` matches the existing swap flow.
#[frb(ignore)]
fn swap_response_to_tx(
    resp: &Value,
    swapper: Address,
    chain_hash: u64,
) -> Result<TransactionRequestInfo, String> {
    let swap = resp.get("swap").ok_or("swap field missing")?;
    let to = swap
        .get("to")
        .and_then(Value::as_str)
        .ok_or("swap.to missing")?;
    let data = swap
        .get("data")
        .and_then(Value::as_str)
        .ok_or("swap.data missing")?;
    if data.is_empty() || data == "0x" {
        return Err("swap.data empty — quote expired, refetch".to_string());
    }

    let value = parse_hex_u256(swap.get("value").and_then(Value::as_str).unwrap_or("0x0"))?;
    let input = hex::decode(data.strip_prefix("0x").unwrap_or(data)).map_err(|e| e.to_string())?;

    let mut tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(
            Address::from_str(to).map_err(|e| e.to_string())?,
        )),
        from: Some(swapper),
        value: Some(value),
        input: input.into(),
        gas: swap.get("gasLimit").and_then(as_u64),
        ..Default::default()
    };
    tx.chain_id = swap.get("chainId").and_then(as_u64);

    Ok(TransactionRequest::Ethereum((
        tx,
        TransactionMetadata {
            chain_hash,
            broadcast: true,
            ..Default::default()
        },
    ))
    .into())
}

/// Quote orchestration for the `ExchangeProvider::Uniswap` arm of
/// `crate::api::exchange::fetch_exchange_quote`: hit `/quote` and surface the output amount
/// plus the Permit2 typed data to sign (for ERC-20 inputs on routings that use Permit2).
#[frb(ignore)]
pub async fn uniswap_quote_info(
    meta: &UniswapMeta,
    asset: &ExchangeAsset,
    from_asset: &str,
    to_asset: &str,
    amount: &str,
    destination: &str,
) -> Result<ExchangeQuoteInfo, String> {
    let in_chain = meta.chain_id;
    let (out_chain, tout) = parse_out(to_asset, in_chain);
    let tin = input_token(asset.token.native, from_asset);

    let client = Client::new();
    let body = quote_body(destination, &tin, &tout, in_chain, out_chain, amount, 50);
    let resp = trading_api_post(&client, "/quote", &body).await?;

    let amount_out = output_amount(&resp)?;
    let permit_typed_data_json = match permit_value(&resp) {
        Some(pd) => Some(permit_to_typed_data(pd)?),
        None => None,
    };

    Ok(ExchangeQuoteInfo {
        provider: ExchangeProvider::Uniswap(meta.clone()),
        amount_out,
        permit_typed_data_json,
    })
}

/// Tx-build orchestration for the `ExchangeProvider::Uniswap` arm of
/// `crate::api::exchange::build_exchange_tx`. Re-quotes for freshness (quotes expire in
/// ~30-60s), signs the Permit2 EIP-712 internally when present, calls `/swap`, then returns
/// the unsigned tx for the UI to sign+broadcast.
#[frb(ignore)]
#[allow(clippy::too_many_arguments)]
pub async fn build_uniswap_tx_info(
    wallet_index: usize,
    account_index: usize,
    meta: &UniswapMeta,
    token_in: String,
    token_out: String,
    amount_in: String,
    slippage_bps: u32,
    is_native_in: bool,
    password: Option<String>,
    passphrase: Option<String>,
) -> Result<TransactionRequestInfo, String> {
    let in_chain = meta.chain_id;
    let (out_chain, tout) = parse_out(&token_out, in_chain);
    let tin = input_token(is_native_in, &token_in);

    // Swapper address + the source chain that signs/broadcasts, read under one short guard
    // (no await inside).
    let (swapper, chain_hash) = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        let chain_hash = service
            .core
            .get_providers()
            .into_iter()
            .find(|p| p.config.chain_id() == in_chain)
            .map(|p| p.config.hash())
            .ok_or_else(|| "source chain provider not found".to_string())?;
        let wallet = service
            .core
            .get_wallet_by_index(wallet_index)
            .map_err(ServiceError::BackgroundError)?;
        let data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let account = data
            .get_account(account_index)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        (account.addr.to_alloy_addr(), chain_hash)
    };

    let client = Client::new();
    let quote = trading_api_post(
        &client,
        "/quote",
        &quote_body(
            &swapper.to_string(),
            &tin,
            &tout,
            in_chain,
            out_chain,
            &amount_in,
            slippage_bps,
        ),
    )
    .await?;

    // Sign the Permit2 typed data internally when the routing requires it. The signed JSON
    // is the transformed standard form; the /swap body re-attaches the original permitData.
    let signature: Option<String> = match permit_value(&quote) {
        Some(pd) => {
            let typed_data_json = permit_to_typed_data(pd)?;
            let (_pubkey, sig) = crate::api::transaction::sign_typed_data_eip712(
                wallet_index,
                account_index,
                password,
                passphrase,
                typed_data_json,
                None,
                None,
            )
            .await?;
            Some(sig)
        }
        None => None,
    };

    let swap_req = build_swap_body(&quote, signature.as_deref())?;
    let swap_resp = trading_api_post(&client, "/swap", &swap_req).await?;

    swap_response_to_tx(&swap_resp, swapper, chain_hash)
}

#[cfg(test)]
mod uniswap_tests {
    use super::*;

    #[test]
    fn parse_out_same_chain_plain_addr() {
        let (chain, addr) = parse_out("0xabc", 8453);
        assert_eq!(chain, 8453);
        assert_eq!(addr.as_ref(), "0xabc");
    }

    #[test]
    fn parse_out_cross_chain_prefix() {
        let (chain, addr) = parse_out("42161:0xdef", 8453);
        assert_eq!(chain, 42161);
        assert_eq!(addr.as_ref(), "0xdef");
    }

    #[test]
    fn input_token_native_uses_sentinel() {
        assert_eq!(input_token(true, "0xWETH").as_ref(), NATIVE_SENTINEL);
        assert_eq!(input_token(false, "0xUSDC").as_ref(), "0xUSDC");
    }

    #[test]
    fn permit_to_typed_data_infers_primary_and_message() {
        // Permit2 PermitSingle shape as returned by the Trading API.
        let permit = json!({
            "domain": { "name": "Permit2", "chainId": 1, "verifyingContract": "0x000000000022D473030F116dDEE9F6B43aC78BA3" },
            "types": {
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
            "values": { "spender": "0x66a9", "sigDeadline": "1", "details": {} }
        });
        let out: Value = zilpay::serde_json::from_str(&permit_to_typed_data(&permit).unwrap()).unwrap();
        assert_eq!(out["primaryType"], "PermitSingle");
        assert!(out["message"].is_object());
        // EIP712Domain injected with only the present domain keys, in canonical order.
        let dom = out["types"]["EIP712Domain"].as_array().unwrap();
        let names: Vec<&str> = dom.iter().map(|e| e["name"].as_str().unwrap()).collect();
        assert_eq!(names, ["name", "chainId", "verifyingContract"]);
    }

    #[test]
    fn build_swap_body_strips_and_reattaches_permit() {
        let quote = json!({
            "requestId": "x", "routing": "CLASSIC",
            "permitData": { "domain": {} }, "permitTransaction": null,
            "quote": { "output": { "amount": "1" } }
        });
        // No signature → permit dropped, no signature field.
        let no_sig = build_swap_body(&quote, None).unwrap();
        assert!(no_sig.get("permitData").is_none());
        assert!(no_sig.get("signature").is_none());
        assert!(no_sig.get("requestId").is_none());
        // With signature → both re-attached.
        let with_sig = build_swap_body(&quote, Some("0xsig")).unwrap();
        assert_eq!(with_sig["signature"], "0xsig");
        assert!(with_sig.get("permitData").is_some());
    }

    #[test]
    fn swap_response_to_tx_parses_fields() {
        let resp = json!({ "swap": {
            "to": "0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af",
            "data": "0x1234",
            "value": "0x0de0b6b3a7640000",
            "chainId": 1,
            "gasLimit": 341542
        }});
        let tx = swap_response_to_tx(&resp, Address::ZERO, 42).unwrap();
        let evm = tx.evm.unwrap();
        assert_eq!(evm.chain_id, Some(1));
        assert_eq!(evm.gas_limit, Some(341542));
        assert_eq!(evm.value.as_deref(), Some("1000000000000000000"));
        assert!(evm.data.is_some_and(|d| !d.is_empty()));
    }
}
