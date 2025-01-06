pub use zilpay::history::transaction::TokenInfo;

pub struct BaseTokenInfo {
    pub value: String,
    pub symbol: String,
    pub decimals: u8,
}

impl From<TokenInfo> for BaseTokenInfo {
    fn from(value: TokenInfo) -> Self {
        Self {
            value: value.value.to_string(),
            symbol: value.symbol,
            decimals: value.decimals,
        }
    }
}
