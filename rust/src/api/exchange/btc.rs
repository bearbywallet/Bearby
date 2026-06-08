use std::str::FromStr;
use std::sync::Arc;

use zilpay::background::bg_bitcoin::BitcoinManagement;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::background::bg_wallet::WalletManagement;
use zilpay::base64::{engine::general_purpose::STANDARD, Engine as _};
use zilpay::bitcoin::{self, psbt::Psbt, Address as BtcAddress};
use zilpay::proto::address::Address;
use zilpay::proto::tx::TransactionRequest;
use zilpay::proto::U256;
use zilpay::secrecy::SecretString;
use zilpay::token::ft::FToken;
use zilpay::wallet::wallet_storage::StorageOperations;

use crate::api::transaction::{sign_and_broadcast_one, unlock_seed};
use crate::frb_generated::StreamSink;
use crate::models::exchange::relay::{RelayBlob, RelaySource};
use crate::models::exchange::{ExchangeTxDisplay, SwapAuth, SwapParams};
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;

/// Parse a base64 PSBT into non-OP_RETURN outputs as `(Address::Secp256k1Bitcoin, amount_sat)`.
pub(crate) fn psbt_destinations(
    psbt_b64: &str,
    network: bitcoin::Network,
) -> Result<Vec<(Address, u64)>, String> {
    let bytes = STANDARD
        .decode(psbt_b64)
        .map_err(|e| format!("psbt base64: {e}"))?;
    let psbt = Psbt::deserialize(&bytes).map_err(|e| format!("psbt decode: {e}"))?;

    psbt.unsigned_tx
        .output
        .iter()
        .filter(|o| !o.script_pubkey.is_op_return())
        .map(|o| {
            let addr = BtcAddress::from_script(&o.script_pubkey, network)
                .map_err(|e| format!("script→addr: {e}"))?;
            Ok((
                Address::Secp256k1Bitcoin(addr.to_string().into_bytes()),
                o.value.to_sat(),
            ))
        })
        .collect()
}

pub(super) async fn execute_btc_exchange_swap(
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
    let ExchangeTxDisplay {
        swap_title,
        swap_info,
        out_token,
        ..
    } = display;
    let chain_hash = from.token.chain_hash;

    let prepared = provider
        .prepare_swap(&from, &to, &amount_in, slippage_bps)
        .await?;

    let blob: RelayBlob = zilpay::serde_json::from_str(&prepared.quote_blob)
        .map_err(|e| format!("invalid relay quote blob: {e}"))?;
    let psbt_b64 = match blob.source {
        RelaySource::Btc { psbt } => psbt,
        RelaySource::Evm { .. } | RelaySource::Svm { .. } | RelaySource::Tron { .. } => {
            return Err("expected RelaySource::Btc from quote".to_string());
        }
    };

    let core = Arc::clone(
        &BACKGROUND_SERVICE
            .read()
            .await
            .as_ref()
            .ok_or(ServiceError::NotRunning)?
            .core,
    );
    let network = core
        .get_provider(chain_hash)
        .map_err(ServiceError::BackgroundError)?
        .config
        .bitcoin_network()
        .unwrap_or(bitcoin::Network::Bitcoin);
    let (vault_addr, amount_sat) = psbt_destinations(&psbt_b64, network)?
        .into_iter()
        .next()
        .ok_or_else(|| "relay PSBT has no spendable outputs".to_string())?;

    let seed = unlock_seed(&core, auth.wallet_index, auth.password).await?;
    let secret_passphrase = SecretString::new(auth.passphrase.unwrap_or_default().into());

    let wallet = core
        .get_wallet_by_index(auth.wallet_index)
        .map_err(ServiceError::BackgroundError)?;
    let wallet_data = wallet
        .get_wallet_data()
        .map_err(|e| ServiceError::WalletError(auth.wallet_index, e))?;
    let account = wallet_data
        .get_account(auth.account_index)
        .map_err(|e| ServiceError::AccountError(auth.account_index, auth.wallet_index, e))?;
    let token: FToken = wallet
        .get_ftokens()
        .map_err(|e| ServiceError::WalletError(auth.wallet_index, e))?
        .into_iter()
        .find(|t| t.chain_hash == chain_hash && t.native)
        .ok_or(ServiceError::TokenError(
            zilpay::errors::token::TokenError::TokenParseError,
        ))?;

    let token_info = out_token.and_then(|t| {
        U256::from_str(&t.value)
            .ok()
            .map(|value| (value, t.decimals, t.symbol))
    });
    let mut btc_tx = core
        .build_btc_deposit_with_memo(&token, account, vault_addr, amount_sat, None, None)
        .await
        .map_err(ServiceError::BackgroundError)?;
    let TransactionRequest::Bitcoin((_, metadata, _)) = &mut btc_tx else {
        return Err("internal: expected Bitcoin tx".to_string());
    };
    metadata.title = Some(swap_title);
    metadata.info = Some(swap_info);
    if let Some(info) = token_info {
        metadata.token_info = Some(info);
    }

    let _ = sink.add("swapping".to_string());
    let hist = sign_and_broadcast_one(
        &core,
        auth.wallet_index,
        auth.account_index,
        &seed,
        &secret_passphrase,
        btc_tx,
    )
    .await?;
    let _ = sink.add("done".to_string());

    Ok(vec![hist])
}
