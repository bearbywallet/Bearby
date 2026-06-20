use zilpay::secrecy::SecretString;

use crate::api::transaction::{sign_and_broadcast_one, unlock_seed};
use crate::frb_generated::StreamSink;
use crate::models::exchange::{ExchangeTxDisplay, SwapAuth, SwapParams};
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::utils::{errors::ServiceError, helpers::handle};

pub(super) async fn execute_svm_exchange_swap(
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

    let core = handle()?;

    let seed = unlock_seed(&core, auth.wallet_index, auth.password).await?;
    let secret_passphrase = SecretString::new(auth.passphrase.unwrap_or_default().into());

    let prepared = provider
        .prepare_swap(&from, &to, &amount_in, slippage_bps)
        .await?;

    let swap_tx = provider
        .finalize_swap(
            &prepared.quote_blob,
            None,
            display.swap_title,
            display.swap_info,
            display.out_token,
        )
        .await?
        .try_into()
        .map_err(ServiceError::TransactionErrors)?;

    let _ = sink.add("swapping".to_string());

    let hist = sign_and_broadcast_one(
        &core,
        auth.wallet_index,
        auth.account_index,
        &seed,
        &secret_passphrase,
        swap_tx,
    )
    .await?;

    let _ = sink.add("done".to_string());

    Ok(vec![hist])
}
