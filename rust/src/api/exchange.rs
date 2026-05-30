use std::collections::{HashMap, HashSet};

use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::rpc::network_config::ChainConfig;
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
    let all_ftokens: Vec<ExchangeAsset> = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        let all_chain: Vec<ChainConfig> = service
            .core
            .get_providers()
            .into_iter()
            .map(|n| n.config)
            .collect();

        let mut assets: HashMap<(u64, usize), ExchangeAsset> = HashMap::new();

        for wallet in service.core.wallets.iter() {
            let ftokens = wallet.get_ftokens().map_err(|e| e.to_string())?;
            for t in ftokens {
                let key = (t.chain_hash, t.addr.to_hash());

                if let Some(existing) = assets.get_mut(&key) {
                    for (&account_idx, balance) in &t.balances {
                        existing
                            .token
                            .balances
                            .entry(account_idx)
                            .or_insert(balance.to_string());
                    }
                    continue;
                }

                let chain = match all_chain.iter().find(|c| c.hash() == t.chain_hash) {
                    Some(c) => c,
                    None => continue,
                };
                let providers: HashSet<ExchangeProvider> = condidate
                    .iter()
                    .filter(|p| p.is_support(t.addr.prefix_type(), chain.slip_44, chain.chain_id()))
                    .cloned()
                    .map(|p| match p {
                        ExchangeProvider::Uniswap(_) => ExchangeProvider::Uniswap(
                            UniswapMeta::for_chain(chain.chain_id()).unwrap_or_default(),
                        ),
                        p => p,
                    })
                    .collect();

                assets.insert(
                    key,
                    ExchangeAsset {
                        token: t.into(),
                        providers,
                        halted: true,
                    },
                );
            }
        }

        assets.into_values().collect::<Vec<ExchangeAsset>>()
    }
    .into_iter()
    .collect();

    Ok(all_ftokens)
}

pub async fn fetch_exchange_quote(
    asset: ExchangeAsset,
    from_asset: String,
    to_asset: String,
    amount: String,
    destination: String,
) -> Result<Vec<ExchangeQuoteInfo>, String> {
    let mut quotes = Vec::with_capacity(asset.providers.len());
    for provider in &asset.providers {
        let result = match provider {
            ExchangeProvider::Uniswap(meta) => {
                uniswap_quote_info(meta, &asset, &from_asset, &to_asset, &amount, &destination)
                    .await
            }
            ExchangeProvider::Thorchain(_) => continue,
            ExchangeProvider::ZIlSwap(_) => continue,
            ExchangeProvider::SunSwap(_) => continue,
        };
        if let Ok(quote) = result {
            quotes.push(quote);
        }
    }
    if quotes.is_empty() {
        Err("No provider returned a quote".into())
    } else {
        Ok(quotes)
    }
}

/// Build the unsigned swap transaction for the chosen provider. The UI signs and
/// broadcasts it via the existing `sign_send_transactions` FFI. `token_in` is the WETH
/// address for native ETH inputs. For ERC20 inputs the Permit2 EIP-712 signature is
/// produced internally from `permit_nonce` and the supplied `password`/`passphrase`, so
/// the UI never signs the permit itself.
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
    match provider {
        ExchangeProvider::Uniswap(meta) => {
            build_uniswap_tx_info(
                wallet_index,
                account_index,
                &meta,
                token_in,
                token_out,
                amount_in,
                amount_out,
                fee_tier,
                slippage_bps,
                deadline,
                is_native_in,
                permit_nonce,
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
