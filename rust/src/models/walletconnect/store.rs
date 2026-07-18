//! Persisted WalletConnect state (client seed, pairings, sessions) via LocalStorage.
//!
//! # Security tradeoff
//!
//! The WC blob is stored as **plaintext JSON** in the same sled DB as other app
//! state. It holds:
//! - `client_seed` — long-lived relay Ed25519 identity (not a wallet key)
//! - pairing/session `sym_key_hex` — channel encryption keys for open sessions
//!
//! These are lower value than BIP39/secret keys (which go through the cipher
//! stack), but they are still secrets: session keys enable reading/writing the
//! relay mailbox for that topic; the client seed is a stable relay identity.
//! Encrypting this blob via the cipher session is a follow-up; until then,
//! device-storage encryption (OS keychain / full-disk) is the boundary.
//! In-memory `client_seed` is zeroized on drop.

use std::collections::BTreeMap;
use std::sync::Arc;

use flutter_rust_bridge::frb;
use zilpay::errors::storage::LocalStorageError;
use zilpay::rand::Rng;
use zilpay::serde::{Deserialize, Serialize};
use zilpay::storage::LocalStorage;
use zilpay::zeroize::Zeroize;

use super::error::WcError;
use super::pairing::StoredPairing;
use super::session::Session;

#[frb(ignore)]
pub const WC_STORE_KEY: &[u8] = b"walletconnect_state_v1";

#[frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct WcState {
    /// Relay Ed25519 seed. Zeroized on drop (see module security note).
    pub client_seed: [u8; 32],
    pub pairings: BTreeMap<String, StoredPairing>,
    pub sessions: BTreeMap<String, Session>,
}

impl Default for WcState {
    fn default() -> Self {
        let mut client_seed = [0u8; 32];
        zilpay::rand::rng().fill_bytes(&mut client_seed);
        Self {
            client_seed,
            pairings: BTreeMap::new(),
            sessions: BTreeMap::new(),
        }
    }
}

impl Drop for WcState {
    fn drop(&mut self) {
        self.client_seed.zeroize();
    }
}

impl WcState {
    #[frb(ignore)]
    pub fn load(storage: &LocalStorage) -> Result<Self, WcError> {
        match storage.get(WC_STORE_KEY) {
            Ok(bytes) => {
                let mut state: Self = zilpay::serde_json::from_slice(&bytes)
                    .map_err(|e| WcError::Storage(e.to_string()))?;
                let now = now_secs();
                state.prune_expired(now);
                Ok(state)
            }
            // Only "missing key" → fresh identity. Any other storage failure
            // must surface so we never silently rotate client_seed / drop sessions.
            Err(LocalStorageError::StorageDataNotFound) => Ok(Self::default()),
            Err(e) => Err(WcError::Storage(e.to_string())),
        }
    }

    /// Persist state. Does **not** fsync (`flush`) — sled writes are durable
    /// enough for WC session metadata; fsync-per-message would block the async
    /// runtime under the state mutex.
    #[frb(ignore)]
    pub fn save(&self, storage: &LocalStorage) -> Result<(), WcError> {
        let bytes =
            zilpay::serde_json::to_vec(self).map_err(|e| WcError::Storage(e.to_string()))?;
        storage
            .set(WC_STORE_KEY, &bytes)
            .map_err(|e| WcError::Storage(e.to_string()))?;
        Ok(())
    }

    #[frb(ignore)]
    pub fn prune_expired(&mut self, now: u64) {
        self.pairings.retain(|_, p| !p.is_expired(now));
        self.sessions.retain(|_, s| !s.is_expired(now));
    }
}

#[frb(ignore)]
pub fn now_secs() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

#[frb(ignore)]
pub fn now_ms() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

/// Load state from Background's shared storage.
#[frb(ignore)]
pub fn load_from_core(storage: &Arc<LocalStorage>) -> Result<WcState, WcError> {
    WcState::load(storage.as_ref())
}

/// Persist state to Background's shared storage.
#[frb(ignore)]
pub fn save_to_core(storage: &Arc<LocalStorage>, state: &WcState) -> Result<(), WcError> {
    state.save(storage.as_ref())
}
