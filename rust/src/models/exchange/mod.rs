pub mod thorchain;
pub mod uniswap;

use flutter_rust_bridge::frb;
use zilpay::crypto::slip44::{BITCOIN, ETHEREUM, SOLANA, TRON, ZILLIQA};

use super::ftoken::FTokenInfo;
use super::transactions::base_token::BaseTokenInfo;
use std::collections::HashSet;

pub use uniswap::UniswapMeta;

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
            Self::Uniswap(_) => addr_type == 1 && uniswap::is_supported_chain(chain_id),
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

/// Display metadata composed on the Dart side and threaded into every tx built for a swap.
/// Passed as a single struct to keep the FFI surface small.
#[derive(Debug, Clone)]
pub struct ExchangeTxDisplay {
    /// Flutter local asset path, e.g. `"assets/icons/uniswap.svg"`.
    pub provider_icon: String,
    /// History title for the swap tx: `"Swap"`.
    pub swap_title: String,
    /// History detail line: `"1.5 BNB → 120 CAKE · Uniswap"`.
    pub swap_info: String,
    /// History title for the approve tx: `"Approve WORM"`.
    pub approve_title: String,
    /// History title for the software permit entry: `"Permit2 · Uniswap"`.
    pub permit_title: String,
    /// Destination token with the expected `amountOut` as `value` (wei string).
    pub out_token: Option<BaseTokenInfo>,
}

#[derive(Debug)]
pub struct ExchangeQuoteInfo {
    pub provider: ExchangeProvider,
    pub amount_out: String,
    /// Standard EIP-712 typed-data JSON to sign (Permit2). `None` for native input or
    /// when the API returns no permit (`permitData: null`).
    pub permit_typed_data_json: Option<String>,
}
