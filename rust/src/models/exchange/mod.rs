pub mod curve_fi;
pub mod thorchain;
pub mod uniswap;

use curve_fi::MetadataCurveFi;
use thorchain::MetadataThorchain;
use uniswap::MetadataUniswap;

use super::provider::NetworkConfigInfo;

#[derive(Debug)]
pub enum ExchangeProvider {
    Thorchain(MetadataThorchain),
    CurveFi(MetadataCurveFi),
    Uniswap(MetadataUniswap),
}

impl Default for ExchangeProvider {
    fn default() -> Self {
        Self::Thorchain(MetadataThorchain)
    }
}

impl ExchangeProvider {
    pub fn is_supported(&self, config: &NetworkConfigInfo) -> bool {
        match self {
            Self::Thorchain(_) => MetadataThorchain::is_supported(config),
            Self::CurveFi(_) => MetadataCurveFi::is_supported(config),
            Self::Uniswap(_) => MetadataUniswap::is_supported(config),
        }
    }
}
