use crate::frb_generated::StreamSink;
use lazy_static::lazy_static;
use std::sync::Arc;
use tokio::sync::RwLock;

pub use zilpay::background::Background;
pub use zilpay::crypto::bip49::Bip49DerivationPath;

pub struct Serivce {
    pub running: bool,
    pub message_sink: Option<StreamSink<String>>,
    pub core: Arc<Background>,
}

lazy_static! {
    static ref BACKGROUND_SERVICE: RwLock<Option<Serivce>> = RwLock::new(None);
}

impl Serivce {
    fn from_path(path: &str) -> Result<Self, String> {
        let core = Background::from_storage_path(path).map_err(|e| e.to_string())?;

        Ok(Self {
            core: Arc::new(core),
            running: true,
            message_sink: None,
        })
    }

    fn stop(&mut self) {
        self.running = false;
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn start_service(path: &str) -> Result<(), String> {
    let mut service = BACKGROUND_SERVICE.write().await;

    if service.is_none() {
        *service = Some(Serivce::from_path(path)?);
    }

    Ok(())
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn stop_service() -> Result<(), String> {
    let mut service = BACKGROUND_SERVICE.write().await;

    if let Some(background) = service.as_mut() {
        background.stop();
        *service = None;
        Ok(())
    } else {
        Err("Service is not running".to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn start_worker(_sink: StreamSink<String>) -> Result<(), String> {
    let service = BACKGROUND_SERVICE.read().await;

    if service.is_some() {
        return Err("Service is already running".to_string());
    }

    // thread::spawn(|| {
    //     background_worker();
    // });

    Ok(())
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn is_service_running() -> bool {
    BACKGROUND_SERVICE.read().await.is_some()
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_bip39_wallet(
    password: &str,
    mnemonic_str: &str,
    indexes: &[usize],
    _net_codes: &[usize], // TODO: add netowrk codes for wallet
) -> Result<String, String> {
    // TODO: // detect by networks.
    let derive = Bip49DerivationPath::Zilliqa;

    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let key = Arc::get_mut(&mut service.core)
            .ok_or("Cannot get mutable reference to core")?
            .add_bip39_wallet(password, mnemonic_str, indexes, derive)
            .map_err(|e| e.to_string())?;
        let key_str = hex::encode(key);

        Ok(key_str)
    } else {
        Err("Service is not running".to_string())
    }
}
