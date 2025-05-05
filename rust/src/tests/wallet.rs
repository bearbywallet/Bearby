#[cfg(test)]
mod wallet_tests {
    use std::time::Duration;
    use std::{
        fs::{self},
        path::Path,
        sync::atomic::AtomicU8,
    };

    use tempfile::tempdir;
    use zilpay::config::key::SECRET_KEY_SIZE;
    use zilpay::proto::keypair::KeyPair;
    use zilpay::proto::secret_key::SecretKey;
    use zilpay::{
        background::{bg_provider::ProvidersManagement, bg_wallet::WalletManagement},
        proto::pubkey::PubKey,
        rpc::network_config::ChainConfig,
        wallet::wallet_storage::StorageOperations,
    };

    use crate::api::token::{add_ftoken, fetch_token_meta};
    use crate::api::transaction::{cacl_gas_fee, create_token_transfer, TokenTransferParamsInfo};
    use crate::api::wallet::{add_sk_wallet, AddSKWalletParams};
    use crate::{
        api::{
            backend::{get_data, load_service},
            provider::{get_chains_providers_from_json, select_accounts_chain},
            utils::bip39_checksum_valid,
            wallet::{
                add_bip39_wallet, add_next_bip39_account, delete_account, delete_wallet,
                get_wallets, make_keystore_file, restore_from_keystore, reveal_bip39_phrase,
                reveal_keypair, select_account, zilliqa_get_bech32_base16_address,
                zilliqa_get_n_format, zilliqa_swap_chain, AddNextBip39AccountParams,
                Bip39AddWalletParams,
            },
        },
        models::settings::{WalletArgonParamsInfo, WalletSettingsInfo},
        service::service::BACKGROUND_SERVICE,
        utils::utils::{with_service, with_wallet},
    };
    use lazy_static::lazy_static;

    lazy_static! {
        pub static ref GUARD: AtomicU8 = AtomicU8::new(1);
    }

    async fn wait_for(expected: u8) {
        while GUARD.load(std::sync::atomic::Ordering::Relaxed) != expected {
            tokio::time::sleep(Duration::from_millis(10)).await;
        }
    }

    const PASSWORD: &str = "test_password";
    const INVALID_MNEMONIC_STR: &str =
        "use fit orphan skill memory impose attract mobile delay inch ill trophy";
    const VALID_MNEMONIC_STR: &str =
        "use fit skill orphan memory impose attract mobile delay inch ill trophy";
    const SK: &str = "e8351e8eb0057b809b9c3ea4e9286a6f4f5d9281cddfa77c1f52c3359ce34bad";
    const ZLP_ADDR: &str = "zil1l0g8u6f9g0fsvjuu74ctyla2hltefrdyt7k5f4";

    #[tokio::test]
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

        GUARD.store(2, std::sync::atomic::Ordering::Relaxed);
    }

    #[test]
    fn test_b_validate_mnemonic_valid() {
        let valid_mnemonic =
            "use fit skill orphan memory impose attract mobile delay inch ill trophy".to_string();
        assert!(bip39_checksum_valid(valid_mnemonic));
    }

    #[test]
    fn test_c_validate_mnemonic_invalid() {
        let valid_mnemonic =
            "use fit skill orphan memory impose attract mobile delay inch trophy ill".to_string();
        assert!(!bip39_checksum_valid(valid_mnemonic));
    }

    #[tokio::test]
    async fn test_d_add_chain_provider() {
        wait_for(2).await;

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
        assert_eq!(zilliqa_provider_mainnet.rpc.len(), 4);
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

        let path = Path::new("../assets/chains/testnet-chains.json");
        let content = fs::read_to_string(path).unwrap();
        let providers: Vec<ChainConfig> = get_chains_providers_from_json(content)
            .unwrap()
            .into_iter()
            .map(|c| c.try_into().unwrap())
            .collect();
        let zilliqa_protomainnet_provider = providers.first().unwrap();

        service
            .core
            .add_provider(zilliqa_protomainnet_provider.clone())
            .unwrap();

        GUARD.store(3, std::sync::atomic::Ordering::Relaxed);
    }

    #[tokio::test]
    async fn test_e_create_bip39_wallet_check_mnemonic() {
        wait_for(3).await;

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
            tokens_list_fetcher: false,
            node_ranking_enabled: false,
            max_connections: 0,
            request_timeout_secs: 0,
            rates_api_options: 0,
        };
        let ftokens = vec![];

        assert!(add_bip39_wallet(params, wallet_settings, ftokens)
            .await
            .is_err());

        GUARD.store(4, std::sync::atomic::Ordering::Relaxed);
    }

    #[tokio::test]
    async fn test_f_create_bip39_wallet() {
        wait_for(4).await;

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
            tokens_list_fetcher: false,
            node_ranking_enabled: false,
            max_connections: 0,
            request_timeout_secs: 0,
            rates_api_options: 0,
        };
        let ftokens = vec![];

        let (session, wallet_address) = add_bip39_wallet(params, wallet_settings.clone(), ftokens)
            .await
            .unwrap();

        assert!(!session.is_empty());
        assert!(!wallet_address.is_empty());

        let wallets = get_wallets().await.unwrap();

        assert_eq!(wallets.len(), 1);

        {
            assert_eq!(wallets[0].tokens.len(), 1);
            assert_eq!(wallets[0].tokens[0].chain_hash, zil_chain_config.hash());
            assert_eq!(
                wallets[0].tokens[0].addr,
                "0x0000000000000000000000000000000000000000"
            );
            assert_eq!(wallets[0].tokens[0].decimals, 18);
            assert_eq!(wallets[0].tokens[0].addr_type, 1);
            assert!(wallets[0].tokens[0].native);
        }

        let wallet = wallets.first().unwrap();

        assert_eq!(wallet.wallet_type, "SecretPhrase.false");
        assert_eq!(wallet.wallet_name, "ZIlliqa Wallet");
        assert_eq!(wallet.auth_type, "faceId");
        assert_eq!(wallet.wallet_address, wallet_address);
        assert_eq!(&wallet.wallet_address, &wallet_address);
        assert_eq!(wallet.accounts.len(), 1);
        assert_eq!(wallet.selected_account, 0);
        assert_eq!(wallet.tokens.len(), 1);
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

        let address = zilliqa_get_n_format(0, 0).await.unwrap();

        assert_eq!(address, "zil10yxnd0snkark2mv7p54qc5saevcn4d8eaauhca");

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

        let zil_testnet_chain_config = {
            let guard = BACKGROUND_SERVICE.read().await;
            let service = guard.as_ref().unwrap();
            let providers = service.core.get_providers();

            providers[2].config.clone()
        };

        select_accounts_chain(0, zil_testnet_chain_config.hash())
            .await
            .unwrap();

        add_next_bip39_account(AddNextBip39AccountParams {
            wallet_index: 0,
            account_index: 1,
            name: "Second account".to_string(),
            passphrase: String::new(),
            identifiers: vec![String::from("test identifier")],
            password: None,
            session_cipher: Some(session.clone()),
        })
        .await
        .unwrap();

        select_account(0, 1).await.unwrap();

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();

        assert_eq!(wallet.tokens.len(), 1);

        with_wallet(0, |wallet| {
            let data = wallet.get_wallet_data().unwrap();
            let selected_account = data.get_selected_account().unwrap();

            assert_eq!(data.selected_account, 1);
            assert_eq!(selected_account.chain_hash, zil_testnet_chain_config.hash());
            assert_eq!(selected_account.name, "Second account");
            assert_eq!(selected_account.account_type.code(), 1);
            assert_eq!(
                selected_account.pub_key.to_string(),
                "010317743c1830dada97f96c51fa439b7a0673700ee38c71ccb117c9f0e974af522e"
            );
            assert_eq!(
                selected_account.chain_id,
                zil_testnet_chain_config.chain_id()
            );
            assert_eq!(selected_account.slip_44, zil_chain_config.slip_44);
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

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();

        assert_eq!(wallets.len(), 1);
        assert_eq!(wallet.wallet_type, "SecretPhrase.false");
        assert_eq!(wallet.wallet_name, "ZIlliqa Wallet");
        assert_eq!(wallet.auth_type, "faceId");
        assert_eq!(wallet.wallet_address, wallet_address);
        assert_eq!(wallet.accounts.len(), 2);
        assert_eq!(wallet.selected_account, 1);
        assert_eq!(wallet.default_chain_hash, zil_chain_config.hash());

        {
            assert_eq!(wallet.tokens.len(), 1);

            let token = &wallet.tokens[0];
            assert_eq!(token.name, "BinanceCoin");
            assert_eq!(token.symbol, "BNB");
            assert_eq!(token.decimals, 18);
            assert_eq!(token.addr, "0x0000000000000000000000000000000000000000");
            assert_eq!(token.addr_type, 1);
            assert_eq!(
        token.logo,
        Some("https://raw.githubusercontent.com/zilpay/zilpay-cdn/refs/heads/main/icons/%{shortName}%/%{symbol}%/%{dark,light}%.webp".to_string())
    );
            assert!(token.balances.is_empty());
            assert_eq!(token.rate, 0.0);
            assert!(!token.default);
            assert!(token.native);
            assert_eq!(token.chain_hash, bsc_chain_config.hash());
        }

        {
            let account1 = &wallet.accounts[0];
            assert_eq!(account1.addr, "0x790D36BE13b747656d9E0D2a0c521DCB313ab4f9");
            assert_eq!(account1.addr_type, 1);
            assert_eq!(account1.name, "Account 1");
            assert_eq!(account1.chain_hash, bsc_chain_config.hash());
            assert_eq!(account1.chain_id, bsc_chain_config.chain_id());
            assert_eq!(account1.slip_44, bsc_chain_config.slip_44);
            assert_eq!(account1.index, 0);

            let account2 = &wallet.accounts[1];
            assert_eq!(account2.addr, "0xab92316Bd8f486C773C80EC88A00721A35f2D1de");
            assert_eq!(account2.addr_type, 1);
            assert_eq!(account2.name, "Second account");
            assert_eq!(account2.chain_hash, bsc_chain_config.hash());
            assert_eq!(account2.chain_id, bsc_chain_config.chain_id());
            assert_eq!(account2.slip_44, bsc_chain_config.slip_44);
            assert_eq!(account2.index, 1);
        }

        {
            assert_eq!(wallet.settings.cipher_orders, vec![0, 1, 2]);

            assert_eq!(wallet.settings.argon_params.memory, 10);
            assert_eq!(wallet.settings.argon_params.iterations, 1);
            assert_eq!(wallet.settings.argon_params.threads, 1);
            assert_eq!(
                wallet.settings.argon_params.secret,
                "2bb80d537b1da3e38bd30361aa855686bde0eacd7162fef6a25fe97bf527a25b"
            );

            assert_eq!(wallet.settings.currency_convert, "BTC");
            assert!(wallet.settings.ipfs_node.is_none());

            assert!(!wallet.settings.ens_enabled);
            assert!(!wallet.settings.tokens_list_fetcher);
            assert!(!wallet.settings.node_ranking_enabled);
            assert_eq!(wallet.settings.max_connections, 0);
            assert_eq!(wallet.settings.request_timeout_secs, 0);
            assert_eq!(wallet.settings.rates_api_options, 0);

            // try add next account with binance smart chain network
            add_next_bip39_account(AddNextBip39AccountParams {
                wallet_index: 0,
                account_index: 2,
                name: "account 3".to_string(),
                passphrase: String::new(),
                identifiers: vec![String::from("test identifier")],
                password: None,
                session_cipher: Some(session.clone()),
            })
            .await
            .unwrap();

            let wallets = get_wallets().await.unwrap();
            let wallet = wallets.first().unwrap();

            {
                let account3 = &wallet.accounts[2];

                for acc in &wallet.accounts {
                    assert_eq!(account3.chain_hash, acc.chain_hash);
                    assert_eq!(account3.chain_id, acc.chain_id);
                    assert_eq!(account3.slip_44, acc.slip_44);
                }

                assert_eq!(account3.addr, "0x1DA83F5b443cc87FBdC6ec06E40F4098C1592210");
                assert_eq!(account3.addr_type, 1);
                assert_eq!(account3.name, "account 3");
                assert_eq!(account3.index, 2);
            }

            select_accounts_chain(0, zil_chain_config.hash())
                .await
                .unwrap();
            zilliqa_swap_chain(0, 2).await.unwrap();

            let wallets = get_wallets().await.unwrap();
            let wallet = wallets.first().unwrap();

            {
                let account3 = &wallet.accounts[2];
                assert_eq!(account3.addr, "zil1xancfmqvv6nhwdf8uwy79xd7fr2t94ejqr3xs8");
                assert_eq!(account3.addr_type, 0);
                assert_eq!(account3.name, "account 3");
                assert_eq!(account3.chain_hash, wallet.default_chain_hash);
                assert_eq!(
                    &account3.chain_id,
                    zil_chain_config.chain_ids.last().unwrap()
                );
                assert_eq!(account3.slip_44, zil_chain_config.slip_44);
                assert_eq!(account3.index, 2);
            }

            with_wallet(0, |wallet| {
                let ftokens = wallet.get_ftokens().unwrap();
                assert_eq!(ftokens.len(), 3);
                Ok(())
            })
            .await
            .unwrap();

            let words = reveal_bip39_phrase(
                0,
                vec![String::from("test identifier")],
                PASSWORD.to_string(),
                None,
            )
            .await
            .unwrap();

            assert_eq!(words, VALID_MNEMONIC_STR);

            let keypair2 = reveal_keypair(
                0,
                2,
                vec![String::from("test identifier")],
                PASSWORD.to_string(),
                None,
            )
            .await
            .unwrap();
            let keypair0 = reveal_keypair(
                0,
                0,
                vec![String::from("test identifier")],
                PASSWORD.to_string(),
                None,
            )
            .await
            .unwrap();

            assert_eq!(
                keypair0.pk,
                "03feba86ca2043ac21bcf111f43658d3303f3a0d508e4c01c83e357788937cd234"
            );
            assert_eq!(
                keypair0.sk,
                "9a46a88b33c8c5b0c34532d461cc564dcc499ba74b5327c8a1d4cd145d53af2c"
            );

            assert_eq!(
                keypair2.pk,
                "02e839fb64c54e634678d8ab1432472186012fa9177f8b2ba834793ede02cc503f"
            );
            assert_eq!(
                keypair2.sk,
                "0a82ab0e408290b46b509a9d573ae35302e3017f5f50c57fdd5f4b78c9dea14a"
            );

            delete_account(0, 2).await.unwrap();
            delete_account(0, 1).await.unwrap();

            let wallets = get_wallets().await.unwrap();
            let wallet = wallets.first().unwrap();

            assert_eq!(wallet.accounts.len(), 1);

            let keystore_bytes = make_keystore_file(
                0,
                PASSWORD.to_string(),
                vec![String::from("test identifier")],
            )
            .await
            .unwrap();

            delete_wallet(
                0,
                vec![String::from("test identifier")],
                None,
                Some(session),
            )
            .await
            .unwrap();

            let wallets = get_wallets().await.unwrap();

            assert_eq!(wallets.len(), 0);

            let (_, new_address) = restore_from_keystore(
                keystore_bytes,
                vec![String::from("new identifier")],
                PASSWORD.to_string(),
                "fingerprint".to_string(),
            )
            .await
            .unwrap();
            let wallets = get_wallets().await.unwrap();
            let wallet = wallets.first().unwrap();

            assert_eq!(wallets.len(), 1);
            assert_eq!(wallet.wallet_address, new_address);
            assert_eq!(wallet.wallet_name, "ZIlliqa Wallet");
            assert_eq!(wallet.wallet_type, "SecretPhrase.false");
            assert_eq!(wallet.auth_type, "fingerprint");
            assert_eq!(wallet.selected_account, 0);
            assert_eq!(wallet.default_chain_hash, zil_chain_config.hash());
            assert_eq!(wallet.accounts.len(), 1);

            {
                assert_eq!(
                    wallet.accounts[0].addr,
                    "0x790D36BE13b747656d9E0D2a0c521DCB313ab4f9"
                );
                assert_eq!(wallet.accounts[0].addr_type, 1);
                assert_eq!(wallet.accounts[0].chain_hash, zil_chain_config.hash());
                assert_eq!(wallet.accounts[0].chain_id, zil_chain_config.chain_id());
                assert_eq!(wallet.accounts[0].slip_44, zil_chain_config.slip_44);
                assert_eq!(wallet.accounts[0].index, 0);
            }

            let words = reveal_bip39_phrase(
                0,
                vec![String::from("new identifier")],
                PASSWORD.to_string(),
                None,
            )
            .await
            .unwrap();

            assert_eq!(words, VALID_MNEMONIC_STR);

            let keypair0 = reveal_keypair(
                0,
                0,
                vec![String::from("new identifier")],
                PASSWORD.to_string(),
                None,
            )
            .await
            .unwrap();

            assert_eq!(
                keypair0.pk,
                "03feba86ca2043ac21bcf111f43658d3303f3a0d508e4c01c83e357788937cd234"
            );
            assert_eq!(
                keypair0.sk,
                "9a46a88b33c8c5b0c34532d461cc564dcc499ba74b5327c8a1d4cd145d53af2c"
            );
        }

        delete_wallet(
            0,
            vec![String::from("new identifier")],
            Some(PASSWORD.to_string()),
            None,
        )
        .await
        .unwrap();

        GUARD.store(5, std::sync::atomic::Ordering::Relaxed);
    }

    #[tokio::test]
    async fn test_c_create_sk_wallet() {
        wait_for(5).await;
        let zil_chain_config = {
            let guard = BACKGROUND_SERVICE.read().await;
            let service = guard.as_ref().unwrap();
            let providers = service.core.get_providers();

            providers[0].config.clone()
        };
        let params = AddSKWalletParams {
            sk: SK.to_string(),
            password: PASSWORD.to_string(),
            wallet_name: "SK Wallet".to_string(),
            biometric_type: "faceId".to_string(),
            identifiers: vec![String::from("test sk identifier")],
            chain_hash: zil_chain_config.hash(),
        };
        let wallet_settings = WalletSettingsInfo {
            cipher_orders: vec![0, 1],
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
        let ftokens = vec![];
        let (session, wallet_address) = add_sk_wallet(params, wallet_settings, ftokens)
            .await
            .unwrap();
        assert!(!session.is_empty());
        assert!(!wallet_address.is_empty());
        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();

        {
            assert_eq!(wallets.len(), 1);
            assert_eq!(wallet.wallet_type, "SecretKey");
            assert_eq!(wallet.wallet_name, "SK Wallet");
            assert_eq!(wallet.auth_type, "faceId");
            assert_eq!(wallet.wallet_address, wallet_address);
            assert_eq!(wallet.accounts.len(), 1);
            assert_eq!(wallet.selected_account, 0);
        }

        {
            let account = &wallet.accounts[0];
            assert_eq!(account.name, "SK Wallet");
            assert_eq!(account.index, 0);
            assert_eq!(account.chain_hash, zil_chain_config.hash());
            assert_eq!(account.chain_id, zil_chain_config.chain_id());
            assert_eq!(account.slip_44, zil_chain_config.slip_44);
        }

        {
            assert_eq!(wallet.tokens.len(), 1);
            let evm_token = &wallet.tokens[0];
            assert_eq!(evm_token.name, "Zilliqa");
            assert_eq!(evm_token.symbol, "ZIL");
            assert_eq!(evm_token.decimals, 18);
            assert_eq!(evm_token.addr, "0x0000000000000000000000000000000000000000");
            assert_eq!(evm_token.addr_type, 1);
            assert_eq!(
            evm_token.logo,
            Some("https://raw.githubusercontent.com/zilpay/zilpay-cdn/refs/heads/main/icons/%{shortName}%/%{symbol}%/%{dark,light}%.webp".to_string())
        );
            assert!(evm_token.balances.is_empty());
            assert_eq!(evm_token.rate, 0.0);
            assert!(!evm_token.default);
            assert!(evm_token.native);
            assert_eq!(evm_token.chain_hash, zil_chain_config.hash());

            zilliqa_swap_chain(0, 0).await.unwrap();
            let wallets = get_wallets().await.unwrap();
            let wallet = wallets.first().unwrap();

            let zil_token = &wallet.tokens[0];
            assert_eq!(zil_token.name, "Zilliqa");
            assert_eq!(zil_token.symbol, "ZIL");
            assert_eq!(zil_token.decimals, 12);
            assert_eq!(zil_token.addr, "zil1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq9yf6pz");
            assert_eq!(zil_token.addr_type, 0);
            assert_eq!(
            zil_token.logo,
            Some("https://raw.githubusercontent.com/zilpay/zilpay-cdn/refs/heads/main/icons/%{shortName}%/%{symbol}%/%{dark,light}%.webp".to_string())
        );
            assert!(zil_token.balances.is_empty());
            assert_eq!(zil_token.rate, 0.0);
            assert!(!zil_token.default);
            assert!(zil_token.native);
            assert_eq!(zil_token.chain_hash, zil_chain_config.hash());

            zilliqa_swap_chain(0, 0).await.unwrap();
        }

        {
            assert_eq!(wallet.settings.cipher_orders, vec![0, 1]);
            assert_eq!(wallet.settings.argon_params.memory, 10);
            assert_eq!(wallet.settings.argon_params.iterations, 1);
            assert_eq!(wallet.settings.argon_params.threads, 1);
            assert_eq!(
                wallet.settings.argon_params.secret,
                "2bb80d537b1da3e38bd30361aa855686bde0eacd7162fef6a25fe97bf527a25b"
            );
            assert_eq!(wallet.settings.currency_convert, "BTC");
            assert!(wallet.settings.ipfs_node.is_none());
            assert!(!wallet.settings.ens_enabled);
            assert!(!wallet.settings.tokens_list_fetcher);
            assert!(!wallet.settings.node_ranking_enabled);
            assert_eq!(wallet.settings.max_connections, 0);
            assert_eq!(wallet.settings.request_timeout_secs, 0);
            assert_eq!(wallet.settings.rates_api_options, 0);
        }

        assert_eq!(wallet.default_chain_hash, zil_chain_config.hash());
        assert_eq!(
            reveal_bip39_phrase(
                0,
                vec![String::from("test sk identifier")],
                PASSWORD.to_string(),
                None,
            )
            .await,
            Err("Wallet error at index: 0: Invalid account type".to_string())
        );

        let keypair = reveal_keypair(
            0,
            0,
            vec![String::from("test sk identifier")],
            PASSWORD.to_string(),
            None,
        )
        .await
        .unwrap();

        assert_eq!(&keypair.sk, SK);
        assert_eq!(
            &keypair.pk,
            "02d2f48dfb27a3e35f1029aeaed8d65a209c45cadde40a73481f2d84ed3c9205b4"
        );
        let bech32 = zilliqa_get_n_format(0, 0).await.unwrap();

        assert_eq!("zil1vqzxx6d24dqd4kc0pr5nv8kqztnwh3shfm2s0m", bech32);

        let bsc_chain_config = {
            let guard = BACKGROUND_SERVICE.read().await;
            let service = guard.as_ref().unwrap();
            let providers = service.core.get_providers();

            providers[1].config.clone()
        };

        select_accounts_chain(0, bsc_chain_config.hash())
            .await
            .unwrap();

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();

        {
            let account = &wallet.accounts[0];
            assert_eq!(account.name, "SK Wallet");
            assert_eq!(account.addr, "0x60046369aAab40dADB0F08e9361ec012e6ebC617");
            assert_eq!(account.index, 0);
            assert_eq!(account.chain_hash, bsc_chain_config.hash());
            assert_eq!(account.chain_id, bsc_chain_config.chain_id());
            assert_eq!(account.slip_44, bsc_chain_config.slip_44);
        }

        {
            assert_eq!(wallet.tokens.len(), 1);
            let bnb_token = &wallet.tokens[0];
            assert_eq!(bnb_token.name, "BinanceCoin");
            assert_eq!(bnb_token.symbol, "BNB");
            assert_eq!(bnb_token.decimals, 18);
            assert_eq!(bnb_token.addr, "0x0000000000000000000000000000000000000000");
            assert_eq!(bnb_token.addr_type, 1);
            assert_eq!(
        bnb_token.logo,
        Some("https://raw.githubusercontent.com/zilpay/zilpay-cdn/refs/heads/main/icons/%{shortName}%/%{symbol}%/%{dark,light}%.webp".to_string())
    );
            assert!(bnb_token.balances.is_empty());
            assert_eq!(bnb_token.rate, 0.0);
            assert!(!bnb_token.default);
            assert!(bnb_token.native);
            assert_eq!(bnb_token.chain_hash, bsc_chain_config.hash());
        }

        assert_eq!(wallet.default_chain_hash, zil_chain_config.hash());

        let keystore_bytes = make_keystore_file(
            0,
            PASSWORD.to_string(),
            vec![String::from("test sk identifier")],
        )
        .await
        .unwrap();

        delete_wallet(
            0,
            vec![String::from("test sk identifier")],
            None,
            Some(session),
        )
        .await
        .unwrap();

        let wallets = get_wallets().await.unwrap();
        assert_eq!(wallets.len(), 0);

        let (_session, _new_address) = restore_from_keystore(
            keystore_bytes,
            vec![String::from("test sk identifier")],
            PASSWORD.to_string(),
            "fingerprint".to_string(),
        )
        .await
        .unwrap();
        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();

        {
            assert_eq!(wallets.len(), 1);
            assert_eq!(wallet.wallet_type, "SecretKey");
            assert_eq!(wallet.wallet_name, "SK Wallet");
            assert_eq!(wallet.auth_type, "fingerprint");
            assert!(!wallet.wallet_address.is_empty());
            assert_eq!(wallet.accounts.len(), 1);
            assert_eq!(wallet.selected_account, 0);

            let account = &wallet.accounts[0];
            assert_eq!(account.name, "SK Wallet");
            assert_eq!(account.addr, "0x60046369aAab40dADB0F08e9361ec012e6ebC617");
            assert_eq!(account.addr_type, 1);
            assert_eq!(account.index, 0);
            assert_eq!(account.chain_hash, zil_chain_config.hash());
            assert_eq!(account.chain_id, zil_chain_config.chain_id());
            assert_eq!(account.slip_44, zil_chain_config.slip_44);

            assert_eq!(wallet.tokens.len(), 1);

            let evm_token = &wallet.tokens[0];
            assert_eq!(evm_token.name, "Zilliqa");
            assert_eq!(evm_token.symbol, "ZIL");
            assert_eq!(evm_token.decimals, 18);
            assert_eq!(evm_token.addr, "0x0000000000000000000000000000000000000000");
            assert_eq!(evm_token.addr_type, 1);
            assert_eq!(
        evm_token.logo,
        Some("https://raw.githubusercontent.com/zilpay/zilpay-cdn/refs/heads/main/icons/%{shortName}%/%{symbol}%/%{dark,light}%.webp".to_string())
    );
            assert!(evm_token.balances.is_empty());
            assert_eq!(evm_token.rate, 0.0);
            assert!(!evm_token.default);
            assert!(evm_token.native);
            assert_eq!(evm_token.chain_hash, zil_chain_config.hash());

            zilliqa_swap_chain(0, 0).await.unwrap();
            let wallets = get_wallets().await.unwrap();
            let wallet = wallets.first().unwrap();

            let zil_token = &wallet.tokens[0];
            assert_eq!(zil_token.name, "Zilliqa");
            assert_eq!(zil_token.symbol, "ZIL");
            assert_eq!(zil_token.decimals, 12);
            assert_eq!(zil_token.addr, "zil1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq9yf6pz");
            assert_eq!(zil_token.addr_type, 0);
            assert_eq!(
        zil_token.logo,
        Some("https://raw.githubusercontent.com/zilpay/zilpay-cdn/refs/heads/main/icons/%{shortName}%/%{symbol}%/%{dark,light}%.webp".to_string())

    );
            assert!(zil_token.balances.is_empty());
            assert_eq!(zil_token.rate, 0.0);
            assert!(!zil_token.default);
            assert!(zil_token.native);
            assert_eq!(zil_token.chain_hash, zil_chain_config.hash());

            assert_eq!(wallet.settings.cipher_orders, vec![0, 1]);
            assert_eq!(wallet.settings.argon_params.memory, 10);
            assert_eq!(wallet.settings.argon_params.iterations, 1);
            assert_eq!(wallet.settings.argon_params.threads, 1);
            assert_eq!(
                wallet.settings.argon_params.secret,
                "2bb80d537b1da3e38bd30361aa855686bde0eacd7162fef6a25fe97bf527a25b"
            );
            assert_eq!(wallet.settings.currency_convert, "BTC");
            assert!(wallet.settings.ipfs_node.is_none());
            assert!(!wallet.settings.ens_enabled);
            assert!(!wallet.settings.tokens_list_fetcher);
            assert!(!wallet.settings.node_ranking_enabled);
            assert_eq!(wallet.settings.max_connections, 0);
            assert_eq!(wallet.settings.request_timeout_secs, 0);
            assert_eq!(wallet.settings.rates_api_options, 0);

            assert_eq!(wallet.default_chain_hash, zil_chain_config.hash());

            let restored_keypair = reveal_keypair(
                0,
                0,
                vec![String::from("test sk identifier")],
                PASSWORD.to_string(),
                None,
            )
            .await
            .unwrap();

            assert_eq!(&restored_keypair.sk, SK);
            assert_eq!(
                &restored_keypair.pk,
                "02d2f48dfb27a3e35f1029aeaed8d65a209c45cadde40a73481f2d84ed3c9205b4"
            );
            zilliqa_swap_chain(0, 0).await.unwrap();
        }

        select_accounts_chain(0, zil_chain_config.hash())
            .await
            .unwrap();
        zilliqa_swap_chain(0, 0).await.unwrap();

        let token = fetch_token_meta(ZLP_ADDR.to_string(), 0).await.unwrap();

        {
            assert_eq!(token.name, "ZilPay wallet");
            assert_eq!(token.symbol, "ZLP");
            assert_eq!(token.decimals, 18);
            assert_eq!(token.addr, ZLP_ADDR);
            assert_eq!(token.addr_type, 0);
            assert_eq!(token.logo, None);
            assert!(token.balances.contains_key(&0));
            assert_eq!(token.balances.get(&0).unwrap(), "0");
            assert_eq!(token.rate, 0.0);
            assert!(!token.default);
            assert!(!token.native);
            assert_eq!(token.chain_hash, zil_chain_config.hash());
        }

        add_ftoken(token.clone(), 0).await.unwrap();

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();

        let bytes_sk: [u8; SECRET_KEY_SIZE] = hex::decode(SK).unwrap().try_into().unwrap();
        let sk = SecretKey::Secp256k1Sha256Zilliqa(bytes_sk);
        let keypair = KeyPair::from_secret_key(sk).unwrap();

        assert_eq!(wallet.tokens.len(), 2);

        let tx = create_token_transfer(TokenTransferParamsInfo {
            wallet_index: 0,
            account_index: 0,
            token: wallet.tokens.last().unwrap().clone(),
            amount: "1000000000000000000".to_string(),
            recipient: "zil1wl38cwww2u3g8wzgutxlxtxwwc0rf7jf27zace".to_string(),
            icon: "".to_string(),
        })
        .await
        .unwrap();

        {
            assert_eq!(tx.metadata.chain_hash, zil_chain_config.hash());
            assert_eq!(tx.metadata.hash, None);
            assert_eq!(tx.metadata.info, None);
            assert_eq!(tx.metadata.icon, Some("".to_string()));
            assert_eq!(tx.metadata.title, None);
            assert_eq!(
                tx.metadata.signer,
                Some(keypair.get_pubkey().unwrap().to_string())
            );

            // Assert token info
            let token_info = tx.metadata.token_info.as_ref().unwrap();
            assert_eq!(token_info.value, "1000000000000000000");
            assert_eq!(token_info.symbol, "ZLP");
            assert_eq!(token_info.decimals, 18);

            // Assert Scilla transaction details
            let scilla = tx.scilla.as_ref().unwrap();
            assert_eq!(scilla.chain_id, 1);
            assert_eq!(scilla.nonce, 0);
            assert_eq!(scilla.gas_price, 2000000000);
            assert_eq!(scilla.gas_limit, 2000);
            assert_eq!(scilla.to_addr, token.addr);
            assert_eq!(scilla.amount, 0);
            assert_eq!(scilla.code, "");
            assert_eq!(scilla.data, "{\"_tag\":\"Transfer\",\"params\":[{\"type\":\"ByStr20\",\"value\":\"0x77e27c39ce572283b848e2cdf32cce761e34fa49\",\"vname\":\"to\"},{\"type\":\"Uint128\",\"value\":\"1000000000000000000\",\"vname\":\"amount\"}]}");

            // Assert EVM is None
            assert!(tx.evm.is_none());
        }

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();

        assert_eq!(
            wallet.accounts[0].addr,
            "zil1q2yyq6z2sz26p54700e5zpzu3gj070wxt8h75h"
        );
        let diff_addr = zilliqa_get_n_format(0, 0).await.unwrap();

        assert_eq!(diff_addr, "0x60046369aAab40dADB0F08e9361ec012e6ebC617");

        zilliqa_swap_chain(0, 0).await.unwrap();

        let diff_addr = zilliqa_get_n_format(0, 0).await.unwrap();

        assert_eq!(diff_addr, "zil1vqzxx6d24dqd4kc0pr5nv8kqztnwh3shfm2s0m");

        let token = fetch_token_meta("0x2274005778063684fbB1BfA96a2b725dC37D75f9".to_string(), 0)
            .await
            .unwrap();
        let mut tx = create_token_transfer(TokenTransferParamsInfo {
            wallet_index: 0,
            account_index: 0,
            token,
            amount: "1".to_string(),
            recipient: "0xa1B2Ff03F501A4d8278CB75a9075F406A5B8C5Ff".to_string(),
            icon: "".to_string(),
        })
        .await
        .unwrap();

        if let Some(evm) = tx.evm.as_mut() {
            evm.from = Some("0x558d34db1952A45b1CC216F0B39646aA6306D90b".to_string());
        }

        // let tx = TransactionRequestInfo {
        //     metadata: TransactionMetadataInfo {
        //         chain_hash: zil_chain_config.hash(),
        //         hash: None,
        //         info: None,
        //         icon: None,
        //         title: None,
        //         signer: None,
        //         token_info: None,
        //     },
        //     scilla: None,
        //                 evm: Some(TransactionRequestEVM {
        //         nonce: None,
        //         // from: Some(wallet.accounts[0].addr.clone()),
        //         from: Some("0xa1B2Ff03F501A4d8278CB75a9075F406A5B8C5Ff".to_string()),
        //         to: Some("0xe30161F32A019d876F082d9FF13ed451a03A2086".to_string()),
        //         value: Some("0xde0b6b3a7640000".to_string()),
        //         // gas_limit: Some(1197051),
        //         gas_limit: None,
        //         data: Some(hex::decode("5ae401dc0000000000000000000000000000000000000000000000000000000067e63a35000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000e404e45aaf00000000000000000000000094e18ae7dd5ee57b55f30c4b63e2760c09efb1920000000000000000000000002274005778063684fbb1bfa96a2b725dc37d75f900000000000000000000000000000000000000000000000000000000000009c4000000000000000000000000a1b2ff03f501a4d8278cb75a9075f406a5b8c5ff0000000000000000000000000000000000000000000000000905438e600100000000000000000000000000000000000000000000000000000000000000001f3d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e404e45aaf00000000000000000000000094e18ae7dd5ee57b55f30c4b63e2760c09efb1920000000000000000000000002274005778063684fbb1bfa96a2b725dc37d75f900000000000000000000000000000000000000000000000000000000000001f4000000000000000000000000a1b2ff03f501a4d8278cb75a9075f406a5b8c5ff00000000000000000000000000000000000000000000000004db73254763000000000000000000000000000000000000000000000000000000000000000012c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000").unwrap()),
        //         max_fee_per_gas: None,
        //         max_priority_fee_per_gas: None,
        //         gas_price: None,
        //         chain_id: None,
        //         access_list: None,
        //         blob_versioned_hashes: None,
        //         max_fee_per_blob_gas: None,
        //     }),
        // };
        let gas = cacl_gas_fee(0, 0, tx).await.unwrap();

        assert!(gas.gas_price > 0);
        assert!(gas.tx_estimate_gas > 0);
    }
}
