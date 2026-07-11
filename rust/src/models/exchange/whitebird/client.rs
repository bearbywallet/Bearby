//! HTTP client for the Bearby WhiteBird proxy.
//!
//! The proxy authenticates against WhiteBird with the merchant `x-api-key`
//! server-side, so the app only ever talks to `wbdev.bearby.ru` (testnet)
//! or `wb.bearby.ru` (mainnet). Errors come back as plain-text bodies.

use std::time::Duration;

use flutter_rust_bridge::frb;
use zilpay::reqwest;
use zilpay::serde::{self, Serialize};
use zilpay::serde_json;

const PROXY_TESTNET: &str = "https://wbdev.bearby.ru";
const PROXY_MAINNET: &str = "https://wb.bearby.ru";

/// WhiteBird API — used directly only for client-token operations the proxy
/// cannot perform (it holds the merchant key, not the user's JWT).
const API_TESTNET: &str = "https://api.dev.wbdevel.net";
/// Placeholder until mainnet is provisioned (provider is testnet-gated).
const API_MAINNET: &str = "https://api.whitebird.io";

const REQUEST_TIMEOUT: Duration = Duration::from_secs(20);

#[must_use]
pub const fn base_url(is_testnet: bool) -> &'static str {
    if is_testnet {
        PROXY_TESTNET
    } else {
        PROXY_MAINNET
    }
}

#[must_use]
pub const fn api_url(is_testnet: bool) -> &'static str {
    if is_testnet {
        API_TESTNET
    } else {
        API_MAINNET
    }
}

#[frb(ignore)]
fn http() -> &'static reqwest::Client {
    static CLIENT: std::sync::OnceLock<reqwest::Client> = std::sync::OnceLock::new();
    CLIENT.get_or_init(reqwest::Client::new)
}

#[frb(ignore)]
async fn decode_response<T: serde::de::DeserializeOwned>(
    url: &str,
    resp: Result<reqwest::Response, reqwest::Error>,
) -> Result<T, String> {
    match resp {
        Ok(r) if r.status().is_success() => {
            let body = r.text().await.map_err(|e| format!("{url}: body {e}"))?;
            serde_json::from_str::<T>(&body).map_err(|e| format!("{url}: decode {e}"))
        }
        Ok(r) => {
            let status = r.status();
            let body = match r.text().await {
                Ok(text) => text,
                Err(e) => format!("body error: {e}"),
            };
            Err(format!("{url}: {status}: {body}"))
        }
        Err(e) => Err(format!("{url}: {e}")),
    }
}

#[frb(ignore)]
pub async fn post_json<T: serde::de::DeserializeOwned>(
    is_testnet: bool,
    path: &str,
    body: &(impl Serialize + Sync),
) -> Result<T, String> {
    let url = format!("{}{path}", base_url(is_testnet));
    let payload = serde_json::to_string(body).map_err(|e| e.to_string())?;
    let resp = http()
        .post(&url)
        .header("content-type", "application/json")
        .timeout(REQUEST_TIMEOUT)
        .body(payload)
        .send()
        .await;
    decode_response(&url, resp).await
}

/// POST straight to the WhiteBird API with the user's client JWT.
/// Returns the raw body on success — some endpoints answer with empty text.
#[frb(ignore)]
pub async fn post_bearer(
    is_testnet: bool,
    path: &str,
    access_token: &str,
    body: &(impl Serialize + Sync),
) -> Result<String, String> {
    let url = format!("{}{path}", api_url(is_testnet));
    let payload = serde_json::to_string(body).map_err(|e| e.to_string())?;
    let resp = http()
        .post(&url)
        .header("content-type", "application/json")
        .header("authorization", format!("Bearer {access_token}"))
        .timeout(REQUEST_TIMEOUT)
        .body(payload)
        .send()
        .await;
    match resp {
        Ok(r) if r.status().is_success() => {
            r.text().await.map_err(|e| format!("{url}: body {e}"))
        }
        Ok(r) => {
            let status = r.status();
            let body = match r.text().await {
                Ok(text) => text,
                Err(e) => format!("body error: {e}"),
            };
            Err(format!("{url}: {status}: {body}"))
        }
        Err(e) => Err(format!("{url}: {e}")),
    }
}
