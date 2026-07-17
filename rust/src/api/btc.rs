//! WalletConnect bip122 (Bitcoin) helpers: PSBT ⇄ request bridge and BIP-137 signMessage.

use std::collections::HashMap;

use flutter_rust_bridge::frb;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_wallet::WalletManagement;
use zilpay::base64::Engine;
use zilpay::bitcoin::psbt::Psbt;
use zilpay::bitcoin::secp256k1::SecretKey;
use zilpay::bitcoin::{Amount, ScriptBuf, Transaction as BitcoinTransaction, TxOut, Witness};
use zilpay::crypto::bip49::DerivationPath;
use zilpay::proto::btc_msg::{bip137_message_hash_hex, sign_message_bip137};
use zilpay::proto::btc_tx::{build_psbt, BitcoinMetadata};
use zilpay::proto::btc_utils::ByteCodec;
use zilpay::proto::tx::{TransactionMetadata, TransactionRequest};
use zilpay::proto::U256;
use zilpay::secrecy::SecretString;
use zilpay::wallet::bitcoin_wallet::BitcoinWallet;
use zilpay::wallet::wallet_crypto::WalletCrypto;
use zilpay::wallet::wallet_storage::StorageOperations;
use zilpay::wallet::wallet_types::WalletTypes;

use crate::api::transaction::unlock_seed;
use crate::models::transactions::btc::{TransactionBitcoin, TxOutInfo};
use crate::models::transactions::request::TransactionRequestInfo;
use crate::utils::errors::ServiceError;
use crate::utils::helpers::{handle, script_to_address};

/// One entry from WalletConnect `signPsbt.signInputs[]`.
#[derive(Debug, Clone)]
pub struct WcSignInputInfo {
    pub address: String,
    pub index: u32,
    pub sighash_types: Option<Vec<u32>>,
}

/// BIP-137 signMessage result for bip122.
#[derive(Debug, Clone)]
pub struct BtcSignedMessageInfo {
    pub address: String,
    pub signature_base64: String,
    pub message_hash_hex: String,
}

/// Reject non-default sighash types (v1: only SIGHASH_ALL = 1).
fn validate_sighash_types(sign_inputs: &[WcSignInputInfo]) -> Result<(), String> {
    for input in sign_inputs {
        if let Some(types) = &input.sighash_types {
            if types.iter().any(|t| *t != 1) {
                return Err("only SIGHASH_ALL is supported".to_string());
            }
        }
    }
    Ok(())
}

/// Parse a dApp PSBT (base64) into Bearby's typed request so the standard
/// confirm-modal → `sign_send_transactions` pipeline can sign/broadcast it.
///
/// Resolves each input's `(addr_type, derivation_path)` by matching the input
/// address against the wallet's BTC address chains; errors if any `signInputs`
/// entry is not a wallet address or requests a non-default sighash.
///
/// **v1 limitation:** every PSBT input must be wallet-owned (core signs the
/// whole tx via multi-input metadata). Mixed-party PSBTs (counterparty inputs
/// in swaps/coinjoins) are rejected. Spec-level partial signing is future work.
pub async fn btc_psbt_to_request(
    wallet_index: usize,
    account_index: usize,
    psbt_base64: String,
    sign_inputs: Vec<WcSignInputInfo>,
    broadcast: bool,
    title: Option<String>,
    icon: Option<String>,
) -> Result<TransactionRequestInfo, String> {
    validate_sighash_types(&sign_inputs)?;

    let psbt_bytes = zilpay::base64::engine::general_purpose::STANDARD
        .decode(psbt_base64.trim())
        .map_err(|e| format!("invalid psbt base64: {e}"))?;
    let psbt: Psbt =
        Psbt::deserialize(&psbt_bytes).map_err(|e| format!("invalid psbt: {e}"))?;

    let core = handle()?;
    let wallet = core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let wallet_data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let account = wallet_data
        .get_account(account_index)
        .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))?;
    let network = account
        .addr
        .get_bitcoin_network()
        .map_err(ServiceError::from)?;
    let chains = wallet
        .get_btc_addresses(account_index, wallet_data.chain_hash)
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

    let addr_lookup = build_btc_address_lookup(&chains);

    // Validate every signInputs entry against wallet addresses + PSBT bounds.
    let input_count = psbt.unsigned_tx.input.len();
    for si in &sign_inputs {
        let idx = si.index as usize;
        if idx >= input_count {
            return Err(format!(
                "signInputs index {} out of bounds ({})",
                si.index, input_count
            ));
        }
        if !addr_lookup.contains_key(si.address.as_str()) {
            return Err(format!("address not owned by wallet: {}", si.address));
        }
    }

    let mut witness_utxos: Vec<TxOut> = Vec::with_capacity(input_count);
    let mut input_meta: Vec<(u8, DerivationPath)> = Vec::with_capacity(input_count);

    for (i, psbt_input) in psbt.inputs.iter().enumerate() {
        let utxo = psbt_input
            .witness_utxo
            .clone()
            .or_else(|| {
                psbt_input.non_witness_utxo.as_ref().and_then(|prev| {
                    let vout = psbt.unsigned_tx.input.get(i)?.previous_output.vout as usize;
                    prev.output.get(vout).cloned()
                })
            })
            .ok_or_else(|| format!("missing witness_utxo for input {i}"))?;

        let addr_str = script_to_address(utxo.script_pubkey.as_bytes(), network)
            .ok_or_else(|| format!("cannot derive address for input {i}"))?;
        let (addr_type_byte, path) = addr_lookup.get(addr_str.as_str()).cloned().ok_or_else(|| {
            format!("PSBT input {i} address {addr_str} is not owned by the wallet")
        })?;

        witness_utxos.push(utxo);
        input_meta.push((addr_type_byte, path));
    }

    let unsigned_tx = psbt.unsigned_tx.clone();
    let output_sum: u64 = unsigned_tx.output.iter().map(|o| o.value.to_sat()).sum();

    // Prefer explicit recipient outputs (non-wallet) for the confirm modal amount.
    let mut outgoing: u64 = 0;
    for out in &unsigned_tx.output {
        let out_addr = script_to_address(out.script_pubkey.as_bytes(), network);
        let is_ours = out_addr
            .as_deref()
            .map(|a| addr_lookup.contains_key(a))
            .unwrap_or(false);
        if !is_ours {
            outgoing = outgoing.saturating_add(out.value.to_sat());
        }
    }
    if outgoing == 0 {
        // Self-send / consolidation: show total outputs as value.
        outgoing = output_sum;
    }

    let native_symbol = core
        .get_provider(wallet_data.chain_hash)
        .ok()
        .and_then(|p| {
            p.config
                .ftokens
                .iter()
                .find(|t| t.native)
                .map(|t| t.symbol.clone())
        })
        .unwrap_or_else(|| "BTC".to_string());

    let metadata = TransactionMetadata {
        chain_hash: wallet_data.chain_hash,
        hash: None,
        info: None,
        icon,
        title,
        signer: Some(account.addr.clone()),
        token_info: Some((U256::from(outgoing), 8, native_symbol)),
        broadcast,
    };

    let btc_meta = BitcoinMetadata {
        witness_utxos,
        input_meta,
    };

    let req = TransactionRequest::Bitcoin((unsigned_tx, metadata, btc_meta));
    req.try_into()
        .map_err(|e: zilpay::errors::tx::TransactionErrors| e.to_string())
}

/// Signed tx → finalized PSBT (base64). Rebuilds the PSBT from the unsigned
/// skeleton and moves each input's script_sig/witness into
/// `final_script_sig` / `final_script_witness`.
#[frb(sync)]
pub fn btc_finalized_psbt_from_signed(
    tx: TransactionBitcoin,
    witness_utxos: Vec<TxOutInfo>,
) -> Result<String, String> {
    let native_tx: BitcoinTransaction = tx
        .try_into()
        .map_err(|e| format!("Failed to convert transaction: {e:?}"))?;

    if native_tx.input.len() != witness_utxos.len() {
        return Err(format!(
            "witness_utxos length {} does not match input count {}",
            witness_utxos.len(),
            native_tx.input.len()
        ));
    }

    // Preserve final scripts before stripping for from_unsigned_tx.
    let finals: Vec<(ScriptBuf, Witness)> = native_tx
        .input
        .iter()
        .map(|i| (i.script_sig.clone(), i.witness.clone()))
        .collect();

    let mut unsigned = native_tx;
    for input in &mut unsigned.input {
        input.script_sig = ScriptBuf::new();
        input.witness = Witness::new();
    }

    let native_utxos: Vec<TxOut> = witness_utxos
        .into_iter()
        .map(|utxo| TxOut {
            value: Amount::from_sat(utxo.value),
            script_pubkey: ScriptBuf::from(utxo.script_pubkey),
        })
        .collect();

    let mut psbt = build_psbt(unsigned, &native_utxos)
        .map_err(|e| format!("Failed to build PSBT: {e:?}"))?;

    for (i, (script_sig, witness)) in finals.into_iter().enumerate() {
        if i >= psbt.inputs.len() {
            break;
        }
        let input = &mut psbt.inputs[i];
        if !script_sig.is_empty() {
            input.final_script_sig = Some(script_sig);
        }
        if !witness.is_empty() {
            input.final_script_witness = Some(witness);
        }
    }

    let bytes = psbt.serialize();
    Ok(zilpay::base64::engine::general_purpose::STANDARD.encode(bytes))
}

/// BIP-137 ecdsa `signMessage` for an address belonging to the given account.
///
/// **v1:** does not write to transaction history (unlike `sign_message` /
/// EIP-712). Sub-address signing is the priority path for WalletConnect.
pub async fn btc_sign_message_bip137(
    wallet_index: usize,
    account_index: usize,
    password: Option<String>,
    passphrase: Option<String>,
    address: String,
    message: String,
) -> Result<BtcSignedMessageInfo, String> {
    let core = handle()?;
    let seed = unlock_seed(&core, wallet_index, password).await?;
    let secret_passphrase = SecretString::new(passphrase.unwrap_or_default().into());

    let wallet = core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let wallet_data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    wallet_data
        .get_account(account_index)
        .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))?;

    let chains = wallet
        .get_btc_addresses(account_index, wallet_data.chain_hash)
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let addr_lookup = build_btc_address_lookup(&chains);

    let (addr_type_byte, path) = addr_lookup
        .get(address.as_str())
        .cloned()
        .ok_or_else(|| format!("address not owned by wallet: {address}"))?;
    let addr_type = zilpay::bitcoin::AddressType::from_byte(addr_type_byte)
        .map_err(|e| format!("invalid address type: {e}"))?;

    let secret_key = match &wallet_data.wallet_type {
        WalletTypes::SecretPhrase(_) => {
            let mnemonic = wallet
                .reveal_mnemonic(&seed)
                .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
            let seed_secret = mnemonic
                .to_seed(&secret_passphrase)
                .map_err(|e| format!("bip39 seed: {e:?}"))?;
            let sk = zilpay::proto::bip32::derive_private_key(&seed_secret, &path.get_path())
                .map_err(|e| format!("derive key: {e:?}"))?;
            SecretKey::from_slice(&sk.to_bytes()).map_err(|e| format!("invalid secret key: {e}"))?
        }
        WalletTypes::SecretKey => {
            let keypair = wallet
                .reveal_keypair(account_index, &seed, &secret_passphrase)
                .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
            let sk_bytes = keypair.get_sk_bytes();
            SecretKey::from_slice(&sk_bytes).map_err(|e| format!("invalid secret key: {e}"))?
        }
        _ => return Err("wallet type cannot sign BTC messages".to_string()),
    };

    let signature_base64 = sign_message_bip137(&secret_key, message.as_bytes(), addr_type)
        .map_err(|e| format!("bip137 sign: {e}"))?;
    let message_hash_hex = bip137_message_hash_hex(&message);

    Ok(BtcSignedMessageInfo {
        address,
        signature_base64,
        message_hash_hex,
    })
}

/// Map address string → (address_type_byte, derivation path) across all BTC chains.
fn build_btc_address_lookup(
    chains: &HashMap<zilpay::bitcoin::AddressType, zilpay::proto::btc_utils::AddressChain>,
) -> HashMap<String, (u8, DerivationPath)> {
    let mut capacity = 0usize;
    for chain in chains.values() {
        capacity = capacity
            .saturating_add(chain.external.len())
            .saturating_add(chain.internal.len());
    }
    let mut map = HashMap::with_capacity(capacity);
    for (addr_type, chain) in chains {
        let byte = addr_type.to_byte();
        for entry in chain.external.iter().chain(chain.internal.iter()) {
            map.insert(entry.address.auto_format(), (byte, entry.path.clone()));
        }
    }
    map
}

#[cfg(test)]
mod tests {
    use super::*;
    use zilpay::bitcoin::absolute::LockTime;
    use zilpay::bitcoin::hashes::Hash as _;
    use zilpay::bitcoin::transaction::Version;
    use zilpay::bitcoin::{OutPoint, Sequence, TxIn, Txid};

    fn dummy_txout(value: u64) -> TxOut {
        TxOut {
            value: Amount::from_sat(value),
            // empty script — only for structure tests of finalized psbt
            script_pubkey: ScriptBuf::new(),
        }
    }

    fn sign_input(address: &str, sighash_types: Option<Vec<u32>>) -> WcSignInputInfo {
        WcSignInputInfo {
            address: address.into(),
            index: 0,
            sighash_types,
        }
    }

    #[test]
    fn finalized_psbt_roundtrip_preserves_witness() {
        let witness = Witness::from_slice(&[vec![0x30, 0x44], vec![0x02, 0x21]]);
        let script_sig = ScriptBuf::new();
        let txid = Txid::from_byte_array([1u8; 32]);
        let signed = BitcoinTransaction {
            version: Version(2),
            lock_time: LockTime::ZERO,
            input: vec![TxIn {
                previous_output: OutPoint { txid, vout: 0 },
                script_sig: script_sig.clone(),
                sequence: Sequence::MAX,
                witness: witness.clone(),
            }],
            output: vec![dummy_txout(1000)],
        };

        let tx_info = TransactionBitcoin::from(signed);
        let utxos = vec![TxOutInfo {
            value: 2000,
            script_pubkey: vec![],
            address: None,
        }];

        let b64 = btc_finalized_psbt_from_signed(tx_info, utxos).expect("psbt");
        let bytes = zilpay::base64::engine::general_purpose::STANDARD
            .decode(&b64)
            .expect("b64");
        let psbt = Psbt::deserialize(&bytes).expect("deserialize");
        assert_eq!(psbt.inputs.len(), 1);
        assert_eq!(
            psbt.inputs[0]
                .final_script_witness
                .as_ref()
                .map(|w| w.to_vec()),
            Some(witness.to_vec())
        );
    }

    #[test]
    fn sighash_non_all_is_rejected() {
        assert!(validate_sighash_types(&[sign_input("bc1qtest", Some(vec![3]))]).is_err());
        assert!(validate_sighash_types(&[sign_input("bc1qtest", Some(vec![1]))]).is_ok());
        assert!(validate_sighash_types(&[sign_input("bc1qtest", None)]).is_ok());
        assert!(validate_sighash_types(&[sign_input("bc1qtest", Some(vec![]))]).is_ok());
        assert!(validate_sighash_types(&[sign_input(
            "bc1qtest",
            Some(vec![1, 3])
        )])
        .is_err());
    }
}
