use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::U256;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::rpc::{
    common::JsonRPC, methods::ZilMethods, network_config::ChainConfig, provider::RpcProvider,
    zil_interfaces::ResultRes,
};
use zilpay::serde_json::{json, Value};

use crate::utils::errors::ServiceError;
use crate::utils::helpers::with_service;

use super::addr::{strip_0x, with_0x_lower};

#[frb(ignore)]
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct PoolReserves {
    pub zil: U256,
    pub token: U256,
}

fn parse_u256_value(value: Option<&Value>) -> Result<U256, String> {
    value
        .and_then(Value::as_str)
        .ok_or_else(|| "missing numeric field".to_string())
        .and_then(|v| U256::from_str(v).map_err(|e| e.to_string()))
}

fn rpc_error<T>(res: &ResultRes<T>) -> Option<String> {
    res.error.as_ref().map(ToString::to_string)
}

async fn chain_config(chain_hash: u64) -> Result<ChainConfig, String> {
    with_service(|core| {
        Ok(core
            .get_provider(chain_hash)
            .map_err(ServiceError::BackgroundError)?
            .config
            .clone())
    })
    .await
    .map_err(|e: ServiceError| e.to_string())
}

fn pool_from_result(res: &ResultRes<Value>, token_base16: &str) -> Result<PoolReserves, String> {
    if let Some(err) = rpc_error(res) {
        return Err(err);
    }

    let key = with_0x_lower(token_base16);
    let key_no_prefix = strip_0x(&key);
    let pools = res
        .result
        .as_ref()
        .and_then(|value| value.get("pools"))
        .ok_or_else(|| "missing pools substate".to_string())?;
    let pool = pools
        .get(&key)
        .or_else(|| pools.get(key_no_prefix))
        .ok_or_else(|| "pool not found".to_string())?;
    let args = pool
        .get("arguments")
        .and_then(Value::as_array)
        .ok_or_else(|| "invalid pool arguments".to_string())?;
    let zil = parse_u256_value(args.first())?;
    let token = parse_u256_value(args.get(1))?;

    Ok(PoolReserves { zil, token })
}

#[frb(ignore)]
pub async fn fetch_pool(
    chain_hash: u64,
    core_base16: &str,
    token_base16: &str,
) -> Result<PoolReserves, String> {
    let pools = fetch_pools_for(chain_hash, core_base16, &[token_base16]).await?;
    pools
        .first()
        .copied()
        .ok_or_else(|| "pool not found".to_string())
}

#[frb(ignore)]
pub async fn fetch_pools_for(
    chain_hash: u64,
    core_base16: &str,
    token_base16: &[&str],
) -> Result<Vec<PoolReserves>, String> {
    if token_base16.is_empty() {
        return Ok(Vec::with_capacity(0));
    }

    let config = chain_config(chain_hash).await?;
    let provider: RpcProvider<ChainConfig> = RpcProvider::new(&config);
    let contract = strip_0x(core_base16);
    let requests = token_base16
        .iter()
        .map(|token| {
            let key = with_0x_lower(token);
            RpcProvider::<ChainConfig>::build_payload(
                json!([contract, "pools", [key]]),
                ZilMethods::GetSmartContractSubState,
            )
        })
        .collect::<Vec<Value>>();

    let results = provider
        .req::<Vec<ResultRes<Value>>>(Value::Array(requests))
        .await
        .map_err(|e| e.to_string())?;

    if results.len() != token_base16.len() {
        return Err("pool response length mismatch".to_string());
    }

    results
        .iter()
        .zip(token_base16.iter())
        .map(|(res, token)| pool_from_result(res, token))
        .collect()
}

#[frb(ignore)]
pub async fn fetch_allowance(
    chain_hash: u64,
    token_base16: &str,
    owner: &str,
    spender: &str,
) -> Result<U256, String> {
    let config = chain_config(chain_hash).await?;
    let provider: RpcProvider<ChainConfig> = RpcProvider::new(&config);
    let owner_key = owner.to_ascii_lowercase();
    let spender_key = spender.to_ascii_lowercase();
    let payload = RpcProvider::<ChainConfig>::build_payload(
        json!([
            strip_0x(token_base16),
            "allowances",
            [&owner_key, &spender_key]
        ]),
        ZilMethods::GetSmartContractSubState,
    );

    let res = provider
        .req::<ResultRes<Value>>(payload)
        .await
        .map_err(|e| e.to_string())?;
    if let Some(err) = rpc_error(&res) {
        return Err(err);
    }

    let allowance = res
        .result
        .as_ref()
        .and_then(|value| value.get("allowances"))
        .and_then(|value| value.get(&owner_key))
        .and_then(|value| value.get(&spender_key))
        .and_then(Value::as_str)
        .and_then(|value| U256::from_str(value).ok())
        .unwrap_or(U256::ZERO);

    Ok(allowance)
}

#[frb(ignore)]
pub async fn fetch_deadline_block(chain_hash: u64, window: u64) -> Result<u64, String> {
    let config = chain_config(chain_hash).await?;
    let provider: RpcProvider<ChainConfig> = RpcProvider::new(&config);
    let payload =
        RpcProvider::<ChainConfig>::build_payload(json!([]), ZilMethods::GetBlockchainInfo);
    let res = provider
        .req::<ResultRes<Value>>(payload)
        .await
        .map_err(|e| e.to_string())?;
    if let Some(err) = rpc_error(&res) {
        return Err(err);
    }

    let current = res
        .result
        .as_ref()
        .and_then(|value| value.get("NumTxBlocks"))
        .and_then(|value| {
            value
                .as_str()
                .and_then(|s| s.parse::<u64>().ok())
                .or_else(|| value.as_u64())
        })
        .ok_or_else(|| "missing NumTxBlocks".to_string())?;

    Ok(current.saturating_add(window))
}
