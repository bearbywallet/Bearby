//! Ed25519 (EdDSA) relay JWT with `did:key` issuer. Matches reown_core relay_auth.

use flutter_rust_bridge::frb;
use zilpay::base64::Engine;
use zilpay::ed25519_dalek::{Signer, SigningKey, Verifier, VerifyingKey};

use super::error::WcError;

/// Multicodec header for ed25519-pub — `bs58::decode("K36")` == `[0xed, 0x01]`.
const MULTICODEC_ED25519: [u8; 2] = [0xed, 0x01];
const JWT_TTL: u64 = 86_400;

#[frb(ignore)]
pub fn did_key(public: &[u8; 32]) -> String {
    let mut bytes = [0u8; 34];
    bytes[..2].copy_from_slice(&MULTICODEC_ED25519);
    bytes[2..].copy_from_slice(public);
    format!("did:key:z{}", zilpay::bs58::encode(bytes).into_string())
}

/// EdDSA JWT: `base64url(header).base64url(claims).base64url(sig)`, no padding.
///
/// `iat` is used as-is (callers that follow reown production pass `now - 60`).
#[frb(ignore)]
pub fn sign_relay_jwt(
    seed: &[u8; 32],
    aud: &str,
    sub: &str,
    iat: u64,
    ttl: u64,
) -> Result<String, WcError> {
    let key = SigningKey::from_bytes(seed);
    let iss = did_key(key.verifying_key().as_bytes());
    let header = zilpay::base64::engine::general_purpose::URL_SAFE_NO_PAD
        .encode(br#"{"alg":"EdDSA","typ":"JWT"}"#);
    // Compact JSON with stable key order for wire compatibility.
    let claims = format!(
        r#"{{"iss":"{iss}","sub":"{sub}","aud":"{aud}","iat":{iat},"exp":{}}}"#,
        iat + ttl
    );
    let payload = zilpay::base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(claims.as_bytes());
    let mut signing_input = String::with_capacity(header.len() + 1 + payload.len());
    signing_input.push_str(&header);
    signing_input.push('.');
    signing_input.push_str(&payload);
    let sig = key.sign(signing_input.as_bytes());
    let sig_b64 =
        zilpay::base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(sig.to_bytes());
    let mut jwt = String::with_capacity(signing_input.len() + 1 + sig_b64.len());
    jwt.push_str(&signing_input);
    jwt.push('.');
    jwt.push_str(&sig_b64);
    Ok(jwt)
}

/// Convenience: iat = now − 60s, ttl = 1 day (reown production defaults).
#[frb(ignore)]
pub fn sign_relay_jwt_now(
    seed: &[u8; 32],
    aud: &str,
    sub_entropy: &[u8; 32],
    now: u64,
) -> Result<String, WcError> {
    let iat = now.saturating_sub(60);
    let sub = zilpay::hex::encode(sub_entropy);
    sign_relay_jwt(seed, aud, &sub, iat, JWT_TTL)
}

/// Verify an EdDSA JWT produced by [`sign_relay_jwt`]. Returns payload iss.
#[frb(ignore)]
pub fn verify_relay_jwt(jwt: &str) -> Result<String, WcError> {
    let mut parts = jwt.split('.');
    let header = parts.next().ok_or(WcError::Crypto("jwt segments"))?;
    let payload = parts.next().ok_or(WcError::Crypto("jwt segments"))?;
    let sig_b64 = parts.next().ok_or(WcError::Crypto("jwt segments"))?;
    if parts.next().is_some() {
        return Err(WcError::Crypto("jwt segments"));
    }
    let mut signing_input = String::with_capacity(header.len() + 1 + payload.len());
    signing_input.push_str(header);
    signing_input.push('.');
    signing_input.push_str(payload);

    let claims_raw = zilpay::base64::engine::general_purpose::URL_SAFE_NO_PAD
        .decode(payload)
        .map_err(|_| WcError::Crypto("jwt payload b64"))?;
    let claims: zilpay::serde_json::Value =
        zilpay::serde_json::from_slice(&claims_raw).map_err(WcError::from)?;
    let iss = claims
        .get("iss")
        .and_then(|v| v.as_str())
        .ok_or(WcError::Crypto("jwt iss"))?;
    let pub_bytes = decode_did_key(iss)?;
    let vk = VerifyingKey::from_bytes(&pub_bytes).map_err(|_| WcError::Crypto("verifying key"))?;
    let sig_bytes = zilpay::base64::engine::general_purpose::URL_SAFE_NO_PAD
        .decode(sig_b64)
        .map_err(|_| WcError::Crypto("jwt sig b64"))?;
    let sig_arr: [u8; 64] = sig_bytes
        .as_slice()
        .try_into()
        .map_err(|_| WcError::Crypto("jwt sig len"))?;
    let sig = zilpay::ed25519_dalek::Signature::from_bytes(&sig_arr);
    vk.verify(signing_input.as_bytes(), &sig)
        .map_err(|_| WcError::Crypto("jwt verify"))?;
    Ok(iss.to_owned())
}

#[frb(ignore)]
fn decode_did_key(iss: &str) -> Result<[u8; 32], WcError> {
    let multicodec = iss
        .strip_prefix("did:key:z")
        .ok_or(WcError::Crypto("did:key prefix"))?;
    let bytes = zilpay::bs58::decode(multicodec)
        .into_vec()
        .map_err(|_| WcError::Crypto("did:key bs58"))?;
    if bytes.len() != 34 || bytes[0] != 0xed || bytes[1] != 0x01 {
        return Err(WcError::Crypto("did:key multicodec"));
    }
    let mut out = [0u8; 32];
    out.copy_from_slice(&bytes[2..]);
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    // From reown_core/test/relay_auth_test.dart
    const TEST_SUBJECT: &str =
        "c479fe5dc464e771e78b193d239a65b58d278cad1c34bfb0b5716e5bb514928e";
    const TEST_AUDIENCE: &str = "wss://relay.walletconnect.com";
    const TEST_IAT: u64 = 1_656_910_097;
    const TEST_TTL: u64 = 86_400;
    const TEST_SEED: &str =
        "58e0254c211b858ef7896b00e3f36beeb13d568d47c6031c4218b87718061295";
    const EXPECTED_ISS: &str = "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH";
    const EXPECTED_JWT: &str = "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkaWQ6a2V5Ono2TWtvZEhad25lVlJTaHRhTGY4SktZa3hwREdwMXZHWm5wR21kQnBYOE0yZXh4SCIsInN1YiI6ImM0NzlmZTVkYzQ2NGU3NzFlNzhiMTkzZDIzOWE2NWI1OGQyNzhjYWQxYzM0YmZiMGI1NzE2ZTViYjUxNDkyOGUiLCJhdWQiOiJ3c3M6Ly9yZWxheS53YWxsZXRjb25uZWN0LmNvbSIsImlhdCI6MTY1NjkxMDA5NywiZXhwIjoxNjU2OTk2NDk3fQ.bAKl1swvwqqV_FgwvD4Bx3Yp987B9gTpZctyBviA-EkAuWc8iI8SyokOjkv9GJESgid4U8Tf2foCgrQp2qrxBA";

    fn seed() -> [u8; 32] {
        let b = zilpay::hex::decode(TEST_SEED).expect("seed");
        let mut a = [0u8; 32];
        a.copy_from_slice(&b);
        a
    }

    #[test]
    fn did_key_matches_fixture() {
        let key = SigningKey::from_bytes(&seed());
        assert_eq!(did_key(key.verifying_key().as_bytes()), EXPECTED_ISS);
    }

    #[test]
    fn sign_jwt_matches_fixture() {
        let jwt = sign_relay_jwt(&seed(), TEST_AUDIENCE, TEST_SUBJECT, TEST_IAT, TEST_TTL)
            .expect("sign");
        assert_eq!(jwt, EXPECTED_JWT);
    }

    #[test]
    fn verify_self_signed_jwt() {
        let jwt = sign_relay_jwt(&seed(), TEST_AUDIENCE, TEST_SUBJECT, TEST_IAT, TEST_TTL)
            .expect("sign");
        let iss = verify_relay_jwt(&jwt).expect("verify");
        assert!(iss.starts_with("did:key:z6Mk"));
        assert_eq!(iss, EXPECTED_ISS);
    }

    #[test]
    fn second_fixture_from_reown() {
        // relay_auth_test.dart jwt1
        const SEED2: &str =
            "db74f4788fbaf87bc8e3cd6a84ae82586fd4fd701216a1d18f7ed936cb3a8cfb";
        const SUB2: &str =
            "6a26d1c13b8f7bfda6e7415f6db94084a3b97f2990da5216fa5aa7b80f08391d";
        const IAT2: u64 = 1_674_244_632;
        const EXPECTED: &str = "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkaWQ6a2V5Ono2TWtrTUhRRlYzYkNUOXVIV3Z6Z1N4UXNMbVZzMVc1c0NVdzhyQnBmamg5ZHNydiIsInN1YiI6IjZhMjZkMWMxM2I4ZjdiZmRhNmU3NDE1ZjZkYjk0MDg0YTNiOTdmMjk5MGRhNTIxNmZhNWFhN2I4MGYwODM5MWQiLCJhdWQiOiJ3c3M6Ly9yZWxheS53YWxsZXRjb25uZWN0LmNvbSIsImlhdCI6MTY3NDI0NDYzMiwiZXhwIjoxNjc0MzMxMDMyfQ.FUfsQtGuyMTOfEjQUdfr_KfBEaftEQPU9lpQ_mNwgpPlzqk2Hmn9RKnbTnvL9rPWzbm5wnWrc7LuzUQGqp99Cw";
        let mut seed = [0u8; 32];
        seed.copy_from_slice(&zilpay::hex::decode(SEED2).expect("seed2"));
        let jwt = sign_relay_jwt(&seed, TEST_AUDIENCE, SUB2, IAT2, TEST_TTL).expect("sign");
        assert_eq!(jwt, EXPECTED);
    }
}
