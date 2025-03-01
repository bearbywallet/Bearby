use aes::cipher::generic_array::GenericArray;
use aes::cipher::{BlockDecrypt, KeyInit};
use aes::Aes256;
use base64::engine::general_purpose;
use base64::Engine;
use pbkdf2::pbkdf2_hmac;
use serde_json::Value;
use sha2::{Digest, Sha256, Sha512};
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

fn generate_key(password: &str, salt: &str, cost: u32) -> [u8; 32] {
    let password_bytes = password.as_bytes();

    let mut hasher = Sha256::default();
    hasher.update(password_bytes);
    let password_hash = hasher.finalize();
    let password_hex = hex::encode(password_hash);

    let salt = salt.as_bytes();

    let mut key = [0u8; 32];
    pbkdf2_hmac::<Sha512>(&password_hex.as_bytes(), salt, cost, &mut key);

    key
}

fn decrypt(key_bytes: &[u8; 32], iv: &str, cipher: &str) -> Result<String, String> {
    let iv_bytes = hex::decode(iv).map_err(|e| e.to_string())?;
    let cipher_bytes = general_purpose::STANDARD
        .decode(cipher)
        .map_err(|e| e.to_string())?;

    if key_bytes.len() != 32 {
        return Err("Key must be 32 bytes long".into());
    }
    if iv_bytes.len() != 16 {
        return Err("IV must be 16 bytes long".into());
    }
    if cipher_bytes.len() % 16 != 0 {
        return Err("Cipher length must be multiple of 16 bytes".into());
    }

    let cipher = Aes256::new(GenericArray::from_slice(&key_bytes[..32]));
    let mut plaintext = Vec::with_capacity(cipher_bytes.len());
    let mut previous_block = iv_bytes;
    let mut cipher_bytes = cipher_bytes;

    for chunk in cipher_bytes.chunks_mut(16) {
        let mut decrypted_block = chunk.to_vec();
        cipher.decrypt_block((&mut decrypted_block[..]).into());
        for (i, &byte) in previous_block.iter().enumerate() {
            decrypted_block[i] ^= byte;
        }
        plaintext.extend_from_slice(&decrypted_block);
        previous_block = chunk.to_vec();
    }

    if let Some(&padding_len) = plaintext.last() {
        let len = plaintext.len();
        if padding_len > 0
            && padding_len <= 16
            && plaintext[len - padding_len as usize..]
                .iter()
                .all(|&x| x == padding_len)
        {
            plaintext.truncate(len - padding_len as usize);
        }
    }

    Ok(String::from_utf8(plaintext).map_err(|e| e.to_string())?)
}

pub fn load_old_database_android() -> Result<(String, String), String> {
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

pub fn try_restore_rkstorage(vault_json: String, password: String) -> Result<String, String> {
    let salt = "ZilPay";
    let cost = 5000;
    let json_value: Value = serde_json::from_str(&vault_json).map_err(|e| e.to_string())?;
    let key = generate_key(&password, salt, cost);
    let iv = json_value
        .get("iv")
        .ok_or(String::from("invalid iv"))?
        .as_str()
        .unwrap_or_default();
    let cipher = json_value
        .get("cipher")
        .ok_or(String::from("invalid cipher"))?
        .as_str()
        .unwrap_or_default();
    let secre_words = decrypt(&key, &iv, &cipher)?;

    Ok(secre_words)
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
