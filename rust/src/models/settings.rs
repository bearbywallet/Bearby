pub use zilpay::settings::argon2::ArgonParams;
pub use zilpay::settings::wallet_settings::WalletSettings;

#[derive(Debug)]
pub struct WalletArgonParamsInfo {
    pub memory: u32,
    pub iterations: u32,
    pub threads: u32,
    pub secret: String,
}

impl From<ArgonParams> for WalletArgonParamsInfo {
    fn from(value: ArgonParams) -> Self {
        WalletArgonParamsInfo {
            memory: value.memory,
            iterations: value.iterations,
            threads: value.threads,
            secret: hex::encode(value.secret),
        }
    }
}

#[derive(Debug)]
pub struct WalletSettingsInfo {
    pub cipher_orders: Vec<u8>,
    pub argon_params: WalletArgonParamsInfo,
    pub currency_convert: Option<String>,
    pub ipfs_node: Option<String>,
    pub ens_enabled: bool,
    pub gas_control_enabled: bool,
    pub node_ranking_enabled: bool,
    pub max_connections: u8,
    pub request_timeout_secs: u32,
}

impl From<WalletSettings> for WalletSettingsInfo {
    fn from(value: WalletSettings) -> Self {
        WalletSettingsInfo {
            argon_params: value.argon_params.into(),
            cipher_orders: value.cipher_orders.iter().map(|v| v.code()).collect(),
            currency_convert: value.features.currency_convert,
            ipfs_node: value.features.ipfs_node,
            ens_enabled: value.features.ens_enabled,
            gas_control_enabled: value.network.gas_control_enabled,
            node_ranking_enabled: value.network.node_ranking_enabled,
            max_connections: value.network.max_connections,
            request_timeout_secs: value.network.request_timeout_secs,
        }
    }
}
