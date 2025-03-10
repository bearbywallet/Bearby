use zilpay::background::book::AddressBookEntry;

#[derive(Debug)]
pub struct AddressBookEntryInfo {
    pub name: String,
    pub addr: String,
    pub net: usize,
    pub slip44: u32,
}

impl From<&AddressBookEntry> for AddressBookEntryInfo {
    fn from(book: &AddressBookEntry) -> Self {
        AddressBookEntryInfo {
            name: book.name.clone(),
            addr: book.addr.auto_format(),
            net: book.net,
            slip44: book.slip44,
        }
    }
}
