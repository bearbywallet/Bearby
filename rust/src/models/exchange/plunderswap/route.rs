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

use super::math::amount_in_after_fee;
use super::{
    decode_quote_lens_return, encode_quote_lens_call, PlunderConfig, QuoteLensQuote, RouteKind,
    QUOTE_LENS_GAS, ROUTE_NONE, ROUTE_V2, ROUTE_V3_PATH, ROUTE_V3_SINGLE,
};
use crate::utils::errors::ServiceError;
use crate::utils::helpers::with_service;

#[frb(ignore)]
#[derive(Clone, Debug, PartialEq, Eq)]
pub(super) struct RoutePlan {
    pub kind: RouteKind,
    pub amount_out: U256,
}

fn quote_call_object(
    cfg: &PlunderConfig,
    token_in: Address,
    token_out: Address,
    amount_in: U256,
) -> Value {
    let data = encode_quote_lens_call(token_in, token_out, amount_in);
    json!({
        "to": cfg.addrs.quote_lens.to_string(),
        "data": hex::encode_prefixed(&data),
        "gas": format!("0x{QUOTE_LENS_GAS:x}"),
    })
}

fn decode_result(item: &ResultRes<Value>) -> Option<QuoteLensQuote> {
    if item.error.is_some() {
        return None;
    }
    item.result
        .as_ref()
        .and_then(Value::as_str)
        .and_then(|hex_value| hex::decode(hex_value).ok())
        .and_then(|bytes| decode_quote_lens_return(&bytes))
}

fn route_from_quote(quote: QuoteLensQuote, token_in: &str, token_out: &str) -> Option<RoutePlan> {
    if quote.route_type == ROUTE_NONE || quote.amount_out == U256::ZERO {
        return None;
    }

    let kind = match quote.route_type {
        ROUTE_V2 => RouteKind::V2 {
            path: quote.v2_path.iter().map(ToString::to_string).collect(),
        },
        ROUTE_V3_SINGLE => RouteKind::V3 {
            token_in: token_in.to_string(),
            token_out: token_out.to_string(),
            fee_tier: quote.fee_tier,
        },
        ROUTE_V3_PATH => RouteKind::V3Path {
            path: hex::encode_prefixed(quote.v3_path),
        },
        _ => return None,
    };

    Some(RoutePlan {
        kind,
        amount_out: quote.amount_out,
    })
}

async fn request_quote(
    chain_config: &ChainConfig,
    payload: &Value,
) -> Result<Vec<ResultRes<Value>>, String> {
    let provider: RpcProvider<ChainConfig> = RpcProvider::new(chain_config);
    match provider.req::<Vec<ResultRes<Value>>>(payload.clone()).await {
        Ok(res) => Ok(res),
        Err(primary_error) => {
            eprintln!("[plunderswap-quote] lens eth_call transport_error={primary_error}");
            if chain_config.chain_id() != super::ZILLIQA_MAINNET_CHAIN_ID {
                return Err(primary_error.to_string());
            }

            let client = zilpay::reqwest::Client::new();
            let mut fallback_error = primary_error.to_string();
            for url in ["https://api.zilliqa.com/evm", "https://api.zilliqa.com"] {
                eprintln!("[plunderswap-quote] retry lens eth_call rpc_url={url}");
                let response = client.post(url).json(payload).send().await;
                match response {
                    Ok(response) => match response.json::<Vec<ResultRes<Value>>>().await {
                        Ok(res) => return Ok(res),
                        Err(err) => fallback_error = err.to_string(),
                    },
                    Err(err) => fallback_error = err.to_string(),
                }
            }

            Err(fallback_error)
        }
    }
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

    let call = RpcProvider::<ChainConfig>::build_payload(
        json!([
            quote_call_object(cfg, token_in_addr, token_out_addr, net_amount_in),
            "latest"
        ]),
        EvmMethods::Call,
    );

    let chain_config = with_service(|core| {
        Ok(core
            .get_provider(chain_hash)
            .map_err(ServiceError::BackgroundError)?
            .config
            .clone())
    })
    .await
    .map_err(|e: ServiceError| e.to_string())?;

    if cfg!(debug_assertions) {
        eprintln!(
            "[plunderswap-quote] lens eth_call lens={} gas=0x{QUOTE_LENS_GAS:x} \
             chain_hash={chain_hash} chain_id={} token_in={token_in} token_out={token_out} \
             gross={amount_in} net={net_amount_in} rpc_nodes={}",
            cfg.addrs.quote_lens,
            cfg.addrs.chain_id,
            chain_config.rpc.join(","),
        );
    }

    let payload = Value::Array(vec![call]);
    let res = request_quote(&chain_config, &payload).await?;
    let quote = res
        .first()
        .and_then(decode_result)
        .ok_or_else(|| "no liquidity for pair".to_string())?;

    route_from_quote(quote, token_in, token_out).ok_or_else(|| "no liquidity for pair".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use zilpay::alloy::sol_types::SolCall;

    fn addr(byte: u8) -> Address {
        Address::from([byte; 20])
    }

    fn cfg() -> PlunderConfig {
        PlunderConfig {
            addrs: crate::models::exchange::plunderswap::PlunderAddrs {
                chain_id: 32_769,
                fee_router: addr(0xa1),
                wzil: addr(0x94),
                quote_lens: addr(0xbe),
            },
        }
    }

    #[test]
    fn quote_call_object_targets_lens_and_sets_gas() {
        let value = quote_call_object(&cfg(), addr(0x11), addr(0x22), U256::from(100u64));
        assert_eq!(
            value.get("to").and_then(Value::as_str),
            Some(addr(0xbe).to_string().as_str())
        );
        assert_eq!(value.get("gas").and_then(Value::as_str), Some("0x989680"));
        let data = value
            .get("data")
            .and_then(Value::as_str)
            .and_then(|raw| hex::decode(raw).ok())
            .expect("calldata");
        assert_eq!(
            data.get(..4),
            Some(super::super::abi::quoteBestRouteCall::SELECTOR.as_slice())
        );
    }

    #[test]
    fn route_from_quote_maps_all_lens_route_types() {
        let token_in = addr(0x11).to_string();
        let token_out = addr(0x22).to_string();

        let v2 = route_from_quote(
            QuoteLensQuote {
                route_type: ROUTE_V2,
                amount_out: U256::from(10u64),
                fee_tier: 0,
                v2_path: vec![addr(0x11), addr(0x55), addr(0x22)],
                v3_path: Vec::new(),
            },
            &token_in,
            &token_out,
        )
        .expect("v2 route");
        assert!(matches!(v2.kind, RouteKind::V2 { ref path } if path.len() == 3));

        let v3 = route_from_quote(
            QuoteLensQuote {
                route_type: ROUTE_V3_SINGLE,
                amount_out: U256::from(11u64),
                fee_tier: 2_500,
                v2_path: Vec::new(),
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
                route_type: ROUTE_V3_PATH,
                amount_out: U256::from(12u64),
                fee_tier: 0,
                v2_path: Vec::new(),
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
        for (route_type, amount_out) in [(ROUTE_NONE, 1u64), (ROUTE_V2, 0u64), (99, 1u64)] {
            assert!(route_from_quote(
                QuoteLensQuote {
                    route_type,
                    amount_out: U256::from(amount_out),
                    fee_tier: 0,
                    v2_path: vec![addr(0x11), addr(0x22)],
                    v3_path: Vec::new(),
                },
                "0x11",
                "0x22",
            )
            .is_none());
        }
    }
}
