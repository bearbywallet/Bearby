use std::str::FromStr;

use flutter_rust_bridge::frb;
use sha2::{Digest, Sha256};
pub use zilpay::intl::number::{format_u256, CURRENCY_SYMBOLS};
use zilpay::{background::Mnemonic, config::bip39::EN_WORDS, proto::U256};

use crate::utils::utils::parse_address;

pub fn is_valid_address(addr: String) -> bool {
    parse_address(addr).is_ok()
}

pub fn bitcoin_address_type_from_address(addr: String) -> Result<String, String> {
    let addr = bitcoin::Address::from_str(&addr)
        .map_err(|e| e.to_string())?
        .assume_checked();

    if let Some(address_type) = addr.address_type() {
        return Ok(address_type.to_string());
    }

    Err("invalid addr".to_string())
}

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
    let mnemonic = match Mnemonic::parse_str(&EN_WORDS, &words) {
        Ok(m) => m,
        Err(_) => return false,
    };
    let checksum = mnemonic.checksum();
    let entropy: Vec<u8> = mnemonic.to_entropy().collect();

    let mut hasher = Sha256::new();
    hasher.update(&entropy);
    let digest = hasher.finalize();

    let word_count = mnemonic.word_count;
    let expected_checksum = digest[0] >> (8 - word_count / 3);

    if checksum == expected_checksum {
        true
    } else {
        false
    }
}

#[frb(sync)]
pub fn to_wei(value: String, decimals: u8) -> Result<(String, u8), String> {
    let big_value = zilpay::intl::wei::to_wei(value, decimals).map_err(|e| e.to_string())?;

    Ok((big_value.to_string(), decimals))
}

#[frb(sync)]
pub fn from_wei(value: String, decimals: u8) -> Result<String, String> {
    let value_float = zilpay::intl::wei::from_wei(value, decimals).map_err(|e| e.to_string())?;

    Ok(value_float)
}

#[test]
fn test_bip39_checksum_valid() {
    const CORRECT_WORDS: &str = "minor convince list alarm tide wasp define poverty valley around clump bamboo please beauty finish fall expose stairs muscle noise stand swamp erase six";
    const INCORRECT_WORDS: &str = "minor convince list alarm tide wasp define poverty valley around clump bamboo please beauty finish fall stairs muscle noise stand swamp erase six expose";

    assert!(bip39_checksum_valid(CORRECT_WORDS.to_string()));
    assert!(!bip39_checksum_valid(INCORRECT_WORDS.to_string()));
}

#[test]
fn test_intl_number_formating_repro() {
    let value = "27000000".to_string(); // 27 USDT (6 decimals)
    let decimals = 6;
    let locale_str = "en_US";
    let native_symbol = "USDT";
    let converted_symbol = "USD";
    let threshold = 1000.0;
    let compact = true;
    let rate = 1.0;

    let (native, converted_val) = intl_number_formating(
        value,
        decimals,
        locale_str,
        native_symbol,
        converted_symbol,
        threshold,
        compact,
        rate,
    );

    println!("Native: {}", native);
    println!("Converted: {}", converted_val);
}
