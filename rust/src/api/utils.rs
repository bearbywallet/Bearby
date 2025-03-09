use flutter_rust_bridge::frb;
pub use zilpay::intl::number::format_u256;
use zilpay::proto::U256;

#[frb(sync)]
pub fn intl_number_formating(
    value: String,
    decimals: u8,
    locale_str: &str,
    symbol_str: &str,
    threshold: f64,
    compact: bool,
    converted: f64,
) -> String {
    let u256_value: U256 = value.parse::<U256>().unwrap_or_default();

    format_u256(
        u256_value, decimals, locale_str, symbol_str, threshold, compact, converted,
    )
}
