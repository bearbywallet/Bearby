//! Wallet-side WalletConnect v2 sign engine: pair, approve/reject, request/respond.

use std::collections::BTreeMap;
use std::sync::Arc;

use flutter_rust_bridge::frb;
use zilpay::serde::Serialize;
use zilpay::serde_json;
use zilpay::storage::LocalStorage;
use zilpay::tokio::sync::{mpsc, Mutex};

use super::crypto::{self, KeyPair, KEY_LEN};
use super::error::WcError;
use super::pairing::{PairingUri, StoredPairing};
use super::relay::{Inbound, RelayConfig, RelayHandle, RelayStatus, spawn_relay};
use super::rpc::{
    self, rpc_err, rpc_ok, Metadata, MethodOpts, Participant, Relay, RpcRequest, RpcResponseWire,
    SessionDeleteParams, SessionEventBody, SessionEventParams, SessionProposeParams,
    SessionProposeResult, SessionRequestParams, SessionSettleParams, SessionUpdateParams,
    SettledNamespace,
    PROPOSE_REJECT_TAG, SESSION_DELETE, SESSION_EVENT, SESSION_EXTEND, SESSION_PING,
    SESSION_PROPOSE, SESSION_REQUEST, SESSION_SETTLE, SESSION_UPDATE, SEVEN_DAYS,
};
use super::session::{self, Proposal, Session};
use super::store::{self, now_ms, now_secs, WcState};

/// Prefix logs so they show up clearly in `flutter run` / logcat.
macro_rules! wc_log {
    ($($arg:tt)*) => {{
        eprintln!("[wc] {}", format!($($arg)*));
    }};
}

fn topic_short(topic: &str) -> &str {
    topic.get(..12).unwrap_or(topic)
}

#[frb(ignore)]
#[derive(Debug, Clone)]
pub enum WcEvent {
    Proposal(Proposal),
    Request {
        topic: String,
        id: u64,
        chain_id: String,
        method: String,
        params: String,
        peer: Metadata,
    },
    SessionSettled {
        topic: String,
    },
    SessionDeleted {
        topic: String,
        code: i64,
        message: String,
    },
    SessionEvent {
        topic: String,
        chain_id: String,
        name: String,
        data: String,
    },
    RelayConnected,
    RelayDisconnected,
    Error(String),
}

struct PendingProposal {
    proposal: Proposal,
    pairing_topic: String,
}

#[frb(ignore)]
pub struct WcEngine {
    relay: RelayHandle,
    state: Mutex<WcState>,
    storage: Arc<LocalStorage>,
    self_meta: Metadata,
    pending: Mutex<BTreeMap<u64, PendingProposal>>,
    event_tx: mpsc::Sender<WcEvent>,
}

impl WcEngine {
    #[frb(ignore)]
    pub async fn start(
        project_id: String,
        package_name: String,
        platform: String,
        self_meta: Metadata,
        storage: Arc<LocalStorage>,
        event_tx: mpsc::Sender<WcEvent>,
    ) -> Result<Arc<Self>, WcError> {
        let mut state = store::load_from_core(&storage)?;
        let now = now_secs();
        state.prune_expired(now);
        store::save_to_core(&storage, &state)?;

        let mut topics = Vec::with_capacity(state.pairings.len() + state.sessions.len());
        topics.extend(state.pairings.keys().cloned());
        topics.extend(state.sessions.keys().cloned());

        let cfg = RelayConfig {
            project_id,
            relay_url: "wss://relay.walletconnect.org".to_owned(),
            client_seed: state.client_seed,
            package_name,
            platform,
        };
        let (relay, inbound_rx, status_rx) = spawn_relay(cfg, topics);

        let engine = Arc::new(Self {
            relay,
            state: Mutex::new(state),
            storage,
            self_meta,
            pending: Mutex::new(BTreeMap::new()),
            event_tx: event_tx.clone(),
        });

        let eng = Arc::clone(&engine);
        zilpay::tokio::spawn(async move {
            eng.dispatch_loop(inbound_rx).await;
        });
        let eng2 = Arc::clone(&engine);
        zilpay::tokio::spawn(async move {
            eng2.status_loop(status_rx).await;
        });

        Ok(engine)
    }

    async fn status_loop(self: Arc<Self>, mut rx: mpsc::Receiver<RelayStatus>) {
        while let Some(s) = rx.recv().await {
            let ev = match s {
                RelayStatus::Connected => WcEvent::RelayConnected,
                RelayStatus::Disconnected => WcEvent::RelayDisconnected,
                RelayStatus::Fatal(m) => WcEvent::Error(m),
            };
            let _ = self.event_tx.send(ev).await;
        }
    }

    async fn dispatch_loop(self: Arc<Self>, mut rx: mpsc::Receiver<Inbound>) {
        while let Some(inbound) = rx.recv().await {
            if let Err(e) = self.dispatch(inbound).await {
                let _ = self.event_tx.send(WcEvent::Error(e.to_string())).await;
            }
        }
    }

    async fn dispatch(&self, inbound: Inbound) -> Result<(), WcError> {
        let sym_key = self.key_for_topic(&inbound.topic).await?;
        let opened = crypto::open(&sym_key, &inbound.message)?;
        // Request has "method"; response does not.
        match serde_json::from_slice::<RpcRequest>(&opened.plaintext) {
            Ok(req) if !req.method.is_empty() => match req.method.as_str() {
                "wc_sessionPropose" => self.on_propose(&inbound.topic, req).await,
                "wc_sessionRequest" => self.on_request(&inbound.topic, req).await,
                "wc_sessionDelete" => self.on_delete(&inbound.topic, req).await,
                "wc_sessionPing" => {
                    self.respond_ok(
                        &inbound.topic,
                        req.id,
                        SESSION_PING.res_tag,
                        SESSION_PING.res_ttl,
                        true,
                    )
                    .await
                }
                "wc_sessionUpdate" => self.on_update(&inbound.topic, req).await,
                "wc_sessionExtend" => self.on_extend(&inbound.topic, req).await,
                "wc_sessionEvent" => self.on_event(&inbound.topic, req).await,
                // Tags for unknown methods: use session-request response tags as a
                // generic envelope (relay only cares about tag for routing priority).
                // Pairing-topic unknowns are rare after settle.
                _ => {
                    self.respond_err(
                        &inbound.topic,
                        req.id,
                        10001,
                        "unsupported method",
                        SESSION_REQUEST.res_tag,
                        SESSION_REQUEST.res_ttl,
                    )
                    .await
                }
            },
            _ => self.on_response(&inbound.topic, &opened.plaintext).await,
        }
    }

    async fn key_for_topic(&self, topic: &str) -> Result<[u8; KEY_LEN], WcError> {
        let state = self.state.lock().await;
        if let Some(s) = state.sessions.get(topic) {
            return s.sym_key();
        }
        if let Some(p) = state.pairings.get(topic) {
            return p.sym_key();
        }
        wc_log!(
            "key_for_topic miss topic={} pairings={} sessions={}",
            topic_short(topic),
            state.pairings.len(),
            state.sessions.len()
        );
        Err(WcError::UnknownTopic(topic.to_owned()))
    }

    // ── Pair ──────────────────────────────────────────────────────────────

    #[frb(ignore)]
    pub async fn pair(&self, uri: &str) -> Result<(), WcError> {
        let parsed = PairingUri::try_from(uri)?;
        let now = now_secs();
        {
            let mut state = self.state.lock().await;
            state.pairings.insert(
                parsed.topic.clone(),
                StoredPairing::new_inactive(&parsed.sym_key, now),
            );
            store::save_to_core(&self.storage, &state)?;
        }
        wc_log!(
            "pair topic={} expiry_in={}s",
            topic_short(&parsed.topic),
            rpc::FIVE_MINUTES
        );
        let _sub_id = self.relay.subscribe(parsed.topic).await?;
        Ok(())
    }

    // ── Propose ───────────────────────────────────────────────────────────

    async fn on_propose(&self, pairing_topic: &str, req: RpcRequest) -> Result<(), WcError> {
        let params: SessionProposeParams = serde_json::from_str(req.params.get())?;
        let proposal = Proposal {
            id: req.id,
            pairing_topic: pairing_topic.to_owned(),
            proposer_pub: params.proposer.public_key,
            proposer_meta: params.proposer.metadata,
            required: params.required_namespaces,
            optional: params.optional_namespaces,
            expiry: now_secs().saturating_add(rpc::FIVE_MINUTES),
        };
        wc_log!(
            "propose id={} pairing={} peer={} required={:?}",
            proposal.id,
            topic_short(pairing_topic),
            proposal.proposer_meta.name,
            proposal.required.keys().collect::<Vec<_>>()
        );
        self.pending.lock().await.insert(
            proposal.id,
            PendingProposal {
                pairing_topic: pairing_topic.to_owned(),
                proposal: proposal.clone(),
            },
        );
        let _ = self.event_tx.send(WcEvent::Proposal(proposal)).await;
        Ok(())
    }

    // ── Approve ───────────────────────────────────────────────────────────

    #[frb(ignore)]
    pub async fn approve(
        &self,
        proposal_id: u64,
        namespaces: BTreeMap<String, SettledNamespace>,
    ) -> Result<String, WcError> {
        let pending = {
            let mut map = self.pending.lock().await;
            map.remove(&proposal_id)
                .ok_or(WcError::ProposalNotFound(proposal_id))?
        };
        wc_log!(
            "approve start id={} pairing={} ns={:?}",
            proposal_id,
            topic_short(&pending.pairing_topic),
            namespaces.keys().collect::<Vec<_>>()
        );
        session::conforms(&pending.proposal.required, &namespaces)?;

        let kp = {
            let mut rng = zilpay::rand::rng();
            KeyPair::generate(&mut rng)
        };
        let peer_pub = crypto::decode_hex32(&pending.proposal.proposer_pub)?;
        let sym_key = crypto::derive_sym_key(&kp.secret, &peer_pub)?;
        let session_topic = crypto::topic_of(&sym_key);
        let self_pub_hex = kp.public_hex();
        let expiry = now_secs().saturating_add(SEVEN_DAYS);

        wc_log!(
            "approve keys session={} self_pub={}",
            topic_short(&session_topic),
            self_pub_hex.get(..12).unwrap_or(&self_pub_hex)
        );

        // reown: store session symKey *before* encoding settle (crypto keychain /
        // our sessions map). Otherwise seal_and_publish → UnknownTopic.
        {
            let mut state = self.state.lock().await;
            if let Some(p) = state.pairings.get_mut(&pending.pairing_topic) {
                p.activate(now_secs());
            } else {
                wc_log!(
                    "approve: pairing {} missing at insert (will still try publish)",
                    topic_short(&pending.pairing_topic)
                );
            }
            state.sessions.insert(
                session_topic.clone(),
                Session {
                    topic: session_topic.clone(),
                    pairing_topic: pending.pairing_topic.clone(),
                    sym_key_hex: zilpay::hex::encode(sym_key),
                    self_pub: self_pub_hex.clone(),
                    peer_pub: pending.proposal.proposer_pub.clone(),
                    peer_meta: pending.proposal.proposer_meta.clone(),
                    namespaces: namespaces.clone(),
                    expiry,
                    acknowledged: false,
                },
            );
            store::save_to_core(&self.storage, &state)?;
            wc_log!(
                "approve stored session; pairings={} sessions={}",
                state.pairings.len(),
                state.sessions.len()
            );
        }

        // 1. subscribe session topic
        if let Err(e) = self.relay.subscribe(session_topic.clone()).await {
            wc_log!("approve subscribe failed: {e}");
            let _ = self.remove_session(&session_topic).await;
            return Err(e);
        }

        // 2. respond on pairing topic (tag 1101)
        let result = SessionProposeResult {
            relay: Relay::irn(),
            responder_public_key: self_pub_hex.clone(),
        };
        if let Err(e) = self
            .publish_response(
                &pending.pairing_topic,
                proposal_id,
                &result,
                SESSION_PROPOSE.res_tag,
                SESSION_PROPOSE.res_ttl,
            )
            .await
        {
            wc_log!("approve pairing response failed: {e}");
            let _ = self.remove_session(&session_topic).await;
            return Err(e);
        }
        wc_log!(
            "approve published propose response tag={} pairing={}",
            SESSION_PROPOSE.res_tag,
            topic_short(&pending.pairing_topic)
        );

        // 3. settle on session topic (tag 1102) — session key is in store now
        let settle = SessionSettleParams {
            relay: Relay::irn(),
            namespaces,
            controller: Participant {
                public_key: self_pub_hex,
                metadata: self.self_meta.clone(),
            },
            expiry,
        };
        if let Err(e) = self
            .publish_request(&session_topic, "wc_sessionSettle", &settle, &SESSION_SETTLE)
            .await
        {
            wc_log!("approve settle failed: {e}");
            let _ = self.remove_session(&session_topic).await;
            return Err(e);
        }
        wc_log!(
            "approve published settle tag={} session={}",
            SESSION_SETTLE.req_tag,
            topic_short(&session_topic)
        );

        Ok(session_topic)
    }

    // ── Reject ────────────────────────────────────────────────────────────

    #[frb(ignore)]
    pub async fn reject(&self, proposal_id: u64, code: i64, message: &str) -> Result<(), WcError> {
        let pending = {
            let mut map = self.pending.lock().await;
            map.remove(&proposal_id)
        };
        let Some(pending) = pending else {
            // Idempotent: approve already consumed the proposal.
            wc_log!("reject id={proposal_id}: already gone (ok)");
            return Ok(());
        };
        wc_log!(
            "reject id={proposal_id} pairing={} code={code}",
            topic_short(&pending.pairing_topic)
        );
        self.respond_err(
            &pending.pairing_topic,
            proposal_id,
            code,
            message,
            PROPOSE_REJECT_TAG,
            SESSION_PROPOSE.res_ttl,
        )
        .await
    }

    // ── Session request ───────────────────────────────────────────────────

    async fn on_request(&self, topic: &str, req: RpcRequest) -> Result<(), WcError> {
        let params: SessionRequestParams = serde_json::from_str(req.params.get())?;
        let peer = {
            let state = self.state.lock().await;
            let session = state
                .sessions
                .get(topic)
                .ok_or_else(|| WcError::SessionNotFound(topic.to_owned()))?;
            if !session.supports_chain(&params.chain_id)
                || !session.supports_method(&params.chain_id, &params.request.method)
            {
                drop(state);
                return self
                    .respond_err(
                        topic,
                        req.id,
                        3005,
                        "unauthorized",
                        SESSION_REQUEST.res_tag,
                        SESSION_REQUEST.res_ttl,
                    )
                    .await;
            }
            session.peer_meta.clone()
        };
        let _ = self
            .event_tx
            .send(WcEvent::Request {
                topic: topic.to_owned(),
                id: req.id,
                chain_id: params.chain_id,
                method: params.request.method,
                params: params.request.params.get().to_owned(),
                peer,
            })
            .await;
        Ok(())
    }

    #[frb(ignore)]
    pub async fn respond_result(
        &self,
        topic: &str,
        id: u64,
        result_json: &str,
    ) -> Result<(), WcError> {
        let value: serde_json::Value =
            serde_json::from_str(result_json).map_err(WcError::from)?;
        self.publish_response(
            topic,
            id,
            &value,
            SESSION_REQUEST.res_tag,
            SESSION_REQUEST.res_ttl,
        )
        .await
    }

    #[frb(ignore)]
    pub async fn respond_error(
        &self,
        topic: &str,
        id: u64,
        code: i64,
        message: &str,
    ) -> Result<(), WcError> {
        self.respond_err(
            topic,
            id,
            code,
            message,
            SESSION_REQUEST.res_tag,
            SESSION_REQUEST.res_ttl,
        )
        .await
    }

    // ── Delete / disconnect ───────────────────────────────────────────────

    async fn on_delete(&self, topic: &str, req: RpcRequest) -> Result<(), WcError> {
        let params: SessionDeleteParams =
            serde_json::from_str(req.params.get()).unwrap_or_else(|_| SessionDeleteParams {
                code: 6000,
                message: "Session deleted".to_owned(),
            });
        self.respond_ok(
            topic,
            req.id,
            SESSION_DELETE.res_tag,
            SESSION_DELETE.res_ttl,
            true,
        )
        .await?;
        self.remove_session(topic).await?;
        let _ = self
            .event_tx
            .send(WcEvent::SessionDeleted {
                topic: topic.to_owned(),
                code: params.code,
                message: params.message,
            })
            .await;
        Ok(())
    }

    #[frb(ignore)]
    pub async fn disconnect(&self, topic: &str) -> Result<(), WcError> {
        let params = SessionDeleteParams {
            code: 6000,
            message: "User disconnected".to_owned(),
        };
        let _ = self
            .publish_request(topic, "wc_sessionDelete", &params, &SESSION_DELETE)
            .await;
        self.remove_session(topic).await?;
        let _ = self
            .event_tx
            .send(WcEvent::SessionDeleted {
                topic: topic.to_owned(),
                code: 6000,
                message: "User disconnected".to_owned(),
            })
            .await;
        Ok(())
    }

    async fn remove_session(&self, topic: &str) -> Result<(), WcError> {
        {
            let mut state = self.state.lock().await;
            state.sessions.remove(topic);
            store::save_to_core(&self.storage, &state)?;
        }
        // Relay looks up the subscription id from its topic map (including
        // sessions restored after restart that were re-subscribed on connect).
        let _ = self.relay.unsubscribe(topic.to_owned()).await;
        Ok(())
    }

    /// Wallet → dApp `wc_sessionEvent` (e.g. `accountsChanged`, `chainChanged`).
    /// Mirrors reown `emitSessionEvent`.
    #[frb(ignore)]
    pub async fn emit_session_event(
        &self,
        topic: &str,
        chain_id: &str,
        name: &str,
        data_json: &str,
    ) -> Result<(), WcError> {
        {
            let state = self.state.lock().await;
            if !state.sessions.contains_key(topic) {
                return Err(WcError::SessionNotFound(topic.to_owned()));
            }
            // Wallet-originated CAIP standard events are always allowed (reown
            // samples emit accountsChanged even when the approved event set is
            // sparse). Other event names still require session advertising.
            let standard = name == "accountsChanged" || name == "chainChanged";
            if !standard {
                let session = state.sessions.get(topic);
                let any = session.is_some_and(|s| {
                    s.namespaces
                        .values()
                        .any(|ns| ns.events.iter().any(|e| e == name))
                });
                if !any {
                    wc_log!(
                        "emit_session_event skip topic={} event={} not in session events",
                        topic_short(topic),
                        name
                    );
                    return Ok(());
                }
            }
        }

        let data: Box<zilpay::serde_json::value::RawValue> =
            zilpay::serde_json::value::RawValue::from_string(data_json.to_owned())
                .map_err(|_| WcError::Crypto("event data json"))?;
        let params = SessionEventParams {
            chain_id: chain_id.to_owned(),
            event: SessionEventBody {
                name: name.to_owned(),
                data,
            },
        };
        wc_log!(
            "emit_session_event topic={} chain={} name={}",
            topic_short(topic),
            chain_id,
            name
        );
        self.publish_request(topic, "wc_sessionEvent", &params, &SESSION_EVENT)
            .await
    }

    /// Update CAIP-10 accounts in session namespaces for `ns_key` (e.g. `eip155`)
    /// to the given list, then persist. Used after account switch so session
    /// state matches the active wallet account.
    #[frb(ignore)]
    pub async fn update_session_accounts(
        &self,
        topic: &str,
        ns_key: &str,
        accounts: Vec<String>,
    ) -> Result<(), WcError> {
        let count = accounts.len();
        {
            let mut state = self.state.lock().await;
            let session = state
                .sessions
                .get_mut(topic)
                .ok_or_else(|| WcError::SessionNotFound(topic.to_owned()))?;
            if let Some(ns) = session.namespaces.get_mut(ns_key) {
                ns.accounts = accounts;
            }
            store::save_to_core(&self.storage, &state)?;
        }
        wc_log!(
            "update_session_accounts topic={} ns={} count={count}",
            topic_short(topic),
            ns_key
        );
        Ok(())
    }

    // ── Update / extend / event ───────────────────────────────────────────

    async fn on_update(&self, topic: &str, req: RpcRequest) -> Result<(), WcError> {
        let params: SessionUpdateParams = serde_json::from_str(req.params.get())?;
        {
            let mut state = self.state.lock().await;
            if let Some(s) = state.sessions.get_mut(topic) {
                s.namespaces = params.namespaces;
                store::save_to_core(&self.storage, &state)?;
            }
        }
        self.respond_ok(
            topic,
            req.id,
            SESSION_UPDATE.res_tag,
            SESSION_UPDATE.res_ttl,
            true,
        )
        .await
    }

    async fn on_extend(&self, topic: &str, req: RpcRequest) -> Result<(), WcError> {
        let new_expiry = now_secs().saturating_add(SEVEN_DAYS);
        {
            let mut state = self.state.lock().await;
            if let Some(s) = state.sessions.get_mut(topic) {
                s.expiry = new_expiry;
                store::save_to_core(&self.storage, &state)?;
            }
        }
        self.respond_ok(
            topic,
            req.id,
            SESSION_EXTEND.res_tag,
            SESSION_EXTEND.res_ttl,
            true,
        )
        .await
    }

    async fn on_event(&self, topic: &str, req: RpcRequest) -> Result<(), WcError> {
        let params: SessionEventParams = serde_json::from_str(req.params.get())?;
        let _ = self
            .event_tx
            .send(WcEvent::SessionEvent {
                topic: topic.to_owned(),
                chain_id: params.chain_id,
                name: params.event.name,
                data: params.event.data.get().to_owned(),
            })
            .await;
        self.respond_ok(
            topic,
            req.id,
            SESSION_EVENT.res_tag,
            SESSION_EVENT.res_ttl,
            true,
        )
        .await
    }

    async fn on_response(&self, topic: &str, plaintext: &[u8]) -> Result<(), WcError> {
        // Settle ack (tag 1103): result true → acknowledged
        let resp: RpcResponseWire = match serde_json::from_slice(plaintext) {
            Ok(r) => r,
            Err(_) => return Ok(()),
        };
        if resp.error.is_some() {
            return Ok(());
        }
        let mut state = self.state.lock().await;
        if let Some(s) = state.sessions.get_mut(topic) {
            if !s.acknowledged {
                s.acknowledged = true;
                store::save_to_core(&self.storage, &state)?;
                drop(state);
                let _ = self
                    .event_tx
                    .send(WcEvent::SessionSettled {
                        topic: topic.to_owned(),
                    })
                    .await;
            }
        }
        Ok(())
    }

    // ── Publish helpers (DRY funnel) ──────────────────────────────────────

    async fn publish_request<T: Serialize>(
        &self,
        topic: &str,
        method: &str,
        params: &T,
        opts: &MethodOpts,
    ) -> Result<(), WcError> {
        let id = {
            let mut rng = zilpay::rand::rng();
            rpc::payload_id(3, now_ms(), &mut rng)
        };
        let params_val = serde_json::to_value(params).map_err(WcError::from)?;
        let body = jsonrpc_request(id, method, params_val)?;
        wc_log!(
            "publish_request method={method} tag={} topic={}",
            opts.req_tag,
            topic_short(topic)
        );
        self.seal_and_publish(topic, &body, opts.req_tag, opts.req_ttl, opts.prompt)
            .await
    }

    async fn publish_response<T: Serialize>(
        &self,
        topic: &str,
        id: u64,
        result: &T,
        tag: u32,
        ttl: u64,
    ) -> Result<(), WcError> {
        let body = rpc_ok(id, result);
        let text = serde_json::to_string(&body).map_err(WcError::from)?;
        wc_log!(
            "publish_response id={id} tag={tag} topic={}",
            topic_short(topic)
        );
        self.seal_and_publish(topic, &text, tag, ttl, false).await
    }

    async fn respond_ok(
        &self,
        topic: &str,
        id: u64,
        tag: u32,
        ttl: u64,
        result: bool,
    ) -> Result<(), WcError> {
        self.publish_response(topic, id, &result, tag, ttl).await
    }

    async fn respond_err(
        &self,
        topic: &str,
        id: u64,
        code: i64,
        message: &str,
        tag: u32,
        ttl: u64,
    ) -> Result<(), WcError> {
        let body = rpc_err(id, code, message);
        let text = serde_json::to_string(&body).map_err(WcError::from)?;
        self.seal_and_publish(topic, &text, tag, ttl, false).await
    }

    async fn seal_and_publish(
        &self,
        topic: &str,
        plaintext: &str,
        tag: u32,
        ttl: u64,
        prompt: bool,
    ) -> Result<(), WcError> {
        let sym_key = self.key_for_topic(topic).await?;
        let envelope = {
            let mut rng = zilpay::rand::rng();
            crypto::seal(&sym_key, plaintext.as_bytes(), None, &mut rng)?
        };
        self.relay
            .publish(topic.to_owned(), envelope, tag, ttl, prompt)
            .await
    }

    // ── Queries ───────────────────────────────────────────────────────────

    #[frb(ignore)]
    pub async fn sessions(&self) -> Vec<Session> {
        let state = self.state.lock().await;
        state.sessions.values().cloned().collect()
    }

    #[frb(ignore)]
    pub async fn shutdown(&self) {
        self.relay.shutdown().await;
    }
}

fn jsonrpc_request(
    id: u64,
    method: &str,
    params: serde_json::Value,
) -> Result<String, WcError> {
    serde_json::to_string(&serde_json::json!({
        "id": id,
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
    }))
    .map_err(WcError::from)
}
