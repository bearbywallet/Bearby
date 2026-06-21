//! Uniswap deployment table. The actual quoting/swap-building logic lives in the shared
//! [`super::univ_router`] engine; this module only maps a source `chain_id` to Uniswap's
//! Universal Router + QuoterV2 + Permit2 + WETH addresses and its V3 fee tiers.

use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::Address;

use super::univ_router::{RouterAddrs, RouterConfig};
use super::{ProviderCommon, ProviderQuote};

/// Uniswap V3 fee tiers (bips * 100): 0.01% / 0.05% / 0.30% / 1.00%.
pub const UNISWAP_FEE_TIERS: &[u32] = &[100, 500, 3000, 10000];

/// Canonical Permit2, identical on every Uniswap chain.
const PERMIT2: &str = "0x000000000022D473030F116dDEE9F6B43aC78BA3";

/// Chains the Universal Router is deployed on.
const SUPPORTED_CHAINS: &[u64] = &[1, 10, 56, 137, 8453, 42161];

#[frb(ignore)]
pub fn is_supported_chain(chain_id: u64) -> bool {
    SUPPORTED_CHAINS.contains(&chain_id)
}

#[derive(Debug, Clone, Copy)]
pub struct UniswapCfg {
    pub default_slippage_bps: u32,
    pub supports_price_protection: bool,
}

impl UniswapCfg {
    pub const fn default() -> Self {
        Self {
            default_slippage_bps: 50,
            supports_price_protection: true,
        }
    }
}

/// FFI-safe Uniswap metadata. Quote data is mutable route state and is excluded from identity.
#[derive(Debug, Clone)]
pub struct UniswapMeta {
    pub common: ProviderCommon,
    pub cfg: UniswapCfg,
    pub quote: Option<ProviderQuote>,
}

impl UniswapMeta {
    /// `Some` iff `chain_id` has Universal Router + QuoterV2 deployments.
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
                icon_asset: "assets/icons/uniswap.svg".to_owned(),
                display_name: "Uniswap".to_owned(),
            },
            cfg: UniswapCfg::default(),
            quote: None,
        })
    }

    /// Parse the deployment table into the engine's [`RouterConfig`].
    #[frb(ignore)]
    pub fn resolve(&self) -> Result<RouterConfig, String> {
        let (universal_router, quoter_v2, weth) = match self.common.chain_id {
            1 => (
                "0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af",
                "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
                "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            ),
            10 => (
                "0x851116D9223fabED8E56C0E6b8Ad0c31d98b3507",
                "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
                "0x4200000000000000000000000000000000000006",
            ),
            56 => (
                "0x1906c1d672b88cd1b9ac7593301ca990f94eae07",
                "0x78D78E420Da98ad378D7799bE8f4AF69033EB077",
                "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
            ),
            137 => (
                "0x1095692A6237d83C6a72F3F5eFEdb9A670C49223",
                "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
                "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
            ),
            8453 => (
                "0x6fF5693b99212Da76ad316178A184AB56D299b43",
                "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a",
                "0x4200000000000000000000000000000000000006",
            ),
            42161 => (
                "0xA51afAFe0263b40EdaEf0Df8781eA9aa03E381a3",
                "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
                "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
            ),
            _ => return Err("unsupported chain".to_string()),
        };

        let parse = |s: &str| Address::from_str(s).map_err(|e| e.to_string());
        Ok(RouterConfig {
            addrs: RouterAddrs {
                chain_id: self.common.chain_id,
                universal_router: parse(universal_router)?,
                quoter_v2: parse(quoter_v2)?,
                permit2: parse(PERMIT2)?,
                weth: parse(weth)?,
            },
            fee_tiers: UNISWAP_FEE_TIERS,
        })
    }
}

#[cfg(test)]
mod uniswap_tests {
    use super::*;

    fn meta(chain_id: u64) -> UniswapMeta {
        UniswapMeta::for_chain(
            42,
            chain_id,
            60,
            "0x0000000000000000000000000000000000000001",
        )
        .unwrap()
    }

    #[test]
    fn meta_for_chain_known_and_unknown() {
        assert!(
            UniswapMeta::for_chain(42, 1, 60, "0x0000000000000000000000000000000000000001")
                .is_some()
        );
        assert!(
            UniswapMeta::for_chain(42, 56, 60, "0x0000000000000000000000000000000000000001")
                .is_some()
        );
        assert!(
            UniswapMeta::for_chain(42, 8453, 60, "0x0000000000000000000000000000000000000001")
                .is_some()
        );
        assert!(
            UniswapMeta::for_chain(42, 999, 60, "0x0000000000000000000000000000000000000001")
                .is_none()
        );
    }

    #[test]
    fn meta_resolve_bsc() {
        let cfg = meta(56).resolve().unwrap();
        assert_eq!(cfg.addrs.chain_id, 56);
        assert_eq!(cfg.fee_tiers, UNISWAP_FEE_TIERS);
        assert_eq!(
            cfg.addrs.universal_router,
            Address::from_str("0x1906c1d672b88cd1b9ac7593301ca990f94eae07").unwrap()
        );
        assert_eq!(
            cfg.addrs.quoter_v2,
            Address::from_str("0x78D78E420Da98ad378D7799bE8f4AF69033EB077").unwrap()
        );
        assert_eq!(
            cfg.addrs.weth,
            Address::from_str("0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c").unwrap()
        );
    }

    #[test]
    fn meta_resolve_parses_addresses() {
        let cfg = meta(1).resolve().unwrap();
        assert_eq!(cfg.addrs.chain_id, 1);
        assert_eq!(
            cfg.addrs.universal_router,
            Address::from_str("0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af").unwrap()
        );
        assert_eq!(
            cfg.addrs.permit2,
            Address::from_str("0x000000000022D473030F116dDEE9F6B43aC78BA3").unwrap()
        );
    }

    #[test]
    fn meta_resolve_unsupported_chain() {
        let meta = UniswapMeta {
            common: ProviderCommon {
                chain_hash: 42,
                chain_id: 999,
                slip44: 60,
                account_addr: String::new(),
                icon_asset: String::new(),
                display_name: String::new(),
            },
            cfg: UniswapCfg::default(),
            quote: None,
        };
        assert!(meta.resolve().is_err());
    }

    #[test]
    fn is_supported_chain_returns_true_for_deployed() {
        assert!(is_supported_chain(1));
        assert!(is_supported_chain(56));
        assert!(is_supported_chain(42161));
        assert!(!is_supported_chain(999));
    }
}
