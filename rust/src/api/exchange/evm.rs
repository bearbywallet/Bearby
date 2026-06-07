use std::sync::Arc;

use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_tx::{update_tx_from_params, TransactionsManagement};
use zilpay::background::bg_wallet::WalletManagement;
use zilpay::background::Background;
use zilpay::network::evm::RequiredTxParams;
use zilpay::proto::address::Address;
use zilpay::proto::tx::{ETHTransactionRequest, TransactionMetadata, TransactionRequest};
use zilpay::proto::U256;
use zilpay::secrecy::SecretString;
use zilpay::wallet::wallet_storage::StorageOperations;

use crate::api::transaction::{sign_and_broadcast_one, unlock_seed};
use crate::frb_generated::StreamSink;
use crate::models::exchange::{ExchangeTxDisplay, SwapAuth, SwapParams};
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;

const SWAP_ESTIMATE_BUFFER: (u64, u64) = (115, 100);
const SWAP_API_FALLBACK_BUFFER: (u64, u64) = (140, 100);

fn buffer_gas(gas: u64, (num, den): (u64, u64)) -> u64 {
    gas.saturating_mul(num) / den
}

fn eth_gas(tx: &TransactionRequest) -> Option<u64> {
    match tx {
        TransactionRequest::Ethereum((eth, _)) => eth.gas,
        _ => None,
    }
}

fn set_eth_gas(tx: &mut TransactionRequest, gas: u64) {
    if let TransactionRequest::Ethereum((eth, _)) = tx {
        eth.gas = Some(gas);
    }
}

pub(super) fn resolve_swap_signer(
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

pub(super) async fn estimate_fast_params(
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

pub(super) async fn apply_swap_gas_limit(
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

pub(super) fn apply_fast_fees(
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

pub(super) async fn execute_evm_exchange_swap(
    auth: SwapAuth,
    params: SwapParams,
    display: ExchangeTxDisplay,
    sink: StreamSink<String>,
) -> Result<Vec<HistoricalTransactionInfo>, String> {
    let SwapParams { provider, from, to, amount_in, slippage_bps } = params;
    let ExchangeTxDisplay { approve_title, permit_title, swap_title, swap_info, out_token } =
        display;

    let is_native_in = from.token.native;
    let wrap = provider
        .is_wrap_unwrap(&from, &to, from.token.addr.as_str(), to.token.addr.as_str())
        .unwrap_or(false);

    let core = Arc::clone(
        &BACKGROUND_SERVICE
            .read()
            .await
            .as_ref()
            .ok_or(ServiceError::NotRunning)?
            .core,
    );

    let seed = unlock_seed(&core, auth.wallet_index, auth.password).await?;
    let secret_passphrase = SecretString::new(auth.passphrase.unwrap_or_default().into());
    let common = provider.common();
    let chain_hash = common.chain_hash;
    let (signer, _) = resolve_swap_signer(&core, auth.wallet_index, auth.account_index)?;

    let base = estimate_fast_params(&core, chain_hash, &signer).await?;
    let mut nonce = base.nonce;
    let mut results: Vec<HistoricalTransactionInfo> = Vec::with_capacity(2);

    if !is_native_in && !wrap {
        if let Some(approval) = provider
            .check_approval(&from, &to, &amount_in, approve_title)
            .await?
        {
            let _ = sink.add("approving".to_string());
            let mut approve_tx: TransactionRequest =
                approval.try_into().map_err(ServiceError::TransactionErrors)?;
            apply_fast_fees(&mut approve_tx, &base, nonce)?;
            results.push(
                sign_and_broadcast_one(
                    &core,
                    auth.wallet_index,
                    auth.account_index,
                    &seed,
                    &secret_passphrase,
                    approve_tx,
                )
                .await?,
            );
            nonce += 1;
            let _ = sink.add("approved".to_string());
        }
    }

    let prepared = provider.prepare_swap(&from, &to, &amount_in, slippage_bps).await?;

    let permit_signature = if let Some(typed_data) = prepared.permit_typed_data_json {
        let _ = sink.add("permit".to_string());
        let (_, sig) = core
            .sign_typed_data_eip712(
                auth.wallet_index,
                auth.account_index,
                &seed,
                &secret_passphrase,
                &typed_data,
                Some(permit_title),
                Some(common.icon_asset.clone()),
            )
            .await
            .map_err(ServiceError::BackgroundError)?;
        Some(sig.to_hex_prefixed())
    } else {
        None
    };

    let mut swap_tx: TransactionRequest = provider
        .finalize_swap(
            &prepared.quote_blob,
            permit_signature.as_deref(),
            swap_title,
            swap_info,
            out_token,
        )
        .await?
        .try_into()
        .map_err(ServiceError::TransactionErrors)?;
    apply_swap_gas_limit(&core, chain_hash, &mut swap_tx).await;
    apply_fast_fees(&mut swap_tx, &base, nonce)?;

    let _ = sink.add("swapping".to_string());
    results.push(
        sign_and_broadcast_one(
            &core,
            auth.wallet_index,
            auth.account_index,
            &seed,
            &secret_passphrase,
            swap_tx,
        )
        .await?,
    );
    let _ = sink.add("done".to_string());

    Ok(results)
}

#[cfg(test)]
mod tests {
    use super::*;
    use zilpay::network::evm::GasFeeHistory;

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

    #[test]
    fn buffer_gas_applies_ratio_and_saturates() {
        assert_eq!(buffer_gas(182_000, SWAP_ESTIMATE_BUFFER), 209_300);
        assert_eq!(buffer_gas(179_917, SWAP_API_FALLBACK_BUFFER), 251_883);
        assert_eq!(buffer_gas(u64::MAX, (115, 100)), u64::MAX / 100);
    }
}
