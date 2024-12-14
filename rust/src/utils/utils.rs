use std::sync::Arc;
use zilpay::wallet::Wallet;

use crate::{
    models::{background::BackgroundState, wallet::WalletInfo},
    service::service::{ServiceBackground, BACKGROUND_SERVICE},
};

pub enum ServiceError {
    CoreAccess,
    Custom(String),
    MutexLock,
    NotRunning,
    WalletAccess(usize),
}

impl From<ServiceError> for String {
    fn from(err: ServiceError) -> Self {
        match err {
            ServiceError::NotRunning => "Service is not running".to_string(),
            ServiceError::MutexLock => "Failed to acquire lock".to_string(),
            ServiceError::CoreAccess => "Cannot get mutable reference to core".to_string(),
            ServiceError::WalletAccess(idx) => format!("Failed to access wallet at index {}", idx),
            ServiceError::Custom(msg) => msg,
        }
    }
}

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
    hex::decode(session_cipher.unwrap_or_default())
        .map_err(|_| ServiceError::Custom("Invalid Session cipher".to_string()))
}

pub fn get_background_state(service: &ServiceBackground) -> Result<BackgroundState, ServiceError> {
    let wallets = service
        .core
        .wallets
        .iter()
        .map(wallet_info_from_wallet)
        .collect();

    let notifications_wallet_states = service
        .core
        .settings
        .notifications
        .wallet_states
        .iter()
        .map(|(k, v)| (*k, v.into()))
        .collect();

    Ok(BackgroundState {
        wallets,
        notifications_wallet_states,
        notifications_global_enabled: service.core.settings.notifications.global_enabled,
        locale: service.core.settings.locale.to_string(),
        appearances: service.core.settings.theme.appearances.code(),
    })
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

    // Since we need a mutable reference, we need to clone the Arc and try to get exclusive access
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

pub trait IntoServiceError<T> {
    fn service_err(self) -> Result<T, ServiceError>;
}

impl<T, E: ToString> IntoServiceError<T> for Result<T, E> {
    fn service_err(self) -> Result<T, ServiceError> {
        self.map_err(|e| ServiceError::Custom(e.to_string()))
    }
}
