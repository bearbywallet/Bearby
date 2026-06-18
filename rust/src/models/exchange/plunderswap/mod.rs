mod abi;
mod math;
mod route;
mod tx;

use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::{Address, U256};
use zilpay::{serde, serde_json};

use self::math::resolve_pair;
use self::route::quote_route;
use self::tx::{build_approval_if_needed, build_finalized_swap};
use super::{ExchangeAsset, PreparedSwap, ProviderCommon, ProviderQuote};
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::request::TransactionRequestInfo;

pub const ZILLIQA_MAINNET_CHAIN_ID: u64 = 32_769;

/// `PlunderFeeRouter`'s input fee (1% = 100 bps). Quotes subtract it before routing.
pub const PROXY_FEE_BPS: u32 = 100;

/// V3 fee tiers to probe (bips * 100): 0.01% / 0.05% / 0.25% / 0.30% / 1.00%.
///
/// The live WZIL/pZIL fork test uses 0.25%; 0.30% is also probed to avoid
/// silently missing pools deployed by Uni-style factories.
pub const PLUNDER_V3_FEE_TIERS: &[u32] = &[100, 500, 2_500, 3_000, 10_000];

pub const SWAP_GAS: u64 = 400_000;
pub const APPROVE_GAS: u64 = 60_000;

const FEE_ROUTER: &str = "0x8F2e461aec4f75B3Bd6058FfCB121a832eb0711b";
const WZIL: &str = "0x94e18aE7dd5eE57B55f30c4B63E2760c09EFb192";
const ROUTER_V2: &str = "0x33C6a20D2a605da9Fd1F506ddEd449355f0564fe";
const QUOTER_V2: &str = "0xAE4474364B8fc6Ce0fe8F888752540C05948AD94";

#[frb(ignore)]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct PlunderAddrs {
    pub chain_id: u64,
    pub fee_router: Address,
    pub wzil: Address,
    pub router_v2: Address,
    pub quoter_v2: Address,
}

#[frb(ignore)]
#[derive(Clone, Debug)]
pub struct PlunderConfig {
    pub addrs: PlunderAddrs,
    pub fee_tiers: &'static [u32],
}

#[derive(Debug, Clone, Copy)]
pub struct PlunderCfg {
    pub default_slippage_bps: u32,
    pub supports_price_protection: bool,
}

impl PlunderCfg {
    #[must_use]
    pub const fn default() -> Self {
        Self {
            default_slippage_bps: 50,
            supports_price_protection: true,
        }
    }
}

#[derive(Debug, Clone)]
pub struct PlunderMeta {
    pub common: ProviderCommon,
    pub cfg: PlunderCfg,
    pub quote: Option<ProviderQuote>,
}

#[frb(ignore)]
#[must_use]
pub const fn is_supported_chain(chain_id: u64) -> bool {
    matches!(chain_id, ZILLIQA_MAINNET_CHAIN_ID)
}

impl PlunderMeta {
    #[frb(ignore)]
    pub fn for_chain(
        chain_hash: u64,
        chain_id: u64,
        slip44: u32,
        account_addr: &str,
    ) -> Option<Self> {
        is_supported_chain(chain_id).then(|| Self {
            common: ProviderCommon {
                chain_hash,
                chain_id,
                slip44,
                account_addr: account_addr.to_owned(),
                icon_asset: "assets/icons/plunderswap.svg".to_owned(),
                display_name: "PlunderSwap".to_owned(),
            },
            cfg: PlunderCfg::default(),
            quote: None,
        })
    }

    #[frb(ignore)]
    pub fn resolve(&self) -> Result<PlunderConfig, String> {
        let parse = |input: &str| Address::from_str(input).map_err(|e| e.to_string());
        Ok(PlunderConfig {
            addrs: PlunderAddrs {
                chain_id: self.common.chain_id,
                fee_router: parse(FEE_ROUTER)?,
                wzil: parse(WZIL)?,
                router_v2: parse(ROUTER_V2)?,
                quoter_v2: parse(QUOTER_V2)?,
            },
            fee_tiers: PLUNDER_V3_FEE_TIERS,
        })
    }
}

#[frb(ignore)]
#[derive(serde::Serialize, serde::Deserialize, Clone, Debug, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub(super) enum RouteKind {
    V2 {
        path: Vec<String>,
    },
    V3 {
        token_in: String,
        token_out: String,
        fee_tier: u32,
    },
    Wrap {
        token: String,
    },
}

#[frb(ignore)]
#[derive(serde::Serialize, serde::Deserialize, Clone, Debug, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub(super) struct QuoteBlob {
    chain_id: u64,
    fee_router: String,
    route: RouteKind,
    amount_in: String,
    amount_out: String,
    slippage_bps: u32,
    is_native_in: bool,
    is_native_out: bool,
    recipient: String,
}

struct ResolvedSwap {
    cfg: PlunderConfig,
    token_in: String,
    token_out: String,
    is_native_out: bool,
    is_wrap_unwrap: bool,
}

fn resolve_swap(
    meta: &PlunderMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    from_asset: &str,
    to_asset: &str,
) -> Result<ResolvedSwap, String> {
    if from.token.chain_hash != to.token.chain_hash {
        return Err("cross-chain swap not supported".to_string());
    }
    if from.token.chain_hash != meta.common.chain_hash {
        return Err("provider chain mismatch".to_string());
    }

    let cfg = meta.resolve()?;
    let (token_in, token_out, is_native_out, is_wrap_unwrap) = resolve_pair(
        cfg.addrs.chain_id,
        cfg.addrs.wzil,
        from_asset,
        to_asset,
        from.token.native,
    )?;

    Ok(ResolvedSwap {
        cfg,
        token_in,
        token_out,
        is_native_out,
        is_wrap_unwrap,
    })
}

#[frb(ignore)]
pub fn is_wrap_unwrap(
    meta: &PlunderMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    from_asset: &str,
    to_asset: &str,
) -> Result<bool, String> {
    resolve_swap(meta, from, to, from_asset, to_asset).map(|resolved| resolved.is_wrap_unwrap)
}

#[frb(ignore)]
pub async fn plunderswap_quote_info(
    meta: &PlunderMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    from_asset: &str,
    to_asset: &str,
    amount: &str,
) -> Result<ProviderQuote, String> {
    let resolved = resolve_swap(meta, from, to, from_asset, to_asset)?;
    if resolved.is_wrap_unwrap {
        return Ok(ProviderQuote {
            amount_out: amount.to_string(),
            permit_typed_data_json: None,
            is_wrap_unwrap: true,
        });
    }

    let route = quote_route(
        meta.common.chain_hash,
        &resolved.cfg,
        &resolved.token_in,
        &resolved.token_out,
        amount,
    )
    .await?;

    Ok(ProviderQuote {
        amount_out: route.amount_out.to_string(),
        permit_typed_data_json: None,
        is_wrap_unwrap: false,
    })
}

#[frb(ignore)]
pub async fn plunderswap_check_approval(
    meta: &PlunderMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
    approve_title: String,
    icon: String,
) -> Result<Option<TransactionRequestInfo>, String> {
    if from.token.native {
        return Ok(None);
    }

    let resolved = resolve_swap(
        meta,
        from,
        to,
        from.token.addr.as_str(),
        to.token.addr.as_str(),
    )?;
    if resolved.is_wrap_unwrap {
        return Ok(None);
    }

    let owner = Address::from_str(&meta.common.account_addr).map_err(|e| e.to_string())?;
    build_approval_if_needed(
        &resolved.cfg,
        owner,
        meta.common.chain_hash,
        from.token.addr.as_str(),
        amount,
        approve_title,
        icon,
    )
    .await
}

#[frb(ignore)]
pub async fn plunderswap_prepare_swap(
    meta: &PlunderMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount: &str,
    slippage_bps: u32,
) -> Result<PreparedSwap, String> {
    let resolved = resolve_swap(
        meta,
        from,
        to,
        from.token.addr.as_str(),
        to.token.addr.as_str(),
    )?;
    let amount_in = U256::from_str(amount).map_err(|e| e.to_string())?;
    let (route, amount_out) = if resolved.is_wrap_unwrap {
        (
            RouteKind::Wrap {
                token: resolved.token_in,
            },
            amount_in,
        )
    } else {
        let plan = quote_route(
            meta.common.chain_hash,
            &resolved.cfg,
            &resolved.token_in,
            &resolved.token_out,
            amount,
        )
        .await?;
        (plan.kind, plan.amount_out)
    };

    let blob = QuoteBlob {
        chain_id: resolved.cfg.addrs.chain_id,
        fee_router: resolved.cfg.addrs.fee_router.to_string(),
        route,
        amount_in: amount_in.to_string(),
        amount_out: amount_out.to_string(),
        slippage_bps,
        is_native_in: from.token.native,
        is_native_out: resolved.is_native_out,
        recipient: meta.common.account_addr.clone(),
    };

    Ok(PreparedSwap {
        permit_typed_data_json: None,
        quote_blob: serde_json::to_string(&blob).map_err(|e| e.to_string())?,
    })
}

#[frb(ignore)]
pub async fn plunderswap_finalize_swap(
    quote_blob: &str,
    chain_hash: u64,
    swapper: Address,
    swap_title: String,
    swap_info: String,
    provider_icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let blob: QuoteBlob =
        serde_json::from_str(quote_blob).map_err(|e| format!("invalid quote_blob: {e}"))?;
    build_finalized_swap(
        &blob,
        chain_hash,
        swapper,
        swap_title,
        swap_info,
        provider_icon,
        out_token,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    fn meta(chain_id: u64) -> PlunderMeta {
        PlunderMeta::for_chain(
            42,
            chain_id,
            313,
            "0x0000000000000000000000000000000000000001",
        )
        .unwrap_or_else(|| PlunderMeta {
            common: ProviderCommon {
                chain_hash: 42,
                chain_id,
                slip44: 313,
                account_addr: "0x0000000000000000000000000000000000000001".to_string(),
                icon_asset: "assets/icons/plunderswap.svg".to_string(),
                display_name: "PlunderSwap".to_string(),
            },
            cfg: PlunderCfg::default(),
            quote: None,
        })
    }

    #[test]
    fn meta_for_chain_known_and_unknown() {
        assert!(PlunderMeta::for_chain(
            42,
            ZILLIQA_MAINNET_CHAIN_ID,
            313,
            "0x0000000000000000000000000000000000000001"
        )
        .is_some());
        assert!(
            PlunderMeta::for_chain(42, 1, 313, "0x0000000000000000000000000000000000000001")
                .is_none()
        );
    }

    #[test]
    fn resolve_parses_mainnet_addresses() -> Result<(), String> {
        let cfg = meta(ZILLIQA_MAINNET_CHAIN_ID).resolve()?;
        assert_eq!(cfg.addrs.chain_id, ZILLIQA_MAINNET_CHAIN_ID);
        assert_eq!(cfg.fee_tiers, PLUNDER_V3_FEE_TIERS);
        assert_eq!(
            cfg.addrs.fee_router,
            Address::from_str(FEE_ROUTER).map_err(|e| e.to_string())?
        );
        assert_eq!(
            cfg.addrs.wzil,
            Address::from_str(WZIL).map_err(|e| e.to_string())?
        );
        assert_eq!(
            cfg.addrs.router_v2,
            Address::from_str(ROUTER_V2).map_err(|e| e.to_string())?
        );
        assert_eq!(
            cfg.addrs.quoter_v2,
            Address::from_str(QUOTER_V2).map_err(|e| e.to_string())?
        );
        Ok(())
    }

    #[test]
    fn quote_blob_round_trips() -> Result<(), String> {
        let blob = QuoteBlob {
            chain_id: ZILLIQA_MAINNET_CHAIN_ID,
            fee_router: FEE_ROUTER.to_string(),
            route: RouteKind::V3 {
                token_in: WZIL.to_string(),
                token_out: "0xc85b0db68467dede96A7087F4d4C47731555cA7A".to_string(),
                fee_tier: 2_500,
            },
            amount_in: "100".to_string(),
            amount_out: "200".to_string(),
            slippage_bps: 50,
            is_native_in: true,
            is_native_out: false,
            recipient: "0x0000000000000000000000000000000000000001".to_string(),
        };
        let json = serde_json::to_string(&blob).map_err(|e| e.to_string())?;
        let parsed: QuoteBlob = serde_json::from_str(&json).map_err(|e| e.to_string())?;
        assert_eq!(parsed, blob);
        Ok(())
    }
}
