use super::btc::{BitcoinMetadataInfo, TransactionBitcoin};
use super::solana::TransactionSolana;
pub use super::transaction_metadata::TransactionMetadataInfo;
use super::tron::TransactionTron;
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
    pub btc: Option<TransactionBitcoin>,
    pub tron: Option<TransactionTron>,
    pub solana: Option<TransactionSolana>,
    pub signed_message: Option<String>,
    pub timestamp: u64,
}

impl From<HistoricalTransaction> for HistoricalTransactionInfo {
    fn from(value: HistoricalTransaction) -> Self {
        let network = value
            .metadata
            .signer
            .as_ref()
            .and_then(|s| s.get_bitcoin_network().ok())
            .unwrap_or(zilpay::bitcoin::Network::Bitcoin);

        Self {
            status: value.status.into(),
            metadata: value.metadata.into(),
            btc: value.btc.map(|(tx, meta)| {
                let meta = BitcoinMetadataInfo::from(meta);
                TransactionBitcoin::from_tx_with_utxos(tx, &meta.witness_utxos, network)
            }),
            tron: value.tron.map(Into::into),
            solana: value.solana.map(Into::into),
            evm: value.evm,
            scilla: value.scilla,
            signed_message: value.signed_message,
            timestamp: value.timestamp,
        }
    }
}
