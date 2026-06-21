use zilpay::proto::tx::TransactionRequest;

use crate::models::exchange::relay::RelayOrigin;
use crate::models::exchange::{ExchangeProvider, ExchangeTxDisplay, SwapAuth, SwapParams};
use crate::models::transactions::request::TransactionRequestInfo;
use crate::utils::{errors::ServiceError, helpers::handle};

use super::evm::{
    apply_fast_fees, apply_swap_gas_limit, estimate_fast_params, resolve_swap_signer,
};
use super::zil::{apply_zil_params, estimate_zil_params};

pub struct PreparedSwapInfo {
    pub permit_typed_data_json: Option<String>,
    pub quote_blob: String,
}

fn is_relay_tron_origin(provider: &ExchangeProvider, params: &SwapParams) -> bool {
    provider.is_relay()
        && matches!(
            RelayOrigin::from_addr_type(params.from.token.addr_type),
            Some(RelayOrigin::Tron)
        )
}

pub async fn check_exchange_approval(
    auth: SwapAuth,
    params: SwapParams,
    nonce: u64,
    approve_title: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    if params.from.token.native {
        return Ok(None);
    }

    let core = handle()?;

    let (signer, _) = resolve_swap_signer(&core, auth.wallet_index, auth.account_index)?;
    let chain_hash = params.provider.common().chain_hash;
    let approval = params
        .provider
        .check_approval(&params.from, &params.to, &params.amount_in, approve_title)
        .await?;

    match approval {
        Some(info) if is_relay_tron_origin(&params.provider, &params) => Ok(Some(info)),
        Some(info) => {
            let is_scilla = info.scilla.is_some();
            let mut tx: TransactionRequest =
                info.try_into().map_err(ServiceError::TransactionErrors)?;
            if is_scilla {
                let base = estimate_zil_params(&core, chain_hash, &signer).await?;
                apply_zil_params(&mut tx, &base, nonce)?;
                return Ok(Some(
                    tx.try_into().map_err(ServiceError::TransactionErrors)?,
                ));
            }
            let base = estimate_fast_params(&core, chain_hash, &signer).await?;
            apply_fast_fees(&mut tx, &base, nonce)?;
            Ok(Some(
                tx.try_into().map_err(ServiceError::TransactionErrors)?,
            ))
        }
        None => Ok(None),
    }
}

pub async fn prepare_exchange_swap(params: SwapParams) -> Result<PreparedSwapInfo, String> {
    let prepared = params
        .provider
        .prepare_swap(
            &params.from,
            &params.to,
            &params.amount_in,
            params.slippage_bps,
        )
        .await?;

    Ok(PreparedSwapInfo {
        permit_typed_data_json: prepared.permit_typed_data_json,
        quote_blob: prepared.quote_blob,
    })
}

pub async fn finalize_exchange_swap(
    auth: SwapAuth,
    provider: ExchangeProvider,
    quote_blob: String,
    permit_signature: Option<String>,
    nonce: u64,
    display: ExchangeTxDisplay,
) -> Result<TransactionRequestInfo, String> {
    let core = handle()?;

    let (signer, _) = resolve_swap_signer(&core, auth.wallet_index, auth.account_index)?;
    let chain_hash = provider.common().chain_hash;
    let finalized = provider
        .finalize_swap(
            &quote_blob,
            permit_signature.as_deref(),
            display.swap_title,
            display.swap_info,
            display.out_token,
        )
        .await?;
    if provider.is_relay() && finalized.tron.is_some() {
        return Ok(finalized);
    }

    let is_scilla = finalized.scilla.is_some();
    let mut swap_tx: TransactionRequest = finalized
        .try_into()
        .map_err(ServiceError::TransactionErrors)?;
    if is_scilla {
        let base = estimate_zil_params(&core, chain_hash, &signer).await?;
        apply_zil_params(&mut swap_tx, &base, nonce)?;
        return Ok(swap_tx
            .try_into()
            .map_err(ServiceError::TransactionErrors)?);
    }
    apply_swap_gas_limit(&core, chain_hash, &mut swap_tx).await;
    let base = estimate_fast_params(&core, chain_hash, &signer).await?;
    apply_fast_fees(&mut swap_tx, &base, nonce)?;

    Ok(swap_tx
        .try_into()
        .map_err(ServiceError::TransactionErrors)?)
}

pub async fn estimate_swap_base_nonce(
    wallet_index: usize,
    account_index: usize,
) -> Result<u64, String> {
    let core = handle()?;

    let (signer, chain_hash) = resolve_swap_signer(&core, wallet_index, account_index)?;
    let base = match signer {
        zilpay::proto::address::Address::Secp256k1Sha256(_) => {
            estimate_zil_params(&core, chain_hash, &signer).await?
        }
        _ => estimate_fast_params(&core, chain_hash, &signer).await?,
    };

    Ok(base.nonce)
}
