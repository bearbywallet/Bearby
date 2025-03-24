use flutter_rust_bridge::frb;
use sha2::{Digest, Sha256};
pub use zilpay::intl::number::{format_u256, CURRENCY_SYMBOLS};
use zilpay::{background::Mnemonic, proto::U256};

#[frb(sync)]
pub fn intl_number_formating(
    value: String,
    decimals: u8,
    locale_str: &str,
    native_symbol_str: &str,
    converted_symbol_str: &str,
    threshold: f64,
    compact: bool,
    converted: f64,
) -> (String, String) {
    let u256_value: U256 = value.parse::<U256>().unwrap_or_default();

    format_u256(
        u256_value,
        decimals,
        locale_str,
        native_symbol_str,
        converted_symbol_str,
        threshold,
        compact,
        converted,
    )
}

pub fn get_currencies_tickets() -> Vec<(String, String)> {
    CURRENCY_SYMBOLS
        .iter()
        .map(|(symbol, ticket)| (symbol.to_string(), ticket.to_string()))
        .collect()
}

pub fn bip39_checksum_valid(words: String) -> bool {
    let mnemonic = match Mnemonic::parse_normalized(&words) {
        Ok(m) => m,
        Err(_) => return false,
    };
    let checksum = mnemonic.checksum();
    let entropy = mnemonic.to_entropy();

    let mut hasher = Sha256::new();
    hasher.update(&entropy);
    let digest = hasher.finalize();

    let word_count = mnemonic.word_count();
    let expected_checksum = digest[0] >> (8 - word_count / 3);

    if checksum == expected_checksum {
        true
    } else {
        false
    }
}
