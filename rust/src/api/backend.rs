use zilpay::background::Background;
use zilpay::crypto::bip49::Bip49DerivationPath;

use crate::api::bg;
use crate::frb_generated::StreamSink;

#[flutter_rust_bridge::frb(dart_async)]
pub fn add_bip39_wallet(
    password: &str,
    mnemonic_str: &str,
    indexes: &[usize],
    net_codes: &[usize],
) -> Result<String, String> {
    let derive = Bip49DerivationPath::Zilliqa;
    // let testbg = Background::from_storage_path();

    Ok(String::new())
    // Background::add_bip39_wallet(password, mnemonic_str, indexes, , ).map_err(|e| e.to_string())
}
