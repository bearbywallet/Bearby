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

use super::evm::TransactionRequestEVM;
use super::scilla::TransactionRequestScilla;
use super::transaction_metadata::TransactionMetadataInfo;

#[derive(Debug, Clone)]
pub struct TransactionRequestInfo {
    pub metadata: TransactionMetadataInfo,
    pub scilla: Option<TransactionRequestScilla>,
    pub evm: Option<TransactionRequestEVM>,
}

impl TryFrom<TransactionRequestInfo> for TransactionRequest {
    type Error = TransactionErrors;

    fn try_from(value: TransactionRequestInfo) -> Result<Self, Self::Error> {
        if let Some(scilla_tx) = value.scilla {
            let tx_req =
                TransactionRequest::Zilliqa((scilla_tx.try_into()?, value.metadata.into()));
            Ok(tx_req)
        } else if let Some(evm_tx) = value.evm {
            let tx_req = TransactionRequest::Ethereum((evm_tx.try_into()?, value.metadata.into()));
            Ok(tx_req)
        } else {
            Err(TransactionErrors::InvalidTxHash)
        }
    }
}

impl From<TransactionRequest> for TransactionRequestInfo {
    fn from(value: TransactionRequest) -> Self {
        let metadata: TransactionMetadataInfo = match value {
            TransactionRequest::Zilliqa((_, ref metadata)) => metadata.to_owned().into(),
            TransactionRequest::Ethereum((_, ref metadata)) => metadata.to_owned().into(),
        };

        match value {
            TransactionRequest::Zilliqa((tx, _)) => Self {
                metadata,
                scilla: Some(tx.into()),
                evm: None,
            },
            TransactionRequest::Ethereum((tx, _)) => Self {
                metadata,
                scilla: None,
                evm: Some(tx.into()),
            },
        }
    }
}
