use zilpay::{
    background::bg_provider::ProvidersManagement, wallet::wallet_storage::StorageOperations,
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
    utils::{
        errors::ServiceError,
        utils::{
            decode_session, get_last_wallet, pubkey_from_provider, with_service, with_service_mut,
        },
    },
};

pub struct LedgerParamsInput {
    pub pub_key: String,
    pub wallet_index: usize,
    pub wallet_name: String,
    pub ledger_id: String,
    pub account_name: String,
    pub biometric_type: String,
    pub identifiers: Vec<String>,
    pub chain_hash: u64,
}

pub async fn add_ledger_wallet(
    params: LedgerParamsInput,
    wallet_settings: WalletSettingsInfo,
    ftokens: Vec<FTokenInfo>,
) -> Result<(String, String), String> {
    with_service_mut(|core| {
        let provider = core.get_provider(params.chain_hash)?;
        let bip49 = provider.get_bip49(params.wallet_index);
        let pub_key = pubkey_from_provider(&params.pub_key, bip49)?;
        let ftokens = ftokens
            .into_iter()
            .map(TryFrom::try_from)
            .collect::<Result<Vec<FToken>, TokenError>>()?;
        let identifiers = params.identifiers;
        let params = BackgroundLedgerParams {
            ftokens,
            chain_hash: params.chain_hash,
            pub_key,
            account_name: params.account_name,
            wallet_index: params.wallet_index,
            wallet_name: params.wallet_name,
            ledger_id: params.ledger_id.as_bytes().to_vec(),
            biometric_type: params.biometric_type.into(),
            wallet_settings: wallet_settings.try_into()?,
        };

        let session = core
            .add_ledger_wallet(params, WalletSettings::default(), &identifiers)
            .map_err(ServiceError::BackgroundError)?;
        let wallet = get_last_wallet(core)?;

        Ok((hex::encode(session), hex::encode(wallet.wallet_address)))
    })
    .await
    .map_err(Into::into)
}

pub async fn add_ledger_account(
    wallet_index: usize,
    account_index: usize,
    name: String,
    pub_key: String,
    identifiers: &[String],
    session_cipher: Option<String>,
) -> Result<(), String> {
    with_service(|core| {
        let session = decode_session(session_cipher)?;

        core.unlock_wallet_with_session(session, identifiers, wallet_index)?;

        let wallet = core.get_wallet_by_index(wallet_index)?;
        let data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let first_account = data
            .accounts
            .first()
            .ok_or(ServiceError::AccountAccess(0, wallet_index))?;

        let provider = core.get_provider(first_account.chain_hash)?;
        let bip49 = provider.get_bip49(wallet_index);
        let pub_key = pubkey_from_provider(&pub_key, bip49)?;

        wallet
            .add_ledger_account(name, pub_key, account_index, &provider.config)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}
