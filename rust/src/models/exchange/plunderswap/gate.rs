//! PlunderSwap eager liquidity gate. The probe reuses the SAME lens primitive as the quote path
//! (`encode_quote_lens_call` / `decode_quote_lens_return`) — never duplicated route logic. RPC
//! fallback is handled by [`RpcProvider::req`], which iterates the chain's configured `rpc` nodes
//! (see `ChainConfig::urls`) — no hardcoded URLs. Fail-open on RPC/decode error: a transient error
//! must not strip a working pair; genuinely-dead pairs still surface "no liquidity" at quote time.

use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{Address, U256};
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::rpc::{
    common::JsonRPC, methods::EvmMethods, network_config::ChainConfig, provider::RpcProvider,
    zil_interfaces::ResultRes,
};
use zilpay::serde_json::{json, Value};

use super::{decode_quote_lens_return, encode_quote_lens_call, QUOTE_LENS_GAS, ROUTE_NONE};
use crate::models::exchange::gate::find_meta;
use crate::models::exchange::{ExchangeAsset, ExchangeProvider};
use crate::utils::helpers::handle;

/// Returns indices of `assets` confirmed to have NO PlunderSwap liquidity (WZIL → token route is
/// empty or returns zero). Skips native tokens and WZIL itself. Fail-open: a transient RPC or
/// decode error returns an empty vec (no false positives), so quote-time gating still catches
/// genuinely-dead pairs.
#[frb(ignore)]
pub(in crate::models::exchange) async fn evaluate_liquidity_eager(
    assets: &[ExchangeAsset],
) -> Vec<usize> {
    // Find the first PlunderSwap meta via the generic helper — its `common.chain_hash` identifies
    // the Zilliqa chain and `resolve()` yields the lens config. No clone, no reconstruction.
    let Some(meta) = find_meta(assets, |p| match p {
        ExchangeProvider::PlunderSwap(m) => Some(m),
        _ => None,
    }) else {
        return Vec::new();
    };
    let cfg = match meta.resolve() {
        Ok(cfg) => cfg,
        Err(err) => {
            eprintln!("[exchange-bootstrap] Plunder liquidity gate config_error={err}");
            return Vec::new();
        }
    };

    let Ok(core) = handle() else {
        eprintln!("[exchange-bootstrap] Plunder liquidity gate: service not running");
        return Vec::new();
    };
    let chain_config = match core.get_provider(meta.common.chain_hash) {
        Ok(provider) => provider.config,
        Err(err) => {
            eprintln!(
                "[exchange-bootstrap] Plunder liquidity gate chain not found chain_hash={}: {err}",
                meta.common.chain_hash
            );
            return Vec::new();
        }
    };

    // Collect (asset_index, token_address): probe WZIL → token reachability. The lens routes
    // through configured hubs, so this also covers tokens that only pair via a hub (e.g.
    // WZIL → zUSDT → token). A token reachable only through a non-WZIL hub is intentionally
    // gated out — the exchange funds swaps from ZIL/WZIL.
    let candidates: Vec<(usize, Address)> = assets
        .iter()
        .enumerate()
        .filter_map(|(idx, asset)| {
            let has_plunder = asset
                .providers
                .iter()
                .any(|provider| matches!(provider, ExchangeProvider::PlunderSwap(_)));
            if !has_plunder || asset.token.native {
                return None;
            }
            let token = Address::from_str(&asset.token.addr).ok()?;
            if token == cfg.addrs.wzil {
                return None;
            }
            Some((idx, token))
        })
        .collect();

    if candidates.is_empty() {
        return Vec::new();
    }

    let probe_amount = U256::from(crate::models::exchange::gate::probe_amount(
        crate::models::exchange::plunderswap::WZIL_DECIMALS,
    ));
    let calls: Vec<Value> = candidates
        .iter()
        .map(|(_, token)| build_lens_call(cfg.addrs.quote_lens, cfg.addrs.wzil, *token, probe_amount))
        .collect();

    eprintln!(
        "[exchange-bootstrap] Plunder liquidity gate candidates={} lens={} gas=0x{:x}",
        candidates.len(),
        cfg.addrs.quote_lens,
        QUOTE_LENS_GAS,
    );

    let results = match request_batch(&chain_config, Value::Array(calls)).await {
        Ok(results) => results,
        Err(err) => {
            eprintln!("[exchange-bootstrap] Plunder liquidity gate skipped (rpc error): {err}");
            return Vec::new();
        }
    };

    let mut dead = Vec::new();
    for (index, (asset_idx, _token)) in candidates.iter().enumerate() {
        // Positional correlation is safe: RpcProvider::req_evm assigns sequential ids to each
        // batch element and re-sorts the response by id before returning, guaranteeing the reply
        // order matches the request order (rpc/src/provider.rs).
        let confirmed_no_liquidity = results
            .get(index)
            .filter(|item| item.error.is_none())
            .and_then(|item| item.result.as_ref())
            .and_then(Value::as_str)
            .and_then(|raw| hex::decode(raw).ok())
            .and_then(|bytes| decode_quote_lens_return(&bytes))
            .is_some_and(|quote| quote.route_type == ROUTE_NONE || quote.amount_out == U256::ZERO);
        if confirmed_no_liquidity {
            dead.push(*asset_idx);
        }
    }
    dead
}

fn build_lens_call(
    quote_lens: Address,
    token_in: Address,
    token_out: Address,
    amount: U256,
) -> Value {
    let data = encode_quote_lens_call(token_in, token_out, amount);
    RpcProvider::<ChainConfig>::build_payload(
        json!([
            {
                "to": quote_lens.to_string(),
                "data": hex::encode_prefixed(&data),
                "gas": format!("0x{QUOTE_LENS_GAS:x}"),
            },
            "latest"
        ]),
        EvmMethods::Call,
    )
}

/// Batched lens `eth_call`. Fallback across RPC nodes is handled by [`RpcProvider::req`], which
/// iterates `ChainConfig::urls()` — no hardcoded URLs.
async fn request_batch(
    chain_config: &ChainConfig,
    payload: Value,
) -> Result<Vec<ResultRes<Value>>, String> {
    let provider: RpcProvider<ChainConfig> = RpcProvider::new(chain_config);
    provider
        .req::<Vec<ResultRes<Value>>>(payload)
        .await
        .map_err(|err| err.to_string())
}
