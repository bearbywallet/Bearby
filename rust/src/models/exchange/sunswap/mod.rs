mod abi;
pub(super) mod gate;
mod math;
mod route;
mod tx;

use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::{Address as AlloyAddress, U256};
use zilpay::alloy::sol_types::SolCall;
use zilpay::proto::address::Address;
use zilpay::{serde, serde_json};

use self::math::resolve_pair;
use self::route::quote_route;
use self::tx::{build_approval_if_needed, build_finalized_swap};
use super::{ExchangeAsset, PreparedSwap, ProviderCommon, ProviderQuote};
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::request::TransactionRequestInfo;

/// `SunFeeRouter`'s input fee (1% = 100 bps). Matches the on-chain `MAX_FEE_BPS`.
/// Quotes subtract it before routing.
pub const PROXY_FEE_BPS: u32 = 100;

pub const TRON_MAINNET_CHAIN_ID: u64 = 728_126_428;
pub const TRON_NILE_CHAIN_ID: u64 = 3_448_148_188;

// Nile (deployed — dex-router/README.md "SunSwap Nile deployment").
const NILE_FEE_ROUTER: &str = "TVSy9pau8hqRwYNGJ4rU9LwebDbTQGHNVE";
const NILE_QUOTE_LENS: &str = "TKvmxYRWK7Ea9YQ1LTyBpqfbJ2MTLXRWT9";
const NILE_WTRX: &str = "TYsbWxNnyTgsZaTFaue9hqpxkU3Fkco94a";

// Mainnet (deployed — dex-router/README.md "SunSwap mainnet deployment").
const MAINNET_WTRX: &str = "TNUC9Qb1rRpS5CbWLmNMxXBjyFoydXjWFR";
const MAINNET_FEE_ROUTER: Option<&str> = Some("TFRViCT6E8rqzpExaKw32w6FcVCaRS1rxM");
const MAINNET_QUOTE_LENS: Option<&str> = Some("TSmHPMzhGmZZmjcCuWGAuDiG3BDJt9g4uh");

/// Route-type consts (per `SunQuoteLens.sol`). No V2.
pub const ROUTE_NONE: u8 = 0;
pub const ROUTE_V3_SINGLE: u8 = 1;
pub const ROUTE_V3_PATH: u8 = 2;

#[frb(ignore)]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SunAddrs {
    pub chain_id: u64,
    pub fee_router: Address,
    pub wtrx: Address,
    pub quote_lens: Address,
}

#[frb(ignore)]
#[derive(Clone, Debug)]
pub struct SunConfig {
    pub addrs: SunAddrs,
}

#[frb(ignore)]
#[derive(Clone, Debug, PartialEq, Eq)]
pub(crate) struct QuoteLensQuote {
    pub route_type: u8,
    pub amount_out: U256,
    pub fee_tier: u32,
    pub v3_path: Vec<u8>,
}

#[frb(ignore)]
pub(crate) fn encode_quote_lens_call(
    token_in: AlloyAddress,
    token_out: AlloyAddress,
    amount_in: U256,
) -> Vec<u8> {
    abi::quoteBestRouteCall {
        tokenIn: token_in,
        tokenOut: token_out,
        amountIn: amount_in,
    }
    .abi_encode()
}

#[frb(ignore)]
pub(crate) fn decode_quote_lens_return(data: &[u8]) -> Option<QuoteLensQuote> {
    let best = abi::quoteBestRouteCall::abi_decode_returns(data).ok()?;
    Some(QuoteLensQuote {
        route_type: best.routeType,
        amount_out: best.amountOut,
        fee_tier: best.fee.to::<u32>(),
        v3_path: best.v3Path.to_vec(),
    })
}

#[derive(Debug, Clone, Copy)]
pub struct SunSwapCfg {
    pub default_slippage_bps: u32,
    pub supports_price_protection: bool,
}

impl SunSwapCfg {
    #[must_use]
    pub const fn default() -> Self {
        Self {
            default_slippage_bps: 50,
            supports_price_protection: true,
        }
    }
}

#[derive(Debug, Clone)]
pub struct SunSwapMeta {
    pub common: ProviderCommon,
    pub cfg: SunSwapCfg,
    pub quote: Option<ProviderQuote>,
}

#[frb(ignore)]
#[must_use]
pub const fn is_supported_chain(chain_id: u64) -> bool {
    chain_id == TRON_NILE_CHAIN_ID
        || (chain_id == TRON_MAINNET_CHAIN_ID && MAINNET_FEE_ROUTER.is_some())
}

impl SunSwapMeta {
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
                icon_asset: "assets/icons/sunswap.svg".to_owned(),
                display_name: "SunSwap".to_owned(),
            },
            cfg: SunSwapCfg::default(),
            quote: None,
        })
    }

    #[frb(ignore)]
    pub fn resolve(&self) -> Result<SunConfig, String> {
        let (fee_router_str, quote_lens_str, wtrx_str) = match self.common.chain_id {
            TRON_NILE_CHAIN_ID => (NILE_FEE_ROUTER, NILE_QUOTE_LENS, NILE_WTRX),
            TRON_MAINNET_CHAIN_ID => (
                MAINNET_FEE_ROUTER.expect("checked by is_supported_chain"),
                MAINNET_QUOTE_LENS.expect("checked by is_supported_chain"),
                MAINNET_WTRX,
            ),
            _ => return Err("SunSwap not deployed on this chain".to_string()),
        };
        let parse = |input: &str| {
            Address::from_tron_address(input).map_err(|e| e.to_string())
        };
        let addrs = SunAddrs {
            chain_id: self.common.chain_id,
            fee_router: parse(fee_router_str)?,
            wtrx: parse(wtrx_str)?,
            quote_lens: parse(quote_lens_str)?,
        };
        Ok(SunConfig { addrs })
    }
}

#[frb(ignore)]
#[derive(serde::Serialize, serde::Deserialize, Clone, Debug, PartialEq, Eq)]
#[serde(crate = "zilpay::serde")]
pub(super) enum RouteKind {
    V3 {
        token_in: String,
        token_out: String,
        fee_tier: u32,
    },
    /// Multi-hop V3 route. `path` is the `0x`-prefixed hex of the packed Uniswap
    /// path bytes (`addr ‖ fee ‖ addr ‖ ... ‖ addr`), round-tripped verbatim into
    /// `swapExactInput` at finalize time.
    V3Path {
        path: String,
    },
    /// TRX↔WTRX wrap/unwrap. The WTRX address comes from `SunConfig.addrs.wtrx`
    /// at finalize time, so this variant carries no payload.
    Wrap,
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
    cfg: SunConfig,
    token_in: String,
    token_out: String,
    is_native_out: bool,
    is_wrap_unwrap: bool,
}

/// Convert a TRON base58 address (`T...`) to 20-byte EVM hex (`0x...`) for ABI
/// calldata. EVM hex addresses and the native sentinel pass through unchanged.
pub(super) fn to_evm_hex(addr: &str) -> Result<String, String> {
    if addr.starts_with("0x") || addr.is_empty() {
        return Ok(addr.to_owned());
    }
    let tron = Address::from_tron_address(addr).map_err(|e| e.to_string())?;
    Ok(tron.to_alloy_addr().to_string())
}

fn resolve_swap(
    meta: &SunSwapMeta,
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
    let wtrx_alloy = cfg.addrs.wtrx.to_alloy_addr();
    let from_evm = to_evm_hex(from_asset)?;
    let to_evm = to_evm_hex(to_asset)?;
    let (token_in, token_out, is_native_out, is_wrap_unwrap) = resolve_pair(
        cfg.addrs.chain_id,
        wtrx_alloy,
        &from_evm,
        &to_evm,
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
    meta: &SunSwapMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    from_asset: &str,
    to_asset: &str,
) -> Result<bool, String> {
    resolve_swap(meta, from, to, from_asset, to_asset).map(|resolved| resolved.is_wrap_unwrap)
}

/// Resolve the swapper as a TRON `proto::address::Address` (21-byte form).
fn swapper_tron(account_addr: &str) -> Result<Address, String> {
    Address::from_str_hex(account_addr).map_err(|e| e.to_string())
}

#[frb(ignore)]
pub async fn sunswap_quote_info(
    meta: &SunSwapMeta,
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

    let owner = swapper_tron(&meta.common.account_addr)?;
    let route = quote_route(
        meta.common.chain_hash,
        &resolved.cfg,
        &owner,
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
pub async fn sunswap_check_approval(
    meta: &SunSwapMeta,
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

    let owner = swapper_tron(&meta.common.account_addr)?;
    build_approval_if_needed(
        &resolved.cfg,
        &owner,
        meta.common.chain_hash,
        from.token.addr.as_str(),
        amount,
        approve_title,
        icon,
    )
    .await
}

#[frb(ignore)]
pub async fn sunswap_prepare_swap(
    meta: &SunSwapMeta,
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
        (RouteKind::Wrap, amount_in)
    } else {
        let owner = swapper_tron(&meta.common.account_addr)?;
        let plan = quote_route(
            meta.common.chain_hash,
            &resolved.cfg,
            &owner,
            &resolved.token_in,
            &resolved.token_out,
            amount,
        )
        .await?;
        (plan.kind, plan.amount_out)
    };

    if cfg!(debug_assertions) {
        eprintln!(
            "[sunswap-prepare] route={route:?} amount_in={amount_in} amount_out={amount_out} \n             slippage_bps={slippage_bps} native_in={} native_out={}",
            from.token.native, resolved.is_native_out
        );
    }

    let blob = QuoteBlob {
        chain_id: resolved.cfg.addrs.chain_id,
        fee_router: resolved.cfg.addrs.fee_router.auto_format(),
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
pub async fn sunswap_finalize_swap(
    meta: &SunSwapMeta,
    quote_blob: &str,
    swap_title: String,
    swap_info: String,
    provider_icon: String,
    out_token: Option<BaseTokenInfo>,
) -> Result<TransactionRequestInfo, String> {
    let blob: QuoteBlob =
        serde_json::from_str(quote_blob).map_err(|e| format!("invalid quote_blob: {e}"))?;
    let cfg = meta.resolve()?;
    let swapper = swapper_tron(&meta.common.account_addr)?;
    build_finalized_swap(
        &cfg,
        &blob,
        meta.common.chain_hash,
        &swapper,
        swap_title,
        swap_info,
        provider_icon,
        out_token,
    )
    .await
}

#[cfg(test)]
mod tests {
    use super::*;

    fn meta(chain_id: u64) -> SunSwapMeta {
        SunSwapMeta {
            common: ProviderCommon {
                chain_hash: 42,
                chain_id,
                slip44: 195,
                account_addr: "TXy123456789012345678901234567890AB".to_string(),
                icon_asset: "assets/icons/sunswap.svg".to_string(),
                display_name: "SunSwap".to_string(),
            },
            cfg: SunSwapCfg::default(),
            quote: None,
        }
    }

    #[test]
    fn meta_for_chain_known_and_unknown() {
        assert!(SunSwapMeta::for_chain(
            42,
            TRON_NILE_CHAIN_ID,
            195,
            "TXy123456789012345678901234567890AB"
        )
        .is_some());
        // Mainnet is now deployed.
        assert!(SunSwapMeta::for_chain(
            42,
            TRON_MAINNET_CHAIN_ID,
            195,
            "TXy123456789012345678901234567890AB"
        )
        .is_some());
        assert!(
            SunSwapMeta::for_chain(42, 1, 195, "TXy123456789012345678901234567890AB").is_none()
        );
    }

    #[test]
    fn resolve_parses_nile_addresses() -> Result<(), String> {
        let cfg = meta(TRON_NILE_CHAIN_ID).resolve()?;
        assert_eq!(cfg.addrs.chain_id, TRON_NILE_CHAIN_ID);
        assert_eq!(cfg.addrs.fee_router.auto_format(), NILE_FEE_ROUTER);
        assert_eq!(cfg.addrs.wtrx.auto_format(), NILE_WTRX);
        assert_eq!(cfg.addrs.quote_lens.auto_format(), NILE_QUOTE_LENS);
        Ok(())
    }

    #[test]
    fn resolve_parses_mainnet_addresses() -> Result<(), String> {
        let cfg = meta(TRON_MAINNET_CHAIN_ID).resolve()?;
        assert_eq!(cfg.addrs.chain_id, TRON_MAINNET_CHAIN_ID);
        assert_eq!(
            cfg.addrs.fee_router.auto_format(),
            MAINNET_FEE_ROUTER.expect("mainnet deployed")
        );
        assert_eq!(cfg.addrs.wtrx.auto_format(), MAINNET_WTRX);
        assert_eq!(
            cfg.addrs.quote_lens.auto_format(),
            MAINNET_QUOTE_LENS.expect("mainnet deployed")
        );
        Ok(())
    }

    #[test]
    fn quote_lens_abi_round_trips() {
        use zilpay::alloy::primitives::aliases::U24;
        use zilpay::alloy::sol_types::SolValue;

        let quote = abi::Quote {
            routeType: ROUTE_V3_SINGLE,
            amountOut: U256::from(123u64),
            fee: U24::from(2_500u64),
            v3Path: Vec::new().into(),
        };
        let bytes = (quote,).abi_encode_params();
        let decoded = decode_quote_lens_return(&bytes).expect("quote decode");
        assert_eq!(decoded.route_type, ROUTE_V3_SINGLE);
        assert_eq!(decoded.amount_out, U256::from(123u64));
        assert_eq!(decoded.fee_tier, 2_500);
        assert!(decoded.v3_path.is_empty());
    }

    #[test]
    fn quote_blob_round_trips_v3() -> Result<(), String> {
        let blob = QuoteBlob {
            chain_id: TRON_NILE_CHAIN_ID,
            fee_router: NILE_FEE_ROUTER.to_string(),
            route: RouteKind::V3 {
                token_in: NILE_WTRX.to_string(),
                token_out: "TLhZ48yfHygMLM2uZr87zJJusHjGen97gh".to_string(),
                fee_tier: 2_500,
            },
            amount_in: "100".to_string(),
            amount_out: "200".to_string(),
            slippage_bps: 50,
            is_native_in: true,
            is_native_out: false,
            recipient: "TXy123456789012345678901234567890AB".to_string(),
        };
        let json = serde_json::to_string(&blob).map_err(|e| e.to_string())?;
        let parsed: QuoteBlob = serde_json::from_str(&json).map_err(|e| e.to_string())?;
        assert_eq!(parsed, blob);
        Ok(())
    }

    #[test]
    fn quote_blob_round_trips_v3path() -> Result<(), String> {
        let blob = QuoteBlob {
            chain_id: TRON_NILE_CHAIN_ID,
            fee_router: NILE_FEE_ROUTER.to_string(),
            route: RouteKind::V3Path {
                // Packed 2-hop path placeholder: `addr ‖ fee ‖ addr ‖ fee ‖ addr`.
                // Round-trip only exercises serde, so a literal hex suffices.
                path: "0x00000000000000000000000094e18ae7dd5ee57b55f30c4b63e2760c09efb1920001f40000000000000000000000002274005778063684fbb1bfa96a2b725dc37d75f9000bb8000000000000000000000000c85b0db68467dede96a7087f4d4c47731555ca7a".to_string(),
            },
            amount_in: "100".to_string(),
            amount_out: "200".to_string(),
            slippage_bps: 50,
            is_native_in: true,
            is_native_out: false,
            recipient: "TXy123456789012345678901234567890AB".to_string(),
        };
        let json = serde_json::to_string(&blob).map_err(|e| e.to_string())?;
        let parsed: QuoteBlob = serde_json::from_str(&json).map_err(|e| e.to_string())?;
        assert_eq!(parsed, blob);
        Ok(())
    }
}
