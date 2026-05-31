use std::collections::{HashMap, HashSet};

use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::wallet::wallet_storage::StorageOperations;

use crate::models::exchange::uniswap::{build_uniswap_tx_info, uniswap_quote_info};
use crate::models::exchange::{ExchangeAsset, ExchangeProvider, ExchangeQuoteInfo, UniswapMeta};
use crate::models::transactions::request::TransactionRequestInfo;
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;

pub async fn bootstrap_exchange_providers() -> Result<Vec<ExchangeAsset>, String> {
    let condidate = HashSet::from([
        ExchangeProvider::Thorchain(0),
        ExchangeProvider::ZIlSwap(0),
        ExchangeProvider::Uniswap(Default::default()),
    ]);

    let guard = BACKGROUND_SERVICE.read().await;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let all_providers = service.core.get_providers();

    dbg!("bootstrap_exchange_providers: chain providers count", all_providers.len());

    // Pre-size on the exact catalog token count (the slice iterators report exact hints).
    let total_tokens: usize = all_providers.iter().map(|p| p.config.ftokens.len()).sum();

    // chain_hash -> (slip44, chain_id), so custom wallet tokens can resolve their chain
    // after the catalog pass below consumes the provider configs.
    let chain_meta: HashMap<u64, (u32, u64)> = all_providers
        .iter()
        .map(|p| (p.config.hash(), (p.config.slip_44, p.config.chain_id())))
        .collect();

    // Exchange providers supported for a given (token address kind, chain).
    let make_providers =
        |addr_prefix: u8, slip_44: u32, chain_id: u64| -> HashSet<ExchangeProvider> {
            condidate
                .iter()
                .filter(|p| p.is_support(addr_prefix, slip_44, chain_id))
                .cloned()
                .map(|p| match p {
                    ExchangeProvider::Uniswap(_) => ExchangeProvider::Uniswap(
                        UniswapMeta::for_chain(chain_id).unwrap_or_default(),
                    ),
                    p => p,
                })
                .collect()
        };

    let mut assets: HashMap<(u64, usize), ExchangeAsset> = HashMap::with_capacity(total_tokens);

    // 1. Catalog: every token on every chain, so all chains are offered for swap/bridge —
    //    not just the wallet's currently selected one. Balances are filled in pass 2.
    for provider in all_providers {
        let chain = provider.config;
        let slip_44 = chain.slip_44;
        let chain_id = chain.chain_id();
        dbg!("bootstrap_exchange_providers: chain", &chain.short_name, chain_id, slip_44, chain.ftokens.len());
        for token in chain.ftokens {
            let key = (token.chain_hash, token.addr.to_hash());
            let providers = make_providers(token.addr.prefix_type(), slip_44, chain_id);
            if !providers.is_empty() {
                dbg!("bootstrap_exchange_providers: token + providers",
                    &token.symbol,
                    &token.name,
                    chain_id,
                    token.addr.prefix_type(),
                    &providers,
                );
            }
            assets.entry(key).or_insert_with(|| ExchangeAsset {
                token: token.into(),
                providers,
                halted: true,
            });
        }
    }

    // 2. Wallet holdings: overlay real balances onto catalog tokens, and add any custom
    //    tokens the user imported that aren't part of a chain catalog.
    for wallet in service.core.wallets.iter() {
        for token in wallet.get_ftokens().map_err(|e| e.to_string())? {
            let key = (token.chain_hash, token.addr.to_hash());
            match assets.get_mut(&key) {
                Some(existing) => {
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
                        dbg!("bootstrap_exchange_providers: custom token, chain meta not found", &token.symbol, token.chain_hash);
                        continue;
                    };
                    let providers = make_providers(token.addr.prefix_type(), slip_44, chain_id);
                    dbg!("bootstrap_exchange_providers: custom wallet token",
                        &token.symbol,
                        chain_id,
                        &providers,
                    );
                    assets.insert(
                        key,
                        ExchangeAsset {
                            token: token.into(),
                            providers,
                            halted: true,
                        },
                    );
                }
            }
        }
    }

    let result: Vec<ExchangeAsset> = assets.into_values().collect();
    dbg!("bootstrap_exchange_providers: DONE", result.len());
    Ok(result)
}

pub async fn fetch_exchange_quote(
    asset: ExchangeAsset,
    from_asset: String,
    to_asset: String,
    amount: String,
    destination: String,
) -> Result<Vec<ExchangeQuoteInfo>, String> {
    dbg!("fetch_exchange_quote: START",
        &asset.token.symbol,
        &asset.token.chain_hash,
        &asset.token.native,
        &from_asset,
        &to_asset,
        &amount,
        &destination,
        &asset.providers,
    );

    let mut quotes = Vec::with_capacity(asset.providers.len());
    for provider in &asset.providers {
        dbg!("fetch_exchange_quote: trying provider", provider);
        let result = match provider {
            ExchangeProvider::Uniswap(meta) => {
                uniswap_quote_info(meta, &asset, &from_asset, &to_asset, &amount, &destination)
                    .await
            }
            ExchangeProvider::Thorchain(_) => {
                dbg!("fetch_exchange_quote: Thorchain not yet implemented, skipping");
                continue;
            }
            ExchangeProvider::ZIlSwap(_) => {
                dbg!("fetch_exchange_quote: ZIlSwap not yet implemented, skipping");
                continue;
            }
            ExchangeProvider::SunSwap(_) => {
                dbg!("fetch_exchange_quote: SunSwap not yet implemented, skipping");
                continue;
            }
        };
        if let Err(e) = &result {
            dbg!("fetch_exchange_quote: provider FAILED", provider, e);
        }
        if let Ok(quote) = result {
            dbg!("fetch_exchange_quote: provider OK", provider, &quote.amount_out);
            quotes.push(quote);
        }
    }
    if quotes.is_empty() {
        dbg!("fetch_exchange_quote: NO provider returned a quote");
        Err("No provider returned a quote".into())
    } else {
        dbg!("fetch_exchange_quote: SUCCESS", quotes.len());
        Ok(quotes)
    }
}

/// Build the unsigned swap (or cross-chain bridge) transaction for the chosen provider.
/// The UI signs and broadcasts it via the existing `sign_send_transactions` FFI. For
/// native inputs `token_in` is ignored (the provider uses its own native sentinel); for
/// ERC20 inputs requiring Permit2 the EIP-712 signature is produced internally from the
/// freshly fetched quote and the supplied `password`/`passphrase`, so the UI never signs
/// the permit itself.
#[allow(clippy::too_many_arguments)]
pub async fn build_exchange_tx(
    wallet_index: usize,
    account_index: usize,
    provider: ExchangeProvider,
    token_in: String,
    token_out: String,
    amount_in: String,
    amount_out: String,
    fee_tier: u32,
    slippage_bps: u32,
    deadline: u64,
    is_native_in: bool,
    permit_nonce: Option<u64>,
    password: Option<String>,
    passphrase: Option<String>,
) -> Result<TransactionRequestInfo, String> {
    // The Trading API derives routing, fees and the Permit2 nonce itself, so these legacy
    // on-chain params are accepted for FFI stability but unused by the Uniswap arm.
    let _ = (&amount_out, &fee_tier, &deadline, &permit_nonce);

    match provider {
        ExchangeProvider::Uniswap(meta) => {
            build_uniswap_tx_info(
                wallet_index,
                account_index,
                &meta,
                token_in,
                token_out,
                amount_in,
                slippage_bps,
                is_native_in,
                password,
                passphrase,
            )
            .await
        }
        ExchangeProvider::Thorchain(_) => todo!(),
        ExchangeProvider::ZIlSwap(_) => todo!(),
        ExchangeProvider::SunSwap(_) => todo!(),
    }
}
