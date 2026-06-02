//! PancakeSwap deployment table (`infinity-universal-router`). The quoting/swap-building logic
//! is shared with Uniswap via the [`super::univ_router`] engine — PancakeSwap's Universal Router
//! is a fork with byte-for-byte identical command opcodes, so this module only carries the
//! per-chain addresses and PancakeSwap V3's fee tiers.
//!
//! Only chains with a confirmed router **and** QuoterV2 are enabled. The five `0.0001`-salt
//! chains (ETH/Arbitrum/Linea/zkEVM/opBNB) deploy the router via a CREATE3 factory under a salt
//! whose address is not recorded in the contracts repo — they're left out of [`SUPPORTED_CHAINS`]
//! until their router (and, for zkEVM, QuoterV2) address is confirmed.

use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::Address;

use super::univ_router::{RouterAddrs, RouterConfig};

/// PancakeSwap V3 fee tiers (bips * 100): 0.01% / 0.05% / 0.25% / 1.00%.
/// Note the 0.25% tier (`2500`) where Uniswap uses 0.30% (`3000`).
const PANCAKE_FEE_TIERS: &[u32] = &[100, 500, 2500, 10000];

/// PancakeSwap's own Permit2 fork — identical address on every chain.
/// Source: every `infinity-universal-router/script/.../Deploy*.s.sol`.
const PERMIT2: &str = "0x31c2F6fcFf4F8759b3Bd5Bf0e1084A055615c768";

/// Chains with a confirmed Universal Router + QuoterV2 deployment.
const SUPPORTED_CHAINS: &[u64] = &[56, 8453];

#[frb(ignore)]
pub fn is_supported_chain(chain_id: u64) -> bool {
    SUPPORTED_CHAINS.contains(&chain_id)
}

/// FFI-safe PancakeSwap marker. Only the source chain id is needed — deployment addresses
/// are resolved internally from a const table via [`PancakeMeta::resolve`].
#[derive(Debug, Default, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct PancakeMeta {
    pub chain_id: u64,
}

impl PancakeMeta {
    /// `Some` iff `chain_id` has Universal Router + QuoterV2 deployments.
    #[frb(ignore)]
    pub fn for_chain(chain_id: u64) -> Option<Self> {
        is_supported_chain(chain_id).then_some(Self { chain_id })
    }

    /// Parse the deployment table into the engine's [`RouterConfig`].
    ///
    /// Router addresses are confirmed from `infinity-universal-router/deploy-addresses/`
    /// (CREATE3 salt `INFINITY-UNIVERSAL-ROUTER/UniversalRouter/1.0.0`). QuoterV2 addresses are
    /// PancakeSwap V3 periphery (not in the router repo).
    #[frb(ignore)]
    pub fn resolve(&self) -> Result<RouterConfig, String> {
        let (universal_router, quoter_v2, weth) = match self.chain_id {
            // BNB Chain (wrapped native = WBNB)
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
                chain_id: self.chain_id,
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

    #[test]
    fn meta_for_chain_known_and_unknown() {
        assert!(PancakeMeta::for_chain(56).is_some());
        assert!(PancakeMeta::for_chain(8453).is_some());
        // 0.0001-salt chains are gated until their router address is confirmed.
        assert!(PancakeMeta::for_chain(1).is_none());
        assert!(PancakeMeta::for_chain(999).is_none());
    }

    #[test]
    fn meta_resolve_bsc() {
        let cfg = PancakeMeta::for_chain(56).unwrap().resolve().unwrap();
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
        let cfg = PancakeMeta::for_chain(8453).unwrap().resolve().unwrap();
        assert_eq!(
            cfg.addrs.universal_router,
            Address::from_str("0xd9C500DfF816a1Da21A48A732d3498Bf09dc9AEB").unwrap()
        );
    }

    #[test]
    fn meta_resolve_unsupported_chain() {
        let meta = PancakeMeta { chain_id: 1 };
        assert!(meta.resolve().is_err());
    }

    #[test]
    fn pancake_uses_v3_025_percent_tier() {
        assert!(PANCAKE_FEE_TIERS.contains(&2500));
        assert!(!PANCAKE_FEE_TIERS.contains(&3000));
    }
}
