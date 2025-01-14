use std::str::FromStr;

use zilpay::errors::network::NetworkErrors;
pub use zilpay::rpc::network_config::Bip44Network;
pub use zilpay::rpc::network_config::NetworkConfig;

pub struct NetworkConfigInfo {
    pub token_symbol: String,
    pub logo: Option<String>,
    pub network_name: String,
    pub chain_id: u64,
    pub fallback_enabled: bool,
    pub urls: Vec<String>,
    pub explorer_urls: Vec<String>,
    pub default: bool,
    pub bip49: String,
}

impl From<NetworkConfig> for NetworkConfigInfo {
    fn from(value: NetworkConfig) -> Self {
        Self {
            logo: value.logo,
            token_symbol: value.token_symbol,
            bip49: value.bip49.to_string(),
            network_name: value.network_name,
            chain_id: value.chain_id,
            fallback_enabled: value.fallback_enabled,
            urls: value.urls,
            explorer_urls: value.explorer_urls,
            default: value.default,
        }
    }
}

impl TryFrom<NetworkConfigInfo> for NetworkConfig {
    type Error = NetworkErrors;
    fn try_from(value: NetworkConfigInfo) -> Result<Self, Self::Error> {
        Ok(Self {
            logo: value.logo,
            token_symbol: value.token_symbol,
            bip49: Bip44Network::from_str(&value.bip49)?,
            network_name: value.network_name,
            chain_id: value.chain_id,
            fallback_enabled: value.fallback_enabled,
            urls: value.urls,
            explorer_urls: value.explorer_urls,
            default: value.default,
        })
    }
}
