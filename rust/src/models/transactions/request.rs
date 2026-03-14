pub use zilpay::config::sha::SHA256_SIZE;
pub use zilpay::errors::address::AddressError;
pub use zilpay::proto::tron_tx::TronTransaction;
use zilpay::proto::tron_tx::TronWebTransaction;
pub use zilpay::proto::tx::{BTCTransactionRequest, TransactionMetadata, TransactionRequest};
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

extern crate bitcoin;

#[derive(Debug, Clone)]
pub struct TransactionRequestInfo {
    pub metadata: TransactionMetadataInfo,
    pub scilla: Option<TransactionRequestScilla>,
    pub evm: Option<TransactionRequestEVM>,
    pub btc: Option<String>,
    pub tron: Option<String>,
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
        } else if let Some(btc_hex) = value.btc {
            let bytes = hex::decode(btc_hex).map_err(|_| TransactionErrors::InvalidTxHash)?;
            let btc_tx = bitcoin::consensus::encode::deserialize(&bytes)
                .map_err(|_| TransactionErrors::InvalidTxHash)?;
            let tx_req = TransactionRequest::Bitcoin((btc_tx, value.metadata.into()));
            Ok(tx_req)
        } else if let Some(tron_str) = value.tron {
            let sign_req_tron = serde_json::from_str::<TronWebTransaction>(&tron_str)
                .map_err(|e| TransactionErrors::ConvertTxError(e.to_string()))?;
            let req_tron_tx = TronTransaction::from_tron_web(&sign_req_tron)?;
            let tx_req = TransactionRequest::Tron((req_tron_tx, value.metadata.into()));
            Ok(tx_req)
        } else {
            Err(TransactionErrors::InvalidTransaction)
        }
    }
}

impl From<TransactionRequest> for TransactionRequestInfo {
    fn from(value: TransactionRequest) -> Self {
        let metadata: TransactionMetadataInfo = match value {
            TransactionRequest::Zilliqa((_, ref metadata)) => metadata.to_owned().into(),
            TransactionRequest::Ethereum((_, ref metadata)) => metadata.to_owned().into(),
            TransactionRequest::Bitcoin((_, ref metadata)) => metadata.to_owned().into(),
            TransactionRequest::Tron((_, ref metadata)) => metadata.to_owned().into(),
        };

        match value {
            TransactionRequest::Zilliqa((tx, _)) => Self {
                metadata,
                scilla: Some(tx.into()),
                evm: None,
                btc: None,
                tron: None,
            },
            TransactionRequest::Ethereum((tx, _)) => Self {
                metadata,
                scilla: None,
                evm: Some(tx.into()),
                btc: None,
                tron: None,
            },
            TransactionRequest::Bitcoin((tx, _)) => {
                let bytes = bitcoin::consensus::encode::serialize(&tx);
                let hex = hex::encode(bytes);
                Self {
                    metadata,
                    scilla: None,
                    evm: None,
                    btc: Some(hex),
                    tron: None,
                }
            }
            TransactionRequest::Tron((tx, _)) => {
                // TODO: must be fixed!
                let tron_web = tx.to_tron_web().unwrap();
                let json = serde_json::to_string(&tron_web).unwrap_or_default();

                Self {
                    metadata,
                    scilla: None,
                    evm: None,
                    btc: None,
                    tron: Some(json),
                }
            }
        }
    }
}
