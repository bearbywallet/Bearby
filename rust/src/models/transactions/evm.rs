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

use super::access_list::AccessListItem;

pub struct TransactionRequestEVM {
    pub nonce: Option<u64>,
    pub from: Option<String>,
    pub to: Option<String>,
    pub value: Option<String>,
    pub gas_limit: Option<u64>,
    pub data: Option<Vec<u8>>,
    pub max_fee_per_gas: Option<u128>,
    pub max_priority_fee_per_gas: Option<u128>,
    pub gas_price: Option<u128>,
    pub chain_id: Option<u64>,
    pub access_list: Option<Vec<AccessListItem>>,
    pub blob_versioned_hashes: Option<Vec<String>>,
    pub max_fee_per_blob_gas: Option<u128>,
}

impl From<ETHTransactionRequest> for TransactionRequestEVM {
    fn from(value: ETHTransactionRequest) -> Self {
        Self {
            nonce: value.nonce,
            from: value.from.map(|a| a.to_string()),
            to: value
                .to
                .and_then(|k| k.to().cloned())
                .map(|addr| addr.to_string()),
            value: value.value.map(|v| v.to_string()),
            gas_limit: value.gas,
            data: value.input.into_input().map(|b| b.into()),
            max_fee_per_gas: value.max_fee_per_gas,
            max_priority_fee_per_gas: value.max_priority_fee_per_gas,
            gas_price: value.gas_price,
            chain_id: value.chain_id,
            access_list: value
                .access_list
                .map(|list| list.iter().map(|item| item.clone().into()).collect()),
            blob_versioned_hashes: value
                .blob_versioned_hashes
                .map(|hashes| hashes.iter().map(|h| hex::encode(h.0)).collect()),
            max_fee_per_blob_gas: value.max_fee_per_blob_gas,
        }
    }
}

impl TryFrom<TransactionRequestEVM> for ETHTransactionRequest {
    type Error = TransactionErrors;

    fn try_from(value: TransactionRequestEVM) -> Result<Self, Self::Error> {
        Ok(Self {
            from: value
                .from
                .and_then(|addr| AlloyAddress::from_str(&addr).ok()),
            to: match value.to {
                Some(to) => Some(AlloyTxKind::Call(AlloyAddress::from_str(&to).map_err(
                    |_| TransactionErrors::AddressError(AddressError::InvalidETHAddress(to)),
                )?)),
                None => Some(AlloyTxKind::Create),
            },
            gas_price: value.gas_price,
            max_fee_per_gas: value.max_fee_per_gas,
            max_priority_fee_per_gas: value.max_priority_fee_per_gas,
            max_fee_per_blob_gas: value.max_fee_per_blob_gas,
            gas: value.gas_limit,
            value: value.value.and_then(|v| U256::from_str(&v).ok()),
            input: value.data.map(AlloyBytes::from).into(),
            nonce: value.nonce,
            chain_id: value.chain_id,
            access_list: value
                .access_list
                .map(|list| {
                    list.into_iter()
                        .map(|item| item.try_into())
                        .collect::<Result<Vec<AlloyAccessListItem>, _>>()
                })
                .transpose()?
                .map(|v| v.into()),
            blob_versioned_hashes: value
                .blob_versioned_hashes
                .map(|hashes| {
                    hashes
                        .into_iter()
                        .map(|hash| {
                            let bytes =
                                hex::decode(hash).map_err(|_| TransactionErrors::InvalidHash)?;
                            if bytes.len() != SHA256_SIZE {
                                return Err(TransactionErrors::InvalidHash);
                            }
                            let mut array = [0u8; SHA256_SIZE];
                            array.copy_from_slice(&bytes);
                            Ok(array.into())
                        })
                        .collect::<Result<Vec<_>, _>>()
                })
                .transpose()?,
            transaction_type: None,
            sidecar: None,
            authorization_list: None,
        })
    }
}
