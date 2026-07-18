//! External FFI for the WalletConnect v2 wallet engine.

use std::sync::{Arc, LazyLock};

use arc_swap::ArcSwapOption;
use zilpay::tokio::sync::{mpsc, Mutex};

use crate::frb_generated::StreamSink;
use crate::models::walletconnect::engine::{WcEngine, WcEvent};
use crate::models::walletconnect::ffi::{
    approvals_to_namespaces, WcEventInfo, WcNamespaceApproval, WcSessionInfo,
};
use crate::models::walletconnect::rpc::Metadata;
use crate::utils::helpers::handle;

static WC_ENGINE: LazyLock<ArcSwapOption<WcEngine>> = LazyLock::new(ArcSwapOption::const_empty);

static EVENT_RX: LazyLock<Mutex<Option<mpsc::Receiver<WcEvent>>>> =
    LazyLock::new(|| Mutex::new(None));

/// Serializes `wc_init` so concurrent calls cannot double-spawn the engine.
static INIT_LOCK: LazyLock<Mutex<()>> = LazyLock::new(|| Mutex::new(()));

fn with_wc() -> Result<Arc<WcEngine>, String> {
    WC_ENGINE
        .load_full()
        .ok_or_else(|| "walletconnect engine not initialized".to_owned())
}

/// Initialize the WalletConnect engine (idempotent if already running).
///
/// `platform`: `"android"` | `"ios"` | `"macos"` | `"linux"` | `"windows"`.
/// `package_name`: Android package / iOS bundle id.
pub async fn wc_init(
    project_id: String,
    app_name: String,
    app_description: String,
    app_url: String,
    app_icon: String,
    package_name: String,
    platform: String,
) -> Result<(), String> {
    let _guard = INIT_LOCK.lock().await;
    if WC_ENGINE.load().is_some() {
        return Ok(());
    }
    let core = handle().map_err(|e| e.to_string())?;
    let storage = core.storage();
    let meta = Metadata {
        name: app_name,
        description: app_description,
        url: app_url,
        icons: if app_icon.is_empty() {
            Vec::new()
        } else {
            vec![app_icon]
        },
    };
    let (event_tx, event_rx) = mpsc::channel::<WcEvent>(64);
    let engine = WcEngine::start(
        project_id,
        package_name,
        platform,
        meta,
        storage,
        event_tx,
    )
    .await
    .map_err(|e| e.to_string())?;
    *EVENT_RX.lock().await = Some(event_rx);
    WC_ENGINE.store(Some(engine));
    Ok(())
}

/// Stream engine events into Flutter. Call after [`wc_init`].
///
/// When the Dart sink closes (hot-restart, cancel), the receiver is put back
/// so a subsequent `wc_events()` call can re-attach without full re-init.
pub async fn wc_events(sink: StreamSink<WcEventInfo>) -> Result<(), String> {
    let mut rx = EVENT_RX
        .lock()
        .await
        .take()
        .ok_or_else(|| "wc_events already attached or engine not init".to_owned())?;

    let mut channel_closed = false;
    loop {
        match rx.recv().await {
            Some(ev) => {
                let info: WcEventInfo = ev.into();
                if sink.add(info).is_err() {
                    // Dart cancelled / hot-restart — keep the channel alive.
                    break;
                }
            }
            None => {
                // Engine dropped the sender (shutdown).
                channel_closed = true;
                break;
            }
        }
    }

    if !channel_closed && WC_ENGINE.load().is_some() {
        *EVENT_RX.lock().await = Some(rx);
    }
    Ok(())
}

/// Pair with a dApp via WalletConnect URI (`wc:…@2?…`).
pub async fn wc_pair(uri: String) -> Result<(), String> {
    let eng = with_wc()?;
    eng.pair(&uri).await.map_err(|e| e.to_string())
}

/// Approve a pending session proposal with CAIP-10 namespaces built by Flutter.
pub async fn wc_approve_session(
    proposal_id: u64,
    namespaces: Vec<WcNamespaceApproval>,
) -> Result<String, String> {
    let eng = with_wc()?;
    let map = approvals_to_namespaces(namespaces);
    eng.approve(proposal_id, map)
        .await
        .map_err(|e| e.to_string())
}

/// Reject a pending session proposal (error code 5000).
pub async fn wc_reject_session(proposal_id: u64) -> Result<(), String> {
    let eng = with_wc()?;
    eng.reject(proposal_id, 5000, "User rejected")
        .await
        .map_err(|e| e.to_string())
}

/// Respond to a `wc_sessionRequest` with a JSON result (opaque to the SDK).
pub async fn wc_respond_ok(
    topic: String,
    id: u64,
    result_json: String,
) -> Result<(), String> {
    let eng = with_wc()?;
    eng.respond_result(&topic, id, &result_json)
        .await
        .map_err(|e| e.to_string())
}

/// Respond to a `wc_sessionRequest` with a JSON-RPC error.
pub async fn wc_respond_err(
    topic: String,
    id: u64,
    code: i64,
    message: String,
) -> Result<(), String> {
    let eng = with_wc()?;
    eng.respond_error(&topic, id, code, &message)
        .await
        .map_err(|e| e.to_string())
}

/// Disconnect an active session (publish delete + drop local state).
pub async fn wc_disconnect(topic: String) -> Result<(), String> {
    let eng = with_wc()?;
    eng.disconnect(&topic).await.map_err(|e| e.to_string())
}

/// List active sessions.
pub async fn wc_sessions() -> Result<Vec<WcSessionInfo>, String> {
    let eng = with_wc()?;
    let sessions = eng.sessions().await;
    Ok(sessions.iter().map(WcSessionInfo::from).collect())
}

/// Emit a wallet-originated `wc_sessionEvent` (e.g. `accountsChanged`).
///
/// `data_json` is opaque JSON (typically `["0x…"]` for accountsChanged).
pub async fn wc_emit_session_event(
    topic: String,
    chain_id: String,
    name: String,
    data_json: String,
) -> Result<(), String> {
    let eng = with_wc()?;
    eng.emit_session_event(&topic, &chain_id, &name, &data_json)
        .await
        .map_err(|e| e.to_string())
}

/// Replace CAIP-10 accounts for one namespace key on a session (local state).
pub async fn wc_update_session_accounts(
    topic: String,
    ns_key: String,
    accounts: Vec<String>,
) -> Result<(), String> {
    let eng = with_wc()?;
    eng.update_session_accounts(&topic, &ns_key, accounts)
        .await
        .map_err(|e| e.to_string())
}

/// Shut down the relay and clear the engine singleton.
pub async fn wc_shutdown() -> Result<(), String> {
    let _guard = INIT_LOCK.lock().await;
    if let Some(eng) = WC_ENGINE.swap(None) {
        eng.shutdown().await;
    }
    *EVENT_RX.lock().await = None;
    Ok(())
}
