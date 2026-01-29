#[cfg(test)]
mod btc_wallet_tests {
    use std::{fs, path::Path};

    use tempfile::tempdir;
    use zilpay::background::bg_provider::ProvidersManagement;
    use zilpay::crypto::bip49::DerivationPath;
    use zilpay::rpc::network_config::ChainConfig;

    use crate::api::wallet::{
        add_bip39_wallet, add_next_bip39_account, bitcoin_change_address_type, get_wallets,
        AddNextBip39AccountParams, Bip39AddWalletParams,
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
            bip_purpose: DerivationPath::BIP84_PURPOSE,
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

        // Expected addresses for each BIP type
        let expected_bip44 = vec![
            "1Ei9UmLQv4o4UJTy5r5mnGFeC9auM3W5P1",
            "14RBPsg6mBkLSJokkzeuoCkTtoeD3nK2Kz",
            "1CvVq3DvykCiuKztE29EsLzvmgbbcWQWBr",
        ];

        let expected_bip49 = vec![
            "39sr5B8UAdxeoXbnpdw4frfxXwWwEChwzp",
            "37EtUYWDGFUYhF65JqZMkkiUd4dDmwHv8J",
            "3B9F7Smod2KrRVT4tzodovWhxk4YEJyr7J",
        ];

        let expected_bip84 = vec![
            "bc1q4qw42stdzjqs59xvlrlxr8526e3nunw7mp73te",
            "bc1qp533522veg9uyhpx3sva9vqrnfzmt262n4lsuq",
            "bc1qt3az9lwpqfvr466mezsewuzdc4d379ldv83d4c",
        ];

        let expected_bip86 = vec![
            "bc1pfzhx49qe6s5exppe5hqljg3n6587xk0w75xqr70pgdt7ygnfkssqxqjd9l",
            "bc1p0lks35d0spqsvz2t3t0kqus38wrlpmcjtvvupkfkwdrzfh6zjyps9rvd6v",
            "bc1p6f0xvqe892y0fvm2hwnmmj6fzczp7lx6tluvwhymcca4d7a45jjsgzlsdv",
        ];

        // Test BIP44 (Legacy P2PKH)
        println!("\n=== Testing BIP44 (Legacy P2PKH) ===");
        bitcoin_change_address_type(0, "p2pkh".to_string(), Some(PASSWORD.to_string()), None)
            .await
            .unwrap();

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();
        println!("BIP44 addresses:");
        for (i, account) in wallet.accounts.iter().take(3).enumerate() {
            println!("  Account {}: {}", i, account.addr);
            assert_eq!(
                account.addr, expected_bip44[i],
                "BIP44 Account {} address mismatch",
                i
            );
        }

        // Test BIP49 (Nested SegWit P2SH-P2WPKH)
        println!("\n=== Testing BIP49 (Nested SegWit P2SH-P2WPKH) ===");
        bitcoin_change_address_type(0, "p2sh".to_string(), Some(PASSWORD.to_string()), None)
            .await
            .unwrap();

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();
        println!("BIP49 addresses:");
        for (i, account) in wallet.accounts.iter().take(3).enumerate() {
            println!("  Account {}: {}", i, account.addr);
            assert_eq!(
                account.addr, expected_bip49[i],
                "BIP49 Account {} address mismatch",
                i
            );
        }

        // Test BIP84 (Native SegWit Bech32 P2WPKH)
        println!("\n=== Testing BIP84 (Native SegWit Bech32 P2WPKH) ===");
        bitcoin_change_address_type(0, "p2wpkh".to_string(), Some(PASSWORD.to_string()), None)
            .await
            .unwrap();

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();
        println!("BIP84 addresses:");
        for (i, account) in wallet.accounts.iter().take(3).enumerate() {
            println!("  Account {}: {}", i, account.addr);
            assert_eq!(
                account.addr, expected_bip84[i],
                "BIP84 Account {} address mismatch",
                i
            );
        }

        // Test BIP86 (Taproot Bech32m P2TR)
        println!("\n=== Testing BIP86 (Taproot Bech32m P2TR) ===");
        bitcoin_change_address_type(0, "p2tr".to_string(), Some(PASSWORD.to_string()), None)
            .await
            .unwrap();

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();
        println!("BIP86 addresses:");
        for (i, account) in wallet.accounts.iter().take(3).enumerate() {
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
