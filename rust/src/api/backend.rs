use crate::frb_generated::StreamSink;
use lazy_static::lazy_static;
use std::thread;
use tokio::sync::RwLock;
use zilpay::background::Background;
use zilpay::crypto::bip49::Bip49DerivationPath;

// fn background_worker() {
//     while {
//         let service = BACKGROUND_SERVICE.read();
//         service.as_ref().map(|s| s.running).unwrap_or(false)
//     } {
//         let service = BACKGROUND_SERVICE.read();

//         if let Some(background) = service.as_ref() {
//             if let Some(sink) = &background.message_sink {
//                 // sink.add("Background message").unwrap_or_else(|e| {
//                 //     eprintln!("Error sending message: {}", e);
//                 // });
//             }
//         }

//         drop(service);

//         thread::sleep(std::time::Duration::from_secs(1));
//     }
// }

pub struct Serivce {
    pub running: bool,
    pub message_sink: Option<StreamSink<String>>,
    pub core: Background,
}

lazy_static! {
    static ref BACKGROUND_SERVICE: RwLock<Option<Serivce>> = RwLock::new(None);
}

impl Serivce {
    fn from_path(path: &str) -> Result<Self, String> {
        let core = Background::from_storage_path(path).map_err(|e| e.to_string())?;

        Ok(Self {
            core,
            running: true,
            message_sink: None,
        })
    }

    // fn new(sink: StreamSink<String>) -> Self {
    //     Self {
    //         running: true,
    //         message_sink: Some(sink),
    //     }
    // }

    fn stop(&mut self) {
        self.running = false;
    }
}

#[flutter_rust_bridge::frb(sync)]
pub async fn start_service(path: &str) -> Result<(), String> {
    let mut service = BACKGROUND_SERVICE.write().await;

    if service.is_none() {
        *service = Some(Serivce::from_path(path)?);
    }

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
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

#[flutter_rust_bridge::frb(sync)]
pub async fn start_worker(sink: StreamSink<String>) -> Result<(), String> {
    let service = BACKGROUND_SERVICE.read().await;

    if service.is_some() {
        return Err("Service is already running".to_string());
    }

    // thread::spawn(|| {
    //     background_worker();
    // });

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub async fn is_service_running() -> bool {
    BACKGROUND_SERVICE.read().await.is_some()
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_bip39_wallet(
    password: &str,
    mnemonic_str: &str,
    indexes: &[usize],
    net_codes: &[usize],
) -> Result<String, String> {
    let derive = Bip49DerivationPath::Zilliqa;
    let service = BACKGROUND_SERVICE.read().await.as_ref();

    Ok(String::new())
    // BACKGROUND_SERVICE.read().and_then(|guard| {}) {
    // if let Some(service) = BACKGROUND_SERVICE.read() {}

    // Background::add_bip39_wallet(password, mnemonic_str, indexes, , ).map_err(|e| e.to_string())
}
