use std::sync::Arc;

use crate::frb_generated::StreamSink;
use crate::models::ftoken::FTokenInfo;
use crate::models::gas::RequiredTxParamsInfo;
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::service::service::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;
use crate::utils::utils::{decode_session, parse_address, with_service};
use tokio::sync::mpsc;
pub use zilpay::background::bg_provider::ProvidersManagement;
pub use zilpay::background::bg_tx::TransactionsManagement;
pub use zilpay::background::bg_wallet::WalletManagement;
use zilpay::background::bg_worker::{JobMessage, WorkerManager};
pub use zilpay::background::{bg_rates::RatesManagement, bg_token::TokensManagement};
use zilpay::config::sha::SHA256_SIZE;
pub use zilpay::errors::background::BackgroundError;
pub use zilpay::errors::wallet::WalletErrors;
pub use zilpay::proto::address::Address;
use zilpay::proto::pubkey::PubKey;
use zilpay::proto::signature::Signature;
pub use zilpay::proto::tx::TransactionReceipt;
pub use zilpay::proto::tx::TransactionRequest;
pub use zilpay::proto::U256;
use zilpay::token::ft::FToken;
pub use zilpay::wallet::wallet_storage::StorageOperations;
pub use zilpay::wallet::wallet_transaction::WalletTransaction;

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
        let wallet_data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let sender_account =
            wallet_data
                .accounts
                .get(account_index)
                .ok_or(ServiceError::AccountError(
                    account_index,
                    wallet_index,
                    zilpay::errors::wallet::WalletErrors::InvalidAccountIndex(account_index),
                ))?;
        let mut tx = tx.try_into().map_err(ServiceError::TransactionErrors)?;

        match &mut tx {
            TransactionRequest::Zilliqa((zil_tx, _)) => {
                zil_tx.chain_id = sender_account.chain_id as u16;
            }
            TransactionRequest::Ethereum((eth_tx, _)) => {
                eth_tx.chain_id = Some(sender_account.chain_id);
            }
        }

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

pub async fn prepare_message(
    wallet_index: usize,
    account_index: usize,
    message: String,
) -> Result<Vec<u8>, String> {
    with_service(|core| {
        let hash = core.prepare_message(wallet_index, account_index, &message)?;
        Ok(hash.to_vec())
    })
    .await
    .map_err(Into::into)
}

pub struct Eip712Hashes {
    pub domain_separator: Vec<u8>,
    pub hash_struct_message: Vec<u8>,
}

pub async fn prepare_eip712_message(typed_data_json: String) -> Result<Eip712Hashes, String> {
    with_service(|core| {
        let typed_data = core.prepare_eip712_message(typed_data_json)?;
        let domain_separator = typed_data.domain.separator().to_vec();
        let hash_struct_message = typed_data
            .hash_struct()
            .map_err(|e| BackgroundError::FailDeserializeTypedData(e.to_string()))?
            .to_vec();

        Ok(Eip712Hashes {
            domain_separator,
            hash_struct_message,
        })
    })
    .await
    .map_err(Into::into)
}

pub async fn sign_message(
    wallet_index: usize,
    account_index: usize,
    password: Option<String>,
    passphrase: Option<String>,
    session_cipher: Option<String>,
    identifiers: Vec<String>,
    message: String,
) -> Result<(String, String), String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let core = Arc::clone(&service.core);

    let signed: (PubKey, Signature) = {
        let seed_bytes = if let Some(pass) = password {
            core.unlock_wallet_with_password(&pass, &identifiers, wallet_index)
        } else {
            let session = decode_session(session_cipher)?;
            core.unlock_wallet_with_session(session, &identifiers, wallet_index)
        }
        .map_err(ServiceError::BackgroundError)?;
        let signed = core
            .sign_message(
                wallet_index,
                account_index,
                &seed_bytes,
                passphrase.as_ref().map(|s| s.as_ref()),
                &message,
            )
            .map_err(ServiceError::BackgroundError)?;

        Ok::<(PubKey, Signature), ServiceError>(signed)
    }
    .map_err(Into::<ServiceError>::into)?;
    let sig = signed.1.to_hex_prefixed();
    let pubkey = signed.0.as_hex_str();

    Ok((pubkey, sig))
}

pub async fn sign_typed_data_eip712(
    wallet_index: usize,
    account_index: usize,
    password: Option<String>,
    passphrase: Option<String>,
    session_cipher: Option<String>,
    identifiers: Vec<String>,
    typed_data_json: String,
) -> Result<(String, String), String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let core = Arc::clone(&service.core);

    let signed: (PubKey, Signature) = {
        let seed_bytes = if let Some(pass) = password {
            core.unlock_wallet_with_password(&pass, &identifiers, wallet_index)
        } else {
            let session = decode_session(session_cipher)?;
            core.unlock_wallet_with_session(session, &identifiers, wallet_index)
        }
        .map_err(ServiceError::BackgroundError)?;
        let signed = core
            .sign_typed_data_eip712(
                wallet_index,
                account_index,
                &seed_bytes,
                passphrase.as_ref().map(|s| s.as_ref()),
                &typed_data_json,
            )
            .await
            .map_err(ServiceError::BackgroundError)?;

        Ok::<(PubKey, Signature), ServiceError>(signed)
    }
    .map_err(Into::<ServiceError>::into)?;
    let sig = signed.1.to_hex_prefixed();
    let pubkey = signed.0.as_hex_str();

    Ok((pubkey, sig))
}

pub async fn get_history(wallet_index: usize) -> Result<Vec<HistoricalTransactionInfo>, String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let history = wallet
            .get_history()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        let history: Vec<HistoricalTransactionInfo> =
            history.into_iter().map(|tx| tx.into()).rev().collect();

        Ok(history)
    })
    .await
    .map_err(Into::into)
}

pub async fn clear_history(wallet_index: usize) -> Result<(), String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        wallet
            .clear_history()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

#[derive(Debug)]
pub struct TokenTransferParamsInfo {
    pub wallet_index: usize,
    pub account_index: usize,
    pub token: FTokenInfo,
    pub amount: String,
    pub recipient: String,
    pub icon: String,
}

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
        let sender_account =
            data.accounts
                .get(params.account_index)
                .ok_or(ServiceError::AccountError(
                    params.account_index,
                    params.wallet_index,
                    zilpay::errors::wallet::WalletErrors::InvalidAccountIndex(params.account_index),
                ))?;

        if params.token.addr_type != sender_account.addr.prefix_type() {
            return Err(ServiceError::AccountError(
                params.wallet_index,
                params.account_index,
                WalletErrors::InvalidAccountType,
            ));
        }

        let token: FToken = params.token.try_into()?;
        let mut tx = core.build_token_transfer(&token, &sender_account, recipient, amount)?;

        tx.set_icon(params.icon);

        Ok(tx.into())
    })
    .await
    .map_err(Into::into)
}

pub async fn cacl_gas_fee(
    wallet_index: usize,
    account_index: usize,
    params: TransactionRequestInfo,
) -> Result<RequiredTxParamsInfo, String> {
    let chain_hash = params.metadata.chain_hash;
    let gas = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        let chain = service
            .core
            .get_provider(chain_hash)
            .map_err(ServiceError::BackgroundError)?;
        let tx: TransactionRequest = params.try_into().map_err(ServiceError::TransactionErrors)?;
        let wallet = service
            .core
            .get_wallet_by_index(wallet_index)
            .map_err(ServiceError::BackgroundError)?;
        let data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let sender_account = data
            .accounts
            .get(account_index)
            .ok_or(ServiceError::AccountError(
                account_index,
                wallet_index,
                zilpay::errors::wallet::WalletErrors::InvalidAccountIndex(account_index),
            ))?;

        let mut gas = chain
            .estimate_params_batch(&tx, &sender_account.addr, 4, None)
            .await
            .map_err(ServiceError::NetworkErrors)?;

        if gas.tx_estimate_gas == U256::ZERO {
            match tx {
                TransactionRequest::Zilliqa((tx, _)) => {
                    gas.tx_estimate_gas = U256::from(tx.gas_limit);
                }
                TransactionRequest::Ethereum((tx, _)) => {
                    gas.tx_estimate_gas = tx.gas.map(|gas| U256::from(gas)).unwrap_or(U256::ZERO);
                }
            }
        }

        gas
    };

    Ok(gas.into())
}

pub async fn check_pending_tranasctions(
    wallet_index: usize,
) -> Result<Vec<HistoricalTransactionInfo>, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    let history = service
        .core
        .check_pending_txns(wallet_index)
        .await
        .map_err(ServiceError::BackgroundError)?;
    let history: Vec<HistoricalTransactionInfo> =
        history.into_iter().map(|tx| tx.into()).rev().collect();

    Ok(history)
}

pub async fn start_history_worker(
    wallet_index: usize,
    sink: StreamSink<String>,
) -> Result<(), String> {
    let (tx, mut rx) = mpsc::channel(10);

    {
        let mut guard = BACKGROUND_SERVICE.write().await;
        let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;

        let handle = service
            .core
            .start_txns_track_job(wallet_index, tx)
            .await
            .map_err(|e| e.to_string())?;

        if let Some(block_handle) = &service.block_handle {
            block_handle.abort();
            service.block_handle = None;
        }

        service.history_handle = Some(handle);
    }

    while let Some(msg) = rx.recv().await {
        match msg {
            JobMessage::Tx => {
                sink.add(String::with_capacity(0)).unwrap_or_default();
            }
            JobMessage::Error(e) => {
                sink.add(e).unwrap_or_default();
            }
            _ => break,
        }
    }

    Ok(())
}

pub async fn stop_history_worker() -> Result<(), String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;

    if let Some(history_handle) = &service.history_handle {
        history_handle.abort();

        service.history_handle = None;
    }

    Ok(())
}
