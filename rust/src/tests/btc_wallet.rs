#[cfg(test)]
mod btc_wallet_tests {
    use std::{fs, path::Path};

    use tempfile::tempdir;
    use zilpay::background::bg_provider::ProvidersManagement;
    use zilpay::crypto::bip49::DerivationPath;
    use zilpay::crypto::slip44::BITCOIN;
    use zilpay::rpc::network_config::ChainConfig;

    use crate::api::backend::get_data;
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
        let target_chain = global_data
            .providers
            .iter()
            .find(|p| p.slip_44 == BITCOIN)
            .unwrap();

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
            wallet_name: "Bitcoin Wallet".to_string(),
            biometric_type: "none".to_string(),
            chain_hash: target_chain.chain_hash,
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
        assert_eq!(wallet.slip44, BITCOIN);
        assert_eq!(wallet.bip, DerivationPath::BIP86_PURPOSE);

        let btc_accounts = wallet
            .accounts
            .get(&BITCOIN)
            .and_then(|m| m.get(&DerivationPath::BIP86_PURPOSE))
            .unwrap();

        assert_eq!(btc_accounts.len(), 1);

        let account = &btc_accounts[0];
        assert_eq!(
            account.addr,
            "bc1pfzhx49qe6s5exppe5hqljg3n6587xk0w75xqr70pgdt7ygnfkssqxqjd9l"
        );
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
        assert_eq!(token.chain_hash, 7125286628901439293);
    }
}
