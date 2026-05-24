pub mod thorchain;

use thorchain::{ThorchainInbound, ThorchainSwapQuote};

use super::provider::NetworkConfigInfo;

#[derive(Debug)]
pub enum ExchangeProviderId {
    Thorchain,
}

#[derive(Debug)]
pub enum ExchangeProviderMetadata {
    Thorchain(Vec<ThorchainInbound>),
}

#[derive(Debug)]
pub enum ExchangeProviderQuote {
    Thorchain(ThorchainSwapQuote),
}

impl ExchangeProviderId {
    pub fn is_supported(&self, config: &NetworkConfigInfo) -> bool {
        match self {
            Self::Thorchain => thorchain::is_chain_supported(config),
        }
    }
}
