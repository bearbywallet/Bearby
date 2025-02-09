use zilpay::wallet::account::Account;

#[derive(Debug)]
pub struct AccountInfo {
    pub addr: String,
    pub addr_type: u8,
    pub name: String,
    pub chain_hash: u64,
    pub index: usize,
}

impl From<&Account> for AccountInfo {
    fn from(account: &Account) -> Self {
        AccountInfo {
            addr: account.addr.auto_format(),
            addr_type: account.addr.prefix_type(),
            name: account.name.clone(),
            chain_hash: account.chain_hash,
            index: account.account_type.value(),
        }
    }
}
