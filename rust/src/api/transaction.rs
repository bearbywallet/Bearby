use std::sync::Arc;

use crate::models::gas::GasInfo;
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::service::service::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;
use crate::utils::utils::{decode_session, parse_address, with_service};

pub use zilpay::background::bg_provider::ProvidersManagement;
pub use zilpay::background::bg_tx::TransactionsManagement;
pub use zilpay::background::bg_wallet::WalletManagement;
pub use zilpay::background::{bg_rates::RatesManagement, bg_token::TokensManagement};
pub use zilpay::errors::background::BackgroundError;
pub use zilpay::errors::wallet::WalletErrors;
pub use zilpay::proto::address::Address;
pub use zilpay::proto::tx::TransactionReceipt;
pub use zilpay::proto::tx::TransactionRequest;
pub use zilpay::proto::U256;
pub use zilpay::wallet::wallet_storage::StorageOperations;
pub use zilpay::wallet::wallet_transaction::WalletTransaction;

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sign_send_transactions(
    wallet_index: usize,
    account_index: usize,
    password: Option<String>,
    passphrase: Option<String>,
    session_cipher: Option<String>,
    identifiers: Vec<String>,
    tx: TransactionRequestInfo,
) -> Result<HistoricalTransactionInfo, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let core = Arc::clone(&service.core);

    let signed_tx = {
        let seed_bytes = if let Some(pass) = password {
            core.unlock_wallet_with_password(&pass, &identifiers, wallet_index)
        } else {
            let session = decode_session(session_cipher)?;
            core.unlock_wallet_with_session(session, &identifiers, wallet_index)
        }
        .map_err(ServiceError::BackgroundError)?;

        let wallet = core
            .get_wallet_by_index(wallet_index)
            .map_err(ServiceError::BackgroundError)?;
        let tx = tx.try_into().map_err(ServiceError::TransactionErrors)?;

        let signed_tx = wallet
            .sign_transaction(
                tx,
                account_index,
                &seed_bytes,
                passphrase.as_ref().map(|m| m.as_str()),
            )
            .await
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok::<TransactionReceipt, ServiceError>(signed_tx)
    }
    .map_err(Into::<ServiceError>::into)?;

    let tx = core
        .broadcast_signed_transactions(wallet_index, account_index, vec![signed_tx])
        .await
        .map_err(ServiceError::BackgroundError)?
        .into_iter()
        .next()
        .map(|v| v.into())
        .ok_or(ServiceError::TransactionErrors(
            zilpay::errors::tx::TransactionErrors::InvalidTxHash,
        ))?;

    Ok(tx)
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

#[flutter_rust_bridge::frb(dart_async)]
pub async fn cacl_gas_fee(params: TransactionRequestInfo) -> Result<GasInfo, String> {
    let chain_hash = params.metadata.chain_hash;
    let gas = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        let chain = service
            .core
            .get_provider(chain_hash)
            .map_err(ServiceError::BackgroundError)?;
        let tx: TransactionRequest = params.try_into().map_err(ServiceError::TransactionErrors)?;

        chain
            .estimate_gas_batch(&tx, 4, None)
            .await
            .map_err(ServiceError::NetworkErrors)?
    };

    Ok(gas.into())
}
