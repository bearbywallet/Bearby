use zilpay::proto::solana_tx::SolanaHistoryTransaction;

/// FRB/Dart-facing Solana history payload (typed, Bitcoin/Tron style).
#[derive(Debug, Clone)]
pub struct TransactionSolana {
    pub message: Vec<u8>,
    pub signature: Vec<u8>,
    /// Base58 signature string for UI / explorers.
    pub transaction_hash: String,
    pub fee: Option<u64>,
    pub slot: Option<u64>,
}

impl From<&SolanaHistoryTransaction> for TransactionSolana {
    fn from(value: &SolanaHistoryTransaction) -> Self {
        Self {
            // FRB ownership boundary: clone message/signature bytes for Dart.
            message: value.message.clone(),
            signature: value.signature.clone(),
            transaction_hash: value.tx_id(),
            fee: value.fee,
            slot: value.slot,
        }
    }
}

impl From<SolanaHistoryTransaction> for TransactionSolana {
    fn from(value: SolanaHistoryTransaction) -> Self {
        let transaction_hash = value.tx_id();
        Self {
            message: value.message,
            signature: value.signature,
            transaction_hash,
            fee: value.fee,
            slot: value.slot,
        }
    }
}

impl From<TransactionSolana> for SolanaHistoryTransaction {
    fn from(value: TransactionSolana) -> Self {
        Self {
            message: value.message,
            signature: value.signature,
            fee: value.fee,
            slot: value.slot,
        }
    }
}
