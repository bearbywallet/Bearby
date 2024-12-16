use thiserror::Error;
use zilpay::zil_errors::{
    address::AddressError, background::BackgroundError, settings::SettingsErrors,
    wallet::WalletErrors,
};

#[derive(Debug, Error)]
pub enum ServiceError {
    #[error("Service is not running")]
    NotRunning,

    #[error("Failed to acquire lock")]
    MutexLock,

    #[error("Cannot get mutable reference to core")]
    CoreAccess,

    #[error("background Error: {0}")]
    BackgroundError(BackgroundError),

    #[error("Wallet error at index: {0}: {1}")]
    WalletError(usize, WalletErrors),

    #[error("Account error at index: {0}, wallet index at {1}: {2}")]
    AccountError(usize, usize, WalletErrors),

    #[error("address error: {0}")]
    AddressError(AddressError),

    #[error("settings error: {0}")]
    SettingsError(SettingsErrors),

    #[error("Failed to access wallet at index {0}")]
    WalletAccess(usize),

    #[error("Failed to access account at index {0} and wallet index at {1}")]
    AccountAccess(usize, usize),

    #[error("not valid account type!")]
    AccountTypeNotValid,

    #[error("Failed to decode session")]
    DecodeSession,

    #[error("Failed to save wallet")]
    FailToSaveWallet,

    #[error("Failed to decode secret key")]
    DecodeSecretKey,

    #[error("Invalid secret key length")]
    InvalidSecretKeyLength,

    #[error("Failed to decode public key")]
    DecodePublicKey,

    #[error("Invalid public key length")]
    InvalidPublicKeyLength,
}

impl From<BackgroundError> for ServiceError {
    fn from(error: BackgroundError) -> Self {
        ServiceError::BackgroundError(error)
    }
}

impl From<hex::FromHexError> for ServiceError {
    fn from(_: hex::FromHexError) -> Self {
        ServiceError::DecodeSecretKey
    }
}

impl From<ServiceError> for String {
    fn from(error: ServiceError) -> String {
        error.to_string()
    }
}
