//! Session creation and open-order tracking via the Bearby proxy.

use flutter_rust_bridge::frb;
use zilpay::serde::Deserialize;
use zilpay::serde_json::{json, Map, Value};

use super::client;

/// Result of `POST /api/sessions` — pre-calculated exchange context.
#[derive(Debug, Clone)]
pub struct WhiteBirdSessionInfo {
    pub session_id: String,
    /// Ready-to-open SDK URL (informational; the app embeds via the JS SDK).
    pub sdk_url: String,
    pub from_net_amount: String,
    pub to_net_amount: String,
    pub limit_min: String,
    pub limit_max: String,
}

/// Open (PROCESSING) order for the exchange-page badge/modal.
#[derive(Debug, Clone)]
pub struct WhiteBirdOpenOrder {
    pub order_id: String,
    pub number: Option<String>,
    pub from_asset: String,
    pub to_asset: String,
    /// Human decimal amounts as reported by WhiteBird.
    pub from_amount: String,
    pub to_amount: String,
    pub status: String,
    /// `true` when the input leg is a crypto transfer (sell order).
    pub is_sell: bool,
    /// Deposit address awaiting the user's crypto (sell orders only).
    pub deposit_address: Option<String>,
    /// `true` once WhiteBird has seen the incoming crypto transaction.
    pub crypto_received: bool,
    pub created_at: String,
    pub expires_at: Option<String>,
    /// WhiteBird client uuid — persisted by Dart for future history lookups.
    pub client_id: String,
}

#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct SessionExchangeBody {
    #[serde(default)]
    from_net_amount: String,
    #[serde(default)]
    to_net_amount: String,
}

#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct SessionLimitBody {
    #[serde(default)]
    min: String,
    #[serde(default)]
    max: String,
}

#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct SessionSdkBody {
    #[serde(default)]
    url: String,
}

#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct SessionBody {
    session_id: String,
    exchange: SessionExchangeBody,
    limit: SessionLimitBody,
    sdk: SessionSdkBody,
}

/// Create an exchange session (`POST /api/sessions`). `from_amount` is a human
/// decimal string; `destination_crypto_address` is the payout address for buys
/// and ignored by WhiteBird for sells (the proxy requires the field either way).
#[frb(ignore)]
pub async fn create_session(
    is_testnet: bool,
    from_code: &str,
    to_code: &str,
    from_amount: &str,
    destination_crypto_address: &str,
    external_client_id: &str,
) -> Result<WhiteBirdSessionInfo, String> {
    let body = json!({
        "fromAsset": from_code,
        "fromAmount": from_amount,
        "toAsset": to_code,
        "destinationCryptoAddress": destination_crypto_address,
        "externalClientId": external_client_id,
    });
    eprintln!(
        "[whitebird] create session {from_code}->{to_code} amount={from_amount} client={external_client_id}"
    );
    let resp: SessionBody = client::post_json(is_testnet, "/api/sessions", &body).await?;
    Ok(WhiteBirdSessionInfo {
        session_id: resp.session_id,
        sdk_url: resp.sdk.url,
        from_net_amount: resp.exchange.from_net_amount,
        to_net_amount: resp.exchange.to_net_amount,
        limit_min: resp.limit.min,
        limit_max: resp.limit.max,
    })
}

fn str_field(value: &Value, key: &str) -> Option<String> {
    match value.get(key) {
        Some(Value::String(s)) if !s.is_empty() => Some(s.clone()),
        Some(Value::Number(n)) => Some(n.to_string()),
        _ => None,
    }
}

fn parse_order(item: &Value) -> Option<WhiteBirdOpenOrder> {
    let order_id = str_field(item, "id")?;
    let conditions = item.get("conditions")?;
    let input = item.get("input")?;
    let input_type = str_field(input, "type").unwrap_or_default();
    let input_status = str_field(input, "status").unwrap_or_default();
    let is_sell = input_type == "CRYPTO_TRANSFER";
    // A sell input sits in PROCESSING while *waiting* for the deposit — only a
    // transaction hash or a terminal status proves the crypto actually arrived.
    let crypto_received = is_sell
        && (str_field(input, "hash").is_some() || input_status == "COMPLETED");
    Some(WhiteBirdOpenOrder {
        number: str_field(item, "number"),
        from_asset: str_field(conditions, "fromAsset").unwrap_or_default(),
        to_asset: str_field(conditions, "toAsset").unwrap_or_default(),
        from_amount: str_field(conditions, "fromGrossAmount").unwrap_or_default(),
        to_amount: str_field(conditions, "toNetAmount").unwrap_or_default(),
        status: str_field(item, "status").unwrap_or_default(),
        is_sell,
        deposit_address: is_sell.then(|| str_field(input, "toAddress")).flatten(),
        crypto_received,
        created_at: str_field(item, "creationDate").unwrap_or_default(),
        expires_at: str_field(input, "expirationDate"),
        client_id: str_field(item, "clientId").unwrap_or_default(),
        order_id,
    })
}

/// Cancel an active order with the user's client JWT
/// (`POST /api/v3/exchange/client/order/{id}/reject` on the WhiteBird API —
/// the same call the SDK's "cancel order" button makes; there is no
/// merchant-key equivalent).
#[frb(ignore)]
pub async fn reject_order(
    is_testnet: bool,
    order_id: &str,
    access_token: &str,
) -> Result<(), String> {
    let path = format!("/api/v3/exchange/client/order/{order_id}/reject");
    eprintln!("[whitebird] reject order {order_id}");
    let body = json!({ "requestBody": {} });
    client::post_bearer(is_testnet, path.as_str(), access_token, &body)
        .await
        .map(|_| ())
}

/// List open PROCESSING orders (`POST /api/orders/history`).
///
/// Prefers `clientIds: [uuid]` (stage often 401s on `externalClientId`);
/// never filters status `NEW` — stage returns an empty 400 for it.
#[frb(ignore)]
pub async fn open_orders(
    is_testnet: bool,
    client_id: Option<&str>,
    external_client_id: &str,
) -> Result<Vec<WhiteBirdOpenOrder>, String> {
    let mut body = Map::new();
    match client_id.filter(|s| !s.is_empty()) {
        Some(cid) => {
            body.insert("clientIds".to_owned(), json!([cid]));
        }
        None => {
            body.insert(
                "externalClientId".to_owned(),
                Value::String(external_client_id.to_owned()),
            );
        }
    }
    body.insert("statuses".to_owned(), json!(["PROCESSING"]));

    let resp: Value = client::post_json(is_testnet, "/api/orders/history", &body).await?;
    let content = resp.get("content").and_then(Value::as_array);
    let orders = content.map_or_else(Vec::new, |items| {
        items.iter().filter_map(parse_order).collect()
    });
    eprintln!(
        "[whitebird] open orders client={client_id:?} external={external_client_id} count={}",
        orders.len()
    );
    Ok(orders)
}
