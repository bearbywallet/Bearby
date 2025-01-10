use std::sync::Arc;
use zilpay::{
    background::Background,
    config::key::{PUB_KEY_SIZE, SECRET_KEY_SIZE},
    crypto::bip49::Bip49DerivationPath,
    proto::{address::Address, pubkey::PubKey, secret_key::SecretKey},
    wallet::Wallet,
};

use crate::{
    models::{background::BackgroundState, wallet::WalletInfo},
    service::service::BACKGROUND_SERVICE,
};

use super::errors::ServiceError;

pub fn parse_address(addr: String) -> Result<Address, ServiceError> {
    Address::from_zil_base16(&addr)
        .or_else(|_| Address::from_zil_bech32(&addr))
        .or_else(|_| Address::from_eth_address(&addr))
        .map_err(ServiceError::AddressError)
}

pub fn wallet_info_from_wallet(w: &Wallet) -> WalletInfo {
    WalletInfo {
        provider: w.data.provider_index,
        auth_type: w.data.biometric_type.clone().into(),
        wallet_name: w.data.wallet_name.clone(),
        wallet_type: w.data.wallet_type.to_str(),
        wallet_address: format!("0x{}", hex::encode(w.data.wallet_address)),
        accounts: w.data.accounts.iter().map(|v| v.into()).collect(),
        selected_account: w.data.selected_account,
        tokens: w.ftokens.clone().into_iter().map(|v| v.into()).collect(),
        settings: w.data.settings.clone().into(),
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

pub fn pubkey_from_provider(
    pub_key: &str,
    bip49: Bip49DerivationPath,
) -> Result<PubKey, ServiceError> {
    let pub_key_bytes = decode_public_key(pub_key)?;

    let pub_key = match bip49 {
        Bip49DerivationPath::Zilliqa(_) => PubKey::Secp256k1Sha256Zilliqa(pub_key_bytes),
        Bip49DerivationPath::Ethereum(_) => PubKey::Secp256k1Keccak256Ethereum(pub_key_bytes),
        Bip49DerivationPath::Bitcoin(_) => PubKey::Secp256k1Bitcoin(pub_key_bytes),
        Bip49DerivationPath::Solana(_) => PubKey::Ed25519Solana(pub_key_bytes),
    };

    Ok(pub_key)
}

pub fn secretkey_from_provider(
    secret_key: &str,
    bip49: Bip49DerivationPath,
) -> Result<SecretKey, ServiceError> {
    let sk = secret_key.strip_prefix("0x").unwrap_or(secret_key);
    let secret_key_bytes = decode_secret_key(&sk)?;

    let sk = match bip49 {
        Bip49DerivationPath::Zilliqa(_) => SecretKey::Secp256k1Sha256Zilliqa(secret_key_bytes),
        Bip49DerivationPath::Ethereum(_) => SecretKey::Secp256k1Keccak256Ethereum(secret_key_bytes),
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
    let wallets: Vec<WalletInfo> = service
        .wallets
        .iter()
        .map(wallet_info_from_wallet)
        .collect();

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
        notifications_global_enabled: service.settings.notifications.global_enabled,
        locale: service.settings.locale.to_string(),
        appearances: service.settings.theme.appearances.code(),
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
