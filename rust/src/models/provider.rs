pub use zilpay::rpc::network_config::NetworkConfig;

pub struct NetworkConfigInfo {
    pub network_name: String,
    pub chain_id: u64,
    pub fallback_enabled: bool,
    pub urls: Vec<String>,
    pub explorer_urls: Vec<String>,
    pub default: bool,
}

impl From<NetworkConfig> for NetworkConfigInfo {
    fn from(value: NetworkConfig) -> Self {
        Self {
            network_name: value.network_name,
            chain_id: value.chain_id,
            fallback_enabled: value.fallback_enabled,
            urls: value.urls,
            explorer_urls: value.explorer_urls,
            default: value.default,
        }
    }
}

impl From<NetworkConfigInfo> for NetworkConfig {
    fn from(value: NetworkConfigInfo) -> Self {
        Self {
            network_name: value.network_name,
            chain_id: value.chain_id,
            fallback_enabled: value.fallback_enabled,
            urls: value.urls,
            explorer_urls: value.explorer_urls,
            default: value.default,
        }
    }
}
