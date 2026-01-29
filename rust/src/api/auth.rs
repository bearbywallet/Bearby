use crate::{service::service::BACKGROUND_SERVICE, utils::errors::ServiceError};
use secrecy::{zeroize::Zeroize, SecretString};
pub use zilpay::background::bg_wallet::WalletManagement;
use zilpay::session;

pub async fn try_unlock_with_session(wallet_index: usize) -> Result<bool, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    service
        .core
        .unlock_wallet_with_session(wallet_index)
        .await
        .map_err(ServiceError::BackgroundError)?;

    Ok(true)
}

pub async fn try_unlock_with_password(
    password: String,
    wallet_index: usize,
    identifiers: Option<Vec<String>>,
) -> Result<bool, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let mut password = SecretString::new(password.into());

    service
        .core
        .unlock_wallet_with_password(&password, identifiers.as_deref(), wallet_index)
        .map_err(ServiceError::BackgroundError)?;

    password.zeroize();

    Ok(true)
}

pub async fn get_biometric_type() -> Result<Vec<String>, String> {
    Ok(session::keychain_store::device_biometric_type()
        .map_err(|e| e.to_string())?
        .into_iter()
        .map(|v| v.into())
        .collect())
}
