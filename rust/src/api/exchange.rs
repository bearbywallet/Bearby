use flutter_rust_bridge::frb;

use crate::models::{
    exchange::{thorchain, ExchangeProvider},
    provider::NetworkConfigInfo,
};

#[frb(sync)]
pub fn bootstrap_exchange_providers(configs: Vec<NetworkConfigInfo>) -> Vec<ExchangeProvider> {
    if configs.is_empty() {
        return Vec::with_capacity(0);
    }

    let candidates = [ExchangeProvider::Thorchain(Default::default())];

    let mut result = Vec::with_capacity(candidates.len());

    for candidate in candidates {
        if configs.iter().any(|c| candidate.is_supported(c)) {
            result.push(candidate);
        }
    }

    result
}

pub async fn fetch_exchange_provider_data(
    provider: ExchangeProvider,
    from_asset: String,
    to_asset: String,
    amount: String,
    destination: String,
) -> Result<ExchangeProvider, String> {
    match provider {
        ExchangeProvider::Thorchain(_) => {
            let metadata = thorchain::fetch_thorchain_data(
                &from_asset,
                &to_asset,
                &amount,
                &destination,
            )
            .await?;
            Ok(ExchangeProvider::Thorchain(metadata))
        }
    }
}

pub async fn build_exchange_transaction(
    _provider: ExchangeProvider,
) -> Result<String, String> {
    todo!()
}
