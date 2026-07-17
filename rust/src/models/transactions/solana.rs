pub use zilpay::proto::solana_tx::SolanaHistoryTransaction;

/// FFI mirror of core `SolanaHistoryTransaction` (history path).
/// Byte fields are hex-encoded strings for FRB/Dart.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TransactionSolana {
    pub message: String,
    pub signature: String,
    pub fee: Option<u64>,
    pub slot: Option<u64>,
    /// Base58 signature (Solana tx id).
    pub tx_id: String,
}

impl From<SolanaHistoryTransaction> for TransactionSolana {
    fn from(value: SolanaHistoryTransaction) -> Self {
        let tx_id = value.tx_id();
        Self {
            message: zilpay::alloy::hex::encode(value.message),
            signature: zilpay::alloy::hex::encode(value.signature),
            fee: value.fee,
            slot: value.slot,
            tx_id,
        }
    }
}
