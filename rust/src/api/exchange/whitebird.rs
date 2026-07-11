//! FFI surface for the WhiteBird fiat↔crypto flow.
//!
//! Thin wrappers over `models::exchange::whitebird::orders` — the Dart side
//! owns session tokens and the SDK WebView; Rust only talks to the Bearby
//! proxy (`wbdev.bearby.ru` / `wb.bearby.ru`).

use crate::models::exchange::whitebird::orders::{
    self, WhiteBirdOpenOrder, WhiteBirdSessionInfo,
};

/// Create a WhiteBird exchange session (`POST /api/sessions` on the proxy).
///
/// `from_amount` is a human decimal string. `destination_crypto_address` is the
/// payout address for buys; WhiteBird ignores it for sells but the proxy
/// requires the field, so pass the user's account address either way.
pub async fn whitebird_create_session(
    is_testnet: bool,
    from_code: String,
    to_code: String,
    from_amount: String,
    destination_crypto_address: String,
    external_client_id: String,
) -> Result<WhiteBirdSessionInfo, String> {
    orders::create_session(
        is_testnet,
        from_code.as_str(),
        to_code.as_str(),
        from_amount.as_str(),
        destination_crypto_address.as_str(),
        external_client_id.as_str(),
    )
    .await
}

/// List open PROCESSING orders for the exchange-page badge/modal.
pub async fn whitebird_open_orders(
    is_testnet: bool,
    external_client_id: String,
    client_id: Option<String>,
) -> Result<Vec<WhiteBirdOpenOrder>, String> {
    orders::open_orders(
        is_testnet,
        client_id.as_deref(),
        external_client_id.as_str(),
    )
    .await
}
