//! SunSwap eager liquidity gate. Probes WTRX → token reachability for every TRON token carrying
//! a SunSwap provider. TRON's full-node API (`triggerconstantcontract`) is not batchable, so probes
//! run concurrently via [`buffer_unordered`] with a bounded concurrency cap and each probe carries
//! its own index so correctness never depends on stream completion order. The provider is resolved
//! once (not per-probe) and shared via [`Arc`]. Each probe reuses the SAME lens primitive as the
//! quote path (`encode_quote_lens_call` / `decode_quote_lens_return`) — never duplicated route
//! logic. Fail-open on RPC/decode error: a transient error must not strip a working pair;
//! genuinely-dead pairs still surface "no liquidity" at quote time.

use std::str::FromStr;
use std::sync::Arc;

use flutter_rust_bridge::frb;
use futures::stream::{self, StreamExt};
use zilpay::alloy::primitives::{Address as AlloyAddress, U256};
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::network::tron::TronOperations;

use super::{decode_quote_lens_return, encode_quote_lens_call, to_evm_hex, ROUTE_NONE};
use crate::models::exchange::gate::find_meta;
use crate::models::exchange::{ExchangeAsset, ExchangeProvider};
use crate::utils::helpers::handle;

/// Upper bound on concurrent TRON `triggerconstantcontract` probes. Prevents a burst of N
/// simultaneous HTTP calls from rate-limiting or overloading the full node.
const PROBE_CONCURRENCY: usize = 8;

/// Returns indices of `assets` confirmed to have NO SunSwap liquidity (WTRX → token route is empty
/// or returns zero). Skips native tokens and WTRX itself. Fail-open: a transient RPC or decode
/// error leaves the pair in place (no false positives), so quote-time gating still catches
/// genuinely-dead pairs.
#[frb(ignore)]
pub(in crate::models::exchange) async fn evaluate_liquidity_eager(
    assets: &[ExchangeAsset],
) -> Vec<usize> {
    // Find the first SunSwap meta via the generic helper — no clone, no reconstruction.
    let Some(meta) = find_meta(assets, |p| match p {
        ExchangeProvider::SunSwap(m) => Some(m),
        _ => None,
    }) else {
        return Vec::new();
    };
    let cfg = match meta.resolve() {
        Ok(cfg) => cfg,
        Err(err) => {
            eprintln!("[exchange-bootstrap] SunSwap liquidity gate config_error={err}");
            return Vec::new();
        }
    };

    let chain_hash = meta.common.chain_hash;

    // Resolve the NetworkProvider once via the lock-free handle() — not per-probe (avoids N
    // storage reads). Shared across all probes via Arc (cheap refcount clone per future).
    let Ok(core) = handle() else {
        eprintln!("[exchange-bootstrap] SunSwap liquidity gate: service not running");
        return Vec::new();
    };
    let provider = match core.get_provider(chain_hash) {
        Ok(provider) => Arc::new(provider),
        Err(err) => {
            eprintln!(
                "[exchange-bootstrap] SunSwap liquidity gate chain not found chain_hash={chain_hash}: {err}"
            );
            return Vec::new();
        }
    };

    // Collect (asset_index, evm_token_address): probe WTRX → token reachability. The lens routes
    // through configured hubs, covering tokens that only pair via a hub.
    let wtrx_alloy = cfg.addrs.wtrx.to_alloy_addr();
    let candidates: Vec<(usize, AlloyAddress)> = assets
        .iter()
        .enumerate()
        .filter_map(|(idx, asset)| {
            let has_sunswap = asset
                .providers
                .iter()
                .any(|p| matches!(p, ExchangeProvider::SunSwap(_)));
            if !has_sunswap || asset.token.native {
                return None;
            }
            // Token addresses are TRON base58 or EVM hex — resolve to EVM hex for the lens ABI.
            // Same normalization as the quote path (sunswap/mod.rs::to_evm_hex) — DRY.
            let evm_hex = to_evm_hex(&asset.token.addr).ok()?;
            let token = AlloyAddress::from_str(&evm_hex).ok()?;
            if token == wtrx_alloy {
                return None;
            }
            Some((idx, token))
        })
        .collect();

    if candidates.is_empty() {
        return Vec::new();
    }

    let probe_amount = U256::from(crate::models::exchange::gate::probe_amount(
        crate::models::exchange::sunswap::WTRX_DECIMALS,
    ));
    eprintln!(
        "[exchange-bootstrap] SunSwap liquidity gate candidates={} lens={} chain_hash={chain_hash}",
        candidates.len(),
        cfg.addrs.quote_lens.auto_format(),
    );

    // Concurrent tron_constant_call probes — same primitive as the quote path. Each probe carries
    // its own asset index so results are matched by carried index, NOT by stream completion order
    // (buffer_unordered yields in completion order, so positional indexing would misattribute
    // results).
    let probes: Vec<_> = candidates
        .iter()
        .map(|(idx, token)| {
            let provider = Arc::clone(&provider);
            let lens = cfg.addrs.quote_lens.clone();
            let data = encode_quote_lens_call(wtrx_alloy, *token, probe_amount);
            let idx = *idx;
            async move {
                // For a constant (read-only) call the owner is irrelevant — pass the lens
                // address as both owner and contract (two shared borrows, no clone).
                let result = provider
                    .tron_constant_call(&lens, &lens, data)
                    .await
                    .map_err(|err| err.to_string());
                (idx, result)
            }
        })
        .collect();
    let results: Vec<(usize, Result<Vec<u8>, String>)> =
        stream::iter(probes).buffer_unordered(PROBE_CONCURRENCY).collect().await;

    let mut dead = Vec::new();
    for (asset_idx, result) in results {
        // Fail open: only flag no-liquidity on a *decoded* no-liquidity answer.
        let confirmed_no_liquidity = match result {
            Ok(raw) => decode_quote_lens_return(&raw).is_some_and(|quote| {
                quote.route_type == ROUTE_NONE || quote.amount_out == U256::ZERO
            }),
            Err(err) => {
                eprintln!(
                    "[exchange-bootstrap] SunSwap liquidity gate probe_error idx={asset_idx}: {err}"
                );
                false
            }
        };
        if confirmed_no_liquidity {
            dead.push(asset_idx);
        }
    }
    dead
}
