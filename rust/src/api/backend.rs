use std::{thread::sleep, time::Duration};

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

#[flutter_rust_bridge::frb(dart_async)]
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

#[flutter_rust_bridge::frb(dart_async)]
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

pub fn tick(sink: StreamSink<i32>) -> Result<(), String> {
    let mut ticks = 0;
    loop {
        sink.add(ticks).unwrap();
        sleep(Duration::from_secs(1));
        if ticks == i32::MAX {
            break;
        }
        ticks += 1;
    }
    Ok(())
}

#[flutter_rust_bridge::frb(dart_async)]
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

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_data() -> Result<BackgroundState, String> {
    with_service(get_background_state).await.map_err(Into::into)
}
