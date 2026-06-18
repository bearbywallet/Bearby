use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{aliases::U160, aliases::U24, Address, U256};
use zilpay::alloy::sol_types::SolCall;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::rpc::{
    common::JsonRPC, methods::EvmMethods, network_config::ChainConfig, provider::RpcProvider,
    zil_interfaces::ResultRes,
};
use zilpay::serde_json::{json, Value};

use super::abi::{quoteExactInputSingleCall, IPlunderRouterV2, QuoteExactInputSingleParams};
use super::math::amount_in_after_fee;
use super::{PlunderConfig, RouteKind};
use crate::utils::errors::ServiceError;
use crate::utils::helpers::with_service;

#[frb(ignore)]
#[derive(Clone, Debug, PartialEq, Eq)]
pub(super) struct RoutePlan {
    pub kind: RouteKind,
    pub amount_out: U256,
}

fn encode_v2_quote(amount_in: U256, path: Vec<Address>) -> Vec<u8> {
    IPlunderRouterV2::getAmountsOutCall {
        amountIn: amount_in,
        path,
    }
    .abi_encode()
}

fn encode_v3_quote(token_in: Address, token_out: Address, amount_in: U256, fee: u32) -> Vec<u8> {
    quoteExactInputSingleCall {
        params: QuoteExactInputSingleParams {
            tokenIn: token_in,
            tokenOut: token_out,
            amountIn: amount_in,
            fee: U24::from(fee),
            sqrtPriceLimitX96: U160::ZERO,
        },
    }
    .abi_encode()
}

fn decode_v2_quote(data: &[u8]) -> Option<U256> {
    IPlunderRouterV2::getAmountsOutCall::abi_decode_returns(data)
        .ok()
        .and_then(|amounts| amounts.last().copied())
}

fn decode_v3_quote(data: &[u8]) -> Option<U256> {
    quoteExactInputSingleCall::abi_decode_returns(data)
        .ok()
        .map(|returns| returns.amountOut)
}

fn decode_result(
    res: &[ResultRes<Value>],
    index: usize,
    decode: fn(&[u8]) -> Option<U256>,
) -> Option<U256> {
    let response = res.get(index).filter(|response| response.error.is_none())?;
    response
        .result
        .as_ref()
        .and_then(|value| value.as_str())
        .and_then(|hex_value| hex::decode(hex_value).ok())
        .and_then(|bytes| decode(&bytes))
        .filter(|amount| *amount > U256::ZERO)
}

#[frb(ignore)]
pub(super) fn best_route(routes: impl IntoIterator<Item = RoutePlan>) -> Option<RoutePlan> {
    routes
        .into_iter()
        .filter(|route| route.amount_out > U256::ZERO)
        .reduce(|best, route| {
            if route.amount_out > best.amount_out {
                route
            } else {
                best
            }
        })
}

fn v2_quote_paths(token_in: Address, token_out: Address, wzil: Address) -> Vec<Vec<Address>> {
    let has_wzil_side = token_in == wzil || token_out == wzil;
    let capacity = if has_wzil_side { 1 } else { 2 };
    let mut paths = Vec::with_capacity(capacity);
    paths.push(Vec::from([token_in, token_out]));
    if !has_wzil_side {
        paths.push(Vec::from([token_in, wzil, token_out]));
    }
    paths
}

fn address_path_to_strings(path: &[Address]) -> Vec<String> {
    path.iter().map(ToString::to_string).collect()
}

fn v2_candidates<'a>(
    res: &'a [ResultRes<Value>],
    paths: &'a [Vec<Address>],
) -> impl Iterator<Item = RoutePlan> + 'a {
    paths.iter().enumerate().filter_map(|(index, path)| {
        decode_result(res, index, decode_v2_quote).map(|amount_out| RoutePlan {
            kind: RouteKind::V2 {
                path: address_path_to_strings(path),
            },
            amount_out,
        })
    })
}

fn v3_candidates<'a>(
    res: &'a [ResultRes<Value>],
    offset: usize,
    fee_tiers: &'a [u32],
    token_in: &'a str,
    token_out: &'a str,
) -> impl Iterator<Item = RoutePlan> + 'a {
    fee_tiers
        .iter()
        .enumerate()
        .filter_map(move |(index, &fee_tier)| {
            decode_result(res, offset + index, decode_v3_quote).map(|amount_out| RoutePlan {
                kind: RouteKind::V3 {
                    token_in: token_in.to_string(),
                    token_out: token_out.to_string(),
                    fee_tier,
                },
                amount_out,
            })
        })
}

#[frb(ignore)]
pub(super) async fn quote_route(
    chain_hash: u64,
    cfg: &PlunderConfig,
    token_in: &str,
    token_out: &str,
    amount_in: &str,
) -> Result<RoutePlan, String> {
    let token_in_addr = Address::from_str(token_in).map_err(|e| e.to_string())?;
    let token_out_addr = Address::from_str(token_out).map_err(|e| e.to_string())?;
    let gross_amount_in = U256::from_str(amount_in).map_err(|e| e.to_string())?;
    let net_amount_in = amount_in_after_fee(gross_amount_in);
    let v2_paths = v2_quote_paths(token_in_addr, token_out_addr, cfg.addrs.wzil);

    let mut calls = Vec::with_capacity(v2_paths.len() + cfg.fee_tiers.len());
    calls.extend(v2_paths.iter().map(|path| {
        let v2_data = encode_v2_quote(net_amount_in, path.clone());
        RpcProvider::<ChainConfig>::build_payload(
            json!([{ "to": cfg.addrs.router_v2.to_string(), "data": hex::encode_prefixed(&v2_data) }, "latest"]),
            EvmMethods::Call,
        )
    }));
    calls.extend(cfg.fee_tiers.iter().map(|&fee_tier| {
        let data = encode_v3_quote(token_in_addr, token_out_addr, net_amount_in, fee_tier);
        RpcProvider::<ChainConfig>::build_payload(
            json!([{ "to": cfg.addrs.quoter_v2.to_string(), "data": hex::encode_prefixed(&data) }, "latest"]),
            EvmMethods::Call,
        )
    }));

    let chain_config = with_service(|core| {
        Ok(core
            .get_provider(chain_hash)
            .map_err(ServiceError::BackgroundError)?
            .config
            .clone())
    })
    .await
    .map_err(|e: ServiceError| e.to_string())?;

    let provider: RpcProvider<ChainConfig> = RpcProvider::new(&chain_config);
    let res = provider
        .req::<Vec<ResultRes<Value>>>(Value::Array(calls))
        .await
        .map_err(|e| e.to_string())?;

    best_route(v2_candidates(&res, &v2_paths).chain(v3_candidates(
        &res,
        v2_paths.len(),
        cfg.fee_tiers,
        token_in,
        token_out,
    )))
    .ok_or_else(|| "no liquidity for pair".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn addr(byte: u8) -> Address {
        Address::from([byte; 20])
    }

    #[test]
    fn v2_quote_paths_include_wzil_intermediary_for_token_pairs() {
        let paths = v2_quote_paths(addr(0x11), addr(0x22), addr(0x94));
        assert_eq!(paths.len(), 2);
        assert_eq!(paths.first(), Some(&Vec::from([addr(0x11), addr(0x22)])));
        assert_eq!(
            paths.get(1),
            Some(&Vec::from([addr(0x11), addr(0x94), addr(0x22)]))
        );
    }

    #[test]
    fn v2_quote_paths_skip_duplicate_wzil_intermediary_for_native_edges() {
        let paths = v2_quote_paths(addr(0x94), addr(0x22), addr(0x94));
        assert_eq!(paths, Vec::from([Vec::from([addr(0x94), addr(0x22)])]));
    }

    #[test]
    fn best_route_picks_largest_output() {
        let token_in = addr(0x11).to_string();
        let token_out = addr(0x22).to_string();
        let best = best_route([
            RoutePlan {
                kind: RouteKind::V2 {
                    path: Vec::from([token_in.clone(), token_out.clone()]),
                },
                amount_out: U256::from(100u64),
            },
            RoutePlan {
                kind: RouteKind::V3 {
                    token_in,
                    token_out,
                    fee_tier: 2_500,
                },
                amount_out: U256::from(101u64),
            },
        ]);
        assert_eq!(best.map(|route| route.amount_out), Some(U256::from(101u64)));
    }

    #[test]
    fn best_route_keeps_first_route_on_tie() {
        let token_in = addr(0x11).to_string();
        let token_out = addr(0x22).to_string();
        let best = best_route([
            RoutePlan {
                kind: RouteKind::V2 {
                    path: Vec::from([token_in.clone(), token_out.clone()]),
                },
                amount_out: U256::from(100u64),
            },
            RoutePlan {
                kind: RouteKind::V3 {
                    token_in,
                    token_out,
                    fee_tier: 2_500,
                },
                amount_out: U256::from(100u64),
            },
        ]);
        assert!(matches!(
            best.map(|route| route.kind),
            Some(RouteKind::V2 { .. })
        ));
    }

    #[test]
    fn quote_calldata_uses_expected_selectors() {
        let token_in = addr(0x11);
        let token_out = addr(0x22);
        let v2 = encode_v2_quote(U256::from(100u64), Vec::from([token_in, token_out]));
        let v3 = encode_v3_quote(token_in, token_out, U256::from(100u64), 2_500);
        assert_eq!(
            v2.get(..4),
            Some(IPlunderRouterV2::getAmountsOutCall::SELECTOR.as_slice())
        );
        assert_eq!(
            v3.get(..4),
            Some(quoteExactInputSingleCall::SELECTOR.as_slice())
        );
    }
}
