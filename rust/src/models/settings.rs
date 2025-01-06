pub use zilpay::cipher::options::CipherOrders;
pub use zilpay::config::sha::SHA256_SIZE;
pub use zilpay::settings::argon2::ArgonParams;
pub use zilpay::settings::wallet_settings::WalletSettings;
pub use zilpay::zil_errors::settings::SettingsErrors;
use zilpay::{
    settings::wallet_settings::{NetworkSettings, WalletFeatures},
    zil_errors::cipher::CipherErrors,
};

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

impl TryFrom<WalletArgonParamsInfo> for ArgonParams {
    type Error = SettingsErrors;

    fn try_from(value: WalletArgonParamsInfo) -> Result<Self, Self::Error> {
        let secret: [u8; SHA256_SIZE] = hex::decode(&value.secret)
            .map_err(|e| SettingsErrors::InvalidHex(e.to_string()))?
            .try_into()
            .map_err(|_| SettingsErrors::InvalidHashSize(value.secret))?;

        Ok(Self {
            secret,
            memory: value.memory,
            iterations: value.iterations,
            threads: value.threads,
        })
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

impl TryFrom<WalletSettingsInfo> for WalletSettings {
    type Error = SettingsErrors;

    fn try_from(value: WalletSettingsInfo) -> Result<Self, Self::Error> {
        Ok(Self {
            cipher_orders: value
                .cipher_orders
                .iter()
                .map(|v| CipherOrders::from_code(*v))
                .collect::<Result<Vec<CipherOrders>, CipherErrors>>()?,
            argon_params: value.argon_params.try_into()?,
            features: WalletFeatures {
                currency_convert: value.currency_convert,
                ens_enabled: value.ens_enabled,
                ipfs_node: value.ipfs_node,
            },
            network: NetworkSettings {
                gas_control_enabled: value.gas_control_enabled,
                node_ranking_enabled: value.node_ranking_enabled,
                max_connections: value.max_connections,
                request_timeout_secs: value.request_timeout_secs,
            },
        })
    }
}
