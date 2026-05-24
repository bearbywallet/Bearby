use std::str::FromStr;

use crate::utils::helpers::script_to_address;
pub use zilpay::crypto::bip49::DerivationPath;
pub use zilpay::errors::tx::TransactionErrors;
pub use zilpay::proto::btc_tx::BitcoinMetadata;

#[derive(Debug, Clone)]
pub struct OutPointInfo {
    pub txid: String,
    pub vout: u32,
}

#[derive(Debug, Clone)]
pub struct TxInInfo {
    pub previous_output: OutPointInfo,
    pub script_sig: Vec<u8>,
    pub sequence: u32,
    pub witness: Vec<Vec<u8>>,
    pub address: Option<String>,
}

#[derive(Debug, Clone)]
pub struct TxOutInfo {
    pub value: u64,
    pub script_pubkey: Vec<u8>,
    pub address: Option<String>,
}

#[derive(Debug, Clone)]
pub struct TransactionBitcoin {
    pub version: i32,
    pub lock_time: u32,
    pub input: Vec<TxInInfo>,
    pub output: Vec<TxOutInfo>,
    pub fee: Option<u64>,
}

impl TransactionBitcoin {
    pub fn from_tx_with_utxos(
        tx: zilpay::bitcoin::Transaction,
        witness_utxos: &[TxOutInfo],
        network: zilpay::bitcoin::Network,
    ) -> Self {
        let input_sum: u64 = witness_utxos.iter().map(|u| u.value).sum();
        let output_sum: u64 = tx.output.iter().map(|o| o.value.to_sat()).sum();
        let mut btc_tx = TransactionBitcoin::from(tx);
        btc_tx.fee = input_sum.checked_sub(output_sum);

        for tx_out in &mut btc_tx.output {
            tx_out.address = script_to_address(&tx_out.script_pubkey, network);
        }

        for (tx_in, utxo) in btc_tx.input.iter_mut().zip(witness_utxos.iter()) {
            tx_in.address = script_to_address(&utxo.script_pubkey, network);
        }

        btc_tx
    }
}

impl From<zilpay::bitcoin::Transaction> for TransactionBitcoin {
    fn from(tx: zilpay::bitcoin::Transaction) -> Self {
        Self {
            version: tx.version.0,
            lock_time: tx.lock_time.to_consensus_u32(),
            input: tx
                .input
                .into_iter()
                .map(|tx_in| TxInInfo {
                    previous_output: OutPointInfo {
                        txid: tx_in.previous_output.txid.to_string(),
                        vout: tx_in.previous_output.vout,
                    },
                    script_sig: tx_in.script_sig.into_bytes(),
                    sequence: tx_in.sequence.0,
                    witness: tx_in.witness.to_vec(),
                    address: None,
                })
                .collect(),
            output: tx
                .output
                .into_iter()
                .map(|tx_out| TxOutInfo {
                    value: tx_out.value.to_sat(),
                    script_pubkey: tx_out.script_pubkey.into_bytes(),
                    address: None,
                })
                .collect(),
            fee: None,
        }
    }
}

impl TryFrom<TransactionBitcoin> for zilpay::bitcoin::Transaction {
    type Error = TransactionErrors;

    fn try_from(value: TransactionBitcoin) -> Result<Self, Self::Error> {
        let input = value
            .input
            .into_iter()
            .map(|tx_in| {
                let txid = zilpay::bitcoin::Txid::from_str(&tx_in.previous_output.txid)
                    .map_err(|e| TransactionErrors::ConvertTxError(e.to_string()))?;
                Ok(zilpay::bitcoin::TxIn {
                    previous_output: zilpay::bitcoin::OutPoint {
                        txid,
                        vout: tx_in.previous_output.vout,
                    },
                    script_sig: zilpay::bitcoin::ScriptBuf::from(tx_in.script_sig),
                    sequence: zilpay::bitcoin::Sequence(tx_in.sequence),
                    witness: zilpay::bitcoin::Witness::from_slice(&tx_in.witness),
                })
            })
            .collect::<Result<Vec<_>, TransactionErrors>>()?;

        let output = value
            .output
            .into_iter()
            .map(|tx_out| zilpay::bitcoin::TxOut {
                value: zilpay::bitcoin::Amount::from_sat(tx_out.value),
                script_pubkey: zilpay::bitcoin::ScriptBuf::from(tx_out.script_pubkey),
            })
            .collect();

        Ok(zilpay::bitcoin::Transaction {
            version: zilpay::bitcoin::transaction::Version(value.version),
            lock_time: zilpay::bitcoin::absolute::LockTime::from_consensus(value.lock_time),
            input,
            output,
        })
    }
}

#[derive(Debug, Clone)]
pub struct InputMetaInfo {
    pub address_type: u8,
    pub derivation_path: String,
}

#[derive(Debug, Clone)]
pub struct BitcoinMetadataInfo {
    pub witness_utxos: Vec<TxOutInfo>,
    pub input_meta: Vec<InputMetaInfo>,
}

impl From<BitcoinMetadata> for BitcoinMetadataInfo {
    fn from(value: BitcoinMetadata) -> Self {
        Self {
            witness_utxos: value
                .witness_utxos
                .into_iter()
                .map(|tx_out| TxOutInfo {
                    value: tx_out.value.to_sat(),
                    script_pubkey: tx_out.script_pubkey.into_bytes(),
                    address: None,
                })
                .collect(),
            input_meta: value
                .input_meta
                .into_iter()
                .map(|(addr_type, path)| InputMetaInfo {
                    address_type: addr_type,
                    derivation_path: path.to_string(),
                })
                .collect(),
        }
    }
}

impl TryFrom<BitcoinMetadataInfo> for BitcoinMetadata {
    type Error = TransactionErrors;

    fn try_from(value: BitcoinMetadataInfo) -> Result<Self, Self::Error> {
        let witness_utxos = value
            .witness_utxos
            .into_iter()
            .map(|tx_out| zilpay::bitcoin::TxOut {
                value: zilpay::bitcoin::Amount::from_sat(tx_out.value),
                script_pubkey: zilpay::bitcoin::ScriptBuf::from(tx_out.script_pubkey),
            })
            .collect();

        let input_meta = value
            .input_meta
            .into_iter()
            .map(|meta| {
                let path = DerivationPath::try_from(meta.derivation_path.as_str())
                    .map_err(|e| TransactionErrors::ConvertTxError(e.to_string()))?;
                Ok((meta.address_type, path))
            })
            .collect::<Result<Vec<_>, TransactionErrors>>()?;

        Ok(BitcoinMetadata {
            witness_utxos,
            input_meta,
        })
    }
}
