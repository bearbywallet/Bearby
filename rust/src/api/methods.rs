use crate::{models::keypair::KeyPairInfo, utils::utils::decode_secret_key};
pub use zilpay::background::{bg_crypto::CryptoOperations, Background};
use zilpay::proto::keypair::KeyPair;

pub fn gen_bip39_words(count: u8) -> Result<String, String> {
    Background::gen_bip39(count).map_err(|e| e.to_string())
}

pub fn check_not_exists_bip39_words(words: Vec<String>, _lang: String) -> Vec<usize> {
    // TODO: add more lang for bip39.
    Background::find_invalid_bip39_words(&words)
}

pub fn gen_keypair() -> Result<KeyPairInfo, String> {
    let (sk, pk) = Background::gen_keypair().map_err(|e| e.to_string())?;

    Ok(KeyPairInfo { sk, pk })
}

pub fn keypair_from_sk(sk: String) -> Result<KeyPairInfo, String> {
    let sk = decode_secret_key(&sk)?;
    let (pk, sk) = KeyPair::from_sk_bytes(sk).map_err(|e| e.to_string())?;

    Ok(KeyPairInfo {
        sk: hex::encode(sk),
        pk: hex::encode(pk),
    })
}

pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
