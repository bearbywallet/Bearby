pub use zilpay::proto::tx::{TransactionMetadata, TransactionRequest};
use zilpay::proto::{tx::ETHTransactionRequest, zil_tx::ZILTransactionRequest};

pub enum ChainType {
    Scilla,
    Evm,
}

pub struct TransactionRequestInfo {
    pub metadata: TransactionMetadataInfo,
    pub chain_type: ChainType,
    pub scilla: Option<TransactionRequestScilla>,
    pub evm: Option<TransactionRequestEVM>,
}

impl From<TransactionRequest> for TransactionRequestInfo {
    fn from(value: TransactionRequest) -> Self {
        let chain_type = match value {
            TransactionRequest::Zilliqa(_) => ChainType::Scilla,
            TransactionRequest::Ethereum(_) => ChainType::Evm,
        };
        let metadata: TransactionMetadataInfo = match value {
            TransactionRequest::Zilliqa((_, ref metadata)) => metadata.to_owned().into(),
            TransactionRequest::Ethereum((_, ref metadata)) => metadata.to_owned().into(),
        };

        match value {
            TransactionRequest::Zilliqa((tx, _)) => Self {
                chain_type,
                metadata,
                scilla: Some(tx.into()),
                evm: None,
            },
            TransactionRequest::Ethereum((tx, _)) => Self {
                chain_type,
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
            signer: value.signer.map(|v| v.as_hex_str()),
            token_info: value.token_info.map(|t| BaseTokenInfo {
                value: t.0.to_string(),
                decimals: t.1,
                symbol: t.2,
            }),
        }
    }
}

pub struct AccessListItem {
    pub address: String,
    pub storage_keys: Vec<String>, // B256 -> [u8;32]
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
            access_list: value.access_list.map(|list| {
                list.iter()
                    .map(|item| AccessListItem {
                        address: item.address.to_string(),
                        storage_keys: item.storage_keys.iter().map(|k| hex::encode(k.0)).collect(),
                    })
                    .collect()
            }),
            blob_versioned_hashes: value
                .blob_versioned_hashes
                .map(|hashes| hashes.iter().map(|h| hex::encode(h.0)).collect()),
            max_fee_per_blob_gas: value.max_fee_per_blob_gas,
        }
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
