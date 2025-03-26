#[cfg(test)]
mod wallet_tests {
    use std::{
        fs::{self},
        path::Path,
    };

    use serial_test::serial;
    use tempfile::tempdir;
    use zilpay::{background::bg_provider::ProvidersManagement, rpc::network_config::ChainConfig};

    use crate::{
        api::{
            backend::{get_data, load_service},
            provider::get_chains_providers_from_json,
            utils::bip39_checksum_valid,
            wallet::{add_bip39_wallet, get_wallets, Bip39AddWalletParams},
        },
        models::settings::{WalletArgonParamsInfo, WalletSettingsInfo},
        service::service::BACKGROUND_SERVICE,
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
        let chain_config = {
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
            chain_hash: chain_config.hash(),
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

        let wallet = wallets.first().unwrap();

        assert_eq!(wallet.wallet_type, "SecretPhrase.false");
        assert_eq!(wallet.wallet_name, "ZIlliqa Wallet");
        assert_eq!(wallet.auth_type, "faceId");
        assert_eq!(wallet.wallet_address, address);
        assert_eq!(&wallet.wallet_address, &address);
        assert_eq!(wallet.accounts.len(), 1);
        assert_eq!(wallet.selected_account, 0);
        assert_eq!(wallet.tokens.len(), 2); // 2 because Zilliqa legacy and EVM

        assert_eq!(wallet.default_chain_hash, chain_config.hash());
    }
}
