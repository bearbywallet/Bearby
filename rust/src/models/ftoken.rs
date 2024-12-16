use std::collections::HashMap;

use zilpay::wallet::ft::FToken;

#[derive(Debug)]
pub struct FTokenInfo {
    pub name: String,
    pub symbol: String,
    pub decimals: u8,
    pub addr: String,
    pub balances: HashMap<String, String>,
    pub default: bool,
    pub net_id: usize,
}

impl From<&FToken> for FTokenInfo {
    fn from(ft: &FToken) -> Self {
        let balances = ft
            .balances
            .iter()
            .map(|(addr, balance)| (addr.auto_format(), balance.to_string()))
            .collect();

        FTokenInfo {
            balances,
            addr: ft.addr.auto_format(),
            name: ft.name.clone(),
            symbol: ft.symbol.clone(),
            decimals: ft.decimals,
            default: ft.default,
            net_id: ft.net_id,
        }
    }
}
