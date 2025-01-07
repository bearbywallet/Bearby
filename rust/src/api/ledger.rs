use zilpay::wallet::wallet_storage::StorageOperations;
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
        utils::{decode_public_key, decode_session, get_last_wallet, with_service_mut},
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
    pub provider_index: usize,
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_ledger_wallet(
    params: LedgerParamsInput,
    wallet_settings: WalletSettingsInfo,
    ftokens: Vec<FTokenInfo>,
) -> Result<(String, String), String> {
    with_service_mut(|core| {
        let pub_key_bytes = decode_public_key(&params.pub_key)?;
        let pub_key = PubKey::Secp256k1Sha256Zilliqa(pub_key_bytes);
        let ftokens = ftokens
            .into_iter()
            .map(TryFrom::try_from)
            .collect::<Result<Vec<FToken>, TokenError>>()?;
        let identifiers = params.identifiers;
        let params = BackgroundLedgerParams {
            ftokens,
            provider_index: params.provider_index,
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

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_ledger_account(
    wallet_index: usize,
    account_index: usize,
    name: String,
    pub_key: String,
    identifiers: &[String],
    session_cipher: Option<String>,
) -> Result<(), String> {
    with_service_mut(|core| {
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

        let pub_key_bytes = decode_public_key(&pub_key)?;
        let pub_key = match first_account.pub_key {
            PubKey::Secp256k1Sha256Zilliqa(_) => PubKey::Secp256k1Sha256Zilliqa(pub_key_bytes),
            PubKey::Secp256k1Keccak256Ethereum(_) => {
                PubKey::Secp256k1Keccak256Ethereum(pub_key_bytes)
            }
            _ => return Err(ServiceError::AccountTypeNotValid),
        };

        wallet
            .add_ledger_account(name, pub_key, account_index, first_account.provider_index)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))
    })
    .await
    .map_err(Into::into)
}
