use std::str::FromStr;

pub use zilpay::config::sha::SHA256_SIZE;
pub use zilpay::errors::address::AddressError;
pub use zilpay::proto::tx::{TransactionMetadata, TransactionRequest};
pub use zilpay::proto::U256;
pub use zilpay::proto::{address::Address, pubkey::PubKey};
pub use zilpay::proto::{
    AlloyAccessList, AlloyAccessListItem, AlloyAddress, AlloyBytes, AlloyTxKind,
};
pub use zilpay::{
    errors::tx::TransactionErrors,
    proto::{tx::ETHTransactionRequest, zil_tx::ZILTransactionRequest},
};

pub struct AccessListItem {
    pub address: String,
    pub storage_keys: Vec<String>,
}

impl From<AlloyAccessListItem> for AccessListItem {
    fn from(value: AlloyAccessListItem) -> Self {
        Self {
            address: value.address.to_string(),
            storage_keys: value
                .storage_keys
                .iter()
                .map(|k| hex::encode(k.0))
                .collect(),
        }
    }
}

impl TryFrom<AccessListItem> for AlloyAccessListItem {
    type Error = TransactionErrors;

    fn try_from(value: AccessListItem) -> Result<Self, Self::Error> {
        Ok(Self {
            address: AlloyAddress::from_str(&value.address).unwrap_or_default(),
            storage_keys: value
                .storage_keys
                .into_iter()
                .map(|key| {
                    let bytes = hex::decode(key).map_err(|_| TransactionErrors::InvalidHash)?;

                    if bytes.len() != SHA256_SIZE {
                        return Err(TransactionErrors::InvalidHash);
                    }

                    let mut array = [0u8; SHA256_SIZE];
                    array.copy_from_slice(&bytes);

                    Ok(array.into())
                })
                .collect::<Result<Vec<_>, _>>()?,
        })
    }
}
