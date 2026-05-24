use flutter_rust_bridge::frb;

use crate::models::{exchange::ExchangeProvider, provider::NetworkConfigInfo};

#[frb(sync)]
pub fn bootstrap_exchange_providers(configs: Vec<NetworkConfigInfo>) -> Vec<ExchangeProvider> {
    if configs.is_empty() {
        return Vec::with_capacity(0);
    }

    let candidates = [
        ExchangeProvider::Thorchain(Default::default()),
        ExchangeProvider::CurveFi(Default::default()),
        ExchangeProvider::Uniswap(Default::default()),
    ];

    let mut result = Vec::with_capacity(candidates.len());

    for candidate in candidates {
        if configs.iter().any(|c| candidate.is_supported(c)) {
            result.push(candidate);
        }
    }

    result
}
