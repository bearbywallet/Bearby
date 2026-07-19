//! Namespace-aware signing for WalletConnect session requests.
//! Parses dapp params and produces the exact JSON result the dapp expects;
//! formats mirror reown_flutter's sample-wallet handlers.

use zilpay::alloy::eips::Encodable2718;
use zilpay::base64::{engine::general_purpose::STANDARD, Engine};
use zilpay::proto::keypair::KeyPair;
use zilpay::proto::signature::Signature;
use zilpay::serde::Deserialize;
use zilpay::serde_json::{self, json, Value};
use zilpay::wallet::account::AccountV2;

use super::error::WcError;

/// Debug-only sign tracing (matches engine `wc_log!` gating).
macro_rules! sign_log {
    ($($arg:tt)*) => {{
        #[cfg(debug_assertions)]
        {
            eprintln!("[wc][sign] {}", format!($($arg)*));
        }
    }};
}

pub(crate) const fn slip44_for_namespace(ns: &str) -> Option<u32> {
    match ns.as_bytes() {
        b"eip155" => Some(zilpay::crypto::slip44::ETHEREUM),
        b"solana" => Some(zilpay::crypto::slip44::SOLANA),
        b"bip122" => Some(zilpay::crypto::slip44::BITCOIN),
        b"tron" => Some(zilpay::crypto::slip44::TRON),
        _ => None,
    }
}

/// Dispatch a signature-only WC method. `eth_sendTransaction`,
/// `solana_signAndSendTransaction` and bip122 `sendTransfer` go through the
/// regular transaction pipeline instead (fee UI + broadcast).
pub(crate) async fn sign_request(
    keypair: &KeyPair,
    account: &AccountV2,
    method: &str,
    params_json: &str,
) -> Result<Value, WcError> {
    match method {
        "personal_sign" | "eth_sign" => eth_personal_sign(keypair, method, params_json),
        "eth_signTypedData" | "eth_signTypedData_v3" | "eth_signTypedData_v4" => {
            eth_sign_typed_data(keypair, params_json).await
        }
        // Signature-only raw transaction signing (no broadcast). Returns the
        // 0x-prefixed 2718-encoded signed payload the dapp may broadcast itself.
        "eth_signTransaction" => eth_sign_transaction(keypair, params_json).await,
        "solana_signMessage" => solana_sign_message(keypair, params_json),
        "solana_signTransaction" => solana_sign_transaction(keypair, params_json),
        "solana_signAllTransactions" => solana_sign_all(keypair, params_json),
        "signMessage" => btc_sign_message(keypair, account, params_json),
        "signPsbt" => btc_sign_psbt(keypair, params_json),
        "tron_signMessage" => tron_sign_message(keypair, params_json),
        "tron_signTransaction" => tron_sign_transaction(keypair, params_json),
        other => Err(WcError::UnsupportedMethod(other.to_owned())),
    }
}

fn message_bytes_from_params(method: &str, params_json: &str) -> Result<Vec<u8>, WcError> {
    // personal_sign: [data, address] · eth_sign: [address, data]
    let params: Vec<Value> = serde_json::from_str(params_json)?;
    let idx = usize::from(method == "eth_sign");
    let data = params
        .get(idx)
        .and_then(Value::as_str)
        .ok_or(WcError::BadParams("missing message param"))?;
    let hex_body = data.strip_prefix("0x").unwrap_or(data);
    match zilpay::hex::decode(hex_body) {
        Ok(bytes) => Ok(bytes),
        Err(_) => Ok(data.as_bytes().to_vec()),
    }
}

fn eth_personal_sign(keypair: &KeyPair, method: &str, params_json: &str) -> Result<Value, WcError> {
    let bytes = message_bytes_from_params(method, params_json)?;
    sign_log!("{method} signing {} message byte(s)", bytes.len());
    let sig = keypair
        .sign_message(&bytes)
        .map_err(|e| WcError::Signing(e.to_string()))?;
    let out = sig.to_hex_prefixed();
    sign_log!("{method} ok -> {out}");
    Ok(Value::String(out))
}

async fn eth_sign_typed_data(keypair: &KeyPair, params_json: &str) -> Result<Value, WcError> {
    let params: Vec<Value> = serde_json::from_str(params_json)?;
    let raw = params
        .get(1)
        .ok_or(WcError::BadParams("missing typed data"))?;
    let typed: zilpay::alloy::dyn_abi::TypedData = match raw {
        Value::String(s) => serde_json::from_str(s)?,
        other => serde_json::from_value(other.clone())?,
    };
    sign_log!(
        "eth_signTypedData domain chain={:?} name={:?}",
        typed.domain.chain_id, typed.domain.name
    );
    let sig = keypair
        .sign_typed_data_eip712(typed)
        .await
        .map_err(|e| WcError::Signing(e.to_string()))?;
    let out = sig.to_hex_prefixed();
    sign_log!("eth_signTypedData ok -> {out}");
    Ok(Value::String(out))
}

/// `eth_signTransaction`: sign a raw EVM transaction *without* broadcasting.
/// params[0] is the transaction object (`{ from, to, value, data, gas, chainId, ... }`).
/// Returns the `0x`-prefixed 2718-encoded signed payload.
async fn eth_sign_transaction(keypair: &KeyPair, params_json: &str) -> Result<Value, WcError> {
    let params: Vec<Value> = serde_json::from_str(params_json)?;
    let tx_value = params
        .into_iter()
        .next()
        .ok_or(WcError::BadParams("missing transaction object"))?;

    // EIP-155 signing needs a chain id; accept hex ("0x1") or decimal.
    let chain_id = evm_chain_id_from_value(&tx_value)
        .ok_or(WcError::BadParams("missing/invalid chainId"))?;

    let mut eth_tx: zilpay::proto::tx::ETHTransactionRequest =
        serde_json::from_value(tx_value)?;
    eth_tx.chain_id = Some(chain_id);

    sign_log!(
        "eth_signTransaction chain_id={chain_id} to={:?} value={:?} gas={:?}",
        eth_tx.to, eth_tx.value, eth_tx.gas
    );

    // Signature-only: broadcast=false so the pipeline never sends it.
    let metadata = zilpay::proto::tx::TransactionMetadata {
        chain_hash: chain_id,
        hash: None,
        info: None,
        icon: None,
        title: None,
        signer: None,
        token_info: None,
        broadcast: false,
    };
    let req = zilpay::proto::tx::TransactionRequest::Ethereum((eth_tx, metadata));
    let receipt = req
        .sign(keypair)
        .await
        .map_err(|e| WcError::Signing(e.to_string()))?;
    let envelope = match receipt {
        zilpay::proto::tx::TransactionReceipt::Ethereum((env, _)) => env,
        _ => return Err(WcError::Signing("expected ethereum receipt".into())),
    };

    // Raw signed transaction, type-prefixed (2718) for eth_sendRawTransaction.
    let raw = envelope.encoded_2718();
    let hex = zilpay::alloy::hex::encode(&raw);
    sign_log!("eth_signTransaction ok, raw={}B", raw.len());
    Ok(Value::String(format!("0x{hex}")))
}

/// Extract an EVM `chainId` from a JSON tx object, accepting `"0x1"` or `1`.
fn evm_chain_id_from_value(v: &Value) -> Option<u64> {
    let c = v.get("chainId").or_else(|| v.get("chain_id"))?;
    match c {
        Value::String(s) => u64::from_str_radix(s.trim_start_matches("0x"), 16).ok(),
        Value::Number(n) => n.as_u64(),
        _ => None,
    }
}

#[derive(Deserialize)]
#[serde(crate = "zilpay::serde")]
struct SolanaMessageParams {
    message: String,
}

fn solana_sign_message(keypair: &KeyPair, params_json: &str) -> Result<Value, WcError> {
    let p: SolanaMessageParams = serde_json::from_str(params_json)?;
    let bytes = zilpay::bs58::decode(&p.message)
        .into_vec()
        .map_err(|_| WcError::BadParams("message is not base58"))?;
    let sig = keypair
        .sign_message(&bytes)
        .map_err(|e| WcError::Signing(e.to_string()))?;
    let Signature::Ed25519Solana(raw) = sig else {
        return Err(WcError::BadParams("account is not ed25519"));
    };
    Ok(json!({ "signature": zilpay::bs58::encode(raw).into_string() }))
}

#[derive(Deserialize)]
#[serde(crate = "zilpay::serde")]
struct SolanaTransactionParams {
    transaction: String,
}

fn signed_solana_receipt(
    keypair: &KeyPair,
    transaction_b64: &str,
) -> Result<zilpay::proto::solana_tx::SolanaTransactionReceipt, WcError> {
    let wire = STANDARD
        .decode(transaction_b64)
        .map_err(|_| WcError::BadParams("transaction is not base64"))?;
    let message = zilpay::proto::solana_tx::normalize_solana_message(&wire)
        .map_err(|_| WcError::BadParams("invalid solana transaction"))?;
    zilpay::proto::solana_tx::SolanaTransaction { message }
        .sign(keypair)
        .map_err(|e| WcError::Signing(e.to_string()))
}

fn solana_sign_transaction(keypair: &KeyPair, params_json: &str) -> Result<Value, WcError> {
    let p: SolanaTransactionParams = serde_json::from_str(params_json)?;
    let receipt = signed_solana_receipt(keypair, &p.transaction)?;
    Ok(json!({ "signature": receipt.tx_id() }))
}

#[derive(Deserialize)]
#[serde(crate = "zilpay::serde")]
struct SolanaTransactionsParams {
    transactions: Vec<String>,
}

fn solana_sign_all(keypair: &KeyPair, params_json: &str) -> Result<Value, WcError> {
    let p: SolanaTransactionsParams = serde_json::from_str(params_json)?;
    let signed = p
        .transactions
        .iter()
        .map(|tx| signed_solana_receipt(keypair, tx).map(|r| STANDARD.encode(r.encode())))
        .collect::<Result<Vec<_>, WcError>>()?;
    Ok(json!({ "transactions": signed }))
}

#[derive(Deserialize)]
#[serde(crate = "zilpay::serde")]
struct BtcSignMessageParams {
    message: String,
}

fn btc_keys(
    keypair: &KeyPair,
) -> Result<
    (
        zilpay::bitcoin::secp256k1::SecretKey,
        zilpay::bitcoin::AddressType,
        zilpay::bitcoin::Network,
    ),
    WcError,
> {
    let KeyPair::Secp256k1Bitcoin((_, sk_bytes, net, addr_type)) = keypair else {
        return Err(WcError::BadParams("account is not bitcoin"));
    };
    let sk = zilpay::bitcoin::secp256k1::SecretKey::from_slice(sk_bytes)
        .map_err(|e| WcError::Signing(e.to_string()))?;
    Ok((sk, *addr_type, *net))
}

fn btc_sign_message(
    keypair: &KeyPair,
    account: &AccountV2,
    params_json: &str,
) -> Result<Value, WcError> {
    let p: BtcSignMessageParams = serde_json::from_str(params_json)?;
    let (sk, addr_type, _) = btc_keys(keypair)?;
    let sig_b64 = zilpay::proto::btc_msg::sign_message_bip137(&sk, p.message.as_bytes(), addr_type)
        .map_err(|e| WcError::Signing(e.to_string()))?;
    Ok(json!({
        "signature": sig_b64,
        "address": account.addr.auto_format(),
    }))
}

#[derive(Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct BtcSignPsbtParams {
    psbt: String,
    #[serde(default)]
    broadcast: bool,
}

/// v1 limitation: stamps/signs **all** inputs with this account's key.
/// Mixed-owner / coinjoin PSBTs (where `signInputs` would select a subset)
/// either partially fail inside `psbt.sign` and surface as `Signing`, or
/// are unsupported. AppKit bitcoin flows send single-owner PSBTs only.
/// Follow-up: honor `signInputs: [{address, index}]` via a selective
/// `sign_psbt_inputs` helper in `proto::btc_tx`.
fn btc_sign_psbt(keypair: &KeyPair, params_json: &str) -> Result<Value, WcError> {
    let p: BtcSignPsbtParams = serde_json::from_str(params_json)?;
    let raw = STANDARD
        .decode(&p.psbt)
        .map_err(|_| WcError::BadParams("psbt is not base64"))?;
    let mut psbt = zilpay::bitcoin::Psbt::deserialize(&raw)
        .map_err(|_| WcError::BadParams("invalid psbt"))?;
    let (sk, addr_type, network) = btc_keys(keypair)?;
    let pubkey = zilpay::bitcoin::secp256k1::PublicKey::from_slice(
        keypair
            .get_pubkey()
            .map_err(|e| WcError::Signing(e.to_string()))?
            .as_bytes(),
    )
    .map_err(|e| WcError::Signing(e.to_string()))?;
    zilpay::proto::btc_tx::sign_psbt(&mut psbt, &sk, &pubkey, network, addr_type)
        .map_err(|e| WcError::Signing(e.to_string()))?;
    if p.broadcast {
        zilpay::proto::btc_tx::finalize_psbt(&mut psbt, addr_type)
            .map_err(|e| WcError::Signing(e.to_string()))?;
        let psbt_b64 = STANDARD.encode(psbt.serialize());
        let tx = psbt.extract_tx_unchecked_fee_rate();
        return Ok(json!({
            "psbt": psbt_b64,
            "txhex": zilpay::hex::encode(zilpay::bitcoin::consensus::encode::serialize(&tx)),
            "txid": tx.compute_txid().to_string(),
        }));
    }
    Ok(json!({ "psbt": STANDARD.encode(psbt.serialize()) }))
}

#[derive(Deserialize)]
#[serde(crate = "zilpay::serde")]
struct TronSignMessageParams {
    message: String,
}

fn tron_sign_message(keypair: &KeyPair, params_json: &str) -> Result<Value, WcError> {
    let p: TronSignMessageParams = serde_json::from_str(params_json)?;
    let hash = zilpay::proto::tron_tx::tron_personal_message_hash(p.message.as_bytes());
    let sig = keypair
        .sign_hash(&hash)
        .map_err(|e| WcError::Signing(e.to_string()))?;
    Ok(json!({ "signature": sig.to_hex_prefixed() }))
}

fn tron_sign_transaction(keypair: &KeyPair, params_json: &str) -> Result<Value, WcError> {
    let mut params: Value = serde_json::from_str(params_json)?;
    // tron_service.dart: params.transaction.transaction ?? params.transaction
    let mut outer = params
        .get_mut("transaction")
        .map(Value::take)
        .ok_or(WcError::BadParams("missing transaction"))?;
    let mut tx_value = match outer.get_mut("transaction") {
        Some(inner) => inner.take(),
        None => outer,
    };
    let tron_web: zilpay::proto::tron_tx::TronWebTransaction =
        zilpay::serde::Deserialize::deserialize(&tx_value)?;
    let tx = zilpay::proto::tron_tx::TronTransaction::from_tron_web(&tron_web)
        .map_err(|e| WcError::Signing(e.to_string()))?;
    let receipt = tx
        .sign(keypair)
        .map_err(|e| WcError::Signing(e.to_string()))?;
    if let Some(obj) = tx_value.as_object_mut() {
        obj.insert("signature".to_owned(), json!([receipt.signature_hex()]));
    }
    Ok(tx_value)
}

#[cfg(test)]
mod tests {
    use super::*;
    use zilpay::proto::keypair::KeyPair;
    use zilpay::wallet::account_type::AccountType;

    fn sol_account(kp: &KeyPair) -> AccountV2 {
        AccountV2 {
            name: "s".into(),
            account_type: AccountType::Bip39HD(0),
            addr: kp.get_addr().expect("addr"),
            pub_key: None,
        }
    }

    fn run<F, T>(f: F) -> T
    where
        F: std::future::Future<Output = T>,
    {
        futures::executor::block_on(f)
    }

    #[test]
    fn slip44_namespace_map() {
        assert_eq!(
            slip44_for_namespace("eip155"),
            Some(zilpay::crypto::slip44::ETHEREUM)
        );
        assert_eq!(
            slip44_for_namespace("solana"),
            Some(zilpay::crypto::slip44::SOLANA)
        );
        assert_eq!(
            slip44_for_namespace("bip122"),
            Some(zilpay::crypto::slip44::BITCOIN)
        );
        assert_eq!(
            slip44_for_namespace("tron"),
            Some(zilpay::crypto::slip44::TRON)
        );
        assert!(slip44_for_namespace("cosmos").is_none());
    }

    #[test]
    fn eth_personal_sign_returns_0x_hex() {
        run(async {
            let kp = KeyPair::gen_keccak256().unwrap();
            let msg = b"hello";
            let hex = format!("0x{}", zilpay::hex::encode(msg));
            let params = format!(r#"["{hex}","0xabc"]"#);
            let acc = AccountV2 {
                name: "e".into(),
                account_type: AccountType::Bip39HD(0),
                addr: kp.get_addr().unwrap(),
                pub_key: None,
            };
            let v = sign_request(&kp, &acc, "personal_sign", &params)
                .await
                .unwrap();
            let s = v.as_str().unwrap();
            assert!(s.starts_with("0x"));
            assert_eq!(s.len(), 2 + 65 * 2);

            let direct = kp.sign_message(msg).unwrap().to_hex_prefixed();
            assert_eq!(s, direct);
        });
    }

    #[test]
    fn solana_sign_message_base58_roundtrip() {
        run(async {
            let kp = KeyPair::gen_solana().unwrap();
            let msg = b"wc-solana-msg";
            let b58 = zilpay::bs58::encode(msg).into_string();
            let params = format!(r#"{{"message":"{b58}","pubkey":"x"}}"#);
            let acc = sol_account(&kp);
            let v = sign_request(&kp, &acc, "solana_signMessage", &params)
                .await
                .unwrap();
            let sig_b58 = v["signature"].as_str().unwrap();
            let sig_bytes = zilpay::bs58::decode(sig_b58).into_vec().unwrap();
            assert_eq!(sig_bytes.len(), 64);
            let sig_arr: [u8; 64] = sig_bytes.try_into().unwrap();
            let sig = Signature::Ed25519Solana(sig_arr);
            assert!(kp.verify_sig(msg, &sig).unwrap());
        });
    }

    #[test]
    fn solana_sign_transaction_keys() {
        run(async {
            let kp = KeyPair::gen_solana().unwrap();
            let from = match kp.get_pubkey().unwrap() {
                zilpay::proto::pubkey::PubKey::Ed25519Solana(pk) => pk,
                _ => panic!("expected solana pubkey"),
            };
            let to = zilpay::solana_pubkey::Pubkey::new_from_array([2u8; 32]);
            let message = zilpay::proto::solana_tx::build_sol_transfer_message(
                &from, &to, 1_000, &[0u8; 32],
            )
            .unwrap();
            // Full wire: 0x01 ‖ empty-sig-placeholder ‖ message (dapp often sends this)
            let mut wire = Vec::with_capacity(1 + 64 + message.len());
            wire.push(0x01);
            wire.extend_from_slice(&[0u8; 64]);
            wire.extend_from_slice(&message);
            let b64 = STANDARD.encode(&wire);
            let params = format!(r#"{{"transaction":"{b64}"}}"#);
            let acc = sol_account(&kp);
            let v = sign_request(&kp, &acc, "solana_signTransaction", &params)
                .await
                .unwrap();
            assert!(v.get("signature").and_then(Value::as_str).is_some());
        });
    }

    #[test]
    fn bip122_sign_message_header() {
        run(async {
            let kp = KeyPair::gen_bitcoin(
                zilpay::bitcoin::Network::Bitcoin,
                zilpay::bitcoin::AddressType::P2wpkh,
            )
            .unwrap();
            let acc = AccountV2 {
                name: "b".into(),
                account_type: AccountType::Bip39HD(0),
                addr: kp.get_addr().unwrap(),
                pub_key: None,
            };
            let params =
                r#"{"message":"Welcome to Flutter AppKit on Bitcoin","account":"bip122:x"}"#;
            let v = sign_request(&kp, &acc, "signMessage", params)
                .await
                .unwrap();
            let sig_b64 = v["signature"].as_str().unwrap();
            let raw = STANDARD.decode(sig_b64).unwrap();
            assert_eq!(raw.len(), 65);
            // P2WPKH header base 39 + rec_id (0..3) → 39..=42
            assert!((39..=42).contains(&raw[0]));
            assert_eq!(v["address"].as_str().unwrap(), acc.addr.auto_format());
        });
    }

    #[test]
    fn tron_sign_message_shape() {
        run(async {
            let kp = KeyPair::gen_tron().unwrap();
            let acc = AccountV2 {
                name: "t".into(),
                account_type: AccountType::Bip39HD(0),
                addr: kp.get_addr().unwrap(),
                pub_key: None,
            };
            let params = r#"{"address":"Txxx","message":"hi tron"}"#;
            let v = sign_request(&kp, &acc, "tron_signMessage", params)
                .await
                .unwrap();
            let s = v["signature"].as_str().unwrap();
            assert!(s.starts_with("0x"));
            assert_eq!(s.len(), 2 + 65 * 2);
        });
    }

    #[test]
    fn unsupported_method_errors() {
        run(async {
            let kp = KeyPair::gen_keccak256().unwrap();
            let acc = AccountV2 {
                name: "e".into(),
                account_type: AccountType::Bip39HD(0),
                addr: kp.get_addr().unwrap(),
                pub_key: None,
            };
            let err = sign_request(&kp, &acc, "wallet_switchEthereumChain", "[]")
                .await
                .unwrap_err();
            assert!(matches!(err, WcError::UnsupportedMethod(_)));
        });
    }
}
