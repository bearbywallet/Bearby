//! Wallet token ↔ WhiteBird asset-id mapping and synthetic fiat tokens.

use std::collections::{HashMap, HashSet};

use crate::models::exchange::{ExchangeAsset, ExchangeProvider};
use crate::models::ftoken::FTokenInfo;

use super::WhiteBirdMeta;

/// addr_type values in use by real chains: 0 zil, 1 evm, 2 btc, 3 svm, 4 tron.
/// Synthetic fiat tokens get their own value far outside that range.
pub const FIAT_ADDR_TYPE: u8 = 200;
pub const FIAT_DECIMALS: u8 = 2;

const CHAIN_ETH: u64 = 1;
const CHAIN_BNB: u64 = 56;

/// (WhiteBird asset id, display name, bundled icon asset).
pub const FIAT_CURRENCIES: [(&str, &str, &str); 4] = [
    ("BYN", "Belarusian Ruble", "assets/icons/byn.svg"),
    ("RUB", "Russian Ruble", "assets/icons/rub.svg"),
    ("USD", "US Dollar", "assets/icons/usd.svg"),
    ("EUR", "Euro", "assets/icons/euro.svg"),
];

/// Map a wallet token to a WhiteBird asset id. `None` = unsupported (e.g. ZIL).
#[must_use]
pub fn map_token(addr_type: u8, chain_id: u64, symbol: &str, native: bool) -> Option<&'static str> {
    let is = |name: &str| symbol.trim().eq_ignore_ascii_case(name);
    match addr_type {
        2 if native => Some("BTC"),
        4 if native => Some("TRX"),
        4 if is("USDT") => Some("USDT_TRC"),
        3 if native => Some("SOL"),
        3 if is("USDT") => Some("USDT_SPL"),
        3 if is("USDC") => Some("USDC_SPL"),
        1 if chain_id == CHAIN_ETH && native => Some("ETH"),
        1 if chain_id == CHAIN_ETH && is("USDT") => Some("USDT_ERC"),
        1 if chain_id == CHAIN_ETH && is("USDC") => Some("USDC_ERC"),
        1 if chain_id == CHAIN_BNB && native => Some("BNB"),
        1 if chain_id == CHAIN_BNB && is("USDT") => Some("USDT_BNB"),
        1 if chain_id == CHAIN_BNB && is("USDC") => Some("USDC_BNB"),
        _ => None,
    }
}

/// Network label WhiteBird expects next to a crypto asset code; `None` for fiat.
#[must_use]
pub fn network_for_code(code: &str) -> Option<&'static str> {
    match code {
        "BTC" => Some("Bitcoin"),
        "ETH" | "USDT_ERC" | "USDC_ERC" => Some("Ethereum"),
        "TRX" | "USDT_TRC" => Some("Tron"),
        "BNB" | "USDT_BNB" | "USDC_BNB" => Some("BNB"),
        "SOL" | "USDT_SPL" | "USDC_SPL" => Some("SOLANA"),
        "TON" | "USDT_TON" => Some("Ton"),
        _ => None,
    }
}

/// Synthetic fiat [`ExchangeAsset`]s pinned to the active chain so they surface
/// in both pay/get lists and `scope_providers` never strips their provider.
#[must_use]
pub fn fiat_exchange_assets(
    active_chain_hash: u64,
    chain_id: u64,
    slip44: u32,
    account_addr: &str,
    is_testnet: bool,
) -> Vec<ExchangeAsset> {
    FIAT_CURRENCIES
        .iter()
        .map(|&(code, name, icon)| {
            let mut providers = HashSet::with_capacity(1);
            providers.insert(ExchangeProvider::WhiteBird(WhiteBirdMeta::fiat(
                active_chain_hash,
                chain_id,
                slip44,
                account_addr,
                code,
                is_testnet,
            )));
            ExchangeAsset {
                token: FTokenInfo {
                    name: name.to_owned(),
                    symbol: code.to_owned(),
                    decimals: FIAT_DECIMALS,
                    addr: format!("fiat:{code}"),
                    addr_type: FIAT_ADDR_TYPE,
                    logo: Some(icon.to_owned()),
                    balances: HashMap::with_capacity(0),
                    rate: 0.0,
                    default: false,
                    native: false,
                    chain_hash: active_chain_hash,
                },
                providers,
                halted: false,
            }
        })
        .collect()
}
