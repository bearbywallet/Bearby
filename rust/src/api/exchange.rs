use std::collections::HashSet;

use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::rpc::network_config::ChainConfig;
use zilpay::token::ft::FToken;
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
        let mut seen = HashSet::new();
        let all_chain: Vec<ChainConfig> = service
            .core
            .get_providers()
            .into_iter()
            .map(|n| n.config)
            .collect();
        let all_ftokens: Vec<ExchangeAsset> = service
            .core
            .wallets
            .iter()
            .map(|w| w.get_ftokens().map_err(|e| e.to_string()))
            .collect::<Result<Vec<Vec<FToken>>, String>>()?
            .into_iter()
            .flatten()
            .filter_map(|t: FToken| {
                // Dedup by (chain, addr): native tokens use an all-zero address, so
                // `to_hash()` alone collides across every chain (and between ETH/ZIL),
                // which would drop every native asset but the first one.
                if !seen.insert((t.chain_hash, t.addr.to_hash())) {
                    return None;
                }

                let chain = all_chain.iter().find(|c| c.hash() == t.chain_hash)?;
                let slip44 = chain.slip_44;
                let chain_id = chain.chain_id();
                let addr_type = t.addr.prefix_type();
                let providers: HashSet<ExchangeProvider> = condidate
                    .iter()
                    .filter(|p| p.is_support(addr_type, slip44, chain_id))
                    .cloned()
                    .collect();

                Some(ExchangeAsset {
                    token: t.into(),
                    providers,
                    halted: true,
                })
            })
            .collect();

        all_ftokens
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
