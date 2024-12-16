use zilpay::wallet::account::Account;

#[derive(Debug)]
pub struct AccountInfo {
    pub addr: String,
    pub name: String,
}

impl From<&Account> for AccountInfo {
    fn from(account: &Account) -> Self {
        AccountInfo {
            addr: account.addr.auto_format(),
            name: account.name.clone(),
        }
    }
}
