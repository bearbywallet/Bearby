use std::collections::{HashMap, HashSet};
use std::sync::Arc;

use zilpay::background::Background;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_tx::{TransactionsManagement, update_tx_from_params};
use zilpay::background::bg_wallet::WalletManagement;
use zilpay::crypto::slip44::{TRON, ZILLIQA};
use zilpay::network::evm::RequiredTxParams;
use zilpay::proto::U256;
use zilpay::proto::address::Address;
use zilpay::proto::tx::{ETHTransactionRequest, TransactionMetadata, TransactionRequest};
use zilpay::secrecy::SecretString;
use zilpay::wallet::wallet_storage::StorageOperations;

use crate::api::transaction::{sign_and_broadcast_one, unlock_seed};
use crate::frb_generated::StreamSink;
use crate::models::exchange::{
    ExchangeAsset, ExchangeProvider, ExchangeTxDisplay, PancakeMeta, ProviderQuote, RelayMeta,
    SunSwapMeta, SwapAuth, SwapParams, UniswapMeta, ZilSwapMeta,
};
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;

/// Bootstrap all exchange providers across every registered chain.
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
                          chain_id: u64,
                          chain_hash: u64|
     -> HashSet<ExchangeProvider> {
        let account_addr = relay_accounts.get(&slip_44);
        let mut providers = HashSet::with_capacity(5);

        if let Some(account_addr) = account_addr {
            // Uniswap — EVM chains with a deployed Universal Router.
            if addr_prefix == 1 && crate::models::exchange::uniswap::is_supported_chain(chain_id) {
                if let Some(meta) = UniswapMeta::for_chain(chain_hash, chain_id, slip_44, account_addr) {
                    providers.insert(ExchangeProvider::Uniswap(meta));
                }
            }

            // PancakeSwap — EVM chains with a deployed Universal Router.
            if addr_prefix == 1 && crate::models::exchange::pancakeswap::is_supported_chain(chain_id) {
                if let Some(meta) = PancakeMeta::for_chain(chain_hash, chain_id, slip_44, account_addr) {
                    providers.insert(ExchangeProvider::PancakeSwap(meta));
                }
            }

            // Relay — intent bridge. EVM chains use their EIP-155 ids; Solana/Bitcoin map to Relay ids.
            if let Some(meta) = RelayMeta::for_chain(chain_hash, slip_44, chain_id, account_addr) {
                providers.insert(ExchangeProvider::Relay(meta));
            }

            // ZilSwap — Zilliqa chain.
            if addr_prefix == 0 && slip_44 == ZILLIQA {
                providers.insert(ExchangeProvider::ZilSwap(ZilSwapMeta::for_chain(
                    chain_hash,
                    chain_id,
                    slip_44,
                    account_addr,
                )));
            }

            // SunSwap — TRON chain.
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
            let providers = make_providers(
                token.addr.prefix_type(),
                slip_44,
                chain_id,
                token.chain_hash,
            );
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
                    let providers = make_providers(
                        token.addr.prefix_type(),
                        slip_44,
                        chain_id,
                        token.chain_hash,
                    );
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

/// Parallel quote refresh for all providers on `from`.
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
        .find(|provider| provider.is_wrap_unwrap(&from, &to, from_addr, to_addr).unwrap_or(false))
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

/// Resolve `(proto signer for fee/nonce estimation, source chain_hash)` from the active
/// wallet/account. Synchronous and lock-free — it operates on an already-cloned `core`, so it never
/// re-acquires the service lock. Used when no provider-scoped chain context is available.
fn resolve_swap_signer(
    core: &Arc<Background>,
    wallet_index: usize,
    account_index: usize,
) -> Result<(Address, u64), ServiceError> {
    let wallet = core
        .get_wallet_by_index(wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
    let account = data
        .get_account(account_index)
        .map_err(|e| ServiceError::AccountError(account_index, wallet_index, e))?;

    Ok((account.addr.clone(), data.chain_hash))
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
pub async fn execute_exchange_swap(
    auth: SwapAuth,
    params: SwapParams,
    display: ExchangeTxDisplay,
    sink: StreamSink<String>,
) -> Result<Vec<HistoricalTransactionInfo>, String> {
    let SwapParams {
        provider,
        from,
        to,
        amount_in,
        slippage_bps,
    } = params;
    let is_native_in = from.token.native;
    let wrap = provider
        .is_wrap_unwrap(&from, &to, from.token.addr.as_str(), to.token.addr.as_str())
        .unwrap_or(false);

    let core = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        Arc::clone(&service.core)
    };

    let seed = unlock_seed(&core, auth.wallet_index, auth.password).await?;
    let secret_passphrase = SecretString::new(auth.passphrase.unwrap_or_default().into());
    let common = provider.common();
    let chain_hash = common.chain_hash;
    let provider_icon = common.icon_asset.clone();
    let (signer, _active_chain_hash) =
        resolve_swap_signer(&core, auth.wallet_index, auth.account_index)?;

    let base = estimate_fast_params(&core, chain_hash, &signer).await?;
    let mut nonce = base.nonce;
    let mut results: Vec<HistoricalTransactionInfo> = Vec::with_capacity(2);

    // One-time ERC-20 approval. Native inputs and wraps never need it.
    if !is_native_in && !wrap {
        if let Some(approval) = provider
            .check_approval(&from, &to, &amount_in, display.approve_title.clone())
            .await?
        {
            let _ = sink.add("approving".to_string());
            let mut approve_tx: TransactionRequest = approval
                .try_into()
                .map_err(ServiceError::TransactionErrors)?;
            apply_fast_fees(&mut approve_tx, &base, nonce)?;
            let hist = sign_and_broadcast_one(
                &core,
                auth.wallet_index,
                auth.account_index,
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

    let prepared = provider
        .prepare_swap(&from, &to, &amount_in, slippage_bps)
        .await?;
    let permit_signature: Option<String> = match prepared.permit_typed_data_json {
        Some(typed_data) => {
            let _ = sink.add("permit".to_string());
            let (_pubkey, sig) = core
                .sign_typed_data_eip712(
                    auth.wallet_index,
                    auth.account_index,
                    &seed,
                    &secret_passphrase,
                    &typed_data,
                    Some(display.permit_title.clone()),
                    Some(provider_icon.clone()),
                )
                .await
                .map_err(ServiceError::BackgroundError)?;
            Some(sig.to_hex_prefixed())
        }
        None => None,
    };

    let mut swap_tx: TransactionRequest = provider
        .finalize_swap(
            &prepared.quote_blob,
            permit_signature.as_deref(),
            display.swap_title,
            display.swap_info,
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
        auth.wallet_index,
        auth.account_index,
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
pub async fn check_exchange_approval(
    auth: SwapAuth,
    params: SwapParams,
    nonce: u64,
    approve_title: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    if params.from.token.native {
        return Ok(None);
    }

    let core = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        Arc::clone(&service.core)
    };

    let (signer, _active_chain_hash) =
        resolve_swap_signer(&core, auth.wallet_index, auth.account_index)?;
    let chain_hash = params.provider.common().chain_hash;
    let approval = params
        .provider
        .check_approval(&params.from, &params.to, &params.amount_in, approve_title)
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

pub async fn prepare_exchange_swap(params: SwapParams) -> Result<PreparedSwapInfo, String> {
    let prepared = params
        .provider
        .prepare_swap(&params.from, &params.to, &params.amount_in, params.slippage_bps)
        .await?;

    Ok(PreparedSwapInfo {
        permit_typed_data_json: prepared.permit_typed_data_json,
        quote_blob: prepared.quote_blob,
    })
}

/// **Ledger final step.** Attach the device-signed permit signature, build the Universal Router swap
/// calldata, and return the swap tx with FAST fees + the given `nonce` already applied — ready for the device to sign and
/// the UI to broadcast via `send_signed_transactions`.
pub async fn finalize_exchange_swap(
    auth: SwapAuth,
    provider: ExchangeProvider,
    quote_blob: String,
    permit_signature: Option<String>,
    nonce: u64,
    display: ExchangeTxDisplay,
) -> Result<TransactionRequestInfo, String> {
    let core = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        Arc::clone(&service.core)
    };

    let (signer, _active_chain_hash) =
        resolve_swap_signer(&core, auth.wallet_index, auth.account_index)?;
    let chain_hash = provider.common().chain_hash;
    let built = provider
        .finalize_swap(
            &quote_blob,
            permit_signature.as_deref(),
            display.swap_title,
            display.swap_info,
            display.out_token,
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

    let (signer, chain_hash) = resolve_swap_signer(&core, wallet_index, account_index)?;
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
