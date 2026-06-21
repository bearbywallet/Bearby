//! Relay.link intent/solver bridge engine.
//!
//! Relay returns ready-to-sign origin-chain transactions (`approve` then `deposit`/`swap`) from
//! `POST /quote`; the solver fills the destination chain. All implementation details stay behind
//! `#[frb(ignore)]`; only [`RelayMeta`] crosses `flutter_rust_bridge` as an
//! `ExchangeProvider::Relay` payload.

use std::borrow::Cow;
use std::collections::{HashMap, HashSet};
use std::str::FromStr;
use std::sync::Arc;
use std::time::{Duration, Instant};

use arc_swap::ArcSwapOption;
use flutter_rust_bridge::frb;
use zilpay::alloy::hex;
use zilpay::alloy::primitives::{Address, U256};
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::network::solana::{SolanaMessageBuild, SolanaOperations};
use zilpay::proto::address::Address as ProtoAddress;
use zilpay::proto::solana_tx::SolanaTransaction;
use zilpay::proto::tx::{ETHTransactionRequest, TransactionMetadata, TransactionRequest};
use zilpay::proto::AlloyTxKind;
use zilpay::reqwest;
use zilpay::serde::{self, Deserialize, Serialize};
use zilpay::serde_json;
use zilpay::solana_instruction::{AccountMeta, Instruction};
use zilpay::solana_pubkey::Pubkey;

use super::{ExchangeAsset, ProviderCommon, ProviderQuote};
use crate::models::exchange::univ_router::PreparedSwap;
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::request::TransactionRequestInfo;

const FEE_RECIPIENT: &str = "0x74d35b31ed6b31818331bc28fe343669126f152f";
const FEE_BIPS: u32 = 50;

const RELAY_BASE_URLS: &[&str] = &["https://api.relay.link"];

pub const RELAY_BTC_CHAIN_ID: u64 = 8_253_038;
pub const RELAY_SOL_CHAIN_ID: u64 = 792_703_809;
pub const RELAY_TRON_CHAIN_ID: u64 = 728_126_428;
const RELAY_BTC_NATIVE: &str = "bc1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqmql8k8";
const RELAY_SOL_NATIVE: &str = "11111111111111111111111111111111";
const RELAY_TRON_NATIVE: &str = "T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb";

const SUPPORTED_EVM_CHAINS: &[u64] = &[1, 10, 56, 137, 8453, 42161, 43114];
const DEFAULT_RELAY_EVM_GAS: u64 = 400_000;
const DEFAULT_RELAY_APPROVE_GAS: u64 = 60_000;

/// Cache TTL for the GET /chains support matrix. One fetch feeds every validate across every
/// chain; within TTL a validate is a lock-free cache load (no network).
const RELAY_SUPPORT_TTL: Duration = Duration::from_secs(300);

/// Origin-chain runtime classifier derived from the token address type.
/// Used to route swap execution without inspecting slip44.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum RelayOrigin {
    Evm,
    Svm,
    Btc,
    Tron,
}

impl RelayOrigin {
    pub(crate) const fn from_addr_type(addr_type: u8) -> Option<Self> {
        match addr_type {
            1 => Some(Self::Evm),
            3 => Some(Self::Svm),
            2 => Some(Self::Btc),
            4 => Some(Self::Tron),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, Copy)]
pub struct RelayCfg {
    pub default_slippage_bps: u32,
    pub supports_price_protection: bool,
}

impl RelayCfg {
    pub const fn default() -> Self {
        Self {
            default_slippage_bps: 30,
            supports_price_protection: true,
        }
    }
}

#[derive(Debug, Clone)]
pub struct RelayMeta {
    pub common: ProviderCommon,
    pub cfg: RelayCfg,
    pub quote: Option<ProviderQuote>,
}

impl RelayMeta {
    /// Construct a `RelayMeta` for the given origin chain.
    ///
    /// `addr_type` is the address-family classifier from `Address::prefix_type()`:
    /// 1 = EVM, 2 = BTC, 3 = Solana, 4 = TRON.
    ///
    /// Token support is decided eagerly by the support gate
    /// ([`evaluate_support_eager`]) from GET /chains, not here: native TRX, A7A5, wrapped-BTC on
    /// TRON are pruned at load time because TRON is `tokenSupport: "Limited"` and they aren't
    /// bridgeable currencies. No hardcoded per-token special cases.
    #[frb(ignore)]
    pub fn for_chain(
        chain_hash: u64,
        addr_type: u8,
        chain_id: u64,
        account_addr: &str,
    ) -> Option<Self> {
        relay_chain_id(addr_type, chain_id)
            .filter(|id| is_supported_chain(*id))
            .map(|relay_chain_id| Self {
                common: ProviderCommon {
                    chain_hash,
                    chain_id: relay_chain_id,
                    slip44: u32::from(addr_type),
                    account_addr: account_addr.to_owned(),
                    icon_asset: "assets/icons/relay.svg".to_owned(),
                    display_name: "Relay".to_owned(),
                },
                cfg: RelayCfg::default(),
                quote: None,
            })
    }
}

#[frb(ignore)]
pub fn is_supported_chain(chain_id: u64) -> bool {
    SUPPORTED_EVM_CHAINS.contains(&chain_id)
        || chain_id == RELAY_BTC_CHAIN_ID
        || chain_id == RELAY_SOL_CHAIN_ID
        || chain_id == RELAY_TRON_CHAIN_ID
}

/// Map an origin address type to a Relay chain identifier.
/// Returns `None` for address families that Relay does not recognise.
#[frb(ignore)]
pub const fn relay_chain_id(addr_type: u8, evm_chain_id: u64) -> Option<u64> {
    match addr_type {
        1 => Some(evm_chain_id),
        2 => Some(RELAY_BTC_CHAIN_ID),
        3 => Some(RELAY_SOL_CHAIN_ID),
        4 => Some(RELAY_TRON_CHAIN_ID),
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
    /// BTC-origin only: ask Relay for a unique per-request deposit address so the
    /// deposit may originate from any wallet address (we rebuild the tx ourselves).
    #[serde(skip_serializing_if = "std::ops::Not::not")]
    use_deposit_address: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    refund_to: Option<&'a str>,
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
    #[serde(rename = "depositAddress")]
    pub deposit_address: Option<String>,
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
    /// TriggerSmartContract parameter block returned by Relay for TRON-origin steps.
    /// Relay uses a "parameter" key (instead of EVM-style to/data) with fields:
    /// contract_address, data, call_value, owner_address.
    #[serde(rename = "parameter")]
    pub tron_tx: Option<serde_json::Value>,
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

// Minimal wire structs for parsing the Relay Solana instruction format.
// These never cross Flutter — they are immediately converted to native Solana types.

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct RelaySvmAccountWire {
    pubkey: String,
    is_signer: bool,
    is_writable: bool,
}

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct RelaySvmInstructionWire {
    program_id: String,
    keys: Vec<RelaySvmAccountWire>,
    data: String,
}

impl TryFrom<RelaySvmAccountWire> for AccountMeta {
    type Error = String;

    fn try_from(value: RelaySvmAccountWire) -> Result<Self, Self::Error> {
        Ok(Self {
            pubkey: Pubkey::from_str(&value.pubkey).map_err(|e| e.to_string())?,
            is_signer: value.is_signer,
            is_writable: value.is_writable,
        })
    }
}

impl TryFrom<RelaySvmInstructionWire> for Instruction {
    type Error = String;

    fn try_from(value: RelaySvmInstructionWire) -> Result<Self, Self::Error> {
        let mut accounts = Vec::with_capacity(value.keys.len());
        for key in value.keys {
            accounts.push(AccountMeta::try_from(key)?);
        }
        Ok(Self {
            program_id: Pubkey::from_str(&value.program_id).map_err(|e| e.to_string())?,
            accounts,
            data: hex::decode(&value.data).map_err(|e| e.to_string())?,
        })
    }
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
        instructions: Vec<Instruction>,
        /// Base58-encoded address lookup table addresses; kept as strings for
        /// reliable serde round-trip without requiring Pubkey serde feature.
        lookup_table_addresses: Vec<String>,
    },
    Btc {
        psbt: String,
        /// Unique per-request deposit address from Relay's deposit-address flow;
        /// the on-chain deposit is attributed by this address, so it (not the
        /// PSBT vault output) is the authoritative destination.
        deposit_address: String,
    },
    Tron {
        to: String,
        data: String,
        value: String,
    },
}

#[frb(ignore)]
#[derive(Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub struct RelayBlob {
    pub source: RelaySource,
    pub chain_hash: u64,
}

/// Display metadata for the swap confirmation UI.
pub(crate) struct RelayDisplay {
    pub(crate) swap_title: String,
    pub(crate) swap_info: String,
    pub(crate) icon: String,
    pub(crate) out_token: Option<BaseTokenInfo>,
}

#[frb(ignore)]
fn relay_client() -> &'static reqwest::Client {
    static CLIENT: std::sync::OnceLock<reqwest::Client> = std::sync::OnceLock::new();
    CLIENT.get_or_init(reqwest::Client::new)
}

#[frb(ignore)]
async fn relay_post<T: serde::de::DeserializeOwned>(
    path: &str,
    body: &(impl Serialize + Sync),
) -> Result<T, String> {
    let client = relay_client();
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
            Err(e) => {
                last_err = format!("{url}: {e}");
            }
        }
    }

    Err(format!("relay request failed: {last_err}"))
}

const fn relay_currency(asset: &ExchangeAsset, relay_chain_id: u64) -> Cow<'_, str> {
    match (relay_chain_id, asset.token.native) {
        (RELAY_BTC_CHAIN_ID, true) => Cow::Borrowed(RELAY_BTC_NATIVE),
        (RELAY_SOL_CHAIN_ID, true) => Cow::Borrowed(RELAY_SOL_NATIVE),
        (RELAY_TRON_CHAIN_ID, true) => Cow::Borrowed(RELAY_TRON_NATIVE),
        _ => Cow::Borrowed(asset.token.addr.as_str()),
    }
}

fn relay_origin_chain_id(asset: &ExchangeAsset) -> Result<u64, String> {
    asset
        .relay_meta()
        .map(|meta| meta.common.chain_id)
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
    let origin_chain_id = origin_meta.common.chain_id;
    let destination_chain_id = destination_meta.common.chain_id;
    let is_btc_origin = origin_chain_id == RELAY_BTC_CHAIN_ID;
    let req = QuoteRequest {
        user: origin_meta.common.account_addr.as_str(),
        recipient: destination_meta.common.account_addr.as_str(),
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
        use_deposit_address: is_btc_origin,
        refund_to: is_btc_origin.then_some(origin_meta.common.account_addr.as_str()),
    };
    if is_btc_origin {
        eprintln!(
            "[btc-relay] quote user={} refund_to={:?} use_deposit_address={} amount={amount}",
            req.user, req.refund_to, req.use_deposit_address,
        );
    }
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

/// Pick the primary swap/deposit step, returning its data together with the
/// step-level `depositAddress` (set by Relay in the deposit-address flow).
fn swap_step_data_owned(quote: QuoteResponse) -> Option<(StepData, Option<String>)> {
    use std::ops::ControlFlow;

    match quote.steps.into_iter().try_fold(None, |fallback, step| {
        let Step {
            id,
            deposit_address,
            items,
            ..
        } = step;
        let is_primary = ["deposit", "swap"]
            .iter()
            .any(|step_id| id.eq_ignore_ascii_case(step_id));
        let is_approve = id.eq_ignore_ascii_case("approve");
        let data = items
            .into_iter()
            .next()
            .map(|item| (item.data, deposit_address));

        if is_primary {
            ControlFlow::Break(data)
        } else if fallback.is_none() && !is_approve {
            ControlFlow::Continue(data)
        } else {
            ControlFlow::Continue(fallback)
        }
    }) {
        ControlFlow::Break(primary) | ControlFlow::Continue(primary) => primary,
    }
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

fn tron_blob_from_step(mut step: StepData, chain_hash: u64) -> Result<RelayBlob, String> {
    // Fast path: Relay returned EVM-style to/data fields for this TRON step.
    if let (Some(to), Some(data)) = (
        step.to.take().filter(|v| !v.is_empty()),
        step.data.take().filter(|v| !v.is_empty()),
    ) {
        return Ok(RelayBlob {
            source: RelaySource::Tron {
                to,
                data,
                value: step.value.unwrap_or_else(|| "0".to_string()),
            },
            chain_hash,
        });
    }

    // Standard path: Relay returns TRON TriggerSmartContract params in a "parameter" block.
    let param = step
        .tron_tx
        .take()
        .ok_or_else(|| "relay Tron tx missing parameter".to_string())?;

    let to = param
        .get("contract_address")
        .and_then(serde_json::Value::as_str)
        .filter(|v| !v.is_empty())
        .ok_or_else(|| "relay Tron tx missing contract_address".to_string())?
        .to_owned();

    let data = param
        .get("data")
        .and_then(serde_json::Value::as_str)
        .unwrap_or("")
        .to_owned();

    let value = param
        .get("call_value")
        .and_then(serde_json::Value::as_i64)
        .unwrap_or(0)
        .to_string();

    Ok(RelayBlob {
        source: RelaySource::Tron { to, data, value },
        chain_hash,
    })
}

fn blob_from_step(
    step: StepData,
    deposit_address: Option<String>,
    origin_chain_id: u64,
    chain_hash: u64,
) -> Result<RelayBlob, String> {
    match origin_chain_id {
        id if is_evm_relay_chain(id) => evm_blob_from_step(step, id, chain_hash),
        RELAY_SOL_CHAIN_ID => {
            let raw = step
                .instructions
                .ok_or_else(|| "relay Solana tx missing instructions".to_string())?;
            let wire: Vec<RelaySvmInstructionWire> =
                serde_json::from_value(raw).map_err(|e| e.to_string())?;
            let mut instructions = Vec::with_capacity(wire.len());
            for w in wire {
                instructions.push(Instruction::try_from(w)?);
            }
            Ok(RelayBlob {
                source: RelaySource::Svm {
                    instructions,
                    lookup_table_addresses: step.address_lookup_table_addresses.unwrap_or_default(),
                },
                chain_hash,
            })
        }
        RELAY_BTC_CHAIN_ID => {
            // Deposit-address flow: the unique address is required for attribution;
            // the PSBT (when present) is kept only as auxiliary data.
            let psbt = step.psbt.unwrap_or_default();
            let deposit_address = deposit_address.filter(|v| !v.is_empty()).ok_or_else(|| {
                eprintln!("[btc-relay] step missing depositAddress (useDepositAddress flow)");
                "relay Bitcoin quote missing depositAddress".to_string()
            })?;
            eprintln!(
                "[btc-relay] step deposit_address={deposit_address} psbt_len={}",
                psbt.len(),
            );
            Ok(RelayBlob {
                source: RelaySource::Btc {
                    psbt,
                    deposit_address,
                },
                chain_hash,
            })
        }
        RELAY_TRON_CHAIN_ID => tron_blob_from_step(step, chain_hash),
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
    TransactionRequest::Ethereum((
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
    .try_into()
    .map_err(|e: zilpay::errors::tx::TransactionErrors| e.to_string())
}

#[frb(ignore)]
pub async fn relay_quote_info(
    origin_meta: &RelayMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
) -> Result<ProviderQuote, String> {
    let destination_meta = to
        .relay_meta()
        .ok_or_else(|| "destination is not a Relay asset".to_string())?;
    let is_btc_origin = origin_meta.common.chain_id == RELAY_BTC_CHAIN_ID;
    let req = QuoteRequest {
        user: origin_meta.common.account_addr.as_str(),
        recipient: destination_meta.common.account_addr.as_str(),
        origin_chain_id: origin_meta.common.chain_id,
        destination_chain_id: destination_meta.common.chain_id,
        origin_currency: relay_currency(from, origin_meta.common.chain_id),
        destination_currency: relay_currency(to, destination_meta.common.chain_id),
        amount,
        trade_type: "EXACT_INPUT",
        app_fees: [AppFee {
            recipient: FEE_RECIPIENT,
            fee: FEE_BIPS,
        }],
        use_deposit_address: is_btc_origin,
        refund_to: is_btc_origin.then_some(origin_meta.common.account_addr.as_str()),
    };
    if is_btc_origin {
        eprintln!(
            "[btc-relay] quote_info user={} refund_to={:?} use_deposit_address={} amount={amount}",
            req.user, req.refund_to, req.use_deposit_address,
        );
    }
    let quote = relay_post::<QuoteResponse>("/quote", &req).await?;
    let amount_out = quote.details.currency_out.amount;
    if amount_out.is_empty() {
        return Err("relay quote missing amount out".to_string());
    }

    Ok(ProviderQuote {
        amount_out,
        permit_typed_data_json: None,
        is_wrap_unwrap: false,
    })
}

#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub async fn relay_check_approval(
    swapper: &str,
    chain_hash: u64,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
    approve_title: String,
    provider_icon: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    if let Ok(origin_chain_id) = evm_origin_chain_id(from) {
        let swapper = Address::from_str(swapper).map_err(|e| e.to_string())?;
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

        return Ok(Some(
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
            .try_into()
            .map_err(|e: zilpay::errors::tx::TransactionErrors| e.to_string())?,
        ));
    }

    if from.token.addr_type == 4 && !from.token.native {
        return tron_relay_check_approval(
            swapper,
            chain_hash,
            from,
            to,
            amount,
            approve_title,
            provider_icon,
        )
        .await;
    }

    Ok(None)
}

async fn tron_relay_check_approval(
    swapper: &str,
    chain_hash: u64,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
    approve_title: String,
    provider_icon: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    let (quote, _, _) = fetch_quote(from, to, amount).await?;

    // TRON steps carry calldata in the "parameter" block (tron_tx), not EVM-style to/data.
    let Some(step) = step_data_by_id(&quote, &["approve"]).filter(|step| {
        step.tron_tx
            .as_ref()
            .and_then(|p| p.get("contract_address"))
            .and_then(serde_json::Value::as_str)
            .is_some_and(|v| !v.is_empty())
    }) else {
        return Ok(None);
    };

    let param = step
        .tron_tx
        .as_ref()
        .ok_or_else(|| "approve step missing parameter".to_string())?;

    let contract_addr = param
        .get("contract_address")
        .and_then(serde_json::Value::as_str)
        .filter(|v| !v.is_empty())
        .unwrap_or_default();

    let calldata = param
        .get("data")
        .and_then(serde_json::Value::as_str)
        .unwrap_or_default();

    let call_value = param
        .get("call_value")
        .and_then(serde_json::Value::as_i64)
        .unwrap_or(0)
        .to_string();

    crate::api::exchange::tron::finalize_tron_relay(
        swapper,
        chain_hash,
        contract_addr,
        calldata,
        &call_value,
        RelayDisplay {
            swap_title: approve_title,
            swap_info: String::new(),
            icon: provider_icon,
            out_token: None,
        },
    )
    .await
    .map(Some)
}

#[frb(ignore)]
pub async fn relay_prepare_swap(
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
) -> Result<PreparedSwap, String> {
    match RelayOrigin::from_addr_type(from.token.addr_type) {
        None => return Err("Relay origin address type is not supported".to_string()),
        Some(RelayOrigin::Btc)
        | Some(RelayOrigin::Evm)
        | Some(RelayOrigin::Svm)
        | Some(RelayOrigin::Tron) => {}
    }
    let origin_chain_id = relay_origin_chain_id(from)?;
    let (quote, _, _) = fetch_quote(from, to, amount).await?;
    let (step, deposit_address) =
        swap_step_data_owned(quote).ok_or_else(|| "relay quote missing swap step".to_string())?;
    let blob = blob_from_step(
        step,
        deposit_address,
        origin_chain_id,
        from.token.chain_hash,
    )?;

    Ok(PreparedSwap {
        permit_typed_data_json: None,
        quote_blob: serde_json::to_string(&blob).map_err(|e| e.to_string())?,
    })
}

#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub async fn relay_finalize_swap(
    quote_blob: &str,
    account_addr: &str,
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
            let swapper = Address::from_str(account_addr).map_err(|e| e.to_string())?;
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
            with_display(
                tx,
                chain_hash,
                swap_title,
                swap_info,
                provider_icon,
                out_token,
            )
        }
        RelaySource::Svm {
            instructions,
            lookup_table_addresses,
        } => {
            finalize_svm_relay(
                account_addr,
                chain_hash,
                &instructions,
                &lookup_table_addresses,
                RelayDisplay {
                    swap_title,
                    swap_info,
                    icon: provider_icon,
                    out_token,
                },
            )
            .await
        }
        RelaySource::Btc { .. } => {
            Err("BTC-origin swaps are executed out-of-band via execute_exchange_swap".to_string())
        }
        RelaySource::Tron { to, data, value } => {
            crate::api::exchange::tron::finalize_tron_relay(
                account_addr,
                chain_hash,
                &to,
                &data,
                &value,
                RelayDisplay {
                    swap_title,
                    swap_info,
                    icon: provider_icon,
                    out_token,
                },
            )
            .await
        }
    }
}

/// Build and return a Solana `TransactionRequestInfo` for a Relay SVM-origin swap.
///
/// Fetches the latest blockhash and resolves any address lookup tables via the
/// Solana provider, then delegates message construction to the core builder.
async fn finalize_svm_relay(
    payer_addr: &str,
    chain_hash: u64,
    instructions: &[Instruction],
    lookup_table_addresses: &[String],
    display: RelayDisplay,
) -> Result<TransactionRequestInfo, String> {
    let payer = Pubkey::from_str(payer_addr).map_err(|e| e.to_string())?;

    let mut pubkey_tables = Vec::with_capacity(lookup_table_addresses.len());
    for addr in lookup_table_addresses {
        pubkey_tables.push(Pubkey::from_str(addr.as_str()).map_err(|e| e.to_string())?);
    }

    let core = crate::utils::helpers::handle()
        .map_err(|e| e.to_string())?;
    let provider = core.get_provider(chain_hash).map_err(|e| e.to_string())?;

    let message = provider
        .solana_build_message(SolanaMessageBuild {
            payer: &payer,
            instructions,
            lookup_table_addresses: &pubkey_tables,
        })
        .await
        .map_err(|e| e.to_string())?;

    let token_info = display.out_token.and_then(|t| {
        U256::from_str(&t.value)
            .ok()
            .map(|value| (value, t.decimals, t.symbol))
    });

    TransactionRequest::Solana((
        SolanaTransaction { message },
        TransactionMetadata {
            chain_hash,
            broadcast: true,
            title: Some(display.swap_title),
            info: Some(display.swap_info),
            icon: Some(display.icon),
            token_info,
            ..Default::default()
        },
    ))
    .try_into()
    .map_err(|e: zilpay::errors::tx::TransactionErrors| e.to_string())
}

// ============================================================================
// Eager support gate — data-driven token support via GET /chains.
//
// Relay returns a `tokenSupport` field per chain ("All" | "Limited"). On "All" chains every
// token with solver/DEX liquidity is bridgeable, so liquidity is decided lazily at quote time and
// the gate never prunes. On "Limited" chains only the listed currencies flagged
// `supportsBridging: true` are bridgeable — everything else is pruned at load time. This makes
// Relay an eager gate symmetric with Plunder/SunSwap, fed by one cached /chains fetch. The
// hardcoded TRX branch is gone: native TRX is pruned because TRON is "Limited" and TRX isn't a
// bridgeable currency.
// ============================================================================

/// Per-chain bridging support distilled from GET /chains.
#[frb(ignore)]
struct ChainSupport {
    /// `tokenSupport == "All"`: every token with liquidity is bridgeable → never prune at load
    /// time. When `true`, `bridgeable` is left empty (not built) to save allocations.
    supports_all: bool,
    /// Canonicalized bridgeable currency addresses. Consulted only when `!supports_all`.
    bridgeable: HashSet<String>,
}

type SupportMatrix = HashMap<u64, ChainSupport>;

#[frb(ignore)]
struct CachedMatrix {
    fetched_at: Instant,
    matrix: Arc<SupportMatrix>,
}

/// Process-wide, lock-free cache. One GET /chains feeds every validate; mirrors the `CORE`
/// pattern (`service/background.rs`). `const_empty()` allows static init with no `Lazy`.
static RELAY_SUPPORT: ArcSwapOption<CachedMatrix> = ArcSwapOption::const_empty();

/// Return a fresh-or-stale support matrix. Fast path: a load-full of the cache when within TTL.
/// On miss/stale: fetch + rebuild + publish. On fetch error: serve the last good matrix if any,
/// else `None` (caller fails open → prunes nothing).
#[frb(ignore)]
async fn support_matrix() -> Option<Arc<SupportMatrix>> {
    if let Some(cached) = RELAY_SUPPORT.load_full() {
        if cached.fetched_at.elapsed() < RELAY_SUPPORT_TTL {
            return Some(Arc::clone(&cached.matrix));
        }
    }
    match fetch_chains().await {
        Ok(resp) => {
            let matrix = Arc::new(build_matrix(resp));
            RELAY_SUPPORT.store(Some(Arc::new(CachedMatrix {
                fetched_at: Instant::now(),
                matrix: Arc::clone(&matrix),
            })));
            Some(matrix)
        }
        Err(err) => {
            eprintln!("[exchange-validate] Relay /chains fetch failed: {err}");
            RELAY_SUPPORT.load_full().map(|c| Arc::clone(&c.matrix)) // stale-but-usable
        }
    }
}

#[frb(ignore)]
#[derive(Deserialize)]
#[serde(crate = "zilpay::serde")]
struct ChainsResponse {
    chains: Vec<ChainEntry>,
}

#[frb(ignore)]
#[derive(Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct ChainEntry {
    id: u64,
    token_support: Option<String>,
    /// Relay VM family: "evm" | "svm" | "bvm" | "tvm" | "lvm". Source of address family —
    /// never guess from chain id (unknown chains would be mis-canonicalized as EVM).
    vm_type: Option<String>,
    currency: Option<ChainCurrency>,
    erc20_currencies: Option<Vec<ChainCurrency>>,
}

#[frb(ignore)]
#[derive(Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct ChainCurrency {
    address: String,
    supports_bridging: Option<bool>,
}

/// GET /chains via the shared `relay_client()` (same client as /quote). Iterates `RELAY_BASE_URLS`
/// — no hardcoded URLs.
#[frb(ignore)]
async fn fetch_chains() -> Result<ChainsResponse, String> {
    let client = relay_client();
    let mut last_err = String::new();
    for base in RELAY_BASE_URLS {
        let url = format!("{base}/chains");
        let resp = client
            .get(&url)
            .timeout(Duration::from_secs(10))
            .send()
            .await;
        match resp {
            Ok(r) if r.status().is_success() => {
                let body = r.text().await.map_err(|e| format!("{url}: body {e}"))?;
                return serde_json::from_str::<ChainsResponse>(&body)
                    .map_err(|e| format!("{url}: decode {e}"));
            }
            Ok(r) => {
                let status = r.status();
                let body = r.text().await.unwrap_or_default();
                last_err = format!("{url}: {status}: {body}");
            }
            Err(e) => last_err = format!("{url}: {e}"),
        }
    }
    Err(format!("relay /chains failed: {last_err}"))
}

/// Address family (matches our `addr_type`: 1 EVM, 2 BTC, 3 SOL, 4 TRON) from Relay's `vmType`.
/// Returns `None` for VM families we don't support — those chains are skipped at matrix build,
/// so their addresses are never (mis-)canonicalized. No chain-id guessing, no EVM default.
#[frb(ignore)]
fn relay_addr_family(vm_type: Option<&str>) -> Option<u8> {
    match vm_type? {
        "evm" => Some(1),
        "bvm" => Some(2),
        "svm" => Some(3),
        "tvm" => Some(4),
        _ => None, // lvm / future families: not supported here
    }
}

/// Canonical comparable key for a currency address. Applied identically to matrix entries and to
/// the asset's `relay_currency`, so string equality is robust to format quirks:
/// - EVM: lowercase (Relay returns lowercase hex; our `auto_format()` is EIP-55 checksummed).
/// - TRON: parse base58 OR hex → canonical base58, so it matches whichever form Relay returns.
/// - BTC (bech32, lowercase) / SOL (base58, case-significant): compared as-is.
#[frb(ignore)]
fn canonical_currency(family: u8, addr: &str) -> Option<Cow<'_, str>> {
    match family {
        1 => Some(Cow::Owned(addr.to_ascii_lowercase())),
        4 => ProtoAddress::from_tron_address(addr)
            .or_else(|_| ProtoAddress::from_str_hex(addr))
            .ok()
            .map(|a| Cow::Owned(a.auto_format())),
        _ => Some(Cow::Borrowed(addr)),
    }
}

#[frb(ignore)]
fn build_matrix(resp: ChainsResponse) -> SupportMatrix {
    let mut matrix = HashMap::with_capacity(resp.chains.len());
    for chain in resp.chains {
        // Skip families we can't canonicalize — never queried, and guarantees no mis-lowercased
        // base58 key leaks into the matrix.
        let Some(family) = relay_addr_family(chain.vm_type.as_deref()) else {
            continue;
        };
        // PERMISSIVE DEFAULT: only an explicit "Limited" enables pruning. A missing/renamed
        // tokenSupport must never strip tokens (fail-open on schema drift).
        let supports_all = chain.token_support.as_deref() != Some("Limited");
        let mut bridgeable = HashSet::new();
        if !supports_all {
            // Native + erc20 currencies flagged supportsBridging, canonicalized.
            let entries = chain
                .currency
                .into_iter()
                .chain(chain.erc20_currencies.unwrap_or_default());
            for c in entries {
                if c.supports_bridging.unwrap_or(false) {
                    if let Some(key) = canonical_currency(family, &c.address) {
                        bridgeable.insert(key.into_owned());
                    }
                }
            }
        }
        matrix.insert(
            chain.id,
            ChainSupport {
                supports_all,
                bridgeable,
            },
        );
    }
    matrix
}

/// Returns indices of `assets` whose Relay route is NOT supported per GET /chains. Reuses
/// `relay_currency` (single source of truth for the address Relay sees) + `relay_meta`. Fail-open:
/// on fetch failure with no cache, prunes nothing (lazy /quote still catches dead routes).
#[frb(ignore)]
pub(in crate::models::exchange) async fn evaluate_support_eager(
    assets: &[ExchangeAsset],
) -> Vec<usize> {
    // The /chains matrix is mainnet-only (RELAY_BASE_URLS[0]); skip on testnet so a mainnet matrix
    // is never applied to testnet assets. Kept inside the gate — the orchestrator stays generic.
    if relay_assets_are_testnet(assets) {
        return Vec::new();
    }
    let Some(matrix) = support_matrix().await else {
        return Vec::new();
    };
    assets
        .iter()
        .enumerate()
        .filter_map(|(idx, asset)| {
            let meta = asset.relay_meta()?;                  // not a Relay asset → skip
            let chain = matrix.get(&meta.common.chain_id)?;   // chain absent → keep (fail-open)
            if chain.supports_all {
                return None;                                  // liquidity decided lazily
            }
            let currency = relay_currency(asset, meta.common.chain_id);
            let key = canonical_currency(asset.token.addr_type, currency.as_ref())?;
            (!chain.bridgeable.contains(key.as_ref())).then_some(idx)
        })
        .collect()
}

/// True when the (network-uniform) asset set is on testnet. Bootstrap filters by
/// `current_is_testnet`, so the first Relay asset's chain decides for the whole set — one
/// `handle()` + one provider lookup, not per-asset.
#[frb(ignore)]
fn relay_assets_are_testnet(assets: &[ExchangeAsset]) -> bool {
    let Ok(core) = crate::utils::helpers::handle() else {
        return false;
    };
    assets
        .iter()
        .find_map(|asset| asset.relay_meta())
        .and_then(|meta| core.get_provider(meta.common.chain_hash).ok())
        .map(|provider| provider.config.testnet.unwrap_or(false))
        .unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn relay_meta_known_and_unknown() {
        assert_eq!(
            RelayMeta::for_chain(42, 1, 1, "0x0000000000000000000000000000000000000001")
                .map(|m| m.common.chain_id),
            Some(1)
        );
        assert_eq!(
            RelayMeta::for_chain(43, 3, 101, "11111111111111111111111111111111")
                .map(|m| m.common.chain_id),
            Some(RELAY_SOL_CHAIN_ID)
        );
        assert_eq!(
            RelayMeta::for_chain(44, 1, 11_155_111, "0x0000000000000000000000000000000000000001"),
            None
        );
        // Native TRX now ALSO receives a Relay provider at this layer — whether it is bridgeable
        // is decided by the support gate (evaluate_support_eager) from GET /chains, not here.
        // See `matrix_limited_prunes_unlisted_tron_token` for the data-driven prune.
        assert!(RelayMeta::for_chain(
            46,
            4,
            RELAY_TRON_CHAIN_ID,
            "T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb"
        )
        .is_some());
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
        let (step, deposit_address) =
            swap_step_data_owned(quote).ok_or_else(|| "missing swap step".to_string())?;
        assert_eq!(deposit_address, None);
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

    #[test]
    fn svm_wire_account_converts_to_account_meta() {
        let wire = RelaySvmAccountWire {
            pubkey: "11111111111111111111111111111111".to_string(),
            is_signer: true,
            is_writable: false,
        };
        let meta = AccountMeta::try_from(wire).unwrap();
        assert!(meta.is_signer);
        assert!(!meta.is_writable);
    }

    #[test]
    fn svm_wire_instruction_converts() {
        let wire = RelaySvmInstructionWire {
            program_id: "11111111111111111111111111111111".to_string(),
            keys: vec![RelaySvmAccountWire {
                pubkey: "11111111111111111111111111111111".to_string(),
                is_signer: false,
                is_writable: true,
            }],
            data: "0x02000000".to_string(),
        };
        let ix = Instruction::try_from(wire).unwrap();
        assert_eq!(ix.accounts.len(), 1);
        assert_eq!(ix.data, [2, 0, 0, 0]);
    }

    #[test]
    fn relay_blob_svm_round_trip() -> Result<(), String> {
        use zilpay::solana_pubkey::Pubkey;
        let ix = Instruction {
            program_id: Pubkey::default(),
            accounts: vec![],
            data: vec![1, 2, 3],
        };
        let blob = RelayBlob {
            source: RelaySource::Svm {
                instructions: vec![ix],
                lookup_table_addresses: vec![],
            },
            chain_hash: 99,
        };
        let json = serde_json::to_string(&blob).map_err(|e| e.to_string())?;
        let decoded: RelayBlob = serde_json::from_str(&json).map_err(|e| e.to_string())?;
        assert_eq!(decoded, blob);
        Ok(())
    }

    #[test]
    fn relay_origin_addr_type_classification() {
        assert_eq!(RelayOrigin::from_addr_type(1), Some(RelayOrigin::Evm));
        assert_eq!(RelayOrigin::from_addr_type(3), Some(RelayOrigin::Svm));
        assert_eq!(RelayOrigin::from_addr_type(2), Some(RelayOrigin::Btc));
        assert_eq!(RelayOrigin::from_addr_type(4), Some(RelayOrigin::Tron));
        assert_eq!(RelayOrigin::from_addr_type(0), None);
    }

    #[test]
    fn matrix_limited_prunes_unlisted_tron_token() {
        // TRON is tokenSupport "Limited": native TRX is supportsBridging:false, USDT is true.
        // Any unlisted token (e.g. A7A5) is pruned purely from data — no hardcoded branch.
        let resp = serde_json::from_str::<ChainsResponse>(r#"{"chains":[
          {"id":728126428,"tokenSupport":"Limited","vmType":"tvm",
           "currency":{"address":"T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb","supportsBridging":false},
           "erc20Currencies":[{"address":"TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t","supportsBridging":true}]}
        ]}"#).unwrap();
        let m = build_matrix(resp);
        let tron = m.get(&RELAY_TRON_CHAIN_ID).unwrap();
        assert!(!tron.supports_all);
        let usdt = canonical_currency(4, "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t").unwrap();
        assert!(tron.bridgeable.contains(usdt.as_ref()));      // USDT kept
        // Native TRX is not bridgeable → not in the bridgeable set → would be pruned by the gate.
        let trx = canonical_currency(4, "T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb").unwrap();
        assert!(!tron.bridgeable.contains(trx.as_ref()));
    }

    #[test]
    fn matrix_all_keeps_unflagged_token() {
        // On an "All" chain a currency with supportsBridging:false (WBTC on Optimism) is still
        // bridgeable — the bridgeable set is intentionally NOT built, so nothing is pruned.
        let resp = serde_json::from_str::<ChainsResponse>(r#"{"chains":[
          {"id":10,"tokenSupport":"All","vmType":"evm",
           "currency":{"address":"0x0000000000000000000000000000000000000000","supportsBridging":true},
           "erc20Currencies":[{"address":"0x68f180fcce6836688e9084f035309e29bf0a2095","supportsBridging":false}]}
        ]}"#).unwrap();
        let m = build_matrix(resp);
        let op = m.get(&10).unwrap();
        assert!(op.supports_all);
        assert!(op.bridgeable.is_empty());
    }

    #[test]
    fn canonical_evm_lowercases() {
        assert_eq!(canonical_currency(1, "0xABCdef").unwrap(), "0xabcdef");
    }

    #[test]
    fn matrix_missing_token_support_defaults_permissive() {
        // A chain with no tokenSupport field must NOT prune (fail-open on schema drift).
        let resp = serde_json::from_str::<ChainsResponse>(r#"{"chains":[
          {"id":1,"vmType":"evm",
           "currency":{"address":"0x0000000000000000000000000000000000000000","supportsBridging":true}}
        ]}"#).unwrap();
        let m = build_matrix(resp);
        assert!(m.get(&1).unwrap().supports_all);
    }

    #[test]
    fn matrix_skips_unknown_vm_family() {
        // Unknown/absent vmType → chain skipped, so its addresses never enter the matrix and we
        // never apply EVM lowercasing to a base58 address.
        let resp = serde_json::from_str::<ChainsResponse>(r#"{"chains":[
          {"id":1399811149,"tokenSupport":"Limited","vmType":"lvm",
           "currency":{"address":"So11111111111111111111111111111111111111112","supportsBridging":true}}
        ]}"#).unwrap();
        assert!(build_matrix(resp).is_empty());
    }
}
