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
    background::{bg_provider::ProvidersManagement, bg_wallet::WalletManagement},
    crypto::slip44::ZILLIQA,
    proto::{address::Address, pubkey::PubKey},
    wallet::{wallet_storage::StorageOperations, wallet_types::WalletTypes},
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

pub async fn get_combine_sort_addresses(wallet_index: usize) -> Result<Vec<Category>, String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let wallet_data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let selected_account = wallet_data
            .get_selected_account()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let providers = core.get_providers();

        let my_accounts: Vec<Entry> = if selected_account.slip_44 == ZILLIQA
            && !matches!(wallet_data.wallet_type, WalletTypes::Ledger(_))
        {
            let capacity = wallet_data.accounts.len() * 2;
            let mut accounts = Vec::with_capacity(capacity);

            accounts.extend(wallet_data.accounts.iter().flat_map(|acc| {
                let name = acc.name.clone();
                let pub_key_bytes = acc.pub_key.as_bytes();
                vec![
                    Entry {
                        name: name.clone(),
                        address: PubKey::Secp256k1Sha256(pub_key_bytes)
                            .get_addr()
                            .unwrap_or(Address::Secp256k1Sha256(Address::ZERO))
                            .auto_format(),
                        tag: Some("legacy".to_string()),
                    },
                    Entry {
                        name: name,
                        address: PubKey::Secp256k1Keccak256(pub_key_bytes)
                            .get_addr()
                            .unwrap_or(Address::Secp256k1Keccak256(Address::ZERO))
                            .auto_format(),
                        tag: Some("evm".to_string()),
                    },
                ]
            }));

            accounts
        } else {
            wallet_data
                .accounts
                .iter()
                .map(|acc| Entry {
                    name: acc.name.clone(),
                    address: acc.addr.auto_format(),
                    tag: None,
                })
                .collect()
        };
        let book: Vec<Entry> = core
            .get_address_book()
            .into_iter()
            .filter_map(|contact| {
                if selected_account.addr.prefix_type() == contact.addr.prefix_type() {
                    Some(Entry {
                        name: contact.name,
                        address: contact.addr.auto_format(),
                        tag: Some("book".to_string()),
                    })
                } else {
                    None
                }
            })
            .collect();
        let wallets_category: Vec<Category> = core
            .wallets
            .iter()
            .filter_map(|other_wallet| {
                if other_wallet.wallet_address == wallet.wallet_address {
                    return None;
                }

                let data = if let Some(data) = other_wallet.get_wallet_data().ok() {
                    data
                } else {
                    return None;
                };

                let chain_teg = providers
                    .iter()
                    .find(|p| p.config.hash() == data.default_chain_hash)
                    .and_then(|p| Some(&p.config.name));
                let entries: Vec<Entry> = data
                    .accounts
                    .into_iter()
                    .filter_map(|acc| {
                        if acc.addr.prefix_type() == selected_account.addr.prefix_type() {
                            Some(Entry {
                                name: acc.name,
                                address: acc.addr.auto_format(),
                                tag: chain_teg.cloned(),
                            })
                        } else {
                            None
                        }
                    })
                    .collect();

                Some(Category {
                    entries,
                    name: data.wallet_name,
                })
            })
            .collect();
        let mut categories: Vec<Category> = vec![
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
