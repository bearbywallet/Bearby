use std::sync::Arc;
use zilpay::crypto::slip44;
pub use zilpay::{
    background::Background,
    config::key::{PUB_KEY_SIZE, SECRET_KEY_SIZE},
    proto::{address::Address, pubkey::PubKey, secret_key::SecretKey},
    wallet::{wallet_data::WalletData, Wallet, WalletAddrType},
};
pub use zilpay::{
    background::{bg_provider::ProvidersManagement, bg_wallet::WalletManagement},
    crypto::bip49::DerivationPath,
    errors::{background::BackgroundError, wallet::WalletErrors},
};

use crate::{
    models::{background::BackgroundState, wallet::WalletInfo},
    service::service::BACKGROUND_SERVICE,
};

use super::errors::ServiceError;

pub fn parse_address(addr: String) -> Result<Address, ServiceError> {
    if addr.starts_with("0x") {
        Address::from_eth_address(&addr).map_err(ServiceError::AddressError)
    } else {
        Address::from_zil_bech32(&addr)
            .or_else(|_| Address::from_eth_address(&addr))
            .map_err(ServiceError::AddressError)
    }
}

pub fn decode_session(session_cipher: Option<String>) -> Result<Vec<u8>, ServiceError> {
    hex::decode(session_cipher.unwrap_or_default()).map_err(|_| ServiceError::DecodeSession)
}

pub fn decode_secret_key(sk: &str) -> Result<[u8; SECRET_KEY_SIZE], ServiceError> {
    let sk = sk.strip_prefix("0x").unwrap_or(sk);
    hex::decode(sk)
        .map_err(|_| ServiceError::DecodeSecretKey)?
        .try_into()
        .map_err(|_| ServiceError::InvalidSecretKeyLength)
}

pub fn pubkey_from_provider(pub_key: &str, bip49: DerivationPath) -> Result<PubKey, ServiceError> {
    let pub_key_bytes = decode_public_key(pub_key)?;

    let pub_key = match bip49.slip44 {
        slip44::ZILLIQA => PubKey::Secp256k1Sha256(pub_key_bytes),
        slip44::ETHEREUM => PubKey::Secp256k1Keccak256(pub_key_bytes),
        slip44::BITCOIN => PubKey::Secp256k1Bitcoin(pub_key_bytes),
        slip44::SOLANA => PubKey::Ed25519Solana(pub_key_bytes),
        _ => todo!(),
    };

    Ok(pub_key)
}

pub fn secretkey_from_provider(
    secret_key: &str,
    bip49: DerivationPath,
) -> Result<SecretKey, ServiceError> {
    let sk = secret_key.strip_prefix("0x").unwrap_or(secret_key);
    let secret_key_bytes = decode_secret_key(&sk)?;

    let sk = match bip49.slip44 {
        slip44::ZILLIQA => SecretKey::Secp256k1Sha256Zilliqa(secret_key_bytes),
        slip44::ETHEREUM => SecretKey::Secp256k1Keccak256Ethereum(secret_key_bytes),
        _ => todo!(),
    };

    Ok(sk)
}

pub fn decode_public_key(pub_key: &str) -> Result<[u8; PUB_KEY_SIZE], ServiceError> {
    let pub_key = pub_key.strip_prefix("0x").unwrap_or(pub_key);
    let pub_key_bytes: [u8; PUB_KEY_SIZE] = hex::decode(pub_key)
        .map_err(|_| ServiceError::DecodePublicKey)?
        .try_into()
        .map_err(|_| ServiceError::InvalidPublicKeyLength)?;

    Ok(pub_key_bytes)
}

pub fn get_background_state(service: &Background) -> Result<BackgroundState, ServiceError> {
    let providers = service.get_providers();
    let wallets = service
        .wallets
        .iter()
        .map(|w| w.try_into())
        .collect::<Result<Vec<WalletInfo>, WalletErrors>>()
        .map_err(BackgroundError::WalletError)?;

    let notifications_wallet_states = service
        .settings
        .notifications
        .wallet_states
        .iter()
        .map(|(k, v)| (*k, v.into()))
        .collect();

    Ok(BackgroundState {
        wallets,
        notifications_wallet_states,
        browser_settings: service.settings.browser.clone().into(),
        notifications_global_enabled: service.settings.notifications.global_enabled,
        locale: service.settings.locale.to_string(),
        appearances: service.settings.theme.appearances.code(),
        abbreviated_number: service.settings.theme.compact_numbers,
        providers: providers.into_iter().map(|p| p.config.into()).collect(),
    })
}

pub fn get_last_wallet(service: &Background) -> Result<&Wallet, ServiceError> {
    service.wallets.last().ok_or(ServiceError::FailToSaveWallet)
}

pub async fn with_service<F, T>(f: F) -> Result<T, ServiceError>
where
    F: FnOnce(&zilpay::background::Background) -> Result<T, ServiceError>,
{
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    f(&service.core)
}

pub async fn with_service_mut<F, T>(f: F) -> Result<T, ServiceError>
where
    F: FnOnce(&mut zilpay::background::Background) -> Result<T, ServiceError>,
{
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let core = Arc::get_mut(&mut service.core).ok_or(ServiceError::CoreAccess)?;

        f(core)
    } else {
        Err(ServiceError::NotRunning)
    }
}

pub async fn with_wallet_mut<F, T>(wallet_index: usize, f: F) -> Result<T, ServiceError>
where
    F: FnOnce(&mut Wallet) -> Result<T, ServiceError>,
{
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let core = Arc::get_mut(&mut service.core).ok_or(ServiceError::CoreAccess)?;

        let wallet = core
            .wallets
            .get_mut(wallet_index)
            .ok_or(ServiceError::WalletAccess(wallet_index))?;

        f(wallet)
    } else {
        Err(ServiceError::NotRunning)
    }
}

pub async fn with_wallet<F, T>(wallet_index: usize, f: F) -> Result<T, ServiceError>
where
    F: FnOnce(&Wallet) -> Result<T, ServiceError>,
{
    if let Some(service) = BACKGROUND_SERVICE.read().await.as_ref() {
        let core = Arc::clone(&service.core);
        let wallet = core.get_wallet_by_index(wallet_index)?;

        f(wallet)
    } else {
        Err(ServiceError::NotRunning)
    }
}
