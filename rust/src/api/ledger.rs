use std::collections::HashMap;
use std::sync::Arc;

use zilpay::background::bg_bitcoin::BitcoinManagement;
use zilpay::{
    background::bg_provider::ProvidersManagement,
    crypto::bip49::{split_path, DerivationPath},
    proto::address::Address,
    proto::btc_utils::ByteCodec,
    wallet::wallet_storage::StorageOperations,
};
pub use zilpay::{
    background::{bg_wallet::WalletManagement, BackgroundLedgerParams},
    settings::wallet_settings::WalletSettings,
    wallet::wallet_account::AccountManagement,
};
pub use zilpay::{errors::token::TokenError, token::ft::FToken};
pub use zilpay::{proto::pubkey::PubKey, wallet::LedgerParams};

use zilpay::crypto::slip44;

use crate::{
    models::btc_chain::{AddressChainInfo, BtcAccountXpubsInputInfo},
    service::service::BACKGROUND_SERVICE,
    utils::{
        errors::ServiceError,
        utils::{get_last_wallet, pubkey_from_provider, with_service},
    },
};

pub async fn scan_btc_account_history(
    xpubs: BtcAccountXpubsInputInfo,
    ledger_index: u8,
    chain_hash: u64,
) -> Result<HashMap<u8, AddressChainInfo>, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    let xpubs = zilpay::proto::btc_utils::BtcAccountXpubsInput::try_from(xpubs)
        .map_err(|e: ServiceError| e.to_string())?;

    let core_result = service
        .core
        .scan_btc_account_history(&xpubs, ledger_index, chain_hash)
        .await
        .map_err(|e| e.to_string())?;

    Ok(core_result
        .into_iter()
        .map(|(addr_type, chain)| (addr_type.to_byte(), chain.into()))
        .collect())
}

pub struct LedgerParamsInput {
    pub pub_keys: Vec<(u8, String)>,
    pub wallet_index: usize,
    pub wallet_name: String,
    pub ledger_id: String,
    pub account_names: Vec<String>,
    pub biometric_type: String,
    pub chain_hash: u64,
    pub zilliqa_legacy: bool,
    pub btc_chains: HashMap<u8, HashMap<u8, AddressChainInfo>>,
}

pub async fn add_ledger_wallet(
    params: LedgerParamsInput,
    wallet_settings: crate::models::settings::WalletSettingsInfo,
    ftokens: Vec<crate::models::ftoken::FTokenInfo>,
) -> Result<String, String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;

    let provider = service
        .core
        .get_provider(params.chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let is_bitcoin = provider.config.slip_44 == slip44::BITCOIN;
    let accounts = params
        .pub_keys
        .into_iter()
        .map(|(ledger_index, key_or_addr)| {
            if is_bitcoin {
                Ok((ledger_index, None))
            } else {
                let pub_key =
                    pubkey_from_provider(&key_or_addr, &provider.config, params.zilliqa_legacy)?;
                Ok((ledger_index, Some(pub_key)))
            }
        })
        .collect::<Result<Vec<(u8, Option<PubKey>)>, ServiceError>>()?;
    let ftokens = ftokens
        .into_iter()
        .map(TryFrom::try_from)
        .collect::<Result<Vec<FToken>, TokenError>>()
        .map_err(ServiceError::TokenError)?;
    let wallet_settings = wallet_settings
        .try_into()
        .map_err(ServiceError::SettingsError)?;

    let btc_chains: HashMap<
        u8,
        HashMap<bitcoin::AddressType, zilpay::proto::btc_utils::AddressChain>,
    > = params
        .btc_chains
        .into_iter()
        .map(|(ledger_index, inner)| {
            let core_inner = inner
                .into_iter()
                .map(|(addr_type_byte, chain_info)| {
                    let addr_type =
                        bitcoin::AddressType::from_byte(addr_type_byte).map_err(|e| {
                            ServiceError::ParseError("address_type".into(), e.to_string())
                        })?;
                    let chain = chain_info.try_into()?;
                    Ok((addr_type, chain))
                })
                .collect::<Result<HashMap<_, _>, ServiceError>>()?;
            Ok((ledger_index, core_inner))
        })
        .collect::<Result<HashMap<_, _>, ServiceError>>()
        .map_err(|e: ServiceError| e.to_string())?;

    let params = BackgroundLedgerParams {
        ftokens,
        accounts,
        wallet_settings,
        chain_hash: params.chain_hash,
        account_names: params.account_names,
        wallet_index: params.wallet_index,
        wallet_name: params.wallet_name,
        ledger_id: params.ledger_id.as_bytes().to_vec(),
        biometric_type: params.biometric_type.into(),
        btc_chains,
    };

    Arc::get_mut(&mut service.core)
        .ok_or(ServiceError::CoreAccess)?
        .add_ledger_wallet(params, WalletSettings::default())
        .await
        .map_err(ServiceError::BackgroundError)?;
    let wallet = get_last_wallet(&service.core)?;

    Ok(hex::encode(wallet.wallet_address))
}

pub async fn update_ledger_accounts(
    wallet_index: usize,
    accounts: Vec<(u8, String, String)>,
    zilliqa_legacy: bool,
    derive_path: String,
) -> Result<(), String> {
    with_service(|core| {
        let dp = DerivationPath::try_from(derive_path.as_str())?;
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let wallet_data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let provider = core.get_provider(wallet_data.chain_hash)?;
        let is_bitcoin = provider.config.slip_44 == slip44::BITCOIN;
        let mut accounts = accounts
            .into_iter()
            .map(|(ledger_index, key_or_addr, name)| {
                if is_bitcoin {
                    let addr = Address::from_bitcoin_address(&key_or_addr)?;
                    Ok((ledger_index, None, addr, name))
                } else {
                    let pub_key =
                        pubkey_from_provider(&key_or_addr, &provider.config, zilliqa_legacy)?;
                    let addr = pub_key.get_addr()?;
                    Ok((ledger_index, Some(pub_key), addr, name))
                }
            })
            .collect::<Result<Vec<(u8, Option<PubKey>, Address, String)>, ServiceError>>()?;

        accounts.dedup_by(|a, b| a.0 == b.0 && a.2 == b.2);

        wallet
            .update_ledger_accounts(accounts, &provider.config, dp.bip)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

pub async fn ledger_split_path(path: String) -> Result<Vec<u32>, String> {
    split_path(&path).map_err(|e| e.to_string())
}
