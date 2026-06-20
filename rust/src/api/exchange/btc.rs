use std::str::FromStr;

use zilpay::background::bg_bitcoin::BitcoinManagement;
use zilpay::background::bg_wallet::WalletManagement;
use zilpay::proto::address::Address;
use zilpay::proto::btc_utils::BtcAccountXpubsInput;
use zilpay::proto::tx::TransactionRequest;
use zilpay::proto::U256;
use zilpay::secrecy::SecretString;
use zilpay::token::ft::FToken;
use zilpay::wallet::wallet_crypto::WalletCrypto;
use zilpay::wallet::wallet_storage::StorageOperations;
use zilpay::wallet::wallet_types::WalletTypes;

use crate::api::transaction::{sign_and_broadcast_one, unlock_seed};
use crate::frb_generated::StreamSink;
use crate::models::exchange::relay::{RelayBlob, RelaySource};
use crate::models::exchange::{ExchangeTxDisplay, SwapAuth, SwapParams};
use crate::models::transactions::history::HistoricalTransactionInfo;
use crate::utils::{errors::ServiceError, helpers::handle};

pub(super) async fn execute_btc_exchange_swap(
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
    let (vault_addr, amount_sat) = match blob.source {
        RelaySource::Btc {
            psbt,
            deposit_address,
        } => {
            // Deposit-address flow: Relay attributes the deposit by this unique
            // address, so the rebuilt tx only has to pay it the quoted amount.
            zilpay::bitcoin::Address::from_str(&deposit_address)
                .map_err(|e| format!("invalid relay deposit address: {e}"))?
                .require_network(zilpay::bitcoin::Network::Bitcoin)
                .map_err(|e| format!("relay deposit address network: {e}"))?;
            let amount_sat = amount_in
                .parse::<u64>()
                .map_err(|e| format!("invalid BTC amount {amount_in}: {e}"))?;
            eprintln!(
                "[btc-relay] deposit vault={deposit_address} amount_sat={amount_sat} psbt_len={}",
                psbt.len(),
            );
            (
                Address::Secp256k1Bitcoin(deposit_address.into_bytes()),
                amount_sat,
            )
        }
        RelaySource::Evm { .. } | RelaySource::Svm { .. } | RelaySource::Tron { .. } => {
            return Err("expected RelaySource::Btc from quote".to_string());
        }
    };

    let core = handle()?;

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

    // HD wallets need the account xpubs so the deposit builder can bootstrap a
    // fresh P2WPKH change address (rotation leaves no unused internal entry).
    let xpubs = match &wallet_data.wallet_type {
        WalletTypes::SecretPhrase(_) => {
            let network = account
                .addr
                .get_bitcoin_network()
                .map_err(|e| format!("btc network: {e}"))?;
            let mnemonic = wallet
                .reveal_mnemonic(&seed)
                .map_err(|e| ServiceError::WalletError(auth.wallet_index, e))?;
            let seed_secret = mnemonic
                .to_seed(&secret_passphrase)
                .map_err(|e| format!("bip39 seed: {e:?}"))?;
            let acct_idx = u32::try_from(auth.account_index)
                .map_err(|_| "account index overflow".to_string())?;
            Some(
                BtcAccountXpubsInput::from_seed(&seed_secret, acct_idx, network)
                    .map_err(|e| format!("btc xpubs: {e:?}"))?,
            )
        }
        _ => None,
    };

    let mut btc_tx = core
        .build_btc_deposit_with_memo(
            &token,
            account,
            vault_addr,
            amount_sat,
            None,
            None,
            xpubs.as_ref(),
        )
        .await
        .map_err(ServiceError::BackgroundError)?;
    let TransactionRequest::Bitcoin((tx, metadata, btc_meta)) = &mut btc_tx else {
        return Err("internal: expected Bitcoin tx".to_string());
    };
    eprintln!(
        "[btc-relay] built deposit inputs={} input_sat={} outputs={}",
        tx.input.len(),
        btc_meta
            .witness_utxos
            .iter()
            .map(|u| u.value.to_sat())
            .sum::<u64>(),
        tx.output.len(),
    );
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
    eprintln!(
        "[btc-relay] broadcast txid={}",
        hist.metadata.hash.as_deref().unwrap_or("<none>"),
    );
    let _ = sink.add("done".to_string());

    Ok(vec![hist])
}
