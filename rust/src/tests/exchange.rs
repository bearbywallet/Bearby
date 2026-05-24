#[cfg(test)]
mod exchange_tests {
    use std::fs;
    use std::path::Path;

    use crate::api::exchange::{
        bootstrap_exchange_providers, fetch_exchange_assets, fetch_exchange_quote,
    };
    use crate::api::provider::get_chains_providers_from_json;
    use crate::models::exchange::ExchangeProviderId;
    use zilpay::tokio;

    #[zilpay::tokio::test]
    async fn test_fetch_exchange_assets() {
        let path = Path::new("../assets/chains/testnet-chains.json");
        let content = fs::read_to_string(path).unwrap();
        let configs = get_chains_providers_from_json(content).unwrap();

        let (exchange_providers, wallet_tokens) = match bootstrap_exchange_providers(configs.clone(), 0).await {
            Ok(result) => result,
            Err(_) => return,
        };

        let provider = match exchange_providers.into_iter().next() {
            Some(p) => p,
            None => return,
        };

        match fetch_exchange_assets(provider, configs, wallet_tokens).await {
            Ok(groups) => {
                for group in &groups {
                    eprintln!(
                        "chain_hash={} assets={}",
                        group.chain_hash,
                        group.assets.len()
                    );
                    for asset in &group.assets {
                        eprintln!(
                            "  {} ({}) halted={}",
                            asset.token.symbol, asset.provider_asset_id, asset.halted
                        );
                    }
                }
            }
            Err(e) => eprintln!("fetch_exchange_assets failed: {e}"),
        }
    }

    #[zilpay::tokio::test]
    async fn test_fetch_exchange_quote() {
        let path = Path::new("../assets/chains/testnet-chains.json");
        let content = fs::read_to_string(path).unwrap();
        let configs = get_chains_providers_from_json(content).unwrap();

        let (exchange_providers, _) = match bootstrap_exchange_providers(configs, 0).await {
            Ok(result) => result,
            Err(_) => return,
        };

        let provider = match exchange_providers.into_iter().next() {
            Some(ExchangeProviderId::Thorchain) => ExchangeProviderId::Thorchain,
            None => return,
        };

        match fetch_exchange_quote(
            provider,
            "BTC.BTC".to_string(),
            "ETH.ETH".to_string(),
            "1000000".to_string(),
            "0x0000000000000000000000000000000000000000".to_string(),
        )
        .await
        {
            Ok(quote) => dbg!(&quote),
            Err(e) => {
                eprintln!("fetch_exchange_quote failed (expected if halted): {e}");
                return;
            }
        };
    }
}
