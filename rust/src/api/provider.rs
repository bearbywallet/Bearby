use crate::{
    models::provider::NetworkConfigInfo,
    utils::utils::{with_service, with_service_mut},
};
use zilpay::background::bg_provider::ProvidersManagement;
pub use zilpay::settings::{
    notifications::NotificationState,
    theme::{Appearances, Theme},
};
pub use zilpay::{
    background::bg_settings::SettingsManagement, wallet::wallet_storage::StorageOperations,
};

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_providers() -> Result<Vec<NetworkConfigInfo>, String> {
    with_service(|core| {
        Ok(core
            .providers
            .iter()
            .map(|p| p.config.clone().into())
            .collect::<Vec<NetworkConfigInfo>>())
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
pub async fn add_provider(provider_config: NetworkConfigInfo) -> Result<(), String> {
    with_service_mut(|core| {
        core.add_provider(provider_config.try_into()?)?;
        Ok(())
    })
    .await
    .map_err(Into::into)
}
