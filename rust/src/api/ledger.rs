pub use zilpay::{
    background::{bg_wallet::WalletManagement, BackgroundLedgerParams},
    settings::wallet_settings::WalletSettings,
    wallet::wallet_account::AccountManagement,
};
pub use zilpay::{proto::pubkey::PubKey, wallet::LedgerParams};

use crate::utils::{
    errors::ServiceError,
    utils::{decode_public_key, decode_session, get_last_wallet, with_service_mut},
};

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_ledger_wallet(
    pub_key: String,
    wallet_index: usize,
    wallet_name: String,
    ledger_id: String,
    account_name: String,
    biometric_type: String,
    identifiers: &[String],
    provider_index: usize,
) -> Result<(String, String), String> {
    with_service_mut(|core| {
        let pub_key_bytes = decode_public_key(&pub_key)?;
        let pub_key = PubKey::Secp256k1Sha256Zilliqa(pub_key_bytes);
        let params = BackgroundLedgerParams {
            provider_index,
            pub_key,
            account_name,
            wallet_index,
            wallet_name,
            ledger_id: ledger_id.as_bytes().to_vec(),
            biometric_type: biometric_type.into(),
            wallet_settings: Default::default(),
            ftokens: vec![], // TODO: add the settings, ftokens, network
        };

        let session = core
            .add_ledger_wallet(params, WalletSettings::default(), identifiers)
            .map_err(ServiceError::BackgroundError)?;
        let wallet = get_last_wallet(core)?;

        Ok((
            hex::encode(session),
            hex::encode(wallet.data.wallet_address),
        ))
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_ledger_account(
    wallet_index: usize,
    account_index: usize,
    name: String,
    pub_key: String,
    identifiers: &[String],
    session_cipher: Option<String>,
) -> Result<(), String> {
    with_service_mut(|core| {
        let session = decode_session(session_cipher)?;

        core.unlock_wallet_with_session(session, identifiers, wallet_index)?;

        let wallet = core
            .wallets
            .get_mut(wallet_index)
            .ok_or(ServiceError::WalletAccess(wallet_index))?;
        let first_account = wallet
            .data
            .accounts
            .first()
            .ok_or(ServiceError::AccountAccess(0, wallet_index))?;

        let pub_key_bytes = decode_public_key(&pub_key)?;
        let pub_key = match first_account.pub_key {
            PubKey::Secp256k1Sha256Zilliqa(_) => PubKey::Secp256k1Sha256Zilliqa(pub_key_bytes),
            PubKey::Secp256k1Keccak256Ethereum(_) => {
                PubKey::Secp256k1Keccak256Ethereum(pub_key_bytes)
            }
            _ => return Err(ServiceError::AccountTypeNotValid),
        };

        wallet
            .add_ledger_account(name, &pub_key, account_index)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}
