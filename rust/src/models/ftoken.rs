use std::collections::HashMap;

use zilpay::token::ft::FToken;

#[derive(Debug)]
pub struct FTokenInfo {
    pub name: String,
    pub symbol: String,
    pub decimals: u8,
    pub addr: String,
    pub balances: HashMap<usize, String>,
    pub default: bool,
    pub provider_index: usize,
}

impl From<&FToken> for FTokenInfo {
    fn from(ft: &FToken) -> Self {
        let balances = ft
            .balances
            .iter()
            .map(|(account_index, balance)| (*account_index, balance.to_string()))
            .collect();

        FTokenInfo {
            balances,
            addr: ft.addr.auto_format(),
            name: ft.name.clone(),
            symbol: ft.symbol.clone(),
            decimals: ft.decimals,
            default: ft.default,
            provider_index: ft.provider_index,
        }
    }
}

impl From<FToken> for FTokenInfo {
    fn from(ft: FToken) -> Self {
        let balances = ft
            .balances
            .iter()
            .map(|(account_index, balance)| (*account_index, balance.to_string()))
            .collect();

        FTokenInfo {
            balances,
            addr: ft.addr.auto_format(),
            name: ft.name,
            symbol: ft.symbol,
            decimals: ft.decimals,
            default: ft.default,
            provider_index: ft.provider_index,
        }
    }
}
