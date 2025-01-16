pub use zilpay::proto::keypair::KeyPair;

pub struct KeyPairInfo {
    pub sk: String,
    pub pk: String,
}

impl From<KeyPair> for KeyPairInfo {
    fn from(value: KeyPair) -> Self {
        match value {
            KeyPair::Secp256k1Sha256Zilliqa((pk, sk)) => Self {
                sk: hex::encode(sk),
                pk: hex::encode(pk),
            },
            KeyPair::Secp256k1Keccak256Ethereum((pk, sk)) => Self {
                sk: hex::encode(sk),
                pk: hex::encode(pk),
            },
        }
    }
}
