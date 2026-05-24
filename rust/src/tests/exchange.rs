#[cfg(test)]
mod exchange_tests {
    use std::fs;
    use std::path::Path;

    use crate::api::exchange::bootstrap_exchange_providers;
    use crate::api::provider::get_chains_providers_from_json;

    #[tokio::test]
    async fn test_bootstrap_exchange_providers() {
        let path = Path::new("../assets/chains/testnet-chains.json");
        let content = fs::read_to_string(path).unwrap();
        let providers = get_chains_providers_from_json(content).unwrap();
        let exchange_providers = bootstrap_exchange_providers(providers);
        dbg!(&exchange_providers);
    }
}
