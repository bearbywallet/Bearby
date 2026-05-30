pub mod thorchain;
pub mod uniswap;

use flutter_rust_bridge::frb;
use zilpay::crypto::slip44::{BITCOIN, ETHEREUM, SOLANA, TRON, ZILLIQA};

use super::ftoken::FTokenInfo;
use std::collections::HashSet;

/// FFI-safe Uniswap deployment metadata. Addresses are hex `0x...` strings so the
/// whole struct crosses the flutter_rust_bridge boundary; they are parsed into alloy
/// `Address` once, internally, via [`UniswapMeta::resolve`].
#[derive(Debug, Default, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct UniswapMeta {
    pub chain_id: u64,
    pub universal_router: String,
    pub quoter_v2: String,
    pub permit2: String,
    pub weth: String,
}

#[derive(Debug, PartialEq, PartialOrd, Eq, Hash, Clone)]
pub enum ExchangeProvider {
    Thorchain(u64),
    Uniswap(UniswapMeta),
    ZIlSwap(u64),
    SunSwap(u64),
}

impl ExchangeProvider {
    #[frb(ignore)]
    pub fn is_support(&self, addr_type: u8, slip44: u32, chain_id: u64) -> bool {
        match self {
            Self::Thorchain(_) => {
                const SLIP44: &[u32] = &[BITCOIN, ETHEREUM, TRON, SOLANA];
                SLIP44.contains(&slip44)
            }
            Self::Uniswap(_) => addr_type == 1 && UniswapMeta::for_chain(chain_id).is_some(),
            Self::ZIlSwap(_) => {
                const SLIP44: &[u32] = &[ZILLIQA];
                addr_type == 0 && SLIP44.contains(&slip44)
            }
            Self::SunSwap(_) => {
                const SLIP44: &[u32] = &[TRON];
                addr_type == 4 && SLIP44.contains(&slip44)
            }
        }
    }
}

#[derive(Debug)]
pub struct ExchangeAsset {
    pub token: FTokenInfo,
    pub providers: HashSet<ExchangeProvider>,
    pub halted: bool,
}

#[derive(Debug)]
pub struct ExchangeQuoteInfo {
    pub provider: ExchangeProvider,
    pub amount_out: String,
    pub fee_tier: Option<u32>,
    pub permit_typed_data_json: Option<String>,
    pub permit_nonce: Option<u64>,
}
