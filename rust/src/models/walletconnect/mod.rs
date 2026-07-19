//! Minimal wallet-side WalletConnect v2 SDK.
//!
//! Pure protocol logic lives here. Everything except [`ffi`] is `#[frb(ignore)]`.
//! External FFI surface: `crate::api::walletconnect`.

pub mod crypto;
pub mod engine;
pub mod error;
pub mod ffi;
pub mod pairing;
pub mod relay;
pub mod relay_auth;
pub mod rpc;
pub mod session;
pub(crate) mod sign;
pub mod store;

pub use ffi::{
    WcEventInfo, WcNamespaceApproval, WcNamespaceInfo, WcProposalInfo, WcRequestInfo,
    WcSessionInfo,
};
