use std::str::FromStr;
use std::sync::Arc;

use secrecy::zeroize::Zeroize;
use secrecy::SecretString;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_storage::StorageManagement;
use zilpay::errors::background::BackgroundError;
use zilpay::errors::token::TokenError;
use zilpay::errors::wallet::WalletErrors;
use zilpay::proto::address::Address;
use zilpay::token::ft::FToken;
use zilpay::wallet::wallet_crypto::WalletCrypto;
use zilpay::wallet::wallet_storage::StorageOperations;
pub use zilpay::{
    background::bg_wallet::WalletManagement, wallet::wallet_account::AccountManagement,
};
pub use zilpay::{
    background::{BackgroundBip39Params, BackgroundSKParams},
    crypto::bip49::DerivationPath,
    proto::{pubkey::PubKey, secret_key::SecretKey},
};

use crate::models::ftoken::FTokenInfo;
use crate::models::keypair::KeyPairInfo;
use crate::models::settings::WalletSettingsInfo;
use crate::service::service::BACKGROUND_SERVICE;
use crate::utils::utils::{secretkey_from_provider, with_wallet};
use crate::{
    models::wallet::WalletInfo,
    utils::{errors::ServiceError, utils::with_service},
};

use super::provider::select_accounts_chain;

pub async fn get_wallets() -> Result<Vec<WalletInfo>, String> {
    with_service(|core| {
        let wallets = core
            .wallets
            .iter()
            .map(|w| w.try_into())
            .collect::<Result<Vec<WalletInfo>, WalletErrors>>()
            .map_err(BackgroundError::WalletError)?;

        Ok(wallets)
    })
    .await
    .map_err(Into::into)
}

pub struct Bip39AddWalletParams {
    pub password: String,
    pub mnemonic_str: String,
    pub mnemonic_check: bool,
    pub accounts: Vec<(usize, String)>,
    pub passphrase: String,
    pub wallet_name: String,
    pub biometric_type: String,
    pub chain_hash: u64,
    pub bip_purpose: u32,
}

pub async fn add_bip39_wallet(
    params: Bip39AddWalletParams,
    wallet_settings: WalletSettingsInfo,
    additional_ftokens: Vec<FTokenInfo>,
) -> Result<String, String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;

    let provider = service
        .core
        .get_provider(params.chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let net = provider.config.bitcoin_network();
    let accounts_bip49 = params
        .accounts
        .into_iter()
        .map(|(i, name)| {
            (
                DerivationPath::new(provider.config.slip_44, i, params.bip_purpose, net),
                name,
            )
        })
        .collect::<Vec<(DerivationPath, String)>>();
    let ftokens = additional_ftokens
        .into_iter()
        .map(TryFrom::try_from)
        .collect::<Result<Vec<FToken>, TokenError>>()
        .map_err(ServiceError::TokenError)?;
    let wallet_settings = wallet_settings
        .try_into()
        .map_err(ServiceError::SettingsError)?;
    let password = SecretString::new(params.password.into());
    Arc::get_mut(&mut service.core)
        .ok_or(ServiceError::CoreAccess)?
        .add_bip39_wallet(BackgroundBip39Params {
            ftokens,
            wallet_settings,
            mnemonic_check: params.mnemonic_check,
            chain_hash: params.chain_hash,
            password: &password,
            mnemonic_str: &params.mnemonic_str,
            accounts: &accounts_bip49,
            passphrase: &params.passphrase,
            wallet_name: params.wallet_name,
            biometric_type: params.biometric_type.into(),
        })
        .await
        .map_err(ServiceError::BackgroundError)?;
    let wallet = service
        .core
        .wallets
        .last()
        .ok_or(ServiceError::FailToSaveWallet)?;

    Ok(hex::encode(wallet.wallet_address))
}

pub struct AddSKWalletParams {
    pub sk: String,
    pub password: String,
    pub wallet_name: String,
    pub biometric_type: String,
    pub chain_hash: u64,
    pub bip_purpose: u32,
}

pub async fn add_sk_wallet(
    params: AddSKWalletParams,
    wallet_settings: WalletSettingsInfo,
    ftokens: Vec<FTokenInfo>,
) -> Result<String, String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;

    let ftokens = ftokens
        .into_iter()
        .map(TryFrom::try_from)
        .collect::<Result<Vec<FToken>, TokenError>>()
        .map_err(ServiceError::TokenError)?;
    let provider = service
        .core
        .get_provider(params.chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let net = provider.config.bitcoin_network();
    let bip49 = DerivationPath::new(provider.config.slip_44, 0, params.bip_purpose, net);

    let secret_key = secretkey_from_provider(&params.sk, bip49)?;
    let wallet_settings = wallet_settings
        .try_into()
        .map_err(ServiceError::SettingsError)?;
    let password = SecretString::new(params.password.into());
    Arc::get_mut(&mut service.core)
        .ok_or(ServiceError::CoreAccess)?
        .add_sk_wallet(BackgroundSKParams {
            ftokens,
            chain_hash: params.chain_hash,
            secret_key,
            wallet_name: params.wallet_name,
            biometric_type: params.biometric_type.into(),
            password: &password,
            wallet_settings,
        })
        .await
        .map_err(ServiceError::BackgroundError)?;
    let wallet = service
        .core
        .wallets
        .last()
        .ok_or(ServiceError::FailToSaveWallet)?;

    Ok(hex::encode(wallet.wallet_address))
}

pub struct AddNextBip39AccountParams {
    pub wallet_index: usize,
    pub account_index: usize,
    pub name: String,
    pub passphrase: String,
    pub password: Option<String>,
}

pub async fn add_next_bip39_account(params: AddNextBip39AccountParams) -> Result<(), String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;
    let password = params.password.map(|p| SecretString::new(p.into()));

    let seed = if let Some(mut pass) = password {
        let key = service
            .core
            .unlock_wallet_with_password(&pass, None, params.wallet_index)
            .await;
        pass.zeroize();

        key
    } else {
        service
            .core
            .unlock_wallet_with_session(params.wallet_index)
            .await
    }
    .map_err(ServiceError::BackgroundError)?;

    let wallet = service
        .core
        .get_wallet_by_index(params.wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let wallet_data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(params.wallet_index, e))?;
    let selected_account = wallet_data
        .get_selected_account()
        .map_err(|e| ServiceError::WalletError(params.wallet_index, e))?;
    let default_chain = service
        .core
        .get_provider(wallet_data.default_chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let bip49 = match selected_account.pub_key {
        PubKey::Secp256k1Sha256(_) | PubKey::Secp256k1Keccak256(_) | PubKey::Ed25519Solana(_) => {
            DerivationPath::new(
                default_chain.config.slip_44,
                params.account_index,
                DerivationPath::BIP44_PURPOSE,
                None,
            )
        }
        PubKey::Secp256k1Bitcoin((_, net, btc_addr_type)) => DerivationPath::new(
            default_chain.config.slip_44,
            params.account_index,
            DerivationPath::bip_from_address_type(btc_addr_type),
            Some(net),
        ),
    };

    wallet
        .add_next_bip39_account(
            params.name,
            &bip49,
            &params.passphrase,
            &seed,
            &default_chain.config,
        )
        .map_err(|e| ServiceError::WalletError(params.wallet_index, e))?;

    let mut wallet_data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(params.wallet_index, e))?;

    if let Some(added_account) = wallet_data.accounts.last_mut() {
        added_account.slip_44 = selected_account.slip_44;
        added_account.chain_hash = selected_account.chain_hash;
        added_account.chain_id = selected_account.chain_id;
    }

    wallet
        .save_wallet_data(wallet_data)
        .map_err(|e| ServiceError::WalletError(params.wallet_index, e))?;

    Ok(())
}

pub async fn select_account(wallet_index: usize, account_index: usize) -> Result<(), String> {
    with_wallet(wallet_index, |wallet| {
        wallet
            .select_account(account_index)
            .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))
    })
    .await
    .map_err(Into::into)
}

pub async fn change_account_name(
    wallet_index: usize,
    account_index: usize,
    new_name: String,
) -> Result<(), String> {
    with_wallet(wallet_index, |wallet| {
        let mut data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let acc = data
            .accounts
            .get_mut(account_index)
            .ok_or(ServiceError::AccountError(
                account_index,
                wallet_index,
                WalletErrors::InvalidAccountIndex(account_index),
            ))?;

        acc.name = new_name;

        wallet
            .save_wallet_data(data)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

pub async fn change_wallet_name(wallet_index: usize, new_name: String) -> Result<(), String> {
    with_wallet(wallet_index, |wallet| {
        let mut data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        data.wallet_name = new_name;

        wallet
            .save_wallet_data(data)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

pub async fn delete_wallet(wallet_index: usize, password: Option<String>) -> Result<(), String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;
    let password = password.map(|p| SecretString::new(p.into()));

    if let Some(mut pass) = password {
        let key = service
            .core
            .unlock_wallet_with_password(&pass, None, wallet_index)
            .await;

        pass.zeroize();

        key
    } else {
        service.core.unlock_wallet_with_session(wallet_index).await
    }
    .map_err(ServiceError::BackgroundError)?;

    Arc::get_mut(&mut service.core)
        .ok_or(ServiceError::CoreAccess)?
        .delete_wallet(wallet_index)
        .map_err(ServiceError::BackgroundError)?;

    Ok(())
}

pub async fn delete_account(wallet_index: usize, account_index: usize) -> Result<(), String> {
    with_wallet(wallet_index, |wallet| {
        wallet
            .delete_account(account_index)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

pub async fn set_biometric(
    wallet_index: usize,
    password: Option<String>,
    new_biometric_type: String,
) -> Result<(), String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let mut password = password.map(|p| SecretString::new(p.into()));

    service
        .core
        .set_biometric(password.as_ref(), wallet_index, new_biometric_type.into())
        .await
        .map_err(ServiceError::BackgroundError)?;

    password.zeroize();

    Ok(())
}

pub async fn bitcoin_change_address_type(
    wallet_index: usize,
    new_address_type: String,
    password: Option<String>,
    passphrase: Option<String>,
) -> Result<(), String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let password = password.map(|p| SecretString::new(p.into()));
    let address_type = bitcoin::AddressType::from_str(&new_address_type).map_err(|_| {
        ServiceError::AddressError(zilpay::errors::address::AddressError::InvalidKeyType)
    })?;
    let seed = if let Some(mut pass) = password {
        let key = service
            .core
            .unlock_wallet_with_password(&pass, None, wallet_index)
            .await;
        pass.zeroize();
        key
    } else {
        service.core.unlock_wallet_with_session(wallet_index).await
    }
    .map_err(ServiceError::BackgroundError)?;

    let wallet = service
        .core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let mut wallet_data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let provider = service
        .core
        .get_provider(wallet_data.default_chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let new_bip_purpose = DerivationPath::bip_from_address_type(address_type);
    let mnemonic = wallet
        .reveal_mnemonic(&seed)
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let mnemonic_seed = mnemonic
        .to_seed(passphrase.as_deref().unwrap_or(""))
        .map_err(|e| ServiceError::WalletError(wallet_index, WalletErrors::Bip39Error(e)))?;

    for (index, account) in wallet_data.accounts.iter_mut().enumerate() {
        let net = match account.pub_key {
            PubKey::Secp256k1Bitcoin((_, net, _)) => Some(net),
            _ => {
                return Err(ServiceError::WalletError(
                    wallet_index,
                    WalletErrors::InvalidAccountType,
                )
                .into());
            }
        };

        let new_path = DerivationPath::new(provider.config.slip_44, index, new_bip_purpose, net);

        let keypair =
            zilpay::proto::keypair::KeyPair::from_bip39_seed(&mnemonic_seed, &new_path)
                .map_err(|e| ServiceError::WalletError(wallet_index, WalletErrors::from(e)))?;

        account.pub_key = keypair
            .get_pubkey()
            .map_err(|e| ServiceError::WalletError(wallet_index, WalletErrors::from(e)))?;
        account.addr = keypair
            .get_addr()
            .map_err(|e| ServiceError::WalletError(wallet_index, WalletErrors::from(e)))?;
    }

    let mut ftokens = wallet
        .get_ftokens()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

    ftokens.iter_mut().for_each(|t| {
        t.balances.clear();
    });

    wallet
        .save_wallet_data(wallet_data)
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    wallet
        .save_ftokens(&ftokens)
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

    Ok(())
}

pub async fn reveal_keypair(
    wallet_index: usize,
    account_index: usize,
    password: String,
    passphrase: Option<String>,
) -> Result<KeyPairInfo, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    let mut password = SecretString::new(password.into());
    let seed = service
        .core
        .unlock_wallet_with_password(&password, None, wallet_index)
        .await
        .map_err(ServiceError::BackgroundError)?;
    let wallet = service
        .core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let keypair = wallet
        .reveal_keypair(account_index, &seed, passphrase.as_deref())
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

    password.zeroize();

    Ok(keypair.into())
}

pub async fn reveal_bip39_phrase(
    wallet_index: usize,
    password: String,
    _passphrase: Option<String>,
) -> Result<String, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    let mut password = SecretString::new(password.into());
    let seed = service
        .core
        .unlock_wallet_with_password(&password, None, wallet_index)
        .await
        .map_err(ServiceError::BackgroundError)?;
    let wallet = service
        .core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let m = wallet
        .reveal_mnemonic(&seed)
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

    password.zeroize();

    Ok(m.to_string())
}

pub async fn zilliqa_swap_chain(wallet_index: usize, account_index: usize) -> Result<(), String> {
    with_service(|core| {
        core.swap_zilliqa_chain(wallet_index, account_index)?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

pub async fn zilliqa_get_bech32_base16_address(
    wallet_index: usize,
    account_index: usize,
) -> Result<(String, String), String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let account = data
            .accounts
            .get(account_index)
            .ok_or(ServiceError::AccountError(
                account_index,
                wallet_index,
                WalletErrors::NoAccounts,
            ))?;

        match account.pub_key {
            PubKey::Secp256k1Sha256(_) => Ok((
                account.addr.get_zil_bech32().unwrap_or_default(),
                account.addr.get_zil_check_sum_addr().unwrap_or_default(),
            )),
            PubKey::Secp256k1Keccak256(pk) => {
                let addr_result = PubKey::Secp256k1Sha256(pk)
                    .get_addr()
                    .map(|addr| {
                        (
                            addr.get_zil_bech32().unwrap_or_default(),
                            addr.get_zil_check_sum_addr().unwrap_or_default(),
                        )
                    })
                    .map_err(|_| ServiceError::DecodePublicKey)?;

                Ok(addr_result)
            }
            _ => Err(ServiceError::DecodePublicKey),
        }
    })
    .await
    .map_err(Into::into)
}

pub async fn get_zil_eth_checksum_addresses(wallet_index: usize) -> Result<Vec<String>, String> {
    with_wallet(wallet_index, |wallet| {
        let data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let addresses = data
            .accounts
            .into_iter()
            .filter_map(|a| match a.pub_key {
                PubKey::Secp256k1Sha256(pk) => PubKey::Secp256k1Keccak256(pk)
                    .get_addr()
                    .ok()
                    .and_then(|a| a.to_eth_checksummed().ok()),
                PubKey::Secp256k1Keccak256(_) => a.addr.to_eth_checksummed().ok(),
                _ => None,
            })
            .collect::<Vec<String>>();

        Ok(addresses)
    })
    .await
    .map_err(Into::into)
}

pub async fn get_zil_bech32_addresses(wallet_index: usize) -> Result<Vec<String>, String> {
    with_wallet(wallet_index, |wallet| {
        let data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let addresses = data
            .accounts
            .into_iter()
            .filter_map(|a| match a.pub_key {
                PubKey::Secp256k1Sha256(_) => a.addr.get_zil_bech32().ok(),
                PubKey::Secp256k1Keccak256(pk) => PubKey::Secp256k1Sha256(pk)
                    .get_addr()
                    .ok()
                    .and_then(|addr| addr.get_zil_bech32().ok()),
                _ => None,
            })
            .collect::<Vec<String>>();

        Ok(addresses)
    })
    .await
    .map_err(Into::into)
}

pub fn zilliqa_legacy_base16_to_bech32(base16: String) -> Result<String, String> {
    let addr = Address::from_zil_base16(&base16).map_err(|e| e.to_string())?;

    Ok(addr.get_zil_bech32().unwrap_or_default())
}

pub async fn zilliqa_get_n_format(
    wallet_index: usize,
    account_index: usize,
) -> Result<String, String> {
    with_wallet(wallet_index, |wallet| {
        let data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let account = data
            .accounts
            .get(account_index)
            .ok_or(WalletErrors::InvalidAccountIndex(account_index))
            .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))?;

        let address = match account.pub_key {
            PubKey::Secp256k1Sha256(pk) => PubKey::Secp256k1Keccak256(pk)
                .get_addr()
                .ok()
                .and_then(|a| a.to_eth_checksummed().ok()),
            PubKey::Secp256k1Keccak256(_) => account
                .pub_key
                .get_addr()
                .ok()
                .and_then(|a| a.get_zil_bech32().ok()),
            _ => None,
        }
        .ok_or(ServiceError::AccountTypeNotValid)?;

        Ok(address)
    })
    .await
    .map_err(Into::into)
}

pub async fn make_keystore_file(wallet_index: usize, password: String) -> Result<Vec<u8>, String> {
    let mut password = SecretString::new(password.into());
    let chain_hash = with_wallet(wallet_index, |wallet| {
        let data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(data.default_chain_hash)
    })
    .await?;
    select_accounts_chain(wallet_index, chain_hash).await?;

    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    let keystore_bytes = service
        .core
        .get_keystore(wallet_index, &password)
        .await
        .map_err(ServiceError::BackgroundError)?;
    password.zeroize();
    Ok(keystore_bytes)
}

pub async fn restore_from_keystore(
    keystore_bytes: Vec<u8>,
    password: String,
    biometric_type: String,
) -> Result<String, String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;
    let mut password = SecretString::new(password.into());

    Arc::get_mut(&mut service.core)
        .ok_or(ServiceError::CoreAccess)?
        .load_keystore(keystore_bytes, &password, biometric_type.into())
        .await
        .map_err(ServiceError::BackgroundError)?;

    let wallet = service
        .core
        .wallets
        .last()
        .ok_or(ServiceError::FailToSaveWallet)?;

    password.zeroize();

    Ok(hex::encode(wallet.wallet_address))
}
