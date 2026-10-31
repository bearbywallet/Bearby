use std::collections::HashMap;

use super::{account::AccountInfo, ftoken::FTokenInfo, settings::WalletSettingsInfo};
pub use zilpay::wallet::Wallet;
use zilpay::{
    background::bg_wallet::{
        Bip39ChainBalance, Bip39DiscoveredAccount, Bip39ScanChunkResult,
    },
    errors::wallet::WalletErrors,
    wallet::wallet_storage::StorageOperations,
};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Bip39ChainBalanceInfo {
    pub chain_name: String,
    pub chain_hash: u64,
    pub slip44: u32,
    pub addr: String,
    pub symbol: String,
    pub balance: String,
    pub decimals: u8,
    pub tx_count: u32,
}

impl From<Bip39ChainBalance> for Bip39ChainBalanceInfo {
    fn from(value: Bip39ChainBalance) -> Self {
        Self {
            chain_name: value.chain_name,
            chain_hash: value.chain_hash,
            slip44: value.slip44,
            addr: value.addr,
            symbol: value.symbol,
            balance: value.balance,
            decimals: value.decimals,
            tx_count: value.tx_count,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Bip39DiscoveredAccountInfo {
    pub index: u32,
    pub addr: String,
    pub legacy_addr: Option<String>,
    pub balance: String,
    pub decimals: u8,
    pub symbol: String,
    pub tx_count: u32,
    pub has_activity: bool,
    pub chain_balances: Vec<Bip39ChainBalanceInfo>,
}

impl From<Bip39DiscoveredAccount> for Bip39DiscoveredAccountInfo {
    fn from(value: Bip39DiscoveredAccount) -> Self {
        Self {
            index: value.index,
            addr: value.addr,
            legacy_addr: value.legacy_addr,
            balance: value.balance,
            decimals: value.decimals,
            symbol: value.symbol,
            tx_count: value.tx_count,
            has_activity: value.has_activity,
            chain_balances: value.chain_balances.into_iter().map(Into::into).collect(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct Bip39ScanChunkResultInfo {
    pub accounts: Vec<Bip39DiscoveredAccountInfo>,
    pub scanned_from: u32,
    pub scanned_to: u32,
    pub total_target: u32,
    pub cached_count: u32,
    pub network_error: Option<String>,
}

impl From<Bip39ScanChunkResult> for Bip39ScanChunkResultInfo {
    fn from(value: Bip39ScanChunkResult) -> Self {
        Self {
            accounts: value.accounts.into_iter().map(Into::into).collect(),
            scanned_from: value.scanned_from,
            scanned_to: value.scanned_to,
            total_target: value.total_target,
            cached_count: value.cached_count,
            network_error: value.network_error,
        }
    }
}

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
            wallet_address: zilpay::alloy::hex::encode(w.wallet_address),
            selected_account: data.selected_account,
            tokens: ftokens,
            settings: data.settings.into(),
        })
    }
}
