use std::sync::Arc;

use zilpay::{
    background::bg_provider::ProvidersManagement,
    crypto::bip49::{split_path, DerivationPath},
    wallet::wallet_storage::StorageOperations,
};
pub use zilpay::{
    background::{bg_wallet::WalletManagement, BackgroundLedgerParams},
    settings::wallet_settings::WalletSettings,
    wallet::wallet_account::AccountManagement,
};
pub use zilpay::{errors::token::TokenError, token::ft::FToken};
pub use zilpay::{proto::pubkey::PubKey, wallet::LedgerParams};

use crate::{
    models::{ftoken::FTokenInfo, settings::WalletSettingsInfo},
    service::service::BACKGROUND_SERVICE,
    utils::{
        errors::ServiceError,
        utils::{get_last_wallet, pubkey_from_provider, with_service},
    },
};

pub struct LedgerParamsInput {
    pub pub_keys: Vec<(u8, String)>,
    pub wallet_index: usize,
    pub wallet_name: String,
    pub ledger_id: String,
    pub account_names: Vec<String>,
    pub biometric_type: String,
    pub identifiers: Vec<String>,
    pub chain_hash: u64,
    pub zilliqa_legacy: bool,
    pub bip_purpose: u32,
}

pub async fn add_ledger_wallet(
    params: LedgerParamsInput,
    wallet_settings: WalletSettingsInfo,
    ftokens: Vec<FTokenInfo>,
) -> Result<String, String> {
    let mut guard = BACKGROUND_SERVICE.write().await;
    let service = guard.as_mut().ok_or(ServiceError::NotRunning)?;

    let provider = service
        .core
        .get_provider(params.chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let net = provider.config.bitcoin_network();
    let bip49 = DerivationPath::new(
        provider.config.slip_44,
        params.wallet_index,
        params.bip_purpose,
        net,
    );
    let pub_keys = params
        .pub_keys
        .into_iter()
        .map(|(ledger_index, pk)| {
            pubkey_from_provider(&pk, bip49, params.zilliqa_legacy)
                .map(|pub_key| (ledger_index, pub_key))
        })
        .collect::<Result<Vec<(u8, PubKey)>, ServiceError>>()?;
    let ftokens = ftokens
        .into_iter()
        .map(TryFrom::try_from)
        .collect::<Result<Vec<FToken>, TokenError>>()
        .map_err(ServiceError::TokenError)?;
    let identifiers = params.identifiers;
    let wallet_settings = wallet_settings
        .try_into()
        .map_err(ServiceError::SettingsError)?;
    let params = BackgroundLedgerParams {
        ftokens,
        pub_keys,
        wallet_settings,
        chain_hash: params.chain_hash,
        account_names: params.account_names,
        wallet_index: params.wallet_index,
        wallet_name: params.wallet_name,
        ledger_id: params.ledger_id.as_bytes().to_vec(),
        biometric_type: params.biometric_type.into(),
    };

    Arc::get_mut(&mut service.core)
        .ok_or(ServiceError::CoreAccess)?
        .add_ledger_wallet(params, WalletSettings::default(), &identifiers)
        .await
        .map_err(ServiceError::BackgroundError)?;
    let wallet = get_last_wallet(&service.core)?;

    Ok(hex::encode(wallet.wallet_address))
}

pub async fn update_ledger_accounts(
    wallet_index: usize,
    accounts: Vec<(u8, String, String)>, // index, pubkey, name
    zilliqa_legacy: bool,
) -> Result<(), String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let wallet_data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let selected_account = wallet_data
            .get_selected_account()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let provider = core.get_provider(wallet_data.default_chain_hash)?;
        let bip49 = match selected_account.pub_key {
            PubKey::Secp256k1Sha256(_)
            | PubKey::Secp256k1Keccak256(_)
            | PubKey::Ed25519Solana(_) => DerivationPath::new(
                provider.config.slip_44,
                wallet_index,
                DerivationPath::BIP44_PURPOSE,
                None,
            ),
            PubKey::Secp256k1Bitcoin((_, net, btc_addr_type)) => DerivationPath::new(
                provider.config.slip_44,
                wallet_index,
                DerivationPath::bip_from_address_type(btc_addr_type),
                Some(net),
            ),
        };
        let mut accounts = accounts
            .into_iter()
            .map(|(ledger_index, pk, name)| {
                pubkey_from_provider(&pk, bip49, zilliqa_legacy)
                    .map(|pub_key| (ledger_index, pub_key, name))
            })
            .collect::<Result<Vec<(u8, PubKey, String)>, ServiceError>>()?;

        accounts.dedup_by(|a, b| a.0 == b.0 && a.1 == b.1);

        wallet
            .update_ledger_accounts(accounts, &provider.config)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

pub async fn ledger_split_path(path: String) -> Result<Vec<u32>, String> {
    split_path(&path).map_err(|e| e.to_string())
}
