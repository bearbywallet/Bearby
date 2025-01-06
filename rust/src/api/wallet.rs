use zilpay::token::ft::FToken;
use zilpay::zil_errors::token::TokenError;
pub use zilpay::{
    background::bg_wallet::WalletManagement, wallet::wallet_account::AccountManagement,
};
pub use zilpay::{
    background::{BackgroundBip39Params, BackgroundSKParams},
    crypto::bip49::Bip49DerivationPath,
    proto::{pubkey::PubKey, secret_key::SecretKey},
};

use crate::models::ftoken::FTokenInfo;
use crate::models::settings::WalletSettingsInfo;
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

pub struct Bip39AddWalletParams {
    pub password: String,
    pub mnemonic_str: String,
    pub accounts: Vec<(usize, String)>,
    pub passphrase: String,
    pub wallet_name: String,
    pub biometric_type: String,
    pub provider: usize,
    pub identifiers: Vec<String>,
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_bip39_wallet(
    params: Bip39AddWalletParams,
    wallet_settings: WalletSettingsInfo,
    ftokens: Vec<FTokenInfo>,
) -> Result<(String, String), String> {
    with_service_mut(|core| {
        let accounts_bip39 = params
            .accounts
            .into_iter()
            // TODO: detect network by provider id.
            .map(|(i, name)| (Bip49DerivationPath::Zilliqa(i), name))
            .collect::<Vec<_>>();
        let ftokens = ftokens
            .into_iter()
            .map(TryFrom::try_from)
            .collect::<Result<Vec<FToken>, TokenError>>()?;
        let session = core
            .add_bip39_wallet(BackgroundBip39Params {
                ftokens,
                wallet_settings: wallet_settings.try_into()?,
                provider: params.provider,
                password: &params.password,
                mnemonic_str: &params.mnemonic_str,
                accounts: &accounts_bip39,
                passphrase: &params.passphrase,
                wallet_name: params.wallet_name,
                biometric_type: params.biometric_type.into(),
                device_indicators: &params.identifiers,
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

pub struct AddSKWalletParams {
    pub sk: String,
    pub password: String,
    pub wallet_name: String,
    pub biometric_type: String,
    pub identifiers: Vec<String>,
    pub provider: usize,
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_sk_wallet(
    params: AddSKWalletParams,
    wallet_settings: WalletSettingsInfo,
    ftokens: Vec<FTokenInfo>,
) -> Result<(String, String), String> {
    with_service_mut(|core| {
        let sk = params.sk.strip_prefix("0x").unwrap_or(&params.sk);
        let secret_key = decode_secret_key(&sk)?;
        let ftokens = ftokens
            .into_iter()
            .map(TryFrom::try_from)
            .collect::<Result<Vec<FToken>, TokenError>>()?;
        let secret_key = SecretKey::Secp256k1Sha256Zilliqa(secret_key);
        let session = core.add_sk_wallet(BackgroundSKParams {
            ftokens,
            provider: params.provider,
            secret_key,
            wallet_name: params.wallet_name,
            biometric_type: params.biometric_type.into(),
            password: &params.password,
            device_indicators: &params.identifiers,
            wallet_settings: wallet_settings.try_into()?,
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
    identifiers: Vec<String>,
    password: Option<String>,
    session_cipher: Option<String>,
) -> Result<(), String> {
    with_service_mut(|core| {
        let seed = if let Some(pass) = password {
            core.unlock_wallet_with_password(&pass, &identifiers, wallet_index)
        } else {
            let session = decode_session(session_cipher)?;
            core.unlock_wallet_with_session(session, &identifiers, wallet_index)
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
