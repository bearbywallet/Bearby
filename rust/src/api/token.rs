use crate::{
    models::ftoken::FTokenInfo,
    service::service::BACKGROUND_SERVICE,
    utils::{errors::ServiceError, utils::parse_address},
};
use std::sync::Arc;
pub use zilpay::background::{bg_rates::RatesManagement, bg_token::TokensManagement};
pub use zilpay::proto::address::Address;

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sync_balances(wallet_index: usize) -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let core = Arc::get_mut(&mut service.core).ok_or(ServiceError::CoreAccess)?;

        core.sync_ftokens_balances(wallet_index)
            .await
            .map_err(ServiceError::BackgroundError)?;

        Ok(())
    } else {
        Err(ServiceError::NotRunning.to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn update_rates() -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.read().await.as_ref() {
        let core = Arc::clone(&service.core);

        core.update_rates()
            .await
            .map_err(ServiceError::BackgroundError)?;

        Ok(())
    } else {
        Err(ServiceError::NotRunning.to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_rates() -> Result<String, String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let core = Arc::get_mut(&mut service.core).ok_or(ServiceError::CoreAccess)?;
        let value = core.get_rates();

        Ok(value.to_string())
    } else {
        Err(ServiceError::NotRunning.to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn update_token_list(_net: usize) -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let _core = Arc::get_mut(&mut service.core).ok_or(ServiceError::CoreAccess)?;

        // TODO: add fetch tokens from ZilPay server.

        Ok(())
    } else {
        Err(ServiceError::NotRunning.to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn fetch_token_meta(addr: String, wallet_index: usize) -> Result<FTokenInfo, String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let core = Arc::get_mut(&mut service.core).ok_or(ServiceError::CoreAccess)?;
        let address = parse_address(addr)?;

        let token_meta = core
            .fetch_ftoken_meta(wallet_index, address)
            .await
            .map_err(ServiceError::BackgroundError)?;

        Ok(token_meta.into())
    } else {
        Err(ServiceError::NotRunning.to_string())
    }
}
