use crate::frb_generated::StreamSink;
use lazy_static::lazy_static;
use std::sync::Arc;
use tokio::sync::RwLock;
use zilpay::proto::address::Address;

pub use zilpay::background::BackgroundSKParams;
pub use zilpay::background::{Background, BackgroundBip39Params};
pub use zilpay::config::key::PUB_KEY_SIZE;
pub use zilpay::config::key::SECRET_KEY_SIZE;
pub use zilpay::crypto::bip49::Bip49DerivationPath;
pub use zilpay::proto::pubkey::PubKey;
pub use zilpay::proto::secret_key::SecretKey;
pub use zilpay::settings::common_settings::CommonSettings;
pub use zilpay::settings::wallet_settings::WalletSettings;
pub use zilpay::wallet::account::Account;
pub use zilpay::wallet::ft::FToken;
pub use zilpay::wallet::wallet_data::AuthMethod;
pub use zilpay::wallet::wallet_data::WalletData;
pub use zilpay::wallet::wallet_types::WalletTypes;
pub use zilpay::wallet::LedgerParams;

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
    pub wallet_name: String,
    pub auth_type: String,
    pub settings: WalletSettings,
    pub wallet_address: String,
    pub accounts: Vec<Account>,
    pub selected_account: usize,
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_wallets() -> Result<Vec<WalletInfo>, String> {
    if let Some(service) = BACKGROUND_SERVICE.read().await.as_ref() {
        let core = Arc::as_ref(&service.core);
        let wallets: Vec<WalletInfo> = core
            .wallets
            .iter()
            .map(|w| WalletInfo {
                auth_type: w.data.biometric_type.into(),
                wallet_name: w.data.wallet_name.clone(),
                wallet_type: w.data.wallet_type.code(),
                settings: w.data.settings.clone(),
                wallet_address: w.data.wallet_address.clone(),
                accounts: w.data.accounts.clone(),
                selected_account: w.data.selected_account,
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
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_data() -> Result<BackgroundState, String> {
    if let Some(service) = BACKGROUND_SERVICE.read().await.as_ref() {
        let wallets: Vec<WalletInfo> = service
            .core
            .wallets
            .iter()
            .map(|w| WalletInfo {
                auth_type: w.data.biometric_type.into(),
                wallet_name: w.data.wallet_name.clone(),
                wallet_type: w.data.wallet_type.code(),
                settings: w.data.settings.clone(),
                wallet_address: w.data.wallet_address.clone(),
                accounts: w.data.accounts.clone(),
                selected_account: w.data.selected_account,
            })
            .collect();
        let state = BackgroundState {
            wallets,
            settings: service.core.settings.clone(),
        };

        return Ok(state);
    }

    Err("service is not running".to_string())
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn try_unlock_with_password(
    password: String,
    wallet_index: usize,
    identifiers: &[String],
) -> Result<bool, String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        Arc::get_mut(&mut service.core)
            .ok_or("Cannot get mutable reference to core")?
            .unlock_wallet_with_password(&password, identifiers, wallet_index)
            .map_err(|e| e.to_string())?;

        return Ok(true);
    }

    Err("service is not running".to_string())
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn try_unlock_with_session(
    session_cipher: String,
    wallet_index: usize,
    identifiers: &[String],
) -> Result<bool, String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let session = hex::decode(session_cipher).map_err(|_| "Invalid Session cipher")?;

        Arc::get_mut(&mut service.core)
            .ok_or("Cannot get mutable reference to core")?
            .unlock_wallet_with_session(session, identifiers, wallet_index)
            .map_err(|e| e.to_string())?;

        return Ok(true);
    }

    Err("service is not running".to_string())
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
                auth_type: w.data.biometric_type.into(),
                wallet_name: w.data.wallet_name.clone(),
                wallet_type: w.data.wallet_type.code(),
                settings: w.data.settings.clone(),
                wallet_address: w.data.wallet_address.clone(),
                accounts: w.data.accounts.clone(),
                selected_account: w.data.selected_account,
            })
            .collect();
        let state = BackgroundState {
            wallets,
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
    password: String,
    mnemonic_str: String,
    indexes: &[usize],
    passphrase: String,
    wallet_name: String,
    biometric_type: String,
    networks: Vec<usize>,
    identifiers: &[String],
) -> Result<(String, String), String> {
    // TODO: // detect by networks. here need to think about zilliqa (scilla, evm)
    let derive = Bip49DerivationPath::Zilliqa;

    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let session = Arc::get_mut(&mut service.core)
            .ok_or("Cannot get mutable reference to core")?
            .add_bip39_wallet(
                BackgroundBip39Params {
                    network: networks,
                    password: &password,
                    mnemonic_str: &mnemonic_str,
                    indexes,
                    passphrase: &passphrase,
                    wallet_name,
                    biometric_type: biometric_type.into(),
                    device_indicators: identifiers,
                },
                derive,
            )
            .map_err(|e| e.to_string())?;
        let cipher_session = hex::encode(session);
        let wallet = service
            .core
            .wallets
            .last()
            .ok_or("Fail to Save wallet".to_string())?;

        Ok((cipher_session, wallet.data.wallet_address.clone()))
    } else {
        Err("Service is not running".to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_sk_wallet(
    sk: String,
    password: String,
    account_name: String,
    wallet_name: String,
    biometric_type: String,
    identifiers: &[String],
    networks: Vec<usize>,
) -> Result<(String, String), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let secret_key: [u8; SECRET_KEY_SIZE] = hex::decode(sk)
            .map_err(|_| "Fail to decode key".to_string())?
            .try_into()
            .map_err(|_| "Invlid Secret key len".to_string())?;
        let secret_key = SecretKey::Secp256k1Sha256Zilliqa(secret_key); // TODO: detect by network
        let session = Arc::get_mut(&mut service.core)
            .ok_or("Cannot get mutable reference to core")?
            .add_sk_wallet(BackgroundSKParams {
                network: networks,
                secret_key: &secret_key,
                account_name,
                wallet_name,
                biometric_type: biometric_type.into(),
                password: &password,
                device_indicators: identifiers,
            })
            .map_err(|e| e.to_string())?;
        let cipher_session = hex::encode(session);
        let wallet = service
            .core
            .wallets
            .last()
            .ok_or("Fail to Save wallet".to_string())?;

        Ok((cipher_session, wallet.data.wallet_address.clone()))
    } else {
        Err("Service is not running".to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sync_balances(wallet_index: usize) -> Result<(String, String), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        service
            .core
            .sync_ftokens_balances(wallet_index)
            .await
            .map_err(|e| e.to_string())?;

        Ok(())
    } else {
        Err("Service is not running".to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn fetch_token_meta(addr: String, wallet_index: usize) -> Result<FToken, String> {
    if let Some(service) = BACKGROUND_SERVICE.read().await.as_ref() {
        let address = Address::from_zil_base16(&addr);

        if address.is_err() {
            address = Address::from_zil_bech32(&addr);
        }

        if address.is_err() {
            address = Address::from_eth_address(&addr);
        }

        let parsed_addr = address.map_err(|e| e.to_string())?;

        let token = service
            .core
            .get_ftoken_meta(wallet_index, parsed_addr)
            .await
            .map_err(|e| e.to_string())?;

        Ok(token)
    } else {
        Err("Service is not running".to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_ledger_zilliqa_wallet(
    pub_key: String,
    wallet_index: usize,
    wallet_name: String,
    ledger_id: String,
    account_name: String,
    biometric_type: String,
    identifiers: &[String],
) -> Result<(String, String), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let pub_key_bytes: [u8; PUB_KEY_SIZE] = hex::decode(pub_key)
            .map_err(|e| e.to_string())?
            .try_into()
            .map_err(|_| "invlid pub_key".to_string())?;
        let pub_key = PubKey::Secp256k1Sha256Zilliqa(pub_key_bytes);
        let parmas = LedgerParams {
            networks: vec![0], // TODO: 0 means zilliqa
            pub_key: &pub_key,
            ledger_id: ledger_id.as_bytes().to_vec(),
            name: account_name,
            wallet_index,
            wallet_name,
            biometric_type: biometric_type.into(),
        };
        let session = Arc::get_mut(&mut service.core)
            .ok_or("Cannot get mutable reference to core")?
            .add_ledger_wallet(parmas, identifiers)
            .map_err(|e| e.to_string())?;
        let cipher_session = hex::encode(session);
        let wallet = service
            .core
            .wallets
            .last()
            .ok_or("Fail to Save wallet".to_string())?;

        Ok((cipher_session, wallet.data.wallet_address.clone()))
    } else {
        Err("Service is not running".to_string())
    }
}
