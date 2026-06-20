use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{Address as AlloyAddress, U256};
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::network::tron::TronOperations;
use zilpay::proto::address::Address;

use super::math::amount_in_after_fee;
use super::{decode_quote_lens_return, encode_quote_lens_call, QuoteLensQuote, RouteKind, SunConfig};
use crate::utils::errors::ServiceError;
use crate::utils::helpers::with_service;

#[frb(ignore)]
#[derive(Clone, Debug, PartialEq, Eq)]
pub(super) struct RoutePlan {
    pub kind: RouteKind,
    pub amount_out: U256,
}

fn route_from_quote(quote: QuoteLensQuote, token_in: &str, token_out: &str) -> Option<RoutePlan> {
    if quote.route_type == super::ROUTE_NONE || quote.amount_out == U256::ZERO {
        return None;
    }

    let kind = match quote.route_type {
        super::ROUTE_V3_SINGLE => RouteKind::V3 {
            token_in: token_in.to_string(),
            token_out: token_out.to_string(),
            fee_tier: quote.fee_tier,
        },
        super::ROUTE_V3_PATH => RouteKind::V3Path {
            path: hex::encode_prefixed(quote.v3_path),
        },
        _ => return None,
    };

    Some(RoutePlan {
        kind,
        amount_out: quote.amount_out,
    })
}

#[frb(ignore)]
pub(super) async fn quote_route(
    chain_hash: u64,
    cfg: &SunConfig,
    owner_tron: &Address,
    token_in: &str,
    token_out: &str,
    amount_in: &str,
) -> Result<RoutePlan, String> {
    let token_in_addr = AlloyAddress::from_str(token_in).map_err(|e| e.to_string())?;
    let token_out_addr = AlloyAddress::from_str(token_out).map_err(|e| e.to_string())?;
    let gross_amount_in = U256::from_str(amount_in).map_err(|e| e.to_string())?;
    let net_amount_in = amount_in_after_fee(gross_amount_in);

    let data = encode_quote_lens_call(token_in_addr, token_out_addr, net_amount_in);

    let provider = with_service(|core| {
        core.get_provider(chain_hash).map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(|e: ServiceError| e.to_string())?;

    if cfg!(debug_assertions) {
        eprintln!(
            "[sunswap-quote] lens constant_call lens={} chain_hash={chain_hash} chain_id={} \
             token_in={token_in} token_out={token_out} gross={amount_in} net={net_amount_in}",
            cfg.addrs.quote_lens.auto_format(),
            cfg.addrs.chain_id,
        );
    }

    let raw = provider
        .tron_constant_call(owner_tron, &cfg.addrs.quote_lens, data)
        .await
        .map_err(|e| e.to_string())?;
    let quote = decode_quote_lens_return(&raw)
        .ok_or_else(|| "no liquidity for pair".to_string())?;

    route_from_quote(quote, token_in, token_out).ok_or_else(|| "no liquidity for pair".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use super::super::abi::quoteBestRouteCall;
    use zilpay::alloy::sol_types::SolCall;

    fn addr(byte: u8) -> AlloyAddress {
        AlloyAddress::from([byte; 20])
    }

    #[test]
    fn quote_lens_calldata_targets_lens_selector() {
        let data =
            encode_quote_lens_call(addr(0x11), addr(0x22), U256::from(100u64));
        assert_eq!(
            data.get(..4),
            Some(quoteBestRouteCall::SELECTOR.as_slice())
        );
    }

    #[test]
    fn route_from_quote_maps_v3_single_and_path() {
        let token_in = addr(0x11).to_string();
        let token_out = addr(0x22).to_string();

        let v3 = route_from_quote(
            QuoteLensQuote {
                route_type: super::super::ROUTE_V3_SINGLE,
                amount_out: U256::from(11u64),
                fee_tier: 2_500,
                v3_path: Vec::new(),
            },
            &token_in,
            &token_out,
        )
        .expect("v3 route");
        assert!(matches!(
            v3.kind,
            RouteKind::V3 {
                fee_tier: 2_500,
                ..
            }
        ));

        let v3_path_bytes = vec![0x42; 43];
        let v3_path = route_from_quote(
            QuoteLensQuote {
                route_type: super::super::ROUTE_V3_PATH,
                amount_out: U256::from(12u64),
                fee_tier: 0,
                v3_path: v3_path_bytes.clone(),
            },
            &token_in,
            &token_out,
        )
        .expect("v3 path route");
        assert!(
            matches!(v3_path.kind, RouteKind::V3Path { ref path } if hex::decode(path).ok() == Some(v3_path_bytes))
        );
    }

    #[test]
    fn route_from_quote_rejects_none_zero_and_unknown() {
        for (route_type, amount_out) in [
            (super::super::ROUTE_NONE, 1u64),
            (super::super::ROUTE_V3_SINGLE, 0u64),
            (99, 1u64),
        ] {
            assert!(route_from_quote(
                QuoteLensQuote {
                    route_type,
                    amount_out: U256::from(amount_out),
                    fee_tier: 0,
                    v3_path: Vec::new(),
                },
                "0x11",
                "0x22",
            )
            .is_none());
        }
    }
}
