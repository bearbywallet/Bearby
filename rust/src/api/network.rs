use crate::models::provider::NetworkConfigInfo;
use crate::utils::errors::ServiceError;
use crate::utils::utils::{with_service, with_service_mut};

pub use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_wallet::WalletManagement;
pub use zilpay::background::{bg_rates::RatesManagement, bg_token::TokensManagement};
pub use zilpay::errors::background::BackgroundError;
pub use zilpay::proto::address::Address;
pub use zilpay::wallet::wallet_storage::StorageOperations;

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_providers() -> Result<Vec<NetworkConfigInfo>, String> {
    with_service(|core| {
        let providers_config = core
            .providers
            .iter()
            .map(|v| v.config.clone().into())
            .collect::<Vec<NetworkConfigInfo>>();

        Ok(providers_config)
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_provider(provider_index: usize) -> Result<NetworkConfigInfo, String> {
    with_service(|core| {
        let provider = core.get_provider(provider_index)?;

        Ok(provider.config.clone().into())
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_provider(config: NetworkConfigInfo) -> Result<(), String> {
    with_service_mut(|core| {
        core.add_provider(config.try_into()?)?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn remove_provider(provider_index: usize) -> Result<(), String> {
    with_service_mut(|core| {
        core.remvoe_providers(provider_index)?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn select_provider(provider_index: usize, wallet_index: usize) -> Result<(), String> {
    with_service_mut(|core| {
        core.get_provider(provider_index)?;

        let wallet = core.get_wallet_by_index(wallet_index)?;
        let mut data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        data.accounts
            .get_mut(data.selected_account)
            .map(|acc| acc.provider_index = provider_index);
        wallet
            .save_wallet_data(data)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}
