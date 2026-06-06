//! Relay.link intent/solver bridge engine.
//!
//! Relay returns ready-to-sign origin-chain transactions (`approve` then `deposit`/`swap`) from
//! `POST /quote`; the solver fills the destination chain. All implementation details stay behind
//! `#[frb(ignore)]`; only [`RelayMeta`] crosses `flutter_rust_bridge` as an
//! `ExchangeProvider::Relay` payload.

use std::borrow::Cow;
use std::str::FromStr;
use std::time::Duration;

use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{Address, U256};
use zilpay::crypto::slip44::{BITCOIN, ETHEREUM, SOLANA};
use zilpay::proto::AlloyTxKind;
use zilpay::proto::tx::{ETHTransactionRequest, TransactionMetadata, TransactionRequest};
use zilpay::reqwest;
use zilpay::serde::{self, Deserialize, Serialize};
use zilpay::serde_json;

use super::{ExchangeAsset, ExchangeProvider, ExchangeQuoteInfo};
use crate::models::exchange::univ_router::PreparedSwap;
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::request::TransactionRequestInfo;

const FEE_RECIPIENT: &str = "0x74d35b31ed6b31818331bc28fe343669126f152f";
const FEE_BIPS: u32 = 50;

const RELAY_BASE_URLS: &[&str] = &["https://api.relay.link"];

pub const RELAY_BTC_CHAIN_ID: u64 = 8_253_038;
pub const RELAY_SOL_CHAIN_ID: u64 = 792_703_809;
const RELAY_BTC_NATIVE: &str = "bc1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqmql8k8";
const RELAY_SOL_NATIVE: &str = "11111111111111111111111111111111";

const SUPPORTED_EVM_CHAINS: &[u64] = &[1, 10, 56, 137, 8453, 42161, 43114];
const DEFAULT_RELAY_EVM_GAS: u64 = 400_000;
const DEFAULT_RELAY_APPROVE_GAS: u64 = 60_000;

#[derive(Debug, Default, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct RelayMeta {
    /// Bearby provider hash for the asset's chain.
    pub chain_hash: u64,
    /// Relay chain id. EVM chains use their normal EIP-155 id; Solana and Bitcoin use Relay's
    /// synthetic ids.
    pub chain_id: u64,
    /// Bearby/BIP slip44 for address-family checks and future VM-specific finalizers.
    pub slip44: u32,
    /// Selected wallet account address on this asset's chain. Relay uses the source asset's address
    /// as `user` and the destination asset's address as `recipient`.
    pub account_addr: String,
}

impl RelayMeta {
    #[frb(ignore)]
    pub fn for_chain(
        chain_hash: u64,
        slip44: u32,
        chain_id: u64,
        account_addr: &str,
    ) -> Option<Self> {
        relay_chain_id(slip44, chain_id)
            .filter(|id| is_supported_chain(*id))
            .map(|relay_chain_id| Self {
                chain_hash,
                chain_id: relay_chain_id,
                slip44,
                account_addr: account_addr.to_string(),
            })
    }
}

#[frb(ignore)]
pub fn is_supported_chain(chain_id: u64) -> bool {
    SUPPORTED_EVM_CHAINS.contains(&chain_id)
        || chain_id == RELAY_BTC_CHAIN_ID
        || chain_id == RELAY_SOL_CHAIN_ID
}

#[frb(ignore)]
pub const fn relay_chain_id(slip44: u32, chain_id: u64) -> Option<u64> {
    match (slip44, chain_id) {
        (ETHEREUM, id) => Some(id),
        (BITCOIN, _) => Some(RELAY_BTC_CHAIN_ID),
        (SOLANA, _) => Some(RELAY_SOL_CHAIN_ID),
        _ => None,
    }
}

#[frb(ignore)]
pub fn is_evm_relay_chain(chain_id: u64) -> bool {
    SUPPORTED_EVM_CHAINS.contains(&chain_id)
}

#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct QuoteRequest<'a> {
    user: &'a str,
    recipient: &'a str,
    origin_chain_id: u64,
    destination_chain_id: u64,
    origin_currency: Cow<'a, str>,
    destination_currency: Cow<'a, str>,
    amount: &'a str,
    trade_type: &'static str,
    app_fees: [AppFee<'a>; 1],
}

#[frb(ignore)]
#[derive(Debug, Serialize)]
#[serde(crate = "zilpay::serde")]
struct AppFee<'a> {
    recipient: &'a str,
    fee: u32,
}

#[frb(ignore)]
#[derive(Debug, Default, Deserialize)]
#[serde(crate = "zilpay::serde", default)]
pub struct QuoteResponse {
    pub steps: Vec<Step>,
    pub details: Details,
}

#[frb(ignore)]
#[derive(Debug, Default, Deserialize)]
#[serde(crate = "zilpay::serde", default)]
pub struct Step {
    pub id: String,
    pub kind: String,
    pub items: Vec<Item>,
}

#[frb(ignore)]
#[derive(Debug, Default, Deserialize)]
#[serde(crate = "zilpay::serde", default)]
pub struct Item {
    pub data: StepData,
}

fn string_or_number_opt<'de, D>(deserializer: D) -> Result<Option<String>, D::Error>
where
    D: serde::de::Deserializer<'de>,
{
    match Option::<serde_json::Value>::deserialize(deserializer)? {
        Some(serde_json::Value::String(value)) => Ok(Some(value)),
        Some(serde_json::Value::Number(value)) => Ok(Some(value.to_string())),
        Some(serde_json::Value::Null) | None => Ok(None),
        Some(other) => Err(<D::Error as serde::de::Error>::custom(format!(
            "expected string or number, got {other}"
        ))),
    }
}

#[frb(ignore)]
#[derive(Debug, Default, Deserialize)]
#[serde(crate = "zilpay::serde", default, rename_all = "camelCase")]
pub struct StepData {
    pub from: Option<String>,
    pub to: Option<String>,
    pub data: Option<String>,
    #[serde(deserialize_with = "string_or_number_opt")]
    pub value: Option<String>,
    pub chain_id: Option<u64>,
    #[serde(deserialize_with = "string_or_number_opt")]
    pub gas: Option<String>,
    pub instructions: Option<serde_json::Value>,
    pub address_lookup_table_addresses: Option<Vec<String>>,
    pub psbt: Option<String>,
}

#[frb(ignore)]
#[derive(Debug, Default, Deserialize)]
#[serde(crate = "zilpay::serde", default, rename_all = "camelCase")]
pub struct Details {
    pub currency_out: CurrencyAmount,
}

#[frb(ignore)]
#[derive(Debug, Default, Deserialize)]
#[serde(crate = "zilpay::serde", default, rename_all = "camelCase")]
pub struct CurrencyAmount {
    pub amount: String,
    pub minimum_amount: String,
}

#[frb(ignore)]
#[derive(Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub enum RelaySource {
    Evm {
        chain_id: u64,
        to: String,
        data: String,
        value: String,
        gas: Option<u64>,
    },
    Svm {
        instructions_json: String,
        address_lookup_table_addresses: Vec<String>,
    },
    Btc {
        psbt: String,
    },
}

#[frb(ignore)]
#[derive(Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub struct RelayBlob {
    pub source: RelaySource,
    pub chain_hash: u64,
}

#[frb(ignore)]
async fn relay_post<T: serde::de::DeserializeOwned>(
    path: &str,
    body: &(impl Serialize + Sync),
) -> Result<T, String> {
    let client = reqwest::Client::new();
    let payload = serde_json::to_string(body).map_err(|e| e.to_string())?;
    let mut last_err = String::new();

    for base in RELAY_BASE_URLS {
        let url = format!("{base}{path}");
        let resp = client
            .post(&url)
            .header("content-type", "application/json")
            .header("x-client-id", "bearby")
            .timeout(Duration::from_secs(15))
            .body(payload.clone())
            .send()
            .await;

        match resp {
            Ok(r) if r.status().is_success() => {
                let body = r.text().await.map_err(|e| format!("{url}: body {e}"))?;
                return serde_json::from_str::<T>(&body).map_err(|e| format!("{url}: decode {e}"));
            }
            Ok(r) => {
                let status = r.status();
                let body = match r.text().await {
                    Ok(text) => text,
                    Err(e) => format!("body error: {e}"),
                };
                last_err = format!("{url}: {status}: {body}");
            }
            Err(e) => last_err = format!("{url}: {e}"),
        }
    }

    Err(format!("relay request failed: {last_err}"))
}

const fn relay_currency(asset: &ExchangeAsset, relay_chain_id: u64) -> Cow<'_, str> {
    match (relay_chain_id, asset.token.native) {
        (RELAY_BTC_CHAIN_ID, true) => Cow::Borrowed(RELAY_BTC_NATIVE),
        (RELAY_SOL_CHAIN_ID, true) => Cow::Borrowed(RELAY_SOL_NATIVE),
        _ => Cow::Borrowed(asset.token.addr.as_str()),
    }
}

fn relay_origin_chain_id(asset: &ExchangeAsset) -> Result<u64, String> {
    asset
        .relay_meta()
        .map(|meta| meta.chain_id)
        .ok_or_else(|| "source is not a Relay asset".to_string())
}

fn evm_origin_chain_id(asset: &ExchangeAsset) -> Result<u64, String> {
    let chain_id = relay_origin_chain_id(asset)?;
    if is_evm_relay_chain(chain_id) {
        Ok(chain_id)
    } else {
        Err("Relay supports only EVM-origin swaps for now".to_string())
    }
}

async fn fetch_quote(
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
) -> Result<(QuoteResponse, u64, u64), String> {
    let origin_meta = from
        .relay_meta()
        .ok_or_else(|| "source is not a Relay asset".to_string())?;
    let destination_meta = to
        .relay_meta()
        .ok_or_else(|| "destination is not a Relay asset".to_string())?;
    let origin_chain_id = origin_meta.chain_id;
    let destination_chain_id = destination_meta.chain_id;
    let req = QuoteRequest {
        user: origin_meta.account_addr.as_str(),
        recipient: destination_meta.account_addr.as_str(),
        origin_chain_id,
        destination_chain_id,
        origin_currency: relay_currency(from, origin_chain_id),
        destination_currency: relay_currency(to, destination_chain_id),
        amount,
        trade_type: "EXACT_INPUT",
        app_fees: [AppFee {
            recipient: FEE_RECIPIENT,
            fee: FEE_BIPS,
        }],
    };

    relay_post::<QuoteResponse>("/quote", &req)
        .await
        .map(|quote| (quote, origin_chain_id, destination_chain_id))
}

fn step_data_by_id<'a>(quote: &'a QuoteResponse, ids: &[&str]) -> Option<&'a StepData> {
    quote.steps.iter().find_map(|step| {
        ids.iter()
            .any(|id| step.id.eq_ignore_ascii_case(id))
            .then(|| step.items.first().map(|item| &item.data))
            .flatten()
    })
}

/// `true` when a step carries a complete EVM call (non-empty `to` + `data`). Used to skip
/// incomplete relay steps (e.g. an `approve` whose calldata isn't populated yet) instead of
/// failing the swap.
fn step_has_evm_calldata(step: &StepData) -> bool {
    step.to.as_deref().is_some_and(|v| !v.is_empty())
        && step.data.as_deref().is_some_and(|v| !v.is_empty())
}

fn swap_step_data_owned(quote: QuoteResponse) -> Option<StepData> {
    let mut fallback = None;
    for step in quote.steps {
        let data = step.items.into_iter().next().map(|item| item.data);
        if ["deposit", "swap"]
            .iter()
            .any(|id| step.id.eq_ignore_ascii_case(id))
        {
            return data;
        }
        if fallback.is_none() && !step.id.eq_ignore_ascii_case("approve") {
            fallback = data;
        }
    }
    fallback
}

fn parse_u256_value(value: Option<&str>) -> Result<U256, String> {
    match value.filter(|v| !v.is_empty()) {
        Some(v) if v.starts_with("0x") || v.starts_with("0X") => {
            U256::from_str_radix(v.trim_start_matches("0x").trim_start_matches("0X"), 16)
                .map_err(|e| e.to_string())
        }
        Some(v) => U256::from_str(v).map_err(|e| e.to_string()),
        None => Ok(U256::ZERO),
    }
}

fn parse_u64_value(value: Option<&str>) -> Result<Option<u64>, String> {
    match value.filter(|v| !v.is_empty()) {
        Some(v) if v.starts_with("0x") || v.starts_with("0X") => {
            u64::from_str_radix(v.trim_start_matches("0x").trim_start_matches("0X"), 16)
                .map(Some)
                .map_err(|e| e.to_string())
        }
        Some(v) => v.parse::<u64>().map(Some).map_err(|e| e.to_string()),
        None => Ok(None),
    }
}

fn build_evm_tx(
    tx: RelayEvmTx<'_>,
    chain_hash: u64,
    swapper: Address,
    default_gas: u64,
) -> Result<TransactionRequest, String> {
    let to_addr = Address::from_str(tx.to).map_err(|e| e.to_string())?;
    let input = hex::decode(tx.data).map_err(|e| e.to_string())?;
    let mut eth_tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(to_addr)),
        from: Some(swapper),
        value: Some(parse_u256_value(tx.value)?),
        input: input.into(),
        gas: Some(tx.gas.unwrap_or(default_gas)),
        ..Default::default()
    };
    eth_tx.chain_id = Some(tx.chain_id);

    Ok(TransactionRequest::Ethereum((
        eth_tx,
        TransactionMetadata {
            chain_hash,
            broadcast: true,
            ..Default::default()
        },
    )))
}

#[derive(Clone, Copy)]
struct RelayEvmTx<'a> {
    chain_id: u64,
    to: &'a str,
    data: &'a str,
    value: Option<&'a str>,
    gas: Option<u64>,
}

fn evm_tx_from_step(
    step: &StepData,
    fallback_chain_id: u64,
    chain_hash: u64,
    swapper: Address,
    default_gas: u64,
) -> Result<TransactionRequest, String> {
    let to = step
        .to
        .as_deref()
        .ok_or_else(|| "relay EVM tx missing to".to_string())?;
    let data = step
        .data
        .as_deref()
        .ok_or_else(|| "relay EVM tx missing data".to_string())?;

    build_evm_tx(
        RelayEvmTx {
            chain_id: step.chain_id.unwrap_or(fallback_chain_id),
            to,
            data,
            value: step.value.as_deref(),
            gas: parse_u64_value(step.gas.as_deref())?,
        },
        chain_hash,
        swapper,
        default_gas,
    )
}

fn evm_blob_from_step(
    mut step: StepData,
    fallback_chain_id: u64,
    chain_hash: u64,
) -> Result<RelayBlob, String> {
    let to = step
        .to
        .take()
        .filter(|v| !v.is_empty())
        .ok_or_else(|| "relay EVM tx missing to".to_string())?;
    let data = step
        .data
        .take()
        .filter(|v| !v.is_empty())
        .ok_or_else(|| "relay EVM tx missing data".to_string())?;
    Ok(RelayBlob {
        source: RelaySource::Evm {
            chain_id: step.chain_id.unwrap_or(fallback_chain_id),
            to,
            data,
            value: step.value.unwrap_or_else(|| "0".to_string()),
            gas: parse_u64_value(step.gas.as_deref())?,
        },
        chain_hash,
    })
}

fn blob_from_step(
    step: StepData,
    origin_chain_id: u64,
    chain_hash: u64,
) -> Result<RelayBlob, String> {
    match origin_chain_id {
        id if is_evm_relay_chain(id) => evm_blob_from_step(step, id, chain_hash),
        RELAY_SOL_CHAIN_ID => {
            let instructions = step
                .instructions
                .ok_or_else(|| "relay Solana tx missing instructions".to_string())?;
            Ok(RelayBlob {
                source: RelaySource::Svm {
                    instructions_json: serde_json::to_string(&instructions)
                        .map_err(|e| e.to_string())?,
                    address_lookup_table_addresses: step
                        .address_lookup_table_addresses
                        .unwrap_or_default(),
                },
                chain_hash,
            })
        }
        RELAY_BTC_CHAIN_ID => {
            let psbt = step
                .psbt
                .filter(|v| !v.is_empty())
                .ok_or_else(|| "relay Bitcoin tx missing psbt".to_string())?;
            Ok(RelayBlob {
                source: RelaySource::Btc { psbt },
                chain_hash,
            })
        }
        _ => Err("relay origin chain not supported".to_string()),
    }
}

fn with_display(
    tx: TransactionRequest,
    chain_hash: u64,
    swap_title: String,
    swap_info: String,
    provider_icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let TransactionRequest::Ethereum((evm_tx, _)) = tx else {
        return Err("expected Ethereum tx".to_string());
    };
    Ok(TransactionRequest::Ethereum((
        evm_tx,
        TransactionMetadata {
            chain_hash,
            broadcast: true,
            title: Some(swap_title),
            info: Some(swap_info),
            icon: Some(provider_icon),
            token_info: out_token.and_then(|t| {
                U256::from_str(&t.value)
                    .ok()
                    .map(|value| (value, t.decimals, t.symbol))
            }),
            ..Default::default()
        },
    ))
    .into())
}

#[frb(ignore)]
pub async fn relay_quote_info(
    provider: &ExchangeProvider,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
) -> Result<ExchangeQuoteInfo, String> {
    evm_origin_chain_id(from)?;
    let (quote, _, _) = fetch_quote(from, to, amount).await?;
    let amount_out = quote.details.currency_out.amount;
    if amount_out.is_empty() {
        return Err("relay quote missing amount out".to_string());
    }

    Ok(ExchangeQuoteInfo {
        provider: provider.clone(),
        amount_out,
        permit_typed_data_json: None,
        is_wrap_unwrap: false,
    })
}

#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub async fn relay_check_approval(
    swapper: Address,
    chain_hash: u64,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
    approve_title: String,
    provider_icon: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    let Ok(origin_chain_id) = evm_origin_chain_id(from) else {
        return Ok(None);
    };
    let (quote, _, _) = fetch_quote(from, to, amount).await?;
    // Only build the approval when relay returns complete calldata; an incomplete `approve` step
    // is skipped rather than failing the whole swap.
    let Some(step) =
        step_data_by_id(&quote, &["approve"]).filter(|step| step_has_evm_calldata(step))
    else {
        return Ok(None);
    };
    let tx = evm_tx_from_step(
        step,
        origin_chain_id,
        chain_hash,
        swapper,
        DEFAULT_RELAY_APPROVE_GAS,
    )?;
    let TransactionRequest::Ethereum((evm_tx, _)) = tx else {
        return Err("expected Ethereum tx".to_string());
    };

    Ok(Some(
        TransactionRequest::Ethereum((
            evm_tx,
            TransactionMetadata {
                chain_hash,
                broadcast: true,
                title: Some(approve_title),
                icon: Some(provider_icon),
                ..Default::default()
            },
        ))
        .into(),
    ))
}

#[frb(ignore)]
pub async fn relay_prepare_swap(
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
) -> Result<PreparedSwap, String> {
    let origin_chain_id = evm_origin_chain_id(from)?;
    let (quote, _, _) = fetch_quote(from, to, amount).await?;
    let step =
        swap_step_data_owned(quote).ok_or_else(|| "relay quote missing swap step".to_string())?;
    let blob = blob_from_step(step, origin_chain_id, from.token.chain_hash)?;

    Ok(PreparedSwap {
        permit_typed_data_json: None,
        quote_blob: serde_json::to_string(&blob).map_err(|e| e.to_string())?,
    })
}

#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub async fn relay_finalize_swap(
    quote_blob: &str,
    swapper: Address,
    chain_hash: u64,
    swap_title: String,
    swap_info: String,
    provider_icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let blob: RelayBlob =
        serde_json::from_str(quote_blob).map_err(|e| format!("invalid quote_blob: {e}"))?;

    match blob.source {
        RelaySource::Evm {
            chain_id,
            to,
            data,
            value,
            gas,
        } => {
            let tx = build_evm_tx(
                RelayEvmTx {
                    chain_id,
                    to: &to,
                    data: &data,
                    value: Some(&value),
                    gas,
                },
                chain_hash,
                swapper,
                DEFAULT_RELAY_EVM_GAS,
            )?;
            with_display(tx, chain_hash, swap_title, swap_info, provider_icon, out_token)
        }
        RelaySource::Svm { .. } => Err(
            "Relay Solana-origin swaps require Solana v0/ALT message signing, which is not available yet"
                .to_string(),
        ),
        RelaySource::Btc { .. } => Err(
            "Relay Bitcoin-origin swaps require external PSBT signing/finalization, which is not available yet"
                .to_string(),
        ),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn relay_meta_known_and_unknown() {
        assert_eq!(
            RelayMeta::for_chain(
                42,
                ETHEREUM,
                1,
                "0x0000000000000000000000000000000000000001"
            )
            .map(|m| m.chain_id),
            Some(1)
        );
        assert_eq!(
            RelayMeta::for_chain(43, SOLANA, 101, "11111111111111111111111111111111")
                .map(|m| m.chain_id),
            Some(RELAY_SOL_CHAIN_ID)
        );
        assert_eq!(
            RelayMeta::for_chain(
                44,
                ETHEREUM,
                11_155_111,
                "0x0000000000000000000000000000000000000001"
            ),
            None
        );
    }

    #[test]
    fn relay_blob_round_trip() -> Result<(), String> {
        let blob = RelayBlob {
            source: RelaySource::Evm {
                chain_id: 1,
                to: "0x0000000000000000000000000000000000000001".to_string(),
                data: "0x1234".to_string(),
                value: "0".to_string(),
                gas: Some(21_000),
            },
            chain_hash: 42,
        };
        let json = serde_json::to_string(&blob).map_err(|e| e.to_string())?;
        let decoded: RelayBlob = serde_json::from_str(&json).map_err(|e| e.to_string())?;
        assert_eq!(decoded, blob);
        Ok(())
    }

    #[test]
    fn quote_response_deserializes_currency_out() -> Result<(), String> {
        let raw = r#"{
            "steps": [{
                "id": "deposit",
                "kind": "transaction",
                "items": [{"data": {
                    "from": "0x0000000000000000000000000000000000000002",
                    "to": "0x0000000000000000000000000000000000000001",
                    "data": "0xabcdef",
                    "value": "100",
                    "chainId": 1,
                    "gas": "0x5208"
                }}]
            }],
            "details": {"currencyOut": {"amount": "995", "minimumAmount": "990"}}
        }"#;
        let quote: QuoteResponse = serde_json::from_str(raw).map_err(|e| e.to_string())?;
        assert_eq!(quote.details.currency_out.amount, "995");
        assert_eq!(quote.details.currency_out.minimum_amount, "990");
        let step = swap_step_data_owned(quote).ok_or_else(|| "missing swap step".to_string())?;
        assert_eq!(step.chain_id, Some(1));
        assert_eq!(parse_u64_value(step.gas.as_deref())?, Some(21_000));
        Ok(())
    }

    #[test]
    fn step_calldata_completeness() {
        let complete = StepData {
            to: Some("0x0000000000000000000000000000000000000001".to_string()),
            data: Some("0x095ea7b3".to_string()),
            ..Default::default()
        };
        assert!(step_has_evm_calldata(&complete));

        // An approve step relay hasn't populated yet (no calldata) is treated as incomplete.
        let no_data = StepData {
            to: Some("0x0000000000000000000000000000000000000001".to_string()),
            ..Default::default()
        };
        assert!(!step_has_evm_calldata(&no_data));
        assert!(!step_has_evm_calldata(&StepData::default()));
    }
}
