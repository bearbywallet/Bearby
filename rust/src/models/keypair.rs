pub use zilpay::proto::keypair::KeyPair;

pub struct KeyPairInfo {
    pub sk: String,
    pub pk: String,
}

impl From<KeyPair> for KeyPairInfo {
    fn from(value: KeyPair) -> Self {
        match value {
            KeyPair::Secp256k1Sha256((pk, sk)) => Self {
                sk: hex::encode(sk),
                pk: hex::encode(pk),
            },
            KeyPair::Secp256k1Keccak256((pk, sk)) => Self {
                sk: hex::encode(sk),
                pk: hex::encode(pk),
            },
            KeyPair::Secp256k1Bitcoin((pk, sk, _, _)) => Self {
                sk: hex::encode(sk),
                pk: hex::encode(pk),
            },
        }
    }
}
