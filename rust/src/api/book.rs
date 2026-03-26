use crate::{
    models::book::AddressBookEntryInfo,
    utils::{
        errors::ServiceError,
        utils::{parse_address, with_service},
    },
};
pub use zilpay::background::bg_book::AddressBookManagement;
pub use zilpay::background::book::AddressBookEntry;
pub use zilpay::settings::{
    notifications::NotificationState,
    theme::{Appearances, Theme},
};
use zilpay::{
    background::bg_wallet::WalletManagement,
    crypto::{
        bip49::DerivationPath,
        slip44::{BITCOIN, ZILLIQA},
    },
    wallet::{account::AccountV2, wallet_storage::StorageOperations, wallet_types::WalletTypes},
};

pub async fn add_new_book_address(
    name: String,
    addr: String,
    net: usize,
    slip44: u32,
) -> Result<(), String> {
    with_service(|core| {
        let address = parse_address(addr)?;
        let book = AddressBookEntry::add(name, address, net, slip44);

        core.add_to_address_book(book)
            .map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(Into::into)
}

pub async fn remove_from_address_book(addr: String) -> Result<(), String> {
    with_service(|core| {
        let address = parse_address(addr)?;

        core.remove_from_address_book(&address)
            .map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(Into::into)
}

pub async fn get_address_book_list() -> Result<Vec<AddressBookEntryInfo>, String> {
    with_service(|core| Ok(core.get_address_book().iter().map(Into::into).collect()))
        .await
        .map_err(Into::into)
}

pub struct Category {
    pub name: String,
    pub entries: Vec<Entry>,
}

pub struct Entry {
    pub name: String,
    pub address: String,
    pub tag: Option<String>,
}

fn build_accounts_entries(
    accounts: &[AccountV2],
    wallet_type: &WalletTypes,
    slip44: u32,
) -> Vec<Entry> {
    if slip44 == ZILLIQA && !matches!(wallet_type, WalletTypes::Ledger(_)) {
        accounts
            .iter()
            .flat_map(|acc| {
                if let Ok((legacy, eth)) = acc.get_zilliqa_addr_pair() {
                    vec![
                        Entry {
                            name: acc.name.clone(),
                            address: legacy.auto_format(),
                            tag: Some("legacy".to_string()),
                        },
                        Entry {
                            name: acc.name.clone(),
                            address: eth.auto_format(),
                            tag: Some("evm".to_string()),
                        },
                    ]
                } else {
                    vec![]
                }
            })
            .collect()
    } else {
        accounts
            .iter()
            .map(|acc| Entry {
                name: acc.name.clone(),
                address: acc.addr.auto_format(),
                tag: None,
            })
            .collect()
    }
}

pub async fn get_combine_sort_addresses(wallet_index: usize) -> Result<Vec<Category>, String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let wallet_data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let selected_slip44 = wallet_data.slip44;
        let selected_bip = wallet_data.bip;

        let my_accounts = wallet_data
            .slip44_accounts
            .get(&selected_slip44)
            .and_then(|bip_map| bip_map.get(&selected_bip))
            .map(|accounts| {
                build_accounts_entries(accounts, &wallet_data.wallet_type, selected_slip44)
            })
            .unwrap_or_default();

        let book: Vec<Entry> = core
            .get_address_book()
            .into_iter()
            .filter(|contact| contact.slip44 == selected_slip44)
            .map(|contact| Entry {
                name: contact.name,
                address: contact.addr.auto_format(),
                tag: Some("book".to_string()),
            })
            .collect();

        let wallets_category: Vec<Category> = core
            .wallets
            .iter()
            .filter_map(|other_wallet| {
                if other_wallet.wallet_address == wallet.wallet_address {
                    return None;
                }

                let data = match other_wallet.get_wallet_data() {
                    Ok(d) => d,
                    Err(_) => return None,
                };

                let resolve_bip = if selected_slip44 == BITCOIN {
                    data.bip_preferences
                        .get(&selected_slip44)
                        .copied()
                        .unwrap_or_else(|| DerivationPath::default_bip(selected_slip44))
                } else {
                    DerivationPath::BIP44_PURPOSE
                };

                let accounts = data
                    .slip44_accounts
                    .get(&selected_slip44)
                    .and_then(|bip_map| bip_map.get(&resolve_bip))?;

                let entries = build_accounts_entries(accounts, &data.wallet_type, selected_slip44);
                if entries.is_empty() {
                    return None;
                }

                Some(Category {
                    entries,
                    name: data.wallet_name,
                })
            })
            .collect();

        let mut categories = vec![
            Category {
                name: String::from("my_accounts"),
                entries: my_accounts,
            },
            Category {
                name: String::from("book"),
                entries: book,
            },
        ];

        categories.extend(wallets_category);

        Ok(categories)
    })
    .await
    .map_err(Into::into)
}
