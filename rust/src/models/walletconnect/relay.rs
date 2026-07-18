//! WalletConnect v2 relay client: WSS + irn_publish / irn_subscribe / irn_subscription.
//!
//! **Request model (critical):** the relay task never awaits a response inside the
//! select branch. Outbound RPC frames park a oneshot in `pending`; inbound
//! `handle_text` resolves them. Callers (`RelayHandle`) await the oneshot from
//! *outside* the task so the socket stream keeps being polled.

use std::collections::{BTreeMap, HashMap};
use std::time::{Duration, Instant};

use flutter_rust_bridge::frb;
use futures::{SinkExt, StreamExt};
use zilpay::rand::Rng;
use zilpay::serde::Serialize;
use zilpay::serde_json::{self, json, Value};
use zilpay::tokio::sync::{mpsc, oneshot};
use zilpay::tokio_tungstenite::{
    connect_async,
    tungstenite::{error::Error as WsError, Message},
};

use super::error::WcError;
use super::relay_auth::sign_relay_jwt_now;
use super::rpc::{
    payload_id, IrnPublishParams, IrnSubscribeParams, IrnUnsubscribeParams, IrnSubscriptionParams,
};
use super::store::now_ms;

const SDK_VERSION: &str = "0.1.0";
const RETRY_DELAY: Duration = Duration::from_secs(2);
const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);
const SWEEP_INTERVAL: Duration = Duration::from_secs(5);

/// Close codes that warrant automatic reconnect (reown relay_client.dart).
const RECONNECT_CODES: &[u16] = &[1001, 1002, 1005, 4008, 4010, 10002];
/// WalletConnect relay uses application close code 3000 for auth/JWT failures.
const FATAL_AUTH_CLOSE: u16 = 3000;

#[frb(ignore)]
#[derive(Debug, Clone)]
pub struct RelayConfig {
    pub project_id: String,
    pub relay_url: String,
    pub client_seed: [u8; 32],
    pub package_name: String,
    pub platform: String, // "android" | "ios" | "linux" | …
}

#[frb(ignore)]
pub enum RelayCmd {
    Publish {
        topic: String,
        message: String,
        tag: u32,
        ttl: u64,
        prompt: bool,
        done: oneshot::Sender<Result<(), WcError>>,
    },
    Subscribe {
        topic: String,
        done: oneshot::Sender<Result<String, WcError>>,
    },
    /// Look up subscription id from the relay's topic map (if any) and send irn_unsubscribe.
    Unsubscribe {
        topic: String,
    },
    Shutdown,
}

#[frb(ignore)]
#[derive(Debug, Clone)]
pub struct Inbound {
    pub topic: String,
    pub message: String,
}

#[frb(ignore)]
#[derive(Clone)]
pub struct RelayHandle {
    cmd_tx: mpsc::Sender<RelayCmd>,
}

impl RelayHandle {
    #[frb(ignore)]
    pub async fn publish(
        &self,
        topic: String,
        message: String,
        tag: u32,
        ttl: u64,
        prompt: bool,
    ) -> Result<(), WcError> {
        let (done, rx) = oneshot::channel();
        self.cmd_tx
            .send(RelayCmd::Publish {
                topic,
                message,
                tag,
                ttl,
                prompt,
                done,
            })
            .await
            .map_err(|_| WcError::Transport("relay cmd channel closed".into()))?;
        rx.await
            .map_err(|_| WcError::Transport("relay publish dropped".into()))?
    }

    #[frb(ignore)]
    pub async fn subscribe(&self, topic: String) -> Result<String, WcError> {
        let (done, rx) = oneshot::channel();
        self.cmd_tx
            .send(RelayCmd::Subscribe { topic, done })
            .await
            .map_err(|_| WcError::Transport("relay cmd channel closed".into()))?;
        rx.await
            .map_err(|_| WcError::Transport("relay subscribe dropped".into()))?
    }

    #[frb(ignore)]
    pub async fn unsubscribe(&self, topic: String) -> Result<(), WcError> {
        self.cmd_tx
            .send(RelayCmd::Unsubscribe { topic })
            .await
            .map_err(|_| WcError::Transport("relay cmd channel closed".into()))
    }

    #[frb(ignore)]
    pub async fn shutdown(&self) {
        let _ = self.cmd_tx.send(RelayCmd::Shutdown).await;
    }
}

/// Spawn the relay task. Returns handle + inbound receiver.
#[frb(ignore)]
pub fn spawn_relay(
    cfg: RelayConfig,
    initial_topics: Vec<String>,
) -> (
    RelayHandle,
    mpsc::Receiver<Inbound>,
    mpsc::Receiver<RelayStatus>,
) {
    let (cmd_tx, cmd_rx) = mpsc::channel(64);
    let (inbound_tx, inbound_rx) = mpsc::channel(64);
    let (status_tx, status_rx) = mpsc::channel(8);
    zilpay::tokio::spawn(async move {
        run(cfg, cmd_rx, inbound_tx, status_tx, initial_topics).await;
    });
    (RelayHandle { cmd_tx }, inbound_rx, status_rx)
}

#[frb(ignore)]
#[derive(Debug, Clone)]
pub enum RelayStatus {
    Connected,
    Disconnected,
    Fatal(String),
}

// ── Pending request bookkeeping ───────────────────────────────────────────

enum PendingKind {
    Publish(oneshot::Sender<Result<(), WcError>>),
    /// `done = None` for reconnect resubscribes (no external waiter).
    Subscribe {
        topic: String,
        done: Option<oneshot::Sender<Result<String, WcError>>>,
    },
    /// Fire-and-forget unsubscribe ack.
    Unsubscribe,
}

struct PendingEntry {
    kind: PendingKind,
    deadline: Instant,
}

type PendingMap = HashMap<u64, PendingEntry>;

// ── URL / auth ────────────────────────────────────────────────────────────

#[frb(ignore)]
fn build_url(cfg: &RelayConfig) -> Result<String, WcError> {
    let mut sub = [0u8; 32];
    zilpay::rand::rng().fill_bytes(&mut sub);
    let now = super::store::now_secs();
    let jwt = sign_relay_jwt_now(&cfg.client_seed, &cfg.relay_url, &sub, now)?;
    // reown formatUA: `{protocol}-{version}/{sdk}-{sdkVersion}/{os}` (3 segments).
    // packageName/bundleId is a separate query param, not part of `ua`.
    let ua = format!(
        "wc-2/rust-bearby-{}/{}",
        SDK_VERSION,
        cfg.platform.to_lowercase()
    );
    let mut params: Vec<(&str, String)> = Vec::with_capacity(4);
    params.push(("auth", jwt));
    params.push(("ua", ua));
    params.push(("projectId", cfg.project_id.clone()));
    if !cfg.package_name.is_empty() {
        let key = match cfg.platform.as_str() {
            "ios" => "bundleId",
            "android" => "packageName",
            _ => "origin",
        };
        params.push((key, cfg.package_name.clone()));
    }
    let query: String = params
        .iter()
        .map(|(k, v)| {
            let mut s = String::with_capacity(k.len() + 1 + v.len());
            s.push_str(k);
            s.push('=');
            s.push_str(&urlencoding_minimal(v));
            s
        })
        .collect::<Vec<_>>()
        .join("&");
    // Path must be `/` before the query — `wss://host?q` (no slash) is rejected
    // by the WC ALB with HTTP 400; reown/Dart Uri often emits `host/?q`.
    let base = cfg.relay_url.trim_end_matches('/');
    let mut url = String::with_capacity(base.len() + 2 + query.len());
    url.push_str(base);
    url.push('/');
    url.push('?');
    url.push_str(&query);
    Ok(url)
}

#[frb(ignore)]
fn urlencoding_minimal(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                out.push(b as char);
            }
            _ => {
                out.push('%');
                out.push(nibble(b >> 4));
                out.push(nibble(b & 0xf));
            }
        }
    }
    out
}

fn nibble(n: u8) -> char {
    match n {
        0..=9 => (b'0' + n) as char,
        10..=15 => (b'A' + (n - 10)) as char,
        _ => '0',
    }
}

/// Detect HTTP 401/403 during the WS upgrade (bad projectId / JWT).
fn is_auth_http_error(err: &WsError) -> bool {
    match err {
        WsError::Http(resp) => {
            let status = resp.status().as_u16();
            status == 401 || status == 403
        }
        _ => false,
    }
}

fn should_reconnect(code: Option<u16>) -> bool {
    match code {
        Some(FATAL_AUTH_CLOSE) => false,
        Some(1000) => false, // Normal
        Some(c) if RECONNECT_CODES.contains(&c) => true,
        // Unexpected disconnects (None, other codes) → retry.
        None | Some(_) => true,
    }
}

// ── Task loop ─────────────────────────────────────────────────────────────

async fn run(
    cfg: RelayConfig,
    mut cmd_rx: mpsc::Receiver<RelayCmd>,
    inbound_tx: mpsc::Sender<Inbound>,
    status_tx: mpsc::Sender<RelayStatus>,
    initial_topics: Vec<String>,
) {
    // topic → subscription id (empty until first successful irn_subscribe reply)
    let mut topics: BTreeMap<String, String> = BTreeMap::new();
    for t in initial_topics {
        topics.insert(t, String::new());
    }

    loop {
        let url = match build_url(&cfg) {
            Ok(u) => u,
            Err(e) => {
                let _ = status_tx.send(RelayStatus::Fatal(e.to_string())).await;
                return;
            }
        };

        let ws = match connect_async(&url).await {
            Ok((ws, _)) => ws,
            Err(e) => {
                if is_auth_http_error(&e) {
                    let _ = status_tx
                        .send(RelayStatus::Fatal(format!("auth failed: {e}")))
                        .await;
                    return;
                }
                let _ = status_tx.send(RelayStatus::Disconnected).await;
                zilpay::tokio::time::sleep(RETRY_DELAY).await;
                continue;
            }
        };

        let _ = status_tx.send(RelayStatus::Connected).await;
        let (mut sink, mut stream) = ws.split();
        let mut pending: PendingMap = HashMap::with_capacity(16);
        let mut sweep = zilpay::tokio::time::interval(SWEEP_INTERVAL);

        // Queue resubscribe for every known topic (no external waiter).
        {
            let keys: Vec<String> = topics.keys().cloned().collect();
            for topic in keys {
                if let Err(e) = queue_subscribe(&mut sink, &mut pending, topic, None).await {
                    // Don't kill the task — retry on next reconnect.
                    let _ = status_tx
                        .send(RelayStatus::Disconnected)
                        .await;
                    let _ = e;
                    break;
                }
            }
        }

        // Outcome of the inner select loop.
        enum LoopExit {
            /// Reconnect after delay.
            Reconnect,
            /// Stop the relay task entirely.
            Stop,
        }
        let exit = loop {
            let outcome = zilpay::tokio::select! {
                cmd = cmd_rx.recv() => {
                    match cmd {
                        None | Some(RelayCmd::Shutdown) => {
                            let _ = sink.close().await;
                            fail_all_pending(&mut pending, "shutdown");
                            return;
                        }
                        Some(RelayCmd::Publish { topic, message, tag, ttl, prompt, done }) => {
                            if let Err(e) = queue_publish(
                                &mut sink,
                                &mut pending,
                                PublishArgs {
                                    topic: &topic,
                                    message: &message,
                                    tag,
                                    ttl,
                                    prompt,
                                },
                                done,
                            ).await {
                                let _ = e;
                            }
                            None
                        }
                        Some(RelayCmd::Subscribe { topic, done }) => {
                            if let Err(e) = queue_subscribe(
                                &mut sink, &mut pending, topic, Some(done),
                            ).await {
                                let _ = e;
                            }
                            None
                        }
                        Some(RelayCmd::Unsubscribe { topic }) => {
                            let sub_id = topics.remove(&topic).unwrap_or_default();
                            if !sub_id.is_empty() {
                                let _ = queue_unsubscribe(
                                    &mut sink, &mut pending, &topic, &sub_id,
                                ).await;
                            }
                            None
                        }
                    }
                }
                frame = stream.next() => {
                    match frame {
                        Some(Ok(Message::Text(text))) => {
                            if let Err(e) = handle_text(
                                text.as_str(),
                                &mut sink,
                                &mut pending,
                                &mut topics,
                                &inbound_tx,
                            ).await {
                                if matches!(e, WcError::Transport(_)) {
                                    Some(LoopExit::Reconnect)
                                } else {
                                    None
                                }
                            } else {
                                None
                            }
                        }
                        Some(Ok(Message::Ping(p))) => {
                            let _ = sink.send(Message::Pong(p)).await;
                            None
                        }
                        Some(Ok(Message::Close(frame))) => {
                            let code = frame.as_ref().map(|f| u16::from(f.code));
                            if code == Some(FATAL_AUTH_CLOSE) {
                                fail_all_pending(&mut pending, "auth close");
                                let _ = status_tx
                                    .send(RelayStatus::Fatal(
                                        "relay closed with auth error (3000)".into(),
                                    ))
                                    .await;
                                return;
                            }
                            if should_reconnect(code) {
                                Some(LoopExit::Reconnect)
                            } else {
                                Some(LoopExit::Stop)
                            }
                        }
                        Some(Ok(_)) => None,
                        Some(Err(e)) => {
                            if is_auth_http_error(&e) {
                                fail_all_pending(&mut pending, "auth error");
                                let _ = status_tx
                                    .send(RelayStatus::Fatal(format!("auth failed: {e}")))
                                    .await;
                                return;
                            }
                            Some(LoopExit::Reconnect)
                        }
                        None => Some(LoopExit::Reconnect),
                    }
                }
                _ = sweep.tick() => {
                    sweep_timeouts(&mut pending);
                    None
                }
            };
            if let Some(e) = outcome {
                break e;
            }
        };

        fail_all_pending(&mut pending, "disconnected");
        let _ = status_tx.send(RelayStatus::Disconnected).await;
        match exit {
            LoopExit::Stop => return,
            LoopExit::Reconnect => {
                zilpay::tokio::time::sleep(RETRY_DELAY).await;
            }
        }
    }
}

// ── Fire-and-park helpers (never await a response) ────────────────────────

async fn send_json<S>(sink: &mut S, value: &impl Serialize) -> Result<(), WcError>
where
    S: SinkExt<Message> + Unpin,
    S::Error: std::fmt::Display,
{
    let text = serde_json::to_string(value).map_err(WcError::from)?;
    sink.send(Message::Text(text))
        .await
        .map_err(|e| WcError::Transport(e.to_string()))
}

fn next_rpc_id() -> u64 {
    let mut rng = zilpay::rand::rng();
    payload_id(6, now_ms(), &mut rng)
}

async fn queue_rpc<S>(
    sink: &mut S,
    pending: &mut PendingMap,
    method: &str,
    params: Value,
    kind: PendingKind,
) -> Result<(), WcError>
where
    S: SinkExt<Message> + Unpin,
    S::Error: std::fmt::Display,
{
    let id = next_rpc_id();
    let req = json!({
        "id": id,
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
    });
    if let Err(e) = send_json(sink, &req).await {
        resolve_kind_err(kind, e);
        return Err(WcError::Transport("send failed".into()));
    }
    pending.insert(
        id,
        PendingEntry {
            kind,
            deadline: Instant::now() + REQUEST_TIMEOUT,
        },
    );
    Ok(())
}

struct PublishArgs<'a> {
    topic: &'a str,
    message: &'a str,
    tag: u32,
    ttl: u64,
    prompt: bool,
}

async fn queue_publish<S>(
    sink: &mut S,
    pending: &mut PendingMap,
    args: PublishArgs<'_>,
    done: oneshot::Sender<Result<(), WcError>>,
) -> Result<(), WcError>
where
    S: SinkExt<Message> + Unpin,
    S::Error: std::fmt::Display,
{
    let params = match serde_json::to_value(IrnPublishParams {
        topic: args.topic,
        message: args.message,
        ttl: args.ttl,
        tag: args.tag,
        prompt: args.prompt,
    }) {
        Ok(p) => p,
        Err(e) => {
            let _ = done.send(Err(WcError::from(e)));
            return Err(WcError::Transport("serialize publish".into()));
        }
    };
    queue_rpc(
        sink,
        pending,
        "irn_publish",
        params,
        PendingKind::Publish(done),
    )
    .await
}

async fn queue_subscribe<S>(
    sink: &mut S,
    pending: &mut PendingMap,
    topic: String,
    done: Option<oneshot::Sender<Result<String, WcError>>>,
) -> Result<(), WcError>
where
    S: SinkExt<Message> + Unpin,
    S::Error: std::fmt::Display,
{
    let params = match serde_json::to_value(IrnSubscribeParams {
        topic: topic.as_str(),
    }) {
        Ok(p) => p,
        Err(e) => {
            if let Some(d) = done {
                let _ = d.send(Err(WcError::from(e)));
            }
            return Err(WcError::Transport("serialize subscribe".into()));
        }
    };
    queue_rpc(
        sink,
        pending,
        "irn_subscribe",
        params,
        PendingKind::Subscribe { topic, done },
    )
    .await
}

async fn queue_unsubscribe<S>(
    sink: &mut S,
    pending: &mut PendingMap,
    topic: &str,
    sub_id: &str,
) -> Result<(), WcError>
where
    S: SinkExt<Message> + Unpin,
    S::Error: std::fmt::Display,
{
    let params = serde_json::to_value(IrnUnsubscribeParams {
        topic,
        id: sub_id,
    })
    .map_err(WcError::from)?;
    queue_rpc(
        sink,
        pending,
        "irn_unsubscribe",
        params,
        PendingKind::Unsubscribe,
    )
    .await
}

fn resolve_kind_err(kind: PendingKind, err: WcError) {
    match kind {
        PendingKind::Publish(done) => {
            let _ = done.send(Err(err));
        }
        PendingKind::Subscribe { done: Some(d), .. } => {
            let _ = d.send(Err(err));
        }
        PendingKind::Subscribe { done: None, .. } | PendingKind::Unsubscribe => {}
    }
}

fn fail_all_pending(pending: &mut PendingMap, reason: &str) {
    for (_, entry) in pending.drain() {
        resolve_kind_err(entry.kind, WcError::Transport(reason.into()));
    }
}

fn sweep_timeouts(pending: &mut PendingMap) {
    let now = Instant::now();
    let expired: Vec<u64> = pending
        .iter()
        .filter(|(_, e)| e.deadline <= now)
        .map(|(id, _)| *id)
        .collect();
    for id in expired {
        if let Some(entry) = pending.remove(&id) {
            resolve_kind_err(entry.kind, WcError::Transport("rpc timeout".into()));
        }
    }
}

fn resolve_pending_response(
    pending: &mut PendingMap,
    topics: &mut BTreeMap<String, String>,
    id: u64,
    result: Result<Value, WcError>,
) {
    let Some(entry) = pending.remove(&id) else {
        return;
    };
    match entry.kind {
        PendingKind::Publish(done) => {
            let _ = done.send(result.map(|_| ()));
        }
        PendingKind::Subscribe { topic, done } => match result {
            Ok(v) => {
                let sub_id = v.as_str().map(|s| s.to_owned()).unwrap_or_default();
                if !sub_id.is_empty() {
                    topics.insert(topic, sub_id.clone());
                } else {
                    // Keep topic registered even if id missing so reconnect retries.
                    topics.entry(topic).or_default();
                }
                if let Some(d) = done {
                    if sub_id.is_empty() {
                        let _ = d.send(Err(WcError::Transport(
                            "subscribe result not string".into(),
                        )));
                    } else {
                        let _ = d.send(Ok(sub_id));
                    }
                }
            }
            Err(e) => {
                if let Some(d) = done {
                    let _ = d.send(Err(e));
                }
            }
        },
        PendingKind::Unsubscribe => {
            // No waiter.
            let _ = result;
        }
    }
}

async fn handle_text<S>(
    text: &str,
    sink: &mut S,
    pending: &mut PendingMap,
    topics: &mut BTreeMap<String, String>,
    inbound_tx: &mpsc::Sender<Inbound>,
) -> Result<(), WcError>
where
    S: SinkExt<Message> + Unpin,
    S::Error: std::fmt::Display,
{
    let v: Value = serde_json::from_str(text).map_err(WcError::from)?;
    // Response (no method field).
    if v.get("method").is_none() {
        if let Some(id) = v.get("id").and_then(|i| i.as_u64()) {
            if let Some(err) = v.get("error") {
                let code = err.get("code").and_then(|c| c.as_i64()).unwrap_or(-1);
                let message = err
                    .get("message")
                    .and_then(|m| m.as_str())
                    .unwrap_or("rpc error")
                    .to_owned();
                resolve_pending_response(
                    pending,
                    topics,
                    id,
                    Err(WcError::RelayRpc { code, message }),
                );
            } else {
                let result = v.get("result").cloned().unwrap_or(Value::Null);
                resolve_pending_response(pending, topics, id, Ok(result));
            }
        }
        return Ok(());
    }

    let method = v
        .get("method")
        .and_then(|m| m.as_str())
        .unwrap_or_default();
    if method == "irn_subscription" {
        let id = v.get("id").cloned().unwrap_or(Value::Null);
        let ack = json!({ "id": id, "jsonrpc": "2.0", "result": true });
        send_json(sink, &ack).await?;

        let params: IrnSubscriptionParams =
            serde_json::from_value(v.get("params").cloned().unwrap_or(Value::Null))
                .map_err(WcError::from)?;
        let _ = inbound_tx
            .send(Inbound {
                topic: params.data.topic,
                message: params.data.message,
            })
            .await;
    }
    Ok(())
}

#[cfg(test)]
mod integration_tests {
    use super::*;
    use zilpay::rand::Rng;

    /// Manual integration: connect to the public WC relay and subscribe a random topic.
    /// Run with: `cargo test -p rust_lib_zilpay relay_subscribe -- --ignored --nocapture`
    #[test]
    #[ignore = "hits live relay.walletconnect.org; needs network"]
    fn relay_subscribe_random_topic() {
        // Install rustls CryptoProvider (same as app `zilpay::init()`).
        // Ignore "already installed" — install_default errors if set twice.
        match zilpay::init() {
            Ok(()) => {}
            Err(e) => eprintln!("zilpay::init note: {e}"),
        }
        let rt = zilpay::tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("runtime");
        rt.block_on(async {
            let mut seed = [0u8; 32];
            zilpay::rand::rng().fill_bytes(&mut seed);
            let mut topic_bytes = [0u8; 32];
            zilpay::rand::rng().fill_bytes(&mut topic_bytes);
            let topic = zilpay::hex::encode(topic_bytes);

            let cfg = RelayConfig {
                project_id: "2cb43be3de5d03d9fdc34b3f4d4b0371".to_owned(),
                relay_url: "wss://relay.walletconnect.org".to_owned(),
                client_seed: seed,
                package_name: "com.zilpaymobile".to_owned(),
                platform: "linux".to_owned(),
            };
            let (handle, _inbound, mut status) = spawn_relay(cfg, Vec::new());

            let connected = zilpay::tokio::time::timeout(Duration::from_secs(20), async {
                while let Some(s) = status.recv().await {
                    match s {
                        RelayStatus::Connected => return true,
                        RelayStatus::Fatal(m) => panic!("relay fatal: {m}"),
                        RelayStatus::Disconnected => {}
                    }
                }
                false
            })
            .await
            .unwrap_or(false);
            assert!(connected, "relay did not connect");

            let sub_id =
                zilpay::tokio::time::timeout(Duration::from_secs(20), handle.subscribe(topic))
                    .await
                    .expect("subscribe timeout")
                    .expect("subscribe");
            assert!(!sub_id.is_empty(), "empty subscription id: {sub_id}");
            handle.shutdown().await;
        });
    }
}
