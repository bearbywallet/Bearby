pub mod pancakeswap;
pub mod plunderswap;
pub mod relay;
pub mod sunswap;
pub mod uniswap;
pub mod univ_router;
pub mod zilswap;

use std::borrow::Cow;
use std::collections::HashSet;
use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::Address as AlloyAddress;
use zilpay::crypto::slip44::{TRON, ZILLIQA};

use super::ftoken::FTokenInfo;
use super::transactions::base_token::BaseTokenInfo;
use super::transactions::request::TransactionRequestInfo;

pub use pancakeswap::PancakeMeta;
pub use plunderswap::PlunderMeta;
pub use relay::RelayMeta;
pub use sunswap::SunSwapMeta;
pub use uniswap::UniswapMeta;
pub use univ_router::{PreparedSwap, RouterConfig};

/// Unified chain + account context shared by every provider variant.
/// Participates in Hash/Eq/Ord and forms the provider identity key.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct ProviderCommon {
    pub chain_hash: u64,
    pub chain_id: u64,
    pub slip44: u32,
    pub account_addr: String,
    pub icon_asset: String,
    pub display_name: String,
}

/// Per-provider quote result populated by quote refresh.
/// Excluded from provider identity by the meta type implementations.
#[derive(Debug, Clone)]
pub struct ProviderQuote {
    pub amount_out: String,
    pub permit_typed_data_json: Option<String>,
    pub is_wrap_unwrap: bool,
}

#[derive(Debug, Clone)]
pub struct ZilSwapMeta {
    pub common: ProviderCommon,
    pub quote: Option<ProviderQuote>,
}

impl ZilSwapMeta {
    #[frb(ignore)]
    pub fn for_chain(
        chain_hash: u64,
        chain_id: u64,
        slip44: u32,
        account_addr: &str,
    ) -> Option<Self> {
        zilswap::is_supported_chain(chain_id).then(|| Self {
            common: ProviderCommon {
                chain_hash,
                chain_id,
                slip44,
                account_addr: account_addr.to_owned(),
                icon_asset: "assets/icons/zilswap.svg".to_owned(),
                display_name: "ZilSwap".to_owned(),
            },
            quote: None,
        })
    }
}

macro_rules! identity_from_common {
    ($ty:ty) => {
        impl PartialEq for $ty {
            fn eq(&self, other: &Self) -> bool {
                self.common == other.common
            }
        }
        impl Eq for $ty {}
        impl std::hash::Hash for $ty {
            fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
                self.common.hash(state);
            }
        }
        impl PartialOrd for $ty {
            fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
                Some(self.cmp(other))
            }
        }
        impl Ord for $ty {
            fn cmp(&self, other: &Self) -> std::cmp::Ordering {
                self.common.cmp(&other.common)
            }
        }
    };
}

identity_from_common!(RelayMeta);
identity_from_common!(UniswapMeta);
identity_from_common!(PancakeMeta);
identity_from_common!(PlunderMeta);
identity_from_common!(ZilSwapMeta);
identity_from_common!(SunSwapMeta);

#[derive(Debug, PartialEq, PartialOrd, Eq, Hash, Clone)]
pub enum ExchangeProvider {
    Relay(RelayMeta),
    Uniswap(UniswapMeta),
    PancakeSwap(PancakeMeta),
    PlunderSwap(PlunderMeta),
    ZilSwap(ZilSwapMeta),
    SunSwap(SunSwapMeta),
}

impl ExchangeProvider {
    /// `true` for bridge providers that can route across chains (Relay).
    /// `false` for same-chain DEX providers (Uniswap, PancakeSwap, PlunderSwap, ZilSwap, SunSwap).
    #[frb(ignore)]
    pub const fn is_bridge(&self) -> bool {
        matches!(self, Self::Relay(_))
    }

    #[frb(ignore)]
    pub fn common(&self) -> &ProviderCommon {
        match self {
            Self::Relay(m) => &m.common,
            Self::Uniswap(m) => &m.common,
            Self::PancakeSwap(m) => &m.common,
            Self::PlunderSwap(m) => &m.common,
            Self::ZilSwap(m) => &m.common,
            Self::SunSwap(m) => &m.common,
        }
    }

    #[frb(ignore)]
    pub fn quote(&self) -> Option<&ProviderQuote> {
        match self {
            Self::Relay(m) => m.quote.as_ref(),
            Self::Uniswap(m) => m.quote.as_ref(),
            Self::PancakeSwap(m) => m.quote.as_ref(),
            Self::PlunderSwap(m) => m.quote.as_ref(),
            Self::ZilSwap(m) => m.quote.as_ref(),
            Self::SunSwap(m) => m.quote.as_ref(),
        }
    }

    #[frb(ignore)]
    fn set_quote(self, quote: Option<ProviderQuote>) -> Self {
        match self {
            Self::Relay(mut m) => {
                m.quote = quote;
                Self::Relay(m)
            }
            Self::Uniswap(mut m) => {
                m.quote = quote;
                Self::Uniswap(m)
            }
            Self::PancakeSwap(mut m) => {
                m.quote = quote;
                Self::PancakeSwap(m)
            }
            Self::PlunderSwap(mut m) => {
                m.quote = quote;
                Self::PlunderSwap(m)
            }
            Self::ZilSwap(mut m) => {
                m.quote = quote;
                Self::ZilSwap(m)
            }
            Self::SunSwap(mut m) => {
                m.quote = quote;
                Self::SunSwap(m)
            }
        }
    }

    #[frb(ignore)]
    pub fn with_quote(self, quote: ProviderQuote) -> Self {
        self.set_quote(Some(quote))
    }

    #[frb(ignore)]
    pub fn without_quote(self) -> Self {
        self.set_quote(None)
    }

    #[frb(ignore)]
    pub fn default_slippage_bps(&self) -> u32 {
        match self {
            Self::Uniswap(m) => m.cfg.default_slippage_bps,
            Self::PancakeSwap(m) => m.cfg.default_slippage_bps,
            Self::PlunderSwap(m) => m.cfg.default_slippage_bps,
            Self::SunSwap(m) => m.cfg.default_slippage_bps,
            Self::Relay(m) => m.cfg.default_slippage_bps,
            Self::ZilSwap(_) => 50,
        }
    }

    #[frb(ignore)]
    pub fn supports_price_protection(&self) -> bool {
        match self {
            Self::Uniswap(m) => m.cfg.supports_price_protection,
            Self::PancakeSwap(m) => m.cfg.supports_price_protection,
            Self::PlunderSwap(m) => m.cfg.supports_price_protection,
            Self::SunSwap(m) => m.cfg.supports_price_protection,
            Self::Relay(m) => m.cfg.supports_price_protection,
            Self::ZilSwap(_) => false,
        }
    }

    #[frb(ignore)]
    pub fn is_support(&self, addr_type: u8, slip44: u32, chain_id: u64) -> bool {
        match self {
            Self::Relay(_) => {
                relay::relay_chain_id(addr_type, chain_id).is_some_and(relay::is_supported_chain)
            }
            Self::Uniswap(_) => {
                addr_type == 1 && slip44 != ZILLIQA && uniswap::is_supported_chain(chain_id)
            }
            Self::PancakeSwap(_) => {
                addr_type == 1 && slip44 != ZILLIQA && pancakeswap::is_supported_chain(chain_id)
            }
            Self::PlunderSwap(_) => {
                addr_type == 1 && slip44 == ZILLIQA && plunderswap::is_supported_chain(chain_id)
            }
            Self::ZilSwap(_) => {
                addr_type == 0 && slip44 == ZILLIQA && zilswap::is_supported_chain(chain_id)
            }
            Self::SunSwap(_) => addr_type == 4 && slip44 == TRON,
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
            Self::PlunderSwap(meta) if from.token.chain_hash == to.token.chain_hash => {
                plunderswap::is_wrap_unwrap(meta, from, to, from_asset, to_asset)
            }
            Self::SunSwap(meta) if from.token.chain_hash == to.token.chain_hash => {
                sunswap::is_wrap_unwrap(meta, from, to, from_asset, to_asset)
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
    ) -> Result<ProviderQuote, String> {
        let destination: Cow<'_, str> = match self {
            Self::Relay(_) => to
                .providers
                .iter()
                .find_map(|p| {
                    (p.common().chain_hash == to.token.chain_hash)
                        .then(|| Cow::Owned(p.common().account_addr.clone()))
                })
                .unwrap_or_else(|| Cow::Borrowed(self.common().account_addr.as_str())),
            Self::Uniswap(_)
            | Self::PancakeSwap(_)
            | Self::PlunderSwap(_)
            | Self::ZilSwap(_)
            | Self::SunSwap(_) => Cow::Borrowed(self.common().account_addr.as_str()),
        };

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
                    from,
                    from_asset,
                    to_asset,
                    amount,
                    destination.as_ref(),
                )
                .await
            }
            Self::Relay(meta) => relay::relay_quote_info(meta, from, to, amount).await,
            Self::ZilSwap(meta) => {
                zilswap::zilswap_quote_info(meta, from, to, from_asset, to_asset, amount).await
            }
            Self::PlunderSwap(meta) => {
                plunderswap::plunderswap_quote_info(meta, from, to, from_asset, to_asset, amount)
                    .await
            }
            Self::SunSwap(meta) => {
                sunswap::sunswap_quote_info(meta, from, to, from_asset, to_asset, amount).await
            }
        }
    }

    #[frb(ignore)]
    pub async fn check_approval(
        &self,
        from: &ExchangeAsset,
        to: &ExchangeAsset,
        amount: &str,
        approve_title: String,
    ) -> Result<Option<TransactionRequestInfo>, String> {
        let common = self.common();
        let chain_hash = common.chain_hash;
        let icon = common.icon_asset.clone();
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
                if from.token.native {
                    return Ok(None);
                }
                let swapper =
                    AlloyAddress::from_str(&common.account_addr).map_err(|e| e.to_string())?;
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
                    icon,
                )
                .await
            }
            Self::Relay(_) => {
                // SVM origin has no on-chain approval; native tokens never need approval.
                if from.token.addr_type == 3 || from.token.native {
                    return Ok(None);
                }
                relay::relay_check_approval(
                    common.account_addr.as_str(),
                    chain_hash,
                    from,
                    to,
                    amount,
                    approve_title,
                    icon,
                )
                .await
            }
            Self::ZilSwap(meta) => {
                zilswap::zilswap_check_approval(meta, from, to, amount, approve_title, icon).await
            }
            Self::PlunderSwap(meta) => {
                plunderswap::plunderswap_check_approval(meta, from, to, amount, approve_title, icon)
                    .await
            }
            Self::SunSwap(meta) => {
                sunswap::sunswap_check_approval(meta, from, to, amount, approve_title, icon).await
            }
        }
    }

    #[frb(ignore)]
    pub async fn prepare_swap(
        &self,
        from: &ExchangeAsset,
        to: &ExchangeAsset,
        amount: &str,
        slippage_bps: u32,
    ) -> Result<PreparedSwap, String> {
        let common = self.common();
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
                if from.token.chain_hash != to.token.chain_hash {
                    return Err("cross-chain swap not supported".to_string());
                }
                let swapper =
                    AlloyAddress::from_str(&common.account_addr).map_err(|e| e.to_string())?;
                let cfg = self
                    .router_config()
                    .ok_or_else(|| "no engine".to_string())??;
                univ_router::prepare_router_swap(
                    &cfg,
                    swapper,
                    common.chain_hash,
                    from.token.addr.as_str(),
                    to.token.addr.as_str(),
                    amount,
                    slippage_bps,
                    from.token.native,
                )
                .await
            }
            Self::Relay(_) => relay::relay_prepare_swap(from, to, amount).await,
            Self::ZilSwap(meta) => {
                zilswap::zilswap_prepare_swap(meta, from, to, amount, slippage_bps).await
            }
            Self::PlunderSwap(meta) => {
                plunderswap::plunderswap_prepare_swap(meta, from, to, amount, slippage_bps).await
            }
            Self::SunSwap(meta) => {
                sunswap::sunswap_prepare_swap(meta, from, to, amount, slippage_bps).await
            }
        }
    }

    #[frb(ignore)]
    pub async fn finalize_swap(
        &self,
        quote_blob: &str,
        permit_signature: Option<&str>,
        swap_title: String,
        swap_info: String,
        out_token: Option<BaseTokenInfo>,
    ) -> Result<TransactionRequestInfo, String> {
        let common = self.common();
        let chain_hash = common.chain_hash;
        let icon = common.icon_asset.clone();
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
                let swapper =
                    AlloyAddress::from_str(&common.account_addr).map_err(|e| e.to_string())?;
                univ_router::finalize_router_swap(
                    quote_blob,
                    swapper,
                    chain_hash,
                    permit_signature,
                    swap_title,
                    swap_info,
                    icon,
                    out_token,
                )
                .await
            }
            Self::Relay(_) => {
                relay::relay_finalize_swap(
                    quote_blob,
                    &common.account_addr,
                    chain_hash,
                    swap_title,
                    swap_info,
                    icon,
                    out_token,
                )
                .await
            }
            Self::ZilSwap(_) => {
                zilswap::zilswap_finalize_swap(
                    quote_blob, chain_hash, swap_title, swap_info, icon, out_token,
                )
                .await
            }
            Self::PlunderSwap(_) => {
                let swapper =
                    AlloyAddress::from_str(&common.account_addr).map_err(|e| e.to_string())?;
                plunderswap::plunderswap_finalize_swap(
                    quote_blob, chain_hash, swapper, swap_title, swap_info, icon, out_token,
                )
                .await
            }
            Self::SunSwap(meta) => {
                sunswap::sunswap_finalize_swap(
                    meta, quote_blob, swap_title, swap_info, icon, out_token,
                )
                .await
            }
        }
    }

    #[frb(ignore)]
    pub fn router_config(&self) -> Option<Result<RouterConfig, String>> {
        match self {
            Self::Uniswap(m) => Some(m.resolve()),
            Self::PancakeSwap(m) => Some(m.resolve()),
            Self::Relay(_) | Self::PlunderSwap(_) | Self::ZilSwap(_) | Self::SunSwap(_) => None,
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
            ExchangeProvider::Uniswap(_)
            | ExchangeProvider::PancakeSwap(_)
            | ExchangeProvider::PlunderSwap(_)
            | ExchangeProvider::ZilSwap(_)
            | ExchangeProvider::SunSwap(_) => None,
        })
    }
}

/// Who signs — wallet identity + credentials.
#[derive(Debug, Clone)]
pub struct SwapAuth {
    pub wallet_index: usize,
    pub account_index: usize,
    pub password: Option<String>,
    pub passphrase: Option<String>,
}

/// What to swap — provider carries chain context in `common()`.
#[derive(Debug, Clone)]
pub struct SwapParams {
    pub provider: ExchangeProvider,
    pub from: ExchangeAsset,
    pub to: ExchangeAsset,
    pub amount_in: String,
    pub slippage_bps: u32,
}

/// Display metadata composed on the Dart side and threaded into every tx built for a swap.
#[derive(Debug, Clone)]
pub struct ExchangeTxDisplay {
    pub swap_title: String,
    pub swap_info: String,
    pub approve_title: String,
    pub permit_title: String,
    pub out_token: Option<BaseTokenInfo>,
}
