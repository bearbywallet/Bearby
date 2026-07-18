//! x25519 key agreement, HKDF-SHA256 symKey, topic hash, ChaCha20-Poly1305 envelopes.
//! Wire format matches reown_core `crypto_utils.dart`.

use flutter_rust_bridge::frb;
use zilpay::base64::Engine;
use zilpay::chacha20poly1305::{
    aead::{Aead, KeyInit},
    ChaCha20Poly1305, Key, Nonce,
};
use zilpay::hkdf::Hkdf;
use zilpay::rand::Rng;
use zilpay::sha2::{Digest, Sha256};
use zilpay::x25519_dalek::{PublicKey, StaticSecret};

use super::error::WcError;

#[frb(ignore)]
pub const KEY_LEN: usize = 32;
#[frb(ignore)]
pub const NONCE_LEN: usize = 12;

const TYPE_0: u8 = 0;
const TYPE_1: u8 = 1;

#[frb(ignore)]
pub struct KeyPair {
    pub secret: StaticSecret,
    pub public: PublicKey,
}

impl KeyPair {
    /// Generate a fresh x25519 keypair from OS RNG (seeded via workspace rand).
    #[frb(ignore)]
    pub fn generate(rng: &mut impl Rng) -> Self {
        let mut seed = [0u8; KEY_LEN];
        rng.fill_bytes(&mut seed);
        Self::from_seed(seed)
    }

    #[frb(ignore)]
    pub fn from_seed(seed: [u8; KEY_LEN]) -> Self {
        let secret = StaticSecret::from(seed);
        let public = PublicKey::from(&secret);
        Self { secret, public }
    }

    #[frb(ignore)]
    pub fn public_hex(&self) -> String {
        zilpay::hex::encode(self.public.as_bytes())
    }
}

/// `symKey = HKDF-SHA256(ikm = X25519(priv, peer_pub), salt = ∅, info = ∅, L = 32)`.
#[frb(ignore)]
pub fn derive_sym_key(
    secret: &StaticSecret,
    peer_pub: &[u8; KEY_LEN],
) -> Result<[u8; KEY_LEN], WcError> {
    let shared = secret.diffie_hellman(&PublicKey::from(*peer_pub));
    let hk = Hkdf::<Sha256>::new(None, shared.as_bytes());
    let mut out = [0u8; KEY_LEN];
    hk.expand(&[], &mut out)
        .map_err(|_| WcError::Crypto("hkdf expand"))?;
    Ok(out)
}

/// `topic = hex(sha256(sym_key))`.
#[frb(ignore)]
pub fn topic_of(sym_key: &[u8; KEY_LEN]) -> String {
    zilpay::hex::encode(Sha256::digest(sym_key))
}

/// Hash an arbitrary message (utf-8) with sha256 — used by crypto test vectors.
#[frb(ignore)]
pub fn hash_message(message: &str) -> String {
    zilpay::hex::encode(Sha256::digest(message.as_bytes()))
}

/// Envelope type0: `base64(0x00 || nonce || ct || tag)`.
/// Type1 inserts sender x25519 pub after the type byte.
#[frb(ignore)]
pub fn seal(
    sym_key: &[u8; KEY_LEN],
    plaintext: &[u8],
    sender_pub: Option<&[u8; KEY_LEN]>,
    rng: &mut impl Rng,
) -> Result<String, WcError> {
    seal_with_nonce(sym_key, plaintext, sender_pub, None, rng)
}

/// Like [`seal`] but allows a fixed nonce for fixture tests.
#[frb(ignore)]
pub fn seal_with_nonce(
    sym_key: &[u8; KEY_LEN],
    plaintext: &[u8],
    sender_pub: Option<&[u8; KEY_LEN]>,
    fixed_nonce: Option<[u8; NONCE_LEN]>,
    rng: &mut impl Rng,
) -> Result<String, WcError> {
    let key = Key::from(*sym_key);
    let cipher = ChaCha20Poly1305::new(&key);
    let nonce_bytes = match fixed_nonce {
        Some(n) => n,
        None => {
            let mut n = [0u8; NONCE_LEN];
            rng.fill_bytes(&mut n);
            n
        }
    };
    let nonce = Nonce::from(nonce_bytes);
    let ct = cipher
        .encrypt(&nonce, plaintext)
        .map_err(|_| WcError::Crypto("encrypt"))?;

    let header_len = match sender_pub {
        Some(_) => 1 + KEY_LEN,
        None => 1,
    };
    let mut out = Vec::with_capacity(header_len + NONCE_LEN + ct.len());
    match sender_pub {
        Some(pk) => {
            out.push(TYPE_1);
            out.extend_from_slice(pk);
        }
        None => out.push(TYPE_0),
    }
    out.extend_from_slice(&nonce_bytes);
    out.extend_from_slice(&ct);
    Ok(zilpay::base64::engine::general_purpose::STANDARD.encode(out))
}

#[frb(ignore)]
pub struct Opened {
    pub plaintext: Vec<u8>,
    pub sender_pub: Option<[u8; KEY_LEN]>,
}

#[frb(ignore)]
pub fn open(sym_key: &[u8; KEY_LEN], envelope: &str) -> Result<Opened, WcError> {
    let raw = zilpay::base64::engine::general_purpose::STANDARD
        .decode(envelope)
        .map_err(|_| WcError::Crypto("base64"))?;
    let (env_type, rest) = raw
        .split_first()
        .ok_or(WcError::Crypto("empty envelope"))?;
    let (sender_pub, sealed) = match *env_type {
        TYPE_0 => (None, rest),
        TYPE_1 => {
            let (pk, sealed) = rest
                .split_at_checked(KEY_LEN)
                .ok_or(WcError::Crypto("short type1"))?;
            let mut arr = [0u8; KEY_LEN];
            arr.copy_from_slice(pk);
            (Some(arr), sealed)
        }
        _ => return Err(WcError::Crypto("unsupported envelope type")),
    };
    let (nonce_bytes, ct) = sealed
        .split_at_checked(NONCE_LEN)
        .ok_or(WcError::Crypto("short sealed"))?;
    let mut nonce_arr = [0u8; NONCE_LEN];
    nonce_arr.copy_from_slice(nonce_bytes);
    let key = Key::from(*sym_key);
    let cipher = ChaCha20Poly1305::new(&key);
    let nonce = Nonce::from(nonce_arr);
    let plaintext = cipher
        .decrypt(&nonce, ct)
        .map_err(|_| WcError::Crypto("decrypt"))?;
    Ok(Opened {
        plaintext,
        sender_pub,
    })
}

/// Decode a 32-byte hex key (optional `0x` prefix).
#[frb(ignore)]
pub fn decode_hex32(hex_str: &str) -> Result<[u8; KEY_LEN], WcError> {
    let s = hex_str.strip_prefix("0x").unwrap_or(hex_str);
    let bytes = zilpay::hex::decode(s).map_err(|_| WcError::Crypto("hex decode"))?;
    <[u8; KEY_LEN]>::try_from(bytes.as_slice()).map_err(|_| WcError::Crypto("key length"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use zilpay::rand::rng;

    // Fixtures from reown_core/test/shared/shared_test_values.dart + crypto_test.dart
    const TEST_SELF_PRIV: &str =
        "1fb63fca5c6ac731246f2f069d3bc2454345d5208254aa8ea7bffc6d110c8862";
    const TEST_SELF_PUB: &str =
        "ff7a7d5767c362b0a17ad92299ebdb7831dcbd9a56959c01368c7404543b3342";
    const TEST_PEER_PRIV: &str =
        "36bf507903537de91f5e573666eaa69b1fa313974f23b2b59645f20fea505854";
    const TEST_PEER_PUB: &str =
        "590c2c627be7af08597091ff80dd41f7fa28acd10ef7191d7e830e116d3a186a";
    const TEST_SHARED_KEY: &str =
        "9c87e48e69b33a613907515bcd5b1b4cc10bbaf15167b19804b00f0a9217e607";
    const TEST_HASHED_KEY: &str =
        "a492906ccc809a411bb53a84572b57329375378c6ad7566f3e1c688200123e77";
    const TEST_SYM_KEY: &str =
        "0653ca620c7b4990392e1c53c4a51c14a2840cd20f0f1524cf435b17b6fe988c";
    const TEST_IV: &str = "717765636661617364616473";
    const TEST_ENCODED_TYPE_0: &str =
        "AHF3ZWNmYWFzZGFkc3paHoQ96/mLAdanVxi17icRXq+jyrqXA8ocVgGmryQZBFMg+uwgc8yLa43EOeY+IWEv84g8hn4L3Ncsgz6397sgNKnsNcL7A9k3Mg==";
    const TEST_ENCODED_TYPE_1: &str =
        "Af96fVdnw2KwoXrZIpnr23gx3L2aVpWcATaMdARUOzNCcXdlY2ZhYXNkYWRzeloehD3r+YsB1qdXGLXuJxFer6PKupcDyhxWAaavJBkEUyD67CBzzItrjcQ55j4hYS/ziDyGfgvc1yyDPrf3uyA0qew1wvsD2Tcy";
    const TEST_MESSAGE: &str =
        r#"{"id":1,"jsonrpc":"2.0","method":"test_method","params":{}}"#;
    const TEST_HASHED_MESSAGE: &str =
        "15112289b5b794e68d1ea3cd91330db55582a37d0596f7b99ea8becdf9d10496";

    fn hex32(s: &str) -> [u8; KEY_LEN] {
        decode_hex32(s).expect("fixture hex")
    }

    #[test]
    fn derive_sym_key_is_symmetric() {
        let a = KeyPair::from_seed(hex32(TEST_SELF_PRIV));
        let b = KeyPair::from_seed(hex32(TEST_PEER_PRIV));
        let ab = derive_sym_key(&a.secret, b.public.as_bytes()).expect("ab");
        let ba = derive_sym_key(&b.secret, a.public.as_bytes()).expect("ba");
        assert_eq!(ab, ba);
        assert_eq!(zilpay::hex::encode(ab), TEST_SYM_KEY);
    }

    #[test]
    fn public_keys_match_fixtures() {
        let a = KeyPair::from_seed(hex32(TEST_SELF_PRIV));
        let b = KeyPair::from_seed(hex32(TEST_PEER_PRIV));
        assert_eq!(a.public_hex(), TEST_SELF_PUB);
        assert_eq!(b.public_hex(), TEST_PEER_PUB);
    }

    #[test]
    fn hash_key_matches_fixture() {
        let key = hex32(TEST_SHARED_KEY);
        assert_eq!(topic_of(&key), TEST_HASHED_KEY);
    }

    #[test]
    fn hash_message_matches_fixture() {
        assert_eq!(hash_message(TEST_MESSAGE), TEST_HASHED_MESSAGE);
    }

    #[test]
    fn decrypt_type0_fixture() {
        let sym = hex32(TEST_SYM_KEY);
        let opened = open(&sym, TEST_ENCODED_TYPE_0).expect("open type0");
        assert_eq!(
            String::from_utf8(opened.plaintext).expect("utf8"),
            TEST_MESSAGE
        );
        assert!(opened.sender_pub.is_none());
    }

    #[test]
    fn decrypt_type1_fixture() {
        let sym = hex32(TEST_SYM_KEY);
        let opened = open(&sym, TEST_ENCODED_TYPE_1).expect("open type1");
        assert_eq!(
            String::from_utf8(opened.plaintext).expect("utf8"),
            TEST_MESSAGE
        );
        let sender = opened.sender_pub.expect("sender");
        assert_eq!(zilpay::hex::encode(sender), TEST_SELF_PUB);
    }

    #[test]
    fn encrypt_type0_matches_fixture() {
        let sym = hex32(TEST_SYM_KEY);
        let mut iv = [0u8; NONCE_LEN];
        iv.copy_from_slice(&zilpay::hex::decode(TEST_IV).expect("iv"));
        let mut rng = rng();
        let encoded = seal_with_nonce(&sym, TEST_MESSAGE.as_bytes(), None, Some(iv), &mut rng)
            .expect("seal");
        assert_eq!(encoded, TEST_ENCODED_TYPE_0);
    }

    #[test]
    fn encrypt_type1_matches_fixture() {
        let sym = hex32(TEST_SYM_KEY);
        let sender = hex32(TEST_SELF_PUB);
        let mut iv = [0u8; NONCE_LEN];
        iv.copy_from_slice(&zilpay::hex::decode(TEST_IV).expect("iv"));
        let mut rng = rng();
        let encoded = seal_with_nonce(
            &sym,
            TEST_MESSAGE.as_bytes(),
            Some(&sender),
            Some(iv),
            &mut rng,
        )
        .expect("seal type1");
        assert_eq!(encoded, TEST_ENCODED_TYPE_1);
    }

    #[test]
    fn seal_open_roundtrip_type0() {
        let mut rng = rng();
        let mut sym = [0u8; KEY_LEN];
        rng.fill_bytes(&mut sym);
        let msg = br#"{"id":42,"jsonrpc":"2.0","result":true}"#;
        let env = seal(&sym, msg, None, &mut rng).expect("seal");
        let opened = open(&sym, &env).expect("open");
        assert_eq!(opened.plaintext, msg);
        assert!(opened.sender_pub.is_none());
    }

    #[test]
    fn seal_open_roundtrip_type1() {
        let mut rng = rng();
        let kp = KeyPair::generate(&mut rng);
        let mut sym = [0u8; KEY_LEN];
        rng.fill_bytes(&mut sym);
        let msg = b"hello walletconnect";
        let env = seal(&sym, msg, Some(kp.public.as_bytes()), &mut rng).expect("seal");
        let opened = open(&sym, &env).expect("open");
        assert_eq!(opened.plaintext, msg);
        assert_eq!(opened.sender_pub.as_ref(), Some(kp.public.as_bytes()));
    }
}
