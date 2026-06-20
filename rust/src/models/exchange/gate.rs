//! Eager (load-time) provider validation orchestrator. Runs every provider variant that supports
//! a cheap eager probe (see [`ExchangeProvider::eager_gate`]) in parallel, pruning providers a
//! single probe proves dead. Providers without an eager gate (Uniswap, PancakeSwap, ZilSwap) are
//! validated lazily by the 10s quote loop. This orchestrator has ZERO
//! provider-specific logic — it dispatches via [`EagerGate`] (exhaustive match, no dead arms) and
//! strips via [`ExchangeProvider::eager_gate`] comparison (no discriminant, no per-variant match).

use std::collections::HashSet;

use flutter_rust_bridge::frb;
use futures::future::join_all;

use crate::models::exchange::{
    plunderswap::gate as plunder_gate, relay, sunswap::gate as sun_gate, EagerGate, ExchangeAsset,
    ExchangeProvider,
};

/// Probe amount in wrapped-native base units (18 decimals): 1,000 WZIL / WTRX. The lens routes
/// through configured hubs, so the probe only checks *whether a route exists and returns non-zero
/// output* — the exact amount is not used as a quote. Large enough to avoid dust-rounding to zero
/// on the first hop; small enough to stay clear of pool reserves on shallow pairs.
pub(in crate::models::exchange) const PROBE_AMOUNT: u128 = 1_000 * 10u128.pow(18);

/// Dispatch an eager gate's probe against `assets`, returning the indices of assets confirmed to
/// have NO route. Exhaustive match on [`EagerGate`] — no `Err`, no dead arms: adding a gate
/// variant without an arm is a compile error, not a silent skip.
async fn evaluate_eager(gate: EagerGate, assets: &[ExchangeAsset]) -> Vec<usize> {
    match gate {
        EagerGate::Plunder => plunder_gate::evaluate_liquidity_eager(assets).await,
        EagerGate::Sun => sun_gate::evaluate_liquidity_eager(assets).await,
        EagerGate::Relay => relay::evaluate_support_eager(assets).await,
    }
}

/// Run all eager gates present in `assets` in parallel, prune dead providers, drop now-empty
/// assets. Returns `true` if any provider was stripped or asset dropped (caller can skip a
/// redundant republish when `false`). Immutable borrows of `assets` across futures → safe to run
/// concurrently.
#[frb(ignore)]
pub async fn prune_unsupported(assets: &mut Vec<ExchangeAsset>) -> bool {
    let gates = eager_gates_present(assets);
    if gates.is_empty() {
        return false;
    }

    let dead_per_gate = join_all(gates.iter().map(|&gate| evaluate_eager(gate, assets))).await;

    let mut changed = false;
    for (&gate, dead_indices) in gates.iter().zip(dead_per_gate) {
        for idx in dead_indices {
            strip_eager(&mut assets[idx].providers, gate);
            changed = true;
        }
    }
    if changed {
        assets.retain(|asset| !asset.providers.is_empty());
    }
    changed
}

/// Collect each [`EagerGate`] variant present in `assets` (deduplicated). Returns tags only —
/// `EagerGate` is `Copy`, so no provider clone is needed (the gates scan assets themselves to
/// recover the meta they need).
fn eager_gates_present(assets: &[ExchangeAsset]) -> Vec<EagerGate> {
    let mut gates: Vec<EagerGate> = Vec::new();
    for asset in assets {
        for provider in &asset.providers {
            if let Some(gate) = provider.eager_gate() {
                if !gates.contains(&gate) {
                    gates.push(gate);
                }
            }
        }
    }
    gates
}

/// Remove every provider whose [`eager_gate`](ExchangeProvider::eager_gate) matches `gate`.
/// No discriminant, no per-variant match — derived entirely from the single source of truth.
fn strip_eager(providers: &mut HashSet<ExchangeProvider>, gate: EagerGate) {
    providers.retain(|p| p.eager_gate() != Some(gate));
}

/// Find the first provider meta of a specific variant in `assets`. Generic over the match —
/// removes the per-provider `find_*_meta` duplicate. Returns a reference (no clone).
pub(in crate::models::exchange) fn find_meta<'a, T: ?Sized>(
    assets: &'a [ExchangeAsset],
    matcher: impl Fn(&'a ExchangeProvider) -> Option<&'a T>,
) -> Option<&'a T> {
    assets
        .iter()
        .flat_map(|asset| asset.providers.iter())
        .find_map(matcher)
}
