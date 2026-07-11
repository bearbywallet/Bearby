//! Display quote via the Bearby proxy (`POST /api/exchange/quote`).
//!
//! The proxy takes human decimal amounts as JSON numbers; the response
//! `toAsset.amount` is a decimal string that we convert back to base units
//! with string math so no precision is lost on the way out.

use flutter_rust_bridge::frb;
use zilpay::serde::Deserialize;
use zilpay::serde_json::json;

use crate::models::exchange::{ExchangeAsset, ExchangeProvider, ProviderQuote};

use super::{assets, client, WhiteBirdMeta};

/// Render a base-unit integer amount as a decimal string ("1250000", 6 → "1.25").
#[frb(ignore)]
pub fn base_units_to_decimal(amount_base: &str, decimals: u8) -> Result<String, String> {
    let digits = amount_base.trim();
    if digits.is_empty() || !digits.bytes().all(|b| b.is_ascii_digit()) {
        return Err(format!("invalid base amount: {amount_base}"));
    }
    let decimals = decimals as usize;
    let padded = if digits.len() <= decimals {
        format!("{digits:0>width$}", width = decimals + 1)
    } else {
        digits.to_owned()
    };
    let split = padded.len() - decimals;
    let (int_part, frac_part) = padded.split_at(split);
    let frac_trimmed = frac_part.trim_end_matches('0');
    if frac_trimmed.is_empty() {
        Ok(int_part.to_owned())
    } else {
        Ok(format!("{int_part}.{frac_trimmed}"))
    }
}

/// Parse a decimal string into base units ("1.25", 6 → "1250000"), truncating
/// fractional digits beyond `decimals`.
#[frb(ignore)]
pub fn decimal_to_base_units(amount: &str, decimals: u8) -> Result<String, String> {
    let trimmed = amount.trim();
    let (int_part, frac_part) = match trimmed.split_once('.') {
        Some((i, f)) => (i, f),
        None => (trimmed, ""),
    };
    if int_part.is_empty() && frac_part.is_empty() {
        return Err(format!("invalid decimal amount: {amount}"));
    }
    if !int_part.bytes().all(|b| b.is_ascii_digit())
        || !frac_part.bytes().all(|b| b.is_ascii_digit())
    {
        return Err(format!("invalid decimal amount: {amount}"));
    }
    let decimals = decimals as usize;
    let frac_scaled = if frac_part.len() >= decimals {
        frac_part[..decimals].to_owned()
    } else {
        format!("{frac_part:0<decimals$}")
    };
    let joined = format!("{int_part}{frac_scaled}");
    let stripped = joined.trim_start_matches('0');
    Ok(if stripped.is_empty() {
        "0".to_owned()
    } else {
        stripped.to_owned()
    })
}

#[frb(ignore)]
pub fn whitebird_meta(asset: &ExchangeAsset) -> Option<&WhiteBirdMeta> {
    asset.providers.iter().find_map(|provider| match provider {
        ExchangeProvider::WhiteBird(meta) => Some(meta),
        _ => None,
    })
}

#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct QuoteAssetBody {
    amount: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(crate = "zilpay::serde", rename_all = "camelCase")]
struct QuoteBody {
    to_asset: QuoteAssetBody,
}

/// Fiat↔crypto quote between two WhiteBird-routed assets.
#[frb(ignore)]
pub async fn quote_pair(
    meta: &WhiteBirdMeta,
    from: &ExchangeAsset,
    to: &ExchangeAsset,
    amount_base: &str,
) -> Result<ProviderQuote, String> {
    let to_meta = whitebird_meta(to).ok_or("counterparty has no WhiteBird route")?;
    if meta.is_fiat == to_meta.is_fiat {
        return Err("WhiteBird routes fiat<->crypto only".to_owned());
    }

    let from_human = base_units_to_decimal(amount_base, from.token.decimals)?;
    let from_amount: f64 = from_human
        .parse()
        .map_err(|e| format!("amount parse: {e}"))?;
    if from_amount <= 0.0 {
        return Err("amount must be positive".to_owned());
    }

    let body = json!({
        "fromAsset": {
            "code": meta.asset_code,
            "network": assets::network_for_code(&meta.asset_code),
            "amount": from_amount,
        },
        "toAsset": {
            "code": to_meta.asset_code,
            "network": assets::network_for_code(&to_meta.asset_code),
        },
    });

    let resp: QuoteBody = client::post_json(meta.is_testnet, "/api/exchange/quote", &body).await?;
    let amount_out = resp
        .to_asset
        .amount
        .filter(|s| !s.is_empty())
        .ok_or("quote response missing toAsset.amount")?;

    Ok(ProviderQuote {
        amount_out: decimal_to_base_units(&amount_out, to.token.decimals)?,
        permit_typed_data_json: None,
        is_wrap_unwrap: false,
    })
}

#[cfg(test)]
mod tests {
    use super::{base_units_to_decimal, decimal_to_base_units};

    #[test]
    fn base_units_render_and_parse_roundtrip() {
        assert_eq!(base_units_to_decimal("1250000", 6).as_deref(), Ok("1.25"));
        assert_eq!(base_units_to_decimal("50", 2).as_deref(), Ok("0.5"));
        assert_eq!(base_units_to_decimal("100", 0).as_deref(), Ok("100"));
        assert_eq!(decimal_to_base_units("1.25", 6).as_deref(), Ok("1250000"));
        assert_eq!(decimal_to_base_units("91.67", 2).as_deref(), Ok("9167"));
        assert_eq!(decimal_to_base_units("0.1234567", 6).as_deref(), Ok("123456"));
        assert_eq!(decimal_to_base_units("0", 2).as_deref(), Ok("0"));
    }

    #[test]
    fn invalid_amounts_are_rejected() {
        assert!(base_units_to_decimal("12.5", 6).is_err());
        assert!(base_units_to_decimal("", 6).is_err());
        assert!(decimal_to_base_units("1,5", 2).is_err());
        assert!(decimal_to_base_units("", 2).is_err());
    }
}
