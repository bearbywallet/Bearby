use crate::frb_generated::StreamSink;
use lazy_static::lazy_static;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use zilpay::settings::notifications::NotificationState;

pub use zilpay::background::BackgroundSKParams;
pub use zilpay::background::{Background, BackgroundBip39Params};
pub use zilpay::config::key::PUB_KEY_SIZE;
pub use zilpay::config::key::SECRET_KEY_SIZE;
pub use zilpay::crypto::bip49::Bip49DerivationPath;
pub use zilpay::proto::address::Address;
pub use zilpay::proto::pubkey::PubKey;
pub use zilpay::proto::secret_key::SecretKey;
pub use zilpay::settings::common_settings::CommonSettings;
pub use zilpay::settings::theme::{Appearances, Theme};
pub use zilpay::settings::wallet_settings::WalletSettings;
pub use zilpay::wallet::account::Account;
pub use zilpay::wallet::ft::FToken;
pub use zilpay::wallet::wallet_data::AuthMethod;
pub use zilpay::wallet::wallet_data::WalletData;
pub use zilpay::wallet::wallet_types::WalletTypes;
pub use zilpay::wallet::LedgerParams;

pub struct SerivceBackground {
    pub running: bool,
    pub message_sink: Option<StreamSink<String>>,
    pub core: Arc<Background>,
}

lazy_static! {
    static ref BACKGROUND_SERVICE: RwLock<Option<SerivceBackground>> = RwLock::new(None);
}

impl SerivceBackground {
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
pub struct AccountInfo {
    pub addr: String,
    pub name: String,
}

impl From<&Account> for AccountInfo {
    fn from(account: &Account) -> Self {
        AccountInfo {
            addr: account.addr.auto_format(),
            name: account.name.clone(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct FTokenInfo {
    pub name: String,
    pub symbol: String,
    pub decimals: u8,
    pub addr: String,
    pub balances: HashMap<String, String>,
    pub default: bool,
}

impl From<&FToken> for FTokenInfo {
    fn from(ft: &FToken) -> Self {
        let balances: HashMap<String, String> = ft
            .balances
            .iter()
            .map(|(addr, balance)| (addr.auto_format(), balance.to_string()))
            .collect();

        FTokenInfo {
            balances,
            addr: ft.addr.auto_format(),
            name: ft.name.clone(),
            symbol: ft.symbol.clone(),
            decimals: ft.decimals,
            default: ft.default,
        }
    }
}

#[derive(Debug, Clone)]
pub struct WalletInfo {
    pub wallet_type: String,
    pub wallet_name: String,
    pub auth_type: String,
    pub settings: WalletSettings,
    pub wallet_address: String,
    pub accounts: Vec<AccountInfo>,
    pub selected_account: usize,
    pub tokens: Vec<FTokenInfo>,
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_wallets() -> Result<Vec<WalletInfo>, String> {
    if let Some(service) = BACKGROUND_SERVICE.read().await.as_ref() {
        let core = Arc::as_ref(&service.core);
        let wallets: Vec<WalletInfo> = core
            .wallets
            .iter()
            .map(|w| WalletInfo {
                auth_type: w.data.biometric_type.clone().into(),
                wallet_name: w.data.wallet_name.clone(),
                wallet_type: w.data.wallet_type.to_str(),
                settings: w.data.settings.clone(),
                wallet_address: w.data.wallet_address.clone(),
                accounts: w.data.accounts.iter().map(|v| v.into()).collect(),
                selected_account: w.data.selected_account,
                tokens: w.ftokens.iter().map(|v| v.into()).collect(),
            })
            .collect();

        Ok(wallets)
    } else {
        Err("Service is not running".to_string())
    }
}

#[derive(Debug)]
pub struct BackgroundNotificationState {
    pub transactions: bool,
    pub price: bool,
    pub security: bool,
    pub balance: bool,
}

impl From<&NotificationState> for BackgroundNotificationState {
    fn from(notify: &NotificationState) -> Self {
        BackgroundNotificationState {
            transactions: notify.transactions,
            price: notify.price,
            security: notify.security,
            balance: notify.balance,
        }
    }
}

impl From<NotificationState> for BackgroundNotificationState {
    fn from(state: NotificationState) -> Self {
        BackgroundNotificationState {
            transactions: state.transactions,
            price: state.price,
            security: state.security,
            balance: state.balance,
        }
    }
}

#[derive(Debug)]
pub struct BackgroundState {
    pub wallets: Vec<WalletInfo>,
    pub notifications_wallet_states: HashMap<usize, BackgroundNotificationState>,
    pub notifications_global_enabled: bool,
    pub locale: String,
    pub appearances: u8,
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_data() -> Result<BackgroundState, String> {
    if let Some(service) = BACKGROUND_SERVICE.read().await.as_ref() {
        let wallets: Vec<WalletInfo> = service
            .core
            .wallets
            .iter()
            .map(|w| WalletInfo {
                auth_type: w.data.biometric_type.clone().into(),
                wallet_name: w.data.wallet_name.clone(),
                wallet_type: w.data.wallet_type.to_str(),
                settings: w.data.settings.clone(),
                wallet_address: w.data.wallet_address.clone(),
                accounts: w.data.accounts.iter().map(|v| v.into()).collect(),
                selected_account: w.data.selected_account,
                tokens: w.ftokens.iter().map(|v| v.into()).collect(),
            })
            .collect();
        let state = BackgroundState {
            wallets,
            notifications_wallet_states: service
                .core
                .settings
                .notifications
                .wallet_states
                .iter()
                .map(|(k, v)| {
                    (
                        *k,
                        BackgroundNotificationState {
                            transactions: v.transactions,
                            price: v.price,
                            security: v.security,
                            balance: v.balance,
                        },
                    )
                })
                .collect(),
            notifications_global_enabled: service.core.settings.notifications.global_enabled,
            locale: service.core.settings.locale.to_string(),
            appearances: service.core.settings.theme.appearances.code(),
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
        let bg = SerivceBackground::from_path(path)?;
        let wallets: Vec<WalletInfo> = bg
            .core
            .wallets
            .iter()
            .map(|w| WalletInfo {
                auth_type: w.data.biometric_type.clone().into(),
                wallet_name: w.data.wallet_name.clone(),
                wallet_type: w.data.wallet_type.to_str(),
                settings: w.data.settings.clone(),
                wallet_address: w.data.wallet_address.clone(),
                accounts: w.data.accounts.iter().map(|v| v.into()).collect(),
                selected_account: w.data.selected_account,
                tokens: w.ftokens.iter().map(|v| v.into()).collect(),
            })
            .collect();
        let state = BackgroundState {
            wallets,
            notifications_wallet_states: bg
                .core
                .settings
                .notifications
                .wallet_states
                .iter()
                .map(|(k, v)| {
                    (
                        *k,
                        BackgroundNotificationState {
                            transactions: v.transactions,
                            price: v.price,
                            security: v.security,
                            balance: v.balance,
                        },
                    )
                })
                .collect(),

            notifications_global_enabled: bg.core.settings.notifications.global_enabled,
            locale: bg.core.settings.locale.to_string(),
            appearances: bg.core.settings.theme.appearances.code(),
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
    accouns: &[(usize, String)], // index, name
    passphrase: String,
    wallet_name: String,
    biometric_type: String,
    networks: &[usize],
    identifiers: &[String],
) -> Result<(String, String), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        // TODO: detect by networks indexies
        let derive_fn = Bip49DerivationPath::Zilliqa;
        let accounts_bip39: Vec<(Bip49DerivationPath, String)> = accouns
            .iter()
            .map(|(i, name)| (derive_fn(*i), name.clone()))
            .collect();

        let session = Arc::get_mut(&mut service.core)
            .ok_or("Cannot get mutable reference to core")?
            .add_bip39_wallet(BackgroundBip39Params {
                network: networks,
                password: &password,
                mnemonic_str: &mnemonic_str,
                accounts: &accounts_bip39,
                passphrase: &passphrase,
                wallet_name,
                biometric_type: biometric_type.into(),
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
pub async fn sync_balances(wallet_index: usize) -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        Arc::get_mut(&mut service.core)
            .ok_or("Cannot get mutable reference to core")?
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
        let mut address = Address::from_zil_base16(&addr);

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
pub async fn add_next_bip39_account(
    wallet_index: usize,
    account_index: usize,
    name: String,
    passphrase: String,
    identifiers: &[String],
    password: Option<String>,
    session_cipher: Option<String>,
) -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let core = Arc::get_mut(&mut service.core).ok_or("Cannot get mutable reference to core")?;
        let seed = if password.is_some() {
            core.unlock_wallet_with_password(
                &password.unwrap_or_default(),
                identifiers,
                wallet_index,
            )
            .map_err(|e| e.to_string())?
        } else {
            let session = hex::decode(session_cipher.unwrap_or_default())
                .map_err(|_| "Invalid Session cipher")?;

            core.unlock_wallet_with_session(session, identifiers, wallet_index)
                .map_err(|e| e.to_string())?
        };
        let wallet = core
            .wallets
            .get_mut(wallet_index)
            .ok_or("Fail to get mutable link to wallet".to_string())?;
        let first_account = wallet
            .data
            .accounts
            .first()
            .ok_or("fail to get first account".to_string())?;
        let bip49 = match first_account.pub_key {
            PubKey::Secp256k1Sha256Zilliqa(_) => Bip49DerivationPath::Zilliqa(account_index),
            PubKey::Secp256k1Keccak256Ethereum(_) => Bip49DerivationPath::Ethereum(account_index),
            _ => {
                return Err("Invalid account type".to_string());
            }
        };

        wallet
            .add_next_bip39_account(name, &bip49, &passphrase, &seed)
            .map_err(|e| e.to_string())?;

        Ok(())
    } else {
        Err("Service is not running".to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_ledger_account(
    wallet_index: usize,
    account_index: usize,
    name: String,
    pub_key: String,
    identifiers: &[String],
    session_cipher: Option<String>,
) -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let core = Arc::get_mut(&mut service.core).ok_or("Cannot get mutable reference to core")?;
        let session = hex::decode(session_cipher.unwrap_or_default())
            .map_err(|_| "Invalid Session cipher")?;

        core.unlock_wallet_with_session(session, identifiers, wallet_index)
            .map_err(|e| e.to_string())?;

        let wallet = core
            .wallets
            .get_mut(wallet_index)
            .ok_or("Fail to get mutable link to wallet".to_string())?;
        let first_account = wallet
            .data
            .accounts
            .first()
            .ok_or("fail to get first account".to_string())?;

        let pub_key = pub_key.strip_prefix("0x").unwrap_or(&pub_key);
        let pub_key: [u8; PUB_KEY_SIZE] = hex::decode(pub_key)
            .unwrap_or_default()
            .try_into()
            .or(Err("Invalid pub key size".to_string()))?;
        let pub_key = match first_account.pub_key {
            PubKey::Secp256k1Sha256Zilliqa(_) => PubKey::Secp256k1Sha256Zilliqa(pub_key),
            PubKey::Secp256k1Keccak256Ethereum(_) => PubKey::Secp256k1Keccak256Ethereum(pub_key),
            _ => {
                return Err("Invalid account type".to_string());
            }
        };

        wallet
            .add_ledger_account(name, &pub_key, account_index)
            .map_err(|e| e.to_string())?;

        Ok(())
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

#[flutter_rust_bridge::frb(dart_async)]
pub async fn select_account(wallet_index: usize, account_index: usize) -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        Arc::get_mut(&mut service.core)
            .ok_or("Cannot get mutable reference to core")?
            .wallets
            .get_mut(wallet_index)
            .ok_or("Fail to get mutable link to wallet".to_string())?
            .select_account(account_index)
            .map_err(|e| e.to_string())?;

        Ok(())
    } else {
        Err("Service is not running".to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_theme(appearances_code: u8) -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let new_theme = Theme {
            appearances: Appearances::from_code(appearances_code).map_err(|e| e.to_string())?,
        };

        Arc::get_mut(&mut service.core)
            .ok_or("Cannot get mutable reference to core")?
            .set_theme(new_theme)
            .map_err(|e| e.to_string())?;

        Ok(())
    } else {
        Err("Service is not running".to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_wallet_notifications(
    wallet_index: usize,
    transactions: bool,
    price: bool,
    security: bool,
    balance: bool,
) -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let core = Arc::get_mut(&mut service.core).ok_or("Cannot get mutable reference to core")?;

        core.settings.notifications.wallet_states.insert(
            wallet_index,
            NotificationState {
                transactions,
                price,
                security,
                balance,
            },
        );

        Ok(())
    } else {
        Err("Service is not running".to_string())
    }
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_global_notifications(global_enabled: bool) -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.write().await.as_mut() {
        let core = Arc::get_mut(&mut service.core).ok_or("Cannot get mutable reference to core")?;

        core.settings.notifications.global_enabled = global_enabled;

        Ok(())
    } else {
        Err("Service is not running".to_string())
    }
}
