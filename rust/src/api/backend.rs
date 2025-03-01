use pbkdf2::pbkdf2_hmac;
use sha2::Sha512;
use tokio::sync::mpsc;
pub use zilpay::background::bg_worker::{JobMessage, WorkerManager};
pub use zilpay::{
    background::{Background, BackgroundBip39Params, BackgroundSKParams},
    config::key::{PUB_KEY_SIZE, SECRET_KEY_SIZE},
    proto::{address::Address, pubkey::PubKey, secret_key::SecretKey},
    settings::{
        notifications::NotificationState,
        theme::{Appearances, Theme},
    },
    wallet::LedgerParams,
};

use crate::{
    frb_generated::StreamSink,
    models::background::BackgroundState,
    service::service::{ServiceBackground, BACKGROUND_SERVICE},
    utils::{
        errors::ServiceError,
        utils::{get_background_state, with_service},
    },
};

fn generate_key(password: &str, salt: &str, cost: u32, length: usize) -> String {
    let password = password.as_bytes();
    let salt = salt.as_bytes();

    let mut key = vec![0u8; length / 8];
    pbkdf2_hmac::<Sha512>(password, salt, cost, &mut key);

    let key_hex = hex::encode(key);

    key_hex
}

pub async fn load_old_database_android() -> Result<(String, String), String> {
    let path = "/data/data/com.zilpaymobile/databases/RKStorage";
    let conn = rusqlite::Connection::open(path).map_err(|e| e.to_string())?;
    let vault: String = conn
        .query_row(
            "SELECT value FROM catalystLocalStorage WHERE key = '@/ZilPay/vault'",
            [],
            |row| row.get(0),
        )
        .map_err(|e| e.to_string())?;
    let accounts: String = conn
        .query_row(
            "SELECT value FROM catalystLocalStorage WHERE key = '@/ZilPay/accounts'",
            [],
            |row| row.get(0),
        )
        .map_err(|e| e.to_string())?;

    Ok((vault, accounts))
}

pub async fn try_restore_rkstorage(vault_json: String, password: String) -> Result<String, String> {
    let salt = "ZilPay";
    let cost = 5000;
    let length = 256;
    let key = generate_key(&password, salt, cost, length);

    Ok(String::new())
}

pub async fn load_service(path: &str) -> Result<BackgroundState, String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    if guard.is_none() {
        let bg = ServiceBackground::from_path(path)?;
        let state = get_background_state(&bg.core)?;
        *guard = Some(bg);
        Ok(state)
    } else {
        Err("service already running".to_string())
    }
}

pub async fn stop_service() -> Result<(), String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    if let Some(background) = guard.as_mut() {
        background.stop();
        *guard = None;
        Ok(())
    } else {
        Err("Service is not running".to_string())
    }
}

pub async fn is_service_running() -> bool {
    BACKGROUND_SERVICE.read().await.is_some()
}

pub async fn stop_block_worker() -> Result<(), String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;

    if let Some(block_handle) = &service.block_handle {
        block_handle.abort();

        service.block_handle = None;
    }

    Ok(())
}

pub struct BlockEvent {
    pub block_number: Option<u64>,
    pub error: Option<String>,
}

pub async fn start_block_worker(
    wallet_index: usize,
    sink: StreamSink<BlockEvent>,
) -> Result<(), String> {
    let (tx, mut rx) = mpsc::channel(10);

    {
        let mut guard = BACKGROUND_SERVICE.write().await;
        let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;

        let handle = service
            .core
            .start_block_track_job(wallet_index, tx)
            .await
            .map_err(|e| e.to_string())?;

        if let Some(block_handle) = &service.block_handle {
            block_handle.abort();
            service.block_handle = None;
        }

        service.block_handle = Some(handle);
    }

    while let Some(msg) = rx.recv().await {
        match msg {
            JobMessage::Block(block_number) => {
                sink.add(BlockEvent {
                    block_number: Some(block_number),
                    error: None,
                })
                .unwrap_or_default();
            }
            JobMessage::Error(e) => {
                sink.add(BlockEvent {
                    block_number: None,
                    error: Some(e),
                })
                .unwrap_or_default();
            }
            _ => break,
        }
    }

    Ok(())
}

pub async fn get_data() -> Result<BackgroundState, String> {
    with_service(get_background_state).await.map_err(Into::into)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_key() {
        let password = "123";
        let salt = "ZilPay";
        let cost = 5000;
        let length = 256;

        let result = generate_key(password, salt, cost, length);
        assert!(result.is_ok());

        let key = result.unwrap();

        dbg!(&key);
        assert_eq!(key.len(), 64);
        let key2 = generate_key(password, salt, cost, length).unwrap();
        assert_eq!(key, key2);
    }
}
