use std::sync::Arc;
use zilpay::{
    background::Background,
    config::key::{PUB_KEY_SIZE, SECRET_KEY_SIZE},
    wallet::Wallet,
};

use crate::{
    models::{background::BackgroundState, wallet::WalletInfo},
    service::service::BACKGROUND_SERVICE,
};

use super::errors::ServiceError;

pub fn wallet_info_from_wallet(w: &Wallet) -> WalletInfo {
    WalletInfo {
        networks: w.data.network.clone(),
        auth_type: w.data.biometric_type.clone().into(),
        wallet_name: w.data.wallet_name.clone(),
        wallet_type: w.data.wallet_type.to_str(),
        wallet_address: w.data.wallet_address.clone(),
        accounts: w.data.accounts.iter().map(|v| v.into()).collect(),
        selected_account: w.data.selected_account,
        tokens: w.ftokens.iter().map(|v| v.into()).collect(),
        cipher_orders: w
            .data
            .settings
            .cipher_orders
            .iter()
            .map(|v| v.code())
            .collect(),
        currency_convert: w.data.settings.features.currency_convert.clone(),
        ipfs_node: w.data.settings.features.ipfs_node.clone(),
        ens_enabled: w.data.settings.features.ens_enabled,
        gas_control_enabled: w.data.settings.network.gas_control_enabled,
        node_ranking_enabled: w.data.settings.network.node_ranking_enabled,
        max_connections: w.data.settings.network.max_connections,
        request_timeout_secs: w.data.settings.network.request_timeout_secs,
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
    let guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    let mut core_arc = service.core.clone();
    let core = Arc::get_mut(&mut core_arc).ok_or(ServiceError::CoreAccess)?;

    f(core)
}

pub async fn with_wallet_mut<F, T>(wallet_index: usize, f: F) -> Result<T, ServiceError>
where
    F: FnOnce(&mut Wallet) -> Result<T, ServiceError>,
{
    let guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    let mut core_arc = service.core.clone();
    let core = Arc::get_mut(&mut core_arc).ok_or(ServiceError::CoreAccess)?;

    let wallet = core
        .wallets
        .get_mut(wallet_index)
        .ok_or(ServiceError::WalletAccess(wallet_index))?;

    f(wallet)
}
