mod addr;
pub mod math;
mod pools;
mod tx;

use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::U256;
use zilpay::serde;
use zilpay::serde_json;

use self::addr::{with_0x_lower, zil_base16, zil_checksum_lower};
use self::math::{net_quote, resolve_direction, SwapDirection};
use self::pools::{fetch_allowance, fetch_deadline_block, fetch_pool, fetch_pools_for};
use self::tx::{build_increase_allowance, build_swap_tx, SwapTxArgs};
use super::{ExchangeAsset, PreparedSwap, ProviderQuote, ZilSwapMeta};
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::request::TransactionRequestInfo;

/// Zilliqa mainnet native (Scilla) chain id, i.e. `chain_ids[0]`.
/// The EVM chain id (`chain_ids[1]` = 1) is injected by `sign_and_broadcast_one`.
pub const ZILLIQA_MAINNET_CHAIN_ID: u64 = 32_769;
pub const DEADLINE_BLOCK_WINDOW: u64 = 10;
pub const SWAP_GAS: u64 = 7_000;
pub const APPROVAL_GAS: u64 = 5_000;

/// Proxy fee in basis points (10% = 1000 bps). The proxy skims this from
/// the swap output before forwarding to the user.
pub const PROXY_FEE_BPS: u32 = 1_000;

const MAINNET_PROXY: &str = "0xcccfdec2c9842f3f7ece2b9be996e814d59ca0cc";
const MAINNET_CORE: &str = "0x459CB2d3BAF7e61cFbD5FE362f289aE92b2BaBb0";

#[frb(ignore)]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct ZilSwapConfig {
    pub proxy: &'static str,
    pub core: &'static str,
}

impl ZilSwapConfig {
    #[frb(ignore)]
    pub const fn for_chain(chain_id: u64) -> Option<Self> {
        match chain_id {
            ZILLIQA_MAINNET_CHAIN_ID => Some(Self {
                proxy: MAINNET_PROXY,
                core: MAINNET_CORE,
            }),
            _ => None,
        }
    }
}

#[frb(ignore)]
#[must_use]
pub const fn is_supported_chain(chain_id: u64) -> bool {
    matches!(chain_id, ZILLIQA_MAINNET_CHAIN_ID)
}

impl ZilSwapMeta {
    #[frb(ignore)]
    pub fn config(&self) -> Result<ZilSwapConfig, String> {
        ZilSwapConfig::for_chain(self.common.chain_id)
            .ok_or_else(|| "unsupported ZilSwap chain".to_string())
    }
}

#[frb(ignore)]
#[derive(serde::Serialize, serde::Deserialize)]
#[serde(crate = "zilpay::serde")]
struct QuoteBlob {
    direction: SwapDirection,
    token_base16: String,
    token_out_base16: String,
    amount_in: String,
    amount_out: String,
    account_key: String,
    slippage_bps: u32,
    chain_id: u64,
}

struct ResolvedSwap {
    direction: SwapDirection,
    token_base16: String,
    token_out_base16: String,
    /// Lowercase 0x account key used both as Scilla recipient and ZRC2 allowance owner.
    account_key: String,
}

fn resolve_swap(
    meta: &ZilSwapMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
) -> Result<ResolvedSwap, String> {
    if from.token.chain_hash != to.token.chain_hash
        || from.token.chain_hash != meta.common.chain_hash
    {
        return Err("cross-chain swap not supported".to_string());
    }

    let direction = resolve_direction(from.token.native, to.token.native);
    let token_base16 = if from.token.native {
        String::with_capacity(0)
    } else {
        zil_base16(&from.token.addr)?
    };
    let token_out_base16 = if to.token.native {
        String::with_capacity(0)
    } else {
        zil_base16(&to.token.addr)?
    };
    let account_key = zil_checksum_lower(&meta.common.account_addr)?;

    Ok(ResolvedSwap {
        direction,
        token_base16,
        token_out_base16,
        account_key,
    })
}

async fn quote_output(
    chain_hash: u64,
    cfg: &ZilSwapConfig,
    direction: SwapDirection,
    amount_in: U256,
    token_base16: &str,
    token_out_base16: &str,
) -> Result<U256, String> {
    match direction {
        SwapDirection::ZilToToken => {
            let pool = fetch_pool(chain_hash, cfg.core, token_out_base16).await?;
            Ok(net_quote(direction, amount_in, pool, None))
        }
        SwapDirection::TokenToZil => {
            let pool = fetch_pool(chain_hash, cfg.core, token_base16).await?;
            Ok(net_quote(direction, amount_in, pool, None))
        }
        SwapDirection::TokenToTokens => {
            if token_base16.eq_ignore_ascii_case(token_out_base16) {
                return Err("same-token swap not supported".to_string());
            }
            let pools =
                fetch_pools_for(chain_hash, cfg.core, &[token_base16, token_out_base16]).await?;
            let input = pools
                .first()
                .copied()
                .ok_or_else(|| "input pool not found".to_string())?;
            let output = pools
                .get(1)
                .copied()
                .ok_or_else(|| "output pool not found".to_string())?;
            Ok(net_quote(direction, amount_in, input, Some(output)))
        }
    }
}

#[frb(ignore)]
pub async fn zilswap_quote_info(
    meta: &ZilSwapMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    _from_asset: &str,
    _to_asset: &str,
    amount: &str,
) -> Result<ProviderQuote, String> {
    let cfg = meta.config()?;
    let resolved = resolve_swap(meta, from, to)?;
    let amount_in = U256::from_str(amount).map_err(|e| e.to_string())?;
    let amount_out = quote_output(
        meta.common.chain_hash,
        &cfg,
        resolved.direction,
        amount_in,
        &resolved.token_base16,
        &resolved.token_out_base16,
    )
    .await?;

    Ok(ProviderQuote {
        amount_out: amount_out.to_string(),
        permit_typed_data_json: None,
        is_wrap_unwrap: false,
    })
}

#[frb(ignore)]
pub async fn zilswap_check_approval(
    meta: &ZilSwapMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
    approve_title: String,
    icon: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    if from.token.native {
        return Ok(None);
    }

    let cfg = meta.config()?;
    let resolved = resolve_swap(meta, from, to)?;
    let spender = match resolved.direction {
        SwapDirection::ZilToToken => return Ok(None),
        SwapDirection::TokenToZil | SwapDirection::TokenToTokens => cfg.core,
    };
    let needed = U256::from_str(amount).map_err(|e| e.to_string())?;
    let spender_key = with_0x_lower(spender);
    let allowance = fetch_allowance(
        meta.common.chain_hash,
        &resolved.token_base16,
        &resolved.account_key,
        &spender_key,
    )
    .await?;

    if allowance >= needed {
        return Ok(None);
    }

    build_increase_allowance(
        meta.common.chain_id,
        meta.common.chain_hash,
        &resolved.token_base16,
        spender,
        needed,
        approve_title,
        icon,
    )
    .map(Some)
}

#[frb(ignore)]
pub async fn zilswap_prepare_swap(
    meta: &ZilSwapMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
    slippage_bps: u32,
) -> Result<PreparedSwap, String> {
    let cfg = meta.config()?;
    let resolved = resolve_swap(meta, from, to)?;
    let amount_in = U256::from_str(amount).map_err(|e| e.to_string())?;
    let amount_out = quote_output(
        meta.common.chain_hash,
        &cfg,
        resolved.direction,
        amount_in,
        &resolved.token_base16,
        &resolved.token_out_base16,
    )
    .await?;
    let blob = QuoteBlob {
        direction: resolved.direction,
        token_base16: resolved.token_base16,
        token_out_base16: resolved.token_out_base16,
        amount_in: amount_in.to_string(),
        amount_out: amount_out.to_string(),
        account_key: resolved.account_key,
        slippage_bps,
        chain_id: meta.common.chain_id,
    };

    Ok(PreparedSwap {
        permit_typed_data_json: None,
        quote_blob: serde_json::to_string(&blob).map_err(|e| e.to_string())?,
    })
}

#[frb(ignore)]
pub async fn zilswap_finalize_swap(
    quote_blob: &str,
    chain_hash: u64,
    swap_title: String,
    swap_info: String,
    provider_icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let blob: QuoteBlob =
        serde_json::from_str(quote_blob).map_err(|e| format!("invalid quote_blob: {e}"))?;
    let cfg = ZilSwapConfig::for_chain(blob.chain_id)
        .ok_or_else(|| "unsupported ZilSwap chain".to_string())?;
    let deadline = fetch_deadline_block(chain_hash, DEADLINE_BLOCK_WINDOW).await?;
    let amount_in = U256::from_str(&blob.amount_in).map_err(|e| e.to_string())?;
    let amount_out = U256::from_str(&blob.amount_out).map_err(|e| e.to_string())?;

    build_swap_tx(SwapTxArgs {
        cfg: &cfg,
        direction: blob.direction,
        chain_id: blob.chain_id,
        chain_hash,
        amount_in,
        amount_out,
        slippage_bps: blob.slippage_bps,
        deadline_block: deadline,
        account_key: &blob.account_key,
        token_base16: &blob.token_base16,
        token_out_base16: &blob.token_out_base16,
        title: swap_title,
        info: swap_info,
        icon: provider_icon,
        out_token,
    })
}
