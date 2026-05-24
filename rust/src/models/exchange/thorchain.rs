use flutter_rust_bridge::frb;
use serde::Deserialize;

use crate::models::provider::NetworkConfigInfo;

const THORCHAIN_BASE_URLS: &[&str] = &[
    "https://thornode.thorchain.network",
    "https://gateway.liquify.com/chain/thorchain_api",
];

#[frb(ignore)]
#[derive(Debug, Deserialize)]
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

#[derive(Debug, Default)]
pub struct MetadataThorchain {
    pub inbound_addresses: Vec<ThorchainInbound>,
    pub swap_quote: ThorchainSwapQuote,
}

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

#[derive(Debug, Default)]
pub struct ThorchainSwapQuote {
    pub inbound_address: String,
    pub router: String,
    pub memo: String,
    pub expected_amount_out: String,
    pub expiry: i64,
    pub inbound_confirmation_blocks: i64,
    pub inbound_confirmation_seconds: i64,
    pub outbound_delay_blocks: i64,
    pub outbound_delay_seconds: i64,
    pub total_swap_seconds: i64,
    pub max_streaming_quantity: i64,
    pub streaming_swap_blocks: i64,
    pub streaming_swap_seconds: i64,
    pub fees: ThorchainFees,
    pub dust_threshold: String,
    pub recommended_min_amount_in: String,
    pub recommended_gas_rate: String,
    pub gas_rate_units: String,
    pub warning: String,
    pub notes: String,
}

#[derive(Debug, Default)]
pub struct ThorchainFees {
    pub asset: String,
    pub affiliate: String,
    pub outbound: String,
    pub liquidity: String,
    pub total: String,
    pub slippage_bps: i64,
    pub total_bps: i64,
}

impl From<InboundAddressRaw> for ThorchainInbound {
    fn from(raw: InboundAddressRaw) -> Self {
        Self {
            chain: raw.chain,
            address: raw.address,
            router: raw.router,
            halted: raw.halted,
            global_trading_paused: raw.global_trading_paused,
            chain_trading_paused: raw.chain_trading_paused,
            gas_rate: raw.gas_rate,
            gas_rate_units: raw.gas_rate_units,
            outbound_fee: raw.outbound_fee,
            dust_threshold: raw.dust_threshold,
        }
    }
}

impl From<QuoteSwapRaw> for ThorchainSwapQuote {
    fn from(raw: QuoteSwapRaw) -> Self {
        Self {
            inbound_address: raw.inbound_address,
            router: raw.router,
            memo: raw.memo,
            expected_amount_out: raw.expected_amount_out,
            expiry: raw.expiry,
            inbound_confirmation_blocks: raw.inbound_confirmation_blocks,
            inbound_confirmation_seconds: raw.inbound_confirmation_seconds,
            outbound_delay_blocks: raw.outbound_delay_blocks,
            outbound_delay_seconds: raw.outbound_delay_seconds,
            total_swap_seconds: raw.total_swap_seconds,
            max_streaming_quantity: raw.max_streaming_quantity,
            streaming_swap_blocks: raw.streaming_swap_blocks,
            streaming_swap_seconds: raw.streaming_swap_seconds,
            dust_threshold: raw.dust_threshold,
            recommended_min_amount_in: raw.recommended_min_amount_in,
            recommended_gas_rate: raw.recommended_gas_rate,
            gas_rate_units: raw.gas_rate_units,
            warning: raw.warning,
            notes: raw.notes,
            fees: ThorchainFees {
                asset: raw.fees.asset,
                affiliate: raw.fees.affiliate,
                outbound: raw.fees.outbound,
                liquidity: raw.fees.liquidity,
                total: raw.fees.total,
                slippage_bps: raw.fees.slippage_bps,
                total_bps: raw.fees.total_bps,
            },
        }
    }
}

impl MetadataThorchain {
    pub fn is_supported(config: &NetworkConfigInfo) -> bool {
        matches!(
            config.chain.as_str(),
            "BTC" | "LTC" | "BCH" | "DOGE" | "ETH"
                | "BNB" | "AVAX" | "BASE" | "TRX" | "SOL" | "XRP"
        )
    }
}

#[frb(ignore)]
pub async fn fetch_thorchain_data(
    from_asset: &str,
    to_asset: &str,
    amount: &str,
    destination: &str,
) -> Result<MetadataThorchain, String> {
    let client = reqwest::Client::new();
    let inbound_addresses = fetch_inbound_addresses(&client).await?;
    let swap_quote = fetch_swap_quote(&client, from_asset, to_asset, amount, destination).await?;
    Ok(MetadataThorchain {
        inbound_addresses,
        swap_quote,
    })
}

async fn fetch_inbound_addresses(
    client: &reqwest::Client,
) -> Result<Vec<ThorchainInbound>, String> {
    let mut last_err = String::new();

    for base_url in THORCHAIN_BASE_URLS {
        match try_fetch_inbound_addresses(base_url, client).await {
            Ok(result) => return Ok(result),
            Err(e) => last_err = e,
        }
    }

    Err(last_err)
}

async fn fetch_swap_quote(
    client: &reqwest::Client,
    from_asset: &str,
    to_asset: &str,
    amount: &str,
    destination: &str,
) -> Result<ThorchainSwapQuote, String> {
    let mut last_err = String::new();

    for base_url in THORCHAIN_BASE_URLS {
        match try_fetch_swap_quote(base_url, client, from_asset, to_asset, amount, destination)
            .await
        {
            Ok(result) => return Ok(result),
            Err(e) => last_err = e,
        }
    }

    Err(last_err)
}

async fn try_fetch_inbound_addresses(
    base_url: &str,
    client: &reqwest::Client,
) -> Result<Vec<ThorchainInbound>, String> {
    let url = format!("{base_url}/thorchain/inbound_addresses");
    let resp = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("{e}"))?;

    if !resp.status().is_success() {
        let body = resp.text().await.unwrap_or_default();
        return Err(body);
    }

    let raw: Vec<InboundAddressRaw> = resp.json().await.map_err(|e| format!("{e}"))?;

    let mut result = Vec::with_capacity(raw.len());
    for item in raw {
        result.push(ThorchainInbound::from(item));
    }
    Ok(result)
}

async fn try_fetch_swap_quote(
    base_url: &str,
    client: &reqwest::Client,
    from_asset: &str,
    to_asset: &str,
    amount: &str,
    destination: &str,
) -> Result<ThorchainSwapQuote, String> {
    let url = format!(
        "{base_url}/thorchain/quote/swap?\
         from_asset={from_asset}&to_asset={to_asset}\
         &amount={amount}&destination={destination}"
    );
    let resp = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("{e}"))?;

    if !resp.status().is_success() {
        let body = resp.text().await.unwrap_or_default();
        return Err(body);
    }

    let raw: QuoteSwapRaw = resp.json().await.map_err(|e| format!("{e}"))?;

    Ok(ThorchainSwapQuote::from(raw))
}
