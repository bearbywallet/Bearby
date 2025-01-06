pub use zilpay::config::sha::SHA256_SIZE;
pub use zilpay::proto::tx::{TransactionMetadata, TransactionRequest};
pub use zilpay::proto::U256;
pub use zilpay::proto::{address::Address, pubkey::PubKey};
pub use zilpay::proto::{
    AlloyAccessList, AlloyAccessListItem, AlloyAddress, AlloyBytes, AlloyTxKind,
};
pub use zilpay::zil_errors::address::AddressError;
pub use zilpay::{
    proto::{tx::ETHTransactionRequest, zil_tx::ZILTransactionRequest},
    zil_errors::tx::TransactionErrors,
};

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

impl TryFrom<TransactionRequestScilla> for ZILTransactionRequest {
    type Error = AddressError;

    fn try_from(value: TransactionRequestScilla) -> Result<Self, Self::Error> {
        Ok(Self {
            chain_id: value.chain_id,
            nonce: value.nonce,
            gas_price: value.gas_price,
            gas_limit: value.gas_limit,
            to_addr: Address::from_str_hex(&value.to_addr)?,
            amount: value.amount,
            code: value.code.into_bytes(),
            data: value.data.into_bytes(),
        })
    }
}
