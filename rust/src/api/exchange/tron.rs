use flutter_rust_bridge::frb;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::network::tron::TronOperations;
use zilpay::proto::address::Address;
use zilpay::proto::tron_tx::TronTransaction;
use zilpay::proto::tx::{TransactionMetadata, TransactionRequest};
use zilpay::secrecy::SecretString;

use crate::api::transaction::{sign_and_broadcast_one, unlock_seed};
use crate::frb_generated::StreamSink;
use crate::models::exchange::relay::RelayDisplay;
use crate::models::exchange::{ExchangeTxDisplay, SwapAuth, SwapParams};
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::models::transactions::transaction_metadata::TransactionMetadataInfo;
use crate::models::transactions::tron::TransactionRequestTron;
use crate::utils::{errors::ServiceError, helpers::handle};

/// Parse a TRON address from either base58 ("T...") or Relay's 21-byte hex format ("41...").
/// Relay encodes contract addresses as 21-byte hex with the 0x41 TRON version-byte prefix.
fn tron_addr(s: &str) -> Result<Address, String> {
    if s.len() == 42 && s.starts_with("41") {
        let bytes =
            zilpay::alloy::hex::decode(s).map_err(|e| format!("invalid TRON address hex: {e}"))?;
        return Address::from_tron_bytes(&bytes).map_err(|e| e.to_string());
    }
    Address::from_str_hex(s).map_err(|e| e.to_string())
}

fn parse_tron_call_value(value: &str) -> Result<i64, String> {
    if value.is_empty() {
        Ok(0)
    } else {
        value
            .parse::<i64>()
            .map_err(|e| format!("bad Tron call value: {e}"))
    }
}

fn u256_to_i64_fee(value: zilpay::proto::U256) -> Result<i64, String> {
    value
        .to_string()
        .parse::<i64>()
        .map_err(|e| format!("bad Tron fee estimate: {e}"))
}

#[frb(ignore)]
pub async fn finalize_tron_relay(
    account_addr: &str,
    chain_hash: u64,
    to: &str,
    data_hex: &str,
    value_str: &str,
    display: RelayDisplay,
) -> Result<TransactionRequestInfo, String> {
    let owner = Address::from_str_hex(account_addr).map_err(|e| e.to_string())?;
    let router = tron_addr(to)?;
    let data = zilpay::alloy::hex::decode(data_hex.strip_prefix("0x").unwrap_or(data_hex))
        .map_err(|e| format!("bad calldata: {e}"))?;
    let call_value = parse_tron_call_value(value_str)?;

    let core = handle()?;

    let provider = core
        .get_provider(chain_hash)
        .map_err(ServiceError::BackgroundError)?;

    // Build the transaction and fill the block ref before moving into TransactionRequest.
    // Using Vec::new() for placeholder ref-block fields that tron_fill_block_ref will overwrite.
    let mut tron_tx = TronTransaction::builder()
        .ref_block(Vec::new(), Vec::new())
        .expiration(0)
        .timestamp(0)
        .fee_limit(0)
        .trigger_smart_contract(&owner, &router, call_value, data, 0, 0)
        .build()
        .map_err(|e| e.to_string())?;
    provider
        .tron_fill_block_ref(&mut tron_tx)
        .await
        .map_err(ServiceError::NetworkErrors)?;

    // Move into TransactionRequest so tron_estimate_params_batch can borrow it,
    // then mutate the fee limit in place — no clone needed.
    let mut req = TransactionRequest::Tron((tron_tx, TransactionMetadata::default()));
    let params = provider
        .tron_estimate_params_batch(&req, &owner)
        .await
        .map_err(ServiceError::NetworkErrors)?;

    let TransactionRequest::Tron((ref mut tron_tx, _)) = req else {
        return Err("internal: unexpected transaction variant".to_string());
    };
    tron_tx.set_fee_limit(u256_to_i64_fee(params.current)?);

    let tron_info = TransactionRequestTron::from(tron_tx.to_tron_web().map_err(|e| e.to_string())?);

    Ok(TransactionRequestInfo {
        metadata: TransactionMetadataInfo {
            chain_hash,
            hash: None,
            info: Some(display.swap_info),
            icon: Some(display.icon),
            title: Some(display.swap_title),
            signer: None,
            token_info: display.out_token,
            broadcast: true,
        },
        scilla: None,
        evm: None,
        btc: None,
        tron: Some(tron_info),
        solana: None,
    })
}

pub(super) async fn execute_tron_exchange_swap(
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

    let mut results = Vec::with_capacity(2);

    if !from.token.native {
        if let Some(approval) = provider
            .check_approval(&from, &to, &amount_in, approve_title)
            .await?
        {
            let _ = sink.add("approving".to_string());
            let approve_tx: TransactionRequest = approval
                .try_into()
                .map_err(ServiceError::TransactionErrors)?;
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
            let _ = sink.add("approved".to_string());
        }
    }

    let prepared = provider
        .prepare_swap(&from, &to, &amount_in, slippage_bps)
        .await?;
    let swap_tx: TransactionRequest = provider
        .finalize_swap(&prepared.quote_blob, None, swap_title, swap_info, out_token)
        .await?
        .try_into()
        .map_err(ServiceError::TransactionErrors)?;

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
