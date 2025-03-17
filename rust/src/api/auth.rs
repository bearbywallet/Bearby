use crate::utils::utils::{decode_session, with_service};
pub use zilpay::background::bg_wallet::WalletManagement;

pub async fn try_unlock_with_session(
    session_cipher: String,
    wallet_index: usize,
    identifiers: Vec<String>,
) -> Result<bool, String> {
    let session = decode_session(Some(session_cipher))?;
    with_service(|core| {
        core.unlock_wallet_with_session(session, &identifiers, wallet_index)?;

        Ok(true)
    })
    .await
    .map_err(Into::into)
}

pub async fn try_unlock_with_password(
    password: String,
    wallet_index: usize,
    identifiers: Vec<String>,
) -> Result<bool, String> {
    with_service(|core| {
        core.unlock_wallet_with_password(&password, &identifiers, wallet_index)?;

        Ok(true)
    })
    .await
    .map_err(Into::into)
}
