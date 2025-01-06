use crate::models::transaction::{
    TransactionMetadata, TransactionRequestInfo, TransactionRequestScilla,
};
use crate::utils::errors::ServiceError;
use crate::utils::utils::{with_service, with_service_mut};
pub use zilpay::background::bg_wallet::WalletManagement;
pub use zilpay::background::{bg_rates::RatesManagement, bg_token::TokensManagement};
pub use zilpay::proto::address::Address;
pub use zilpay::wallet::wallet_transaction::WalletTransaction;
pub use zilpay::zil_errors::background::BackgroundError;

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_requested_transactions(
    wallet_index: usize,
) -> Result<Vec<TransactionRequestInfo>, String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let tx_list: Vec<TransactionRequestInfo> = wallet
            .request_txns
            .iter()
            .map(|tx| tx.clone().into())
            .collect();

        Ok(tx_list)
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn clear_requested_transactions(wallet_index: usize) -> Result<(), String> {
    with_service_mut(|core| {
        let wallet = core
            .wallets
            .get_mut(wallet_index)
            .ok_or(BackgroundError::WalletNotExists(wallet_index))?;

        wallet
            .clear_request_transaction()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_requested_transactions(
    wallet_index: usize,
    tx: TransactionRequestInfo,
) -> Result<(), String> {
    with_service_mut(|core| {
        let wallet = core
            .wallets
            .get_mut(wallet_index)
            .ok_or(BackgroundError::WalletNotExists(wallet_index))?;

        // wallet
        //     .add_request_transaction(tx)
        //     .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}
