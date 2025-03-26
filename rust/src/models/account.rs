use zilpay::wallet::account::Account;

#[derive(Debug, PartialEq)]
pub struct AccountInfo {
    pub addr: String,
    pub addr_type: u8,
    pub name: String,
    pub chain_hash: u64,
    pub chain_id: u64,
    pub slip_44: u32,
    pub index: usize,
}

impl From<&Account> for AccountInfo {
    fn from(account: &Account) -> Self {
        let addr_str = match &account.slip_44 {
            // TODO: possible add others chain and make specific address format.
            60 => account.addr.to_eth_checksummed().unwrap_or_default(),
            313 => account.addr.get_zil_bech32().unwrap_or_default(),
            _ => account.addr.auto_format(),
        };

        AccountInfo {
            addr: addr_str,
            addr_type: account.addr.prefix_type(),
            name: account.name.clone(),
            chain_hash: account.chain_hash,
            chain_id: account.chain_id,
            slip_44: account.slip_44,
            index: account.account_type.value(),
        }
    }
}
