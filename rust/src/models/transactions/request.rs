pub use zilpay::config::sha::SHA256_SIZE;
pub use zilpay::errors::address::AddressError;
pub use zilpay::proto::btc_tx::BitcoinMetadata;
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

use zilpay::proto::solana_tx::SolanaTransaction;

use super::btc::BitcoinMetadataInfo;
use super::btc::TransactionBitcoin;
use super::evm::TransactionRequestEVM;
use super::scilla::TransactionRequestScilla;
use super::transaction_metadata::TransactionMetadataInfo;

#[derive(Debug, Clone)]
pub struct TransactionRequestInfo {
    pub metadata: TransactionMetadataInfo,
    pub scilla: Option<TransactionRequestScilla>,
    pub evm: Option<TransactionRequestEVM>,
    pub btc: Option<(TransactionBitcoin, BitcoinMetadataInfo)>,
    pub tron: Option<String>,
    pub solana: Option<Vec<u8>>,
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
        } else if let Some((btc_tx, btc_meta_info)) = value.btc {
            let native_tx: bitcoin::Transaction =
                btc_tx.try_into().map_err(|e: TransactionErrors| e)?;
            let btc_meta: BitcoinMetadata = btc_meta_info.try_into()?;
            let tx_req = TransactionRequest::Bitcoin((native_tx, value.metadata.into(), btc_meta));
            Ok(tx_req)
        } else if let Some(tron_str) = value.tron {
            let sign_req_tron = serde_json::from_str::<TronWebTransaction>(&tron_str)
                .map_err(|e| TransactionErrors::ConvertTxError(e.to_string()))?;
            let req_tron_tx = TronTransaction::from_tron_web(&sign_req_tron)?;
            let tx_req = TransactionRequest::Tron((req_tron_tx, value.metadata.into()));
            Ok(tx_req)
        } else if let Some(solana_msg) = value.solana {
            let tx_req = TransactionRequest::Solana((
                SolanaTransaction {
                    message: solana_msg,
                },
                value.metadata.into(),
            ));
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
            TransactionRequest::Bitcoin((_, ref metadata, _)) => metadata.to_owned().into(),
            TransactionRequest::Tron((_, ref metadata)) => metadata.to_owned().into(),
            TransactionRequest::Solana((_, ref metadata)) => metadata.to_owned().into(),
        };

        match value {
            TransactionRequest::Zilliqa((tx, _)) => Self {
                metadata,
                scilla: Some(tx.into()),
                evm: None,
                btc: None,
                tron: None,
                solana: None,
            },
            TransactionRequest::Ethereum((tx, _)) => Self {
                metadata,
                scilla: None,
                evm: Some(tx.into()),
                btc: None,
                tron: None,
                solana: None,
            },
            TransactionRequest::Bitcoin((tx, ref req_meta, btc_meta)) => {
                let network = req_meta
                    .signer
                    .as_ref()
                    .and_then(|s| s.get_bitcoin_network().ok())
                    .unwrap_or(bitcoin::Network::Bitcoin);
                let btc_meta_info: BitcoinMetadataInfo = btc_meta.into();
                let tx_info = TransactionBitcoin::from_tx_with_utxos(
                    tx,
                    &btc_meta_info.witness_utxos,
                    network,
                );
                Self {
                    metadata,
                    scilla: None,
                    evm: None,
                    btc: Some((tx_info, btc_meta_info)),
                    tron: None,
                    solana: None,
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
                    solana: None,
                }
            }
            TransactionRequest::Solana((tx, _)) => Self {
                metadata,
                scilla: None,
                evm: None,
                btc: None,
                tron: None,
                solana: Some(tx.message),
            },
        }
    }
}
