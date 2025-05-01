use zilpay::wallet::{account::Account, account_type::AccountType};

#[derive(Debug, PartialEq)]
pub struct AccountInfo {
    pub addr: String,
    pub addr_type: u8,
    pub name: String,
    pub pub_key: String,
    pub chain_hash: u64,
    pub chain_id: u64,
    pub slip_44: u32,
    pub index: usize,
}

impl From<&Account> for AccountInfo {
    fn from(account: &Account) -> Self {
        let index = match account.account_type {
            AccountType::Ledger(index) => index,
            AccountType::Bip39HD(index) => index,
            AccountType::PrivateKey(_) => 0,
        };

        AccountInfo {
            index,
            pub_key: account.pub_key.as_hex_str(),
            addr: account.addr.auto_format(),
            addr_type: account.addr.prefix_type(),
            name: account.name.clone(),
            chain_hash: account.chain_hash,
            chain_id: account.chain_id,
            slip_44: account.slip_44,
        }
    }
}
