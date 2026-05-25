pub mod thorchain;
use zilpay::crypto::slip44::{BITCOIN, ETHEREUM, SOLANA, TRON, ZILLIQA};

use super::ftoken::FTokenInfo;
use std::collections::HashSet;

#[derive(Debug, PartialEq, PartialOrd, Eq, Hash, Clone)]
pub enum ExchangeProvider {
    Thorchain(u64),
    Uniswap(u64),
    ZIlSwap(u64),
    SunSwap(u64),
}

impl ExchangeProvider {
    pub fn is_support(&self, addr_type: u8, slip44: u32) -> bool {
        match self {
            Self::Thorchain(_) => {
                const SLIP44: &[u32] = &[BITCOIN, ETHEREUM, TRON, SOLANA];
                SLIP44.contains(&slip44)
            }
            Self::Uniswap(_) => {
                const SLIP44: &[u32] = &[ETHEREUM];
                addr_type == 1 && SLIP44.contains(&slip44)
            }
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
