#[cfg(test)]
mod btc_wallet_tests {
    use std::{collections::HashMap, fs, path::Path};

    use tempfile::tempdir;
    use zilpay::background::bg_provider::ProvidersManagement;
    use zilpay::background::bg_wallet::WalletManagement;
    use zilpay::crypto::bip49::DerivationPath;
    use zilpay::crypto::slip44::{BITCOIN, ETHEREUM, SOLANA, TRON, ZILLIQA};
    use zilpay::rpc::network_config::ChainConfig;
    use zilpay::tokio;
    use zilpay::wallet::bitcoin_wallet::BitcoinWallet;

    use crate::api::backend::get_data;
    use crate::api::provider::{get_providers, select_accounts_chain};
    use crate::api::token::sync_balances;
    use crate::api::utils::address_to_hash;
    use crate::api::wallet::{
        add_bip39_wallet, add_next_bip39_account, get_wallets, AddNextBip39AccountParams,
        Bip39AddWalletParams,
    };
    use crate::api::{backend::load_service, provider::get_chains_providers_from_json};
    use crate::models::settings::{WalletArgonParamsInfo, WalletSettingsInfo};

    const PASSWORD: &str = "test_password";
    const BTC_MNEMONIC_STR: &str = "test test test test test test test test test test test junk";

    const ETH_ADDR: &str = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const TRX_ADDR: &str = "TWer2Ygk5TEheHp3TPuYeqxmB6SsGZmaL6";
    const SOL_ADDR: &str = "oeYf6KAJkLYhBuR8CiGc6L4D4Xtfepr85fuDgA9kq96";
    const BTC_ADDR: &str = "bcrt1pmfr3p9j00pfxjh0zmgp99y8zftmd3s5pmedqhyptwy6lm87hf5ssm803es";

    const EXPECTED_ADDRS: [(u32, &str); 4] = [
        (BITCOIN, BTC_ADDR),
        (ETHEREUM, ETH_ADDR),
        (TRON, TRX_ADDR),
        (SOLANA, SOL_ADDR),
    ];

    #[zilpay::tokio::test]
    async fn test_create_btc_wallet() {
        let dir = tempdir().unwrap();
        load_service(dir.path().to_str().unwrap()).await.unwrap();

        let path = Path::new("../assets/chains/testnet-chains.json");
        let content = fs::read_to_string(path).unwrap();
        let providers: Vec<ChainConfig> = get_chains_providers_from_json(content)
            .unwrap()
            .into_iter()
            .map(|c| c.try_into().unwrap())
            .collect();

        {
            let core = crate::service::background::CORE.load_full().unwrap();
            core.add_batch_providers(providers).unwrap();
        }

        let global_data = get_data().await.unwrap();

        let chain_by_slip44: HashMap<u32, u64> = global_data
            .providers
            .iter()
            .filter(|p| EXPECTED_ADDRS.iter().any(|(slip, _)| *slip == p.slip_44))
            .map(|p| (p.slip_44, p.chain_hash))
            .collect();

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

        let btc_chain_hash = *chain_by_slip44.get(&BITCOIN).unwrap();
        let params = Bip39AddWalletParams {
            password: PASSWORD.to_string(),
            mnemonic_str: BTC_MNEMONIC_STR.to_string(),
            mnemonic_check: true,
            accounts: vec![(0, "A".to_string())],
            passphrase: "".to_string(),
            wallet_name: "Bitcoin Wallet".to_string(),
            biometric_type: "none".to_string(),
            chain_hash: btc_chain_hash,
        };

        let wallet_address = add_bip39_wallet(params, wallet_settings, vec![])
            .await
            .unwrap();

        let history = {
            let core = crate::service::background::CORE.load_full().unwrap();
            let wallet = core.get_wallet_by_index(0).unwrap();
            wallet.get_btc_addresses(0, btc_chain_hash).unwrap()
        };

        assert!(!wallet_address.is_empty());

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();

        assert_eq!(wallet.wallet_type, "SecretPhrase.false");
        assert_eq!(wallet.wallet_name, "Bitcoin Wallet");
        assert_eq!(wallet.auth_type, "none");
        assert_eq!(wallet.chain_hash, btc_chain_hash);
        assert_eq!(wallet.slip44, BITCOIN);
        assert_eq!(wallet.bip, DerivationPath::BIP84_PURPOSE);

        let btc_accounts = wallet
            .accounts
            .get(&BITCOIN)
            .and_then(|m| m.get(&DerivationPath::BIP84_PURPOSE))
            .unwrap();

        assert_eq!(btc_accounts.len(), 1);

        let account = &btc_accounts[0];
        let segwit_history = history.get(&zilpay::bitcoin::AddressType::P2wpkh).unwrap();

        assert!(segwit_history.get_internal().unwrap().history.is_empty());
        assert!(segwit_history.get_internal().unwrap().utxos.is_empty());
        assert!(segwit_history.get_external().unwrap().utxos.is_empty());
        assert!(segwit_history.get_external().unwrap().utxos.is_empty());

        assert_eq!(
            account.addr,
            segwit_history.get_external().unwrap().address.auto_format()
        );
        assert_eq!(account.name, "A");
        assert_eq!(account.index, 0);
        assert_eq!(account.addr_type, 2);
        assert_eq!(account.pub_key, None);

        assert_eq!(wallet.tokens.len(), 1);
        let token = &wallet.tokens[0];
        assert_eq!(token.name, "Bitcoin");
        assert_eq!(token.symbol, "tBTC");
        assert_eq!(token.decimals, 8);
        assert_eq!(
            token.addr,
            "bcrt1pmfr3p9j00pfxjh0zmgp99y8zftmd3s5pmedqhyptwy6lm87hf5ssm803es"
        );
        assert_eq!(token.addr_type, 2);
        assert_eq!(
            token.logo,
            Some("https://raw.githubusercontent.com/zilpay/tokens_meta/refs/heads/master/ft/bitcoin/%{contract_address}%/%{dark,light}%.webp".to_string())
        );
        assert!(token.balances.is_empty());
        assert_eq!(token.rate, 0.0);
        assert!(!token.default);
        assert!(token.native);
        assert_eq!(token.chain_hash, btc_chain_hash);

        let switch_order: [u32; 3] = [TRON, SOLANA, ETHEREUM];

        for slip44 in switch_order {
            let chain_hash = *chain_by_slip44.get(&slip44).unwrap();
            let expected_bip = DerivationPath::default_bip(slip44);
            let expected_addr = EXPECTED_ADDRS.iter().find(|(s, _)| *s == slip44).unwrap().1;

            select_accounts_chain(0, chain_hash, Some(PASSWORD.to_string()))
                .await
                .unwrap();

            let wallets = get_wallets().await.unwrap();
            let wallet = wallets.first().unwrap();

            assert_eq!(wallet.chain_hash, chain_hash);
            assert_eq!(wallet.slip44, slip44);
            assert_eq!(wallet.bip, expected_bip);

            let accounts = wallet
                .accounts
                .get(&slip44)
                .and_then(|m| m.get(&expected_bip))
                .unwrap();

            assert_eq!(accounts[0].addr, expected_addr);
        }

        select_accounts_chain(0, btc_chain_hash, Some(PASSWORD.to_string()))
            .await
            .unwrap();

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();
        assert_eq!(wallet.chain_hash, btc_chain_hash);
        assert_eq!(wallet.slip44, BITCOIN);
        assert_eq!(wallet.bip, DerivationPath::BIP84_PURPOSE);

        let btc_accounts = wallet
            .accounts
            .get(&BITCOIN)
            .and_then(|m| m.get(&DerivationPath::BIP84_PURPOSE))
            .unwrap();
        assert_eq!(
            btc_accounts[0].addr,
            segwit_history.get_external().unwrap().address.auto_format()
        );

        sync_balances(0).await.unwrap();

        {
            let core = crate::service::background::CORE.load_full().unwrap();
            let wallet = core.get_wallet_by_index(0).unwrap();
            let _history = wallet.get_btc_addresses(0, btc_chain_hash).unwrap();

            // dbg!(&history);
        }

        let wallets_after_sync = get_wallets().await.unwrap();
        let wallet = wallets_after_sync.first().unwrap();
        let btc_accounts = wallet
            .accounts
            .get(&BITCOIN)
            .and_then(|m| m.get(&DerivationPath::BIP84_PURPOSE))
            .unwrap();
        let token = &wallet.tokens[0];

        assert_eq!(btc_accounts.len(), 1);

        let account = &btc_accounts[0];
        let expected_balance: u64 = {
            let core = crate::service::background::CORE.load_full().unwrap();
            let wallet = core.get_wallet_by_index(0).unwrap();
            let chains = wallet.get_btc_addresses(0, btc_chain_hash).unwrap();
            chains
                .values()
                .flat_map(|c| c.external.iter().chain(c.internal.iter()))
                .flat_map(|e| e.utxos.iter())
                .map(|u| u.value)
                .sum()
        };

        if expected_balance > 0 {
            let balance_str = token
                .balances
                .get(&address_to_hash(account.addr.clone()))
                .cloned()
                .unwrap_or_default();
            let balance: u64 = balance_str.parse().unwrap_or(0);
            assert_eq!(
                balance, expected_balance,
                "BTC balance should match sum of UTXOs"
            );
        }

        let providers = get_providers().await.unwrap();
        let tron_chain = providers.iter().find(|p| p.slip_44 == TRON).unwrap();

        select_accounts_chain(0, tron_chain.chain_hash, None)
            .await
            .unwrap();

        add_next_bip39_account(AddNextBip39AccountParams {
            wallet_index: 0,
            account_index: 1,
            name: "Acc 1".into(),
            passphrase: String::new(),
            password: Some(PASSWORD.to_string()),
        })
        .await
        .unwrap();

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();

        let tron_chain_hash = *chain_by_slip44.get(&TRON).unwrap();
        assert_eq!(wallet.chain_hash, tron_chain_hash);
        assert_eq!(wallet.slip44, TRON);
        assert_eq!(wallet.bip, DerivationPath::BIP44_PURPOSE);

        for &slip44 in &[BITCOIN, ETHEREUM, TRON, SOLANA, ZILLIQA] {
            let bip = DerivationPath::default_bip(slip44);
            let accounts = wallet
                .accounts
                .get(&slip44)
                .and_then(|m| m.get(&bip))
                .unwrap_or_else(|| panic!("missing accounts for slip44 {}", slip44));
            assert_eq!(
                accounts.len(),
                2,
                "slip44 {} should have 2 accounts after add_next_bip39_account",
                slip44
            );
            assert_eq!(accounts[0].name, "A");
            assert_eq!(accounts[0].index, 0);
            assert_eq!(accounts[1].name, "Acc 1");
            assert_eq!(accounts[1].index, 1);
        }

        let new_addrs: HashMap<u32, &str> = HashMap::from([
            (ETHEREUM, "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"),
            (TRON, "TPjjvMwjPoDC32V2dGDYTkLH4E5LAtBZ6C"),
            (SOLANA, "AqynRZwvVqUPRwRJXvm6odUb3t93fDjnWe3p6BeuUFxD"),
            (ZILLIQA, "0x9E546758fBDcdCd3926d946ad628d0ED7A419106"),
        ]);
        for (&slip44, &expected_addr) in new_addrs.iter() {
            let bip = DerivationPath::default_bip(slip44);
            let accounts = wallet.accounts.get(&slip44).unwrap().get(&bip).unwrap();
            assert_eq!(
                accounts[1].addr, expected_addr,
                "slip44 {} acc-1 addr mismatch",
                slip44
            );
        }

        let zilliqa_accounts = wallet
            .accounts
            .get(&ZILLIQA)
            .and_then(|m| m.get(&DerivationPath::BIP44_PURPOSE))
            .unwrap();
        assert!(zilliqa_accounts[1].pub_key.is_some());

        let btc_accounts = wallet
            .accounts
            .get(&BITCOIN)
            .and_then(|m| m.get(&DerivationPath::BIP84_PURPOSE))
            .unwrap();
        assert_eq!(btc_accounts[1].addr_type, 2);
        assert_eq!(btc_accounts[1].pub_key, None);
        assert!(!btc_accounts[1].addr.is_empty());

        assert_eq!(wallet.tokens.len(), 1);
        let token = &wallet.tokens[0];
        assert_eq!(token.symbol, "TRX");
        assert_eq!(token.chain_hash, tron_chain_hash);
        assert!(token.native);
    }
}
