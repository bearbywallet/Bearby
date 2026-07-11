//! WhiteBird fiat↔crypto ramp as an [`ExchangeProvider`] variant.
//!
//! Quotes go through the Bearby proxy (`wbdev.bearby.ru` / `wb.bearby.ru`);
//! order creation happens inside the WhiteBird JS SDK (session flow), so this
//! module never signs or builds transactions — a sell's deposit transfer is a
//! plain wallet transfer driven from Dart.

pub mod assets;
pub mod client;
pub mod orders;
pub mod quote;

use flutter_rust_bridge::frb;

use super::{ProviderCommon, ProviderQuote};

pub use orders::{WhiteBirdOpenOrder, WhiteBirdSessionInfo};

pub const DISPLAY_NAME: &str = "WhiteBird";
pub const ICON_ASSET: &str = "assets/icons/whitebird.svg";

/// Mainnet proxy (`wb.bearby.ru`) is not deployed yet — provider stays
/// testnet-only until this is flipped.
pub const MAINNET_ENABLED: bool = false;

/// Provider meta crossing FRB as `ExchangeProvider::WhiteBird`.
#[derive(Debug, Clone)]
pub struct WhiteBirdMeta {
    pub common: ProviderCommon,
    pub quote: Option<ProviderQuote>,
    /// WhiteBird asset id for the token this meta is attached to
    /// (`"TRX"`, `"USDT_TRC"`, `"BYN"`, …).
    pub asset_code: String,
    /// `true` when attached to a synthetic fiat token.
    pub is_fiat: bool,
    /// testnet → wbdev.bearby.ru, mainnet → wb.bearby.ru.
    pub is_testnet: bool,
}

impl WhiteBirdMeta {
    #[frb(ignore)]
    fn new(
        chain_hash: u64,
        chain_id: u64,
        slip44: u32,
        account_addr: &str,
        asset_code: &str,
        is_fiat: bool,
        is_testnet: bool,
    ) -> Self {
        Self {
            common: ProviderCommon {
                chain_hash,
                chain_id,
                slip44,
                account_addr: account_addr.to_owned(),
                icon_asset: ICON_ASSET.to_owned(),
                display_name: DISPLAY_NAME.to_owned(),
            },
            quote: None,
            asset_code: asset_code.to_owned(),
            is_fiat,
            is_testnet,
        }
    }

    /// Crypto-side meta for a mapped wallet token.
    #[frb(ignore)]
    pub fn crypto(
        chain_hash: u64,
        chain_id: u64,
        slip44: u32,
        account_addr: &str,
        asset_code: &str,
        is_testnet: bool,
    ) -> Self {
        Self::new(
            chain_hash, chain_id, slip44, account_addr, asset_code, false, is_testnet,
        )
    }

    /// Fiat-side meta for a synthetic fiat token.
    #[frb(ignore)]
    pub fn fiat(
        chain_hash: u64,
        chain_id: u64,
        slip44: u32,
        account_addr: &str,
        fiat_code: &str,
        is_testnet: bool,
    ) -> Self {
        Self::new(
            chain_hash, chain_id, slip44, account_addr, fiat_code, true, is_testnet,
        )
    }
}
