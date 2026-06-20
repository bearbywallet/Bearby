#[cfg(test)]
mod exchange_tests {
    use std::fs;
    use std::path::Path;

    use crate::api::backend::load_service;
    use crate::api::exchange::{
        bootstrap_exchange_providers, finalize_exchange_swap, prepare_exchange_swap,
        refresh_exchange_quotes,
    };
    use crate::api::provider::get_chains_providers_from_json;
    use crate::api::wallet::{add_bip39_wallet, Bip39AddWalletParams};

    use crate::api::backend::is_service_running;
    use crate::models::exchange::{
        ExchangeAsset, ExchangeProvider, ExchangeTxDisplay, SwapAuth, SwapParams,
    };
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
            let core = crate::service::background::CORE.load_full().unwrap();
            core.add_batch_providers(providers.clone()).unwrap();
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

    /// Pick the bootstrapped native-ETH (chain 1) asset with a Uniswap provider, the USDC (chain 1)
    /// destination asset, and the `ExchangeProvider::Uniswap` variant.
    async fn uniswap_asset() -> (ExchangeAsset, ExchangeAsset, ExchangeProvider) {
        let assets = bootstrap_exchange_providers(0, 0).unwrap();
        let asset = assets
            .iter()
            .find(|a| {
                a.token.native
                    && a.providers.iter().any(
                        |p| matches!(p, ExchangeProvider::Uniswap(m) if m.common.chain_id == 1),
                    )
            })
            .cloned()
            .expect("expected native ETH (chain 1) with a Uniswap provider");
        let usdc = assets
            .iter()
            .find(|a| a.token.addr.eq_ignore_ascii_case(USDC_MAINNET))
            .cloned()
            .expect("expected USDC (chain 1) in the catalog");
        let provider = asset
            .providers
            .iter()
            .find(|p| matches!(p, ExchangeProvider::Uniswap(m) if m.common.chain_id == 1))
            .cloned()
            .unwrap();
        (asset, usdc, provider)
    }

    #[zilpay::tokio::test]
    async fn test_bootstrap_exchange_providers() {
        setup_eth_wallet().await;

        let assets = bootstrap_exchange_providers(0, 0).unwrap();

        assert!(
            assets.iter().any(|a| {
                a.providers
                    .iter()
                    .any(|p| matches!(p, ExchangeProvider::Uniswap(_)))
            }),
            "mainnet ETH wallet should expose a Uniswap provider"
        );
    }

    /// Live build via on-chain quoting: native ETH -> USDC on mainnet (no permit, one
    /// batched `eth_call`). `#[ignore]`d because it needs network access; run explicitly with:
    /// `cargo test -p rust_lib_zilpay exchange -- --ignored`.
    #[ignore]
    #[zilpay::tokio::test]
    async fn test_build_exchange_tx_native() {
        setup_eth_wallet().await;
        let (eth, usdc, provider) = uniswap_asset().await;

        let auth = SwapAuth {
            wallet_index: 0,
            account_index: 0,
            password: None,
            passphrase: None,
        };
        let params = SwapParams {
            provider: provider.clone(),
            from: eth,
            to: usdc,
            amount_in: ONE_ETH.to_string(),
            slippage_bps: 50,
        };
        let prepared = prepare_exchange_swap(params)
            .await
            .expect("prepare native swap");
        assert!(
            prepared.permit_typed_data_json.is_none(),
            "native input needs no permit"
        );

        let tx = finalize_exchange_swap(
            auth,
            provider,
            prepared.quote_blob,
            None,
            0,
            ExchangeTxDisplay {
                swap_title: "Swap".to_string(),
                swap_info: "1 ETH → 1000 USDC · Uniswap".to_string(),
                approve_title: "Approve".to_string(),
                permit_title: "Permit".to_string(),
                out_token: None,
            },
        )
        .await
        .expect("finalize native swap tx");

        let evm = tx.evm.expect("evm tx present");
        assert_eq!(evm.chain_id, Some(1));
        assert_eq!(evm.value.as_deref(), Some(ONE_ETH));
        assert!(evm.to.as_deref().is_some_and(|t| t.len() == 42));
        assert!(evm.data.as_ref().is_some_and(|d| !d.is_empty()));
    }

    /// Live read-only quote against the mainnet RPC. `#[ignore]`d because it needs network
    /// access; run explicitly with: `cargo test -p rust_lib_zilpay exchange -- --ignored`.
    #[ignore]
    #[zilpay::tokio::test]
    async fn test_refresh_exchange_quotes() {
        setup_eth_wallet().await;
        let (asset, usdc, _) = uniswap_asset().await;

        let quoted = refresh_exchange_quotes(asset, usdc, ONE_ETH.to_string())
            .await
            .expect("live uniswap quote");

        let provider = quoted
            .providers
            .iter()
            .find(|provider| provider.quote().is_some())
            .expect("expected at least one quote");
        let quote = provider.quote().expect("quote checked above");
        let out: U256 = quote.amount_out.parse().unwrap();
        assert!(out > U256::ZERO, "quote should return non-zero output");
        assert!(
            quote.permit_typed_data_json.is_none(),
            "native input needs no permit"
        );

        dbg!(out);
    }
}
