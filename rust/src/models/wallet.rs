use std::collections::HashMap;

use super::{account::AccountInfo, ftoken::FTokenInfo, settings::WalletSettingsInfo};
pub use zilpay::wallet::Wallet;
use zilpay::{errors::wallet::WalletErrors, wallet::wallet_storage::StorageOperations};

#[derive(Debug, PartialEq)]
pub struct WalletInfo {
    pub wallet_type: String,
    pub wallet_name: String,
    pub auth_type: String,
    pub wallet_address: String,
    pub accounts: HashMap<u32, HashMap<u32, Vec<AccountInfo>>>,
    pub selected_account: usize,
    pub tokens: Vec<FTokenInfo>,
    pub settings: WalletSettingsInfo,
    pub chain_hash: u64,
    pub slip44: u32,
    pub bip: u32,
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
                if t.chain_hash == data.chain_hash
                    && t.addr.prefix_type() == account.addr.prefix_type()
                {
                    Some(t.into())
                } else {
                    None
                }
            })
            .collect();
        let accounts: HashMap<u32, HashMap<u32, Vec<AccountInfo>>> = data
            .slip44_accounts
            .into_iter()
            .map(|(k, v)| {
                (
                    k,
                    v.into_iter()
                        .map(|(kk, vv)| (kk, vv.iter().map(|a| a.into()).collect()))
                        .collect(),
                )
            })
            .collect();

        Ok(Self {
            accounts,
            bip: data.bip,
            chain_hash: data.chain_hash,
            slip44: data.slip44,
            auth_type: data.biometric_type.into(),
            wallet_name: data.wallet_name,
            wallet_type: data.wallet_type.to_str(),
            wallet_address: hex::encode(w.wallet_address),
            selected_account: data.selected_account,
            tokens: ftokens,
            settings: data.settings.into(),
        })
    }
}
