use std::collections::HashMap;

use zilpay::{proto::address::Address, token::ft::FToken, zil_errors::token::TokenError};

#[derive(Debug)]
pub struct FTokenInfo {
    pub name: String,
    pub symbol: String,
    pub decimals: u8,
    pub addr: String,
    pub logo: Option<String>,
    pub balances: HashMap<usize, String>,
    pub default: bool,
    pub native: bool,
    pub provider_index: usize,
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
            logo: ft.logo,
            addr: ft.addr.auto_format(),
            name: ft.name,
            symbol: ft.symbol,
            decimals: ft.decimals,
            default: ft.default,
            native: ft.native,
            provider_index: ft.provider_index,
        }
    }
}

impl TryFrom<FTokenInfo> for FToken {
    type Error = TokenError;

    fn try_from(value: FTokenInfo) -> Result<Self, Self::Error> {
        Ok(Self {
            name: value.name,
            symbol: value.symbol,
            decimals: value.decimals,
            addr: Address::from_str_hex(&value.addr).map_err(TokenError::InvalidContractAddress)?,
            logo: value.logo,
            balances: HashMap::new(),
            default: value.default,
            native: value.native,
            provider_index: value.provider_index,
        })
    }
}
