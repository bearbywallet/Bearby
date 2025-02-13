use std::{thread::sleep, time::Duration};

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
    utils::utils::{get_background_state, with_service},
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

#[flutter_rust_bridge::frb(dart_async)]
pub async fn start_worker() -> Result<(), String> {
    with_service(|_core| {
        //

        Ok(())
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_data() -> Result<BackgroundState, String> {
    with_service(get_background_state).await.map_err(Into::into)
}
