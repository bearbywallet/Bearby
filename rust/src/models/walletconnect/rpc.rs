//! JSON-RPC 2.0 wire types, wc_* payload structs, method tags/TTLs, payload_id.
//! Field names match reown `json_rpc_models.dart` (camelCase on the wire).

use std::collections::BTreeMap;

use flutter_rust_bridge::frb;
use zilpay::rand::Rng;
use zilpay::serde::{Deserialize, Serialize};
use zilpay::serde_json::value::RawValue;

// ── Time constants (reown method_constants.dart) ──────────────────────────

#[frb(ignore)]
pub const FIVE_MINUTES: u64 = 300;
#[frb(ignore)]
pub const ONE_DAY: u64 = 86_400;
#[frb(ignore)]
pub const SEVEN_DAYS: u64 = 604_800;
#[frb(ignore)]
pub const THIRTY_DAYS: u64 = 2_592_000;
#[frb(ignore)]
pub const THIRTY_SECONDS: u64 = 30;

// ── Method options ────────────────────────────────────────────────────────

#[frb(ignore)]
#[derive(Debug, Clone, Copy)]
pub struct MethodOpts {
    pub req_tag: u32,
    pub res_tag: u32,
    pub req_ttl: u64,
    pub res_ttl: u64,
    pub prompt: bool,
}

#[frb(ignore)]
pub const SESSION_PROPOSE: MethodOpts = MethodOpts {
    req_tag: 1100,
    res_tag: 1101,
    req_ttl: FIVE_MINUTES,
    res_ttl: FIVE_MINUTES,
    prompt: true,
};
#[frb(ignore)]
pub const PROPOSE_REJECT_TAG: u32 = 1120;
#[frb(ignore)]
pub const SESSION_SETTLE: MethodOpts = MethodOpts {
    req_tag: 1102,
    res_tag: 1103,
    req_ttl: FIVE_MINUTES,
    res_ttl: FIVE_MINUTES,
    prompt: false,
};
#[frb(ignore)]
pub const SESSION_UPDATE: MethodOpts = MethodOpts {
    req_tag: 1104,
    res_tag: 1105,
    req_ttl: ONE_DAY,
    res_ttl: ONE_DAY,
    prompt: false,
};
#[frb(ignore)]
pub const SESSION_EXTEND: MethodOpts = MethodOpts {
    req_tag: 1106,
    res_tag: 1107,
    req_ttl: ONE_DAY,
    res_ttl: ONE_DAY,
    prompt: false,
};
#[frb(ignore)]
pub const SESSION_REQUEST: MethodOpts = MethodOpts {
    req_tag: 1108,
    res_tag: 1109,
    req_ttl: FIVE_MINUTES,
    res_ttl: FIVE_MINUTES,
    prompt: true,
};
#[frb(ignore)]
pub const SESSION_EVENT: MethodOpts = MethodOpts {
    req_tag: 1110,
    res_tag: 1111,
    req_ttl: FIVE_MINUTES,
    res_ttl: FIVE_MINUTES,
    prompt: true,
};
#[frb(ignore)]
pub const SESSION_DELETE: MethodOpts = MethodOpts {
    req_tag: 1112,
    res_tag: 1113,
    req_ttl: ONE_DAY,
    res_ttl: ONE_DAY,
    prompt: false,
};
#[frb(ignore)]
pub const SESSION_PING: MethodOpts = MethodOpts {
    req_tag: 1114,
    res_tag: 1115,
    req_ttl: THIRTY_SECONDS,
    res_ttl: THIRTY_SECONDS,
    prompt: false,
};

/// reown `JsonRpcUtils.payloadId`: `now_ms * 10^entropy + rand(10^entropy)`.
#[frb(ignore)]
pub fn payload_id(entropy: u32, now_ms: u64, rng: &mut impl Rng) -> u64 {
    let zeros = 10u64.pow(entropy);
    now_ms.saturating_mul(zeros).saturating_add(rng.next_u64() % zeros)
}

// ── JSON-RPC envelopes ────────────────────────────────────────────────────

#[frb(ignore)]
#[derive(Debug, Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct RpcRequest {
    pub id: u64,
    pub jsonrpc: String,
    pub method: String,
    pub params: Box<RawValue>,
}

#[frb(ignore)]
#[derive(Debug, Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct RpcErrorBody {
    pub code: i64,
    pub message: String,
}

#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde")]
pub struct RpcSuccess<T: Serialize> {
    pub id: u64,
    pub jsonrpc: &'static str,
    pub result: T,
}

#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde")]
pub struct RpcFailure {
    pub id: u64,
    pub jsonrpc: &'static str,
    pub error: RpcErrorBody,
}

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct RpcResponseWire {
    pub id: u64,
    #[serde(default)]
    pub result: Option<Box<RawValue>>,
    #[serde(default)]
    pub error: Option<RpcErrorBody>,
}

#[frb(ignore)]
pub fn rpc_ok<T: Serialize>(id: u64, result: T) -> RpcSuccess<T> {
    RpcSuccess {
        id,
        jsonrpc: "2.0",
        result,
    }
}

#[frb(ignore)]
pub fn rpc_err(id: u64, code: i64, message: impl Into<String>) -> RpcFailure {
    RpcFailure {
        id,
        jsonrpc: "2.0",
        error: RpcErrorBody {
            code,
            message: message.into(),
        },
    }
}

// ── wc_* payload types ────────────────────────────────────────────────────

#[frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub struct Relay {
    pub protocol: String,
}

impl Relay {
    #[frb(ignore)]
    pub fn irn() -> Self {
        Self {
            protocol: "irn".to_owned(),
        }
    }
}

#[frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub struct Metadata {
    pub name: String,
    pub description: String,
    pub url: String,
    pub icons: Vec<String>,
}

#[frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub struct Participant {
    #[serde(rename = "publicKey")]
    pub public_key: String,
    pub metadata: Metadata,
}

#[frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub struct ProposedNamespace {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub chains: Option<Vec<String>>,
    #[serde(default)]
    pub methods: Vec<String>,
    #[serde(default)]
    pub events: Vec<String>,
}

#[frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub struct SettledNamespace {
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub chains: Vec<String>,
    pub accounts: Vec<String>,
    pub methods: Vec<String>,
    pub events: Vec<String>,
}

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct SessionProposeParams {
    pub relays: Vec<Relay>,
    #[serde(rename = "requiredNamespaces", default)]
    pub required_namespaces: BTreeMap<String, ProposedNamespace>,
    #[serde(rename = "optionalNamespaces", default)]
    pub optional_namespaces: BTreeMap<String, ProposedNamespace>,
    #[serde(rename = "sessionProperties", default)]
    pub session_properties: Option<BTreeMap<String, String>>,
    pub proposer: Participant,
}

#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde")]
pub struct SessionProposeResult {
    pub relay: Relay,
    #[serde(rename = "responderPublicKey")]
    pub responder_public_key: String,
}

#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde")]
pub struct SessionSettleParams {
    pub relay: Relay,
    pub namespaces: BTreeMap<String, SettledNamespace>,
    pub controller: Participant,
    pub expiry: u64,
}

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct SessionRequestParams {
    #[serde(rename = "chainId")]
    pub chain_id: String,
    pub request: SessionRequestBody,
}

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct SessionRequestBody {
    pub method: String,
    pub params: Box<RawValue>,
    #[serde(rename = "expiryTimestamp", default)]
    pub expiry_timestamp: Option<u64>,
}

#[frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct SessionDeleteParams {
    pub code: i64,
    pub message: String,
}

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct SessionUpdateParams {
    pub namespaces: BTreeMap<String, SettledNamespace>,
}

#[frb(ignore)]
#[derive(Debug, Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct SessionEventParams {
    #[serde(rename = "chainId")]
    pub chain_id: String,
    pub event: SessionEventBody,
}

#[frb(ignore)]
#[derive(Debug, Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct SessionEventBody {
    pub name: String,
    /// Opaque JSON (array of addresses for `accountsChanged`, chain id for `chainChanged`, …).
    pub data: Box<RawValue>,
}

// ── Relay IRN JSON-RPC params ─────────────────────────────────────────────

#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde")]
pub struct IrnPublishParams<'a> {
    pub topic: &'a str,
    pub message: &'a str,
    pub ttl: u64,
    pub tag: u32,
    pub prompt: bool,
}

#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde")]
pub struct IrnSubscribeParams<'a> {
    pub topic: &'a str,
}

#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde")]
pub struct IrnUnsubscribeParams<'a> {
    pub topic: &'a str,
    pub id: &'a str,
}

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct IrnSubscriptionParams {
    pub id: String,
    pub data: IrnSubscriptionData,
}

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct IrnSubscriptionData {
    pub topic: String,
    pub message: String,
    #[serde(default)]
    pub attestation: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use zilpay::rand::rng;

    #[test]
    fn payload_id_shape() {
        let mut rng = rng();
        let now_ms = 1_700_000_000_000u64;
        let id = payload_id(3, now_ms, &mut rng);
        // id = now_ms * 1000 + r where r < 1000
        assert!(id >= now_ms * 1000);
        assert!(id < now_ms * 1000 + 1000);
    }

    #[test]
    fn payload_id_entropy_6() {
        let mut rng = rng();
        let now_ms = 1_700_000_000_000u64;
        let id = payload_id(6, now_ms, &mut rng);
        let zeros = 1_000_000u64;
        assert!(id >= now_ms * zeros);
        assert!(id < now_ms * zeros + zeros);
    }
}
