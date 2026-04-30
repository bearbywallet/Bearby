use std::str::FromStr;

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
}

#[derive(Debug, Clone)]
pub struct TxOutInfo {
    pub value: u64,
    pub script_pubkey: Vec<u8>,
}

#[derive(Debug, Clone)]
pub struct TransactionRequestBitcoin {
    pub version: i32,
    pub lock_time: u32,
    pub input: Vec<TxInInfo>,
    pub output: Vec<TxOutInfo>,
}

impl From<bitcoin::Transaction> for TransactionRequestBitcoin {
    fn from(tx: bitcoin::Transaction) -> Self {
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
                })
                .collect(),
            output: tx
                .output
                .into_iter()
                .map(|tx_out| TxOutInfo {
                    value: tx_out.value.to_sat(),
                    script_pubkey: tx_out.script_pubkey.into_bytes(),
                })
                .collect(),
        }
    }
}

impl TryFrom<TransactionRequestBitcoin> for bitcoin::Transaction {
    type Error = TransactionErrors;

    fn try_from(value: TransactionRequestBitcoin) -> Result<Self, Self::Error> {
        let input = value
            .input
            .into_iter()
            .map(|tx_in| {
                let txid = bitcoin::Txid::from_str(&tx_in.previous_output.txid)
                    .map_err(|e| TransactionErrors::ConvertTxError(e.to_string()))?;
                Ok(bitcoin::TxIn {
                    previous_output: bitcoin::OutPoint {
                        txid,
                        vout: tx_in.previous_output.vout,
                    },
                    script_sig: bitcoin::ScriptBuf::from(tx_in.script_sig),
                    sequence: bitcoin::Sequence(tx_in.sequence),
                    witness: bitcoin::Witness::from_slice(&tx_in.witness),
                })
            })
            .collect::<Result<Vec<_>, TransactionErrors>>()?;

        let output = value
            .output
            .into_iter()
            .map(|tx_out| bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(tx_out.value),
                script_pubkey: bitcoin::ScriptBuf::from(tx_out.script_pubkey),
            })
            .collect();

        Ok(bitcoin::Transaction {
            version: bitcoin::transaction::Version(value.version),
            lock_time: bitcoin::absolute::LockTime::from_consensus(value.lock_time),
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
            .map(|tx_out| bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(tx_out.value),
                script_pubkey: bitcoin::ScriptBuf::from(tx_out.script_pubkey),
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
