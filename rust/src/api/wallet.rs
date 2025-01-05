pub use zilpay::{
    background::bg_wallet::WalletManagement, wallet::wallet_account::AccountManagement,
};
pub use zilpay::{
    background::{BackgroundBip39Params, BackgroundSKParams},
    crypto::bip49::Bip49DerivationPath,
    proto::{pubkey::PubKey, secret_key::SecretKey},
};

use crate::{
    models::wallet::WalletInfo,
    utils::{
        errors::ServiceError,
        utils::{
            decode_secret_key, decode_session, wallet_info_from_wallet, with_service,
            with_service_mut, with_wallet_mut,
        },
    },
};

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_wallets() -> Result<Vec<WalletInfo>, String> {
    with_service(|core| Ok(core.wallets.iter().map(wallet_info_from_wallet).collect()))
        .await
        .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_bip39_wallet(
    password: String,
    mnemonic_str: String,
    accounts: &[(usize, String)],
    passphrase: String,
    wallet_name: String,
    biometric_type: String,
    provider: usize,
    identifiers: &[String],
    // TODO: add params with ftokens and provder config.
) -> Result<(String, String), String> {
    with_service_mut(|core| {
        let accounts_bip39 = accounts
            .iter()
            .map(|(i, name)| (Bip49DerivationPath::Zilliqa(*i), name.clone()))
            .collect::<Vec<_>>();
        let session = core
            .add_bip39_wallet(BackgroundBip39Params {
                provider,
                password: &password,
                mnemonic_str: &mnemonic_str,
                accounts: &accounts_bip39,
                passphrase: &passphrase,
                wallet_name,
                biometric_type: biometric_type.into(),
                device_indicators: identifiers,
                wallet_settings: Default::default(),
                ftokens: vec![],
            })
            .map_err(ServiceError::BackgroundError)?;
        let wallet = core.wallets.last().ok_or(ServiceError::FailToSaveWallet)?;

        Ok((
            hex::encode(session),
            hex::encode(wallet.data.wallet_address),
        ))
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_sk_wallet(
    sk: String,
    password: String,
    wallet_name: String,
    biometric_type: String,
    identifiers: &[String],
    provider: usize,
    // TODO: add params with ftokens and provder config.
) -> Result<(String, String), String> {
    with_service_mut(|core| {
        let sk = sk.strip_prefix("0x").unwrap_or(&sk);
        let secret_key = decode_secret_key(&sk)?;

        let secret_key = SecretKey::Secp256k1Sha256Zilliqa(secret_key);
        let session = core.add_sk_wallet(BackgroundSKParams {
            provider,
            secret_key,
            wallet_name,
            biometric_type: biometric_type.into(),
            password: &password,
            device_indicators: identifiers,
            wallet_settings: Default::default(),
            ftokens: vec![],
        })?;
        let wallet = core.wallets.last().ok_or(ServiceError::FailToSaveWallet)?;

        Ok((
            hex::encode(session),
            hex::encode(wallet.data.wallet_address),
        ))
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_next_bip39_account(
    wallet_index: usize,
    account_index: usize,
    name: String,
    passphrase: String,
    identifiers: &[String],
    password: Option<String>,
    session_cipher: Option<String>,
) -> Result<(), String> {
    with_service_mut(|core| {
        let seed = if let Some(pass) = password {
            core.unlock_wallet_with_password(&pass, identifiers, wallet_index)
        } else {
            let session = decode_session(session_cipher)?;
            core.unlock_wallet_with_session(session, identifiers, wallet_index)
        }
        .map_err(ServiceError::BackgroundError)?;

        let wallet = core
            .wallets
            .get_mut(wallet_index)
            .ok_or(ServiceError::WalletAccess(wallet_index))?;

        let first_account = wallet
            .data
            .accounts
            .first()
            .ok_or(ServiceError::AccountAccess(0, wallet_index))?;

        let bip49 = match first_account.pub_key {
            PubKey::Secp256k1Sha256Zilliqa(_) => Bip49DerivationPath::Zilliqa(account_index),
            PubKey::Secp256k1Keccak256Ethereum(_) => Bip49DerivationPath::Ethereum(account_index),
            _ => return Err(ServiceError::AccountTypeNotValid),
        };

        wallet
            .add_next_bip39_account(name, &bip49, &passphrase, &seed)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn select_account(wallet_index: usize, account_index: usize) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        wallet
            .select_account(account_index)
            .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))
    })
    .await
    .map_err(Into::into)
}
