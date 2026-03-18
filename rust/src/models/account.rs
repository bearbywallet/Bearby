use zilpay::wallet::{account::AccountV2, account_type::AccountType};

#[derive(Debug, PartialEq)]
pub struct AccountInfo {
    pub addr: String,
    pub pub_key: Option<String>,
    pub addr_type: u8,
    pub name: String,
    pub chain_hash: u64,
    pub index: usize,
}

impl From<&AccountV2> for AccountInfo {
    fn from(account: &AccountV2) -> Self {
        let index = match account.account_type {
            AccountType::Ledger(index) => index,
            AccountType::Bip39HD(index) => index,
            AccountType::PrivateKey(_) => 0,
        };

        AccountInfo {
            index,
            pub_key: account.pub_key.clone().map(|pk| pk.to_string()),
            addr: account.addr.auto_format(),
            addr_type: account.addr.prefix_type(),
            name: account.name.clone(),
            chain_hash: account.chain_hash,
        }
    }
}
