use super::{account::AccountInfo, ftoken::FTokenInfo, settings::WalletSettingsInfo};

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
    pub settings: WalletSettingsInfo,
}
