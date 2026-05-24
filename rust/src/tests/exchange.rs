#[cfg(test)]
mod exchange_tests {
    use std::fs;
    use std::path::Path;

    use crate::api::exchange::{bootstrap_exchange_providers, fetch_exchange_provider_data};
    use crate::api::provider::get_chains_providers_from_json;
    use zilpay::tokio;

    #[zilpay::tokio::test]
    async fn test_fetch_exchange_provider_data() {
        let path = Path::new("../assets/chains/testnet-chains.json");
        let content = fs::read_to_string(path).unwrap();
        let providers = get_chains_providers_from_json(content).unwrap();
        let exchange_providers = bootstrap_exchange_providers(providers);

        let provider = match exchange_providers.into_iter().next() {
            Some(p) => p,
            None => return,
        };

        let result = fetch_exchange_provider_data(
            provider,
            "BTC.BTC".to_string(),
            "ETH.ETH".to_string(),
            "1000000".to_string(),
            "0x0000000000000000000000000000000000000000".to_string(),
        )
        .await;

        match result {
            Ok(provider) => dbg!(&provider),
            Err(e) => {
                eprintln!("fetch_exchange_provider_data failed (expected if halted): {e}");
                return;
            }
        };
    }
}
