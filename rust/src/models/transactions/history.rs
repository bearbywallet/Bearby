use super::base_token::BaseTokenInfo;
use zilpay::history::status::TransactionStatus;
pub use zilpay::history::transaction::HistoricalTransaction;

#[derive(Debug)]
pub enum TransactionStatusInfo {
    Pending,
    Confirmed,
    Rejected,
}

impl From<TransactionStatus> for TransactionStatusInfo {
    fn from(value: TransactionStatus) -> Self {
        match value {
            TransactionStatus::Pending => TransactionStatusInfo::Pending,
            TransactionStatus::Confirmed => TransactionStatusInfo::Confirmed,
            TransactionStatus::Rejected => TransactionStatusInfo::Rejected,
        }
    }
}

#[derive(Debug)]
pub struct HistoricalTransactionInfo {
    pub transaction_hash: String,
    pub amount: String,
    pub sender: String,
    pub recipient: String,
    pub contract_address: Option<String>,
    pub status: TransactionStatusInfo,
    pub status_code: Option<u8>,
    pub timestamp: u64,
    pub block_number: Option<u128>,
    pub gas_used: Option<u128>,
    pub gas_limit: Option<u128>,
    pub gas_price: Option<u128>,
    pub blob_gas_used: Option<u128>,
    pub blob_gas_price: Option<u128>,
    pub effective_gas_price: Option<u128>,
    pub fee: u128,
    pub icon: Option<String>,
    pub title: Option<String>,
    pub error: Option<String>,
    pub sig: String,
    pub nonce: u128,
    pub token_info: Option<BaseTokenInfo>,
    pub chain_type: String,
    pub chain_hash: u64,
}

impl From<HistoricalTransaction> for HistoricalTransactionInfo {
    fn from(value: HistoricalTransaction) -> Self {
        Self {
            sig: value.sig,
            transaction_hash: value.transaction_hash,
            amount: value.amount.to_string(),
            sender: value.sender,
            recipient: value.recipient,
            contract_address: value.contract_address,
            status: value.status.into(),
            status_code: value.status_code,
            timestamp: value.timestamp,
            block_number: value.block_number,
            gas_used: value.gas_used,
            gas_limit: value.gas_limit,
            gas_price: value.gas_price,
            blob_gas_used: value.blob_gas_used,
            blob_gas_price: value.blob_gas_price,
            effective_gas_price: value.effective_gas_price,
            fee: value.fee,
            icon: value.icon,
            title: value.title,
            error: value.error,
            nonce: value.nonce,
            token_info: value.token_info.map(|v| v.into()),
            chain_type: value.chain_type.to_string(),
            chain_hash: value.chain_hash,
        }
    }
}
