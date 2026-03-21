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

use super::base_token::BaseTokenInfo;

#[derive(Debug, Clone)]
pub struct TransactionMetadataInfo {
    pub chain_hash: u64,
    pub hash: Option<String>,
    pub info: Option<String>,
    pub icon: Option<String>,
    pub title: Option<String>,
    pub signer: Option<String>,
    pub token_info: Option<BaseTokenInfo>,
    pub btc_witness_utxos: Option<String>,
    pub broadcast: bool,
}

impl From<TransactionMetadata> for TransactionMetadataInfo {
    fn from(value: TransactionMetadata) -> Self {
        let btc_witness_utxos = value
            .btc_witness_utxos
            .and_then(|witness_utxos| serde_json::to_string(&witness_utxos).ok());

        Self {
            btc_witness_utxos,
            chain_hash: value.chain_hash,
            hash: value.hash,
            info: value.info,
            icon: value.icon,
            title: value.title,
            signer: value.signer.map(|v| v.to_string()),
            broadcast: value.broadcast,
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
        let btc_witness_utxos = value
            .btc_witness_utxos
            .and_then(|witness_utxos| serde_json::from_str(&witness_utxos).ok());

        Self {
            btc_witness_utxos,
            chain_hash: value.chain_hash,
            hash: value.hash,
            info: value.info,
            icon: value.icon,
            title: value.title,
            broadcast: value.broadcast,
            signer: value.signer.and_then(|v| Address::from_str_hex(&v).ok()),
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
