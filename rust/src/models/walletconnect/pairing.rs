//! Pairing URI parse (`wc:<topic>@2?...`) and pairing records.

use flutter_rust_bridge::frb;
use zilpay::serde::{Deserialize, Serialize};

use super::crypto::{decode_hex32, KEY_LEN};
use super::error::WcError;
use super::rpc::{FIVE_MINUTES, THIRTY_DAYS};

#[frb(ignore)]
#[derive(Debug, Clone)]
pub struct PairingUri {
    pub topic: String,
    pub sym_key: [u8; KEY_LEN],
    pub relay_protocol: String,
    pub expiry: Option<u64>,
    pub methods: Vec<String>,
}

impl TryFrom<&str> for PairingUri {
    type Error = WcError;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        // Normalize wc:// → wc: and strip whitespace.
        let trimmed = value.trim();
        let normalized = trimmed
            .strip_prefix("wc://")
            .map(|r| {
                let mut s = String::with_capacity(3 + r.len());
                s.push_str("wc:");
                s.push_str(r);
                s
            })
            .unwrap_or_else(|| trimmed.to_owned());

        let rest = normalized
            .strip_prefix("wc:")
            .ok_or(WcError::InvalidUri("scheme"))?;
        let (path, query) = rest
            .split_once('?')
            .ok_or(WcError::InvalidUri("query"))?;
        let (topic, version) = path
            .split_once('@')
            .ok_or(WcError::InvalidUri("missing @"))?;
        if version != "2" {
            return Err(WcError::InvalidUri("not v2"));
        }
        if topic.is_empty() {
            return Err(WcError::InvalidUri("empty topic"));
        }

        let mut sym_key: Option<[u8; KEY_LEN]> = None;
        let mut relay_protocol = String::new();
        let mut expiry: Option<u64> = None;
        let mut methods = Vec::new();

        for pair in query.split('&') {
            let Some((k, raw_v)) = pair.split_once('=') else {
                continue;
            };
            // Percent-decode query values (`methods` may use %2C / %22, etc.).
            let v = percent_decode(raw_v);
            match k {
                "symKey" => {
                    sym_key =
                        Some(decode_hex32(&v).map_err(|_| WcError::InvalidUri("symKey"))?);
                }
                "relay-protocol" => relay_protocol = v,
                "expiryTimestamp" => {
                    expiry = v.parse().ok();
                }
                "methods" => {
                    // methods may be comma-separated or bracketed lists.
                    let cleaned = v
                        .trim_matches(|c| c == '[' || c == ']')
                        .split(',')
                        .filter(|s| !s.is_empty())
                        .map(|s| s.to_owned());
                    methods.extend(cleaned);
                }
                _ => {}
            }
        }

        if relay_protocol != "irn" {
            return Err(WcError::InvalidUri("relay-protocol"));
        }
        let sym_key = sym_key.ok_or(WcError::InvalidUri("symKey"))?;

        Ok(Self {
            topic: topic.to_owned(),
            sym_key,
            relay_protocol,
            expiry,
            methods,
        })
    }
}

#[frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct StoredPairing {
    /// Hex-encoded 32-byte symKey.
    pub sym_key_hex: String,
    pub expiry: u64,
    pub active: bool,
}

/// Minimal percent-decoding for WC URI query values (hex digits only; other
/// `%XX` fall through as literal on parse failure).
#[frb(ignore)]
fn percent_decode(input: &str) -> String {
    let bytes = input.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'%' if i + 2 < bytes.len() => {
                let h1 = from_hex_digit(bytes[i + 1]);
                let h2 = from_hex_digit(bytes[i + 2]);
                match (h1, h2) {
                    (Some(a), Some(b)) => {
                        out.push((a << 4) | b);
                        i += 3;
                    }
                    _ => {
                        out.push(b'%');
                        i += 1;
                    }
                }
            }
            b'+' => {
                out.push(b' ');
                i += 1;
            }
            b => {
                out.push(b);
                i += 1;
            }
        }
    }
    match String::from_utf8(out) {
        Ok(s) => s,
        Err(e) => String::from_utf8_lossy(e.as_bytes()).into_owned(),
    }
}

fn from_hex_digit(b: u8) -> Option<u8> {
    match b {
        b'0'..=b'9' => Some(b - b'0'),
        b'a'..=b'f' => Some(b - b'a' + 10),
        b'A'..=b'F' => Some(b - b'A' + 10),
        _ => None,
    }
}

impl StoredPairing {
    #[frb(ignore)]
    pub fn new_inactive(sym_key: &[u8; KEY_LEN], now: u64) -> Self {
        Self {
            sym_key_hex: zilpay::hex::encode(sym_key),
            expiry: now.saturating_add(FIVE_MINUTES),
            active: false,
        }
    }

    #[frb(ignore)]
    pub fn activate(&mut self, now: u64) {
        self.active = true;
        self.expiry = now.saturating_add(THIRTY_DAYS);
    }

    #[frb(ignore)]
    pub fn sym_key(&self) -> Result<[u8; KEY_LEN], WcError> {
        decode_hex32(&self.sym_key_hex)
    }

    #[frb(ignore)]
    pub fn is_expired(&self, now: u64) -> bool {
        now >= self.expiry
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_URI: &str = "wc:7f6e504bfad60b485450578e05678ed3e8e8c4751d3c6160be17160d63ec90f9@2?symKey=587d5484ce2a2a6ee3ba1962fdd7e8588e06200c46823bd18fbd67def96ad303&relay-protocol=irn";

    #[test]
    fn parse_reown_test_uri() {
        let uri = PairingUri::try_from(TEST_URI).expect("parse");
        assert_eq!(
            uri.topic,
            "7f6e504bfad60b485450578e05678ed3e8e8c4751d3c6160be17160d63ec90f9"
        );
        assert_eq!(
            zilpay::hex::encode(uri.sym_key),
            "587d5484ce2a2a6ee3ba1962fdd7e8588e06200c46823bd18fbd67def96ad303"
        );
        assert_eq!(uri.relay_protocol, "irn");
    }

    #[test]
    fn parse_wc_double_slash() {
        let s = format!("wc://{}", TEST_URI.strip_prefix("wc:").unwrap());
        let uri = PairingUri::try_from(s.as_str()).expect("parse");
        assert_eq!(
            uri.topic,
            "7f6e504bfad60b485450578e05678ed3e8e8c4751d3c6160be17160d63ec90f9"
        );
    }

    #[test]
    fn reject_v1() {
        let err = PairingUri::try_from(
            "wc:abc@1?symKey=587d5484ce2a2a6ee3ba1962fdd7e8588e06200c46823bd18fbd67def96ad303&relay-protocol=irn",
        );
        assert!(matches!(err, Err(WcError::InvalidUri("not v2"))));
    }

    #[test]
    fn reject_missing_symkey() {
        let err = PairingUri::try_from("wc:abc@2?relay-protocol=irn");
        assert!(matches!(err, Err(WcError::InvalidUri("symKey"))));
    }

    #[test]
    fn parse_with_methods() {
        let s = "wc:abc@2?relay-protocol=irn&symKey=587d5484ce2a2a6ee3ba1962fdd7e8588e06200c46823bd18fbd67def96ad303&methods=wc_sessionPropose,wc_authBatchRequest";
        let uri = PairingUri::try_from(s).expect("parse");
        assert_eq!(uri.methods.len(), 2);
    }
}
