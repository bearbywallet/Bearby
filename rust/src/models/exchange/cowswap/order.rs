//! CoW Protocol Orderbook wire types, CIP-38 amount math, EIP-712 `Order` / `OrderCancellations`
//! typed-data builders, and deterministic `orderUid` computation.

use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{keccak256, Address, B256, U256};
use zilpay::alloy::sol_types::SolValue;
use zilpay::serde::{Deserialize, Serialize};
use zilpay::serde_json::json;

/// Default order validity window in seconds (30 minutes).
pub const DEFAULT_VALID_FOR_SECS: u32 = 1800;

const EIP712_DOMAIN_TYPE_STR: &str =
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
const ORDER_TYPE_STR: &str = "Order(address sellToken,address buyToken,address receiver,uint256 sellAmount,uint256 buyAmount,uint32 validTo,bytes32 appData,uint256 feeAmount,string kind,bool partiallyFillable,string sellTokenBalance,string buyTokenBalance)";

const DOMAIN_NAME: &str = "Gnosis Protocol";
const DOMAIN_VERSION: &str = "v2";

/// `POST /api/v1/quote` request body.
#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
pub struct CowQuoteRequest<'a> {
    pub sell_token: &'a str,
    pub buy_token: &'a str,
    pub receiver: &'a str,
    pub app_data: &'a str,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub app_data_hash: Option<&'a str>,
    pub sell_token_balance: &'static str,
    pub buy_token_balance: &'static str,
    pub from: &'a str,
    pub price_quality: &'static str,
    pub signing_scheme: &'static str,
    #[serde(skip_serializing_if = "std::ops::Not::not")]
    pub onchain_order: bool,
    pub kind: &'static str,
    pub sell_amount_before_fee: &'a str,
    pub valid_for: u32,
}

/// `POST /api/v1/quote` response body.
#[frb(ignore)]
#[derive(Debug, Clone, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
pub struct CowQuoteResponse {
    pub quote: CowQuoteData,
    pub from: Option<String>,
    pub expiration: Option<String>,
    pub id: Option<i64>,
    #[serde(default)]
    pub verified: bool,
    pub protocol_fee_bps: Option<String>,
}

/// Nested `quote` object inside [`CowQuoteResponse`].
#[frb(ignore)]
#[derive(Debug, Clone, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
pub struct CowQuoteData {
    pub sell_token: String,
    pub buy_token: String,
    pub receiver: Option<String>,
    pub sell_amount: String,
    pub buy_amount: String,
    pub valid_to: u32,
    pub app_data: String,
    pub app_data_hash: Option<String>,
    pub fee_amount: String,
    pub kind: String,
    pub partially_fillable: bool,
    pub sell_token_balance: Option<String>,
    pub buy_token_balance: Option<String>,
    pub signing_scheme: Option<String>,
}

/// `POST /api/v1/orders` request body for off-chain EIP-712 signed ERC-20 orders.
#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
pub struct CowOrderCreation {
    pub sell_token: String,
    pub buy_token: String,
    pub receiver: String,
    pub sell_amount: String,
    pub buy_amount: String,
    pub valid_to: u32,
    pub app_data: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub app_data_hash: Option<String>,
    pub fee_amount: String,
    pub kind: String,
    pub partially_fillable: bool,
    pub sell_token_balance: String,
    pub buy_token_balance: String,
    pub signing_scheme: String,
    pub signature: String,
    pub from: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub quote_id: Option<i64>,
}

/// `DELETE /api/v1/orders` request body for off-chain EIP-712 order cancellation.
#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
pub struct CowOrderCancellationRequest {
    pub order_uids: Vec<String>,
    pub signature: String,
    pub signing_scheme: String,
}

/// Minimal response from `GET /api/v1/orders/{uid}` for status polling.
#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
pub struct CowOrderStatusResponse {
    pub uid: Option<String>,
    pub status: String,
    #[serde(default)]
    pub executed_sell_amount: Option<String>,
    #[serde(default)]
    pub executed_buy_amount: Option<String>,
}

/// Computed CoW order amounts per CIP-38 (`getQuoteAmountsAndCosts.ts` + `getOrderToSign.ts`).
#[frb(ignore)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CowComputedAmounts {
    /// Gross sell amount (`quote.sellAmount + quote.feeAmount` = user's input amount).
    pub order_sell_amount: U256,
    /// Expected buy amount after network cost, protocol fee, and partner fee (before slippage).
    /// Displayed in the UI as `ProviderQuote.amount_out`.
    pub expected_buy_amount: U256,
    /// Minimum buy amount after partner fee AND slippage tolerance.
    /// Used as `buyAmount` in the signed `Order` / `EthFlowOrder.Data` with `feeAmount = 0`.
    pub order_buy_amount: U256,
}

/// Compute the CIP-38 / `@cowprotocol/sdk-order-book` amount stages for a SELL order:
/// 1. `quote.sellAmount` and `quote.buyAmount` are returned after network cost (`feeAmount`) with
///    the protocol fee already folded into `quote.buyAmount`.
/// 2. `order_sell_amount = beforeAllFees.sellAmount = sellAmount + feeAmount`.
/// 3. `partnerFeeAmount = (buyAmount * partner_fee_bps) / 10_000`.
/// 4. `expected_buy_amount = afterPartnerFees.buyAmount = buyAmount.saturating_sub(partnerFeeAmount)`.
/// 5. `order_buy_amount = afterSlippage.buyAmount = expected_buy_amount - (expected_buy_amount * slippage_bps) / 10_000`
///    (clamped to `>= 1` so `GPv2Settlement` never rejects a zero `buyAmount`).
#[frb(ignore)]
pub fn compute_cow_amounts(
    resp: &CowQuoteResponse,
    partner_fee_bps: u32,
    slippage_bps: u32,
) -> Result<CowComputedAmounts, String> {
    let sell_amount =
        U256::from_str(&resp.quote.sell_amount).map_err(|e| format!("invalid sellAmount: {e}"))?;
    let buy_amount =
        U256::from_str(&resp.quote.buy_amount).map_err(|e| format!("invalid buyAmount: {e}"))?;
    let fee_amount =
        U256::from_str(&resp.quote.fee_amount).map_err(|e| format!("invalid feeAmount: {e}"))?;

    let order_sell_amount = sell_amount.saturating_add(fee_amount);

    let bps_denom = U256::from(10_000u64);
    let partner_fee_amount =
        buy_amount.saturating_mul(U256::from(partner_fee_bps)) / bps_denom;

    let expected_buy_amount = buy_amount.saturating_sub(partner_fee_amount);
    if expected_buy_amount.is_zero() {
        return Err("quote output is too small to cover fees".to_string());
    }

    let slippage_cut =
        expected_buy_amount.saturating_mul(U256::from(slippage_bps)) / bps_denom;
    let order_buy_amount = expected_buy_amount
        .saturating_sub(slippage_cut)
        .max(U256::from(1u64));

    Ok(CowComputedAmounts {
        order_sell_amount,
        expected_buy_amount,
        order_buy_amount,
    })
}

/// Compute the GPv2Settlement EIP-712 `domainSeparator` for `(chain_id, settlement)`.
#[frb(ignore)]
pub fn domain_separator(chain_id: u64, settlement: Address) -> B256 {
    let type_hash = keccak256(EIP712_DOMAIN_TYPE_STR.as_bytes());
    let name_hash = keccak256(DOMAIN_NAME.as_bytes());
    let version_hash = keccak256(DOMAIN_VERSION.as_bytes());
    let encoded = (
        type_hash,
        name_hash,
        version_hash,
        U256::from(chain_id),
        settlement,
    )
        .abi_encode_params();
    keccak256(&encoded)
}

/// Compute the GPv2Order EIP-712 `structHash` (`hash(order, domainSeparator)` inner struct hash).
/// Note that in EIP-712 (`TypedData`), `string` fields (`kind`, `sellTokenBalance`,
/// `buyTokenBalance`) are hashed as `keccak256(bytes(value))`.
#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub fn order_struct_hash(
    sell_token: Address,
    buy_token: Address,
    receiver: Address,
    sell_amount: U256,
    buy_amount: U256,
    valid_to: u32,
    app_data_hash: B256,
    fee_amount: U256,
    kind: &str,
    partially_fillable: bool,
    sell_token_balance: &str,
    buy_token_balance: &str,
) -> B256 {
    let type_hash = keccak256(ORDER_TYPE_STR.as_bytes());
    let kind_hash = keccak256(kind.as_bytes());
    let sell_bal_hash = keccak256(sell_token_balance.as_bytes());
    let buy_bal_hash = keccak256(buy_token_balance.as_bytes());

    let encoded = (
        type_hash,
        sell_token,
        buy_token,
        receiver,
        sell_amount,
        buy_amount,
        valid_to,
        app_data_hash,
        fee_amount,
        kind_hash,
        partially_fillable,
        sell_bal_hash,
        buy_bal_hash,
    )
        .abi_encode_params();
    keccak256(&encoded)
}

/// Compute the EIP-712 signing digest `keccak256("\x19\x01" || domainSeparator || structHash)`.
#[frb(ignore)]
pub fn eip712_signing_digest(domain_sep: B256, struct_hash: B256) -> B256 {
    let mut buf = [0u8; 66];
    buf[0] = 0x19;
    buf[1] = 0x01;
    buf[2..34].copy_from_slice(domain_sep.as_slice());
    buf[34..66].copy_from_slice(struct_hash.as_slice());
    keccak256(buf)
}

/// Pack a 56-byte CoW `orderUid` (`orderDigest (32B) || owner (20B) || validTo (4B big-endian)`).
#[frb(ignore)]
pub fn pack_order_uid(order_digest: B256, owner: Address, valid_to: u32) -> String {
    let mut uid = [0u8; 56];
    uid[..32].copy_from_slice(order_digest.as_slice());
    uid[32..52].copy_from_slice(owner.as_slice());
    uid[52..56].copy_from_slice(&valid_to.to_be_bytes());
    hex::encode_prefixed(uid)
}

/// Compute the deterministic 56-byte `orderUid` for an on-chain `CoWSwapEthFlow` order.
///
/// Per `EthFlowOrder.toCoWSwapOrder` in `cowprotocol/ethflowcontract`:
/// - `sellToken` =chain's wrapped native token (`WRAPPED_NATIVE_TOKEN`)
/// - `validTo` = `u32::MAX` (`0xffffffff`) in the underlying GPv2Order
/// - `feeAmount` = `0` (in the CIP-38 zero-fee order)
/// - `kind` = `"sell"`, `partiallyFillable` = `false`
/// - `sellTokenBalance` = `"erc20"`, `buyTokenBalance` = `"erc20"`
/// - `owner` = `eth_flow_contract`
#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub fn ethflow_order_uid(
    chain_id: u64,
    settlement: Address,
    eth_flow_contract: Address,
    wrapped_native: Address,
    buy_token: Address,
    receiver: Address,
    sell_amount: U256,
    buy_amount: U256,
    app_data_hash: B256,
) -> String {
    let domain_sep = domain_separator(chain_id, settlement);
    let struct_hash = order_struct_hash(
        wrapped_native,
        buy_token,
        receiver,
        sell_amount,
        buy_amount,
        u32::MAX,
        app_data_hash,
        U256::ZERO,
        "sell",
        false,
        "erc20",
        "erc20",
    );
    let digest = eip712_signing_digest(domain_sep, struct_hash);
    pack_order_uid(digest, eth_flow_contract, u32::MAX)
}

/// Standard EIP-712 typed-data JSON for a CoW `Order`.
/// Compatible with both `core.sign_typed_data_eip712` (Alloy `TypedData`) and Ledger's
/// `prepareEip712Message` + `signEIP712HashedMessage`.
#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub fn order_typed_data_json(
    chain_id: u64,
    settlement: &str,
    sell_token: &str,
    buy_token: &str,
    receiver: &str,
    sell_amount: &str,
    buy_amount: &str,
    valid_to: u32,
    app_data_hash: &str,
) -> String {
    json!({
        "types": {
            "EIP712Domain": [
                { "name": "name", "type": "string" },
                { "name": "version", "type": "string" },
                { "name": "chainId", "type": "uint256" },
                { "name": "verifyingContract", "type": "address" }
            ],
            "Order": [
                { "name": "sellToken", "type": "address" },
                { "name": "buyToken", "type": "address" },
                { "name": "receiver", "type": "address" },
                { "name": "sellAmount", "type": "uint256" },
                { "name": "buyAmount", "type": "uint256" },
                { "name": "validTo", "type": "uint32" },
                { "name": "appData", "type": "bytes32" },
                { "name": "feeAmount", "type": "uint256" },
                { "name": "kind", "type": "string" },
                { "name": "partiallyFillable", "type": "bool" },
                { "name": "sellTokenBalance", "type": "string" },
                { "name": "buyTokenBalance", "type": "string" }
            ]
        },
        "primaryType": "Order",
        "domain": {
            "name": DOMAIN_NAME,
            "version": DOMAIN_VERSION,
            "chainId": chain_id,
            "verifyingContract": settlement
        },
        "message": {
            "sellToken": sell_token,
            "buyToken": buy_token,
            "receiver": receiver,
            "sellAmount": sell_amount,
            "buyAmount": buy_amount,
            "validTo": valid_to,
            "appData": app_data_hash,
            "feeAmount": "0",
            "kind": "sell",
            "partiallyFillable": false,
            "sellTokenBalance": "erc20",
            "buyTokenBalance": "erc20"
        }
    })
    .to_string()
}

/// Standard EIP-712 typed-data JSON for off-chain CoW order cancellation (`OrderCancellations`).
#[frb(ignore)]
pub fn order_cancellation_typed_data_json(
    chain_id: u64,
    settlement: &str,
    order_uid: &str,
) -> String {
    json!({
        "types": {
            "EIP712Domain": [
                { "name": "name", "type": "string" },
                { "name": "version", "type": "string" },
                { "name": "chainId", "type": "uint256" },
                { "name": "verifyingContract", "type": "address" }
            ],
            "OrderCancellations": [
                { "name": "orderUids", "type": "bytes[]" }
            ]
        },
        "primaryType": "OrderCancellations",
        "domain": {
            "name": DOMAIN_NAME,
            "version": DOMAIN_VERSION,
            "chainId": chain_id,
            "verifyingContract": settlement
        },
        "message": {
            "orderUids": [order_uid]
        }
    })
    .to_string()
}

/// CoW Protocol Explorer URL (`https://explorer.cow.fi/.../orders/<order_uid>`) for *chain_id*.
#[frb(ignore)]
pub fn cow_explorer_order_url(chain_id: u64, order_uid: &str) -> String {
    let prefix = match chain_id {
        1 => "",
        100 => "/gc",
        137 => "/pol",
        42161 => "/arb1",
        8453 => "/base",
        43114 => "/avax",
        56 => "/bnb",
        10 => "/opt",
        59144 => "/linea",
        11155111 => "/sepolia",
        _ => "",
    };
    format!("https://explorer.cow.fi{prefix}/orders/{order_uid}")
}

fn parse_u64_json(val: Option<&zilpay::serde_json::Value>) -> Option<u64> {
    let v = val?;
    if let Some(n) = v.as_u64() {
        return Some(n);
    }
    let s = v.as_str()?.trim();
    if let Some(hex_str) = s.strip_prefix("0x").or_else(|| s.strip_prefix("0X")) {
        u64::from_str_radix(hex_str, 16).ok()
    } else {
        s.parse::<u64>().ok()
    }
}

/// Enriches a stored `signed_message` JSON string with `cowOrderUid` and `cowExplorerUrl`
/// when the signed payload is a CoW Protocol (`Gnosis Protocol`) EIP-712 `Order` or `OrderCancellations`.
#[frb(ignore)]
pub fn enrich_cow_signed_message(
    msg: &str,
    fallback_chain_id: u64,
    fallback_signer: Option<&str>,
) -> String {
    use zilpay::alloy::dyn_abi::eip712::TypedData;
    use zilpay::serde_json::Value;

    let Ok(Value::Object(mut root)) = zilpay::serde_json::from_str::<Value>(msg) else {
        return msg.to_string();
    };

    let typed_data_val = match root.get("typedData") {
        Some(Value::Object(_)) => root.get("typedData").cloned(),
        Some(Value::String(s)) => zilpay::serde_json::from_str::<Value>(s).ok(),
        _ => None,
    };
    let Some(typed_data) = typed_data_val else {
        return msg.to_string();
    };

    let domain = typed_data.get("domain");
    let domain_name = domain
        .and_then(|d| d.get("name"))
        .and_then(|v| v.as_str());
    if domain_name != Some(DOMAIN_NAME) {
        return msg.to_string();
    }

    let chain_id = parse_u64_json(domain.and_then(|d| d.get("chainId")))
        .filter(|&id| id > 0)
        .unwrap_or(fallback_chain_id);

    let primary_type = typed_data.get("primaryType").and_then(|v| v.as_str());
    let message = typed_data.get("message");

    let order_uid = match primary_type {
        Some("Order") => {
            let Ok(td) = zilpay::serde_json::from_value::<TypedData>(typed_data.clone()) else {
                return msg.to_string();
            };
            let Ok(digest) = td.eip712_signing_hash() else {
                return msg.to_string();
            };
            let signer_str = root
                .get("signer")
                .and_then(|v| v.as_str())
                .or(fallback_signer)
                .or_else(|| message.and_then(|m| m.get("receiver")).and_then(|v| v.as_str()));
            let Some(owner) = signer_str.and_then(|s| Address::from_str(s.trim()).ok()) else {
                return msg.to_string();
            };
            let Some(valid_to) = parse_u64_json(message.and_then(|m| m.get("validTo")))
                .and_then(|n| u32::try_from(n).ok())
            else {
                return msg.to_string();
            };
            pack_order_uid(digest, owner, valid_to)
        }
        Some("OrderCancellations") => {
            let Some(uid) = message
                .and_then(|m| m.get("orderUids"))
                .and_then(|v| v.as_array())
                .and_then(|arr| arr.first())
                .and_then(|v| v.as_str())
                .filter(|s| !s.is_empty())
            else {
                return msg.to_string();
            };
            uid.to_string()
        }
        _ => return msg.to_string(),
    };

    let explorer_url = cow_explorer_order_url(chain_id, &order_uid);
    root.insert("cowOrderUid".to_string(), Value::String(order_uid));
    root.insert("cowExplorerUrl".to_string(), Value::String(explorer_url));
    zilpay::serde_json::to_string(&Value::Object(root)).unwrap_or_else(|_| msg.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::exchange::cowswap::appdata::build_cow_app_data;
    use crate::models::exchange::cowswap::{COW_ETH_FLOW, GPV2_SETTLEMENT};
    use crate::models::exchange::AppFeeConfig;
    use zilpay::alloy::dyn_abi::eip712::TypedData;
    use zilpay::serde_json;

    #[test]
    fn domain_separator_and_order_struct_hash_match_alloy_typed_data() {
        let settlement = Address::from_str(GPV2_SETTLEMENT).unwrap();
        let sell_token = Address::from_str("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48").unwrap();
        let buy_token = Address::from_str("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2").unwrap();
        let receiver = Address::from_str("0x0000000000000000000000000000000000000001").unwrap();
        let app_data = build_cow_app_data(Some(AppFeeConfig::default_fee()));
        let valid_to = 1_776_759_999u32;

        let json_str = order_typed_data_json(
            1,
            GPV2_SETTLEMENT,
            &sell_token.to_string(),
            &buy_token.to_string(),
            &receiver.to_string(),
            "1000000000",
            "420000000000000000",
            valid_to,
            &app_data.app_data_hash,
        );

        let typed: TypedData = serde_json::from_str(&json_str).expect("valid EIP-712 Order JSON");
        let expected_domain = typed.domain.separator();
        let expected_struct = typed.hash_struct().expect("hash_struct Order");
        let expected_digest = typed.eip712_signing_hash().expect("eip712_signing_hash");

        let manual_domain = domain_separator(1, settlement);
        let manual_struct = order_struct_hash(
            sell_token,
            buy_token,
            receiver,
            U256::from(1_000_000_000u64),
            U256::from(420_000_000_000_000_000u64),
            valid_to,
            app_data.hash_bytes,
            U256::ZERO,
            "sell",
            false,
            "erc20",
            "erc20",
        );
        let manual_digest = eip712_signing_digest(manual_domain, manual_struct);

        assert_eq!(manual_domain, expected_domain);
        assert_eq!(manual_struct, expected_struct);
        assert_eq!(manual_digest, expected_digest);
    }

    #[test]
    fn order_cancellation_typed_data_hashes_cleanly() {
        let uid = format!("0x{}", "ab".repeat(56));
        let json_str = order_cancellation_typed_data_json(1, GPV2_SETTLEMENT, &uid);
        let typed: TypedData =
            serde_json::from_str(&json_str).expect("valid OrderCancellations JSON");
        let digest = typed
            .eip712_signing_hash()
            .expect("eip712_signing_hash OrderCancellations");
        assert_ne!(digest, B256::ZERO);
    }

    #[test]
    fn ethflow_order_uid_has_56_bytes_and_owner_and_max_valid_to() {
        let settlement = Address::from_str(GPV2_SETTLEMENT).unwrap();
        let eth_flow = Address::from_str(COW_ETH_FLOW).unwrap();
        let weth = Address::from_str("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2").unwrap();
        let usdc = Address::from_str("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48").unwrap();
        let receiver = Address::from_str("0x0000000000000000000000000000000000000001").unwrap();
        let app_data = build_cow_app_data(Some(AppFeeConfig::default_fee()));

        let uid = ethflow_order_uid(
            1,
            settlement,
            eth_flow,
            weth,
            usdc,
            receiver,
            U256::from(1_000_000_000_000_000_000u64),
            U256::from(2_300_000_000u64),
            app_data.hash_bytes,
        );

        assert!(uid.starts_with("0x"));
        assert_eq!(uid.len(), 2 + 112); // 56 bytes = 112 hex chars
        assert!(uid.ends_with("ffffffff"));
        let owner_slice = &uid[2 + 64..2 + 104];
        assert!(owner_slice.eq_ignore_ascii_case("bA3cB449bD2B4ADddBc894D8697F5170800EAdeC"));
    }

    #[test]
    fn compute_cow_amounts_matches_cip38_partner_fee_and_slippage_stages() {
        let resp = CowQuoteResponse {
            quote: CowQuoteData {
                sell_token: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2".to_string(),
                buy_token: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48".to_string(),
                receiver: Some("0x0000000000000000000000000000000000000001".to_string()),
                sell_amount: "999738518397848395".to_string(),
                buy_amount: "2320971704".to_string(),
                valid_to: 1_776_759_942,
                app_data: "{}".to_string(),
                app_data_hash: None,
                fee_amount: "261481602151605".to_string(),
                kind: "sell".to_string(),
                partially_fillable: false,
                sell_token_balance: Some("erc20".to_string()),
                buy_token_balance: Some("erc20".to_string()),
                signing_scheme: Some("eip712".to_string()),
            },
            from: None,
            expiration: None,
            id: Some(12345),
            verified: true,
            protocol_fee_bps: Some("2".to_string()),
        };

        let computed = compute_cow_amounts(&resp, 100, 50).unwrap();
        // order_sell_amount = beforeAllFees.sellAmount = sellAmount + feeAmount = 1 ETH
        assert_eq!(
            computed.order_sell_amount,
            U256::from(1_000_000_000_000_000_000u64)
        );
        // protocol fee is already folded into quote.buyAmount (2_320_971_704)
        // partner_fee_amount = 2_320_971_704 * 100 / 10_000 = 23_209_717
        // expected_buy_amount = 2_320_971_704 - 23_209_717 = 2_297_761_987
        assert_eq!(computed.expected_buy_amount, U256::from(2_297_761_987u64));
        // slippage_cut = 2_297_761_987 * 50 / 10_000 = 11_488_809
        // order_buy_amount = 2_297_761_987 - 11_488_809 = 2_286_273_178
        assert_eq!(computed.order_buy_amount, U256::from(2_286_273_178u64));
    }

    #[test]
    fn enrich_cow_signed_message_populates_order_uid_and_explorer_url() {
        let app_data = build_cow_app_data(Some(AppFeeConfig::default_fee()));
        let signer = "0xce106C000000000000000000000000000000dd87";
        let valid_to = 1_776_759_999u32;
        let td_str = order_typed_data_json(
            42161,
            GPV2_SETTLEMENT,
            "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
            "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
            signer,
            "10000000",
            "3000000000000000",
            valid_to,
            &app_data.app_data_hash,
        );
        let td_val: zilpay::serde_json::Value = zilpay::serde_json::from_str(&td_str).unwrap();
        let stored = json!({
            "type": "eth_signTypedData_v4",
            "typedData": td_val,
            "signature": "0x1234",
            "pubKey": "02abcd",
            "signer": signer,
        })
        .to_string();

        let enriched = enrich_cow_signed_message(&stored, 42161, Some(signer));
        let parsed: zilpay::serde_json::Value = zilpay::serde_json::from_str(&enriched).unwrap();
        let uid = parsed["cowOrderUid"].as_str().expect("cowOrderUid present");
        let url = parsed["cowExplorerUrl"].as_str().expect("cowExplorerUrl present");

        assert_eq!(uid.len(), 2 + 112);
        assert_eq!(url, format!("https://explorer.cow.fi/arb1/orders/{uid}"));

        // Non-CoW messages remain untouched
        let plain = r#"{"type":"personal_sign","message":"hello","signature":"0x00","signer":"0x01"}"#;
        assert_eq!(enrich_cow_signed_message(plain, 1, None), plain);
    }
}
