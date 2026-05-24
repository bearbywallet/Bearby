use flutter_rust_bridge::frb;

use crate::models::{
    exchange::{
        thorchain, ExchangeProviderId, ExchangeProviderMetadata, ExchangeProviderQuote,
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

pub async fn fetch_exchange_metadata(
    provider: ExchangeProviderId,
) -> Result<ExchangeProviderMetadata, String> {
    match provider {
        ExchangeProviderId::Thorchain => {
            let inbound = thorchain::fetch_thorchain_inbound().await?;
            Ok(ExchangeProviderMetadata::Thorchain(inbound))
        }
    }
}

pub async fn fetch_exchange_quote(
    provider: ExchangeProviderId,
    from_asset: String,
    to_asset: String,
    amount: String,
    destination: String,
) -> Result<ExchangeProviderQuote, String> {
    match provider {
        ExchangeProviderId::Thorchain => {
            let quote = thorchain::fetch_thorchain_swap_quote(
                &from_asset,
                &to_asset,
                &amount,
                &destination,
            )
            .await?;
            Ok(ExchangeProviderQuote::Thorchain(quote))
        }
    }
}
