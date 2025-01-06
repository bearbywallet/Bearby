pub use zilpay::background::bg_wallet::WalletManagement;

use crate::utils::{
    errors::ServiceError,
    utils::{decode_session, with_service_mut},
};

#[flutter_rust_bridge::frb(dart_async)]
pub async fn try_unlock_with_session(
    session_cipher: String,
    wallet_index: usize,
    identifiers: Vec<String>,
) -> Result<bool, String> {
    let session = decode_session(Some(session_cipher))?;
    with_service_mut(|core| {
        core.unlock_wallet_with_session(session, &identifiers, wallet_index)
            .map_err(ServiceError::BackgroundError)?;

        Ok(true)
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn try_unlock_with_password(
    password: String,
    wallet_index: usize,
    identifiers: Vec<String>,
) -> Result<bool, String> {
    with_service_mut(|core| {
        core.unlock_wallet_with_password(&password, &identifiers, wallet_index)
            .map_err(ServiceError::BackgroundError)?;

        Ok(true)
    })
    .await
    .map_err(Into::into)
}
