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
use super::tron::TransactionRequestTron;

#[derive(Debug, Clone)]
pub struct TransactionRequestInfo {
    pub metadata: TransactionMetadataInfo,
    pub scilla: Option<TransactionRequestScilla>,
    pub evm: Option<TransactionRequestEVM>,
    pub btc: Option<(TransactionBitcoin, BitcoinMetadataInfo)>,
    pub tron: Option<TransactionRequestTron>,
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
            let native_tx: zilpay::bitcoin::Transaction =
                btc_tx.try_into().map_err(|e: TransactionErrors| e)?;
            let btc_meta: BitcoinMetadata = btc_meta_info.try_into()?;
            let tx_req = TransactionRequest::Bitcoin((native_tx, value.metadata.into(), btc_meta));
            Ok(tx_req)
        } else if let Some(tron_info) = value.tron {
            let tron_web: TronWebTransaction = tron_info.try_into()?;
            let req_tron_tx = TronTransaction::from_tron_web(&tron_web)?;
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

impl TryFrom<TransactionRequest> for TransactionRequestInfo {
    type Error = TransactionErrors;

    fn try_from(value: TransactionRequest) -> Result<Self, Self::Error> {
        match value {
            TransactionRequest::Zilliqa((tx, metadata)) => Ok(Self {
                metadata: metadata.into(),
                scilla: Some(tx.into()),
                evm: None,
                btc: None,
                tron: None,
                solana: None,
            }),
            TransactionRequest::Ethereum((tx, metadata)) => Ok(Self {
                metadata: metadata.into(),
                scilla: None,
                evm: Some(tx.into()),
                btc: None,
                tron: None,
                solana: None,
            }),
            TransactionRequest::Bitcoin((tx, req_meta, btc_meta)) => {
                let network = req_meta
                    .signer
                    .as_ref()
                    .and_then(|signer| signer.get_bitcoin_network().ok())
                    .unwrap_or(zilpay::bitcoin::Network::Bitcoin);
                let btc_meta_info: BitcoinMetadataInfo = btc_meta.into();
                let tx_info = TransactionBitcoin::from_tx_with_utxos(
                    tx,
                    &btc_meta_info.witness_utxos,
                    network,
                );
                Ok(Self {
                    metadata: req_meta.into(),
                    scilla: None,
                    evm: None,
                    btc: Some((tx_info, btc_meta_info)),
                    tron: None,
                    solana: None,
                })
            }
            TransactionRequest::Tron((tx, metadata)) => {
                let tron_web = tx.to_tron_web()?;
                Ok(Self {
                    metadata: metadata.into(),
                    scilla: None,
                    evm: None,
                    btc: None,
                    tron: Some(TransactionRequestTron::from(tron_web)),
                    solana: None,
                })
            }
            TransactionRequest::Solana((tx, metadata)) => Ok(Self {
                metadata: metadata.into(),
                scilla: None,
                evm: None,
                btc: None,
                tron: None,
                solana: Some(tx.message),
            }),
        }
    }
}
