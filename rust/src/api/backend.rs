pub use zilpay::background::bg_worker::{JobMessage, WorkerManager};
use zilpay::tokio::sync::mpsc;
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
    service::background::{ServiceBackground, BACKGROUND_SERVICE},
    utils::{
        errors::ServiceError,
        helpers::{get_background_state, handle, with_service},
    },
};

pub async fn load_service(path: &str) -> Result<BackgroundState, String> {
    zilpay::init()?; // init pq ssl
    let mut guard = BACKGROUND_SERVICE.write().await;
    if guard.is_none() {
        let bg = ServiceBackground::from_path(path)?;
        let core = bg
            .core
            .load_full()
            .ok_or(ServiceError::NotRunning)?;
        let state = get_background_state(&core)?;
        *guard = Some(bg);
        Ok(state)
    } else {
        Err("service already running".to_string())
    }
}

pub async fn stop_service() -> Result<(), String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    if guard.is_some() {
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
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let mut block_handle = service.block_handle.lock().await;

    if let Some(handle) = block_handle.take() {
        handle.abort();
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
        let core = handle().await?;
        let worker_handle = core
            .start_block_track_job(wallet_index, tx)
            .await
            .map_err(|e| e.to_string())?;
        let guard = BACKGROUND_SERVICE.read().await;
        let Some(service) = guard.as_ref() else {
            worker_handle.abort();
            return Err(ServiceError::NotRunning.into());
        };
        let mut block_handle = service.block_handle.lock().await;

        if let Some(previous_handle) = block_handle.take() {
            previous_handle.abort();
        }

        *block_handle = Some(worker_handle);
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
