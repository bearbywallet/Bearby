use std::str::FromStr;

pub use zilpay::config::sha::SHA256_SIZE;
pub use zilpay::proto::tx::{TransactionMetadata, TransactionRequest};
pub use zilpay::proto::U256;
pub use zilpay::proto::{address::Address, pubkey::PubKey};
pub use zilpay::proto::{
    AlloyAccessList, AlloyAccessListItem, AlloyAddress, AlloyBytes, AlloyTxKind,
};
pub use zilpay::zil_errors::address::AddressError;
pub use zilpay::{
    proto::{tx::ETHTransactionRequest, zil_tx::ZILTransactionRequest},
    zil_errors::tx::TransactionErrors,
};

pub struct TransactionRequestInfo {
    pub metadata: TransactionMetadataInfo,
    pub scilla: Option<TransactionRequestScilla>,
    pub evm: Option<TransactionRequestEVM>,
}

impl TryFrom<TransactionRequestInfo> for TransactionRequest {
    type Error = TransactionErrors;

    fn try_from(value: TransactionRequestInfo) -> Result<Self, Self::Error> {
        if let Some(scilla_tx) = value.scilla {
            let tx_req =
                TransactionRequest::Zilliqa((scilla_tx.try_into()?, value.metadata.into()));

            Ok(tx_req)
        } else if let Some(evm_tx) = value.evm {
            let tx_req = TransactionRequest::Ethereum((evm_tx.try_into()?, value.metadata.into()));

            Ok(tx_req)
        } else {
            Err(TransactionErrors::InvalidTxHash)
        }
    }
}

impl From<TransactionRequest> for TransactionRequestInfo {
    fn from(value: TransactionRequest) -> Self {
        let metadata: TransactionMetadataInfo = match value {
            TransactionRequest::Zilliqa((_, ref metadata)) => metadata.to_owned().into(),
            TransactionRequest::Ethereum((_, ref metadata)) => metadata.to_owned().into(),
        };

        match value {
            TransactionRequest::Zilliqa((tx, _)) => Self {
                metadata,
                scilla: Some(tx.into()),
                evm: None,
            },
            TransactionRequest::Ethereum((tx, _)) => Self {
                metadata,
                scilla: None,
                evm: Some(tx.into()),
            },
        }
    }
}

pub struct BaseTokenInfo {
    pub value: String,
    pub symbol: String,
    pub decimals: u8,
}

pub struct TransactionMetadataInfo {
    pub provider_index: usize,
    pub hash: Option<String>,
    pub info: Option<String>,
    pub icon: Option<String>,
    pub title: Option<String>,
    pub signer: Option<String>,
    pub token_info: Option<BaseTokenInfo>,
}

impl From<TransactionMetadata> for TransactionMetadataInfo {
    fn from(value: TransactionMetadata) -> Self {
        Self {
            provider_index: value.provider_index,
            hash: value.hash,
            info: value.info,
            icon: value.icon,
            title: value.title,
            signer: value.signer.map(|v| v.to_string()),
            token_info: value.token_info.map(|t| BaseTokenInfo {
                value: t.0.to_string(),
                decimals: t.1,
                symbol: t.2,
            }),
        }
    }
}

impl From<TransactionMetadataInfo> for TransactionMetadata {
    fn from(value: TransactionMetadataInfo) -> Self {
        Self {
            provider_index: value.provider_index,
            hash: value.hash,
            info: value.info,
            icon: value.icon,
            title: value.title,
            signer: value.signer.and_then(|v| PubKey::from_str(&v).ok()),
            token_info: value.token_info.map(|v| {
                (
                    U256::from_str(&v.value).unwrap_or_default(),
                    v.decimals,
                    v.symbol,
                )
            }),
        }
    }
}

pub struct AccessListItem {
    pub address: String,
    pub storage_keys: Vec<String>, // B256 -> [u8;32]
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

pub struct TransactionRequestEVM {
    // Base
    pub nonce: Option<u64>,
    pub from: Option<String>,
    pub to: Option<String>,
    pub value: Option<String>,
    pub gas_limit: Option<u64>,
    pub data: Option<Vec<u8>>,

    // EIP-1559
    pub max_fee_per_gas: Option<u128>,
    pub max_priority_fee_per_gas: Option<u128>,

    // Legacy
    pub gas_price: Option<u128>,

    // EIP-155
    pub chain_id: Option<u64>,

    // EIP-2930
    pub access_list: Option<Vec<AccessListItem>>,

    // EIP-4844
    pub blob_versioned_hashes: Option<Vec<String>>, // B256 -> [u8;32]
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

pub struct TransactionRequestScilla {
    pub chain_id: u16,
    pub nonce: u64,
    pub gas_price: u128,
    pub gas_limit: u64,
    pub to_addr: String,
    pub amount: u128,
    pub code: String,
    pub data: String,
}

impl From<ZILTransactionRequest> for TransactionRequestScilla {
    fn from(value: ZILTransactionRequest) -> Self {
        Self {
            chain_id: value.chain_id,
            nonce: value.nonce,
            gas_price: value.gas_price,
            gas_limit: value.gas_limit,
            to_addr: value.to_addr.auto_format(),
            amount: value.amount,
            code: String::from_utf8(value.code).unwrap_or_default(),
            data: String::from_utf8(value.data).unwrap_or_default(),
        }
    }
}

impl TryFrom<TransactionRequestScilla> for ZILTransactionRequest {
    type Error = AddressError;

    fn try_from(value: TransactionRequestScilla) -> Result<Self, Self::Error> {
        Ok(Self {
            chain_id: value.chain_id,
            nonce: value.nonce,
            gas_price: value.gas_price,
            gas_limit: value.gas_limit,
            to_addr: Address::from_str_hex(&value.to_addr)?,
            amount: value.amount,
            code: value.code.into_bytes(),
            data: value.data.into_bytes(),
        })
    }
}
