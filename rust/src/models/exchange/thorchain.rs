use flutter_rust_bridge::frb;
use zilpay::serde::Deserialize;

#[allow(dead_code)]
const THORCHAIN_BASE_URLS: &[&str] = &[
    "https://thornode.thorchain.network",
    "https://gateway.liquify.com/chain/thorchain_api",
    "https://thornode.ninerealms.com",
    "https://thornode.thorswap.net",
    "https://thornode-v2.ninerealms.com",
    "https://thornode.liquify.com",
];

#[frb(ignore)]
#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub struct InboundAddressRaw {
    #[serde(default)]
    pub chain: String,
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
    pub gas_rate: String,
    #[serde(default)]
    pub gas_rate_units: String,
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
