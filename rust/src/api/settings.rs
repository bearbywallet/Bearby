use crate::{
    models::settings::BrowserSettingsInfo,
    utils::{
        errors::ServiceError,
        utils::{with_service, with_wallet},
    },
};
pub use zilpay::settings::{
    notifications::NotificationState,
    theme::{Appearances, Theme},
};
use zilpay::{
    background::bg_settings::SettingsManagement, settings::wallet_settings::TokenQuotesAPIOptions,
    wallet::wallet_storage::StorageOperations,
};

pub async fn set_theme(appearances_code: u8, compact_numbers: bool) -> Result<(), String> {
    with_service(|core| {
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
    with_service(|core| {
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
    with_service(|core| {
        core.set_global_notifications(global_enabled)
            .map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(Into::into)
}

pub async fn set_default_locale(locale: Option<String>) -> Result<(), String> {
    with_service(|core| {
        core.set_locale(locale)?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

pub async fn set_rate_fetcher(wallet_index: usize, currency: String) -> Result<(), String> {
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

pub async fn set_rate_engine(wallet_index: usize, engine_code: u8) -> Result<(), String> {
    with_wallet(wallet_index, |wallet| {
        let mut data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        data.settings.rates_api_options = TokenQuotesAPIOptions::from_code(engine_code);

        wallet
            .save_wallet_data(data)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}

pub async fn set_wallet_ens(wallet_index: usize, ens_enabled: bool) -> Result<(), String> {
    with_wallet(wallet_index, |wallet| {
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
    with_wallet(wallet_index, |wallet| {
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

pub async fn set_tokens_list_fetcher(wallet_index: usize, enabled: bool) -> Result<(), String> {
    with_wallet(wallet_index, |wallet| {
        let mut data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        data.settings.network.tokens_list_fetcher = enabled;

        wallet
            .save_wallet_data(data)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}

pub async fn set_wallet_node_ranking(wallet_index: usize, enabled: bool) -> Result<(), String> {
    with_wallet(wallet_index, |wallet| {
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
    with_service(|core| {
        core.set_browser_settings(browser_settings.into())?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}
