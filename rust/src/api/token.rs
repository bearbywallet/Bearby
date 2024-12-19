use crate::{
    service::service::BACKGROUND_SERVICE,
    utils::{errors::ServiceError, utils::parse_address},
};
use std::sync::Arc;
pub use zilpay::{proto::address::Address, wallet::ft::FToken};

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
pub async fn fetch_token_meta(addr: String, wallet_index: usize) -> Result<FToken, String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let core = Arc::get_mut(&mut service.core).ok_or(ServiceError::CoreAccess)?;
        let address = parse_address(addr)?;

        let token_meta = core
            .get_ftoken_meta(wallet_index, address)
            .await
            .map_err(ServiceError::BackgroundError)?;

        Ok(token_meta)
    } else {
        Err(ServiceError::NotRunning.to_string())
    }
}
