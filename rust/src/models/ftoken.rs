use std::collections::HashMap;
use zilpay::{errors::token::TokenError, proto::address::Address, token::ft::FToken};

#[derive(Debug)]
pub struct FTokenInfo {
    pub name: String,
    pub symbol: String,
    pub decimals: u8,
    pub addr: String,
    pub addr_type: u8,
    pub logo: Option<String>,
    pub balances: HashMap<usize, String>,
    pub rates: HashMap<String, f64>,
    pub default: bool,
    pub native: bool,
    pub chain_hash: u64,
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
            rates: ft.rates,
            logo: ft.logo,
            addr: ft.addr.auto_format(),
            addr_type: ft.addr.prefix_type(),
            name: ft.name,
            symbol: ft.symbol,
            decimals: ft.decimals,
            default: ft.default,
            native: ft.native,
            chain_hash: ft.chain_hash,
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
            rates: value.rates,
            logo: value.logo,
            balances: Default::default(),
            default: value.default,
            native: value.native,
            chain_hash: value.chain_hash,
        })
    }
}
