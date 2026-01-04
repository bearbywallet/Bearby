use super::base_token::BaseTokenInfo;
pub use super::transaction_metadata::TransactionMetadataInfo;
use zilpay::history::status::TransactionStatus;
pub use zilpay::history::transaction::HistoricalTransaction;

#[derive(Debug)]
pub enum TransactionStatusInfo {
    Pending,
    Success,
    Failed,
}

impl From<TransactionStatus> for TransactionStatusInfo {
    fn from(value: TransactionStatus) -> Self {
        match value {
            TransactionStatus::Pending => TransactionStatusInfo::Pending,
            TransactionStatus::Success => TransactionStatusInfo::Success,
            TransactionStatus::Failed => TransactionStatusInfo::Failed,
        }
    }
}

#[derive(Debug)]
pub struct HistoricalTransactionInfo {
    pub status: TransactionStatusInfo,
    pub metadata: TransactionMetadataInfo,
    pub evm: Option<String>,
    pub scilla: Option<String>,
    pub signed_message: Option<String>,
    pub timestamp: u64,
}

impl From<HistoricalTransaction> for HistoricalTransactionInfo {
    fn from(value: HistoricalTransaction) -> Self {
        Self {
            status: value.status.into(),
            metadata: TransactionMetadataInfo {
                chain_hash: value.metadata.chain_hash,
                hash: value.metadata.hash,
                info: value.metadata.info,
                icon: value.metadata.icon,
                title: value.metadata.title,
                signer: value.metadata.signer.map(|s| s.to_string()),
                token_info: value.metadata.token_info.map(|(v, d, s)| BaseTokenInfo {
                    value: v.to_string(),
                    decimals: d,
                    symbol: s,
                }),
                btc_utxo_amounts: value.metadata.btc_utxo_amounts,
            },
            evm: value.evm,
            scilla: value.scilla,
            signed_message: value.signed_message,
            timestamp: value.timestamp,
        }
    }
}
