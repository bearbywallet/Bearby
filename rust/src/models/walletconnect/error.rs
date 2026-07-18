//! WalletConnect engine errors. Internal only (`#[frb(ignore)]`).

use flutter_rust_bridge::frb;
use thiserror::Error;

#[frb(ignore)]
#[derive(Debug, Error)]
pub enum WcError {
    #[error("invalid pairing uri: {0}")]
    InvalidUri(&'static str),
    #[error("crypto: {0}")]
    Crypto(&'static str),
    #[error("relay transport: {0}")]
    Transport(String),
    #[error("relay rpc error {code}: {message}")]
    RelayRpc { code: i64, message: String },
    #[error("serde: {0}")]
    Serde(#[from] zilpay::serde_json::Error),
    #[error("unknown topic: {0}")]
    UnknownTopic(String),
    #[error("proposal {0} not found")]
    ProposalNotFound(u64),
    #[error("session {0} not found")]
    SessionNotFound(String),
    #[error("storage: {0}")]
    Storage(String),
    #[error("engine not initialized")]
    NotInitialized,
    #[error("namespace validation: {0}")]
    Namespace(&'static str),
    #[error("unauthorized chain or method")]
    Unauthorized,
}

#[frb(ignore)]
impl From<WcError> for String {
    fn from(value: WcError) -> Self {
        value.to_string()
    }
}
