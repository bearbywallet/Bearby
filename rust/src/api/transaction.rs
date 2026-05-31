use std::str::FromStr;
use std::sync::Arc;

use crate::frb_generated::StreamSink;
use crate::models::ftoken::FTokenInfo;
use crate::models::gas::RequiredTxParamsInfo;
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;
use crate::utils::helpers::{parse_address, with_service};
use zilpay::background::bg_bitcoin::BitcoinManagement;
pub use zilpay::background::bg_provider::ProvidersManagement;
pub use zilpay::background::bg_token::TokensManagement;
use zilpay::background::bg_tx::update_tx_from_params;
pub use zilpay::background::bg_tx::TransactionsManagement;
pub use zilpay::background::bg_wallet::WalletManagement;
use zilpay::background::bg_worker::{JobMessage, WorkerManager};
use zilpay::background::Background;
use zilpay::bitcoin::bip32::Xpub;
use zilpay::cipher::argon2::Argon2Seed;
use zilpay::crypto::bip49::{components_to_derivation_path, split_path, DerivationPath};
pub use zilpay::errors::background::BackgroundError;
pub use zilpay::errors::wallet::WalletErrors;
use zilpay::history::transaction::HistoricalTransaction;
use zilpay::network::evm::RequiredTxParams;
pub use zilpay::proto::address::Address;
use zilpay::proto::btc_utils::BtcAccountXpubsInput;
use zilpay::proto::pubkey::PubKey;
use zilpay::proto::signature::Signature;
pub use zilpay::proto::tx::TransactionReceipt;
pub use zilpay::proto::tx::TransactionRequest;
use zilpay::proto::utils::safe_chunk_transaction;
pub use zilpay::proto::U256;
use zilpay::secrecy::zeroize::Zeroize;
use zilpay::secrecy::SecretString;
use zilpay::token::ft::FToken;
use zilpay::tokio::sync::mpsc;
use zilpay::wallet::wallet_crypto::WalletCrypto;
pub use zilpay::wallet::wallet_storage::StorageOperations;
pub use zilpay::wallet::wallet_transaction::WalletTransaction;
use zilpay::wallet::wallet_types::WalletTypes;

/// One Argon2 unlock. With a password it derives the seed via password-unlock (zeroizing the
/// password after); otherwise it reuses the active session. Shared by every signing entry point
/// so a single flow never re-derives the seed more than once.
pub(crate) async fn unlock_seed(
    core: &Arc<Background>,
    wallet_index: usize,
    password: Option<String>,
) -> Result<Argon2Seed, ServiceError> {
    let password = password.map(|p| SecretString::new(p.into()));
    let seed = if let Some(mut pass) = password {
        let key = core
            .unlock_wallet_with_password(&pass, None, wallet_index)
            .await;
        pass.zeroize();
        key
    } else {
        core.unlock_wallet_with_session(wallet_index).await
    }
    .map_err(ServiceError::BackgroundError)?;

    Ok(seed)
}

/// Sign one transaction with an already-derived `seed` (no re-unlock) and either broadcast it or
/// persist it to history, per `metadata.broadcast`. Carries the Zilliqa/Ethereum chain_id
/// injection so callers don't repeat it. Used by both the single-tx FFI and the swap orchestrator.
pub(crate) async fn sign_and_broadcast_one(
    core: &Arc<Background>,
    wallet_index: usize,
    account_index: usize,
    seed: &Argon2Seed,
    passphrase: &SecretString,
    mut tx: TransactionRequest,
) -> Result<HistoricalTransactionInfo, ServiceError> {
    let wallet = core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let wallet_data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let chain = core
        .get_provider(wallet_data.chain_hash)
        .map_err(ServiceError::BackgroundError)?;

    match &mut tx {
        TransactionRequest::Zilliqa((zil_tx, _)) => {
            zil_tx.chain_id = chain.config.chain_ids[1] as u16;
        }
        TransactionRequest::Ethereum((eth_tx, _)) => {
            eth_tx.chain_id = Some(chain.config.chain_id());
        }
        _ => {}
    }

    let signed_tx = wallet
        .sign_transaction(tx, account_index, seed, passphrase)
        .await
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

    if signed_tx.get_metadata().broadcast {
        core.broadcast_signed_transactions(wallet_index, vec![signed_tx])
            .await
            .map_err(ServiceError::BackgroundError)?
            .into_iter()
            .next()
            .map(|v| v.into())
            .ok_or(ServiceError::TransactionErrors(
                zilpay::errors::tx::TransactionErrors::InvalidTransaction,
            ))
    } else {
        let history = HistoricalTransaction::from_transaction_receipt(signed_tx)
            .map_err(ServiceError::TransactionErrors)?;
        wallet
            .add_history(std::slice::from_ref(&history))
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        Ok(history.into())
    }
}

pub async fn send_signed_transactions(
    wallet_index: u8,
    account_index: u8,
    tx: TransactionRequestInfo,
    sig: Vec<u8>,
    bip86_xpub: Option<String>,
) -> Result<HistoricalTransactionInfo, String> {
    let tx: TransactionRequest = tx.try_into().map_err(ServiceError::TransactionErrors)?;
    let wallet_index = wallet_index as usize;
    let account_index = account_index as usize;

    let parsed_bip86_xpub = bip86_xpub
        .as_deref()
        .map(Xpub::from_str)
        .transpose()
        .map_err(|e| ServiceError::ParseError("bip86_xpub".into(), e.to_string()))?;

    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let core = Arc::clone(&service.core);
    let wallet = core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let wallet_data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let sender_account = wallet_data
        .get_account(account_index)
        .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))?;
    let signed_tx = tx
        .with_signature(sig, sender_account.pub_key.as_ref())
        .map_err(ServiceError::TransactionErrors)?;

    let receipt = core
        .broadcast_signed_transactions(wallet_index, vec![signed_tx])
        .await
        .map_err(ServiceError::BackgroundError)?
        .into_iter()
        .next()
        .map(|v| v.into())
        .ok_or(ServiceError::TransactionErrors(
            zilpay::errors::tx::TransactionErrors::InvalidTxHash,
        ))?;

    let is_btc = matches!(sender_account.addr, Address::Secp256k1Bitcoin(_));
    let is_bip86 = wallet_data.bip == DerivationPath::BIP86_PURPOSE;

    if is_btc && is_bip86 {
        match (&wallet_data.wallet_type, parsed_bip86_xpub) {
            (WalletTypes::Ledger(_), None) => {
                eprintln!("[btc] BIP86 Ledger BTC tx but bip86_xpub not provided — address rotation skipped");
            }
            (WalletTypes::Ledger(_), Some(xpub)) => {
                if let Err(e) = core
                    .rotate_btc_account(wallet_index, account_index, &xpub)
                    .await
                {
                    eprintln!("[btc] rotate failed after broadcast: {e}");
                }
            }
            _ => {}
        }
    }

    Ok(receipt)
}

pub async fn sign_send_transactions(
    wallet_index: usize,
    account_index: usize,
    password: Option<String>,
    passphrase: Option<String>,
    tx: TransactionRequestInfo,
) -> Result<HistoricalTransactionInfo, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let core = Arc::clone(&service.core);

    let seed_bytes = unlock_seed(&core, wallet_index, password).await?;
    let secret_passphrase = SecretString::new(passphrase.unwrap_or_default().into());

    let req_tx: TransactionRequest = tx.try_into().map_err(ServiceError::TransactionErrors)?;
    let tx = sign_and_broadcast_one(
        &core,
        wallet_index,
        account_index,
        &seed_bytes,
        &secret_passphrase,
        req_tx,
    )
    .await?;

    let wallet = core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let wallet_data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let sender_account = wallet_data
        .get_account(account_index)
        .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))?;

    if matches!(sender_account.addr, Address::Secp256k1Bitcoin(_))
        && wallet_data.bip == DerivationPath::BIP86_PURPOSE
        && matches!(wallet_data.wallet_type, WalletTypes::SecretPhrase(_))
    {
        let network = sender_account
            .addr
            .get_bitcoin_network()
            .map_err(ServiceError::from)?;
        let mnemonic = wallet
            .reveal_mnemonic(&seed_bytes)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let seed_secret = mnemonic
            .to_seed(&secret_passphrase)
            .map_err(|e| ServiceError::ParseError("bip39_seed".into(), format!("{:?}", e)))?;
        let bip86_xpub =
            BtcAccountXpubsInput::from_seed(&seed_secret, account_index as u32, network)
                .map_err(ServiceError::from)?
                .bip86_xpub;
        if let Err(e) = core
            .rotate_btc_account(wallet_index, account_index, &bip86_xpub)
            .await
        {
            eprintln!("[btc] rotate failed after broadcast: {e}");
        }
    }

    Ok(tx)
}

pub struct EncodedRLPTx {
    pub bytes: Vec<u8>,
    pub chunks_bytes: Vec<Vec<u8>>,
}

pub async fn encode_tx_rlp(
    wallet_index: usize,
    account_index: usize,
    tx: TransactionRequestInfo,
    slip44: u32,
) -> Result<EncodedRLPTx, String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let walelt_data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let chain = core.get_provider(walelt_data.chain_hash)?;
        let account = walelt_data
            .get_account(account_index)
            .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))?;
        let mut tx: TransactionRequest = tx.try_into()?;

        match tx {
            TransactionRequest::Bitcoin(_)
            | TransactionRequest::Tron(_)
            | TransactionRequest::Solana(_) => Ok(EncodedRLPTx {
                bytes: tx
                    .to_rlp_encode(account.pub_key.as_ref())
                    .map_err(ServiceError::TransactionErrors)?,
                chunks_bytes: Vec::new(),
            }),
            TransactionRequest::Zilliqa(_) => Ok(EncodedRLPTx {
                bytes: tx
                    .to_rlp_encode(account.pub_key.as_ref())
                    .map_err(ServiceError::TransactionErrors)?,
                chunks_bytes: Vec::new(),
            }),
            TransactionRequest::Ethereum((ref mut tx_eth, _)) => {
                tx_eth.chain_id = Some(chain.config.chain_id());
                let derivation =
                    DerivationPath::with_index(slip44, (0, 0, account.account_type.value()));
                let ledger_path = derivation.get_path().trim_start_matches("m/").to_string();
                let derivation_path = split_path(&ledger_path).unwrap_or_default();
                let derivation_bytes = components_to_derivation_path(&derivation_path);
                let transaction_type = tx_eth.preferred_type();

                let rlp = tx
                    .to_rlp_encode(account.pub_key.as_ref())
                    .map_err(ServiceError::TransactionErrors)?;
                let chunks_bytes =
                    safe_chunk_transaction(&rlp, &derivation_bytes, transaction_type)?;
                Ok(EncodedRLPTx {
                    chunks_bytes,
                    bytes: rlp,
                })
            }
        }
    })
    .await
    .map_err(Into::into)
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
    message: String,
    title: Option<String>,
    icon: Option<String>,
) -> Result<(String, String), String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let core = Arc::clone(&service.core);

    let seed_bytes = unlock_seed(&core, wallet_index, password).await?;
    let secret_passphrase = SecretString::new(passphrase.unwrap_or_default().into());
    let signed: (PubKey, Signature) = core
        .sign_message(
            wallet_index,
            account_index,
            &seed_bytes,
            &secret_passphrase,
            &message,
            title,
            icon,
        )
        .map_err(ServiceError::BackgroundError)?;

    let sig = signed.1.to_hex_prefixed();
    let pubkey = signed.0.as_hex_str();

    Ok((pubkey, sig))
}

pub async fn sign_typed_data_eip712(
    wallet_index: usize,
    account_index: usize,
    password: Option<String>,
    passphrase: Option<String>,
    typed_data_json: String,
    title: Option<String>,
    icon: Option<String>,
) -> Result<(String, String), String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let core = Arc::clone(&service.core);

    let seed_bytes = unlock_seed(&core, wallet_index, password).await?;
    let secret_passphrase = SecretString::new(passphrase.unwrap_or_default().into());
    let signed: (PubKey, Signature) = core
        .sign_typed_data_eip712(
            wallet_index,
            account_index,
            &seed_bytes,
            &secret_passphrase,
            &typed_data_json,
            title,
            icon,
        )
        .await
        .map_err(ServiceError::BackgroundError)?;

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
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let core = Arc::clone(&service.core);

    let recipient = parse_address(params.recipient)?;
    let amount = U256::from_str_radix(&params.amount, 10)
        .map_err(|e| ServiceError::ParseError("amount".to_string(), e.to_string()))?;
    let wallet = core
        .get_wallet_by_index(params.wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(params.wallet_index, e))?;
    let sender_account = data
        .get_account(params.account_index)
        .map_err(|e| ServiceError::AccountError(params.account_index, params.wallet_index, e))?;

    if params.token.addr_type != sender_account.addr.prefix_type() {
        return Err(ServiceError::AccountError(
            params.wallet_index,
            params.account_index,
            WalletErrors::InvalidAccountType,
        )
        .into());
    }

    let token: FToken = params
        .token
        .try_into()
        .map_err(|e: zilpay::errors::token::TokenError| e.to_string())?;

    let final_amount = amount;

    let mut tx = core
        .build_token_transfer(&token, sender_account, recipient, final_amount)
        .await
        .map_err(ServiceError::BackgroundError)?;

    tx.set_icon(params.icon);

    Ok(tx.into())
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
            .get_account(account_index)
            .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))?;

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
                TransactionRequest::Bitcoin(_) => {}
                TransactionRequest::Tron(_) => {}
                TransactionRequest::Solana(_) => {}
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

        if let Some(history_handle) = &service.history_handle {
            history_handle.abort();
            service.history_handle = None;
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

pub async fn update_tx_with_params(
    tx: TransactionRequestInfo,
    params: RequiredTxParamsInfo,
    balance: String,
    chain_hash: u64,
) -> Result<TransactionRequestInfo, String> {
    let mut tx: TransactionRequest = tx.try_into().map_err(ServiceError::TransactionErrors)?;
    let params: RequiredTxParams = params.into();
    let balance: U256 = balance.parse().unwrap_or_default();

    if let TransactionRequest::Tron((ref mut tron_tx, _)) = tx {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        let core = Arc::clone(&service.core);

        let provider = core
            .get_provider(chain_hash)
            .map_err(ServiceError::BackgroundError)?;
        provider
            .tron_fill_block_ref(tron_tx)
            .await
            .map_err(ServiceError::NetworkErrors)?;
    }

    update_tx_from_params(&mut tx, params, balance).map_err(ServiceError::TransactionErrors)?;

    Ok(tx.into())
}

#[cfg(test)]
mod tests_ledger {
    use zilpay::serde_json::from_str;
    use zilpay::{
        config::key::PUB_KEY_SIZE,
        crypto::bip49::{components_to_derivation_path, split_path},
        proto::{
            tx::{ETHTransactionRequest, TransactionRequest},
            utils::safe_chunk_transaction,
        },
    };

    #[test]
    fn test_rlp_legacy() {
        let json_string = r#"
    {
        "to": "0x45312ea0eff7e09c83cbe249fa1d7598c4c8cd4e",
        "gasPrice": "0xce60755f",
        "gas": "0x55c4e",
        "value": "0x5af3107a4000",
        "input": "0x5c9c18e2000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c70000000000000000000000006b175474e89094c44da98b954eedeac495271d0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005af3107a400000000000000000000000000000000000000000000000000006575041f270c7d5000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "nonce": "0xa7",
        "chainId": "0x1"
    }
    "#;
        let path = "44'/60'/0'/0/0";
        let tx: ETHTransactionRequest = from_str(json_string).unwrap();
        let tx_type = tx.preferred_type();
        let native_tx = TransactionRequest::Ethereum((tx, Default::default()));
        let derivation_path = split_path(path).unwrap_or_default();
        let derivation_bytes = components_to_derivation_path(&derivation_path);

        assert_eq!(
            "058000002c8000003c800000000000000000000000",
            zilpay::alloy::hex::encode(&derivation_bytes)
        );

        let rlp = native_tx
            .to_rlp_encode(Some(&zilpay::proto::pubkey::PubKey::Secp256k1Keccak256(
                [0u8; PUB_KEY_SIZE],
            )))
            .unwrap();

        assert_eq!("f9059181a784ce60755f83055c4e9445312ea0eff7e09c83cbe249fa1d7598c4c8cd4e865af3107a4000b905645c9c18e2000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c70000000000000000000000006b175474e89094c44da98b954eedeac495271d0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005af3107a400000000000000000000000000000000000000000000000000006575041f270c7d5000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018080",
        zilpay::alloy::hex::encode(&rlp)
                );

        let chunks_bytes = safe_chunk_transaction(&rlp, &derivation_bytes, tx_type).unwrap();
        let chunks: Vec<String> = chunks_bytes
            .iter()
            .map(zilpay::alloy::hex::encode)
            .collect();

        let should_be = vec![ "058000002c8000003c800000000000000000000000f9059181a784ce60755f83055c4e9445312ea0eff7e09c83cbe249fa1d7598c4c8cd4e865af3107a4000b905645c9c18e2000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c70000000000000000000000006b175474e89094c44da98b954eedeac495271d0f00000000000000000000000000000000000000000000000000",
  "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "0000000000000001000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000",
  "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005af3107a4000000000000000000000000000000000000000000000",
  "00000006575041f270c7d5000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018080"                                                                                                                             ];

        assert_eq!(should_be, chunks);
    }

    #[test]
    fn test_rlp_eip1559() {
        let json_string = r#"
    {
      "from": "0xa1b2ff03f501a4d8278cb75a9075f406a5b8c5ff",
      "to": "0x45312ea0eff7e09c83cbe249fa1d7598c4c8cd4e",
      "maxFeePerGas": "0x1a8e81b20",
      "maxPriorityFeePerGas": "0x0",
      "gas": "0x55c4e",
      "value": "0x5af3107a4000",
      "input": "0x5c9c18e2000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c70000000000000000000000006b175474e89094c44da98b954eedeac495271d0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005af3107a400000000000000000000000000000000000000000000000000006575041f270c7d5000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "nonce": "0xa7",
      "chainId": "0x1"
    }
    "#;
        let path = "44'/60'/0'/0/0";
        let tx: ETHTransactionRequest = from_str(json_string).unwrap();
        let tx_type = tx.preferred_type();
        let native_tx = TransactionRequest::Ethereum((tx, Default::default()));
        let derivation_path = split_path(path).unwrap_or_default();
        let derivation_bytes = components_to_derivation_path(&derivation_path);

        let rlp = native_tx
            .to_rlp_encode(Some(&zilpay::proto::pubkey::PubKey::Secp256k1Keccak256(
                [0u8; PUB_KEY_SIZE],
            )))
            .unwrap();

        assert_eq!(zilpay::alloy::hex::encode(&rlp), "02f905920181a7808501a8e81b2083055c4e9445312ea0eff7e09c83cbe249fa1d7598c4c8cd4e865af3107a4000b905645c9c18e2000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c70000000000000000000000006b175474e89094c44da98b954eedeac495271d0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005af3107a400000000000000000000000000000000000000000000000000006575041f270c7d5000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0");

        let chunks_bytes = safe_chunk_transaction(&rlp, &derivation_bytes, tx_type).unwrap();
        let chunks: Vec<String> = chunks_bytes
            .iter()
            .map(zilpay::alloy::hex::encode)
            .collect();
        let should_be = vec![ "058000002c8000003c80000000000000000000000002f905920181a7808501a8e81b2083055c4e9445312ea0eff7e09c83cbe249fa1d7598c4c8cd4e865af3107a4000b905645c9c18e2000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c70000000000000000000000006b175474e89094c44da98b954eedeac495271d0f000000000000000000000000000000000000000000",
  "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000000000000000000000001000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000",
  "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005af3107a40000000000000000000000000000000000000",
  "0000000000000006575041f270c7d5000000000000000000000000f5f5b97624542d72a9e06f04804bf81baa15e2b4000000000000000000000000bebc44782c7db0a1a60cb6fe97d0b483032ff1c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0"                                                                                                                         ];

        assert_eq!(should_be, chunks);
    }
}
