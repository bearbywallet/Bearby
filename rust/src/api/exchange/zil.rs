use std::sync::Arc;

use flutter_rust_bridge::frb;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_tx::update_tx_from_params;
use zilpay::network::evm::RequiredTxParams;
use zilpay::proto::tx::{TransactionMetadata, TransactionRequest};
use zilpay::proto::zil_tx::ZILTransactionRequest;
use zilpay::proto::U256;
use zilpay::secrecy::SecretString;

use crate::api::transaction::{sign_and_broadcast_one, unlock_seed};
use crate::frb_generated::StreamSink;
use crate::models::exchange::zilswap::SWAP_GAS;
use crate::models::exchange::{ExchangeTxDisplay, SwapAuth, SwapParams};
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::utils::{errors::ServiceError, helpers::handle};

use super::evm::resolve_swap_signer;

#[frb(ignore)]
pub(super) async fn estimate_zil_params(
    core: &Arc<zilpay::background::Background>,
    chain_hash: u64,
    signer: &zilpay::proto::address::Address,
) -> Result<RequiredTxParams, ServiceError> {
    let chain = core
        .get_provider(chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let sample = TransactionRequest::Zilliqa((
        ZILTransactionRequest {
            chain_id: 0,
            nonce: 0,
            gas_price: 0,
            gas_limit: SWAP_GAS,
            to_addr: signer.clone(),
            amount: 0,
            code: Vec::with_capacity(0),
            data: Vec::with_capacity(0),
        },
        TransactionMetadata {
            chain_hash,
            ..Default::default()
        },
    ));
    chain
        .estimate_params_batch(&sample, signer, 4, None)
        .await
        .map_err(ServiceError::NetworkErrors)
}

#[frb(ignore)]
pub(super) fn apply_zil_params(
    tx: &mut TransactionRequest,
    base: &RequiredTxParams,
    nonce: u64,
) -> Result<(), ServiceError> {
    let mut params = base.clone();
    // Zilliqa tx nonces are one-based in `update_tx_from_params`, so pass the
    // last observed/used nonce here; the helper writes `nonce + 1` into the tx.
    params.nonce = nonce;
    // Pass U256::MAX so the max-send branch (balance == amount) never fires for
    // DEX swaps — ZilSwap fees are gas, not amount-derived. With ZERO balance,
    // the branch would trigger for amount==0 (Token→ZIL/approval) and panic.
    update_tx_from_params(tx, params, U256::MAX).map_err(ServiceError::TransactionErrors)
}

#[frb(ignore)]
pub(super) async fn execute_zil_exchange_swap(
    auth: SwapAuth,
    params: SwapParams,
    display: ExchangeTxDisplay,
    sink: &StreamSink<String>,
) -> Result<Vec<HistoricalTransactionInfo>, String> {
    let SwapParams {
        provider,
        from,
        to,
        amount_in,
        slippage_bps,
    } = params;
    let ExchangeTxDisplay {
        approve_title,
        swap_title,
        swap_info,
        out_token,
        ..
    } = display;

    let core = handle()?;

    let seed = unlock_seed(&core, auth.wallet_index, auth.password).await?;
    let secret_passphrase = SecretString::new(auth.passphrase.unwrap_or_default().into());
    let common = provider.common();
    let chain_hash = common.chain_hash;
    let (signer, _) = resolve_swap_signer(&core, auth.wallet_index, auth.account_index)?;
    let base = estimate_zil_params(&core, chain_hash, &signer).await?;
    let mut nonce = base.nonce;
    let mut results = Vec::with_capacity(2);

    if !from.token.native {
        if let Some(approval) = provider
            .check_approval(&from, &to, &amount_in, approve_title)
            .await?
        {
            let _ = sink.add("approving".to_string());
            let mut approve_tx: TransactionRequest = approval
                .try_into()
                .map_err(ServiceError::TransactionErrors)?;
            apply_zil_params(&mut approve_tx, &base, nonce)?;
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
            nonce = nonce.saturating_add(1);
            let _ = sink.add("approved".to_string());
        }
    }

    let prepared = provider
        .prepare_swap(&from, &to, &amount_in, slippage_bps)
        .await?;
    let mut swap_tx: TransactionRequest = provider
        .finalize_swap(&prepared.quote_blob, None, swap_title, swap_info, out_token)
        .await?
        .try_into()
        .map_err(ServiceError::TransactionErrors)?;
    apply_zil_params(&mut swap_tx, &base, nonce)?;

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
