//! FRB-visible mirror structs for WalletConnect (Dart-facing).

use std::collections::BTreeMap;

use super::engine::WcEvent;
use super::rpc::{ProposedNamespace, SettledNamespace};
use super::session::{Proposal, Session};

pub struct WcSessionInfo {
    pub topic: String,
    pub peer_name: String,
    pub peer_description: String,
    pub peer_url: String,
    pub peer_icon: Option<String>,
    pub accounts: Vec<String>,
    pub methods: Vec<String>,
    pub events: Vec<String>,
    pub expiry: u64,
}

pub struct WcNamespaceInfo {
    pub key: String,
    pub chains: Vec<String>,
    pub methods: Vec<String>,
    pub events: Vec<String>,
}

pub struct WcProposalInfo {
    pub id: u64,
    pub pairing_topic: String,
    pub peer_name: String,
    pub peer_description: String,
    pub peer_url: String,
    pub peer_icon: Option<String>,
    pub required: Vec<WcNamespaceInfo>,
    pub optional: Vec<WcNamespaceInfo>,
}

pub struct WcRequestInfo {
    pub topic: String,
    pub id: u64,
    pub chain_id: String,
    pub method: String,
    pub params_json: String,
    pub peer_name: String,
    pub peer_icon: Option<String>,
}

/// Built by Flutter when approving a session.
pub struct WcNamespaceApproval {
    pub key: String,
    pub accounts: Vec<String>,
    pub methods: Vec<String>,
    pub events: Vec<String>,
}

pub enum WcEventInfo {
    Proposal(WcProposalInfo),
    Request(WcRequestInfo),
    SessionSettled { topic: String },
    SessionDeleted { topic: String, message: String },
    SessionEvent {
        topic: String,
        chain_id: String,
        name: String,
        data: String,
    },
    RelayConnected,
    RelayDisconnected,
    Error { message: String },
}

impl From<&Session> for WcSessionInfo {
    fn from(s: &Session) -> Self {
        let mut accounts = Vec::new();
        let mut methods = Vec::new();
        let mut events = Vec::new();
        for ns in s.namespaces.values() {
            accounts.extend(ns.accounts.iter().cloned());
            for m in &ns.methods {
                if !methods.iter().any(|x| x == m) {
                    methods.push(m.clone());
                }
            }
            for e in &ns.events {
                if !events.iter().any(|x| x == e) {
                    events.push(e.clone());
                }
            }
        }
        WcSessionInfo {
            topic: s.topic.clone(),
            peer_name: s.peer_meta.name.clone(),
            peer_description: s.peer_meta.description.clone(),
            peer_url: s.peer_meta.url.clone(),
            peer_icon: s.peer_meta.icons.first().cloned(),
            accounts,
            methods,
            events,
            expiry: s.expiry,
        }
    }
}

fn namespaces_to_info(
    map: &BTreeMap<String, ProposedNamespace>,
) -> Vec<WcNamespaceInfo> {
    let mut out = Vec::with_capacity(map.len());
    for (key, ns) in map {
        out.push(WcNamespaceInfo {
            key: key.clone(),
            chains: ns.chains.clone().unwrap_or_default(),
            methods: ns.methods.clone(),
            events: ns.events.clone(),
        });
    }
    out
}

impl From<&Proposal> for WcProposalInfo {
    fn from(p: &Proposal) -> Self {
        WcProposalInfo {
            id: p.id,
            pairing_topic: p.pairing_topic.clone(),
            peer_name: p.proposer_meta.name.clone(),
            peer_description: p.proposer_meta.description.clone(),
            peer_url: p.proposer_meta.url.clone(),
            peer_icon: p.proposer_meta.icons.first().cloned(),
            required: namespaces_to_info(&p.required),
            optional: namespaces_to_info(&p.optional),
        }
    }
}

impl From<WcEvent> for WcEventInfo {
    fn from(ev: WcEvent) -> Self {
        match ev {
            WcEvent::Proposal(p) => WcEventInfo::Proposal((&p).into()),
            WcEvent::Request {
                topic,
                id,
                chain_id,
                method,
                params,
                peer,
            } => WcEventInfo::Request(WcRequestInfo {
                topic,
                id,
                chain_id,
                method,
                params_json: params,
                peer_name: peer.name,
                peer_icon: peer.icons.into_iter().next(),
            }),
            WcEvent::SessionSettled { topic } => WcEventInfo::SessionSettled { topic },
            WcEvent::SessionDeleted {
                topic,
                message,
                ..
            } => WcEventInfo::SessionDeleted { topic, message },
            WcEvent::SessionEvent {
                topic,
                chain_id,
                name,
                data,
            } => WcEventInfo::SessionEvent {
                topic,
                chain_id,
                name,
                data,
            },
            WcEvent::RelayConnected => WcEventInfo::RelayConnected,
            WcEvent::RelayDisconnected => WcEventInfo::RelayDisconnected,
            WcEvent::Error(message) => WcEventInfo::Error { message },
        }
    }
}

impl From<WcNamespaceApproval> for (String, SettledNamespace) {
    fn from(a: WcNamespaceApproval) -> Self {
        (
            a.key,
            SettledNamespace {
                accounts: a.accounts,
                methods: a.methods,
                events: a.events,
            },
        )
    }
}

/// Convert a list of approvals into a BTreeMap of settled namespaces.
pub fn approvals_to_namespaces(
    approvals: Vec<WcNamespaceApproval>,
) -> BTreeMap<String, SettledNamespace> {
    let mut map = BTreeMap::new();
    for a in approvals {
        let (k, v) = a.into();
        map.insert(k, v);
    }
    map
}
