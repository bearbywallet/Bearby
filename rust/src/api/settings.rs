use crate::{
    models::settings::BrowserSettingsInfo,
    utils::{
        errors::ServiceError,
        utils::{with_service_mut, with_wallet, with_wallet_mut},
    },
};
pub use zilpay::settings::{
    notifications::NotificationState,
    theme::{Appearances, Theme},
};
use zilpay::{
    background::{bg_settings::SettingsManagement, bg_storage::StorageManagement},
    wallet::wallet_storage::StorageOperations,
};

pub async fn set_theme(appearances_code: u8, compact_numbers: bool) -> Result<(), String> {
    with_service_mut(|core| {
        let new_theme = Theme {
            compact_numbers,
            appearances: Appearances::from_code(appearances_code)
                .map_err(ServiceError::SettingsError)?,
        };
        core.set_theme(new_theme)
            .map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(Into::into)
}

pub async fn set_wallet_notifications(
    wallet_index: usize,
    transactions: bool,
    price: bool,
    security: bool,
    balance: bool,
) -> Result<(), String> {
    with_service_mut(|core| {
        core.set_wallet_notifications(
            wallet_index,
            NotificationState {
                transactions,
                price,
                security,
                balance,
            },
        )
        .map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(Into::into)
}

pub async fn set_global_notifications(global_enabled: bool) -> Result<(), String> {
    with_service_mut(|core| {
        core.set_global_notifications(global_enabled)
            .map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(Into::into)
}

pub async fn set_rate_fetcher(wallet_index: usize, currency: Option<String>) -> Result<(), String> {
    with_wallet(wallet_index, |wallet| {
        let mut data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        data.settings.features.currency_convert = currency;

        wallet
            .save_wallet_data(data)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}

pub async fn set_wallet_ens(wallet_index: usize, ens_enabled: bool) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        let mut data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        data.settings.features.ens_enabled = ens_enabled;

        wallet
            .save_wallet_data(data)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}

pub async fn set_wallet_ipfs_node(wallet_index: usize, node: Option<String>) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        let mut data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        data.settings.features.ipfs_node = node;

        wallet
            .save_wallet_data(data)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}

pub async fn set_wallet_gas_control(wallet_index: usize, enabled: bool) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        let mut data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        data.settings.network.gas_control_enabled = enabled;

        wallet
            .save_wallet_data(data)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}

pub async fn set_wallet_node_ranking(wallet_index: usize, enabled: bool) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        let mut data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        data.settings.network.node_ranking_enabled = enabled;

        wallet
            .save_wallet_data(data)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}

pub async fn set_browser_settings(browser_settings: BrowserSettingsInfo) -> Result<(), String> {
    with_service_mut(|core| {
        core.settings.browser = browser_settings.into();
        core.save_settings()?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}
