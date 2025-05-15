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
