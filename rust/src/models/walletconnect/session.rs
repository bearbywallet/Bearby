//! Proposal / Session models and namespace conformance validation.

use std::collections::BTreeMap;

use flutter_rust_bridge::frb;
use zilpay::serde::{Deserialize, Serialize};

use super::crypto::KEY_LEN;
use super::error::WcError;
use super::rpc::{Metadata, ProposedNamespace, SettledNamespace};

#[frb(ignore)]
#[derive(Debug, Clone)]
pub struct Proposal {
    pub id: u64,
    pub pairing_topic: String,
    pub proposer_pub: String,
    pub proposer_meta: Metadata,
    pub required: BTreeMap<String, ProposedNamespace>,
    pub optional: BTreeMap<String, ProposedNamespace>,
    pub expiry: u64,
}

#[frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct Session {
    pub topic: String,
    pub pairing_topic: String,
    /// Hex-encoded session symKey.
    pub sym_key_hex: String,
    pub self_pub: String,
    pub peer_pub: String,
    pub peer_meta: Metadata,
    pub namespaces: BTreeMap<String, SettledNamespace>,
    pub expiry: u64,
    pub acknowledged: bool,
}

impl Session {
    #[frb(ignore)]
    pub fn sym_key(&self) -> Result<[u8; KEY_LEN], WcError> {
        super::crypto::decode_hex32(&self.sym_key_hex)
    }

    #[frb(ignore)]
    pub fn is_expired(&self, now: u64) -> bool {
        now >= self.expiry
    }

    /// True if `chain_id` (CAIP-2) is covered by a settled CAIP-10 account
    /// (`{chain_id}:{address}`).
    #[frb(ignore)]
    pub fn supports_chain(&self, chain_id: &str) -> bool {
        // chain_id like "eip155:1" → ns key "eip155"
        let Some((ns, _)) = chain_id.split_once(':') else {
            return false;
        };
        let Some(settled) = self.namespaces.get(ns) else {
            return false;
        };
        let mut prefix = String::with_capacity(chain_id.len() + 1);
        prefix.push_str(chain_id);
        prefix.push(':');
        settled.accounts.iter().any(|acc| acc.starts_with(&prefix))
    }

    #[frb(ignore)]
    pub fn supports_method(&self, chain_id: &str, method: &str) -> bool {
        let Some((ns, _)) = chain_id.split_once(':') else {
            return false;
        };
        self.namespaces
            .get(ns)
            .is_some_and(|s| s.methods.iter().any(|m| m == method))
    }
}

/// Every required namespace key must exist in `approved`; approved accounts must
/// cover every required chain; approved methods/events must be supersets.
#[frb(ignore)]
pub fn conforms(
    required: &BTreeMap<String, ProposedNamespace>,
    approved: &BTreeMap<String, SettledNamespace>,
) -> Result<(), WcError> {
    for (key, req) in required {
        let settled = approved
            .get(key)
            .ok_or(WcError::Namespace("missing required namespace"))?;

        if let Some(chains) = req.chains.as_ref() {
            for chain in chains {
                let prefix = format!("{chain}:");
                let covered = settled.accounts.iter().any(|a| a.starts_with(&prefix));
                if !covered {
                    return Err(WcError::Namespace("missing required chain account"));
                }
            }
        }

        for m in &req.methods {
            if !settled.methods.iter().any(|x| x == m) {
                return Err(WcError::Namespace("missing required method"));
            }
        }
        for e in &req.events {
            if !settled.events.iter().any(|x| x == e) {
                return Err(WcError::Namespace("missing required event"));
            }
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn req(chains: &[&str], methods: &[&str], events: &[&str]) -> ProposedNamespace {
        ProposedNamespace {
            chains: Some(chains.iter().map(|s| (*s).to_owned()).collect()),
            methods: methods.iter().map(|s| (*s).to_owned()).collect(),
            events: events.iter().map(|s| (*s).to_owned()).collect(),
        }
    }

    fn settled(accounts: &[&str], methods: &[&str], events: &[&str]) -> SettledNamespace {
        SettledNamespace {
            chains: accounts
                .iter()
                .filter_map(|a| {
                    let mut it = a.splitn(3, ':');
                    match (it.next(), it.next(), it.next()) {
                        (Some(ns), Some(r), Some(_)) => Some(format!("{ns}:{r}")),
                        _ => None,
                    }
                })
                .collect(),
            accounts: accounts.iter().map(|s| (*s).to_owned()).collect(),
            methods: methods.iter().map(|s| (*s).to_owned()).collect(),
            events: events.iter().map(|s| (*s).to_owned()).collect(),
        }
    }

    #[test]
    fn conforms_ok() {
        let mut required = BTreeMap::new();
        required.insert(
            "eip155".to_owned(),
            req(&["eip155:1"], &["personal_sign"], &["chainChanged"]),
        );
        let mut approved = BTreeMap::new();
        approved.insert(
            "eip155".to_owned(),
            settled(
                &["eip155:1:0xabc"],
                &["personal_sign", "eth_sign"],
                &["chainChanged", "accountsChanged"],
            ),
        );
        assert!(conforms(&required, &approved).is_ok());
    }

    #[test]
    fn conforms_missing_method() {
        let mut required = BTreeMap::new();
        required.insert(
            "eip155".to_owned(),
            req(&["eip155:1"], &["personal_sign", "eth_sendTransaction"], &[]),
        );
        let mut approved = BTreeMap::new();
        approved.insert(
            "eip155".to_owned(),
            settled(&["eip155:1:0xabc"], &["personal_sign"], &[]),
        );
        assert!(matches!(
            conforms(&required, &approved),
            Err(WcError::Namespace("missing required method"))
        ));
    }

    #[test]
    fn conforms_missing_chain() {
        let mut required = BTreeMap::new();
        required.insert(
            "eip155".to_owned(),
            req(&["eip155:1", "eip155:56"], &[], &[]),
        );
        let mut approved = BTreeMap::new();
        approved.insert(
            "eip155".to_owned(),
            settled(&["eip155:1:0xabc"], &[], &[]),
        );
        assert!(matches!(
            conforms(&required, &approved),
            Err(WcError::Namespace("missing required chain account"))
        ));
    }
}
