#[cfg(test)]
mod exchange_tests {
    use std::fs;
    use std::path::Path;

    use crate::api::backend::load_service;
    use crate::api::exchange::{
        bootstrap_exchange_providers, build_exchange_tx, fetch_exchange_quote,
    };
    use crate::api::provider::get_chains_providers_from_json;
    use crate::api::wallet::{add_bip39_wallet, Bip39AddWalletParams};

    use crate::api::backend::is_service_running;
    use crate::models::exchange::uniswap::V3_FEE_TIERS;
    use crate::models::exchange::{ExchangeAsset, ExchangeProvider, UniswapMeta};
    use crate::models::settings::{WalletArgonParamsInfo, WalletSettingsInfo};
    use crate::service::background::BACKGROUND_SERVICE;
    use tempfile::tempdir;
    use zilpay::background::bg_provider::ProvidersManagement;
    use zilpay::crypto::slip44::ETHEREUM;
    use zilpay::proto::U256;
    use zilpay::rpc::network_config::ChainConfig;
    use zilpay::tokio;
    use zilpay::tokio::sync::Mutex;

    const PASSWORD: &str = "test_password";
    const MNEMONIC_STR: &str = "test test test test test test test test test test test junk";
    // USDC on Ethereum mainnet (6 decimals).
    const USDC_MAINNET: &str = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const ONE_ETH: &str = "1000000000000000000";

    // The service (and its crypto provider) can only be initialized once per process, so
    // all tests share a single boot guarded by this lock.
    static SETUP_DONE: Mutex<bool> = Mutex::const_new(false);

    /// Boot the service exactly once per test process: load mainnet chains and add a
    /// single mainnet-ETH wallet (wallet 0 / account 0). Idempotent across tests.
    async fn setup_eth_wallet() {
        let mut done = SETUP_DONE.lock().await;
        if *done || is_service_running().await {
            *done = true;
            return;
        }

        let dir = tempdir().unwrap();
        let path = dir.path().to_str().unwrap().to_string();
        load_service(&path).await.unwrap();
        // The global service outlives this fn; keep its storage dir alive for the process.
        std::mem::forget(dir);

        let chains = Path::new("../assets/chains/mainnet-chains.json");
        let content = fs::read_to_string(chains).unwrap();
        let providers: Vec<ChainConfig> = get_chains_providers_from_json(content)
            .unwrap()
            .into_iter()
            .map(|c| c.try_into().unwrap())
            .collect();

        {
            let guard = BACKGROUND_SERVICE.read().await;
            let service = guard.as_ref().unwrap();
            service.core.add_batch_providers(providers.clone()).unwrap();
        }

        let eth_chain = providers.iter().find(|c| c.slip_44 == ETHEREUM).unwrap();
        let wallet_settings = WalletSettingsInfo {
            cipher_orders: vec![0],
            argon_params: WalletArgonParamsInfo {
                memory: 10,
                iterations: 1,
                threads: 1,
                secret: "".to_string(),
            },
            currency_convert: "".to_string(),
            ipfs_node: None,
            ens_enabled: false,
            tokens_list_fetcher: false,
            node_ranking_enabled: false,
            max_connections: 0,
            request_timeout_secs: 0,
            rates_api_options: 0,
        };

        let params = Bip39AddWalletParams {
            password: PASSWORD.to_string(),
            mnemonic_str: MNEMONIC_STR.to_string(),
            mnemonic_check: true,
            accounts: vec![(0, "A".to_string())],
            passphrase: "".to_string(),
            wallet_name: "ETH Wallet".to_string(),
            biometric_type: "none".to_string(),
            chain_hash: eth_chain.hash(),
        };

        add_bip39_wallet(params, wallet_settings, vec![])
            .await
            .unwrap();

        *done = true;
    }

    /// Pick the bootstrapped asset that advertises a Uniswap provider, returning both the
    /// asset and its `ExchangeProvider::Uniswap` variant.
    async fn uniswap_asset() -> (ExchangeAsset, ExchangeProvider) {
        let assets = bootstrap_exchange_providers().await.unwrap();
        let asset = assets
            .into_iter()
            .find(|a| {
                a.providers
                    .iter()
                    .any(|p| matches!(p, ExchangeProvider::Uniswap(_)))
            })
            .expect("expected a Uniswap-supported asset");
        let provider = asset
            .providers
            .iter()
            .find(|p| matches!(p, ExchangeProvider::Uniswap(_)))
            .cloned()
            .unwrap();
        (asset, provider)
    }

    #[zilpay::tokio::test]
    async fn test_bootstrap_exchange_providers() {
        setup_eth_wallet().await;

        let assets = bootstrap_exchange_providers().await.unwrap();

        assert!(
            assets.iter().any(|a| {
                a.providers
                    .iter()
                    .any(|p| matches!(p, ExchangeProvider::Uniswap(_)))
            }),
            "mainnet ETH wallet should expose a Uniswap provider"
        );
    }

    #[zilpay::tokio::test]
    async fn test_build_exchange_tx_native() {
        setup_eth_wallet().await;
        let (_, provider) = uniswap_asset().await;
        let meta = UniswapMeta::for_chain(1).unwrap();

        // Native ETH -> USDC. Offline & deterministic (no RPC), so assert strictly.
        let tx = build_exchange_tx(
            0,
            0,
            provider,
            meta.weth.clone(),
            USDC_MAINNET.to_string(),
            ONE_ETH.to_string(),
            "1000000000".to_string(), // 1000 USDC placeholder expected-out
            500,
            50,
            9_999_999_999,
            true,
            None,
            None,
            None,
        )
        .await
        .expect("build native swap tx");

        let evm = tx.evm.expect("evm tx present");
        assert_eq!(evm.chain_id, Some(1));
        assert_eq!(evm.value.as_deref(), Some(ONE_ETH));
        assert_eq!(
            evm.to.as_deref().map(str::to_lowercase),
            Some(meta.universal_router.to_lowercase())
        );
        assert!(evm.data.as_ref().is_some_and(|d| !d.is_empty()));
    }

    /// Live read-only quote against the mainnet RPC. `#[ignore]`d because it needs network
    /// access; run explicitly with: `cargo test -p rust_lib_zilpay exchange -- --ignored`.
    #[zilpay::tokio::test]
    async fn test_fetch_exchange_quote() {
        setup_eth_wallet().await;
        let (asset, _) = uniswap_asset().await;

        let quotes = fetch_exchange_quote(
            asset,
            String::new(),
            USDC_MAINNET.to_string(),
            ONE_ETH.to_string(),
            "0x0000000000000000000000000000000000000001".to_string(),
        )
        .await
        .expect("live uniswap quote");

        assert!(!quotes.is_empty(), "expected at least one quote");

        let quote = &quotes[0];
        let out: U256 = quote.amount_out.parse().unwrap();
        assert!(out > U256::ZERO, "quote should return non-zero output");
        assert!(
            quote.fee_tier.is_some_and(|f| V3_FEE_TIERS.contains(&f)),
            "fee_tier should be one of the probed tiers"
        );
        assert!(
            quote.permit_typed_data_json.is_none(),
            "native input needs no permit"
        );

        dbg!(out, quote.fee_tier);
    }
}
