use std::sync::Arc;

use zilpay::{
    background::{bg_provider::ProvidersManagement, bg_wallet::WalletManagement},
    errors::wallet::WalletErrors,
    network::stake::ZilliqaStakeing,
    proto::{address::Address, U256},
    wallet::wallet_storage::StorageOperations,
};

use crate::{
    models::{stake::FinalOutputInfo, transactions::request::TransactionRequestInfo},
    service::service::BACKGROUND_SERVICE,
    utils::{errors::ServiceError, utils::with_service},
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

pub async fn build_claim_scilla_staking_rewards_tx(
    wallet_index: usize,
    account_index: usize,
    stake: FinalOutputInfo,
) -> Result<TransactionRequestInfo, String> {
    with_service(|core| {
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
        let tx = provider.build_tx_scilla_claim(&stake.into())?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}

pub async fn build_tx_scilla_init_unstake(
    wallet_index: usize,
    account_index: usize,
    stake: FinalOutputInfo,
) -> Result<TransactionRequestInfo, String> {
    with_service(|core| {
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
        let tx = provider.build_tx_scilla_init_unstake(&stake.into())?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}

pub async fn build_tx_scilla_complete_withdrawal(
    wallet_index: usize,
    account_index: usize,
) -> Result<TransactionRequestInfo, String> {
    with_service(|core| {
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
        let tx = provider.build_tx_scilla_complete_withdrawal()?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}

pub async fn build_tx_scilla_withdraw_stake_avely(
    wallet_index: usize,
    account_index: usize,
    stake: FinalOutputInfo,
) -> Result<TransactionRequestInfo, String> {
    with_service(|core| {
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
        let tx = provider.build_tx_scilla_withdraw_stake_avely(&stake.into())?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}

pub async fn build_tx_scilla_complete_withdrawal_avely(
    wallet_index: usize,
    account_index: usize,
) -> Result<TransactionRequestInfo, String> {
    with_service(|core| {
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
        let tx = provider.build_tx_scilla_complete_withdrawal_avely()?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}

pub async fn build_tx_evm_build_stake_request(
    wallet_index: usize,
    account_index: usize,
    stake: FinalOutputInfo,
    amount: String,
) -> Result<TransactionRequestInfo, String> {
    with_service(|core| {
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
        let delegator_address = Address::from_eth_address(&stake.address)?;
        let amount: U256 = amount.parse().unwrap_or_default();
        let tx = provider.build_tx_evm_stake_request(amount, delegator_address)?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}

pub async fn build_tx_evm_build_unstake_request(
    wallet_index: usize,
    account_index: usize,
    stake: FinalOutputInfo,
    amount_to_unstake: String,
) -> Result<TransactionRequestInfo, String> {
    with_service(|core| {
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
        let delegator_address = Address::from_eth_address(&stake.address)?;
        let amount_to_unstake: U256 = amount_to_unstake.parse().unwrap_or_default();
        let tx = provider.build_tx_evm_unstake_request(amount_to_unstake, delegator_address)?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}

pub async fn build_tx_build_claim_unstake_request(
    wallet_index: usize,
    account_index: usize,
    stake: FinalOutputInfo,
) -> Result<TransactionRequestInfo, String> {
    with_service(|core| {
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
        let delegator_address = Address::from_eth_address(&stake.address)?;
        let tx = provider.build_tx_claim_unstake_request(delegator_address)?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}

pub async fn build_tx_build_build_claim_reward_request(
    wallet_index: usize,
    account_index: usize,
    stake: FinalOutputInfo,
) -> Result<TransactionRequestInfo, String> {
    with_service(|core| {
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
        let delegator_address = Address::from_eth_address(&stake.address)?;
        let tx = provider.build_tx_build_claim_reward_request(delegator_address)?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}
