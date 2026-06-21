use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::U256;
use zilpay::serde::{Deserialize, Serialize};

use super::pools::PoolReserves;
use super::PROXY_FEE_BPS;

pub const FEE: u64 = 9_970;
pub const FEE_DENOM: u64 = 10_000;

#[frb(ignore)]
#[derive(Clone, Copy, PartialEq, Eq, Debug, Serialize, Deserialize)]
#[serde(crate = "zilpay::serde")]
pub enum SwapDirection {
    ZilToToken,
    TokenToZil,
    TokenToTokens,
}

#[frb(ignore)]
#[must_use]
pub const fn resolve_direction(from_native: bool, to_native: bool) -> SwapDirection {
    match (from_native, to_native) {
        (true, _) => SwapDirection::ZilToToken,
        (false, true) => SwapDirection::TokenToZil,
        (false, false) => SwapDirection::TokenToTokens,
    }
}

/// Constant-product output with LP fee. Mirrors zilpay.io `DragonDex._outputFor`.
#[frb(ignore)]
#[must_use]
pub fn output_for(exact: U256, in_reserve: U256, out_reserve: U256) -> U256 {
    let fee = U256::from(FEE);
    let denom = U256::from(FEE_DENOM);
    let after_fee = exact.saturating_mul(fee);
    let numerator = after_fee.saturating_mul(out_reserve);
    let denominator = in_reserve.saturating_mul(denom).saturating_add(after_fee);
    if denominator.is_zero() {
        U256::ZERO
    } else {
        numerator / denominator
    }
}

#[frb(ignore)]
#[must_use]
pub fn apply_bps_cut(amount: U256, bps: u32) -> U256 {
    let denom = U256::from(FEE_DENOM);
    let keep = U256::from(FEE_DENOM.saturating_sub(u64::from(bps)));
    amount.saturating_mul(keep) / denom
}

#[frb(ignore)]
#[must_use]
pub fn two_hop_output(
    amount_in: U256,
    input_zil_reserve: U256,
    input_token_reserve: U256,
    output_zil_reserve: U256,
    output_token_reserve: U256,
) -> U256 {
    let zil = output_for(amount_in, input_token_reserve, input_zil_reserve);
    output_for(zil, output_zil_reserve, output_token_reserve)
}

/// Per-direction net quote after the proxy fee. This is the single source of
/// truth for how each direction applies the 10% proxy cut — tested directly.
///
/// - ZIL→Token: input-side skim (proxy forwards 90% to core)
/// - Token→ZIL: output-side skim (AddFunds forwards 90% to user)
/// - Token→Token: no proxy in the path (core direct, recipient = user)
#[frb(ignore)]
#[must_use]
pub fn net_quote(
    direction: SwapDirection,
    amount_in: U256,
    input_pool: PoolReserves,
    output_pool: Option<PoolReserves>,
) -> U256 {
    match direction {
        SwapDirection::ZilToToken => {
            let net_in = apply_bps_cut(amount_in, PROXY_FEE_BPS);
            output_for(net_in, input_pool.zil, input_pool.token)
        }
        SwapDirection::TokenToZil => {
            let gross = output_for(amount_in, input_pool.token, input_pool.zil);
            apply_bps_cut(gross, PROXY_FEE_BPS)
        }
        SwapDirection::TokenToTokens => {
            let out = output_pool.unwrap_or(input_pool);
            two_hop_output(
                amount_in,
                input_pool.zil,
                input_pool.token,
                out.zil,
                out.token,
            )
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolve_direction_matches_native_edges() {
        assert_eq!(resolve_direction(true, false), SwapDirection::ZilToToken);
        assert_eq!(resolve_direction(false, true), SwapDirection::TokenToZil);
        assert_eq!(
            resolve_direction(false, false),
            SwapDirection::TokenToTokens
        );
        assert_eq!(resolve_direction(true, true), SwapDirection::ZilToToken);
    }

    #[test]
    fn output_for_matches_dragon_dex_formula() {
        let out = output_for(
            U256::from(1_000u64),
            U256::from(10_000u64),
            U256::from(20_000u64),
        );
        assert_eq!(out, U256::from(1_813u64));
    }

    #[test]
    fn apply_bps_cut_applies_basis_points() {
        assert_eq!(
            apply_bps_cut(U256::from(100_000u64), 50),
            U256::from(99_500u64)
        );
    }

    #[test]
    fn two_hop_quote_matches_displayed_get_real_price_path() {
        let out = two_hop_output(
            U256::from(1_000u64),
            U256::from(10_000u64),
            U256::from(20_000u64),
            U256::from(30_000u64),
            U256::from(60_000u64),
        );
        assert_eq!(out, U256::from(930u64));
    }

    fn pool(zil: u64, token: u64) -> PoolReserves {
        PoolReserves {
            zil: U256::from(zil),
            token: U256::from(token),
        }
    }

    #[test]
    fn net_quote_zil_to_token_applies_fee_on_input() {
        // ZIL→Token: net_in = 1000 * 0.9 = 900
        // output = output_for(900, 10_000, 20_000)
        let p = pool(10_000, 20_000);
        let out = net_quote(SwapDirection::ZilToToken, U256::from(1_000u64), p, None);
        let expected_input = U256::from(900u64);
        assert_eq!(out, output_for(expected_input, p.zil, p.token));
        // Input-side cut is mathematically better for the user than output-side
        assert!(
            out > apply_bps_cut(
                output_for(U256::from(1_000u64), p.zil, p.token),
                PROXY_FEE_BPS
            )
        );
    }

    #[test]
    fn net_quote_token_to_zil_applies_fee_on_output() {
        // Token→ZIL: gross = output_for(1000, 20_000, 10_000)
        // net = gross * 0.9
        let p = pool(10_000, 20_000);
        let out = net_quote(SwapDirection::TokenToZil, U256::from(1_000u64), p, None);
        let gross = output_for(U256::from(1_000u64), p.token, p.zil);
        assert_eq!(out, apply_bps_cut(gross, PROXY_FEE_BPS));
    }

    #[test]
    fn net_quote_token_to_token_has_no_fee() {
        // Token→Token: full two-hop output, no proxy fee
        let input = pool(10_000, 20_000);
        let output = pool(30_000, 60_000);
        let out = net_quote(
            SwapDirection::TokenToTokens,
            U256::from(1_000u64),
            input,
            Some(output),
        );
        let expected = two_hop_output(
            U256::from(1_000u64),
            input.zil,
            input.token,
            output.zil,
            output.token,
        );
        assert_eq!(out, expected);
        // Verify no 10% haircut was applied
        assert_eq!(out, U256::from(930u64));
    }
}
