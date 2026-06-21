use crate::utils::{errors::ServiceError, helpers::handle};
pub use zilpay::background::bg_wallet::WalletManagement;
use zilpay::secrecy::SecretString;
use zilpay::session;

pub async fn try_unlock_with_session(wallet_index: usize) -> Result<bool, String> {
    let core = handle()?;

    core.unlock_wallet_with_session(wallet_index)
        .await
        .map_err(ServiceError::BackgroundError)?;

    Ok(true)
}

pub async fn try_unlock_with_password(
    password: String,
    wallet_index: usize,
    identifiers: Option<Vec<String>>,
) -> Result<bool, String> {
    let core = handle()?;
    let password = SecretString::new(password.into());

    core.unlock_wallet_with_password(&password, identifiers.as_deref(), wallet_index)
        .await
        .map_err(ServiceError::BackgroundError)?;

    Ok(true)
}

pub async fn get_biometric_type() -> Result<Vec<String>, String> {
    Ok(session::keychain_store::device_biometric_type()
        .map_err(|e| e.to_string())?
        .into_iter()
        .map(|v| v.into())
        .collect())
}
