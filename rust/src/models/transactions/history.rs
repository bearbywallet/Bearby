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
    pub btc: Option<String>,
    pub tron: Option<String>,
    pub signed_message: Option<String>,
    pub timestamp: u64,
}

impl From<HistoricalTransaction> for HistoricalTransactionInfo {
    fn from(value: HistoricalTransaction) -> Self {
        let btc_witness_utxos = value
            .metadata
            .btc_witness_utxos
            .and_then(|witness_utxos| serde_json::to_string(&witness_utxos).ok());

        Self {
            status: value.status.into(),
            metadata: TransactionMetadataInfo {
                btc_witness_utxos,
                chain_hash: value.metadata.chain_hash,
                hash: value.metadata.hash,
                info: value.metadata.info,
                icon: value.metadata.icon,
                title: value.metadata.title,
                broadcast: value.metadata.broadcast,
                signer: value.metadata.signer.map(|s| s.to_string()),
                token_info: value.metadata.token_info.map(|(v, d, s)| BaseTokenInfo {
                    value: v.to_string(),
                    decimals: d,
                    symbol: s,
                }),
            },
            btc: value.btc,
            tron: value.tron,
            evm: value.evm,
            scilla: value.scilla,
            signed_message: value.signed_message,
            timestamp: value.timestamp,
        }
    }
}
