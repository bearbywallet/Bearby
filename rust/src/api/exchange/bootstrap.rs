use std::collections::{HashMap, HashSet};

use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_wallet::WalletManagement;
use zilpay::crypto::slip44::{TRON, ZILLIQA};
use zilpay::rpc::network_config::ChainConfig;
use zilpay::wallet::wallet_storage::StorageOperations;

use crate::models::exchange::{
    ExchangeAsset, ExchangeProvider, PancakeMeta, ProviderQuote, RelayMeta, SunSwapMeta,
    UniswapMeta, ZilSwapMeta,
};
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::{BackgroundError, ServiceError};

fn chain_matches_network(chain: &ChainConfig, is_testnet: bool) -> bool {
    chain.testnet.unwrap_or(false) == is_testnet
}

pub async fn bootstrap_exchange_providers(
    wallet_index: usize,
    account_index: usize,
) -> Result<Vec<ExchangeAsset>, String> {
    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let all_providers = service.core.get_providers();
    let wallet = service
        .core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let wallet_data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let current_is_testnet = all_providers
        .iter()
        .find(|p| p.config.hash() == wallet_data.chain_hash)
        .map(|p| p.config.testnet.unwrap_or(false))
        .ok_or(ServiceError::BackgroundError(
            BackgroundError::ProviderNotExists(wallet_data.chain_hash),
        ))?;

    let mut relay_accounts: HashMap<u32, String> =
        HashMap::with_capacity(wallet_data.slip44_accounts.len());
    for (slip44, bip_accounts) in &wallet_data.slip44_accounts {
        let accounts = bip_accounts
            .get(&wallet_data.bip)
            .or_else(|| bip_accounts.values().next());
        if let Some(account) = accounts.and_then(|items| items.get(account_index)) {
            relay_accounts.insert(*slip44, account.addr.auto_format());
        }
    }

    let total_tokens: usize = all_providers
        .iter()
        .filter(|p| chain_matches_network(&p.config, current_is_testnet))
        .map(|p| p.config.ftokens.len())
        .sum();

    let chain_meta: HashMap<u64, (u32, u64)> = all_providers
        .iter()
        .filter(|p| chain_matches_network(&p.config, current_is_testnet))
        .map(|p| (p.config.hash(), (p.config.slip_44, p.config.chain_id())))
        .collect();

    let make_providers = |addr_prefix: u8,
                          slip_44: u32,
                          chain_id: u64,
                          chain_hash: u64|
     -> HashSet<ExchangeProvider> {
        let account_addr = relay_accounts.get(&slip_44);
        let mut providers = HashSet::with_capacity(5);

        if let Some(account_addr) = account_addr {
            if addr_prefix == 1 && crate::models::exchange::uniswap::is_supported_chain(chain_id) {
                if let Some(meta) =
                    UniswapMeta::for_chain(chain_hash, chain_id, slip_44, account_addr)
                {
                    providers.insert(ExchangeProvider::Uniswap(meta));
                }
            }

            if addr_prefix == 1
                && crate::models::exchange::pancakeswap::is_supported_chain(chain_id)
            {
                if let Some(meta) =
                    PancakeMeta::for_chain(chain_hash, chain_id, slip_44, account_addr)
                {
                    providers.insert(ExchangeProvider::PancakeSwap(meta));
                }
            }

            if let Some(meta) =
                RelayMeta::for_chain(chain_hash, addr_prefix, chain_id, account_addr)
            {
                providers.insert(ExchangeProvider::Relay(meta));
            }

            if addr_prefix == 0 && slip_44 == ZILLIQA {
                providers.insert(ExchangeProvider::ZilSwap(ZilSwapMeta::for_chain(
                    chain_hash,
                    chain_id,
                    slip_44,
                    account_addr,
                )));
            }

            if addr_prefix == 4 && slip_44 == TRON {
                providers.insert(ExchangeProvider::SunSwap(SunSwapMeta::for_chain(
                    chain_hash,
                    chain_id,
                    slip_44,
                    account_addr,
                )));
            }
        }

        providers
    };

    let resolve_halted =
        |_providers: &HashSet<ExchangeProvider>, _slip_44: u32, _chain_id: u64| false;

    let active_chain_hash = wallet_data.chain_hash;
    let scope_providers = |providers: &mut HashSet<ExchangeProvider>, token_chain_hash: u64| {
        if token_chain_hash != active_chain_hash {
            providers.retain(ExchangeProvider::is_bridge);
        }
    };

    let mut assets: HashMap<(u64, usize), ExchangeAsset> = HashMap::with_capacity(total_tokens);

    for provider in all_providers
        .into_iter()
        .filter(|p| chain_matches_network(&p.config, current_is_testnet))
    {
        let chain = provider.config;
        let slip_44 = chain.slip_44;
        let chain_id = chain.chain_id();
        for token in chain.ftokens {
            let key = (token.chain_hash, token.addr.to_hash());
            let mut providers = make_providers(
                token.addr.prefix_type(),
                slip_44,
                chain_id,
                token.chain_hash,
            );
            scope_providers(&mut providers, token.chain_hash);
            let halted = resolve_halted(&providers, slip_44, chain_id);
            assets.entry(key).or_insert_with(|| ExchangeAsset {
                token: token.into(),
                providers,
                halted,
            });
        }
    }

    for wallet in service.core.wallets.iter() {
        for token in wallet.get_ftokens().map_err(|e| e.to_string())? {
            let key = (token.chain_hash, token.addr.to_hash());
            match assets.get_mut(&key) {
                Some(existing) => {
                    existing.token.rate = token.rate;
                    for (&account_idx, balance) in &token.balances {
                        existing
                            .token
                            .balances
                            .entry(account_idx)
                            .or_insert_with(|| balance.to_string());
                    }
                }
                None => {
                    let Some(&(slip_44, chain_id)) = chain_meta.get(&token.chain_hash) else {
                        continue;
                    };
                    let mut providers = make_providers(
                        token.addr.prefix_type(),
                        slip_44,
                        chain_id,
                        token.chain_hash,
                    );
                    scope_providers(&mut providers, token.chain_hash);
                    let halted = resolve_halted(&providers, slip_44, chain_id);
                    assets.insert(
                        key,
                        ExchangeAsset {
                            token: token.into(),
                            providers,
                            halted,
                        },
                    );
                }
            }
        }
    }

    Ok(assets
        .into_values()
        .filter(|asset| !asset.providers.is_empty())
        .collect())
}

pub async fn refresh_exchange_quotes(
    from: ExchangeAsset,
    to: ExchangeAsset,
    amount: String,
) -> Result<ExchangeAsset, String> {
    let from_addr = from.token.addr.as_str();
    let to_addr = to.token.addr.as_str();

    if let Some(provider) = from
        .providers
        .iter()
        .find(|p| p.is_wrap_unwrap(&from, &to, from_addr, to_addr).unwrap_or(false))
    {
        let quote = ProviderQuote {
            amount_out: amount,
            permit_typed_data_json: None,
            is_wrap_unwrap: true,
        };
        let mut providers = HashSet::with_capacity(1);
        providers.insert(provider.clone().with_quote(quote));
        return Ok(ExchangeAsset {
            token: from.token,
            providers,
            halted: from.halted,
        });
    }

    let from_token = from.token;
    let halted = from.halted;
    let handles: Vec<_> = from
        .providers
        .into_iter()
        .map(|provider| {
            let from_asset = ExchangeAsset {
                token: from_token.clone(),
                providers: HashSet::with_capacity(0),
                halted,
            };
            let to_asset = to.clone();
            let amount = amount.clone();
            zilpay::tokio::task::spawn(async move {
                let from_addr = from_asset.token.addr.clone();
                let to_addr = to_asset.token.addr.clone();
                provider
                    .quote_info(
                        &from_asset,
                        &to_asset,
                        from_addr.as_str(),
                        to_addr.as_str(),
                        &amount,
                    )
                    .await
                    .ok()
                    .map(|quote| provider.with_quote(quote))
            })
        })
        .collect();

    let mut providers = HashSet::with_capacity(handles.len());
    for handle in handles {
        if let Ok(Some(provider)) = handle.await {
            providers.insert(provider);
        }
    }

    Ok(ExchangeAsset {
        token: from_token,
        providers,
        halted,
    })
}
