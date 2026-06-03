use std::time::Duration;

use flutter_rust_bridge::frb;
use zilpay::crypto::slip44::{BITCOIN, ETHEREUM, SOLANA, TRON};
use zilpay::reqwest;
use zilpay::serde::de::DeserializeOwned;
use zilpay::serde::{Deserialize, Serialize};
use zilpay::serde_json;

/// Public thornode REST mirrors, tried in order. `thornode.thorchain.network` is kept first —
/// `thornode.ninerealms.com` failed DNS in testing.
const THORCHAIN_BASE_URLS: &[&str] = &[
    "https://thornode.thorchain.network",
    "https://gateway.liquify.com/chain/thorchain_api",
    "https://thornode.ninerealms.com",
    "https://thornode.thorswap.net",
    "https://thornode-v2.ninerealms.com",
    "https://thornode.liquify.com",
];

/// THORChain settles every amount in 1e8 fixed-point regardless of the native asset's own
/// decimals, so quote inputs/outputs must be rescaled at the FFI boundary.
const THOR_DECIMALS: u8 = 8;

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct InboundAddressRaw {
    #[serde(default)]
    pub chain: String,
    #[serde(default)]
    pub pub_key: String,
    #[serde(default)]
    pub address: String,
    #[serde(default)]
    pub router: String,
    #[serde(default)]
    pub halted: bool,
    #[serde(default)]
    pub global_trading_paused: bool,
    #[serde(default)]
    pub chain_trading_paused: bool,
    #[serde(default)]
    pub chain_lp_actions_paused: bool,
    #[serde(default)]
    pub observed_fee_rate: String,
    #[serde(default)]
    pub gas_rate: String,
    #[serde(default)]
    pub gas_rate_units: String,
    #[serde(default)]
    pub outbound_tx_size: String,
    #[serde(default)]
    pub outbound_fee: String,
    #[serde(default)]
    pub dust_threshold: String,
}

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct QuoteSwapRaw {
    #[serde(default)]
    pub inbound_address: String,
    #[serde(default)]
    pub inbound_confirmation_blocks: i64,
    #[serde(default)]
    pub inbound_confirmation_seconds: i64,
    #[serde(default)]
    pub outbound_delay_blocks: i64,
    #[serde(default)]
    pub outbound_delay_seconds: i64,
    #[serde(default)]
    pub fees: QuoteFeesRaw,
    #[serde(default)]
    pub router: String,
    #[serde(default)]
    pub expiry: i64,
    #[serde(default)]
    pub warning: String,
    #[serde(default)]
    pub notes: String,
    #[serde(default)]
    pub dust_threshold: String,
    #[serde(default)]
    pub recommended_min_amount_in: String,
    #[serde(default)]
    pub recommended_gas_rate: String,
    #[serde(default)]
    pub gas_rate_units: String,
    #[serde(default)]
    pub memo: String,
    #[serde(default)]
    pub expected_amount_out: String,
    #[serde(default)]
    pub max_streaming_quantity: i64,
    #[serde(default)]
    pub streaming_swap_blocks: i64,
    #[serde(default)]
    pub streaming_swap_seconds: i64,
    #[serde(default)]
    pub total_swap_seconds: i64,
}

#[frb(ignore)]
#[derive(Debug, Default, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct QuoteFeesRaw {
    #[serde(default)]
    pub asset: String,
    #[serde(default)]
    pub affiliate: String,
    #[serde(default)]
    pub outbound: String,
    #[serde(default)]
    pub liquidity: String,
    #[serde(default)]
    pub total: String,
    #[serde(default)]
    pub slippage_bps: i64,
    #[serde(default)]
    pub total_bps: i64,
}

#[frb(ignore)]
#[derive(Debug, Default)]
pub struct ThorchainInbound {
    pub chain: String,
    pub address: String,
    pub router: String,
    pub halted: bool,
    pub global_trading_paused: bool,
    pub chain_trading_paused: bool,
    pub gas_rate: String,
    pub gas_rate_units: String,
    pub outbound_fee: String,
    pub dust_threshold: String,
}

/// GET a thornode REST endpoint, walking [`THORCHAIN_BASE_URLS`] until one returns a 2xx body
/// that deserializes into `T`. Bodies are parsed via `serde_json` (not reqwest's `json` feature)
/// to stay on the same serde the `#[serde(crate = "zilpay::serde")]` models derive against.
#[frb(ignore)]
pub async fn thorchain_get<T: DeserializeOwned>(
    path: &str,
    query: &[(&str, &str)],
) -> Result<T, String> {
    let client = reqwest::Client::new();
    let mut last_err = String::new();
    // Prefer the FIRST real HTTP-level error (which carries thornode's reason, e.g. a 5xx body
    // saying "trading is halted") over transport failures from later dead fallback URLs — those
    // would otherwise overwrite and mask the actual cause.
    let mut have_http_err = false;

    for base in THORCHAIN_BASE_URLS {
        let url = format!("{base}{path}");
        let resp = client
            .get(&url)
            .query(query)
            .header("x-client-id", "bearby")
            .timeout(Duration::from_secs(10))
            .send()
            .await;

        match resp {
            Ok(r) if r.status().is_success() => match r.text().await {
                Ok(body) => match serde_json::from_str::<T>(&body) {
                    Ok(value) => return Ok(value),
                    Err(e) => {
                        last_err = format!("{url}: decode {e}");
                        have_http_err = true;
                    }
                },
                Err(e) => {
                    last_err = format!("{url}: body {e}");
                    have_http_err = true;
                }
            },
            // Non-2xx: the body carries thornode's actual reason; keep the first one seen.
            Ok(r) => {
                if !have_http_err {
                    let status = r.status();
                    let body = r.text().await.unwrap_or_default();
                    last_err = format!("{url}: status {status}: {body}");
                    have_http_err = true;
                }
            }
            // Transport failure (DNS/TLS/timeout) — only record if no real HTTP error seen yet.
            Err(e) => {
                if !have_http_err {
                    last_err = format!("{url}: {e}");
                }
            }
        }
    }

    Err(format!("all thornode urls failed: {last_err}"))
}

/// Map a Bearby chain to its THORChain chain identifier — **mainnet only**. The `(slip44, chain_id)`
/// pairs are exact so testnets and non-THORChain EVM chains (Arbitrum, Polygon, Optimism, …) resolve
/// to `None`. `None` means "not a THORChain chain".
#[frb(ignore)]
pub const fn thorchain_chain_name(slip44: u32, chain_id: u64) -> Option<&'static str> {
    match (slip44, chain_id) {
        (ETHEREUM, 1) => Some("ETH"),
        (ETHEREUM, 56) => Some("BSC"),
        (ETHEREUM, 43114) => Some("AVAX"),
        (ETHEREUM, 8453) => Some("BASE"),
        (BITCOIN, 0) => Some("BTC"),
        (TRON, 728_126_428) => Some("TRON"),
        (SOLANA, 101) => Some("SOL"),
        _ => None,
    }
}

/// Build a THORChain asset identifier: native is `CHAIN.SYMBOL` (e.g. `ETH.ETH`, `BTC.BTC`),
/// an EVM token is `CHAIN.SYMBOL-0xADDRESS` (e.g. `ETH.USDC-0xa0b8...`). The address keeps its
/// `0x` prefix; THORChain matches it case-insensitively.
#[frb(ignore)]
pub fn thorchain_asset_id(chain: &str, symbol: &str, addr: &str, is_native: bool) -> String {
    if is_native {
        let mut id = String::with_capacity(chain.len() + 1 + symbol.len());
        id.push_str(chain);
        id.push('.');
        id.push_str(symbol);
        id
    } else {
        let mut id = String::with_capacity(chain.len() + symbol.len() + addr.len() + 2);
        id.push_str(chain);
        id.push('.');
        id.push_str(symbol);
        id.push('-');
        id.push_str(addr);
        id
    }
}

/// FFI-safe THORChain provider metadata, populated per token in `bootstrap_exchange_providers`
/// (mirrors [`super::UniswapMeta`]). Carries the asset's resolved THORChain identity so the
/// quote/swap engine never re-derives it: the `chain` id (e.g. `ETH`, `BSC`, `BTC`), the full
/// `asset` id (e.g. `ETH.USDC-0x…`, `BTC.BTC`), and the EVM `chain_id` (`0` for non-EVM source).
#[derive(Debug, Default, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct ThorchainMeta {
    pub chain: String,
    pub asset: String,
    pub chain_id: u64,
}

impl ThorchainMeta {
    /// Resolve a token's THORChain identity, or `None` if its chain isn't a THORChain chain.
    /// Whether to actually attach the provider is decided by pool membership at the call site.
    #[frb(ignore)]
    pub fn for_token(
        slip44: u32,
        chain_id: u64,
        symbol: &str,
        addr: &str,
        native: bool,
    ) -> Option<Self> {
        let chain = thorchain_chain_name(slip44, chain_id)?;
        Some(Self {
            chain: chain.to_string(),
            asset: thorchain_asset_id(chain, symbol, addr, native),
            chain_id,
        })
    }
}

/// Rescale `amount` (a base-unit integer string in `decimals`) into THORChain's 1e8 fixed point.
/// Larger source decimals divide down; smaller multiply up. Returns the scaled integer as a string.
#[frb(ignore)]
pub fn to_thor_amount(amount: &str, decimals: u8) -> Result<String, String> {
    rescale(amount, decimals, THOR_DECIMALS)
}

/// Inverse of [`to_thor_amount`]: bring a 1e8 THORChain amount back to the asset's own `decimals`.
#[frb(ignore)]
pub fn from_thor_amount(amount: &str, decimals: u8) -> Result<String, String> {
    rescale(amount, THOR_DECIMALS, decimals)
}

/// Integer rescale of a base-unit string between two decimal precisions, panic-free via `U256`.
fn rescale(amount: &str, from_dec: u8, to_dec: u8) -> Result<String, String> {
    use zilpay::proto::U256;
    use std::str::FromStr;

    let value = U256::from_str(amount.trim()).map_err(|e| e.to_string())?;
    let scaled = if to_dec >= from_dec {
        let factor = U256::from(10u64).pow(U256::from(to_dec - from_dec));
        value.saturating_mul(factor)
    } else {
        let factor = U256::from(10u64).pow(U256::from(from_dec - to_dec));
        value / factor
    };
    Ok(scaled.to_string())
}

/// Source-chain shape of a prepared swap — drives which transaction `thorchain_finalize_swap`
/// builds. EVM goes through `router.depositWithExpiry`; BTC is a native send + OP_RETURN memo.
#[frb(ignore)]
#[derive(Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub enum ThorchainSource {
    Evm {
        chain_id: u64,
        router: String,
        /// ERC-20 contract for token inputs; empty for native (asset `0x0`).
        asset_addr: String,
        is_native: bool,
    },
    Btc {
        /// sats-per-vbyte fee rate from the inbound `gas_rate`.
        fee_rate: u64,
    },
}

/// Opaque blob serialized into `quote_blob`, carrying everything `thorchain_finalize_swap` needs to
/// rebuild the deposit tx without re-resolving the quote. The UI never inspects it.
#[frb(ignore)]
#[derive(Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct ThorchainBlob {
    pub source: ThorchainSource,
    pub chain_hash: u64,
    /// Vault inbound address funds settle to.
    pub vault: String,
    /// Server-generated routing memo.
    pub memo: String,
    /// Deposit amount in the source asset's own base units (wei / satoshi).
    pub amount: String,
    /// Unix expiry from the quote (EVM `depositWithExpiry` guard).
    pub expiry: i64,
}

// ---------------------------------------------------------------------------
// Swap engine — REST quote + deposit-tx builders. All `#[frb(ignore)]`; alloy types stay internal.
// ---------------------------------------------------------------------------

use std::str::FromStr;

use zilpay::alloy::hex;
use zilpay::alloy::primitives::{Address, U256};
use zilpay::alloy::sol_types::SolCall;
use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::proto::tx::{ETHTransactionRequest, TransactionMetadata, TransactionRequest};
use zilpay::proto::AlloyTxKind;
use zilpay::rpc::{
    common::JsonRPC, methods::EvmMethods, network_config::ChainConfig, provider::RpcProvider,
    zil_interfaces::ResultRes,
};
use zilpay::serde_json::{json, Value};

use super::{ExchangeAsset, ExchangeProvider, ExchangeQuoteInfo};
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::request::TransactionRequestInfo;
use crate::utils::errors::ServiceError;
use crate::utils::helpers::with_service;

/// Conservative starting gas for an EVM `depositWithExpiry`; `apply_swap_gas_limit` refines it from
/// a live estimate. ERC-20 deposits (transfer + event) sit well under this.
const DEFAULT_THOR_DEPOSIT_GAS: u64 = 250_000;
const DEFAULT_THOR_APPROVE_GAS: u64 = 60_000;

mod sol_types {
    use zilpay::alloy::sol;

    sol! {
        function depositWithExpiry(address vault, address asset, uint256 amount, string memo, uint256 expiry) external payable;
        function approve(address spender, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
    }
}

use sol_types::{allowanceCall, approveCall, depositWithExpiryCall};

/// `(slip44, chain_id)` for a chain hash, via the active service.
async fn chain_ctx(chain_hash: u64) -> Result<(u32, u64), String> {
    with_service(|core| {
        let p = core
            .get_provider(chain_hash)
            .map_err(ServiceError::BackgroundError)?;
        Ok((p.config.slip_44, p.config.chain_id()))
    })
    .await
    .map_err(|e: ServiceError| e.to_string())
}

/// THORChain tradeable pool asset ids (lower-cased). These are the `Available` pools from
/// `GET /thorchain/pools` — stable enough to hardcode. Used as a gate: a token only gets the
/// Thorchain provider if its resolved asset id matches a pool below.
#[frb(ignore)]
pub const THORCHAIN_POOLS: &[&str] = &[
    "eth.link-0x514910771af9ca656af840dff83e8264ecf986ca",
    "bsc.btcb-0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c",
    "sol.sol",
    "bsc.busd-0xe9e7cea3dedca5984780bafc599bd69add087d56",
    "eth.dai-0x6b175474e89094c44da98b954eedeac495271d0f",
    "bsc.twt-0x4b0f1812e5df2a09796481ff14017e6005508003",
    "avax.sol-0xfe6b19286885a4f7f55adad09c3cd1f906d2478f",
    "base.vvv-0xacfe6019ed1a7dc6f7b508c02d1b04ec88cc21bf",
    "ltc.ltc",
    "gaia.atom",
    "bsc.eth-0x2170ed0880ac9a755fd29b2688956bd959f933f8",
    "eth.eth",
    "bsc.usdt-0x55d398326f99059ff775485246999027b3197955",
    "avax.usdt-0x9702230a8ea53601f5cd2dc00fdbc13d4df4a8c7",
    "eth.thor-0xa5f2211b9b8170f694421f2046281775e8468044",
    "avax.usdc-0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
    "eth.gusd-0x056fd409e1d7a124bd7017459dfea2f387b6d5cd",
    "eth.aave-0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9",
    "eth.fox-0xc770eefad204b5180df6a14ee197d99d808ee52d",
    "base.eth",
    "doge.doge",
    "eth.lusd-0x5f98805a4e8be255a32880fdec7f6728c6568ba0",
    "eth.usdc-0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    "thor.ruji",
    "tron.usdt-tr7nhqjekqxgtci8q8zy4pl8otszgjlj6t",
    "avax.avax",
    "xrp.xrp",
    "bsc.usdc-0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
    "base.usdc-0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
    "eth.vthor-0x815c23eca83261b6ec689b60cc4a58b54bc24d8d",
    "eth.usdp-0x8e870d67f660d95d5be530380d0ec0bd388289e1",
    "tron.trx",
    "eth.wbtc-0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
    "eth.xrune-0x69fa0fee221ad11012bab0fdb45d444d3d2ce71c",
    "bch.bch",
    "btc.btc",
    "eth.tgt-0x108a850856db3f85d0269a2693d896b394c80325",
    "eth.usdt-0xdac17f958d2ee523a2206206994597c13d831ec7",
    "eth.yfi-0x0bc529c00c6401aef6d220be8c6ea1667f6ad93e",
    "thor.tcy",
    "bsc.bnb",
];

/// Build a `HashSet<String>` from [`THORCHAIN_POOLS`] for O(1) membership checks.
#[frb(ignore)]
pub fn thorchain_pool_set() -> std::collections::HashSet<String> {
    let mut set = std::collections::HashSet::with_capacity(THORCHAIN_POOLS.len());
    for pool in THORCHAIN_POOLS {
        set.insert(pool.to_string());
    }
    set
}

/// Resolve the per-chain THORChain router address from `inbound_addresses`. Used by the Ledger
/// approval step, which precedes the quote (so it can't read the router off a quote response).
#[frb(ignore)]
pub async fn thorchain_router_for_chain(chain_hash: u64) -> Result<String, String> {
    let (slip44, chain_id) = chain_ctx(chain_hash).await?;
    let chain = thorchain_chain_name(slip44, chain_id)
        .ok_or_else(|| "chain not on THORChain".to_string())?;
    let inbounds = thorchain_get::<Vec<InboundAddressRaw>>("/thorchain/inbound_addresses", &[]).await?;
    inbounds
        .into_iter()
        .find(|i| i.chain == chain)
        .map(|i| i.router)
        .filter(|r| !r.is_empty())
        .ok_or_else(|| format!("no THORChain router for {chain}"))
}

/// REST `GET /thorchain/quote/swap` for the `from → to` pair. Both assets carry their resolved
/// THORChain id in their `Thorchain` provider metadata (set at bootstrap), so no chain lookup is
/// needed here. `amount` is the source asset's own base units, rescaled to THORChain's 1e8.
/// `tolerance_bps` bounds the slippage encoded into the returned memo.
async fn fetch_quote(
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
    destination: &str,
    tolerance_bps: u32,
) -> Result<QuoteSwapRaw, String> {
    let from_meta = from
        .thorchain_meta()
        .ok_or_else(|| "source is not a THORChain asset".to_string())?;
    let to_meta = to
        .thorchain_meta()
        .ok_or_else(|| "destination is not a THORChain asset".to_string())?;
    let thor_amount = to_thor_amount(amount, from.token.decimals)?;
    let tolerance = tolerance_bps.to_string();

    thorchain_get::<QuoteSwapRaw>(
        "/thorchain/quote/swap",
        &[
            ("from_asset", from_meta.asset.as_str()),
            ("to_asset", to_meta.asset.as_str()),
            ("amount", thor_amount.as_str()),
            ("destination", destination),
            ("tolerance_bps", tolerance.as_str()),
        ],
    )
    .await
}

/// Cross-chain quote: hits the REST quote endpoint and lifts the expected output back to the
/// destination asset's own decimals. Never needs Permit2 / wrap detection.
#[frb(ignore)]
pub async fn thorchain_quote_info(
    provider: &ExchangeProvider,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
    destination: &str,
    tolerance_bps: u32,
) -> Result<ExchangeQuoteInfo, String> {
    let raw = fetch_quote(from, to, amount, destination, tolerance_bps).await?;
    if !raw.warning.is_empty() {
        dbg!("thorchain_quote_info: warning", &raw.warning);
    }
    let amount_out = from_thor_amount(&raw.expected_amount_out, to.token.decimals)?;

    Ok(ExchangeQuoteInfo {
        provider: provider.clone(),
        amount_out,
        permit_typed_data_json: None,
        is_wrap_unwrap: false,
    })
}

#[frb(ignore)]
pub struct PreparedThorSwap {
    pub quote_blob: String,
}

/// Re-quote for a fresh `memo`/`expiry` and serialize the [`ThorchainBlob`]. The source chain is
/// read from the asset's `Thorchain` metadata: EVM (`chain_id != 0`) records the router + ERC-20
/// asset for `depositWithExpiry`; BTC records the fee rate for the native OP_RETURN send. Other
/// native sources aren't built yet.
#[frb(ignore)]
pub async fn thorchain_prepare_swap(
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
    destination: &str,
    tolerance_bps: u32,
) -> Result<PreparedThorSwap, String> {
    let from_meta = from
        .thorchain_meta()
        .ok_or_else(|| "source is not a THORChain asset".to_string())?;
    let raw = fetch_quote(from, to, amount, destination, tolerance_bps).await?;
    if raw.inbound_address.is_empty() || raw.memo.is_empty() {
        return Err("thorchain quote missing inbound_address/memo".to_string());
    }

    let source = if from_meta.chain_id != 0 {
        ThorchainSource::Evm {
            chain_id: from_meta.chain_id,
            router: raw.router.clone(),
            asset_addr: if from.token.native {
                String::new()
            } else {
                from.token.addr.clone()
            },
            is_native: from.token.native,
        }
    } else if from_meta.chain == "BTC" {
        ThorchainSource::Btc {
            fee_rate: raw.recommended_gas_rate.parse().unwrap_or(0),
        }
    } else {
        return Err(format!(
            "THORChain source chain {} not supported yet",
            from_meta.chain
        ));
    };

    let blob = ThorchainBlob {
        source,
        chain_hash: from.token.chain_hash,
        vault: raw.inbound_address,
        memo: raw.memo,
        amount: amount.to_string(),
        expiry: raw.expiry,
    };

    Ok(PreparedThorSwap {
        quote_blob: serde_json::to_string(&blob).map_err(|e| e.to_string())?,
    })
}

/// Deposit-specific parameters for [`build_deposit_tx`].
struct DepositParams {
    vault: Address,
    asset: Address,
    amount: U256,
    memo: String,
    expiry: i64,
    is_native: bool,
}

/// Build the EVM `router.depositWithExpiry(vault, asset, amount, memo, expiry)` deposit tx.
/// Native input → `asset = 0x0`, `value = amount`; ERC-20 → `asset = token`, `value = 0`
/// (the router pulls the token, so a prior `approve(router)` is required — see
/// [`thorchain_check_approval`]).
fn build_deposit_tx(
    router: Address,
    chain_id: u64,
    chain_hash: u64,
    from: Address,
    deposit: DepositParams,
) -> TransactionRequest {
    let data = depositWithExpiryCall {
        vault: deposit.vault,
        asset: deposit.asset,
        amount: deposit.amount,
        memo: deposit.memo,
        expiry: U256::from(deposit.expiry.max(0) as u64),
    }
    .abi_encode();

    let value = if deposit.is_native {
        deposit.amount
    } else {
        U256::ZERO
    };
    let mut tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(router)),
        from: Some(from),
        value: Some(value),
        input: data.into(),
        gas: Some(DEFAULT_THOR_DEPOSIT_GAS),
        ..Default::default()
    };
    tx.chain_id = Some(chain_id);

    TransactionRequest::Ethereum((
        tx,
        TransactionMetadata {
            chain_hash,
            broadcast: true,
            ..Default::default()
        },
    ))
}

/// Attach display metadata to a built deposit tx (mirrors the tail of `finalize_router_swap`).
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
            token_info: out_token.map(|t| {
                (
                    U256::from_str(&t.value).unwrap_or_default(),
                    t.decimals,
                    t.symbol,
                )
            }),
            ..Default::default()
        },
    ))
    .into())
}

/// Build the deposit tx from the opaque blob. EVM-source only; BTC source is built in the api layer
/// (it needs wallet UTXO access).
#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub async fn thorchain_finalize_swap(
    quote_blob: &str,
    swapper: Address,
    chain_hash: u64,
    swap_title: String,
    swap_info: String,
    provider_icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let blob: ThorchainBlob =
        serde_json::from_str(quote_blob).map_err(|e| format!("invalid quote_blob: {e}"))?;

    match blob.source {
        ThorchainSource::Evm {
            chain_id,
            router,
            asset_addr,
            is_native,
        } => {
            let router = Address::from_str(&router).map_err(|e| e.to_string())?;
            let vault = Address::from_str(&blob.vault).map_err(|e| e.to_string())?;
            let asset = if is_native {
                Address::ZERO
            } else {
                Address::from_str(&asset_addr).map_err(|e| e.to_string())?
            };
            let amount = U256::from_str(&blob.amount).map_err(|e| e.to_string())?;

            let tx = build_deposit_tx(
                router,
                chain_id,
                chain_hash,
                swapper,
                DepositParams {
                    vault,
                    asset,
                    amount,
                    memo: blob.memo,
                    expiry: blob.expiry,
                    is_native,
                },
            );
            with_display(tx, chain_hash, swap_title, swap_info, provider_icon, out_token)
        }
        ThorchainSource::Btc { .. } => {
            Err("BTC-source THORChain finalize is built in the api layer".to_string())
        }
    }
}

/// ERC-20 input only: check the token's allowance to the THORChain `router` and, if short, return
/// an unsigned `approve(router, amount)` tx. Native input never needs approval (`Ok(None)`).
/// Mirrors `router_check_approval` but the spender is the router, not Permit2 — no Permit2 anywhere.
#[allow(clippy::too_many_arguments)]
#[frb(ignore)]
pub async fn thorchain_check_approval(
    swapper: Address,
    chain_hash: u64,
    router: &str,
    token: &str,
    amount: &str,
    approve_title: String,
    provider_icon: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    let config = with_service(|core| {
        Ok(core
            .get_provider(chain_hash)
            .map_err(ServiceError::BackgroundError)?
            .config
            .clone())
    })
    .await
    .map_err(|e: ServiceError| e.to_string())?;

    let router_addr = Address::from_str(router).map_err(|e| e.to_string())?;
    let token_addr = Address::from_str(token).map_err(|e| e.to_string())?;
    let needed = U256::from_str(amount).map_err(|e| e.to_string())?;

    let call = allowanceCall {
        owner: swapper,
        spender: router_addr,
    }
    .abi_encode();
    let payload = RpcProvider::<ChainConfig>::build_payload(
        json!([{ "to": token, "data": hex::encode_prefixed(&call) }, "latest"]),
        EvmMethods::Call,
    );
    let provider: RpcProvider<ChainConfig> = RpcProvider::new(&config);
    let res = provider
        .req::<ResultRes<Value>>(payload)
        .await
        .map_err(|e| e.to_string())?;
    let current = res
        .result
        .as_ref()
        .and_then(|v| v.as_str())
        .and_then(|s| hex::decode(s).ok())
        .and_then(|b| allowanceCall::abi_decode_returns(&b).ok())
        .unwrap_or(U256::ZERO);

    if current >= needed {
        return Ok(None);
    }

    let data = approveCall {
        spender: router_addr,
        amount: U256::MAX,
    }
    .abi_encode();
    let mut tx = ETHTransactionRequest {
        to: Some(AlloyTxKind::Call(token_addr)),
        from: Some(swapper),
        value: Some(U256::ZERO),
        input: data.into(),
        gas: Some(DEFAULT_THOR_APPROVE_GAS),
        ..Default::default()
    };
    tx.chain_id = Some(config.chain_id());

    Ok(Some(
        TransactionRequest::Ethereum((
            tx,
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn chain_name_maps_mainnet_only() {
        assert_eq!(thorchain_chain_name(ETHEREUM, 1), Some("ETH"));
        assert_eq!(thorchain_chain_name(ETHEREUM, 56), Some("BSC"));
        assert_eq!(thorchain_chain_name(ETHEREUM, 43114), Some("AVAX"));
        assert_eq!(thorchain_chain_name(ETHEREUM, 8453), Some("BASE"));
        assert_eq!(thorchain_chain_name(BITCOIN, 0), Some("BTC"));
        assert_eq!(thorchain_chain_name(TRON, 728_126_428), Some("TRON"));
        assert_eq!(thorchain_chain_name(SOLANA, 101), Some("SOL"));
        // testnets and non-THORChain EVM chains (Arbitrum etc.) are excluded.
        assert_eq!(thorchain_chain_name(ETHEREUM, 11_155_111), None);
        assert_eq!(thorchain_chain_name(ETHEREUM, 42161), None);
        assert_eq!(thorchain_chain_name(BITCOIN, 1), None);
    }

    #[test]
    fn meta_for_token_builds_chain_and_asset() {
        let native = ThorchainMeta::for_token(ETHEREUM, 56, "BNB", "0x0", true).unwrap();
        assert_eq!(native.chain, "BSC");
        assert_eq!(native.asset, "BSC.BNB");
        assert_eq!(native.chain_id, 56);

        let token = ThorchainMeta::for_token(
            ETHEREUM,
            56,
            "USDT",
            "0x55d398326f99059fF775485246999027B3197955",
            false,
        )
        .unwrap();
        assert_eq!(
            token.asset,
            "BSC.USDT-0x55d398326f99059fF775485246999027B3197955"
        );

        // Not a THORChain chain → no meta (so no provider gets attached).
        assert!(ThorchainMeta::for_token(ETHEREUM, 42161, "ARB", "0x0", true).is_none());
    }

    #[test]
    fn asset_id_native_vs_erc20() {
        assert_eq!(thorchain_asset_id("ETH", "ETH", "0x0", true), "ETH.ETH");
        assert_eq!(thorchain_asset_id("BTC", "BTC", "", true), "BTC.BTC");
        assert_eq!(
            thorchain_asset_id("ETH", "USDC", "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", false),
            "ETH.USDC-0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        );
    }

    #[test]
    fn thor_amount_rescales_both_directions() {
        // 1 ETH (1e18 wei) <-> 1e8 thor units
        assert_eq!(to_thor_amount("1000000000000000000", 18).unwrap(), "100000000");
        assert_eq!(
            from_thor_amount("100000000", 18).unwrap(),
            "1000000000000000000"
        );
        // 6-decimal USDC: 1 USDC (1e6) -> 1e8 thor units
        assert_eq!(to_thor_amount("1000000", 6).unwrap(), "100000000");
        assert_eq!(from_thor_amount("100000000", 6).unwrap(), "1000000");
        // dividing 1e8 -> 6 decimals truncates sub-units (150 thor units -> 1)
        assert_eq!(from_thor_amount("150", 6).unwrap(), "1");
    }

    #[test]
    fn blob_round_trips() {
        let blob = ThorchainBlob {
            source: ThorchainSource::Evm {
                chain_id: 1,
                router: "0xD37BbE5744D730a1d98d8DC97c42F0Ca46aD7146".to_string(),
                asset_addr: String::new(),
                is_native: true,
            },
            chain_hash: 42,
            vault: "0x82a5cf67f3e6970c0529122178075c0a94878bda".to_string(),
            memo: "=:BTC.BTC:bc1qxy:0/1/0".to_string(),
            amount: "1000000000000000000".to_string(),
            expiry: 1_700_000_000,
        };
        let json = serde_json::to_string(&blob).unwrap();
        let parsed: ThorchainBlob = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed.vault, blob.vault);
        assert_eq!(parsed.memo, blob.memo);
        assert!(matches!(
            parsed.source,
            ThorchainSource::Evm { is_native: true, .. }
        ));
    }

    #[test]
    fn deposit_tx_native_encodes_value_and_memo() {
        let router = Address::from([0xab; 20]);
        let vault = Address::from([0xcd; 20]);
        let from = Address::from([0x11; 20]);
        let amount = U256::from(1_000u64);
        let memo = "=:BTC.BTC:bc1qxy".to_string();

        let tx = build_deposit_tx(
            router,
            1,
            7,
            from,
            DepositParams {
                vault,
                asset: Address::ZERO,
                amount,
                memo: memo.clone(),
                expiry: 123,
                is_native: true,
            },
        );
        let TransactionRequest::Ethereum((eth, meta)) = tx else {
            panic!("expected ethereum tx");
        };
        assert_eq!(meta.chain_hash, 7);
        assert_eq!(eth.value, Some(amount)); // native funds the deposit
        let data = eth.input.input.clone().unwrap();
        assert_eq!(&data[..4], depositWithExpiryCall::SELECTOR.as_slice());
        let decoded = depositWithExpiryCall::abi_decode(&data).unwrap();
        assert_eq!(decoded.vault, vault);
        assert_eq!(decoded.asset, Address::ZERO);
        assert_eq!(decoded.amount, amount);
        assert_eq!(decoded.memo, memo);
        assert_eq!(decoded.expiry, U256::from(123u64));
    }

    #[test]
    fn deposit_tx_erc20_has_zero_value() {
        let token = Address::from([0x22; 20]);
        let tx = build_deposit_tx(
            Address::from([0xab; 20]),
            56,
            1,
            Address::from([0x11; 20]),
            DepositParams {
                vault: Address::from([0xcd; 20]),
                asset: token,
                amount: U256::from(5_000u64),
                memo: "=:ETH.ETH:0xabc".to_string(),
                expiry: 0,
                is_native: false,
            },
        );
        let TransactionRequest::Ethereum((eth, _)) = tx else {
            panic!("expected ethereum tx");
        };
        assert_eq!(eth.value, Some(U256::ZERO)); // router pulls the ERC-20, no native value
        let decoded =
            depositWithExpiryCall::abi_decode(&eth.input.input.clone().unwrap()).unwrap();
        assert_eq!(decoded.asset, token);
    }

    #[test]
    fn inbound_address_raw_deserializes_real_eth_entry() {
        // Trimmed from a live `GET /thorchain/inbound_addresses` (thornode.thorchain.network).
        let body = r#"{
            "chain": "ETH",
            "pub_key": "thorpub1addwnpepqv...",
            "address": "0x82a5cf67f3e6970c0529122178075c0a94878bda",
            "router": "0xD37BbE5744D730a1d98d8DC97c42F0Ca46aD7146",
            "halted": true,
            "global_trading_paused": true,
            "chain_trading_paused": true,
            "chain_lp_actions_paused": true,
            "observed_fee_rate": "10",
            "gas_rate": "15",
            "gas_rate_units": "gwei",
            "outbound_tx_size": "100000",
            "outbound_fee": "1000",
            "dust_threshold": "1000"
        }"#;
        let parsed: InboundAddressRaw = serde_json::from_str(body).unwrap();
        assert_eq!(parsed.chain, "ETH");
        assert_eq!(parsed.router, "0xD37BbE5744D730a1d98d8DC97c42F0Ca46aD7146");
        assert!(parsed.halted);
        assert_eq!(parsed.observed_fee_rate, "10");
        assert_eq!(parsed.outbound_tx_size, "100000");
    }
}
