use crate::models::keypair::KeyPairInfo;
pub use zilpay::background::{bg_crypto::CryptoOperations, Background, Language};
use zilpay::proto::address::Address;

#[flutter_rust_bridge::frb(dart_async)]
pub fn gen_bip39_words(count: u8) -> Result<String, String> {
    Background::gen_bip39(count).map_err(|e| e.to_string())
}

#[flutter_rust_bridge::frb(dart_async)]
pub fn check_not_exists_bip39_words(words: Vec<String>, _lang: String) -> Vec<usize> {
    // TODO: add more lang for bip39.
    Background::find_invalid_bip39_words(&words, Language::English)
}

#[flutter_rust_bridge::frb(dart_async)]
pub fn gen_keypair() -> Result<KeyPairInfo, String> {
    let (sk, pk) = Background::gen_keypair().map_err(|e| e.to_string())?;

    Ok(KeyPairInfo { sk, pk })
}

#[flutter_rust_bridge::frb(dart_async)]
pub fn is_crypto_address(addr: String) -> bool {
    let is_zil_bech32 = Address::from_zil_bech32(&addr).is_ok();
    let is_eth_checksum = Address::from_eth_address(&addr).is_ok();
    let is_zil_base16 = Address::from_zil_base16(&addr).is_ok();

    is_zil_bech32 || is_eth_checksum || is_zil_base16
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
