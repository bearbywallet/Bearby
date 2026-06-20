use std::collections::{HashMap, HashSet};
use std::str::FromStr;

use zilpay::alloy::hex;
use zilpay::alloy::primitives::{Address, U256};
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_wallet::WalletManagement;
use zilpay::crypto::slip44::{BITCOIN, TRON, ZILLIQA};
use zilpay::proto::pubkey::PubKey;
use zilpay::rpc::{
    common::JsonRPC, methods::EvmMethods, network_config::ChainConfig, provider::RpcProvider,
    zil_interfaces::ResultRes,
};
use zilpay::wallet::bitcoin_wallet::BitcoinWallet;
use zilpay::wallet::wallet_storage::StorageOperations;

use crate::models::exchange::{
    plunderswap, ExchangeAsset, ExchangeProvider, PancakeMeta, PlunderMeta, ProviderQuote,
    RelayMeta, SunSwapMeta, UniswapMeta, ZilSwapMeta,
};
use crate::utils::{
    errors::{BackgroundError, ServiceError},
    helpers::handle,
};
use zilpay::serde_json::{json, Value};

fn chain_matches_network(chain: &ChainConfig, is_testnet: bool) -> bool {
    chain.testnet.unwrap_or(false) == is_testnet
}

const fn zilliqa_mode_addr_type(zil_evm_mode: bool) -> u8 {
    if zil_evm_mode {
        1
    } else {
        0
    }
}

fn zilliqa_token_matches_mode(slip_44: u32, addr_prefix: u8, zil_evm_mode: bool) -> bool {
    slip_44 != ZILLIQA || addr_prefix == zilliqa_mode_addr_type(zil_evm_mode)
}

fn provider_names(providers: &HashSet<ExchangeProvider>) -> String {
    let mut names: Vec<&str> = providers
        .iter()
        .map(|provider| match provider {
            ExchangeProvider::Relay(_) => "Relay",
            ExchangeProvider::Uniswap(_) => "Uniswap",
            ExchangeProvider::PancakeSwap(_) => "PancakeSwap",
            ExchangeProvider::PlunderSwap(_) => "PlunderSwap",
            ExchangeProvider::ZilSwap(_) => "ZilSwap",
            ExchangeProvider::SunSwap(_) => "SunSwap",
        })
        .collect();
    names.sort_unstable();
    names.join(",")
}

fn has_plunderswap(providers: &HashSet<ExchangeProvider>) -> bool {
    providers
        .iter()
        .any(|provider| matches!(provider, ExchangeProvider::PlunderSwap(_)))
}

fn remove_plunderswap(providers: &mut HashSet<ExchangeProvider>) {
    providers.retain(|provider| !matches!(provider, ExchangeProvider::PlunderSwap(_)));
}

fn plunder_probe_amount() -> U256 {
    // 1,000 WZIL. The lens receives post-fee amounts in normal quote flow, but
    // bootstrap only cares whether a route exists and returns non-zero output.
    U256::from(1_000_000_000_000_000_000_000u128)
}

async fn request_plunder_gate_batch(
    chain_config: &ChainConfig,
    payload: Value,
) -> Result<Vec<ResultRes<Value>>, String> {
    let provider: RpcProvider<ChainConfig> = RpcProvider::new(chain_config);
    match provider.req::<Vec<ResultRes<Value>>>(payload.clone()).await {
        Ok(res) => Ok(res),
        Err(primary_error) => {
            if chain_config.chain_id() != plunderswap::ZILLIQA_MAINNET_CHAIN_ID {
                return Err(primary_error.to_string());
            }

            let client = zilpay::reqwest::Client::new();
            let mut fallback_error = primary_error.to_string();
            for url in ["https://api.zilliqa.com/evm", "https://api.zilliqa.com"] {
                eprintln!("[exchange-bootstrap] retry Plunder liquidity gate rpc_url={url}");
                let response = client.post(url).json(&payload).send().await;
                match response {
                    Ok(response) => match response.json::<Vec<ResultRes<Value>>>().await {
                        Ok(res) => return Ok(res),
                        Err(err) => fallback_error = err.to_string(),
                    },
                    Err(err) => fallback_error = err.to_string(),
                }
            }

            Err(fallback_error)
        }
    }
}

async fn gate_plunderswap_liquidity(
    chain_config: Option<&ChainConfig>,
    assets: &mut HashMap<(u64, usize, u8), ExchangeAsset>,
) {
    let Some(chain_config) = chain_config else {
        return;
    };
    let Some(meta) = PlunderMeta::for_chain(
        chain_config.hash(),
        chain_config.chain_id(),
        chain_config.slip_44,
        "0x0000000000000000000000000000000000000001",
    ) else {
        return;
    };
    let cfg = match meta.resolve() {
        Ok(cfg) => cfg,
        Err(err) => {
            eprintln!("[exchange-bootstrap] Plunder liquidity gate config_error={err}");
            return;
        }
    };

    let candidates: Vec<((u64, usize, u8), String, Address)> = assets
        .iter()
        .filter_map(|(key, asset)| {
            if !has_plunderswap(&asset.providers) || asset.token.native {
                return None;
            }
            let token = Address::from_str(&asset.token.addr).ok()?;
            if token == cfg.addrs.wzil {
                return None;
            }
            Some((*key, asset.token.symbol.clone(), token))
        })
        .collect();

    if candidates.is_empty() {
        return;
    }

    // Gate on WZIL -> token reachability: the lens routes through configured hubs, so this also
    // covers tokens that only pair via a hub (e.g. WZIL -> zUSDT -> token). A token reachable only
    // through a non-WZIL hub is intentionally gated out — the exchange funds swaps from ZIL/WZIL.
    let probe_amount = plunder_probe_amount();
    let calls: Vec<Value> = candidates
        .iter()
        .map(|(_, _, token)| {
            let data = plunderswap::encode_quote_lens_call(cfg.addrs.wzil, *token, probe_amount);
            RpcProvider::<ChainConfig>::build_payload(
                json!([
                    {
                        "to": cfg.addrs.quote_lens.to_string(),
                        "data": hex::encode_prefixed(&data),
                        "gas": format!("0x{:x}", plunderswap::QUOTE_LENS_GAS),
                    },
                    "latest"
                ]),
                EvmMethods::Call,
            )
        })
        .collect();

    eprintln!(
        "[exchange-bootstrap] Plunder liquidity gate candidates={} lens={} gas=0x{:x}",
        candidates.len(),
        cfg.addrs.quote_lens,
        plunderswap::QUOTE_LENS_GAS,
    );

    let results = match request_plunder_gate_batch(chain_config, Value::Array(calls)).await {
        Ok(results) => results,
        Err(err) => {
            // Fail open: a transient RPC error must not strip PlunderSwap from liquid pairs.
            // Genuinely dead pairs still surface "no liquidity" at quote time.
            eprintln!("[exchange-bootstrap] Plunder liquidity gate skipped (rpc error): {err}");
            return;
        }
    };

    for (index, (key, symbol, token)) in candidates.iter().enumerate() {
        // Fail open: only strip PlunderSwap on a *decoded* no-liquidity answer. A missing item,
        // RPC item-error, or decode failure leaves the provider in place — quote time still gates
        // genuinely-dead pairs, so a flaky probe never hides a working pair.
        let confirmed_no_liquidity = results
            .get(index)
            .filter(|item| item.error.is_none())
            .and_then(|item| item.result.as_ref())
            .and_then(Value::as_str)
            .and_then(|raw| hex::decode(raw).ok())
            .and_then(|bytes| plunderswap::decode_quote_lens_return(&bytes))
            .is_some_and(|quote| {
                quote.route_type == plunderswap::ROUTE_NONE || quote.amount_out == U256::ZERO
            });
        if confirmed_no_liquidity {
            if let Some(asset) = assets.get_mut(key) {
                remove_plunderswap(&mut asset.providers);
                eprintln!(
                    "[exchange-bootstrap] remove PlunderSwap symbol={symbol} token={token} reason=no_liquidity"
                );
            }
        }
    }
}

pub async fn bootstrap_exchange_providers(
    wallet_index: usize,
    account_index: usize,
) -> Result<Vec<ExchangeAsset>, String> {
    let core = handle().await?;
    let all_providers = core.get_providers();
    let wallet = core
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
    let mut zil_evm_account: Option<String> = None;
    for (slip44, bip_accounts) in &wallet_data.slip44_accounts {
        let accounts = bip_accounts
            .get(&wallet_data.bip)
            .or_else(|| bip_accounts.values().next());
        if let Some(account) = accounts.and_then(|items| items.get(account_index)) {
            let is_zilliqa_evm = *slip44 == ZILLIQA
                && matches!(&account.pub_key, Some(PubKey::Secp256k1Keccak256(_)));
            if is_zilliqa_evm {
                zil_evm_account = Some(account.addr.auto_format());
            }

            if *slip44 == BITCOIN {
                let btc_chain_hash = all_providers
                    .iter()
                    .find(|p| {
                        p.config.slip_44 == BITCOIN
                            && chain_matches_network(&p.config, current_is_testnet)
                    })
                    .map(|p| p.config.hash());
                let btc_addr = match btc_chain_hash {
                    Some(hash) => match wallet.get_btc_addresses(account_index, hash) {
                        Ok(chains) => {
                            match zilpay::wallet::bitcoin_wallet::pick_entry_with_most_utxo(&chains)
                                .or_else(|_| {
                                    zilpay::wallet::bitcoin_wallet::pick_primary_btc_entry(&chains)
                                }) {
                                Ok(entry) => {
                                    let _utxo_total: u64 =
                                        entry.utxos.iter().map(|u| u.value).sum();
                                    entry.address.auto_format()
                                }
                                Err(e) => {
                                    eprintln!(
                                        "[btc-relay] pick_entry failed, falling back to account.addr: {e}"
                                    );
                                    account.addr.auto_format()
                                }
                            }
                        }
                        Err(e) => {
                            eprintln!(
                                "[btc-relay] get_btc_addresses failed, falling back to account.addr: {e}"
                            );
                            account.addr.auto_format()
                        }
                    },
                    None => {
                        eprintln!(
                            "[btc-relay] no BTC provider found, falling back to account.addr"
                        );
                        account.addr.auto_format()
                    }
                };
                relay_accounts.insert(*slip44, btc_addr);
            } else {
                relay_accounts.insert(*slip44, account.addr.auto_format());
            }
        }
    }

    let zil_evm_mode = zil_evm_account.is_some();
    let zil_mode_addr_type = zilliqa_mode_addr_type(zil_evm_mode);
    eprintln!(
        "[exchange-bootstrap] wallet_index={wallet_index} account_index={account_index} active_chain_hash={} current_is_testnet={current_is_testnet} zil_mode={} zil_addr_type={zil_mode_addr_type} relay_accounts={}",
        wallet_data.chain_hash,
        if zil_evm_mode { "evm" } else { "scilla" },
        relay_accounts.len()
    );

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

    let plunder_chain_config = all_providers
        .iter()
        .find(|p| {
            chain_matches_network(&p.config, current_is_testnet)
                && p.config.slip_44 == ZILLIQA
                && plunderswap::is_supported_chain(p.config.chain_id())
        })
        .map(|p| p.config.clone());

    let make_providers = |addr_prefix: u8,
                          slip_44: u32,
                          chain_id: u64,
                          chain_hash: u64|
     -> HashSet<ExchangeProvider> {
        let account_addr = relay_accounts.get(&slip_44);
        let mut providers = HashSet::with_capacity(6);

        if let Some(account_addr) = account_addr {
            if addr_prefix == 1
                && slip_44 != ZILLIQA
                && crate::models::exchange::uniswap::is_supported_chain(chain_id)
            {
                if let Some(meta) =
                    UniswapMeta::for_chain(chain_hash, chain_id, slip_44, account_addr)
                {
                    providers.insert(ExchangeProvider::Uniswap(meta));
                }
            }

            if addr_prefix == 1
                && slip_44 != ZILLIQA
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
                if let Some(meta) =
                    ZilSwapMeta::for_chain(chain_hash, chain_id, slip_44, account_addr)
                {
                    providers.insert(ExchangeProvider::ZilSwap(meta));
                }
            }

            if addr_prefix == 1 && slip_44 == ZILLIQA {
                if let Some(evm_addr) = zil_evm_account.as_deref() {
                    if crate::models::exchange::plunderswap::is_supported_chain(chain_id) {
                        if let Some(meta) =
                            PlunderMeta::for_chain(chain_hash, chain_id, slip_44, evm_addr)
                        {
                            providers.insert(ExchangeProvider::PlunderSwap(meta));
                        }
                    }
                }
            }

            if addr_prefix == 4 && slip_44 == TRON {
                if let Some(meta) = SunSwapMeta::for_chain(chain_hash, chain_id, slip_44, account_addr)
                {
                    providers.insert(ExchangeProvider::SunSwap(meta));
                }
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

    let mut assets: HashMap<(u64, usize, u8), ExchangeAsset> = HashMap::with_capacity(total_tokens);
    let mut skipped_mode_tokens = 0usize;

    for provider in all_providers
        .into_iter()
        .filter(|p| chain_matches_network(&p.config, current_is_testnet))
    {
        let chain = provider.config;
        let slip_44 = chain.slip_44;
        let chain_id = chain.chain_id();
        for token in chain.ftokens {
            let addr_prefix = token.addr.prefix_type();
            if !zilliqa_token_matches_mode(slip_44, addr_prefix, zil_evm_mode) {
                skipped_mode_tokens = skipped_mode_tokens.saturating_add(1);
                eprintln!(
                    "[exchange-bootstrap] skip mode-mismatch provider_token symbol={} chain_hash={} addr_type={} expected_addr_type={zil_mode_addr_type}",
                    token.symbol,
                    token.chain_hash,
                    addr_prefix
                );
                continue;
            }
            let key = (token.chain_hash, token.addr.to_hash(), addr_prefix);
            let mut providers = make_providers(addr_prefix, slip_44, chain_id, token.chain_hash);
            scope_providers(&mut providers, token.chain_hash);
            let halted = resolve_halted(&providers, slip_44, chain_id);
            let names = provider_names(&providers);
            if !providers.is_empty() {
                eprintln!(
                    "[exchange-bootstrap] add provider_token symbol={} chain_hash={} addr_type={} providers={names}",
                    token.symbol,
                    token.chain_hash,
                    addr_prefix
                );
            }
            assets.entry(key).or_insert_with(|| ExchangeAsset {
                token: token.into(),
                providers,
                halted,
            });
        }
    }

    for wallet in core.wallets.iter() {
        for token in wallet.get_ftokens().map_err(|e| e.to_string())? {
            let addr_prefix = token.addr.prefix_type();
            if let Some(&(slip_44, _)) = chain_meta.get(&token.chain_hash) {
                if !zilliqa_token_matches_mode(slip_44, addr_prefix, zil_evm_mode) {
                    skipped_mode_tokens = skipped_mode_tokens.saturating_add(1);
                    eprintln!(
                        "[exchange-bootstrap] skip mode-mismatch wallet_token symbol={} chain_hash={} addr_type={} expected_addr_type={zil_mode_addr_type}",
                        token.symbol,
                        token.chain_hash,
                        addr_prefix
                    );
                    continue;
                }
            }
            let key = (token.chain_hash, token.addr.to_hash(), addr_prefix);
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
                    let mut providers =
                        make_providers(addr_prefix, slip_44, chain_id, token.chain_hash);
                    scope_providers(&mut providers, token.chain_hash);
                    let halted = resolve_halted(&providers, slip_44, chain_id);
                    let names = provider_names(&providers);
                    if !providers.is_empty() {
                        eprintln!(
                            "[exchange-bootstrap] add wallet_token symbol={} chain_hash={} addr_type={} providers={names}",
                            token.symbol,
                            token.chain_hash,
                            addr_prefix
                        );
                    }
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

    gate_plunderswap_liquidity(plunder_chain_config.as_ref(), &mut assets).await;

    let result: Vec<ExchangeAsset> = assets
        .into_values()
        .filter(|asset| !asset.providers.is_empty())
        .collect();
    eprintln!(
        "[exchange-bootstrap] complete assets={} skipped_mode_tokens={skipped_mode_tokens}",
        result.len()
    );

    Ok(result)
}

pub async fn refresh_exchange_quotes(
    from: ExchangeAsset,
    to: ExchangeAsset,
    amount: String,
) -> Result<ExchangeAsset, String> {
    let from_addr = from.token.addr.as_str();
    let to_addr = to.token.addr.as_str();
    if let Some(provider) = from.providers.iter().find(|p| {
        p.is_wrap_unwrap(&from, &to, from_addr, to_addr)
            .unwrap_or(false)
    }) {
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
                let provider_name = provider.common().display_name.clone();
                match provider
                    .quote_info(
                        &from_asset,
                        &to_asset,
                        from_addr.as_str(),
                        to_addr.as_str(),
                        &amount,
                    )
                    .await
                {
                    Ok(quote) => Some(provider.with_quote(quote)),
                    Err(err) => {
                        eprintln!(
                            "[exchange-quotes] provider={provider_name} from_symbol={} to_symbol={} from_addr_type={} to_addr_type={} amount={} error={err}",
                            from_asset.token.symbol,
                            to_asset.token.symbol,
                            from_asset.token.addr_type,
                            to_asset.token.addr_type,
                            amount
                        );
                        Some(provider.without_quote())
                    }
                }
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
