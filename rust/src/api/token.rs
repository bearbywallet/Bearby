use crate::{
    models::ftoken::FTokenInfo,
    service::service::BACKGROUND_SERVICE,
    utils::{
        errors::ServiceError,
        utils::{parse_address, with_service},
    },
};
use serde::Deserialize;
use serde_json::Value;
use std::{collections::HashMap, sync::Arc};
pub use zilpay::background::bg_token::TokensManagement;
pub use zilpay::proto::address::Address;
use zilpay::{
    background::{bg_provider::ProvidersManagement, bg_wallet::WalletManagement},
    crypto::slip44::{BITCOIN, ETHEREUM, TRON, ZILLIQA},
    settings::wallet_settings::TokenQuotesAPIOptions,
    token::ft::FToken,
    wallet::{wallet_storage::StorageOperations, wallet_token::TokenManagement},
};

const UNISWAP_API_URL: &str =
    "https://interface.gateway.uniswap.org/v2/data.v1.DataApiService/GetPortfolio";
const COINGECKO_API_URL: &str = "https://api.coingecko.com/api/v3/simple/price";
const ZILLIQA_SCILLA_TOKENS_API: &str = "https://api.zilpay.io/api/v1/tokens";
const ZILLIQA_EVM_TOKENS_API: &str = "https://api.zilpay.io/api/v1/tokens_evm";
const TRON_ACCOUNT_TOKENS_API: &str = "https://ts.endjgfsv.link/api/account/tokens";
const ZERO_EVM: &str = "0x0000000000000000000000000000000000000000";

#[derive(Debug, Deserialize)]
struct ProtectionInfo {
    result: Option<String>,
}

#[derive(Debug, Deserialize)]
struct TokenMetadata {
    #[serde(rename = "logoUrl")]
    logo_url: Option<String>,
    #[serde(rename = "protectionInfo")]
    protection_info: Option<ProtectionInfo>,
}

#[derive(Debug, Deserialize)]
struct PortfolioToken {
    address: Option<String>,
    symbol: Option<String>,
    decimals: Option<u8>,
    name: Option<String>,
    #[serde(rename = "type")]
    token_type: Option<String>,
    metadata: Option<TokenMetadata>,
}

#[derive(Debug, Deserialize)]
struct TokenAmount {
    raw: Option<String>,
}

#[derive(Debug, Deserialize)]
struct PortfolioBalance {
    token: Option<PortfolioToken>,
    amount: Option<TokenAmount>,
}

#[derive(Debug, Deserialize)]
struct Portfolio {
    balances: Option<Vec<PortfolioBalance>>,
}

#[derive(Debug, Deserialize)]
struct PortfolioResponse {
    portfolio: Option<Portfolio>,
}

#[derive(Debug, Deserialize)]
struct ZilliqaEvmTokenResponse {
    address: String,
    decimals: u8,
    name: String,
    symbol: String,
}

#[derive(Debug, Deserialize)]
struct ZilliqaScillaTokenResponse {
    bech32: String,
    name: String,
    symbol: String,
    decimals: u8,
}

#[derive(Debug, Deserialize)]
struct ZilliqaScillaApiResponse {
    list: Vec<ZilliqaScillaTokenResponse>,
}

#[derive(Debug, Deserialize)]
struct ZilstreamToken {
    symbol: String,
    price_eth: Option<String>,
}

#[derive(Debug, Deserialize)]
struct ZilstreamResponse {
    data: Vec<ZilstreamToken>,
}

#[derive(Debug, Deserialize)]
struct TronAccountToken {
    #[serde(rename = "tokenId")]
    token_id: String,
    balance: String,
    #[serde(rename = "tokenName")]
    token_name: String,
    #[serde(rename = "tokenAbbr")]
    token_abbr: String,
    #[serde(rename = "tokenDecimal")]
    token_decimal: u8,
    #[serde(rename = "tokenLogo")]
    token_logo: Option<String>,
}

#[derive(Debug, Deserialize)]
struct TronAccountResponse {
    data: Vec<TronAccountToken>,
}

pub async fn sync_balances(wallet_index: usize) -> Result<(), String> {
    if let Some(service) = BACKGROUND_SERVICE.read().await.as_ref() {
        let core = Arc::clone(&service.core);

        core.sync_ftokens_balances(wallet_index)
            .await
            .map_err(ServiceError::BackgroundError)?;

        Ok(())
    } else {
        Err(ServiceError::NotRunning.to_string())
    }
}

pub async fn update_rates(wallet_index: usize) -> Result<(), String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let wallet = service
        .core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let currency: &str = data.settings.features.currency_convert.as_ref();
    let chain = service
        .core
        .get_provider(data.chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let chain_hash = chain.config.hash();
    let mut ftokens = wallet
        .get_ftokens()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let ftokens_indices: Vec<usize> = ftokens
        .iter()
        .enumerate()
        .filter_map(|(i, token)| {
            if token.chain_hash == chain_hash {
                Some(i)
            } else {
                None
            }
        })
        .collect();
    let native_token = chain
        .config
        .ftokens
        .first()
        .ok_or(ServiceError::TokenError(
            zilpay::errors::token::TokenError::TokenParseError,
        ))?;

    let convert_rate = match data.settings.rates_api_options {
        TokenQuotesAPIOptions::Coingecko => {
            let symbol_id = native_token.symbol.to_lowercase();
            let coingecko_url = format!(
                "{}?symbols={}&vs_currencies={}",
                COINGECKO_API_URL,
                symbol_id,
                currency.to_lowercase()
            );
            let client = reqwest::Client::new();
            let response = client
                .get(&coingecko_url)
                .header("User-Agent", "ZilPay-Wallet/1.0")
                .send()
                .await
                .map_err(|e| format!("HTTP request failed: {}", e))?;
            let rate: Value = response
                .json()
                .await
                .map_err(|e| format!("Failed to parse coingecko response: {}", e))?;
            let convert_rate = rate
                .get(&symbol_id)
                .and_then(|v| v.get(currency.to_lowercase()))
                .and_then(|v| v.as_f64())
                .unwrap_or_default();

            convert_rate
        }
        TokenQuotesAPIOptions::CryptoCompare => {
            let cryptocompare_url = format!(
                "https://min-api.cryptocompare.com/data/price?fsym={}&tsyms={}",
                native_token.symbol,
                currency.to_uppercase()
            );
            let client = reqwest::Client::new();
            let response = client
                .get(&cryptocompare_url)
                .send()
                .await
                .map_err(|e| format!("HTTP request failed: {}", e))?;
            let rate: Value = response
                .json()
                .await
                .map_err(|e| format!("Failed to parse cryptocompare response: {}", e))?;
            let convert_rate = rate
                .get(currency.to_uppercase())
                .and_then(|v| v.as_f64())
                .unwrap_or_default();

            convert_rate
        }
        _ => return Ok(()),
    };

    match chain.config.slip_44 {
        ZILLIQA => {
            let non_native_indices: Vec<usize> = ftokens_indices
                .iter()
                .filter(|&&idx| !ftokens[idx].native)
                .copied()
                .collect();

            for &idx in &ftokens_indices {
                if ftokens[idx].native {
                    ftokens[idx].rate = convert_rate;
                }
            }

            if non_native_indices.is_empty() {
                wallet
                    .save_ftokens(&ftokens)
                    .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
                return Ok(());
            }

            let zilstream_url = "https://api-v2.zilstream.com/tokens?page=1&per_page=500";
            let client = reqwest::Client::new();
            let response = client
                .get(zilstream_url)
                .send()
                .await
                .map_err(|e| format!("HTTP request failed: {}", e))?;
            let zilstream_response: ZilstreamResponse = response
                .json()
                .await
                .map_err(|e| format!("Failed to parse zilstream response: {}", e))?;

            let rate_map: HashMap<String, f64> = zilstream_response
                .data
                .into_iter()
                .filter_map(|token| {
                    let rate = token.price_eth?.parse::<f64>().ok()?;
                    Some((token.symbol.to_uppercase(), rate))
                })
                .collect();

            for &idx in &non_native_indices {
                let token = &mut ftokens[idx];
                let symbol_upper = token.symbol.to_uppercase();
                if let Some(&rate_zil) = rate_map.get(&symbol_upper) {
                    token.rate = rate_zil * convert_rate;
                }
            }

            wallet
                .save_ftokens(&ftokens)
                .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

            Ok(())
        }
        TRON => {
            if let Some(&idx) = ftokens_indices.first() {
                ftokens[idx].rate = convert_rate;
            }

            wallet
                .save_ftokens(&ftokens)
                .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

            Ok(())
        }
        BITCOIN => {
            if let Some(&idx) = ftokens_indices.first() {
                ftokens[idx].rate = convert_rate;
            }

            wallet
                .save_ftokens(&ftokens)
                .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

            Ok(())
        }
        ETHEREUM => {
            if ftokens_indices.is_empty() {
                return Ok(());
            }

            let chain_id = chain.config.chain_ids[0];
            let token_addresses: Vec<String> = ftokens_indices
                .iter()
                .map(|&idx| ftokens[idx].addr.auto_format().to_lowercase())
                .collect();

            let addresses_param = token_addresses.join(",");
            let endpoint_url = format!(
                "https://price.api.cx.metamask.io/v2/chains/{}/spot-prices?tokenAddresses={}&vsCurrency={}&includeMarketData=false",
                chain_id, addresses_param, currency.to_uppercase()
            );

            let client = reqwest::Client::new();
            let response = client
                .get(&endpoint_url)
                .send()
                .await
                .map_err(|e| format!("HTTP request failed: {}", e))?;

            let prices: HashMap<String, HashMap<String, f64>> = response
                .json()
                .await
                .map_err(|e| format!("Failed to parse eth response: {}", e))?;

            let currency_key = currency.to_lowercase();

            for (&idx, addr) in ftokens_indices.iter().zip(token_addresses.iter()) {
                if let Some(price_data) = prices.get(addr) {
                    if let Some(&rate) = price_data.get(&currency_key) {
                        if ftokens[idx].native {
                            ftokens[idx].rate = convert_rate;
                        } else {
                            ftokens[idx].rate = rate;
                        }
                    }
                }
            }

            wallet
                .save_ftokens(&ftokens)
                .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

            Ok(())
        }
        _ => Ok(()),
    }
}

pub async fn fetch_token_meta(addr: String, wallet_index: usize) -> Result<FTokenInfo, String> {
    if let Some(service) = BACKGROUND_SERVICE.read().await.as_ref() {
        let core = Arc::clone(&service.core);
        let address = parse_address(addr)?;

        let token_meta = core
            .fetch_ftoken_meta(wallet_index, address)
            .await
            .map_err(ServiceError::BackgroundError)?;

        Ok(token_meta.into())
    } else {
        Err(ServiceError::NotRunning.to_string())
    }
}

async fn fetch_zilliqa_tokens(
    addr: &Address,
    default_logo: Option<String>,
    chain_hash: u64,
) -> Result<Vec<FTokenInfo>, String> {
    let client = reqwest::Client::new();

    match addr {
        Address::Secp256k1Bitcoin(_) => {
            return Err("btc is not supporting".to_string());
        }
        Address::Secp256k1Tron(_) => {
            return Err("tron token auto-discovery is not supported".to_string());
        }
        Address::Ed25519Solana(_) => {
            return Err("solana token auto-discovery is not supported".to_string());
        }
        Address::Secp256k1Sha256(_) => {
            let response = client
                .get(ZILLIQA_SCILLA_TOKENS_API)
                .send()
                .await
                .map_err(|e| format!("HTTP request failed: {}", e))?;

            if !response.status().is_success() {
                return Err(format!("API error: {}", response.status()));
            }

            let api_response: ZilliqaScillaApiResponse = response
                .json()
                .await
                .map_err(|e| format!("Failed to parse response: {}", e))?;

            let result = api_response
                .list
                .into_iter()
                .map(|token| FTokenInfo {
                    name: token.name,
                    symbol: token.symbol,
                    decimals: token.decimals,
                    addr: token.bech32,
                    addr_type: addr.prefix_type(),
                    logo: default_logo.clone(),
                    balances: HashMap::new(),
                    rate: 0.0,
                    default: false,
                    native: false,
                    chain_hash,
                })
                .collect();

            Ok(result)
        }
        Address::Secp256k1Keccak256(_) => {
            let response = client
                .get(ZILLIQA_EVM_TOKENS_API)
                .send()
                .await
                .map_err(|e| format!("HTTP request failed: {}", e))?;

            if !response.status().is_success() {
                return Err(format!("API error: {}", response.status()));
            }

            let tokens: Vec<ZilliqaEvmTokenResponse> = response
                .json()
                .await
                .map_err(|e| format!("Failed to parse response: {}", e))?;

            let result = tokens
                .into_iter()
                .map(|token| FTokenInfo {
                    name: token.name,
                    symbol: token.symbol,
                    decimals: token.decimals,
                    addr: token.address,
                    addr_type: addr.prefix_type(),
                    logo: default_logo.clone(),
                    balances: HashMap::new(),
                    rate: 0.0,
                    default: false,
                    native: false,
                    chain_hash,
                })
                .collect();

            Ok(result)
        }
    }
}

async fn fetch_tron_tokens(
    addr: &str,
    default_logo: Option<String>,
    chain_hash: u64,
    addr_type: u8,
    selected_account: usize,
) -> Result<Vec<FTokenInfo>, String> {
    let client = reqwest::Client::new();
    let url = format!(
        "{}?show=2&hidden=0&sortBy=2&sortType=1&limit=200&start=0&address={}",
        TRON_ACCOUNT_TOKENS_API, addr
    );

    let response = client
        .get(&url)
        .header("Accept", "application/json, text/plain, */*")
        .header("Origin", "https://sun.io")
        .header("Referer", "https://sun.io/")
        .header("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36")
        .send()
        .await
        .map_err(|e| format!("HTTP request failed: {}", e))?;

    if !response.status().is_success() {
        return Err(format!("API error: {}", response.status()));
    }

    let api_response: TronAccountResponse = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse TRON account tokens response: {}", e))?;

    let result = api_response
        .data
        .into_iter()
        .map(|token| {
            let mut balances = HashMap::new();
            balances.insert(selected_account, token.balance);

            FTokenInfo {
                name: token.token_name,
                symbol: token.token_abbr,
                decimals: token.token_decimal,
                addr: token.token_id,
                addr_type,
                logo: token.token_logo.or_else(|| default_logo.clone()),
                balances,
                rate: 0.0,
                default: false,
                native: false,
                chain_hash,
            }
        })
        .collect();

    Ok(result)
}

pub async fn auto_hint_tokens(wallet_index: usize) -> Result<Vec<FTokenInfo>, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;

    let wallet = service
        .core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let account = data
        .get_selected_account()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let provider = service
        .core
        .get_provider(data.chain_hash)
        .map_err(ServiceError::BackgroundError)?;

    if provider.config.testnet.unwrap_or(false) {
        return Ok(Vec::new());
    }

    let addr = account
        .addr
        .to_eth_checksummed()
        .unwrap_or_else(|_| account.addr.auto_format());

    let chain_id = provider.config.chain_id();
    let chain_hash = data.chain_hash;
    let addr_type = account.addr.prefix_type();
    let default_logo = provider.config.ftokens.first().and_then(|t| t.logo.clone());

    if data.slip44 == ZILLIQA {
        return fetch_zilliqa_tokens(&account.addr, default_logo, chain_hash).await;
    }

    if data.slip44 == TRON {
        let tron_addr = account.addr.auto_format();
        return fetch_tron_tokens(
            &tron_addr,
            default_logo,
            chain_hash,
            addr_type,
            data.selected_account,
        )
        .await;
    }

    let request_body = serde_json::json!({
        "walletAccount": {
            "platformAddresses": [
                { "address": addr }
            ]
        },
        "chainIds": [chain_id],
        "modifier": {
            "address": addr,
            "includeOverrides": []
        }
    });

    let client = reqwest::Client::new();
    let response = client
        .post(UNISWAP_API_URL)
        .header("Content-Type", "application/json")
        .header("Origin", "https://app.uniswap.org")
        .json(&request_body)
        .send()
        .await
        .map_err(|e| format!("HTTP request failed: {}", e))?;

    if !response.status().is_success() {
        return Err(format!("API error: {}", response.status()));
    }

    let result: PortfolioResponse = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse response: {}", e))?;

    let balances = result
        .portfolio
        .and_then(|p| p.balances)
        .unwrap_or_default();

    let tokens: Vec<FTokenInfo> = balances
        .into_iter()
        .filter_map(|balance| {
            let token = balance.token?;

            if let Some(ref metadata) = token.metadata {
                if let Some(ref protection) = metadata.protection_info {
                    if let Some(ref result) = protection.result {
                        if result == "PROTECTION_RESULT_MALICIOUS"
                            || result == "PROTECTION_RESULT_WARNING"
                        {
                            return None;
                        }
                    }
                }
            }

            let token_type = token.token_type.as_deref()?;
            if token_type != "TOKEN_TYPE_ERC20" {
                return None;
            }

            let address = token.address.as_deref()?;
            if address == ZERO_EVM {
                return None;
            }

            let logo = token
                .metadata
                .as_ref()
                .and_then(|m| m.logo_url.clone())
                .or_else(|| default_logo.clone());

            let mut balances_map = HashMap::new();
            balances_map.insert(
                data.selected_account,
                balance
                    .amount
                    .and_then(|a| a.raw)
                    .unwrap_or_else(|| "0".to_string()),
            );

            Some(FTokenInfo {
                name: token.name.unwrap_or_default(),
                symbol: token.symbol.unwrap_or_default(),
                decimals: token.decimals.unwrap_or(18),
                addr: address.to_string(),
                addr_type,
                logo,
                balances: balances_map,
                rate: 0.0,
                default: false,
                native: false,
                chain_hash,
            })
        })
        .collect();

    Ok(tokens)
}

pub async fn add_ftoken(meta: FTokenInfo, wallet_index: usize) -> Result<Vec<FTokenInfo>, String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let token: FToken = meta.try_into()?;

        wallet
            .add_ftoken(token)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        let ftokens = wallet
            .get_ftokens()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?
            .into_iter()
            .map(|t| t.into())
            .collect();

        Ok(ftokens)
    })
    .await
    .map_err(Into::into)
}

pub async fn rm_ftoken(wallet_index: usize, token_address: String) -> Result<(), String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let ftokens = wallet
            .get_ftokens()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let mb_token_index = ftokens
            .iter()
            .position(|ftoken| ftoken.addr.auto_format() == token_address);

        if let Some(token_index) = mb_token_index {
            wallet
                .remove_ftoken(token_index)
                .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        }

        Ok(())
    })
    .await
    .map_err(Into::into)
}
