#[cfg(test)]
mod exchange_tests {
    use std::fs;
    use std::path::Path;

    use crate::api::backend::load_service;
    use crate::api::exchange::bootstrap_exchange_providers;
    use crate::api::provider::get_chains_providers_from_json;
    use crate::api::wallet::{add_bip39_wallet, Bip39AddWalletParams};

    use crate::models::settings::{WalletArgonParamsInfo, WalletSettingsInfo};
    use crate::service::background::BACKGROUND_SERVICE;
    use tempfile::tempdir;
    use zilpay::background::bg_provider::ProvidersManagement;
    use zilpay::crypto::slip44::ETHEREUM;
    use zilpay::rpc::network_config::ChainConfig;
    use zilpay::tokio;

    const PASSWORD: &str = "test_password";
    const BTC_MNEMONIC_STR: &str = "test test test test test test test test test test test junk";

    #[zilpay::tokio::test]
    async fn test_fetch_exchange_assets() {
        let dir = tempdir().unwrap();
        load_service(dir.path().to_str().unwrap()).await.unwrap();

        let path = Path::new("../assets/chains/mainnet-chains.json");
        let content = fs::read_to_string(path).unwrap();
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

        let btc_chain = providers.iter().find(|c| c.slip_44 == ETHEREUM).unwrap();
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
            mnemonic_str: BTC_MNEMONIC_STR.to_string(),
            mnemonic_check: true,
            accounts: vec![(0, "A".to_string())],
            passphrase: "".to_string(),
            wallet_name: "ETH Wallet".to_string(),
            biometric_type: "none".to_string(),
            chain_hash: btc_chain.hash(),
        };

        add_bip39_wallet(params, wallet_settings, vec![])
            .await
            .unwrap();

        let result = bootstrap_exchange_providers().await;

        dbg!(&result);

        // let provider = match exchange_providers.into_iter().next() {
        //     Some(p) => p,
        //     None => return,
        // };

        // match fetch_exchange_assets(provider, configs, wallet_tokens).await {
        //     Ok(groups) => {
        //         for group in &groups {
        //             eprintln!(
        //                 "chain_hash={} assets={}",
        //                 group.chain_hash,
        //                 group.assets.len()
        //             );
        //             for asset in &group.assets {
        //                 eprintln!(
        //                     "  {} ({}) halted={}",
        //                     asset.token.symbol, asset.provider_asset_id, asset.halted
        //                 );
        //             }
        //         }
        //     }
        //     Err(e) => eprintln!("fetch_exchange_assets failed: {e}"),
        // }
    }

    // #[zilpay::tokio::test]
    // async fn test_fetch_exchange_quote() {
    //     let path = Path::new("../assets/chains/testnet-chains.json");
    //     let content = fs::read_to_string(path).unwrap();
    //     let configs = get_chains_providers_from_json(content).unwrap();

    //     let (exchange_providers, _) = match bootstrap_exchange_providers(configs, 0).await {
    //         Ok(result) => result,
    //         Err(_) => return,
    //     };

    //     let provider = match exchange_providers.into_iter().next() {
    //         Some(ExchangeProviderId::Thorchain) => ExchangeProviderId::Thorchain,
    //         None => return,
    //     };

    //     match fetch_exchange_quote(
    //         provider,
    //         "BTC.BTC".to_string(),
    //         "ETH.ETH".to_string(),
    //         "1000000".to_string(),
    //         "0x0000000000000000000000000000000000000000".to_string(),
    //     )
    //     .await
    //     {
    //         Ok(quote) => dbg!(&quote),
    //         Err(e) => {
    //             eprintln!("fetch_exchange_quote failed (expected if halted): {e}");
    //             return;
    //         }
    //     };
    // }
}
