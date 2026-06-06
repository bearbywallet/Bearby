//! PancakeSwap deployment table (`infinity-universal-router`). The quoting/swap-building logic
//! is shared with Uniswap via the [`super::univ_router`] engine.

use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::Address;

use super::univ_router::{RouterAddrs, RouterConfig};
use super::{ProviderCommon, ProviderQuote};

/// PancakeSwap V3 fee tiers (bips * 100): 0.01% / 0.05% / 0.25% / 1.00%.
pub const PANCAKE_FEE_TIERS: &[u32] = &[100, 500, 2500, 10000];

/// PancakeSwap's own Permit2 fork — identical address on every chain.
const PERMIT2: &str = "0x31c2F6fcFf4F8759b3Bd5Bf0e1084A055615c768";

/// Chains with a confirmed Universal Router + QuoterV2 deployment.
const SUPPORTED_CHAINS: &[u64] = &[56, 8453];

#[frb(ignore)]
pub fn is_supported_chain(chain_id: u64) -> bool {
    SUPPORTED_CHAINS.contains(&chain_id)
}

#[derive(Debug, Clone, Copy)]
pub struct PancakeCfg {
    pub default_slippage_bps: u32,
    pub supports_price_protection: bool,
}

impl PancakeCfg {
    pub const fn default() -> Self {
        Self {
            default_slippage_bps: 80,
            supports_price_protection: true,
        }
    }
}

/// FFI-safe PancakeSwap metadata. Quote data is excluded from identity.
#[derive(Debug, Clone)]
pub struct PancakeMeta {
    pub common: ProviderCommon,
    pub cfg: PancakeCfg,
    pub quote: Option<ProviderQuote>,
}

impl PancakeMeta {
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
                icon_asset: "assets/icons/pancakeswap.svg".to_owned(),
                display_name: "PancakeSwap".to_owned(),
            },
            cfg: PancakeCfg::default(),
            quote: None,
        })
    }

    /// Parse the deployment table into the engine's [`RouterConfig`].
    #[frb(ignore)]
    pub fn resolve(&self) -> Result<RouterConfig, String> {
        let (universal_router, quoter_v2, weth) = match self.common.chain_id {
            56 => (
                "0xd9C500DfF816a1Da21A48A732d3498Bf09dc9AEB",
                "0xB048Bbc1Ee6b733FFfCFb9e9CeF7375518e25997",
                "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
            ),
            8453 => (
                "0xd9C500DfF816a1Da21A48A732d3498Bf09dc9AEB",
                "0xB048Bbc1Ee6b733FFfCFb9e9CeF7375518e25997",
                "0x4200000000000000000000000000000000000006",
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
            fee_tiers: PANCAKE_FEE_TIERS,
        })
    }
}

#[cfg(test)]
mod pancakeswap_tests {
    use super::*;

    fn meta(chain_id: u64) -> PancakeMeta {
        PancakeMeta::for_chain(
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
            PancakeMeta::for_chain(42, 56, 60, "0x0000000000000000000000000000000000000001")
                .is_some()
        );
        assert!(
            PancakeMeta::for_chain(42, 8453, 60, "0x0000000000000000000000000000000000000001")
                .is_some()
        );
        assert!(
            PancakeMeta::for_chain(42, 1, 60, "0x0000000000000000000000000000000000000001")
                .is_none()
        );
        assert!(
            PancakeMeta::for_chain(42, 999, 60, "0x0000000000000000000000000000000000000001")
                .is_none()
        );
    }

    #[test]
    fn meta_resolve_bsc() {
        let cfg = meta(56).resolve().unwrap();
        assert_eq!(cfg.addrs.chain_id, 56);
        assert_eq!(cfg.fee_tiers, PANCAKE_FEE_TIERS);
        assert_eq!(
            cfg.addrs.universal_router,
            Address::from_str("0xd9C500DfF816a1Da21A48A732d3498Bf09dc9AEB").unwrap()
        );
        assert_eq!(
            cfg.addrs.quoter_v2,
            Address::from_str("0xB048Bbc1Ee6b733FFfCFb9e9CeF7375518e25997").unwrap()
        );
        assert_eq!(
            cfg.addrs.permit2,
            Address::from_str("0x31c2F6fcFf4F8759b3Bd5Bf0e1084A055615c768").unwrap()
        );
        assert_eq!(
            cfg.addrs.weth,
            Address::from_str("0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c").unwrap()
        );
    }

    #[test]
    fn meta_resolve_base_shares_router() {
        let cfg = meta(8453).resolve().unwrap();
        assert_eq!(
            cfg.addrs.universal_router,
            Address::from_str("0xd9C500DfF816a1Da21A48A732d3498Bf09dc9AEB").unwrap()
        );
    }

    #[test]
    fn meta_resolve_unsupported_chain() {
        let meta = PancakeMeta {
            common: ProviderCommon {
                chain_hash: 42,
                chain_id: 1,
                slip44: 60,
                account_addr: String::new(),
                icon_asset: String::new(),
                display_name: String::new(),
            },
            cfg: PancakeCfg::default(),
            quote: None,
        };
        assert!(meta.resolve().is_err());
    }

    #[test]
    fn pancake_uses_v3_025_percent_tier() {
        assert!(PANCAKE_FEE_TIERS.contains(&2500));
        assert!(!PANCAKE_FEE_TIERS.contains(&3000));
    }
}
