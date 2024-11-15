use zilpay::background::Background;

#[flutter_rust_bridge::frb(dart_async)]
pub fn gen_bip39_words(count: u8) -> Result<String, String> {
    Background::gen_bip39(count).map_err(|e| e.to_string())
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
