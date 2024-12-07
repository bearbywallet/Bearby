use zilpay::background::{Background, Language};

#[flutter_rust_bridge::frb(dart_async)]
pub fn gen_bip39_words(count: u8) -> Result<String, String> {
    Background::gen_bip39(count).map_err(|e| e.to_string())
}

#[flutter_rust_bridge::frb(dart_async)]
pub fn check_not_exists_bip39_words(words: Vec<String>, _lang: String) -> Vec<usize> {
    // TODO: add more lang for bip39.
    Background::find_invalid_bip39_words(&words, Language::English)
}

pub struct KeyPair {
    pub sk: String,
    pub pk: String,
}

#[flutter_rust_bridge::frb(dart_async)]
pub fn gen_keypair() -> Result<KeyPair, String> {
    let (sk, pk) = Background::gen_keypair().map_err(|e| e.to_string())?;

    Ok(KeyPair { sk, pk })
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
