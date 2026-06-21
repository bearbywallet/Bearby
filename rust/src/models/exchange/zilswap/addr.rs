use flutter_rust_bridge::frb;
use zilpay::proto::address::Address;

#[frb(ignore)]
pub(super) fn strip_0x(value: &str) -> &str {
    value
        .strip_prefix("0x")
        .or_else(|| value.strip_prefix("0X"))
        .unwrap_or(value)
}

#[frb(ignore)]
pub(super) fn with_0x_lower(value: &str) -> String {
    let clean = strip_0x(value);
    let mut out = String::with_capacity(clean.len() + 2);
    out.push_str("0x");
    out.push_str(&clean.to_ascii_lowercase());
    out
}

#[frb(ignore)]
pub(super) fn zil_address(addr: &str) -> Result<Address, String> {
    if addr.starts_with("zil") {
        Address::from_str_hex(addr).map_err(|e| e.to_string())
    } else {
        Address::from_zil_base16(strip_0x(addr)).map_err(|e| e.to_string())
    }
}

#[frb(ignore)]
pub(super) fn zil_base16(addr: &str) -> Result<String, String> {
    zil_address(addr)?
        .get_zil_base16()
        .map_err(|e| e.to_string())
}

#[frb(ignore)]
pub(super) fn zil_checksum_lower(addr: &str) -> Result<String, String> {
    zil_address(addr)?
        .get_zil_check_sum_addr()
        .map(|value| value.to_ascii_lowercase())
        .map_err(|e| e.to_string())
}
