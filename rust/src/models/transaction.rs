pub use zilpay::config::sha::SHA256_SIZE;
pub use zilpay::proto::tx::{TransactionMetadata, TransactionRequest};

pub struct TransactionMetadataInfo {
    pub hash: Option<String>,
    pub info: Option<String>,
    pub icon: Option<String>,
    pub title: Option<String>,
    pub signer: Option<String>,
    pub token_info: Option<(String, u8, String)>,
}

pub struct AccessListItem {
    pub address: String,
    pub storage_keys: Vec<[u8; SHA256_SIZE]>, // B256 -> [u8;32]
}

pub struct TransactionRequestEVM {
    // Base
    pub nonce: Option<u64>,
    pub from: String,
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
    pub blob_versioned_hashes: Option<Vec<[u8; SHA256_SIZE]>>, // B256 -> [u8;32]
    pub max_fee_per_blob_gas: Option<u128>,
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
