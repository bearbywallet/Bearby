use std::{
    collections::HashMap,
    hash::{DefaultHasher, Hash, Hasher},
};

use serde_json::Value;
use zilpay::proto::address::Address;
pub use zilpay::{
    errors::network::NetworkErrors,
    rpc::network_config::{ChainConfig, Explorer},
};

use crate::utils::errors::ServiceError;

use super::ftoken::FTokenInfo;

#[derive(Debug)]
pub struct ExplorerInfo {
    pub name: String,
    pub url: String,
    pub icon: Option<String>,
    pub standard: u16,
}

#[derive(Debug)]
pub struct NetworkConfigInfo {
    pub name: String,
    pub logo: String,
    pub chain: String,
    pub short_name: String,
    pub rpc: Vec<String>,
    pub features: Vec<u16>,
    pub chain_id: u64,
    pub chain_ids: Vec<u64>,
    pub slip_44: u32,
    pub diff_block_time: u64,
    pub chain_hash: u64,
    pub ens: Option<String>,
    pub explorers: Vec<ExplorerInfo>,
    pub fallback_enabled: bool,
    pub testnet: Option<bool>,
    pub ftokens: Vec<FTokenInfo>,
}

impl From<ExplorerInfo> for Explorer {
    fn from(value: ExplorerInfo) -> Self {
        Explorer {
            name: value.name,
            url: value.url,
            icon: value.icon,
            standard: value.standard,
        }
    }
}

impl From<Explorer> for ExplorerInfo {
    fn from(value: Explorer) -> Self {
        Self {
            name: value.name,
            url: value.url,
            icon: value.icon,
            standard: value.standard,
        }
    }
}

impl From<ChainConfig> for NetworkConfigInfo {
    fn from(value: ChainConfig) -> Self {
        let chain_hash = value.hash();
        let chain_id = value.chain_id();
        let explorers = value
            .explorers
            .into_iter()
            .map(ExplorerInfo::from)
            .collect();

        Self {
            chain_id,
            ftokens: value
                .ftokens
                .into_iter()
                .filter_map(|t| t.try_into().ok())
                .collect(),
            logo: value.logo,
            diff_block_time: value.diff_block_time,
            testnet: value.testnet,
            chain_hash,
            name: value.name,
            chain: value.chain,
            short_name: value.short_name,
            chain_ids: value.chain_ids.to_vec(),
            rpc: value.rpc,
            features: value.features,
            slip_44: value.slip_44,
            ens: value.ens.map(|a| a.auto_format()),
            explorers,
            fallback_enabled: value.fallback_enabled,
        }
    }
}

impl TryFrom<NetworkConfigInfo> for ChainConfig {
    type Error = NetworkErrors;

    fn try_from(value: NetworkConfigInfo) -> Result<Self, Self::Error> {
        let chain_ids: [u64; 2] = value
            .chain_ids
            .try_into()
            .map_err(|_| NetworkErrors::InvlaidChainConfig)?;
        let explorers = value.explorers.into_iter().map(Explorer::from).collect();
        let ens = value.ens.and_then(|a| Address::from_str_hex(&a).ok());

        Ok(ChainConfig {
            ftokens: value
                .ftokens
                .into_iter()
                .filter_map(|v| v.try_into().ok())
                .collect(),
            logo: value.logo,
            chain_ids,
            diff_block_time: value.diff_block_time,
            testnet: value.testnet,
            name: value.name,
            chain: value.chain,
            short_name: value.short_name,
            rpc: value.rpc,
            features: value.features,
            slip_44: value.slip_44,
            ens,
            explorers,
            fallback_enabled: value.fallback_enabled,
        })
    }
}

impl NetworkConfigInfo {
    pub fn from_json_value(value: &Value) -> Result<Self, ServiceError> {
        match value {
            Value::Object(obj) => {
                let chain_ids = if let Some(Value::Array(ids)) = obj.get("chainIds") {
                    ids.iter()
                        .filter_map(|id| id.as_u64())
                        .collect::<Vec<u64>>()
                } else {
                    return Err(ServiceError::SerdeSerror(
                        "chainIds is required".to_string(),
                    ));
                };

                let mut hasher = DefaultHasher::new();
                let slip_44 = obj.get("slip44").and_then(|v| v.as_u64()).unwrap_or(0) as u32;
                slip_44.hash(&mut hasher);
                chain_ids.hash(&mut hasher);
                if let Some(chain) = obj.get("chain").and_then(|v| v.as_str()) {
                    chain.hash(&mut hasher);
                }
                let chain_hash = hasher.finish();

                let explorers = if let Some(Value::Array(exp_array)) = obj.get("explorers") {
                    exp_array
                        .iter()
                        .filter_map(|exp| {
                            if let Value::Object(exp_obj) = exp {
                                let name = exp_obj.get("name")?.as_str()?.to_string();
                                let url = exp_obj.get("url")?.as_str()?.to_string();
                                let icon = exp_obj
                                    .get("icon")
                                    .and_then(|v| v.as_str())
                                    .map(String::from);
                                let standard = exp_obj
                                    .get("standard")
                                    .and_then(|v| v.as_str())
                                    .map(|s| {
                                        if s.starts_with("EIP") {
                                            s[3..].parse::<u16>().unwrap_or(0)
                                        } else {
                                            0
                                        }
                                    })
                                    .unwrap_or(0);

                                Some(ExplorerInfo {
                                    name,
                                    url,
                                    icon,
                                    standard,
                                })
                            } else {
                                None
                            }
                        })
                        .collect()
                } else {
                    Vec::new()
                };

                let features = if let Some(Value::Array(feat_array)) = obj.get("features") {
                    feat_array
                        .iter()
                        .filter_map(|f| {
                            if let Some(feature_str) = f.as_str() {
                                if feature_str.starts_with("EIP") {
                                    feature_str[3..].parse::<u16>().ok()
                                } else {
                                    None
                                }
                            } else {
                                None
                            }
                        })
                        .collect()
                } else {
                    Vec::new()
                };

                let ftokens = if let Some(Value::Array(token_array)) = obj.get("ftokens") {
                    token_array
                        .iter()
                        .filter_map(|token| {
                            if let Value::Object(token_obj) = token {
                                let name = token_obj.get("name")?.as_str()?.to_string();
                                let symbol = token_obj.get("symbol")?.as_str()?.to_string();
                                let decimals = token_obj.get("decimals")?.as_u64()? as u8;
                                let addr = token_obj.get("addr")?.as_str()?.to_string();
                                let logo = token_obj
                                    .get("logo")
                                    .and_then(|v| v.as_str())
                                    .map(String::from);
                                let native = token_obj
                                    .get("native")
                                    .and_then(|v| v.as_bool())
                                    .unwrap_or(false);
                                let default = token_obj
                                    .get("default")
                                    .and_then(|v| v.as_bool())
                                    .unwrap_or(false);

                                let addr_type = if addr.starts_with("zil") { 1 } else { 0 };

                                Some(FTokenInfo {
                                    name,
                                    symbol,
                                    decimals,
                                    addr,
                                    addr_type,
                                    logo,
                                    balances: HashMap::new(),
                                    default,
                                    native,
                                    chain_hash,
                                })
                            } else {
                                None
                            }
                        })
                        .collect()
                } else {
                    Vec::with_capacity(0)
                };

                let ens = obj
                    .get("ens")
                    .and_then(|v| v.as_str())
                    .and_then(|str| Some(str.to_string()));

                Ok(NetworkConfigInfo {
                    name: obj
                        .get("name")
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string(),
                    logo: obj
                        .get("logo")
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string(),
                    chain: obj
                        .get("chain")
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string(),
                    short_name: obj
                        .get("shortName")
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string(),
                    rpc: if let Some(Value::Array(rpc_array)) = obj.get("rpc") {
                        rpc_array
                            .iter()
                            .filter_map(|r| r.as_str().map(String::from))
                            .collect()
                    } else {
                        Vec::with_capacity(0)
                    },
                    features,
                    chain_id: chain_ids.first().copied().unwrap_or(0),
                    chain_ids,
                    slip_44: obj.get("slip44").and_then(|v| v.as_u64()).unwrap_or(0) as u32,
                    diff_block_time: obj
                        .get("diff_block_time")
                        .and_then(|v| v.as_u64())
                        .unwrap_or_default(),
                    chain_hash,
                    ens,
                    explorers,
                    fallback_enabled: obj
                        .get("fallback_enabled")
                        .and_then(|v| v.as_bool())
                        .unwrap_or(false),
                    testnet: obj.get("testnet").and_then(|v| v.as_bool()),
                    ftokens,
                })
            }
            _ => Err(ServiceError::SerdeSerror(
                "Expected JSON object".to_string(),
            )),
        }
    }
}
