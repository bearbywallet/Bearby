use flutter_rust_bridge::frb;

use crate::models::{
    exchange::{
        thorchain,
        ExchangeProviderId, ExchangeProviderMetadata, ExchangeChainGroup,
        ExchangeQuoteResult, build_exchange_chain_groups,
    },
    provider::NetworkConfigInfo,
};

#[frb(sync)]
pub fn bootstrap_exchange_providers(configs: Vec<NetworkConfigInfo>) -> Vec<ExchangeProviderId> {
    if configs.is_empty() {
        return Vec::with_capacity(0);
    }

    let candidates = [ExchangeProviderId::Thorchain];
    let mut result = Vec::with_capacity(candidates.len());

    for candidate in candidates {
        if configs.iter().any(|c| candidate.is_supported(c)) {
            result.push(candidate);
        }
    }

    result
}

pub async fn fetch_exchange_assets(
    provider: ExchangeProviderId,
    configs: Vec<NetworkConfigInfo>,
) -> Result<Vec<ExchangeChainGroup>, String> {
    match provider {
        ExchangeProviderId::Thorchain => {
            let meta = thorchain::fetch_thorchain_metadata().await?;
            let metadata = ExchangeProviderMetadata::Thorchain(meta);
            Ok(build_exchange_chain_groups(&configs, &metadata))
        }
    }
}

pub async fn fetch_exchange_quote(
    provider: ExchangeProviderId,
    from_asset: String,
    to_asset: String,
    amount: String,
    destination: String,
) -> Result<ExchangeQuoteResult, String> {
    match provider {
        ExchangeProviderId::Thorchain => {
            let quote = thorchain::fetch_thorchain_swap_quote(
                &from_asset,
                &to_asset,
                &amount,
                &destination,
            )
            .await?;
            Ok(quote.into_quote_result())
        }
    }
}
