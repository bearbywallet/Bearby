use zilpay::wallet::account::Account;

#[derive(Debug)]
pub struct AccountInfo {
    pub addr: String,
    pub name: String,
    pub provider_index: usize,
}

impl From<&Account> for AccountInfo {
    fn from(account: &Account) -> Self {
        AccountInfo {
            addr: account.addr.auto_format(),
            name: account.name.clone(),
            provider_index: account.provider_index,
        }
    }
}
