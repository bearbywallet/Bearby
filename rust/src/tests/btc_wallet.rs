#[cfg(test)]
mod btc_wallet_tests {
    use std::{fs, path::Path};

    use tempfile::tempdir;
    use zilpay::background::bg_provider::ProvidersManagement;
    use zilpay::crypto::bip49::DerivationPath;
    use zilpay::rpc::network_config::ChainConfig;

    use crate::api::wallet::{add_bip39_wallet, Bip39AddWalletParams};
    use crate::api::{backend::load_service, provider::get_chains_providers_from_json};
    use crate::models::settings::{WalletArgonParamsInfo, WalletSettingsInfo};
    use crate::service::service::BACKGROUND_SERVICE;

    const PASSWORD: &str = "test_password";
    const BTC_MNEMONIC_STR: &str = "test test test test test test test test test test test junk";

    #[tokio::test]
    async fn test_create_btc_wallet_bip44_legacy() {
        let dir = tempdir().unwrap();
        load_service(dir.path().to_str().unwrap()).await.unwrap();

        let path = Path::new("../assets/chains/testnet-chains.json");
        let content = fs::read_to_string(path).unwrap();
        let providers: Vec<ChainConfig> = get_chains_providers_from_json(content)
            .unwrap()
            .into_iter()
            .map(|c| c.try_into().unwrap())
            .collect();
        let btc_testnet_provider = providers.first().unwrap();

        assert_eq!(btc_testnet_provider.name, "Bitcoin Testnet");
        assert_eq!(btc_testnet_provider.chain, "BTC");

        {
            let guard = BACKGROUND_SERVICE.read().await;
            let service = guard.as_ref().unwrap();
            service
                .core
                .add_provider(btc_testnet_provider.clone())
                .unwrap();
        }

        let wallet_settings = WalletSettingsInfo {
            cipher_orders: vec![0],
            argon_params: WalletArgonParamsInfo {
                memory: 10,
                iterations: 1,
                threads: 1,
                secret: "secret".to_string(),
            },
            currency_convert: "BTC".to_string(),
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
            accounts: vec![(0, "BTC Account".to_string())],
            passphrase: "".to_string(),
            wallet_name: "Bitcoin Wallet".to_string(),
            biometric_type: "none".to_string(),
            chain_hash: btc_testnet_provider.hash(),
            bip_purpose: DerivationPath::BIP44_PURPOSE,
            identifiers: vec![String::from("test btc")],
        };

        let ftokens: Vec<_> = btc_testnet_provider
            .ftokens
            .clone()
            .into_iter()
            .map(Into::into)
            .collect();

        let (session, wallet_address) = add_bip39_wallet(params, wallet_settings, ftokens)
            .await
            .unwrap();

        assert!(!session.is_empty());
        assert!(!wallet_address.is_empty());

        println!("Bitcoin BIP44 wallet created successfully!");
        println!("Wallet address: {}", wallet_address);
    }
}
