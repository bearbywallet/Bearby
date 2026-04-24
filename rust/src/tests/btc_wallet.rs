#[cfg(test)]
mod btc_wallet_tests {
    use std::{fs, path::Path};

    use tempfile::tempdir;
    use zilpay::background::bg_provider::ProvidersManagement;
    use zilpay::rpc::network_config::ChainConfig;

    use crate::api::wallet::{
        add_bip39_wallet, add_next_bip39_account, get_wallets, AddNextBip39AccountParams,
        Bip39AddWalletParams,
    };
    use crate::api::{backend::load_service, provider::get_chains_providers_from_json};
    use crate::models::settings::{WalletArgonParamsInfo, WalletSettingsInfo};
    use crate::service::service::BACKGROUND_SERVICE;

    const PASSWORD: &str = "test_password";
    const BTC_MNEMONIC_STR: &str = "test test test test test test test test test test test junk";

    #[tokio::test]
    async fn test_create_btc_wallet_bip44() {
        let dir = tempdir().unwrap();
        load_service(dir.path().to_str().unwrap()).await.unwrap();

        let path = Path::new("../assets/chains/mainnet-chains.json");
        let content = fs::read_to_string(path).unwrap();
        let providers: Vec<ChainConfig> = get_chains_providers_from_json(content)
            .unwrap()
            .into_iter()
            .map(|c| c.try_into().unwrap())
            .collect();
        let btc_mainnet_provider = providers.first().unwrap();

        assert_eq!(btc_mainnet_provider.name, "Bitcoin");
        assert_eq!(btc_mainnet_provider.chain, "BTC");

        {
            let guard = BACKGROUND_SERVICE.read().await;
            let service = guard.as_ref().unwrap();
            service
                .core
                .add_provider(btc_mainnet_provider.clone())
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
            accounts: vec![(0, "BTC Account 0".to_string())],
            passphrase: "".to_string(),
            wallet_name: "Bitcoin Wallet".to_string(),
            biometric_type: "none".to_string(),
            chain_hash: btc_mainnet_provider.hash(),
        };

        let wallet_address = add_bip39_wallet(params, wallet_settings, vec![])
            .await
            .unwrap();

        assert!(!wallet_address.is_empty());

        add_next_bip39_account(AddNextBip39AccountParams {
            wallet_index: 0,
            account_index: 1,
            name: "BTC Account 1".to_string(),
            passphrase: "".to_string(),
            password: Some(PASSWORD.to_string()),
        })
        .await
        .unwrap();

        add_next_bip39_account(AddNextBip39AccountParams {
            wallet_index: 0,
            account_index: 2,
            name: "BTC Account 2".to_string(),
            passphrase: "".to_string(),
            password: Some(PASSWORD.to_string()),
        })
        .await
        .unwrap();

        println!("Added 2 additional accounts successfully!");

        let expected_bip86 = vec![
            "bc1pfzhx49qe6s5exppe5hqljg3n6587xk0w75xqr70pgdt7ygnfkssqxqjd9l",
            "bc1p0lks35d0spqsvz2t3t0kqus38wrlpmcjtvvupkfkwdrzfh6zjyps9rvd6v",
            "bc1p6f0xvqe892y0fvm2hwnmmj6fzczp7lx6tluvwhymcca4d7a45jjsgzlsdv",
        ];

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();
        let accounts = wallet
            .accounts
            .get(&wallet.slip44)
            .and_then(|m| m.get(&wallet.bip))
            .unwrap();

        println!("BIP86 addresses:");
        for (i, account) in accounts.iter().take(3).enumerate() {
            println!("  Account {}: {}", i, account.addr);
            assert_eq!(
                account.addr, expected_bip86[i],
                "BIP86 Account {} address mismatch",
                i
            );
        }

        println!("\n✓ All address type conversions successful!");
    }
}
