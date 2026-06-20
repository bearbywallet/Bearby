use std::sync::Arc;
use zilpay::rpc::network_config::ChainConfig;
use zilpay::{background::bg_settings::SettingsManagement, crypto::slip44};
pub use zilpay::{
    background::Background,
    config::key::{PUB_KEY_SIZE, SECRET_KEY_SIZE},
    proto::{address::Address, pubkey::PubKey, secret_key::SecretKey},
    wallet::{wallet_data::WalletDataV2, Wallet, WalletAddrType},
};
pub use zilpay::{
    background::{bg_provider::ProvidersManagement, bg_wallet::WalletManagement},
    crypto::bip49::DerivationPath,
    errors::{background::BackgroundError, wallet::WalletErrors},
};

use crate::{
    models::{background::BackgroundState, wallet::WalletInfo},
    service::background::BACKGROUND_SERVICE,
};

use super::errors::ServiceError;

pub fn script_to_address(script: &[u8], network: zilpay::bitcoin::Network) -> Option<String> {
    zilpay::bitcoin::Address::from_script(zilpay::bitcoin::Script::from_bytes(script), network)
        .ok()
        .map(|a| a.to_string())
}

pub fn parse_address(addr: String) -> Result<Address, ServiceError> {
    Address::from_str_hex(&addr).map_err(ServiceError::AddressError)
}

pub fn decode_session(session_cipher: Option<String>) -> Result<Vec<u8>, ServiceError> {
    zilpay::alloy::hex::decode(session_cipher.unwrap_or_default())
        .map_err(|_| ServiceError::DecodeSession)
}

pub fn decode_secret_key(sk: &str) -> Result<[u8; SECRET_KEY_SIZE], ServiceError> {
    let sk = sk.strip_prefix("0x").unwrap_or(sk);
    zilpay::alloy::hex::decode(sk)
        .map_err(|_| ServiceError::DecodeSecretKey)?
        .try_into()
        .map_err(|_| ServiceError::InvalidSecretKeyLength)
}

pub fn pubkey_from_provider(
    pub_key: &str,
    chain_config: &ChainConfig,
    zilliqa_legacy: bool,
) -> Result<PubKey, ServiceError> {
    let pub_key = match chain_config.slip_44 {
        slip44::SOLANA => {
            let bytes =
                zilpay::alloy::hex::decode(pub_key).map_err(|_| ServiceError::DecodePublicKey)?;
            let mut prefixed = vec![3u8];
            prefixed.extend_from_slice(&bytes);
            PubKey::try_from(prefixed.as_slice())?
        }
        _ => {
            let pub_key_vec = PubKey::from_uncompressed_hex(pub_key)?;
            let pub_key_bytes: [u8; PUB_KEY_SIZE] = pub_key_vec
                .try_into()
                .map_err(|_| ServiceError::InvalidPublicKeyLength)?;

            match (chain_config.slip_44, zilliqa_legacy) {
                (slip44::ZILLIQA, true) => PubKey::Secp256k1Sha256(pub_key_bytes),
                (slip44::ZILLIQA, false) => PubKey::Secp256k1Keccak256(pub_key_bytes),
                (slip44::ETHEREUM, _) => PubKey::Secp256k1Keccak256(pub_key_bytes),
                (slip44::BITCOIN, _) => {
                    let network = chain_config
                        .bitcoin_network()
                        .unwrap_or(zilpay::bitcoin::Network::Bitcoin);
                    let addr_type = chain_config
                        .ftokens
                        .iter()
                        .find(|t| t.native)
                        .and_then(|t| t.addr.get_bitcoin_address_type().ok())
                        .unwrap_or(zilpay::bitcoin::AddressType::P2wpkh);

                    PubKey::Secp256k1Bitcoin((pub_key_bytes, network, addr_type))
                }
                (slip44::TRON, _) => PubKey::Secp256k1Tron(pub_key_bytes),
                _ => return Err(ServiceError::AccountTypeNotValid),
            }
        }
    };

    Ok(pub_key)
}

pub fn secretkey_from_provider(
    secret_key: &str,
    chain_config: &ChainConfig,
) -> Result<SecretKey, ServiceError> {
    let trimmed = secret_key.trim();

    let sk = match chain_config.slip_44 {
        slip44::ETHEREUM | slip44::ZILLIQA => {
            let sk = trimmed.strip_prefix("0x").unwrap_or(trimmed);
            let secret_key_bytes = decode_secret_key(sk)?;
            SecretKey::Secp256k1Keccak256Ethereum(secret_key_bytes)
        }
        slip44::BITCOIN => {
            let addr_type = chain_config
                .ftokens
                .iter()
                .find(|t| t.native)
                .and_then(|t| t.addr.get_bitcoin_address_type().ok())
                .unwrap_or(zilpay::bitcoin::AddressType::P2wpkh);
            let network = chain_config
                .bitcoin_network()
                .unwrap_or(zilpay::bitcoin::Network::Bitcoin);

            if let Ok(sk_from_wif) = SecretKey::from_wif(trimmed, addr_type) {
                sk_from_wif
            } else {
                let sk = trimmed.strip_prefix("0x").unwrap_or(trimmed);
                let secret_key_bytes = decode_secret_key(sk)?;

                SecretKey::Secp256k1Bitcoin((secret_key_bytes, network, addr_type))
            }
        }
        slip44::TRON => {
            let sk = trimmed.strip_prefix("0x").unwrap_or(trimmed);
            let secret_key_bytes = decode_secret_key(sk)?;
            SecretKey::Secp256k1Tron(secret_key_bytes)
        }
        _ => {
            return Err(ServiceError::AccountTypeNotValid);
        }
    };

    Ok(sk)
}

pub fn get_background_state(service: &Background) -> Result<BackgroundState, ServiceError> {
    let providers = service.get_providers();
    let settings = service.get_global_settings();
    let wallets = service
        .wallets
        .iter()
        .map(|w| w.try_into())
        .collect::<Result<Vec<WalletInfo>, WalletErrors>>()
        .map_err(BackgroundError::WalletError)?;

    let notifications_wallet_states = settings
        .notifications
        .wallet_states
        .iter()
        .map(|(k, v)| (*k, v.into()))
        .collect();

    Ok(BackgroundState {
        wallets,
        notifications_wallet_states,
        browser_settings: settings.browser.clone().into(),
        notifications_global_enabled: settings.notifications.global_enabled,
        locale: settings.locale.clone(),
        appearances: settings.theme.appearances.code(),
        abbreviated_number: settings.theme.compact_numbers,
        providers: providers.into_iter().map(|p| p.config.into()).collect(),
    })
}

pub fn get_last_wallet(service: &Background) -> Result<&Wallet, ServiceError> {
    service.wallets.last().ok_or(ServiceError::FailToSaveWallet)
}

/// Lock-free read: a single atomic load, zero `.await`, never contends with
/// writers. Returns a shared `Arc<Background>` snapshot.
pub async fn handle() -> Result<Arc<Background>, ServiceError> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    service
        .core
        .load_full()
        .ok_or(ServiceError::NotRunning)
}

/// Copy-on-write mutation. Loads the current snapshot, clones it, applies `f`
/// to the clone, then atomically publishes the result. Serialized by
/// `ServiceBackground::mutation_mutex` to prevent lost-update races between
/// concurrent mutations.
pub async fn mutate_core<F, T>(f: F) -> Result<T, ServiceError>
where
    F: FnOnce(&mut Background) -> Result<T, ServiceError>,
{
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let _lock = service.mutation_mutex.lock().await;
    let current = service
        .core
        .load_full()
        .ok_or(ServiceError::NotRunning)?;
    let mut next = (*current).clone();
    let result = f(&mut next)?;

    service.core.store(Some(Arc::new(next)));

    Ok(result)
}

/// Copy-on-write mutation with an async closure.
///
/// **NB**: the mutation mutex is held across the `.await` in `f` — every
/// concurrent `mutate_core` or `mutate_core_async` call blocks for the
/// duration. Use only for fast structural changes (add/delete wallet,
/// keystore restore); do **not** use for long network I/O. For network-heavy
/// work, fetch data via `handle()` first, then install results with the sync
/// [`mutate_core`].
///
/// Readers (`handle()`) are **never** blocked — they see the pre-mutation
/// snapshot until `store` publishes the result.
pub async fn mutate_core_async<F, T>(f: F) -> Result<T, ServiceError>
where
    F: for<'a> AsyncFnOnce(&'a mut Background) -> Result<T, ServiceError>,
{
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let _lock = service.mutation_mutex.lock().await;
    let current = service
        .core
        .load_full()
        .ok_or(ServiceError::NotRunning)?;
    let mut next = (*current).clone();
    let result = f(&mut next).await?;

    service.core.store(Some(Arc::new(next)));

    Ok(result)
}

pub async fn with_service<F, T>(f: F) -> Result<T, ServiceError>
where
    F: FnOnce(&Background) -> Result<T, ServiceError>,
{
    let core = handle().await?;

    f(&core)
}

pub async fn with_service_mut<F, T>(f: F) -> Result<T, ServiceError>
where
    F: FnOnce(&mut Background) -> Result<T, ServiceError>,
{
    mutate_core(f).await
}

pub async fn with_wallet_mut<F, T>(wallet_index: usize, f: F) -> Result<T, ServiceError>
where
    F: FnOnce(&mut Wallet) -> Result<T, ServiceError>,
{
    mutate_core(|core| {
        let wallet = core
            .wallets
            .get_mut(wallet_index)
            .ok_or(ServiceError::WalletAccess(wallet_index))?;

        f(wallet)
    })
    .await
}

pub async fn with_wallet<F, T>(wallet_index: usize, f: F) -> Result<T, ServiceError>
where
    F: FnOnce(&Wallet) -> Result<T, ServiceError>,
{
    let core = handle().await?;
    let wallet = core.get_wallet_by_index(wallet_index)?;

    f(wallet)
}
