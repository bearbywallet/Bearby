pub mod pancakeswap;
pub mod relay;
pub mod uniswap;
pub mod univ_router;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::Address as AlloyAddress;
use zilpay::crypto::slip44::{BITCOIN, ETHEREUM, SOLANA, TRON, ZILLIQA};

use super::ftoken::FTokenInfo;
use super::transactions::base_token::BaseTokenInfo;
use super::transactions::request::TransactionRequestInfo;
use std::collections::HashSet;

pub use pancakeswap::PancakeMeta;
pub use relay::RelayMeta;
pub use uniswap::UniswapMeta;
pub use univ_router::{PreparedSwap, RouterConfig};

#[derive(Debug, PartialEq, PartialOrd, Eq, Hash, Clone)]
pub enum ExchangeProvider {
    Relay(RelayMeta),
    Uniswap(UniswapMeta),
    PancakeSwap(PancakeMeta),
    ZIlSwap(u64), // TODO: there u64 is plug
    SunSwap(u64), // TODO: there u64 is plug
}

impl ExchangeProvider {
    #[frb(ignore)]
    pub fn is_support(&self, addr_type: u8, slip44: u32, chain_id: u64) -> bool {
        match self {
            Self::Relay(_) => {
                let address_supported = match slip44 {
                    ETHEREUM => addr_type == 1,
                    BITCOIN | SOLANA => true,
                    _ => false,
                };
                address_supported
                    && relay::relay_chain_id(slip44, chain_id)
                        .is_some_and(relay::is_supported_chain)
            }
            Self::Uniswap(_) => addr_type == 1 && uniswap::is_supported_chain(chain_id),
            Self::PancakeSwap(_) => addr_type == 1 && pancakeswap::is_supported_chain(chain_id),
            Self::ZIlSwap(_) => {
                const SLIP44: &[u32] = &[ZILLIQA];
                addr_type == 0 && SLIP44.contains(&slip44)
            }
            Self::SunSwap(_) => {
                const SLIP44: &[u32] = &[TRON];
                addr_type == 4 && SLIP44.contains(&slip44)
            }
        }
    }

    #[frb(ignore)]
    pub const fn is_relay(&self) -> bool {
        matches!(self, Self::Relay(_))
    }

    #[frb(ignore)]
    pub fn is_wrap_unwrap(
        &self,
        from: &ExchangeAsset,
        to: &ExchangeAsset,
        from_asset: &str,
        to_asset: &str,
    ) -> Result<bool, String> {
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_)
                if from.token.chain_hash == to.token.chain_hash =>
            {
                let cfg = self
                    .router_config()
                    .ok_or_else(|| "no engine".to_string())??;
                univ_router::is_wrap_unwrap(&cfg, from_asset, to_asset, from.token.native)
            }
            _ => Ok(false),
        }
    }

    #[frb(ignore)]
    pub async fn quote_info(
        &self,
        from: &ExchangeAsset,
        to: &ExchangeAsset,
        from_asset: &str,
        to_asset: &str,
        amount: &str,
        destination: &str,
    ) -> Result<ExchangeQuoteInfo, String> {
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
                if from.token.chain_hash != to.token.chain_hash {
                    return Err("cross-chain swap not supported".to_string());
                }
                let cfg = self
                    .router_config()
                    .ok_or_else(|| "no engine".to_string())??;
                univ_router::router_quote_info(
                    &cfg,
                    self,
                    from,
                    from_asset,
                    to_asset,
                    amount,
                    destination,
                )
                .await
            }
            Self::Relay(_) => relay::relay_quote_info(self, from, to, amount).await,
            _ => Err("provider not implemented".to_string()),
        }
    }

    #[allow(clippy::too_many_arguments)]
    #[frb(ignore)]
    pub async fn check_approval(
        &self,
        swapper: AlloyAddress,
        chain_hash: u64,
        from: &ExchangeAsset,
        to: &ExchangeAsset,
        amount: &str,
        approve_title: String,
        provider_icon: String,
    ) -> Result<Option<TransactionRequestInfo>, String> {
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
                if from.token.native {
                    return Ok(None);
                }
                let cfg = self
                    .router_config()
                    .ok_or_else(|| "no engine".to_string())??;
                univ_router::router_check_approval(
                    &cfg,
                    swapper,
                    chain_hash,
                    from.token.addr.as_str(),
                    amount,
                    approve_title,
                    provider_icon,
                )
                .await
            }
            Self::Relay(_) => {
                if from.token.native {
                    return Ok(None);
                }
                relay::relay_check_approval(
                    swapper,
                    chain_hash,
                    from,
                    to,
                    amount,
                    approve_title,
                    provider_icon,
                )
                .await
            }
            _ => Ok(None),
        }
    }

    #[allow(clippy::too_many_arguments)]
    #[frb(ignore)]
    pub async fn prepare_swap(
        &self,
        swapper: AlloyAddress,
        chain_hash: u64,
        from: &ExchangeAsset,
        to: &ExchangeAsset,
        amount: &str,
        slippage_bps: u32,
    ) -> Result<PreparedSwap, String> {
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
                if from.token.chain_hash != to.token.chain_hash {
                    return Err("cross-chain swap not supported".to_string());
                }
                let cfg = self
                    .router_config()
                    .ok_or_else(|| "no engine".to_string())??;
                univ_router::prepare_router_swap(
                    &cfg,
                    swapper,
                    chain_hash,
                    from.token.addr.as_str(),
                    to.token.addr.as_str(),
                    amount,
                    slippage_bps,
                    from.token.native,
                )
                .await
            }
            Self::Relay(_) => relay::relay_prepare_swap(from, to, amount).await,
            _ => Err("provider not implemented".to_string()),
        }
    }

    #[allow(clippy::too_many_arguments)]
    #[frb(ignore)]
    pub async fn finalize_swap(
        &self,
        quote_blob: &str,
        swapper: AlloyAddress,
        chain_hash: u64,
        permit_signature: Option<&str>,
        swap_title: String,
        swap_info: String,
        provider_icon: String,
        out_token: Option<BaseTokenInfo>,
    ) -> Result<TransactionRequestInfo, String> {
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
                univ_router::finalize_router_swap(
                    quote_blob,
                    swapper,
                    chain_hash,
                    permit_signature,
                    swap_title,
                    swap_info,
                    provider_icon,
                    out_token,
                )
                .await
            }
            Self::Relay(_) => {
                relay::relay_finalize_swap(
                    quote_blob,
                    swapper,
                    chain_hash,
                    swap_title,
                    swap_info,
                    provider_icon,
                    out_token,
                )
                .await
            }
            _ => Err("provider not implemented".to_string()),
        }
    }

    /// Resolve the shared Universal-Router engine config for the EVM-DEX variants
    /// (Uniswap, PancakeSwap). `None` for non-Universal-Router providers. This is the single
    /// place that maps a provider to its [`RouterConfig`], collapsing the per-function match
    /// arms in `api/exchange.rs`.
    #[frb(ignore)]
    pub fn router_config(&self) -> Option<Result<RouterConfig, String>> {
        match self {
            Self::Uniswap(m) => Some(m.resolve()),
            Self::PancakeSwap(m) => Some(m.resolve()),
            _ => None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct ExchangeAsset {
    pub token: FTokenInfo,
    pub providers: HashSet<ExchangeProvider>,
    pub halted: bool,
}

impl ExchangeAsset {
    #[frb(ignore)]
    pub fn relay_meta(&self) -> Option<&RelayMeta> {
        self.providers.iter().find_map(|provider| match provider {
            ExchangeProvider::Relay(meta) => Some(meta),
            _ => None,
        })
    }
}

/// Display metadata composed on the Dart side and threaded into every tx built for a swap.
/// Passed as a single struct to keep the FFI surface small.
#[derive(Debug, Clone)]
pub struct ExchangeTxDisplay {
    /// Flutter local asset path, e.g. `"assets/icons/uniswap.svg"`.
    pub provider_icon: String,
    /// History title for the swap tx: `"Swap"`.
    pub swap_title: String,
    /// History detail line: `"1.5 BNB → 120 CAKE · Uniswap"`.
    pub swap_info: String,
    /// History title for the approve tx: `"Approve WORM"`.
    pub approve_title: String,
    /// History title for the software permit entry: `"Permit2 · Uniswap"`.
    pub permit_title: String,
    /// Destination token with the expected `amountOut` as `value` (wei string).
    pub out_token: Option<BaseTokenInfo>,
}

#[derive(Debug)]
pub struct ExchangeQuoteInfo {
    pub provider: ExchangeProvider,
    pub amount_out: String,
    /// Standard EIP-712 typed-data JSON to sign (Permit2). `None` for native input or
    /// when the API returns no permit (`permitData: null`).
    pub permit_typed_data_json: Option<String>,
    /// `true` when this is a 1:1 native ↔ wrapped-native wrap/unwrap (no router, no approval/
    /// permit, no fee). The UI renders it as "Wrap"/"Unwrap" and runs a single-step flow.
    pub is_wrap_unwrap: bool,
}
