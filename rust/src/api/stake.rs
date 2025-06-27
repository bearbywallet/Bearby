use std::sync::Arc;

use zilpay::{
    background::{bg_provider::ProvidersManagement, bg_wallet::WalletManagement},
    errors::wallet::WalletErrors,
    network::stake::ZilliqaStakeing,
    wallet::wallet_storage::StorageOperations,
};

use crate::{
    models::stake::FinalOutputInfo, service::service::BACKGROUND_SERVICE,
    utils::errors::ServiceError,
};

pub async fn get_stakes(
    wallet_index: usize,
    account_index: usize,
) -> Result<Vec<FinalOutputInfo>, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let core = Arc::clone(&service.core);
    let wallet = core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;

    let data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let account = data
        .accounts
        .get(account_index)
        .ok_or(WalletErrors::InvalidAccountIndex(account_index))
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let provider = core
        .get_provider(account.chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let stakes = provider
        .get_all_stakes(&account.pub_key)
        .await
        .map_err(ServiceError::NetworkErrors)?;

    Ok(stakes.into_iter().map(|v| v.into()).collect())
}
