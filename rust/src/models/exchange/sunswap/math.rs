use std::borrow::Cow;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::{Address, U256};

use super::PROXY_FEE_BPS;
use crate::models::exchange::univ_router::NATIVE_SENTINEL;

const BPS_DENOMINATOR: u32 = 10_000;

#[frb(ignore)]
#[must_use]
pub(super) fn apply_bps_cut(amount: U256, bps: u32) -> U256 {
    let keep_bps = BPS_DENOMINATOR.saturating_sub(bps);
    amount.saturating_mul(U256::from(keep_bps)) / U256::from(BPS_DENOMINATOR)
}

#[frb(ignore)]
#[must_use]
pub(super) fn amount_in_after_fee(amount: U256) -> U256 {
    apply_bps_cut(amount, PROXY_FEE_BPS)
}

#[frb(ignore)]
#[must_use]
pub(super) fn amount_out_min(amount_out: U256, slippage_bps: u32) -> U256 {
    apply_bps_cut(amount_out, slippage_bps)
}

fn resolve_out(to_asset: &str, source_chain: u64) -> Result<(Cow<'_, str>, bool), String> {
    if let Some((chain_part, addr)) = to_asset.split_once(':') {
        if !chain_part.is_empty() && chain_part.bytes().all(|b| b.is_ascii_digit()) {
            let chain = chain_part
                .parse::<u64>()
                .map_err(|_| "invalid chain id".to_string())?;
            if chain != source_chain {
                return Err("cross-chain swap not supported".to_string());
            }
            let is_native = addr == NATIVE_SENTINEL || addr.is_empty();
            return Ok((Cow::Borrowed(addr), is_native));
        }
    }

    let is_native = to_asset == NATIVE_SENTINEL || to_asset.is_empty();
    Ok((Cow::Borrowed(to_asset), is_native))
}

const fn resolve_in<'a>(is_native_in: bool, wzil: &'a str, from_asset: &'a str) -> Cow<'a, str> {
    if is_native_in {
        Cow::Borrowed(wzil)
    } else {
        Cow::Borrowed(from_asset)
    }
}

#[frb(ignore)]
pub(super) fn resolve_pair(
    chain_id: u64,
    wtrx: Address,
    from_asset: &str,
    to_asset: &str,
    is_native_in: bool,
) -> Result<(String, String, bool, bool), String> {
    let wtrx_hex = wtrx.to_string();
    let (resolved_out, is_native_out) = resolve_out(to_asset, chain_id)?;
    let token_out = if is_native_out {
        Cow::Borrowed(wtrx_hex.as_str())
    } else {
        resolved_out
    };
    let token_in = resolve_in(is_native_in, &wtrx_hex, from_asset);
    let is_wrap_unwrap =
        token_in.eq_ignore_ascii_case(&wtrx_hex) && token_out.eq_ignore_ascii_case(&wtrx_hex);

    Ok((
        token_in.into_owned(),
        token_out.into_owned(),
        is_native_out,
        is_wrap_unwrap,
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn addr(byte: u8) -> Address {
        Address::from([byte; 20])
    }

    #[test]
    fn post_fee_input_uses_proxy_fee_bps() {
        assert_eq!(
            amount_in_after_fee(U256::from(100_000u64)),
            U256::from(99_000u64)
        );
    }

    #[test]
    fn slippage_cut_uses_basis_points() {
        assert_eq!(
            amount_out_min(U256::from(100_000u64), 50),
            U256::from(99_500u64)
        );
    }

    #[test]
    fn resolve_pair_substitutes_wtrx_for_native_edges() -> Result<(), String> {
        let wtrx = addr(0x94);
        let token = addr(0x42).to_string();
        let (token_in, token_out, native_out, wrap) =
            resolve_pair(3_448_148_188, wtrx, NATIVE_SENTINEL, &token, true)?;
        assert_eq!(token_in, wtrx.to_string());
        assert_eq!(token_out, token);
        assert!(!native_out);
        assert!(!wrap);

        let (token_in, token_out, native_out, wrap) =
            resolve_pair(3_448_148_188, wtrx, &wtrx.to_string(), NATIVE_SENTINEL, false)?;
        assert_eq!(token_in, wtrx.to_string());
        assert_eq!(token_out, wtrx.to_string());
        assert!(native_out);
        assert!(wrap);
        Ok(())
    }

    #[test]
    fn resolve_pair_rejects_cross_chain_output() {
        let err = resolve_pair(3_448_148_188, addr(0x94), NATIVE_SENTINEL, "1:0xabc", true)
            .err()
            .unwrap_or_default();
        assert!(err.contains("cross-chain"));
    }
}
