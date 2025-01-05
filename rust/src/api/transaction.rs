use crate::models::transaction::{
    TransactionMetadata, TransactionRequestInfo, TransactionRequestScilla,
};
use crate::utils::utils::with_service;
pub use zilpay::background::bg_wallet::WalletManagement;
pub use zilpay::background::{bg_rates::RatesManagement, bg_token::TokensManagement};
pub use zilpay::proto::address::Address;

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
    with_service(|core| {
        todo!();

        Ok(())
    })
    .await
    .map_err(Into::into)
}
