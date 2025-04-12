use super::{account::AccountInfo, ftoken::FTokenInfo, settings::WalletSettingsInfo};
pub use zilpay::wallet::Wallet;
use zilpay::{errors::wallet::WalletErrors, wallet::wallet_storage::StorageOperations};

#[derive(Debug, PartialEq)]
pub struct WalletInfo {
    pub wallet_type: String,
    pub wallet_name: String,
    pub auth_type: String,
    pub wallet_address: String,
    pub accounts: Vec<AccountInfo>,
    pub selected_account: usize,
    pub tokens: Vec<FTokenInfo>,
    pub settings: WalletSettingsInfo,
    pub default_chain_hash: u64,
}

impl TryFrom<&Wallet> for WalletInfo {
    type Error = WalletErrors;

    fn try_from(w: &Wallet) -> Result<Self, Self::Error> {
        let data = w.get_wallet_data()?;
        let account = data.get_selected_account()?;
        let ftokens: Vec<FTokenInfo> = w
            .get_ftokens()?
            .into_iter()
            .filter_map(|t| {
                if t.chain_hash == account.chain_hash
                    && t.addr.prefix_type() == account.addr.prefix_type()
                {
                    Some(t.into())
                } else {
                    None
                }
            })
            .collect();

        Ok(Self {
            default_chain_hash: data.default_chain_hash,
            auth_type: data.biometric_type.into(),
            wallet_name: data.wallet_name,
            wallet_type: data.wallet_type.to_str(),
            wallet_address: hex::encode(w.wallet_address),
            accounts: data.accounts.iter().map(|v| v.into()).collect(),
            selected_account: data.selected_account,
            tokens: ftokens,
            settings: data.settings.into(),
        })
    }
}
