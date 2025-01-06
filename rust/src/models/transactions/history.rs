use super::base_token::BaseTokenInfo;
use zilpay::history::status::TransactionStatus;
pub use zilpay::history::transaction::HistoricalTransaction;

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

pub struct HistoricalTransactionInfo {
    pub id: String,
    pub amount: String,
    pub sender: String,
    pub recipient: String,
    pub teg: Option<String>,
    pub status: TransactionStatusInfo,
    pub confirmed: Option<u128>,
    pub timestamp: u64,
    pub fee: u128,
    pub icon: Option<String>,
    pub title: Option<String>,
    pub nonce: u64,
    pub token_info: Option<BaseTokenInfo>,
}

impl From<HistoricalTransaction> for HistoricalTransactionInfo {
    fn from(value: HistoricalTransaction) -> Self {
        Self {
            id: value.id,
            amount: value.amount.to_string(),
            sender: value.sender,
            recipient: value.recipient,
            teg: value.teg,
            status: value.status.into(),
            confirmed: value.confirmed,
            timestamp: value.timestamp,
            fee: value.fee,
            icon: value.icon,
            title: value.title,
            nonce: value.nonce,
            token_info: value.token_info.map(|v| v.into()),
        }
    }
}
