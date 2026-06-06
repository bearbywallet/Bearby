use std::collections::{HashMap, HashSet};
use std::str::FromStr;
use std::sync::Arc;

use zilpay::alloy::primitives::Address as AlloyAddress;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_tx::{update_tx_from_params, TransactionsManagement};
use zilpay::background::bg_wallet::WalletManagement;
use zilpay::background::Background;
use zilpay::crypto::slip44::{TRON, ZILLIQA};
use zilpay::network::evm::RequiredTxParams;
use zilpay::proto::address::Address;
use zilpay::proto::tx::{ETHTransactionRequest, TransactionMetadata, TransactionRequest};
use zilpay::proto::U256;
use zilpay::secrecy::SecretString;
use zilpay::wallet::wallet_storage::StorageOperations;

use crate::api::transaction::{sign_and_broadcast_one, unlock_seed};
use crate::frb_generated::StreamSink;
use crate::models::exchange::univ_router::{
    finalize_router_swap, is_wrap_unwrap, prepare_router_swap, router_check_approval,
    router_quote_info,
};
use crate::models::exchange::{
    ExchangeAsset, ExchangeProvider, ExchangeQuoteInfo, ExchangeTxDisplay, PancakeMeta, UniswapMeta,
};
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;

/// Synchronous bootstrap of all exchange providers across every registered chain.
pub async fn bootstrap_exchange_providers() -> Result<Vec<ExchangeAsset>, String> {
    let guard = BACKGROUND_SERVICE
        .try_read()
        .map_err(|_| "service lock contention".to_string())?;
    let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
    let all_providers = service.core.get_providers();

    dbg!("called bootstrap_exchange_providers");

    // Pre-size on the exact catalog token count (the slice iterators report exact hints).
    let total_tokens: usize = all_providers.iter().map(|p| p.config.ftokens.len()).sum();

    // chain_hash -> (slip44, chain_id), so custom wallet tokens can resolve their chain
    // after the catalog pass below consumes the provider configs.
    let chain_meta: HashMap<u64, (u32, u64)> = all_providers
        .iter()
        .map(|p| (p.config.hash(), (p.config.slip_44, p.config.chain_id())))
        .collect();

    // Exchange providers are constructed explicitly per token — no default/empty candidates.
    // Each branch gates on chain/token support (slip44, chain_id, addr_type, pool membership)
    // before inserting the provider with its resolved metadata.
    let make_providers = |addr_prefix: u8,
                          slip_44: u32,
                          chain_id: u64|
     -> HashSet<ExchangeProvider> {
        let mut providers = HashSet::new();

        // Uniswap — EVM chains with a deployed Universal Router
        if addr_prefix == 1 && crate::models::exchange::uniswap::is_supported_chain(chain_id) {
            if let Some(meta) = UniswapMeta::for_chain(chain_id) {
                providers.insert(ExchangeProvider::Uniswap(meta));
            }
        }

        // PancakeSwap — EVM chains with a deployed Universal Router
        if addr_prefix == 1 && crate::models::exchange::pancakeswap::is_supported_chain(chain_id) {
            if let Some(meta) = PancakeMeta::for_chain(chain_id) {
                providers.insert(ExchangeProvider::PancakeSwap(meta));
            }
        }

        // ZIlSwap — Zilliqa chain
        if addr_prefix == 0 && slip_44 == ZILLIQA {
            providers.insert(ExchangeProvider::ZIlSwap(chain_id));
        }

        // SunSwap — TRON chain
        if addr_prefix == 4 && slip_44 == TRON {
            providers.insert(ExchangeProvider::SunSwap(chain_id));
        }

        providers
    };

    // Always not halted: DEX providers have no halt concept.
    let resolve_halted =
        |_providers: &HashSet<ExchangeProvider>, _slip_44: u32, _chain_id: u64| false;

    let mut assets: HashMap<(u64, usize), ExchangeAsset> = HashMap::with_capacity(total_tokens);

    // 1. Catalog: every token on every chain. Balances are filled in pass 2.
    for provider in all_providers {
        let chain = provider.config;
        let slip_44 = chain.slip_44;
        let chain_id = chain.chain_id();
        for token in chain.ftokens {
            let key = (token.chain_hash, token.addr.to_hash());
            let providers = make_providers(token.addr.prefix_type(), slip_44, chain_id);
            let halted = resolve_halted(&providers, slip_44, chain_id);
            assets.entry(key).or_insert_with(|| ExchangeAsset {
                token: token.into(),
                providers,
                halted,
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
                        continue;
                    };
                    let providers = make_providers(token.addr.prefix_type(), slip_44, chain_id);
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

    Ok(assets.into_values().collect())
}

/// Quote `asset → to` across every provider on `asset`.
pub async fn fetch_exchange_quote(
    asset: ExchangeAsset,
    to: ExchangeAsset,
    amount: String,
    destination: String,
) -> Result<Vec<ExchangeQuoteInfo>, String> {
    let from_asset = asset.token.addr.as_str();
    let to_asset = to.token.addr.as_str();
    dbg!(
        "fetch_exchange_quote: START",
        &asset.token.symbol,
        &asset.token.chain_hash,
        &asset.token.native,
        from_asset,
        to_asset,
        &amount,
        &destination,
        &asset.providers,
    );

    // Native ↔ wrapped-native is a 1:1 wrap/unwrap independent of any DEX. Detect it once with the
    // first resolvable provider (used only as a chain-context carrier) and emit a single quote,
    // instead of a duplicate per DEX.
    for provider in &asset.providers {
        let Some(Ok(cfg)) = provider.router_config() else {
            continue;
        };
        if is_wrap_unwrap(&cfg, from_asset, to_asset, asset.token.native).unwrap_or(false) {
            dbg!("fetch_exchange_quote: wrap/unwrap detected", provider);
            return Ok(vec![ExchangeQuoteInfo {
                provider: provider.clone(),
                amount_out: amount.clone(),
                permit_typed_data_json: None,
                is_wrap_unwrap: true,
            }]);
        }
        break;
    }

    let mut quotes = Vec::with_capacity(asset.providers.len());
    for provider in &asset.providers {
        dbg!("fetch_exchange_quote: trying provider", provider);
        // Universal-Router DEX providers (Uniswap, PancakeSwap) share one engine; everything
        // else (ZilSwap, SunSwap) is not yet implemented and resolves to `None`.
        let cfg = match provider.router_config() {
            Some(Ok(cfg)) => cfg,
            Some(Err(e)) => {
                dbg!("fetch_exchange_quote: resolve FAILED", provider, &e);
                continue;
            }
            None => {
                dbg!(
                    "fetch_exchange_quote: provider not yet implemented, skipping",
                    provider
                );
                continue;
            }
        };
        let result = router_quote_info(
            &cfg,
            provider,
            &asset,
            from_asset,
            to_asset,
            &amount,
            &destination,
        )
        .await;
        if let Err(e) = &result {
            dbg!("fetch_exchange_quote: provider FAILED", provider, e);
        }
        if let Ok(quote) = result {
            dbg!(
                "fetch_exchange_quote: provider OK",
                provider,
                &quote.amount_out
            );
            quotes.push(quote);
        }
    }
    // Sort by amount_out descending: best rate at index 0.
    quotes.sort_by(|a, b| {
        let a_val = U256::from_str(&a.amount_out).unwrap_or(U256::ZERO);
        let b_val = U256::from_str(&b.amount_out).unwrap_or(U256::ZERO);
        b_val.cmp(&a_val)
    });
    if quotes.is_empty() {
        dbg!("fetch_exchange_quote: NO provider returned a quote");
        Err("No provider returned a quote".into())
    } else {
        dbg!("fetch_exchange_quote: SUCCESS", quotes.len());
        Ok(quotes)
    }
}

/// Resolve `(proto signer for fee/nonce estimation, alloy swapper for the Universal Router, source
/// chain_hash)` from the active wallet/account. Synchronous and lock-free — it operates on an
/// already-cloned `core`, so it never re-acquires the service lock. The swap source chain is always
/// the wallet's active chain (the "pay" token lives there), which is also the chain that broadcasts.
fn resolve_swap_signer(
    core: &Arc<Background>,
    wallet_index: usize,
    account_index: usize,
) -> Result<(Address, AlloyAddress, u64), ServiceError> {
    let wallet = core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let account = data
        .get_account(account_index)
        .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))?;

    Ok((
        account.addr.clone(),
        account.addr.to_alloy_addr(),
        data.chain_hash,
    ))
}

/// Estimate fee history + the pending nonce once for `signer`, pre-set to the FAST tier. Reused to
/// fill fees on every tx in a swap (approve + swap) without re-simulating each — the sample tx is
/// only there to satisfy the batch RPC; its `estimateGas` result is ignored.
async fn estimate_fast_params(
    core: &Arc<Background>,
    chain_hash: u64,
    signer: &Address,
) -> Result<RequiredTxParams, ServiceError> {
    let chain = core
        .get_provider(chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let sample = TransactionRequest::Ethereum((
        ETHTransactionRequest::default(),
        TransactionMetadata {
            chain_hash,
            ..Default::default()
        },
    ));
    let mut params = chain
        .estimate_params_batch(&sample, signer, 4, None)
        .await
        .map_err(ServiceError::NetworkErrors)?;
    params.current = params.fast;

    Ok(params)
}

/// Swap gas-limit buffers as `(numerator, denominator)`: `1.15×` on a live node estimate, `1.4×`
/// on the built-in default-gas fallback. See [`apply_swap_gas_limit`].
const SWAP_ESTIMATE_BUFFER: (u64, u64) = (115, 100);
const SWAP_API_FALLBACK_BUFFER: (u64, u64) = (140, 100);

/// `gas × num / den`, saturating so it can never panic on overflow.
fn buffer_gas(gas: u64, (num, den): (u64, u64)) -> u64 {
    gas.saturating_mul(num) / den
}

/// The EVM gas limit currently on `tx` (if it's an Ethereum tx).
fn eth_gas(tx: &TransactionRequest) -> Option<u64> {
    match tx {
        TransactionRequest::Ethereum((eth, _)) => eth.gas,
        _ => None,
    }
}

/// Overwrite the EVM gas limit on `tx` in place (no-op for non-Ethereum txs).
fn set_eth_gas(tx: &mut TransactionRequest, gas: u64) {
    if let TransactionRequest::Ethereum((eth, _)) = tx {
        eth.gas = Some(gas);
    }
}

/// Set the swap tx's gas limit from a **live `eth_estimateGas`** against the node (×1.15) when the
/// tx can be simulated, else the conservative default gas already on the tx (×1.4). The fallback
/// covers a swap bundled behind an unmined approve — the allowance isn't on-chain yet, so the
/// simulation reverts (`Err`) — as well as transient RPC failures. The default (`DEFAULT_SWAP_GAS`)
/// is a fixed, generous limit, so the ×1.4 fallback gives it extra head-room. No-op for
/// non-EVM / gas-less txs.
async fn apply_swap_gas_limit(
    core: &Arc<Background>,
    chain_hash: u64,
    swap_tx: &mut TransactionRequest,
) {
    let Some(api_gas) = eth_gas(swap_tx) else {
        return;
    };

    let live = match core.get_provider(chain_hash) {
        Ok(chain) => chain
            .estimate_gas(swap_tx)
            .await
            .ok()
            .and_then(|gas| u64::try_from(gas).ok()),
        Err(_) => None,
    };

    let limit = match live {
        Some(est) => buffer_gas(est, SWAP_ESTIMATE_BUFFER),
        None => buffer_gas(api_gas, SWAP_API_FALLBACK_BUFFER),
    };
    set_eth_gas(swap_tx, limit);
}

/// Apply pre-estimated FAST fees + an explicit `nonce` to an EVM tx, **preserving the gas limit
/// already on the tx** (the swap leg sets it via [`apply_swap_gas_limit`]; the approve leg keeps
/// its `DEFAULT_APPROVE_GAS`) — never re-simulating here, which would revert before the approve is
/// mined. Nonces are caller-sequenced (`N`, `N+1`) so an approve + swap batch never collides.
fn apply_fast_fees(
    tx: &mut TransactionRequest,
    base: &RequiredTxParams,
    nonce: u64,
) -> Result<(), ServiceError> {
    let api_gas = eth_gas(tx);
    let mut params = base.clone();
    params.nonce = nonce;
    if let Some(g) = api_gas {
        params.tx_estimate_gas = U256::from(g);
    }
    update_tx_from_params(tx, params, U256::ZERO).map_err(ServiceError::TransactionErrors)?;

    Ok(())
}

/// **Software-wallet swap orchestrator.** Under a SINGLE unlock: optionally approve the ERC-20,
/// sign the Permit2 EIP-712, build the Universal Router swap calldata, and broadcast approve (`N`) + swap (`N+1`)
/// back-to-back (EVM nonce ordering guarantees the approve executes first). Returns the broadcast
/// histories. Progress streams as `approving`/`approved`/`permit`/`swapping`/`done`. Ledger wallets
/// use the step-by-step `check_exchange_approval` → `prepare_exchange_swap` → `finalize_exchange_swap`
/// path instead (a device cannot sign a batch).
#[allow(clippy::too_many_arguments)]
pub async fn execute_exchange_swap(
    wallet_index: usize,
    account_index: usize,
    provider: ExchangeProvider,
    from: ExchangeAsset,
    to: ExchangeAsset,
    amount_in: String,
    slippage_bps: u32,
    destination: String,
    display: ExchangeTxDisplay,
    password: Option<String>,
    passphrase: Option<String>,
    sink: StreamSink<String>,
) -> Result<Vec<HistoricalTransactionInfo>, String> {
    let _ = &destination;

    let token_in = from.token.addr.as_str();
    let token_out = to.token.addr.as_str();
    let is_native_in = from.token.native;

    let cfg = match provider.router_config() {
        Some(res) => res?,
        None => return Err("unsupported exchange provider".to_string()),
    };

    // A native ↔ wrapped-native wrap/unwrap is a single direct WETH tx — no approve, no permit.
    let wrap = is_wrap_unwrap(&cfg, token_in, token_out, is_native_in).unwrap_or(false);

    let core = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        Arc::clone(&service.core)
    };

    let seed = unlock_seed(&core, wallet_index, password).await?;
    let secret_passphrase = SecretString::new(passphrase.unwrap_or_default().into());
    let (signer, swapper, chain_hash) = resolve_swap_signer(&core, wallet_index, account_index)?;

    let base = estimate_fast_params(&core, chain_hash, &signer).await?;
    let mut nonce = base.nonce;
    let mut results: Vec<HistoricalTransactionInfo> = Vec::with_capacity(2);

    // One-time ERC-20 approval (to the Permit2 contract). Native inputs and wraps never need it.
    if !is_native_in && !wrap {
        if let Some(approval) = router_check_approval(
            &cfg,
            swapper,
            chain_hash,
            token_in,
            &amount_in,
            display.approve_title.clone(),
            display.provider_icon.clone(),
        )
        .await?
        {
            let _ = sink.add("approving".to_string());
            let mut approve_tx: TransactionRequest = approval
                .try_into()
                .map_err(ServiceError::TransactionErrors)?;
            apply_fast_fees(&mut approve_tx, &base, nonce)?;
            let hist = sign_and_broadcast_one(
                &core,
                wallet_index,
                account_index,
                &seed,
                &secret_passphrase,
                approve_tx,
            )
            .await?;
            results.push(hist);
            nonce += 1;
            let _ = sink.add("approved".to_string());
        }
    }

    let prepared = prepare_router_swap(
        &cfg,
        swapper,
        chain_hash,
        token_in,
        token_out,
        &amount_in,
        slippage_bps,
        is_native_in,
    )
    .await?;
    let permit_signature: Option<String> = match prepared.permit_typed_data_json {
        Some(typed_data) => {
            let _ = sink.add("permit".to_string());
            let (_pubkey, sig) = core
                .sign_typed_data_eip712(
                    wallet_index,
                    account_index,
                    &seed,
                    &secret_passphrase,
                    &typed_data,
                    Some(display.permit_title.clone()),
                    Some(display.provider_icon.clone()),
                )
                .await
                .map_err(ServiceError::BackgroundError)?;
            Some(sig.to_hex_prefixed())
        }
        None => None,
    };

    let mut swap_tx: TransactionRequest = finalize_router_swap(
        &prepared.quote_blob,
        swapper,
        chain_hash,
        permit_signature.as_deref(),
        display.swap_title,
        display.swap_info,
        display.provider_icon,
        display.out_token,
    )
    .await?
    .try_into()
    .map_err(ServiceError::TransactionErrors)?;
    apply_swap_gas_limit(&core, chain_hash, &mut swap_tx).await;
    apply_fast_fees(&mut swap_tx, &base, nonce)?;

    let _ = sink.add("swapping".to_string());
    let swap_hist = sign_and_broadcast_one(
        &core,
        wallet_index,
        account_index,
        &seed,
        &secret_passphrase,
        swap_tx,
    )
    .await?;
    results.push(swap_hist);
    let _ = sink.add("done".to_string());

    Ok(results)
}

/// Check whether the chosen provider needs a one-time on-chain ERC-20 `approve` before the swap,
/// and if so return the unsigned approval tx — with FAST fees + the given `nonce` already applied —
/// for a **Ledger** device to sign and broadcast first. Native inputs never need approval
/// (`Ok(None)`). Software wallets don't call this; `execute_exchange_swap` handles approval inline.
#[allow(clippy::too_many_arguments)]
pub async fn check_exchange_approval(
    wallet_index: usize,
    account_index: usize,
    provider: ExchangeProvider,
    token_in: String,
    amount_in: String,
    is_native_in: bool,
    nonce: u64,
    approve_title: String,
    provider_icon: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    if is_native_in {
        return Ok(None);
    }

    let core = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        Arc::clone(&service.core)
    };

    let (signer, swapper, chain_hash) = resolve_swap_signer(&core, wallet_index, account_index)?;
    let cfg = match provider.router_config() {
        Some(res) => res?,
        None => return Ok(None),
    };
    let approval = router_check_approval(
        &cfg,
        swapper,
        chain_hash,
        &token_in,
        &amount_in,
        approve_title,
        provider_icon,
    )
    .await?;

    match approval {
        Some(info) => {
            let mut tx: TransactionRequest =
                info.try_into().map_err(ServiceError::TransactionErrors)?;
            let base = estimate_fast_params(&core, chain_hash, &signer).await?;
            apply_fast_fees(&mut tx, &base, nonce)?;
            Ok(Some(tx.into()))
        }
        None => Ok(None),
    }
}

/// **Ledger step.** Re-quote and surface the Permit2 typed data to sign on-device, plus the opaque
/// quote blob to feed back into [`finalize_exchange_swap`]. Native inputs / routings without a
/// Permit2 authorization return `permit_typed_data_json: None`.
pub struct PreparedSwapInfo {
    pub permit_typed_data_json: Option<String>,
    pub quote_blob: String,
}

#[allow(clippy::too_many_arguments)]
pub async fn prepare_exchange_swap(
    wallet_index: usize,
    account_index: usize,
    provider: ExchangeProvider,
    from: ExchangeAsset,
    to: ExchangeAsset,
    amount_in: String,
    slippage_bps: u32,
    destination: String,
) -> Result<PreparedSwapInfo, String> {
    let _ = &destination;

    let token_in = from.token.addr.as_str();
    let token_out = to.token.addr.as_str();
    let is_native_in = from.token.native;

    let cfg = match provider.router_config() {
        Some(res) => res?,
        None => return Err("unsupported exchange provider".to_string()),
    };

    let core = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        Arc::clone(&service.core)
    };

    let (_signer, swapper, chain_hash) = resolve_swap_signer(&core, wallet_index, account_index)?;
    let prepared = prepare_router_swap(
        &cfg,
        swapper,
        chain_hash,
        token_in,
        token_out,
        &amount_in,
        slippage_bps,
        is_native_in,
    )
    .await?;

    Ok(PreparedSwapInfo {
        permit_typed_data_json: prepared.permit_typed_data_json,
        quote_blob: prepared.quote_blob,
    })
}

/// **Ledger final step.** Attach the device-signed permit signature, build the Universal Router swap
/// calldata, and return the swap tx with FAST fees + the given `nonce` already applied — ready for the device to sign and
/// the UI to broadcast via `send_signed_transactions`.
#[allow(clippy::too_many_arguments)]
pub async fn finalize_exchange_swap(
    wallet_index: usize,
    account_index: usize,
    provider: ExchangeProvider,
    quote_blob: String,
    permit_signature: Option<String>,
    nonce: u64,
    swap_title: String,
    swap_info: String,
    provider_icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let _ = &provider;

    let core = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        Arc::clone(&service.core)
    };

    let (signer, swapper, chain_hash) = resolve_swap_signer(&core, wallet_index, account_index)?;
    let built = finalize_router_swap(
        &quote_blob,
        swapper,
        chain_hash,
        permit_signature.as_deref(),
        swap_title,
        swap_info,
        provider_icon,
        out_token,
    )
    .await?;
    let mut swap_tx: TransactionRequest =
        built.try_into().map_err(ServiceError::TransactionErrors)?;
    apply_swap_gas_limit(&core, chain_hash, &mut swap_tx).await;
    let base = estimate_fast_params(&core, chain_hash, &signer).await?;
    apply_fast_fees(&mut swap_tx, &base, nonce)?;

    Ok(swap_tx.into())
}

/// Base pending nonce for the active account on its chain. The Ledger modal pins it once and passes
/// `N` (approve) / `N+1` (swap) explicitly, since `eth_getTransactionCount(latest)` won't reflect a
/// just-broadcast approve between device prompts.
pub async fn estimate_swap_base_nonce(
    wallet_index: usize,
    account_index: usize,
) -> Result<u64, String> {
    let core = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        Arc::clone(&service.core)
    };

    let (signer, _swapper, chain_hash) = resolve_swap_signer(&core, wallet_index, account_index)?;
    let base = estimate_fast_params(&core, chain_hash, &signer).await?;

    Ok(base.nonce)
}

#[cfg(test)]
mod swap_gas_tests {
    use super::*;
    use zilpay::network::evm::GasFeeHistory;

    // base_fee = 0 keeps `update_tx_from_params` on the legacy branch, so the test needs no RPC.
    fn base_params() -> RequiredTxParams {
        RequiredTxParams {
            gas_price: U256::from(1_000_000_000u64),
            max_priority_fee: U256::ZERO,
            fee_history: GasFeeHistory::default(),
            tx_estimate_gas: U256::ZERO,
            blob_base_fee: U256::ZERO,
            nonce: 0,
            slow: U256::from(1_000_000_000u64),
            market: U256::from(1_500_000_000u64),
            fast: U256::from(2_000_000_000u64),
            current: U256::from(2_000_000_000u64),
        }
    }

    fn eth_tx(gas: u64) -> TransactionRequest {
        TransactionRequest::Ethereum((
            ETHTransactionRequest {
                gas: Some(gas),
                ..Default::default()
            },
            TransactionMetadata::default(),
        ))
    }

    /// The two legs of a swap share one estimate but must get sequential nonces (`N`, `N+1`), and
    /// the gas limit already on the tx must survive — never replaced by a zero re-estimate.
    #[test]
    fn apply_fast_fees_sequences_nonce_and_preserves_api_gas_limit() {
        let base = base_params();

        let mut approve = eth_tx(60_000);
        apply_fast_fees(&mut approve, &base, 5).unwrap();

        let mut swap = eth_tx(321_542);
        apply_fast_fees(&mut swap, &base, 6).unwrap();

        let TransactionRequest::Ethereum((approve_eth, _)) = approve else {
            panic!("expected ethereum tx");
        };
        let TransactionRequest::Ethereum((swap_eth, _)) = swap else {
            panic!("expected ethereum tx");
        };

        assert_eq!(approve_eth.nonce, Some(5));
        assert_eq!(approve_eth.gas, Some(60_000));
        assert_eq!(swap_eth.nonce, Some(6));
        assert_eq!(swap_eth.gas, Some(321_542));
    }

    /// The two swap gas-limit buffers, plus the saturating guard against overflow panics.
    #[test]
    fn buffer_gas_applies_ratio_and_saturates() {
        // live estimate ×1.15, default-gas fallback ×1.4 (integer division truncates).
        assert_eq!(buffer_gas(182_000, SWAP_ESTIMATE_BUFFER), 209_300);
        assert_eq!(buffer_gas(179_917, SWAP_API_FALLBACK_BUFFER), 251_883);
        // saturating_mul keeps it panic-free at the u64 ceiling.
        assert_eq!(buffer_gas(u64::MAX, (115, 100)), u64::MAX / 100);
    }
}
