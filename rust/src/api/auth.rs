use crate::{
    service::service::BACKGROUND_SERVICE,
    utils::{errors::ServiceError, utils::decode_session},
};
pub use zilpay::background::bg_wallet::WalletManagement;

pub async fn try_unlock_with_session(
    session_cipher: Option<String>,
    wallet_index: usize,
    identifiers: Vec<String>,
) -> Result<bool, String> {
    let session = decode_session(session_cipher)?;
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    service
        .core
        .unlock_wallet_with_session(session, &identifiers, wallet_index)
        .await
        .map_err(ServiceError::BackgroundError)?;

    Ok(true)
}

pub async fn try_unlock_with_password(
    password: String,
    wallet_index: usize,
    identifiers: Vec<String>,
) -> Result<bool, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    service
        .core
        .unlock_wallet_with_password(&password, &identifiers, wallet_index)
        .map_err(ServiceError::BackgroundError)?;

    Ok(true)
}
