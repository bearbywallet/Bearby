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
    crypto::slip44::{BITCOIN, ETHEREUM, ZILLIQA},
    token::ft::FToken,
    wallet::{wallet_storage::StorageOperations, wallet_token::TokenManagement},
};

const UNISWAP_API_URL: &str =
    "https://interface.gateway.uniswap.org/v2/data.v1.DataApiService/GetPortfolio";
const COINGECKO_API_URL: &str = "https://api.coingecko.com/api/v3/simple/price";
const ZILLIQA_SCILLA_TOKENS_API: &str = "https://api.zilpay.io/api/v1/tokens";
const ZILLIQA_EVM_TOKENS_API: &str = "https://api.zilpay.io/api/v1/tokens_evm";
const ZERO_EVM: &str = "0x0000000000000000000000000000000000000000";

type CoinGeckoResponse = HashMap<String, HashMap<String, f64>>;

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

pub async fn update_rates(wallet_index: usize) -> Result<Vec<FTokenInfo>, String> {
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
    let mut ftokens = wallet
        .get_ftokens()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let selected_account = data
        .get_selected_account()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let chain = service
        .core
        .get_provider(selected_account.chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let native_token = chain
        .config
        .ftokens
        .first()
        .ok_or(ServiceError::TokenError(
            zilpay::errors::token::TokenError::TokenParseError,
        ))?;
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
        .map_err(|e| format!("Failed to parse CoinGecko response: {}", e))?;
    let convert_rate = rate
        .get(currency.to_uppercase())
        .and_then(|v| v.as_f64())
        .unwrap_or_default();

    dbg!(convert_rate);

    match chain.config.slip_44 {
        ZILLIQA => {
            let zilstream_url = "https://io-cdn.zilstream.com/tokens";
            let client = reqwest::Client::new();
            let response = client
                .get(zilstream_url)
                .send()
                .await
                .map_err(|e| format!("HTTP request failed: {}", e))?;
            let zilstream_shits: Value = response
                .json()
                .await
                .map_err(|e| format!("Failed to parse CoinGecko response: {}", e))?;

            dbg!(&zilstream_shits);
        }
        ETHEREUM => {}
        BITCOIN => {}
        _ => {}
    }

    return Ok(Vec::new());

    if ftokens.is_empty() {
        return Ok(Vec::new());
    }

    let symbols: String = ftokens
        .iter()
        .map(|t| t.symbol.to_lowercase())
        .collect::<Vec<_>>()
        .join(",");

    let url = format!(
        "{}?symbols={}&vs_currencies={}",
        COINGECKO_API_URL, symbols, currency
    );

    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("HTTP request failed: {}", e))?;

    if !response.status().is_success() {
        return Err(format!("CoinGecko API error: {}", response.status()));
    }

    let rates: CoinGeckoResponse = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse CoinGecko response: {}", e))?;

    // for token in &mut ftokens {
    //     let symbol_lower = token.symbol.to_lowercase();
    //     if let Some(price_data) = rates.get(&symbol_lower) {
    //         if let Some(&rate) = price_data.get(&currency) {
    //             token.rate = rate;
    //         }
    //     }
    // }

    wallet
        .save_ftokens(&ftokens)
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

    let updated_tokens = ftokens.into_iter().map(|t| t.into()).collect();

    Ok(updated_tokens)
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
        .get_provider(account.chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    if provider.config.testnet.unwrap_or(false) {
        return Ok(Vec::new());
    }

    let addr = account
        .addr
        .to_eth_checksummed()
        .unwrap_or_else(|_| account.addr.auto_format());

    let chain_id = account.chain_id;
    let chain_hash = account.chain_hash;
    let addr_type = account.addr.prefix_type();
    let default_logo = provider.config.ftokens.first().and_then(|t| t.logo.clone());

    if account.slip_44 == ZILLIQA {
        return fetch_zilliqa_tokens(&account.addr, default_logo, chain_hash).await;
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
