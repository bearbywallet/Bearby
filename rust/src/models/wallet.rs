use super::{account::AccountInfo, ftoken::FTokenInfo};

#[derive(Debug)]
pub struct WalletInfo {
    pub wallet_type: String,
    pub wallet_name: String,
    pub auth_type: String,
    pub wallet_address: String,
    pub accounts: Vec<AccountInfo>,
    pub selected_account: usize,
    pub tokens: Vec<FTokenInfo>,
    pub networks: Vec<usize>,
    pub cipher_orders: Vec<u8>,
    pub currency_convert: Option<String>,
    pub ipfs_node: Option<String>,
    pub ens_enabled: bool,
    pub gas_control_enabled: bool,
    pub node_ranking_enabled: bool,
    pub max_connections: u8,
    pub request_timeout_secs: u32,
}
