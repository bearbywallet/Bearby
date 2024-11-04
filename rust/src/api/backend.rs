use crate::frb_generated::StreamSink;
use lazy_static::lazy_static;
use std::sync::Arc;
use tokio::sync::RwLock;

pub use zilpay::background::Background;
pub use zilpay::crypto::bip49::Bip49DerivationPath;
pub use zilpay::settings::common_settings::CommonSettings;
pub use zilpay::settings::wallet_settings::WalletSettings;
pub use zilpay::wallet::account::Account;
pub use zilpay::wallet::wallet_types::WalletTypes;

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

#[derive(Debug, Clone)]
pub struct WalletInfo {
    pub wallet_type: u8,
    pub settings: WalletSettings,
    pub wallet_address: String,
    pub accounts: Vec<Account>,
    pub selected_account: usize,
    pub enabled: bool,
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_wallets() -> Result<Vec<WalletInfo>, String> {
    if let Some(service) = BACKGROUND_SERVICE.read().await.as_ref() {
        let core = Arc::as_ref(&service.core);
        let wallets: Vec<WalletInfo> = core
            .wallets
            .iter()
            .map(|w| WalletInfo {
                wallet_type: w.data.wallet_type.code(),
                settings: w.data.settings.clone(),
                wallet_address: w.data.wallet_address.clone(),
                accounts: w.data.accounts.clone(),
                selected_account: w.data.selected_account,
                enabled: w.is_enabled(),
            })
            .collect();

        Ok(wallets)
    } else {
        Err("Service is not running".to_string())
    }
}

#[derive(Debug)]
pub struct BackgroundState {
    pub wallets: Vec<WalletInfo>,
    pub settings: CommonSettings,
    pub selected: usize,
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn start_service(path: &str) -> Result<BackgroundState, String> {
    let mut service = BACKGROUND_SERVICE.write().await;

    if service.is_none() {
        let bg = Serivce::from_path(path)?;
        let wallets: Vec<WalletInfo> = bg
            .core
            .wallets
            .iter()
            .map(|w| WalletInfo {
                wallet_type: w.data.wallet_type.code(),
                settings: w.data.settings.clone(),
                wallet_address: w.data.wallet_address.clone(),
                accounts: w.data.accounts.clone(),
                selected_account: w.data.selected_account,
                enabled: w.is_enabled(),
            })
            .collect();
        let selected = 0;
        let state = BackgroundState {
            wallets,
            selected,
            settings: bg.core.settings.clone(),
        };

        *service = Some(bg);

        return Ok(state);
    }

    Err("service already running".to_string())
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
