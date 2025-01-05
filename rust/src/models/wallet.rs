use zilpay::settings::argon2::ArgonParams;

use super::{account::AccountInfo, ftoken::FTokenInfo};

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
pub struct WalletInfo {
    pub wallet_type: String,
    pub wallet_name: String,
    pub auth_type: String,
    pub wallet_address: String,
    pub accounts: Vec<AccountInfo>,
    pub selected_account: usize,
    pub tokens: Vec<FTokenInfo>,
    pub provider: usize,
    pub cipher_orders: Vec<u8>,
    pub argon_params: ArgonParams,
    pub currency_convert: Option<String>,
    pub ipfs_node: Option<String>,
    pub ens_enabled: bool,
    pub gas_control_enabled: bool,
    pub node_ranking_enabled: bool,
    pub max_connections: u8,
    pub request_timeout_secs: u32,
}
