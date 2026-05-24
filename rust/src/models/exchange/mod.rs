pub mod thorchain;

use thorchain::MetadataThorchain;

use super::provider::NetworkConfigInfo;

#[derive(Debug)]
pub enum ExchangeProvider {
    Thorchain(MetadataThorchain),
}

impl Default for ExchangeProvider {
    fn default() -> Self {
        Self::Thorchain(MetadataThorchain { dummy: 0 })
    }
}

impl ExchangeProvider {
    pub fn is_supported(&self, config: &NetworkConfigInfo) -> bool {
        match self {
            Self::Thorchain(_) => MetadataThorchain::is_supported(config),
        }
    }
}
