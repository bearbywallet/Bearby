use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::utils::errors::ServiceError;
use crate::utils::utils::{parse_address, with_service};
pub use zilpay::background::bg_wallet::WalletManagement;
pub use zilpay::background::{bg_rates::RatesManagement, bg_token::TokensManagement};
pub use zilpay::errors::background::BackgroundError;
use zilpay::errors::wallet::WalletErrors;
pub use zilpay::proto::address::Address;
use zilpay::proto::U256;
pub use zilpay::wallet::wallet_storage::StorageOperations;
pub use zilpay::wallet::wallet_transaction::WalletTransaction;

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_requested_transactions(
    wallet_index: usize,
) -> Result<Vec<TransactionRequestInfo>, String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let request_txns = wallet
            .get_request_txns()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let tx_list: Vec<TransactionRequestInfo> =
            request_txns.iter().map(|tx| tx.clone().into()).collect();

        Ok(tx_list)
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn clear_requested_transactions(wallet_index: usize) -> Result<(), String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;

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
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let tx = tx.try_into()?;

        wallet
            .add_request_transaction(tx)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_history(wallet_index: usize) -> Result<Vec<HistoricalTransactionInfo>, String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let history = wallet
            .get_history()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        let history: Vec<HistoricalTransactionInfo> =
            history.iter().map(|tx| tx.clone().into()).collect();

        Ok(history)
    })
    .await
    .map_err(Into::into)
}

pub struct TokenTransferParamsInfo {
    pub wallet_index: usize,
    pub account_index: usize,
    pub token_index: usize,
    pub amount: String,
    pub recipient: String,
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn create_token_transfer(
    params: TokenTransferParamsInfo,
) -> Result<TransactionRequestInfo, String> {
    with_service(|core| {
        let recipient = parse_address(params.recipient)?;
        let amount = U256::from_str_radix(&params.amount, 10)
            .map_err(|e| ServiceError::ParseError("amount".to_string(), e.to_string()))?;

        let wallet = core.get_wallet_by_index(params.wallet_index)?;
        let data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(params.wallet_index, e))?;
        let tokens = wallet
            .get_ftokens()
            .map_err(|e| ServiceError::WalletError(params.wallet_index, e))?;
        let token = tokens
            .get(params.token_index)
            .ok_or(WalletErrors::TokenNotExists(params.token_index))
            .map_err(|e| ServiceError::WalletError(params.wallet_index, e))?;

        let sender_account =
            data.accounts
                .get(params.account_index)
                .ok_or(ServiceError::AccountError(
                    params.account_index,
                    params.wallet_index,
                    zilpay::errors::wallet::WalletErrors::InvalidAccountIndex(params.account_index),
                ))?;

        let tx = core.build_token_transfer(
            token,
            sender_account.addr.clone(), //TODO: shit copy bytes.
            recipient,
            amount,
            sender_account.chain_hash,
        )?;

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}
