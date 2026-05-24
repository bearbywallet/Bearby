pub mod thorchain;

use std::collections::HashMap;

use flutter_rust_bridge::frb;

use thorchain::ThorchainMetadata;

use super::ftoken::FTokenInfo;
use super::provider::NetworkConfigInfo;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExchangeProviderId {
    Thorchain,
}

#[derive(Debug)]
pub struct ExchangeAsset {
    pub token: FTokenInfo,
    pub provider_asset_id: String,
    pub provider: ExchangeProviderId,
    pub halted: bool,
}

#[derive(Debug, Default)]
pub struct ExchangeChainGroup {
    pub chain_hash: u64,
    pub assets: Vec<ExchangeAsset>,
}

#[derive(Debug, Default)]
pub struct ExchangeQuoteResult {
    pub expected_amount_out: String,
    pub min_amount_in: String,
    pub fees: ExchangeFees,
    pub timing: ExchangeTiming,
    pub warning: String,
    pub notes: String,
    pub tx_params: ExchangeTxParams,
}

#[derive(Debug, Default)]
pub struct ExchangeFees {
    pub total: String,
    pub outbound: String,
    pub liquidity: String,
    pub affiliate: String,
    pub slippage_bps: i64,
    pub total_bps: i64,
}

#[derive(Debug, Default)]
pub struct ExchangeTiming {
    pub inbound_seconds: i64,
    pub outbound_seconds: i64,
    pub total_seconds: i64,
}

#[derive(Debug)]
pub enum ExchangeTxParams {
    Thorchain(ThorchainTxParams),
}

impl Default for ExchangeTxParams {
    fn default() -> Self {
        Self::Thorchain(ThorchainTxParams::default())
    }
}

#[derive(Debug, Default)]
pub struct ThorchainTxParams {
    pub inbound_address: String,
    pub router: String,
    pub memo: String,
    pub expiry: i64,
    pub recommended_gas_rate: String,
    pub gas_rate_units: String,
}

#[frb(ignore)]
pub enum ExchangeProviderMetadata {
    Thorchain(ThorchainMetadata),
}

impl ExchangeProviderId {
    pub fn is_supported(&self, config: &NetworkConfigInfo) -> bool {
        match self {
            Self::Thorchain => thorchain::is_chain_supported(config),
        }
    }
}

#[frb(ignore)]
pub fn build_exchange_chain_groups(
    configs: &[NetworkConfigInfo],
    metadata: &ExchangeProviderMetadata,
    wallet_tokens: &[FTokenInfo],
) -> Vec<ExchangeChainGroup> {
    match metadata {
        ExchangeProviderMetadata::Thorchain(meta) => {
            build_thorchain_groups(configs, meta, wallet_tokens)
        }
    }
}

fn prepare_exchange_token(t: &FTokenInfo) -> FTokenInfo {
    let mut t = t.clone();
    t.balances = HashMap::with_capacity(0);
    t.rate = 0.0;
    t.default = false;
    t
}

fn build_thorchain_groups(
    configs: &[NetworkConfigInfo],
    meta: &ThorchainMetadata,
    wallet_tokens: &[FTokenInfo],
) -> Vec<ExchangeChainGroup> {
    let config_by_chain: HashMap<&str, &NetworkConfigInfo> = {
        let mut map = HashMap::with_capacity(configs.len());
        for c in configs {
            map.insert(c.chain.as_str(), c);
        }
        map
    };

    let halt_status: HashMap<&str, bool> = {
        let mut map = HashMap::with_capacity(meta.inbounds.len());
        for ib in &meta.inbounds {
            let halted = ib.halted || ib.global_trading_paused || ib.chain_trading_paused;
            map.insert(ib.chain.as_str(), halted);
        }
        map
    };

    let mut group_index: HashMap<u64, usize> = HashMap::with_capacity(configs.len());
    let mut groups: Vec<ExchangeChainGroup> = Vec::with_capacity(configs.len());

    for pool in &meta.pools {
        let config = match config_by_chain.get(pool.chain.as_str()) {
            Some(c) => *c,
            None => continue,
        };

        let halted = halt_status
            .get(pool.chain.as_str())
            .copied()
            .unwrap_or(true);
        let is_native = pool.token_addr.is_empty();

        let token = if is_native {
            match wallet_tokens
                .iter()
                .find(|t| t.chain_hash == config.chain_hash && t.native)
            {
                Some(t) => t.clone(),
                None => match config.ftokens.iter().find(|t| t.native) {
                    Some(t) => prepare_exchange_token(t),
                    None => continue,
                },
            }
        } else {
            match wallet_tokens.iter().find(|t| {
                t.chain_hash == config.chain_hash
                    && t.addr.eq_ignore_ascii_case(&pool.token_addr)
            }) {
                Some(t) => t.clone(),
                None => match config
                    .ftokens
                    .iter()
                    .find(|t| t.addr.eq_ignore_ascii_case(&pool.token_addr))
                {
                    Some(t) => prepare_exchange_token(t),
                    None => FTokenInfo {
                        name: pool.symbol.clone(),
                        symbol: pool.symbol.clone(),
                        decimals: pool.decimals,
                        addr: pool.token_addr.clone(),
                        addr_type: 0,
                        logo: None,
                        balances: HashMap::with_capacity(0),
                        rate: 0.0,
                        default: false,
                        native: false,
                        chain_hash: config.chain_hash,
                    },
                },
            }
        };

        let asset = ExchangeAsset {
            token,
            provider_asset_id: pool.asset_id.clone(),
            provider: ExchangeProviderId::Thorchain,
            halted: halted || !pool.available,
        };

        let idx = match group_index.get(&config.chain_hash) {
            Some(&i) => i,
            None => {
                let i = groups.len();
                groups.push(ExchangeChainGroup {
                    chain_hash: config.chain_hash,
                    assets: Vec::with_capacity(4),
                });
                group_index.insert(config.chain_hash, i);
                i
            }
        };
        groups[idx].assets.push(asset);
    }

    groups
}
