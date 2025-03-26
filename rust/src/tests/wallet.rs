#[cfg(test)]
mod wallet_tests {
    use std::{
        fs::{self},
        path::Path,
    };

    use serial_test::serial;
    use tempfile::tempdir;
    use zilpay::{
        background::{bg_provider::ProvidersManagement, bg_wallet::WalletManagement},
        proto::pubkey::PubKey,
        rpc::network_config::ChainConfig,
        wallet::wallet_storage::StorageOperations,
    };

    use crate::{
        api::{
            backend::{get_data, load_service},
            provider::{get_chains_providers_from_json, select_accounts_chain},
            utils::bip39_checksum_valid,
            wallet::{
                add_bip39_wallet, add_next_bip39_account, get_wallets, select_account,
                zilliqa_get_0x, zilliqa_get_bech32_base16_address, zilliqa_swap_chain,
                AddNextBip39AccountParams, Bip39AddWalletParams,
            },
        },
        models::settings::{WalletArgonParamsInfo, WalletSettingsInfo},
        service::service::BACKGROUND_SERVICE,
        utils::utils::{with_service, with_wallet},
    };

    const PASSWORD: &str = "test_password";
    const INVALID_MNEMONIC_STR: &str =
        "use fit orphan skill memory impose attract mobile delay inch ill trophy";
    const VALID_MNEMONIC_STR: &str =
        "use fit skill orphan memory impose attract mobile delay inch ill trophy";

    #[tokio::test]
    #[serial]
    async fn test_a_init_service() {
        let dir = tempdir().unwrap();
        load_service(dir.path().to_str().unwrap()).await.unwrap();

        let wallet_state = get_data().await.unwrap();

        assert_eq!(wallet_state.wallets.len(), 0);
        assert_eq!(wallet_state.providers.len(), 0);
        assert_eq!(wallet_state.notifications_wallet_states.len(), 0);
        assert_eq!(wallet_state.notifications_global_enabled, false);
        assert_eq!(wallet_state.locale, None);
        assert_eq!(wallet_state.appearances, 0);
        assert_eq!(wallet_state.abbreviated_number, true);

        assert_eq!(wallet_state.browser_settings.search_engine_index, 0);
        assert_eq!(wallet_state.browser_settings.cache_enabled, true);
        assert_eq!(wallet_state.browser_settings.cookies_enabled, true);
        assert_eq!(wallet_state.browser_settings.content_blocking, 1);
        assert_eq!(wallet_state.browser_settings.do_not_track, false);
        assert_eq!(wallet_state.browser_settings.incognito_mode, false);

        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().unwrap();

        assert!(service.running);
        assert!(service.block_handle.is_none());
        assert!(service.history_handle.is_none());
    }

    #[test]
    #[serial]
    fn test_b_validate_mnemonic_valid() {
        let valid_mnemonic =
            "use fit skill orphan memory impose attract mobile delay inch ill trophy".to_string();
        assert!(bip39_checksum_valid(valid_mnemonic));
    }

    #[test]
    #[serial]
    fn test_c_validate_mnemonic_invalid() {
        let valid_mnemonic =
            "use fit skill orphan memory impose attract mobile delay inch trophy ill".to_string();
        assert!(!bip39_checksum_valid(valid_mnemonic));
    }

    #[tokio::test]
    #[serial]
    async fn test_d_add_chain_provider() {
        let path = Path::new("../assets/chains/mainnet-chains.json");
        let content = fs::read_to_string(path).unwrap();
        let providers: Vec<ChainConfig> = get_chains_providers_from_json(content)
            .unwrap()
            .into_iter()
            .map(|c| c.try_into().unwrap())
            .collect();
        let zilliqa_provider_mainnet = providers.first().unwrap();

        assert_eq!(zilliqa_provider_mainnet.name, "Zilliqa");
        assert_eq!(zilliqa_provider_mainnet.chain, "ZIL");
        assert_eq!(zilliqa_provider_mainnet.short_name, "zilliqa");
        assert_eq!(zilliqa_provider_mainnet.diff_block_time, 0);
        assert_eq!(zilliqa_provider_mainnet.rpc.len(), 2);
        assert_eq!(zilliqa_provider_mainnet.rpc[0], "https://api.zilliqa.com");
        assert_eq!(zilliqa_provider_mainnet.chain_ids, [32769, 1]);
        assert_eq!(zilliqa_provider_mainnet.slip_44, 313);
        assert_eq!(zilliqa_provider_mainnet.testnet, None);
        assert_eq!(zilliqa_provider_mainnet.explorers.len(), 2);
        assert_eq!(zilliqa_provider_mainnet.explorers[0].name, "Viewblock");
        assert_eq!(zilliqa_provider_mainnet.fallback_enabled, true);
        assert_eq!(zilliqa_provider_mainnet.ftokens.len(), 2);
        assert_eq!(zilliqa_provider_mainnet.ftokens[0].name, "Zilliqa");
        assert_eq!(zilliqa_provider_mainnet.ftokens[0].symbol, "ZIL");
        assert_eq!(zilliqa_provider_mainnet.ftokens[0].decimals, 18);
        assert_eq!(zilliqa_provider_mainnet.ftokens[0].native, true);
        assert_eq!(zilliqa_provider_mainnet.ftokens[1].decimals, 12);

        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().unwrap();

        service
            .core
            .add_provider(zilliqa_provider_mainnet.clone())
            .unwrap();

        let binance_provider_mainnet = &providers[1];

        assert_eq!(binance_provider_mainnet.name, "Binance");
        assert_eq!(binance_provider_mainnet.chain, "BNB");
        assert_eq!(binance_provider_mainnet.short_name, "bnbchain");
        assert_eq!(binance_provider_mainnet.diff_block_time, 0);
        assert_eq!(binance_provider_mainnet.rpc.len(), 7);
        assert_eq!(
            binance_provider_mainnet.rpc[0],
            "https://bsc-dataseed.bnbchain.org"
        );
        assert_eq!(&binance_provider_mainnet.features, &[155, 1559, 4844]);
        assert_eq!(binance_provider_mainnet.chain_ids, [56, 0]);
        assert_eq!(binance_provider_mainnet.slip_44, 60);
        assert_eq!(binance_provider_mainnet.testnet, None);
        assert_eq!(binance_provider_mainnet.explorers.len(), 1);
        assert_eq!(binance_provider_mainnet.explorers[0].name, "Bscscan");
        assert_eq!(binance_provider_mainnet.fallback_enabled, true);
        assert_eq!(binance_provider_mainnet.ftokens.len(), 1);
        assert_eq!(binance_provider_mainnet.ftokens[0].name, "BinanceCoin");
        assert_eq!(binance_provider_mainnet.ftokens[0].symbol, "BNB");
        assert_eq!(binance_provider_mainnet.ftokens[0].decimals, 18);
        assert_eq!(binance_provider_mainnet.ftokens[0].native, true);

        service
            .core
            .add_provider(binance_provider_mainnet.clone())
            .unwrap();
    }

    #[tokio::test]
    #[serial]
    async fn test_e_create_bip39_wallet_check_mnemonic() {
        let params = Bip39AddWalletParams {
            password: PASSWORD.to_string(),
            mnemonic_str: INVALID_MNEMONIC_STR.to_string(),
            mnemonic_check: true,
            accounts: vec![(0, "Account 1".to_string())],
            passphrase: "".to_string(),
            wallet_name: "wallet name".to_string(),
            biometric_type: "faceid".to_string(),
            chain_hash: 0,
            identifiers: vec![String::from("test identifier")],
        };
        let wallet_settings = WalletSettingsInfo {
            cipher_orders: vec![0, 1, 2],
            argon_params: WalletArgonParamsInfo {
                memory: 10,
                iterations: 1,
                threads: 1,
                secret: "".to_string(),
            },
            currency_convert: "BTC".to_string(),
            ipfs_node: None,
            ens_enabled: false,
            gas_control_enabled: false,
            node_ranking_enabled: false,
            max_connections: 0,
            request_timeout_secs: 0,
            rates_api_options: 0,
        };
        let ftokens = vec![];

        assert!(add_bip39_wallet(params, wallet_settings, ftokens)
            .await
            .is_err());
    }

    #[tokio::test]
    #[serial]
    async fn test_f_create_bip39_wallet() {
        let zil_chain_config = {
            let guard = BACKGROUND_SERVICE.read().await;
            let service = guard.as_ref().unwrap();
            let providers = service.core.get_providers();

            providers[0].config.clone()
        };

        let params = Bip39AddWalletParams {
            password: PASSWORD.to_string(),
            mnemonic_str: VALID_MNEMONIC_STR.to_string(),
            mnemonic_check: true,
            accounts: vec![(0, "Account 1".to_string())],
            passphrase: "".to_string(),
            wallet_name: "ZIlliqa Wallet".to_string(),
            biometric_type: "faceId".to_string(),
            chain_hash: zil_chain_config.hash(),
            identifiers: vec![String::from("test identifier")],
        };
        let wallet_settings = WalletSettingsInfo {
            cipher_orders: vec![0, 1, 2],
            argon_params: WalletArgonParamsInfo {
                memory: 10,
                iterations: 1,
                threads: 1,
                secret: "secret".to_string(),
            },
            currency_convert: "BTC".to_string(),
            ipfs_node: None,
            ens_enabled: false,
            gas_control_enabled: false,
            node_ranking_enabled: false,
            max_connections: 0,
            request_timeout_secs: 0,
            rates_api_options: 0,
        };
        let ftokens = vec![];

        let (session, address) = add_bip39_wallet(params, wallet_settings.clone(), ftokens)
            .await
            .unwrap();

        assert!(!session.is_empty());
        assert!(!address.is_empty());

        let wallets = get_wallets().await.unwrap();

        assert_eq!(wallets.len(), 1);

        {
            assert_eq!(wallets[0].tokens.len(), 2);
            assert_eq!(wallets[0].tokens[0].chain_hash, zil_chain_config.hash());
            assert_eq!(wallets[0].tokens[1].chain_hash, zil_chain_config.hash());
            assert_eq!(
                wallets[0].tokens[0].addr,
                "0x0000000000000000000000000000000000000000"
            );
            assert_eq!(
                wallets[0].tokens[1].addr,
                "zil1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq9yf6pz"
            );
            assert_eq!(wallets[0].tokens[1].decimals, 12);
            assert_eq!(wallets[0].tokens[0].decimals, 18);
            assert_eq!(wallets[0].tokens[0].addr_type, 1);
            assert_eq!(wallets[0].tokens[1].addr_type, 0);
            assert!(wallets[0].tokens[1].native);
            assert!(wallets[0].tokens[0].native);
        }

        let wallet = wallets.first().unwrap();

        assert_eq!(wallet.wallet_type, "SecretPhrase.false");
        assert_eq!(wallet.wallet_name, "ZIlliqa Wallet");
        assert_eq!(wallet.auth_type, "faceId");
        assert_eq!(wallet.wallet_address, address);
        assert_eq!(&wallet.wallet_address, &address);
        assert_eq!(wallet.accounts.len(), 1);
        assert_eq!(wallet.selected_account, 0);
        assert_eq!(wallet.tokens.len(), 2); // 2 because Zilliqa legacy and EVM

        assert_eq!(wallet.default_chain_hash, zil_chain_config.hash());

        let selected_account = &wallet.accounts[wallet.selected_account];

        assert_eq!(selected_account.name, "Account 1");
        assert_eq!(selected_account.index, 0);
        assert_eq!(selected_account.chain_hash, zil_chain_config.hash());
        assert_eq!(selected_account.chain_id, zil_chain_config.chain_id());
        assert_eq!(selected_account.slip_44, zil_chain_config.slip_44);
        assert_eq!(selected_account.addr_type, 1); // Secp256k1Keccak256

        with_service(|core| {
            let wallet = core.get_wallet_by_index(0).unwrap();
            let data = wallet.get_wallet_data().unwrap();
            let selected_account = data.get_selected_account().unwrap();

            match selected_account.pub_key {
                PubKey::Secp256k1Keccak256(_) => {
                    assert!(true);
                }
                _ => {
                    panic!("invalid pubkey type");
                }
            }

            assert_eq!(
                "0103feba86ca2043ac21bcf111f43658d3303f3a0d508e4c01c83e357788937cd234",
                selected_account.pub_key.to_string()
            );
            Ok(())
        })
        .await
        .unwrap();

        let address = zilliqa_get_0x(0, 0).await.unwrap();

        assert_eq!(address, "0x790D36BE13b747656d9E0D2a0c521DCB313ab4f9");

        let (bech32, base16) = zilliqa_get_bech32_base16_address(0, 0).await.unwrap();

        assert_eq!("0x66316a684F83e7265B82C7eFE46f2E47ec074D7d", base16);
        assert_eq!("zil1vcck56z0s0njvkuzclh7gmewglkqwntazq7h2l", bech32);

        zilliqa_swap_chain(0, 0).await.unwrap();

        with_wallet(0, |wallet| {
            let data = wallet.get_wallet_data().unwrap();
            let selected_account = data.get_selected_account().unwrap();

            assert_eq!(
                selected_account.pub_key.to_string(),
                "0003feba86ca2043ac21bcf111f43658d3303f3a0d508e4c01c83e357788937cd234"
            );
            assert_eq!(selected_account.chain_hash, zil_chain_config.hash());
            assert_ne!(selected_account.chain_id, zil_chain_config.chain_id());
            assert_eq!(selected_account.chain_id, zil_chain_config.chain_ids[1]);
            assert_eq!(selected_account.slip_44, zil_chain_config.slip_44);
            assert_eq!(
                selected_account.addr.auto_format(),
                "zil1vcck56z0s0njvkuzclh7gmewglkqwntazq7h2l"
            );

            Ok(())
        })
        .await
        .unwrap();

        add_next_bip39_account(AddNextBip39AccountParams {
            wallet_index: 0,
            account_index: 1,
            name: "Second account".to_string(),
            passphrase: String::new(),
            identifiers: vec![String::from("test identifier")],
            password: None,
            session_cipher: Some(session),
        })
        .await
        .unwrap();

        select_account(0, 1).await.unwrap();

        with_wallet(0, |wallet| {
            let data = wallet.get_wallet_data().unwrap();
            let selected_account = data.get_selected_account().unwrap();

            assert_eq!(data.selected_account, 1);
            assert_eq!(selected_account.chain_hash, data.default_chain_hash);
            assert_eq!(selected_account.name, "Second account");
            assert_eq!(selected_account.account_type.code(), 1);
            assert_eq!(
                selected_account.pub_key.to_string(),
                "010317743c1830dada97f96c51fa439b7a0673700ee38c71ccb117c9f0e974af522e"
            );
            assert_eq!(selected_account.chain_id, zil_chain_config.chain_id());
            assert_eq!(selected_account.slip_44, zil_chain_config.slip_44);

            Ok(())
        })
        .await
        .unwrap();
        let bsc_chain_config = {
            let guard = BACKGROUND_SERVICE.read().await;
            let service = guard.as_ref().unwrap();
            let providers = service.core.get_providers();

            providers[1].config.clone()
        };

        select_accounts_chain(0, bsc_chain_config.hash())
            .await
            .unwrap();
    }
}
