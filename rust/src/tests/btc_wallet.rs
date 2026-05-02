#[cfg(test)]
mod btc_wallet_tests {
    use std::{collections::HashMap, fs, path::Path};

    use tempfile::tempdir;
    use zilpay::background::bg_provider::ProvidersManagement;
    use zilpay::crypto::bip49::DerivationPath;
    use zilpay::crypto::slip44::{BITCOIN, ETHEREUM, SOLANA, TRON};
    use zilpay::rpc::network_config::ChainConfig;

    use crate::api::backend::get_data;
    use crate::api::provider::select_accounts_chain;
    use crate::api::wallet::{add_bip39_wallet, get_wallets, Bip39AddWalletParams};
    use crate::api::{backend::load_service, provider::get_chains_providers_from_json};
    use crate::models::settings::{WalletArgonParamsInfo, WalletSettingsInfo};
    use crate::service::service::BACKGROUND_SERVICE;

    const PASSWORD: &str = "test_password";
    const BTC_MNEMONIC_STR: &str = "test test test test test test test test test test test junk";

    const BTC_ADDR: &str = "bc1pfzhx49qe6s5exppe5hqljg3n6587xk0w75xqr70pgdt7ygnfkssqxqjd9l";
    const ETH_ADDR: &str = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const TRX_ADDR: &str = "TWer2Ygk5TEheHp3TPuYeqxmB6SsGZmaL6";
    const SOL_ADDR: &str = "oeYf6KAJkLYhBuR8CiGc6L4D4Xtfepr85fuDgA9kq96";

    const EXPECTED_ADDRS: [(u32, &str); 4] = [
        (BITCOIN, BTC_ADDR),
        (ETHEREUM, ETH_ADDR),
        (TRON, TRX_ADDR),
        (SOLANA, SOL_ADDR),
    ];

    #[tokio::test]
    async fn test_create_btc_wallet() {
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
            service.core.add_batch_providers(providers).unwrap();
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

        assert!(!wallet_address.is_empty());

        let wallets = get_wallets().await.unwrap();
        let wallet = wallets.first().unwrap();

        assert_eq!(wallet.wallet_type, "SecretPhrase.false");
        assert_eq!(wallet.wallet_name, "Bitcoin Wallet");
        assert_eq!(wallet.auth_type, "none");
        assert_eq!(wallet.chain_hash, btc_chain_hash);
        assert_eq!(wallet.slip44, BITCOIN);
        assert_eq!(wallet.bip, DerivationPath::BIP86_PURPOSE);

        let btc_accounts = wallet
            .accounts
            .get(&BITCOIN)
            .and_then(|m| m.get(&DerivationPath::BIP86_PURPOSE))
            .unwrap();

        assert_eq!(btc_accounts.len(), 1);

        let account = &btc_accounts[0];
        assert_eq!(account.addr, BTC_ADDR);
        assert_eq!(account.name, "A");
        assert_eq!(account.index, 0);
        assert_eq!(account.addr_type, 2);
        assert_eq!(account.pub_key, None);

        assert_eq!(wallet.tokens.len(), 1);
        let token = &wallet.tokens[0];
        assert_eq!(token.name, "Bitcoin");
        assert_eq!(token.symbol, "BTC");
        assert_eq!(token.decimals, 8);
        assert_eq!(
            token.addr,
            "bc1pmfr3p9j00pfxjh0zmgp99y8zftmd3s5pmedqhyptwy6lm87hf5sspknck9"
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
        assert_eq!(wallet.bip, DerivationPath::BIP86_PURPOSE);

        let btc_accounts = wallet
            .accounts
            .get(&BITCOIN)
            .and_then(|m| m.get(&DerivationPath::BIP86_PURPOSE))
            .unwrap();
        assert_eq!(btc_accounts[0].addr, BTC_ADDR);
    }
}
