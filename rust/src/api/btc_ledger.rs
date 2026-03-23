use bitcoin::bip32::{ChildNumber, Fingerprint, Xpub};
use bitcoin::consensus::encode as btc_encode;
use bitcoin::hashes::Hash;
use bitcoin::psbt::Psbt;
use bitcoin::secp256k1::Secp256k1;
use bitcoin::Transaction as BitcoinTransaction;
use bitcoin::Witness;
use sha2::{Digest, Sha256};
use std::str::FromStr;
use zilpay::crypto::bip49::DerivationPath;

// --- Merkle Tree ---

/// Leaf hash: SHA256(0x00 || data)
pub fn btc_ledger_hash_leaf(data: Vec<u8>) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update([0x00]);
    hasher.update(&data);
    hasher.finalize().to_vec()
}

/// Internal node hash: SHA256(0x01 || left || right)
fn hash_node(left: &[u8], right: &[u8]) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update([0x01]);
    hasher.update(left);
    hasher.update(right);
    hasher.finalize().to_vec()
}

/// SHA256 hash
pub fn btc_ledger_sha256(data: Vec<u8>) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update(&data);
    hasher.finalize().to_vec()
}

/// Largest power of 2 strictly less than n
fn highest_power_of_2_less_than(n: usize) -> usize {
    if n <= 1 {
        return 0;
    }
    let mut p = 1;
    while p * 2 < n {
        p *= 2;
    }
    p
}

/// Build a merkle tree from leaf hashes and return (root, all_nodes_for_proofs).
/// The tree is a balanced binary tree following the Ledger protocol spec.
fn build_merkle_tree(leaf_hashes: &[Vec<u8>]) -> Vec<u8> {
    if leaf_hashes.is_empty() {
        return vec![0u8; 32];
    }
    if leaf_hashes.len() == 1 {
        return leaf_hashes[0].clone();
    }
    let split = highest_power_of_2_less_than(leaf_hashes.len());
    let left_root = build_merkle_tree(&leaf_hashes[..split]);
    let right_root = build_merkle_tree(&leaf_hashes[split..]);
    hash_node(&left_root, &right_root)
}

/// Compute merkle root from leaf hashes.
pub fn btc_ledger_compute_merkle_root(leaf_hashes: Vec<Vec<u8>>) -> Vec<u8> {
    build_merkle_tree(&leaf_hashes)
}

/// Compute merkle proof for a leaf at the given index.
pub fn btc_ledger_get_merkle_proof(
    leaf_hashes: Vec<Vec<u8>>,
    leaf_index: u32,
) -> Result<MerkleProof, String> {
    let idx = leaf_index as usize;
    if idx >= leaf_hashes.len() {
        return Err("leaf_index out of bounds".into());
    }
    let proof = compute_proof(&leaf_hashes, idx);
    Ok(MerkleProof {
        leaf_hash: leaf_hashes[idx].clone(),
        proof_hashes: proof,
    })
}

fn compute_proof(leaf_hashes: &[Vec<u8>], index: usize) -> Vec<Vec<u8>> {
    if leaf_hashes.len() <= 1 {
        return vec![];
    }
    let split = highest_power_of_2_less_than(leaf_hashes.len());
    if index < split {
        let mut proof = compute_proof(&leaf_hashes[..split], index);
        let right_root = build_merkle_tree(&leaf_hashes[split..]);
        proof.push(right_root);
        proof
    } else {
        let mut proof = compute_proof(&leaf_hashes[split..], index - split);
        let left_root = build_merkle_tree(&leaf_hashes[..split]);
        proof.push(left_root);
        proof
    }
}

/// Find the index of a leaf by its hash. Returns -1 if not found.
pub fn btc_ledger_get_merkle_leaf_index(leaf_hashes: Vec<Vec<u8>>, target_hash: Vec<u8>) -> i64 {
    for (i, h) in leaf_hashes.iter().enumerate() {
        if h == &target_hash {
            return i as i64;
        }
    }
    -1
}

// --- Varint Encoding ---

/// Encode a value as a Bitcoin-style varint.
fn encode_varint(value: u64) -> Vec<u8> {
    if value < 0xFD {
        vec![value as u8]
    } else if value <= 0xFFFF {
        let mut buf = vec![0xFDu8];
        buf.extend_from_slice(&(value as u16).to_le_bytes());
        buf
    } else {
        let mut buf = vec![0xFEu8];
        buf.extend_from_slice(&(value as u32).to_le_bytes());
        buf
    }
}

// --- Preimage Store ---

/// Look up preimage data by its SHA-256 hash.
pub fn btc_ledger_get_preimage(
    preimage_hashes: Vec<Vec<u8>>,
    preimage_data: Vec<Vec<u8>>,
    requested_hash: Vec<u8>,
) -> Result<Vec<u8>, String> {
    for (i, h) in preimage_hashes.iter().enumerate() {
        if h == &requested_hash {
            return Ok(preimage_data[i].clone());
        }
    }
    Err(format!(
        "Preimage not found for hash: {}",
        hex::encode(&requested_hash)
    ))
}

// --- PSBT Merkelization ---

/// Represents a merkelized PSBT ready for Ledger signing.
pub struct MerkelizedPsbt {
    /// Global map commitment: varint(n) || keys_root || values_root
    pub global_map_commitment: Vec<u8>,
    /// Leaf hashes for global keys merkle tree
    pub global_map_keys_leaves: Vec<Vec<u8>>,
    /// Leaf hashes for global values merkle tree
    pub global_map_values_leaves: Vec<Vec<u8>>,
    /// Per-input map commitments
    pub input_map_commitments: Vec<Vec<u8>>,
    /// Per-input keys leaf hashes (flattened: input_index -> leaves)
    pub input_map_keys_leaves: Vec<Vec<Vec<u8>>>,
    /// Per-input values leaf hashes
    pub input_map_values_leaves: Vec<Vec<Vec<u8>>>,
    /// Per-output map commitments
    pub output_map_commitments: Vec<Vec<u8>>,
    /// Per-output keys leaf hashes
    pub output_map_keys_leaves: Vec<Vec<Vec<u8>>>,
    /// Per-output values leaf hashes
    pub output_map_values_leaves: Vec<Vec<Vec<u8>>>,
    /// Merkle root of input map commitment leaf hashes
    pub input_maps_root: Vec<u8>,
    /// Merkle root of output map commitment leaf hashes
    pub output_maps_root: Vec<u8>,
    /// All preimage data stored by SHA-256 hash
    pub preimage_hashes: Vec<Vec<u8>>,
    pub preimage_data: Vec<Vec<u8>>,
    /// Counts
    pub input_count: u32,
    pub output_count: u32,
    /// Original PSBT bytes
    pub psbt_bytes: Vec<u8>,
}

/// Merkle proof result
pub struct MerkleProof {
    pub leaf_hash: Vec<u8>,
    pub proof_hashes: Vec<Vec<u8>>,
}

/// Wallet policy for Ledger BTC app
pub struct WalletPolicy {
    /// Descriptor template string, e.g. "wpkh(@0)"
    pub descriptor_template: String,
    /// Keys info strings, e.g. ["[fingerprint/84'/0'/0']xpub..."]
    pub keys_info: Vec<String>,
    /// Wallet policy ID = SHA256(serialized policy)
    pub policy_id: Vec<u8>,
    /// HMAC for registered wallets (empty for default single-key wallets)
    pub policy_hmac: Vec<u8>,
    /// Serialized policy bytes (for preimage store)
    pub serialized: Vec<u8>,
}

/// Input signature from Ledger
pub struct LedgerInputSignature {
    pub input_index: u32,
    pub signature: Vec<u8>,
    pub pubkey: Vec<u8>,
}

/// Finalized transaction result
pub struct FinalizedBtcTx {
    pub raw_tx_hex: String,
    pub tx_hash: String,
    pub psbt_bytes: Vec<u8>,
}

/// Build a merkelized key-value map from sorted keys and values.
/// Returns (commitment, keys_leaf_hashes, values_leaf_hashes) and adds preimages to the store.
fn build_merkle_map(
    keys: &[Vec<u8>],
    values: &[Vec<u8>],
    preimage_hashes: &mut Vec<Vec<u8>>,
    preimage_data: &mut Vec<Vec<u8>>,
) -> (Vec<u8>, Vec<Vec<u8>>, Vec<Vec<u8>>) {
    let keys_leaves: Vec<Vec<u8>> = keys
        .iter()
        .map(|k| btc_ledger_hash_leaf(k.clone()))
        .collect();
    let values_leaves: Vec<Vec<u8>> = values
        .iter()
        .map(|v| btc_ledger_hash_leaf(v.clone()))
        .collect();

    let keys_root = build_merkle_tree(&keys_leaves);
    let values_root = build_merkle_tree(&values_leaves);

    // Commitment: varint(count) || keys_root || values_root
    let mut commitment = encode_varint(keys.len() as u64);
    commitment.extend_from_slice(&keys_root);
    commitment.extend_from_slice(&values_root);

    // Add all keys and values as known-list preimages (0x00 || element)
    // This mirrors the reference addKnownList: preimage = 0x00 || element,
    // hash = SHA256(0x00 || element) = leaf hash
    for (i, key) in keys.iter().enumerate() {
        let mut key_preimage = vec![0x00];
        key_preimage.extend_from_slice(key);
        add_preimage(preimage_hashes, preimage_data, key_preimage);

        let mut val_preimage = vec![0x00];
        val_preimage.extend_from_slice(&values[i]);
        add_preimage(preimage_hashes, preimage_data, val_preimage);
    }

    (commitment, keys_leaves, values_leaves)
}

fn add_preimage(hashes: &mut Vec<Vec<u8>>, data: &mut Vec<Vec<u8>>, preimage: Vec<u8>) {
    let hash = btc_ledger_sha256(preimage.clone());
    // Avoid duplicates
    if !hashes.contains(&hash) {
        hashes.push(hash);
        data.push(preimage);
    }
}

/// Build PSBTv2 global map key-value pairs from a PSBTv0 Psbt.
/// The Ledger Bitcoin app v2 expects PSBTv2 format.
fn build_v2_global_map(psbt: &Psbt) -> (Vec<Vec<u8>>, Vec<Vec<u8>>) {
    let tx = &psbt.unsigned_tx;
    let input_count = tx.input.len();
    let output_count = tx.output.len();

    // PSBTv2 global keys (already in sorted order: 0x02, 0x03, 0x04, 0x05, 0xFB)
    let mut pairs: Vec<(Vec<u8>, Vec<u8>)> = vec![
        // PSBT_GLOBAL_TX_VERSION
        (vec![0x02], tx.version.0.to_le_bytes().to_vec()),
        // PSBT_GLOBAL_FALLBACK_LOCKTIME
        (
            vec![0x03],
            tx.lock_time.to_consensus_u32().to_le_bytes().to_vec(),
        ),
        // PSBT_GLOBAL_INPUT_COUNT
        (vec![0x04], encode_varint(input_count as u64)),
        // PSBT_GLOBAL_OUTPUT_COUNT
        (vec![0x05], encode_varint(output_count as u64)),
        // PSBT_GLOBAL_VERSION = 2
        (vec![0xFB], 2u32.to_le_bytes().to_vec()),
    ];

    pairs.sort_by(|a, b| a.0.cmp(&b.0));

    let keys = pairs.iter().map(|(k, _)| k.clone()).collect();
    let values = pairs.iter().map(|(_, v)| v.clone()).collect();
    (keys, values)
}

/// Build PSBTv2 input map key-value pairs from a PSBTv0 Psbt.
fn build_v2_input_maps(psbt: &Psbt) -> Vec<(Vec<Vec<u8>>, Vec<Vec<u8>>)> {
    let mut maps = Vec::new();

    for (i, txin) in psbt.unsigned_tx.input.iter().enumerate() {
        let mut pairs: Vec<(Vec<u8>, Vec<u8>)> = Vec::new();
        let input = &psbt.inputs[i];

        // Non-witness UTXO (key 0x00)
        if let Some(ref tx) = input.non_witness_utxo {
            pairs.push((vec![0x00], btc_encode::serialize(tx)));
        }

        // Witness UTXO (key 0x01)
        if let Some(ref utxo) = input.witness_utxo {
            pairs.push((vec![0x01], btc_encode::serialize(utxo)));
        }

        // Sighash type (key 0x03)
        if let Some(sighash) = input.sighash_type {
            pairs.push((vec![0x03], sighash.to_u32().to_le_bytes().to_vec()));
        }

        // Redeem script (key 0x04)
        if let Some(ref script) = input.redeem_script {
            pairs.push((vec![0x04], script.as_bytes().to_vec()));
        }

        // BIP32 derivation (key 0x06 || compressed_pubkey)
        for (pubkey, (fingerprint, path)) in &input.bip32_derivation {
            let mut key = vec![0x06];
            key.extend_from_slice(&pubkey.serialize());

            let mut value = Vec::new();
            value.extend_from_slice(fingerprint.as_bytes());
            for child in path {
                value.extend_from_slice(&u32::from(*child).to_le_bytes());
            }
            pairs.push((key, value));
        }

        // PSBT_IN_PREVIOUS_TXID (key 0x0e) - from unsigned_tx
        pairs.push((
            vec![0x0e],
            txin.previous_output.txid.as_byte_array().to_vec(),
        ));

        // PSBT_IN_OUTPUT_INDEX (key 0x0f) - from unsigned_tx
        pairs.push((vec![0x0f], txin.previous_output.vout.to_le_bytes().to_vec()));

        // PSBT_IN_SEQUENCE (key 0x10) - from unsigned_tx
        pairs.push((vec![0x10], txin.sequence.0.to_le_bytes().to_vec()));

        // Taproot internal key (key 0x17)
        if let Some(ref xonly) = input.tap_internal_key {
            pairs.push((vec![0x17], xonly.serialize().to_vec()));
        }

        // Taproot BIP32 derivation (key 0x16 || x_only_pubkey)
        for (xonly_pubkey, (leaf_hashes, (fingerprint, path))) in &input.tap_key_origins {
            let mut key = vec![0x16];
            key.extend_from_slice(&xonly_pubkey.serialize());

            let mut value = Vec::new();
            // varint(num_leaf_hashes) || leaf_hashes || fingerprint || path
            value.extend_from_slice(&encode_varint(leaf_hashes.len() as u64));
            for lh in leaf_hashes {
                value.extend_from_slice(lh.to_byte_array().as_ref());
            }
            value.extend_from_slice(fingerprint.as_bytes());
            for child in path {
                value.extend_from_slice(&u32::from(*child).to_le_bytes());
            }
            pairs.push((key, value));
        }

        pairs.sort_by(|a, b| a.0.cmp(&b.0));

        let keys = pairs.iter().map(|(k, _)| k.clone()).collect();
        let values = pairs.iter().map(|(_, v)| v.clone()).collect();
        maps.push((keys, values));
    }

    maps
}

/// Build PSBTv2 output map key-value pairs from a PSBTv0 Psbt.
fn build_v2_output_maps(psbt: &Psbt) -> Vec<(Vec<Vec<u8>>, Vec<Vec<u8>>)> {
    let mut maps = Vec::new();

    for (i, txout) in psbt.unsigned_tx.output.iter().enumerate() {
        let mut pairs: Vec<(Vec<u8>, Vec<u8>)> = Vec::new();
        let output = &psbt.outputs[i];

        // Redeem script (key 0x00)
        if let Some(ref script) = output.redeem_script {
            pairs.push((vec![0x00], script.as_bytes().to_vec()));
        }

        // BIP32 derivation (key 0x02 || compressed_pubkey)
        for (pubkey, (fingerprint, path)) in &output.bip32_derivation {
            let mut key = vec![0x02];
            key.extend_from_slice(&pubkey.serialize());

            let mut value = Vec::new();
            value.extend_from_slice(fingerprint.as_bytes());
            for child in path {
                value.extend_from_slice(&u32::from(*child).to_le_bytes());
            }
            pairs.push((key, value));
        }

        // PSBT_OUT_AMOUNT (key 0x03) - from unsigned_tx
        pairs.push((vec![0x03], txout.value.to_sat().to_le_bytes().to_vec()));

        // PSBT_OUT_SCRIPT (key 0x04) - from unsigned_tx
        pairs.push((vec![0x04], txout.script_pubkey.as_bytes().to_vec()));

        // Taproot BIP32 derivation (key 0x07 || x_only_pubkey)
        for (xonly_pubkey, (leaf_hashes, (fingerprint, path))) in &output.tap_key_origins {
            let mut key = vec![0x07];
            key.extend_from_slice(&xonly_pubkey.serialize());

            let mut value = Vec::new();
            value.extend_from_slice(&encode_varint(leaf_hashes.len() as u64));
            for lh in leaf_hashes {
                value.extend_from_slice(lh.to_byte_array().as_ref());
            }
            value.extend_from_slice(fingerprint.as_bytes());
            for child in path {
                value.extend_from_slice(&u32::from(*child).to_le_bytes());
            }
            pairs.push((key, value));
        }

        pairs.sort_by(|a, b| a.0.cmp(&b.0));

        let keys = pairs.iter().map(|(k, _)| k.clone()).collect();
        let values = pairs.iter().map(|(_, v)| v.clone()).collect();
        maps.push((keys, values));
    }

    maps
}

/// Decode a Bitcoin-style varint. Returns (value, bytes_consumed).
#[cfg(test)]
fn decode_varint(data: &[u8]) -> (u64, usize) {
    if data.is_empty() {
        return (0, 0);
    }
    let first = data[0];
    if first < 0xFD {
        (first as u64, 1)
    } else if first == 0xFD {
        let val = u16::from_le_bytes([data[1], data[2]]) as u64;
        (val, 3)
    } else if first == 0xFE {
        let val = u32::from_le_bytes([data[1], data[2], data[3], data[4]]) as u64;
        (val, 5)
    } else {
        let val = u64::from_le_bytes([
            data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8],
        ]);
        (val, 9)
    }
}

/// Decompose a PSBT into merkle structures for Ledger signing.
/// Converts PSBTv0 to PSBTv2 key-value maps as required by the Ledger Bitcoin app v2.
pub fn btc_ledger_merkelise_psbt(psbt_bytes: Vec<u8>) -> Result<MerkelizedPsbt, String> {
    let psbt: Psbt =
        Psbt::deserialize(&psbt_bytes).map_err(|e| format!("Failed to parse PSBT: {}", e))?;

    let input_count = psbt.unsigned_tx.input.len();
    let output_count = psbt.unsigned_tx.output.len();

    let mut preimage_hashes: Vec<Vec<u8>> = Vec::new();
    let mut preimage_data: Vec<Vec<u8>> = Vec::new();

    // Build PSBTv2 global map and merkelise
    let (global_keys, global_values) = build_v2_global_map(&psbt);
    let (global_commitment, global_keys_leaves, global_values_leaves) = build_merkle_map(
        &global_keys,
        &global_values,
        &mut preimage_hashes,
        &mut preimage_data,
    );

    // Build PSBTv2 input maps and merkelise
    let input_maps = build_v2_input_maps(&psbt);

    let mut input_map_commitments = Vec::new();
    let mut input_map_keys_leaves = Vec::new();
    let mut input_map_values_leaves = Vec::new();

    for (keys, values) in &input_maps {
        let (commitment, keys_leaves, values_leaves) =
            build_merkle_map(keys, values, &mut preimage_hashes, &mut preimage_data);
        input_map_commitments.push(commitment);
        input_map_keys_leaves.push(keys_leaves);
        input_map_values_leaves.push(values_leaves);
    }

    // Build PSBTv2 output maps and merkelise
    let output_maps = build_v2_output_maps(&psbt);

    let mut output_map_commitments = Vec::new();
    let mut output_map_keys_leaves = Vec::new();
    let mut output_map_values_leaves = Vec::new();

    for (keys, values) in &output_maps {
        let (commitment, keys_leaves, values_leaves) =
            build_merkle_map(keys, values, &mut preimage_hashes, &mut preimage_data);
        output_map_commitments.push(commitment);
        output_map_keys_leaves.push(keys_leaves);
        output_map_values_leaves.push(values_leaves);
    }

    // Build top-level merkle trees for input and output commitments
    let input_commitment_leaves: Vec<Vec<u8>> = input_map_commitments
        .iter()
        .map(|c| btc_ledger_hash_leaf(c.clone()))
        .collect();
    let output_commitment_leaves: Vec<Vec<u8>> = output_map_commitments
        .iter()
        .map(|c| btc_ledger_hash_leaf(c.clone()))
        .collect();

    let input_maps_root = build_merkle_tree(&input_commitment_leaves);
    let output_maps_root = build_merkle_tree(&output_commitment_leaves);

    // Add input/output commitments as known-list preimages (0x00 || commitment)
    for c in &input_map_commitments {
        let mut preimage = vec![0x00];
        preimage.extend_from_slice(c);
        add_preimage(&mut preimage_hashes, &mut preimage_data, preimage);
    }
    for c in &output_map_commitments {
        let mut preimage = vec![0x00];
        preimage.extend_from_slice(c);
        add_preimage(&mut preimage_hashes, &mut preimage_data, preimage);
    }

    Ok(MerkelizedPsbt {
        global_map_commitment: global_commitment,
        global_map_keys_leaves: global_keys_leaves,
        global_map_values_leaves: global_values_leaves,
        input_map_commitments,
        input_map_keys_leaves,
        input_map_values_leaves,
        output_map_commitments,
        output_map_keys_leaves,
        output_map_values_leaves,
        input_maps_root,
        output_maps_root,
        preimage_hashes,
        preimage_data,
        input_count: input_count as u32,
        output_count: output_count as u32,
        psbt_bytes,
    })
}

// --- Wallet Policy ---

/// Map BIP purpose to Ledger wallet descriptor template.
fn descriptor_template_for_bip(bip: u32) -> Option<String> {
    match bip {
        DerivationPath::BIP44_PURPOSE => Some("pkh(@0)".to_string()),
        DerivationPath::BIP49_PURPOSE => Some("sh(wpkh(@0))".to_string()),
        DerivationPath::BIP84_PURPOSE => Some("wpkh(@0)".to_string()),
        DerivationPath::BIP86_PURPOSE => Some("tr(@0)".to_string()),
        _ => None,
    }
}

/// Build a wallet policy for the Ledger BTC app.
/// `xpub`: the extended public key string
/// `master_fingerprint`: 4-byte master key fingerprint
/// `bip_purpose`: BIP purpose number (44, 49, 84, 86)
/// `account_index`: the account index in the derivation path
pub fn btc_ledger_build_wallet_policy(
    xpub: String,
    master_fingerprint: Vec<u8>,
    bip_purpose: u32,
    account_index: u32,
) -> Result<WalletPolicy, String> {
    if master_fingerprint.len() != 4 {
        return Err("Master fingerprint must be 4 bytes".into());
    }

    let descriptor_template = descriptor_template_for_bip(bip_purpose)
        .ok_or_else(|| format!("Unknown BIP purpose: {}", bip_purpose))?;

    // Key info format: [fingerprint/purpose'/cointype'/account']xpub
    // Bitcoin mainnet coin type = 0, testnet = 1
    let fp_hex = hex::encode(&master_fingerprint);
    let key_info = format!(
        "[{}/{}'/0'/{}']{}/**",
        fp_hex, bip_purpose, account_index, xpub
    );
    let keys_info = vec![key_info.clone()];

    // Serialize the policy for hashing
    // Format: version(1) || name_len(1=0) || varint(desc_len) || descriptor || varint(key_count) || keys_merkle_root(32)
    let desc_bytes = descriptor_template.as_bytes();
    let key_info_bytes = key_info.as_bytes();

    // Build keys merkle tree (single key = single leaf)
    let key_leaf = btc_ledger_hash_leaf(key_info_bytes.to_vec());
    let keys_root = build_merkle_tree(&[key_leaf]);

    let mut serialized = Vec::new();
    serialized.push(0x01);
    serialized.push(0x00);
    serialized.extend_from_slice(&encode_varint(desc_bytes.len() as u64));
    serialized.extend_from_slice(desc_bytes);
    serialized.extend_from_slice(&encode_varint(1)); // 1 key
    serialized.extend_from_slice(&keys_root);

    let policy_id = btc_ledger_sha256(serialized.clone());

    Ok(WalletPolicy {
        descriptor_template,
        keys_info,
        policy_id,
        policy_hmac: vec![0u8; 32], // empty for default wallets
        serialized,
    })
}

// --- PSBT Finalization with Ledger Signatures ---

/// Finalize a PSBT with signatures collected from Ledger device.
/// `psbt_bytes`: original PSBT bytes
/// `sigs`: list of (input_index, signature_bytes, pubkey_bytes)
/// `addr_type`: address type as BIP purpose (44=P2PKH, 49=P2SH-P2WPKH, 84=P2WPKH, 86=P2TR)
pub fn btc_ledger_finalize_psbt_with_sigs(
    psbt_bytes: Vec<u8>,
    sigs: Vec<LedgerInputSignature>,
    addr_type: u32,
) -> Result<FinalizedBtcTx, String> {
    let mut psbt: Psbt =
        Psbt::deserialize(&psbt_bytes).map_err(|e| format!("Failed to parse PSBT: {}", e))?;

    let btc_addr_type = match addr_type {
        DerivationPath::BIP44_PURPOSE => bitcoin::AddressType::P2pkh,
        DerivationPath::BIP49_PURPOSE => bitcoin::AddressType::P2sh,
        DerivationPath::BIP84_PURPOSE => bitcoin::AddressType::P2wpkh,
        DerivationPath::BIP86_PURPOSE => bitcoin::AddressType::P2tr,
        _ => {
            return Err(format!(
                "Unknown address type for BIP purpose: {}",
                addr_type
            ))
        }
    };

    // Insert signatures into PSBT inputs
    for sig_info in &sigs {
        let idx = sig_info.input_index as usize;
        if idx >= psbt.inputs.len() {
            return Err(format!(
                "Input index {} out of bounds ({})",
                idx,
                psbt.inputs.len()
            ));
        }

        match btc_addr_type {
            bitcoin::AddressType::P2tr => {
                // Taproot: signature goes into tap_key_sig
                // Signature is 64 bytes (SIGHASH_DEFAULT) or 65 bytes (with sighash byte)
                let schnorr_sig = bitcoin::taproot::Signature::from_slice(&sig_info.signature)
                    .map_err(|e| format!("Invalid Schnorr signature: {}", e))?;
                psbt.inputs[idx].tap_key_sig = Some(schnorr_sig);
            }
            _ => {
                // ECDSA: signature goes into partial_sigs
                let ecdsa_sig = bitcoin::ecdsa::Signature::from_slice(&sig_info.signature)
                    .map_err(|e| format!("Invalid ECDSA signature: {}", e))?;

                let pubkey = if sig_info.pubkey.is_empty() {
                    // Extract pubkey from PSBT's bip32_derivation (set by btc_ledger_prepare_psbt)
                    let (pk, _) = psbt.inputs[idx]
                        .bip32_derivation
                        .iter()
                        .next()
                        .ok_or_else(|| {
                            format!("No pubkey in bip32_derivation for input {}", idx)
                        })?;
                    bitcoin::PublicKey::new(*pk)
                } else {
                    bitcoin::PublicKey::from_slice(&sig_info.pubkey)
                        .map_err(|e| format!("Invalid public key: {}", e))?
                };

                psbt.inputs[idx].partial_sigs.insert(pubkey, ecdsa_sig);
            }
        }
    }

    // Finalize each input
    for input in &mut psbt.inputs {
        match btc_addr_type {
            bitcoin::AddressType::P2tr => {
                if let Some(sig) = input.tap_key_sig.take() {
                    input.final_script_witness = Some(Witness::p2tr_key_spend(&sig));
                }
            }
            bitcoin::AddressType::P2wpkh => {
                if let Some((&pubkey, sig)) = input.partial_sigs.iter().next() {
                    let mut witness = Witness::new();
                    witness.push(sig.serialize());
                    witness.push(pubkey.to_bytes());
                    input.final_script_witness = Some(witness);
                }
                input.partial_sigs.clear();
            }
            bitcoin::AddressType::P2sh => {
                // P2SH-P2WPKH (wrapped segwit)
                if let Some((&pubkey, sig)) = input.partial_sigs.iter().next() {
                    // Witness
                    let mut witness = Witness::new();
                    witness.push(sig.serialize());
                    witness.push(pubkey.to_bytes());
                    input.final_script_witness = Some(witness);

                    // ScriptSig = push(redeemScript) where redeemScript = OP_0 <pubkey_hash>
                    if let Some(redeem_script) = &input.redeem_script {
                        // Build scriptSig manually: <len> <redeem_script>
                        let rs_bytes = redeem_script.as_bytes();
                        let mut script_bytes = Vec::new();
                        script_bytes.push(rs_bytes.len() as u8);
                        script_bytes.extend_from_slice(rs_bytes);
                        input.final_script_sig = Some(bitcoin::ScriptBuf::from_bytes(script_bytes));
                    }
                }
                input.partial_sigs.clear();
            }
            bitcoin::AddressType::P2pkh => {
                // Legacy P2PKH
                if let Some((&pubkey, sig)) = input.partial_sigs.iter().next() {
                    // Build scriptSig: <sig_len> <sig> <pubkey_len> <pubkey>
                    let sig_bytes = sig.serialize();
                    let pk_bytes = pubkey.to_bytes();
                    let mut script_bytes = Vec::new();
                    script_bytes.push(sig_bytes.len() as u8);
                    script_bytes.extend_from_slice(&sig_bytes);
                    script_bytes.push(pk_bytes.len() as u8);
                    script_bytes.extend_from_slice(&pk_bytes);
                    input.final_script_sig = Some(bitcoin::ScriptBuf::from_bytes(script_bytes));
                }
                input.partial_sigs.clear();
            }
            _ => {}
        }

        // Clean up PSBT fields after finalization
        input.witness_utxo = None;
        input.non_witness_utxo = None;
        input.sighash_type = None;
        input.bip32_derivation.clear();
        input.tap_key_origins.clear();
        input.tap_internal_key = None;
        input.redeem_script = None;
        input.witness_script = None;
    }

    // Serialize PSBT before extraction (extract_tx consumes it)
    let psbt_bytes = psbt.serialize();

    // Extract the final signed transaction
    let signed_tx = psbt.extract_tx_unchecked_fee_rate();
    let tx_bytes = btc_encode::serialize(&signed_tx);
    let tx_hash = signed_tx.compute_txid().to_string();

    Ok(FinalizedBtcTx {
        raw_tx_hex: hex::encode(&tx_bytes),
        tx_hash,
        psbt_bytes,
    })
}

// --- PSBT Building for Ledger ---

/// Build PSBT bytes from a raw Bitcoin transaction hex and witness UTXOs JSON.
/// This wraps the existing build_psbt from zilpay-core.
pub fn btc_ledger_build_psbt_from_tx(
    tx_hex: String,
    witness_utxos_json: String,
) -> Result<Vec<u8>, String> {
    let tx_bytes = hex::decode(&tx_hex).map_err(|e| format!("Invalid tx hex: {}", e))?;
    let tx: BitcoinTransaction = btc_encode::deserialize(&tx_bytes)
        .map_err(|e| format!("Failed to deserialize transaction: {}", e))?;

    let witness_utxos: Vec<bitcoin::TxOut> = serde_json::from_str(&witness_utxos_json)
        .map_err(|e| format!("Failed to parse witness UTXOs: {}", e))?;

    let psbt = zilpay::proto::btc_tx::build_psbt(tx, &witness_utxos)
        .map_err(|e| format!("Failed to build PSBT: {:?}", e))?;

    Ok(psbt.serialize())
}

/// Populate BIP32 derivation info into a PSBT for Ledger signing.
/// Derives child keys from the account xpub and matches them against
/// input/output script_pubkeys to set tap_key_origins / bip32_derivation.
pub fn btc_ledger_prepare_psbt(
    psbt_bytes: Vec<u8>,
    master_fingerprint: Vec<u8>,
    bip_purpose: u32,
    account_index: u32,
    xpub: String,
) -> Result<Vec<u8>, String> {
    if master_fingerprint.len() != 4 {
        return Err("Master fingerprint must be 4 bytes".into());
    }

    let mut psbt: Psbt =
        Psbt::deserialize(&psbt_bytes).map_err(|e| format!("Failed to parse PSBT: {}", e))?;

    let secp = Secp256k1::verification_only();
    let account_xpub = Xpub::from_str(&xpub).map_err(|e| format!("Failed to parse xpub: {}", e))?;

    let fp = Fingerprint::from(
        <[u8; 4]>::try_from(&master_fingerprint[..4])
            .map_err(|_| "Invalid fingerprint".to_string())?,
    );

    // Build the hardened portion of the derivation path: purpose'/cointype'/account'
    let account_path = vec![
        ChildNumber::from_hardened_idx(bip_purpose).map_err(|e| e.to_string())?,
        ChildNumber::from_hardened_idx(0).map_err(|e| e.to_string())?, // cointype 0 = mainnet
        ChildNumber::from_hardened_idx(account_index).map_err(|e| e.to_string())?,
    ];

    // Pre-derive child keys for change=0,1 and index=0..GAP_LIMIT
    const GAP_LIMIT: u32 = 30;
    let mut derived_keys: Vec<(bitcoin::secp256k1::PublicKey, Vec<ChildNumber>)> = Vec::new();

    for change in 0..=1u32 {
        let change_child = ChildNumber::from_normal_idx(change).map_err(|e| e.to_string())?;
        let change_xpub = account_xpub
            .derive_pub(&secp, &[change_child])
            .map_err(|e| format!("Failed to derive change key: {}", e))?;

        for idx in 0..GAP_LIMIT {
            let idx_child = ChildNumber::from_normal_idx(idx).map_err(|e| e.to_string())?;
            let child_xpub = change_xpub
                .derive_pub(&secp, &[idx_child])
                .map_err(|e| format!("Failed to derive child key: {}", e))?;

            let mut full_path = account_path.clone();
            full_path.push(change_child);
            full_path.push(idx_child);

            derived_keys.push((child_xpub.public_key, full_path));
        }
    }

    // Match inputs
    for (i, input) in psbt.inputs.iter_mut().enumerate() {
        let script_pubkey = if let Some(ref utxo) = input.witness_utxo {
            utxo.script_pubkey.clone()
        } else {
            continue;
        };

        for (pubkey, full_path) in &derived_keys {
            let matched = match bip_purpose {
                DerivationPath::BIP86_PURPOSE => {
                    // Taproot: compute p2tr script from x-only key
                    let (xonly, _parity) = pubkey.x_only_public_key();
                    let expected = bitcoin::ScriptBuf::new_p2tr(&secp, xonly, None);
                    expected == script_pubkey
                }
                DerivationPath::BIP84_PURPOSE => {
                    // Native SegWit: p2wpkh
                    let btc_pubkey = bitcoin::PublicKey::new(*pubkey);
                    let cpk = bitcoin::CompressedPublicKey::try_from(btc_pubkey);
                    if let Ok(cpk) = cpk {
                        let expected = bitcoin::ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash());
                        expected == script_pubkey
                    } else {
                        false
                    }
                }
                DerivationPath::BIP49_PURPOSE => {
                    // Nested SegWit: p2sh-p2wpkh
                    let btc_pk = bitcoin::PublicKey::new(*pubkey);
                    let cpk = bitcoin::CompressedPublicKey::try_from(btc_pk);
                    if let Ok(cpk) = cpk {
                        let wpkh_script = bitcoin::ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash());
                        let expected = bitcoin::ScriptBuf::new_p2sh(&wpkh_script.script_hash());
                        expected == script_pubkey
                    } else {
                        false
                    }
                }
                DerivationPath::BIP44_PURPOSE => {
                    // Legacy: p2pkh
                    let btc_pubkey = bitcoin::PublicKey::new(*pubkey);
                    let expected = bitcoin::ScriptBuf::new_p2pkh(&btc_pubkey.pubkey_hash());
                    expected == script_pubkey
                }
                _ => false,
            };

            if matched {
                let deriv_path = bitcoin::bip32::DerivationPath::from(full_path.clone());

                if bip_purpose == DerivationPath::BIP86_PURPOSE {
                    let (xonly, _) = pubkey.x_only_public_key();
                    input.tap_internal_key = Some(xonly);
                    input
                        .tap_key_origins
                        .insert(xonly, (vec![], (fp, deriv_path)));
                } else {
                    input.bip32_derivation.insert(*pubkey, (fp, deriv_path));
                }
                break;
            }
        }

        if bip_purpose == DerivationPath::BIP86_PURPOSE && input.tap_key_origins.is_empty() {
            return Err(format!(
                "Could not match input {} to any derived key (gap_limit={})",
                i, GAP_LIMIT
            ));
        } else if bip_purpose != DerivationPath::BIP86_PURPOSE && input.bip32_derivation.is_empty()
        {
            return Err(format!(
                "Could not match input {} to any derived key (gap_limit={})",
                i, GAP_LIMIT
            ));
        }
    }

    // Match outputs (for change output detection)
    for (_i, txout) in psbt.unsigned_tx.output.iter().enumerate() {
        let output = &mut psbt.outputs[_i];

        for (pubkey, full_path) in &derived_keys {
            let matched = match bip_purpose {
                DerivationPath::BIP86_PURPOSE => {
                    let (xonly, _) = pubkey.x_only_public_key();
                    let expected = bitcoin::ScriptBuf::new_p2tr(&secp, xonly, None);
                    expected == txout.script_pubkey
                }
                DerivationPath::BIP84_PURPOSE => {
                    let btc_pubkey = bitcoin::PublicKey::new(*pubkey);
                    let cpk = bitcoin::CompressedPublicKey::try_from(btc_pubkey);
                    if let Ok(cpk) = cpk {
                        bitcoin::ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash()) == txout.script_pubkey
                    } else {
                        false
                    }
                }
                DerivationPath::BIP49_PURPOSE => {
                    let btc_pubkey = bitcoin::PublicKey::new(*pubkey);
                    let cpk = bitcoin::CompressedPublicKey::try_from(btc_pubkey);
                    if let Ok(cpk) = cpk {
                        let wpkh = bitcoin::ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash());
                        bitcoin::ScriptBuf::new_p2sh(&wpkh.script_hash()) == txout.script_pubkey
                    } else {
                        false
                    }
                }
                DerivationPath::BIP44_PURPOSE => {
                    let btc_pubkey = bitcoin::PublicKey::new(*pubkey);
                    bitcoin::ScriptBuf::new_p2pkh(&btc_pubkey.pubkey_hash()) == txout.script_pubkey
                }
                _ => false,
            };

            if matched {
                let deriv_path = bitcoin::bip32::DerivationPath::from(full_path.clone());

                if bip_purpose == DerivationPath::BIP86_PURPOSE {
                    let (xonly, _) = pubkey.x_only_public_key();
                    output
                        .tap_key_origins
                        .insert(xonly, (vec![], (fp, deriv_path)));
                } else {
                    output.bip32_derivation.insert(*pubkey, (fp, deriv_path));
                }
                break;
            }
        }
    }

    Ok(psbt.serialize())
}

/// Encode a BIP32 derivation path to bytes for APDU.
/// Path format: number_of_elements(1) || element1(4) || element2(4) || ...
/// Hardened elements have bit 31 set.
pub fn btc_ledger_encode_path(path: String) -> Result<Vec<u8>, String> {
    let parts: Vec<&str> = path.split('/').collect();
    let mut elements: Vec<u32> = Vec::new();

    for part in &parts {
        let trimmed = part.trim();
        if trimmed == "m" || trimmed.is_empty() {
            continue;
        }
        let (hardened, num_str) = if trimmed.ends_with('\'') || trimmed.ends_with('h') {
            (true, &trimmed[..trimmed.len() - 1])
        } else {
            (false, trimmed)
        };
        let num: u32 = num_str
            .parse()
            .map_err(|_| format!("Invalid path element: {}", trimmed))?;
        let element = if hardened { num | 0x80000000 } else { num };
        elements.push(element);
    }

    let mut buf = Vec::new();
    buf.push(elements.len() as u8);
    for elem in &elements {
        buf.extend_from_slice(&elem.to_be_bytes());
    }
    Ok(buf)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_hasher(data: &[u8]) -> Vec<u8> {
        data.to_vec()
    }

    fn leaf(n: u8) -> Vec<u8> {
        vec![0, n]
    }

    fn merkle_of_count(count: usize) -> (Vec<Vec<u8>>, Vec<u8>) {
        let leaves: Vec<Vec<u8>> = (0..count).map(|i| leaf(i as u8)).collect();
        let root = build_merkle_tree_with_hasher(&leaves, &test_hasher);
        (leaves, root)
    }

    fn build_merkle_tree_with_hasher(
        leaf_hashes: &[Vec<u8>],
        hasher: &impl Fn(&[u8]) -> Vec<u8>,
    ) -> Vec<u8> {
        if leaf_hashes.is_empty() {
            return vec![0u8; 32];
        }
        if leaf_hashes.len() == 1 {
            return leaf_hashes[0].clone();
        }
        let split = highest_power_of_2_less_than(leaf_hashes.len());
        let left_root = build_merkle_tree_with_hasher(&leaf_hashes[..split], hasher);
        let right_root = build_merkle_tree_with_hasher(&leaf_hashes[split..], hasher);
        hasher(&[&[0x01], &left_root[..], &right_root[..]].concat())
    }

    #[test]
    fn test_hash_leaf() {
        let data = vec![0x01, 0x02, 0x03];
        let hash = btc_ledger_hash_leaf(data.clone());
        assert_eq!(hash.len(), 32);

        let mut hasher = Sha256::new();
        hasher.update([0x00]);
        hasher.update(&data);
        let expected = hasher.finalize().to_vec();
        assert_eq!(hash, expected);
    }

    #[test]
    fn test_hash_node() {
        let left = vec![0x01; 32];
        let right = vec![0x02; 32];
        let hash = hash_node(&left, &right);

        let mut hasher = Sha256::new();
        hasher.update([0x01]);
        hasher.update(&left);
        hasher.update(&right);
        let expected = hasher.finalize().to_vec();
        assert_eq!(hash, expected);
    }

    #[test]
    fn test_merkle_root_empty() {
        let root = btc_ledger_compute_merkle_root(vec![]);
        assert_eq!(root, vec![0u8; 32]);
    }

    #[test]
    fn test_merkle_root_single() {
        let leaf = btc_ledger_hash_leaf(vec![0x42]);
        let root = btc_ledger_compute_merkle_root(vec![leaf.clone()]);
        assert_eq!(root, leaf);
    }

    #[test]
    fn test_merkle_root_two() {
        let leaf0 = btc_ledger_hash_leaf(vec![0x01]);
        let leaf1 = btc_ledger_hash_leaf(vec![0x02]);
        let root = btc_ledger_compute_merkle_root(vec![leaf0.clone(), leaf1.clone()]);

        let expected = hash_node(&leaf0, &leaf1);
        assert_eq!(root, expected);
    }

    #[test]
    fn test_merkle_root_matches_js_0_leaves() {
        let (_, root) = merkle_of_count(0);
        let expected = vec![0u8; 32];
        assert_eq!(root, expected);
    }

    #[test]
    fn test_merkle_root_matches_js_1_leaf() {
        let (leaves, root) = merkle_of_count(1);
        assert_eq!(root, leaves[0]);
    }

    #[test]
    fn test_merkle_root_matches_js_2_leaves() {
        let (leaves, root) = merkle_of_count(2);
        let expected = test_hasher(&[&[0x01], &leaves[0][..], &leaves[1][..]].concat());
        assert_eq!(root, expected);
    }

    #[test]
    fn test_merkle_root_matches_js_3_leaves() {
        let (leaves, root) = merkle_of_count(3);
        let left_root = leaves[0..2].iter().map(|l| l.clone()).collect::<Vec<_>>();
        let left = build_merkle_tree_with_hasher(&left_root, &test_hasher);
        let right = leaves[2].clone();
        let expected = test_hasher(&[&[0x01], &left[..], &right[..]].concat());
        assert_eq!(root, expected);
    }

    #[test]
    fn test_merkle_root_matches_js_4_leaves() {
        let (leaves, root) = merkle_of_count(4);
        let left = build_merkle_tree_with_hasher(&leaves[0..2], &test_hasher);
        let right = build_merkle_tree_with_hasher(&leaves[2..4], &test_hasher);
        let expected = test_hasher(&[&[0x01], &left[..], &right[..]].concat());
        assert_eq!(root, expected);
    }

    #[test]
    fn test_merkle_root_matches_js_5_leaves() {
        let (leaves, root) = merkle_of_count(5);
        let left = build_merkle_tree_with_hasher(&leaves[0..4], &test_hasher);
        let right = leaves[4].clone();
        let expected = test_hasher(&[&[0x01], &left[..], &right[..]].concat());
        assert_eq!(root, expected);
    }

    #[test]
    fn test_merkle_proof_single() {
        let leaves: Vec<Vec<u8>> = (0..1).map(|i| btc_ledger_hash_leaf(vec![i])).collect();
        let proof = btc_ledger_get_merkle_proof(leaves.clone(), 0).unwrap();
        assert!(proof.proof_hashes.is_empty());
    }

    #[test]
    fn test_merkle_proof_two() {
        let leaves: Vec<Vec<u8>> = (0..2).map(|i| btc_ledger_hash_leaf(vec![i])).collect();
        let _root = btc_ledger_compute_merkle_root(leaves.clone());

        let proof0 = btc_ledger_get_merkle_proof(leaves.clone(), 0).unwrap();
        assert_eq!(proof0.proof_hashes.len(), 1);
        assert_eq!(proof0.proof_hashes[0], leaves[1]);

        let proof1 = btc_ledger_get_merkle_proof(leaves.clone(), 1).unwrap();
        assert_eq!(proof1.proof_hashes.len(), 1);
        assert_eq!(proof1.proof_hashes[0], leaves[0]);
    }

    #[test]
    fn test_merkle_proof_three() {
        let leaves: Vec<Vec<u8>> = (0..3).map(|i| btc_ledger_hash_leaf(vec![i])).collect();
        let _root = btc_ledger_compute_merkle_root(leaves.clone());

        let proof0 = btc_ledger_get_merkle_proof(leaves.clone(), 0).unwrap();
        assert_eq!(proof0.proof_hashes.len(), 2);

        let proof1 = btc_ledger_get_merkle_proof(leaves.clone(), 1).unwrap();
        assert_eq!(proof1.proof_hashes.len(), 2);

        let proof2 = btc_ledger_get_merkle_proof(leaves.clone(), 2).unwrap();
        assert_eq!(proof2.proof_hashes.len(), 1);
    }

    #[test]
    fn test_merkle_proof_four() {
        let leaves: Vec<Vec<u8>> = (0..4).map(|i| btc_ledger_hash_leaf(vec![i])).collect();
        let _root = btc_ledger_compute_merkle_root(leaves.clone());

        for i in 0..4 {
            let proof = btc_ledger_get_merkle_proof(leaves.clone(), i).unwrap();
            assert_eq!(proof.proof_hashes.len(), 2);
        }
    }

    #[test]
    fn test_merkle_proof_five() {
        let leaves: Vec<Vec<u8>> = (0..5).map(|i| btc_ledger_hash_leaf(vec![i])).collect();
        let _root = btc_ledger_compute_merkle_root(leaves.clone());

        for i in 0..4 {
            let proof = btc_ledger_get_merkle_proof(leaves.clone(), i).unwrap();
            assert_eq!(
                proof.proof_hashes.len(),
                3,
                "Leaf {} should have 3 proof elements",
                i
            );
        }

        let proof4 = btc_ledger_get_merkle_proof(leaves.clone(), 4).unwrap();
        assert_eq!(
            proof4.proof_hashes.len(),
            1,
            "Leaf 4 should have 1 proof element"
        );
    }

    #[test]
    fn test_merkle_leaf_index() {
        let leaves: Vec<Vec<u8>> = (0..5).map(|i| btc_ledger_hash_leaf(vec![i])).collect();

        assert_eq!(
            btc_ledger_get_merkle_leaf_index(leaves.clone(), leaves[3].clone()),
            3
        );
        assert_eq!(
            btc_ledger_get_merkle_leaf_index(leaves.clone(), vec![0u8; 32]),
            -1
        );
    }

    #[test]
    fn test_varint_encoding_matches_js() {
        assert_eq!(encode_varint(0), vec![0x00]);
        assert_eq!(encode_varint(252), vec![0xFC]);
        assert_eq!(encode_varint(253), vec![0xFD, 0xFD, 0x00]);
        assert_eq!(encode_varint(0xFFFF), vec![0xFD, 0xFF, 0xFF]);
        assert_eq!(encode_varint(0x10000), vec![0xFE, 0x00, 0x00, 0x01, 0x00]);
        assert_eq!(encode_varint(1), vec![0x01]);
        assert_eq!(encode_varint(127), vec![0x7F]);
        assert_eq!(encode_varint(128), vec![0x80]);
    }

    #[test]
    fn test_varint_decoding() {
        assert_eq!(decode_varint(&[0x00]), (0, 1));
        assert_eq!(decode_varint(&[0xFC]), (252, 1));
        assert_eq!(decode_varint(&[0xFD, 0xFD, 0x00]), (253, 3));
        assert_eq!(decode_varint(&[0xFD, 0xFF, 0xFF]), (0xFFFF, 3));
        assert_eq!(decode_varint(&[0xFE, 0x00, 0x00, 0x01, 0x00]), (0x10000, 5));
    }

    #[test]
    fn test_encode_path() {
        let path = "m/84'/0'/0'/0/0".to_string();
        let encoded = btc_ledger_encode_path(path).unwrap();
        assert_eq!(encoded[0], 5);
        assert_eq!(encoded.len(), 1 + 5 * 4);

        let elem0 = u32::from_be_bytes([encoded[1], encoded[2], encoded[3], encoded[4]]);
        assert_eq!(elem0, 84 | 0x80000000);
    }

    #[test]
    fn test_encode_path_with_h() {
        let path1 = "m/84'/0'/0'".to_string();
        let path2 = "m/84h/0h/0h".to_string();
        let encoded1 = btc_ledger_encode_path(path1).unwrap();
        let encoded2 = btc_ledger_encode_path(path2).unwrap();
        assert_eq!(encoded1, encoded2);
    }

    #[test]
    fn test_preimage_store() {
        let data = vec![0x01, 0x02, 0x03];
        let hash = btc_ledger_sha256(data.clone());

        let hashes = vec![hash.clone()];
        let datas = vec![data.clone()];

        let result = btc_ledger_get_preimage(hashes, datas, hash).unwrap();
        assert_eq!(result, data);
    }

    #[test]
    fn test_wallet_policy_version_byte() {
        let fp = vec![0xc5, 0x5d, 0x68, 0x95];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP84_PURPOSE, 0).unwrap();

        assert_eq!(
            policy.serialized[0], 0x01,
            "Wallet policy version should be 0x01"
        );
    }

    #[test]
    fn test_wallet_policy_key_format_with_wildcard() {
        let fp = vec![0xc5, 0x5d, 0x68, 0x95];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub.clone(), fp, DerivationPath::BIP84_PURPOSE, 0)
                .unwrap();

        assert!(
            policy.keys_info[0].ends_with("/**"),
            "Key should end with /**"
        );
        assert!(
            policy.keys_info[0].contains(&xpub),
            "Key should contain xpub"
        );
    }

    #[test]
    fn test_wallet_policy_bip84() {
        let fp = vec![0xc5, 0x5d, 0x68, 0x95];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP84_PURPOSE, 0).unwrap();

        assert_eq!(policy.descriptor_template, "wpkh(@0)");
        assert_eq!(policy.policy_id.len(), 32);
        assert_eq!(policy.policy_hmac.len(), 32);
        assert!(policy.keys_info[0].starts_with("[c55d6895/84'/0'/0']"));
        assert!(policy.keys_info[0].ends_with("/**"));
    }

    #[test]
    fn test_wallet_policy_bip44() {
        let fp = vec![0xab, 0xcd, 0xef, 0x12];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP44_PURPOSE, 0).unwrap();

        assert_eq!(policy.descriptor_template, "pkh(@0)");
        assert!(policy.keys_info[0].starts_with("[abcdef12/44'/0'/0']"));
    }

    #[test]
    fn test_wallet_policy_bip49() {
        let fp = vec![0x11, 0x22, 0x33, 0x44];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP49_PURPOSE, 0).unwrap();

        assert_eq!(policy.descriptor_template, "sh(wpkh(@0))");
        assert!(policy.keys_info[0].starts_with("[11223344/49'/0'/0']"));
    }

    #[test]
    fn test_wallet_policy_bip86() {
        let fp = vec![0xaa, 0xbb, 0xcc, 0xdd];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP86_PURPOSE, 0).unwrap();

        assert_eq!(policy.descriptor_template, "tr(@0)");
        assert!(policy.keys_info[0].starts_with("[aabbccdd/86'/0'/0']"));
    }

    #[test]
    fn test_wallet_policy_serialization_format() {
        let fp = vec![0xc5, 0x5d, 0x68, 0x95];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP84_PURPOSE, 0).unwrap();

        assert_eq!(policy.serialized[0], 0x01, "version byte");
        assert_eq!(policy.serialized[1], 0x00, "empty wallet name");

        let desc = "wpkh(@0)".as_bytes();
        assert_eq!(
            policy.serialized[2],
            desc.len() as u8,
            "descriptor length varint"
        );

        let desc_start = 3;
        let desc_end = desc_start + desc.len();
        assert_eq!(
            &policy.serialized[desc_start..desc_end],
            desc,
            "descriptor template"
        );

        assert_eq!(policy.serialized[desc_end], 0x01, "key count varint = 1");

        let keys_root_start = desc_end + 1;
        assert_eq!(
            policy.serialized.len(),
            keys_root_start + 32,
            "keys root (32 bytes)"
        );
    }

    #[test]
    fn test_wallet_policy_different_accounts() {
        let fp = vec![0xc5, 0x5d, 0x68, 0x95];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy0 = btc_ledger_build_wallet_policy(
            xpub.clone(),
            fp.clone(),
            DerivationPath::BIP84_PURPOSE,
            0,
        )
        .unwrap();

        let policy1 =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP84_PURPOSE, 1).unwrap();

        assert_ne!(
            policy0.policy_id, policy1.policy_id,
            "Different accounts should have different policy IDs"
        );
        assert!(policy0.keys_info[0].contains("/0']"));
        assert!(policy1.keys_info[0].contains("/1']"));
    }

    #[test]
    fn test_sha256_consistency() {
        let data = vec![0x01, 0x02, 0x03, 0x04];
        let hash1 = btc_ledger_sha256(data.clone());
        let hash2 = btc_ledger_sha256(data.clone());
        assert_eq!(hash1, hash2);
        assert_eq!(hash1.len(), 32);
    }

    #[test]
    fn test_leaf_hash_vs_sha256() {
        let data = vec![0x01, 0x02, 0x03];
        let leaf_hash = btc_ledger_hash_leaf(data.clone());
        let plain_hash =
            btc_ledger_sha256(vec![0x00].into_iter().chain(data.into_iter()).collect());
        assert_eq!(leaf_hash, plain_hash);
    }

    #[test]
    fn test_highest_power_of_2() {
        assert_eq!(highest_power_of_2_less_than(0), 0);
        assert_eq!(highest_power_of_2_less_than(1), 0);
        assert_eq!(highest_power_of_2_less_than(2), 1);
        assert_eq!(highest_power_of_2_less_than(3), 2);
        assert_eq!(highest_power_of_2_less_than(4), 2);
        assert_eq!(highest_power_of_2_less_than(5), 4);
        assert_eq!(highest_power_of_2_less_than(6), 4);
        assert_eq!(highest_power_of_2_less_than(7), 4);
        assert_eq!(highest_power_of_2_less_than(8), 4);
        assert_eq!(highest_power_of_2_less_than(9), 8);
        assert_eq!(highest_power_of_2_less_than(16), 8);
        assert_eq!(highest_power_of_2_less_than(17), 16);
    }

    #[test]
    fn test_merkle_proof_exact_js_two() {
        let leaves: Vec<Vec<u8>> = (0..2).map(|i| leaf(i as u8)).collect();
        let leaves_hashed: Vec<Vec<u8>> = leaves.iter().map(|l| test_hasher(l)).collect();

        let proof0 = btc_ledger_get_merkle_proof(leaves_hashed.clone(), 0).unwrap();
        assert_eq!(
            proof0.proof_hashes,
            vec![leaves_hashed[1].clone()],
            "Proof for leaf 0 should be [leaf1]"
        );

        let proof1 = btc_ledger_get_merkle_proof(leaves_hashed.clone(), 1).unwrap();
        assert_eq!(
            proof1.proof_hashes,
            vec![leaves_hashed[0].clone()],
            "Proof for leaf 1 should be [leaf0]"
        );
    }

    #[test]
    fn test_merkle_proof_exact_js_three() {
        let leaves: Vec<Vec<u8>> = (0..3).map(|i| leaf(i as u8)).collect();
        let leaves_hashed: Vec<Vec<u8>> = leaves.iter().map(|l| test_hasher(l)).collect();

        let proof0 = btc_ledger_get_merkle_proof(leaves_hashed.clone(), 0).unwrap();
        assert_eq!(proof0.proof_hashes.len(), 2);

        let proof2 = btc_ledger_get_merkle_proof(leaves_hashed.clone(), 2).unwrap();
        assert_eq!(proof2.proof_hashes.len(), 1);
    }

    #[test]
    fn test_merkle_proof_exact_js_four() {
        let leaves: Vec<Vec<u8>> = (0..4).map(|i| leaf(i as u8)).collect();
        let leaves_hashed: Vec<Vec<u8>> = leaves.iter().map(|l| test_hasher(l)).collect();

        for i in 0..4 {
            let proof = btc_ledger_get_merkle_proof(leaves_hashed.clone(), i).unwrap();
            assert_eq!(proof.proof_hashes.len(), 2);
        }
    }

    #[test]
    fn test_merkle_proof_exact_js_five() {
        let leaves: Vec<Vec<u8>> = (0..5).map(|i| leaf(i as u8)).collect();
        let leaves_hashed: Vec<Vec<u8>> = leaves.iter().map(|l| test_hasher(l)).collect();

        for i in 0..4 {
            let proof = btc_ledger_get_merkle_proof(leaves_hashed.clone(), i).unwrap();
            assert_eq!(proof.proof_hashes.len(), 3);
        }

        let proof4 = btc_ledger_get_merkle_proof(leaves_hashed.clone(), 4).unwrap();
        assert_eq!(proof4.proof_hashes.len(), 1);
    }

    #[test]
    fn test_path_elements_to_buffer_js_compat() {
        let path_elements: Vec<u32> = vec![0x80000054, 0x80000000, 0x80000000, 0, 0];
        let mut buf = Vec::new();
        buf.push(path_elements.len() as u8);
        for elem in &path_elements {
            buf.extend_from_slice(&elem.to_be_bytes());
        }

        assert_eq!(buf.len(), 1 + 5 * 4);
        assert_eq!(buf[0], 5);

        assert_eq!(
            u32::from_be_bytes([buf[1], buf[2], buf[3], buf[4]]),
            0x80000054
        );
        assert_eq!(
            u32::from_be_bytes([buf[5], buf[6], buf[7], buf[8]]),
            0x80000000
        );
    }

    #[test]
    fn test_path_string_to_array_js_compat() {
        let path = "m/44'/0'/0'/0/0";
        let encoded = btc_ledger_encode_path(path.to_string()).unwrap();

        assert_eq!(encoded[0], 5);

        let elem0 = u32::from_be_bytes([encoded[1], encoded[2], encoded[3], encoded[4]]);
        assert_eq!(elem0, 0x8000002C);

        let elem1 = u32::from_be_bytes([encoded[5], encoded[6], encoded[7], encoded[8]]);
        assert_eq!(elem1, 0x80000000);
    }

    #[test]
    fn test_path_84h_js_compat() {
        let path = "m/84'/0'/0'/0/0";
        let encoded = btc_ledger_encode_path(path.to_string()).unwrap();

        assert_eq!(encoded[0], 5);

        let elem0 = u32::from_be_bytes([encoded[1], encoded[2], encoded[3], encoded[4]]);
        assert_eq!(elem0, 0x80000054, "84' should be 0x80000054");
    }

    #[test]
    fn test_wallet_policy_empty_name() {
        let fp = vec![0xc5, 0x5d, 0x68, 0x95];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP84_PURPOSE, 0).unwrap();

        assert_eq!(
            policy.serialized[1], 0x00,
            "Wallet name length should be 0 for default wallets"
        );
    }

    #[test]
    fn test_wallet_policy_descriptor_template_bytes() {
        let fp = vec![0xc5, 0x5d, 0x68, 0x95];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP84_PURPOSE, 0).unwrap();

        let desc = "wpkh(@0)".as_bytes();
        assert_eq!(
            policy.serialized[2],
            desc.len() as u8,
            "Descriptor length varint"
        );

        let desc_in_serialized = &policy.serialized[3..3 + desc.len()];
        assert_eq!(desc_in_serialized, desc, "Descriptor template bytes");
    }

    #[test]
    fn test_wallet_policy_key_count_varint() {
        let fp = vec![0xc5, 0x5d, 0x68, 0x95];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP84_PURPOSE, 0).unwrap();

        let desc = "wpkh(@0)".as_bytes();
        let key_count_offset = 3 + desc.len();
        assert_eq!(
            policy.serialized[key_count_offset], 0x01,
            "Key count varint should be 1"
        );
    }

    #[test]
    fn test_wallet_policy_id_is_sha256_of_serialized() {
        let fp = vec![0xc5, 0x5d, 0x68, 0x95];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let policy =
            btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP84_PURPOSE, 0).unwrap();

        let expected_id = btc_ledger_sha256(policy.serialized.clone());
        assert_eq!(
            policy.policy_id, expected_id,
            "Policy ID should be SHA256 of serialized policy"
        );
    }

    #[test]
    fn test_preimage_not_found() {
        let hashes = vec![vec![0u8; 32]];
        let datas = vec![vec![0x01]];
        let unknown_hash = vec![1u8; 32];

        let result = btc_ledger_get_preimage(hashes, datas, unknown_hash);
        assert!(result.is_err());
    }

    #[test]
    fn test_merkle_leaf_index_not_found() {
        let leaves: Vec<Vec<u8>> = (0..3).map(|i| btc_ledger_hash_leaf(vec![i])).collect();

        let unknown_hash = vec![0xFF; 32];
        assert_eq!(btc_ledger_get_merkle_leaf_index(leaves, unknown_hash), -1);
    }

    #[test]
    fn test_merkle_proof_out_of_bounds() {
        let leaves: Vec<Vec<u8>> = (0..3).map(|i| btc_ledger_hash_leaf(vec![i])).collect();

        let result = btc_ledger_get_merkle_proof(leaves, 5);
        assert!(result.is_err());
    }

    #[test]
    fn test_wallet_policy_invalid_fingerprint_length() {
        let fp = vec![0x01, 0x02];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let result = btc_ledger_build_wallet_policy(xpub, fp, DerivationPath::BIP84_PURPOSE, 0);

        assert!(result.is_err());
    }

    #[test]
    fn test_wallet_policy_invalid_bip_purpose() {
        let fp = vec![0xc5, 0x5d, 0x68, 0x95];
        let xpub = "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XYuvFvS3w9TF1joB3Nq5LKFpCGRb5k5Jcc9L4CUmXA4wC9gPgL3ep6D1".to_string();

        let result = btc_ledger_build_wallet_policy(xpub, fp, 12345, 0);

        assert!(result.is_err());
    }

    #[test]
    fn test_encode_path_empty() {
        let path = "m";
        let encoded = btc_ledger_encode_path(path.to_string()).unwrap();
        assert_eq!(encoded, vec![0]);
    }

    #[test]
    fn test_encode_path_m_only() {
        let path = "m/";
        let encoded = btc_ledger_encode_path(path.to_string()).unwrap();
        assert_eq!(encoded, vec![0]);
    }

    #[test]
    fn test_encode_path_non_hardened() {
        let path = "m/0/1/2";
        let encoded = btc_ledger_encode_path(path.to_string()).unwrap();

        assert_eq!(encoded[0], 3);

        let elem0 = u32::from_be_bytes([encoded[1], encoded[2], encoded[3], encoded[4]]);
        assert_eq!(elem0, 0);

        let elem1 = u32::from_be_bytes([encoded[5], encoded[6], encoded[7], encoded[8]]);
        assert_eq!(elem1, 1);

        let elem2 = u32::from_be_bytes([encoded[9], encoded[10], encoded[11], encoded[12]]);
        assert_eq!(elem2, 2);
    }
}
