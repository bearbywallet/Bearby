use zilpay::{
    background::{BackgroundBip39Params, BackgroundSKParams},
    config::key::{PUB_KEY_SIZE, SECRET_KEY_SIZE},
    crypto::bip49::Bip49DerivationPath,
    proto::{address::Address, pubkey::PubKey, secret_key::SecretKey},
    settings::{
        notifications::NotificationState,
        theme::{Appearances, Theme},
    },
    wallet::{ft::FToken, LedgerParams},
};

use crate::{
    frb_generated::StreamSink,
    models::{background::BackgroundState, wallet::WalletInfo},
    service::service::{ServiceBackground, BACKGROUND_SERVICE},
    utils::utils::{
        decode_session, get_background_state, wallet_info_from_wallet, with_service,
        with_service_mut, with_wallet_mut, IntoServiceError, ServiceError,
    },
};

#[flutter_rust_bridge::frb(dart_async)]
pub async fn start_service(path: &str) -> Result<BackgroundState, String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    if guard.is_none() {
        let bg = ServiceBackground::from_path(path)?;
        let state = get_background_state(&bg)?;
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

#[flutter_rust_bridge::frb(dart_async)]
pub async fn is_service_running() -> bool {
    BACKGROUND_SERVICE.read().await.is_some()
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn start_worker(sink: StreamSink<String>) -> Result<(), String> {
    let service = BACKGROUND_SERVICE.read().await;
    if service.is_some() {
        return Err("Service is already running".to_string());
    }
    Ok(())
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_wallets() -> Result<Vec<WalletInfo>, String> {
    with_service(|core| Ok(core.wallets.iter().map(wallet_info_from_wallet).collect()))
        .await
        .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_data() -> Result<BackgroundState, String> {
    with_service(get_background_state).await.map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn try_unlock_with_password(
    password: String,
    wallet_index: usize,
    identifiers: &[String],
) -> Result<bool, String> {
    with_service_mut(|core| {
        core.unlock_wallet_with_password(&password, identifiers, wallet_index)
            .service_err()?;
        Ok(true)
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn try_unlock_with_session(
    session_cipher: String,
    wallet_index: usize,
    identifiers: &[String],
) -> Result<bool, String> {
    let session = decode_session(Some(session_cipher))?;
    with_service_mut(|core| {
        core.unlock_wallet_with_session(session, identifiers, wallet_index)
            .service_err()?;
        Ok(true)
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_bip39_wallet(
    password: String,
    mnemonic_str: String,
    accounts: &[(usize, String)],
    passphrase: String,
    wallet_name: String,
    biometric_type: String,
    networks: &[usize],
    identifiers: &[String],
) -> Result<(String, String), String> {
    with_service_mut(|core| {
        let accounts_bip39 = accounts
            .iter()
            .map(|(i, name)| (Bip49DerivationPath::Zilliqa(*i), name.clone()))
            .collect::<Vec<_>>();

        let session = core
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
            .service_err()?;

        let wallet = core
            .wallets
            .last()
            .ok_or(ServiceError::Custom("Failed to save wallet".into()))?;

        Ok((hex::encode(session), wallet.data.wallet_address.clone()))
    })
    .await
    .map_err(Into::into)
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
    with_service_mut(|core| {
        let sk = sk.strip_prefix("0x").unwrap_or(&sk);
        let secret_key: [u8; SECRET_KEY_SIZE] = hex::decode(sk)
            .map_err(|_| ServiceError::Custom("Failed to decode key".into()))?
            .try_into()
            .map_err(|_| ServiceError::Custom("Invalid Secret key length".into()))?;

        let secret_key = SecretKey::Secp256k1Sha256Zilliqa(secret_key);
        let session = core
            .add_sk_wallet(BackgroundSKParams {
                network: networks,
                secret_key: &secret_key,
                account_name,
                wallet_name,
                biometric_type: biometric_type.into(),
                password: &password,
                device_indicators: identifiers,
            })
            .service_err()?;

        let wallet = core
            .wallets
            .last()
            .ok_or(ServiceError::Custom("Failed to save wallet".into()))?;

        Ok((hex::encode(session), wallet.data.wallet_address.clone()))
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_ledger_wallet(
    pub_key: String,
    wallet_index: usize,
    wallet_name: String,
    ledger_id: String,
    account_name: String,
    biometric_type: String,
    identifiers: &[String],
) -> Result<(String, String), String> {
    with_service_mut(|core| {
        let pub_key_bytes: [u8; PUB_KEY_SIZE] = hex::decode(pub_key)
            .service_err()?
            .try_into()
            .map_err(|_| ServiceError::Custom("Invalid public key".into()))?;

        let pub_key = PubKey::Secp256k1Sha256Zilliqa(pub_key_bytes);
        let params = LedgerParams {
            networks: vec![0],
            pub_key: &pub_key,
            ledger_id: ledger_id.as_bytes().to_vec(),
            name: account_name,
            wallet_index,
            wallet_name,
            biometric_type: biometric_type.into(),
        };

        let session = core.add_ledger_wallet(params, identifiers).service_err()?;
        let wallet = core
            .wallets
            .last()
            .ok_or(ServiceError::Custom("Failed to save wallet".into()))?;

        Ok((hex::encode(session), wallet.data.wallet_address.clone()))
    })
    .await
    .map_err(Into::into)
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
    with_service_mut(|core| {
        let seed = if let Some(pass) = password {
            core.unlock_wallet_with_password(&pass, identifiers, wallet_index)
        } else {
            let session = decode_session(session_cipher).service_err()?;
            core.unlock_wallet_with_session(session, identifiers, wallet_index)
        }
        .service_err()?;

        let wallet = core
            .wallets
            .get_mut(wallet_index)
            .ok_or(ServiceError::WalletAccess(wallet_index))?;

        let first_account = wallet
            .data
            .accounts
            .first()
            .ok_or(ServiceError::Custom("Failed to get first account".into()))?;

        let bip49 = match first_account.pub_key {
            PubKey::Secp256k1Sha256Zilliqa(_) => Bip49DerivationPath::Zilliqa(account_index),
            PubKey::Secp256k1Keccak256Ethereum(_) => Bip49DerivationPath::Ethereum(account_index),
            _ => return Err(ServiceError::Custom("Invalid account type".into())),
        };

        wallet
            .add_next_bip39_account(name, &bip49, &passphrase, &seed)
            .service_err()
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn select_account(wallet_index: usize, account_index: usize) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        wallet.select_account(account_index).service_err()
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sync_balances(wallet_index: usize) -> Result<(), String> {
    with_service_mut(|core| core.sync_ftokens_balances(wallet_index).await.service_err())
        .await
        .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn fetch_token_meta(addr: String, wallet_index: usize) -> Result<FToken, String> {
    with_service(|core| {
        let address = Address::from_zil_base16(&addr)
            .or_else(|_| Address::from_zil_bech32(&addr))
            .or_else(|_| Address::from_eth_address(&addr))
            .service_err()?;

        core.get_ftoken_meta(wallet_index, address)
            .await
            .service_err()
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_theme(appearances_code: u8) -> Result<(), String> {
    with_service_mut(|core| {
        let new_theme = Theme {
            appearances: Appearances::from_code(appearances_code).service_err()?,
        };
        core.set_theme(new_theme).service_err()
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_wallet_notifications(
    wallet_index: usize,
    transactions: bool,
    price: bool,
    security: bool,
    balance: bool,
) -> Result<(), String> {
    with_service_mut(|core| {
        core.set_wallet_notifications(
            wallet_index,
            NotificationState {
                transactions,
                price,
                security,
                balance,
            },
        )
        .service_err()
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_global_notifications(global_enabled: bool) -> Result<(), String> {
    with_service_mut(|core| core.set_global_notifications(global_enabled).service_err())
        .await
        .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_rate_fetcher(wallet_index: usize, currency: Option<String>) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        wallet.data.settings.features.currency_convert = currency;
        wallet.save_to_storage().service_err()
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_wallet_ens(wallet_index: usize, ens_enabled: bool) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        wallet.data.settings.features.ens_enabled = ens_enabled;
        wallet.save_to_storage().service_err()
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_wallet_ipfs_node(wallet_index: usize, node: Option<String>) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        wallet.data.settings.features.ipfs_node = node;
        wallet.save_to_storage().service_err()
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_wallet_gas_control(wallet_index: usize, enabled: bool) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        wallet.data.settings.network.gas_control_enabled = enabled;
        wallet.save_to_storage().service_err()
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn set_wallet_node_ranking(wallet_index: usize, enabled: bool) -> Result<(), String> {
    with_wallet_mut(wallet_index, |wallet| {
        wallet.data.settings.network.node_ranking_enabled = enabled;
        wallet.save_to_storage().service_err()
    })
    .await
    .map_err(Into::into)
}
