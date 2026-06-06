pub mod pancakeswap;
pub mod relay;
pub mod uniswap;
pub mod univ_router;

use std::borrow::Cow;
use std::collections::HashSet;
use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::Address as AlloyAddress;
use zilpay::crypto::slip44::{BITCOIN, ETHEREUM, SOLANA, TRON, ZILLIQA};

use super::ftoken::FTokenInfo;
use super::transactions::base_token::BaseTokenInfo;
use super::transactions::request::TransactionRequestInfo;

pub use pancakeswap::PancakeMeta;
pub use relay::RelayMeta;
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
    pub fn for_chain(chain_hash: u64, chain_id: u64, slip44: u32, account_addr: &str) -> Self {
        Self {
            common: ProviderCommon {
                chain_hash,
                chain_id,
                slip44,
                account_addr: account_addr.to_owned(),
                icon_asset: "assets/icons/zilswap.svg".to_owned(),
                display_name: "ZilSwap".to_owned(),
            },
            quote: None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct SunSwapMeta {
    pub common: ProviderCommon,
    pub quote: Option<ProviderQuote>,
}

impl SunSwapMeta {
    #[frb(ignore)]
    pub fn for_chain(chain_hash: u64, chain_id: u64, slip44: u32, account_addr: &str) -> Self {
        Self {
            common: ProviderCommon {
                chain_hash,
                chain_id,
                slip44,
                account_addr: account_addr.to_owned(),
                icon_asset: "assets/icons/sunswap.svg".to_owned(),
                display_name: "SunSwap".to_owned(),
            },
            quote: None,
        }
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
identity_from_common!(ZilSwapMeta);
identity_from_common!(SunSwapMeta);

#[derive(Debug, PartialEq, PartialOrd, Eq, Hash, Clone)]
pub enum ExchangeProvider {
    Relay(RelayMeta),
    Uniswap(UniswapMeta),
    PancakeSwap(PancakeMeta),
    ZilSwap(ZilSwapMeta),
    SunSwap(SunSwapMeta),
}

impl ExchangeProvider {
    #[frb(ignore)]
    pub fn common(&self) -> &ProviderCommon {
        match self {
            Self::Relay(m) => &m.common,
            Self::Uniswap(m) => &m.common,
            Self::PancakeSwap(m) => &m.common,
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
            Self::ZilSwap(m) => m.quote.as_ref(),
            Self::SunSwap(m) => m.quote.as_ref(),
        }
    }

    #[frb(ignore)]
    pub fn with_quote(self, quote: ProviderQuote) -> Self {
        match self {
            Self::Relay(mut m) => {
                m.quote = Some(quote);
                Self::Relay(m)
            }
            Self::Uniswap(mut m) => {
                m.quote = Some(quote);
                Self::Uniswap(m)
            }
            Self::PancakeSwap(mut m) => {
                m.quote = Some(quote);
                Self::PancakeSwap(m)
            }
            Self::ZilSwap(mut m) => {
                m.quote = Some(quote);
                Self::ZilSwap(m)
            }
            Self::SunSwap(mut m) => {
                m.quote = Some(quote);
                Self::SunSwap(m)
            }
        }
    }

    #[frb(ignore)]
    pub fn default_slippage_bps(&self) -> u32 {
        match self {
            Self::Uniswap(m) => m.cfg.default_slippage_bps,
            Self::PancakeSwap(m) => m.cfg.default_slippage_bps,
            Self::Relay(m) => m.cfg.default_slippage_bps,
            Self::ZilSwap(_) | Self::SunSwap(_) => 50,
        }
    }

    #[frb(ignore)]
    pub fn supports_price_protection(&self) -> bool {
        match self {
            Self::Uniswap(m) => m.cfg.supports_price_protection,
            Self::PancakeSwap(m) => m.cfg.supports_price_protection,
            Self::Relay(m) => m.cfg.supports_price_protection,
            Self::ZilSwap(_) | Self::SunSwap(_) => false,
        }
    }

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
            Self::ZilSwap(_) => addr_type == 0 && slip44 == ZILLIQA,
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
                let cfg = self.router_config().ok_or_else(|| "no engine".to_string())??;
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
            Self::Uniswap(_) | Self::PancakeSwap(_) | Self::ZilSwap(_) | Self::SunSwap(_) => {
                Cow::Borrowed(self.common().account_addr.as_str())
            }
        };

        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
                if from.token.chain_hash != to.token.chain_hash {
                    return Err("cross-chain swap not supported".to_string());
                }
                let cfg = self.router_config().ok_or_else(|| "no engine".to_string())??;
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
            Self::ZilSwap(_) | Self::SunSwap(_) => Err("provider not implemented".to_string()),
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
        let swapper = AlloyAddress::from_str(&common.account_addr).map_err(|e| e.to_string())?;
        let chain_hash = common.chain_hash;
        let icon = common.icon_asset.clone();
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
                if from.token.native {
                    return Ok(None);
                }
                let cfg = self.router_config().ok_or_else(|| "no engine".to_string())??;
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
                    icon,
                )
                .await
            }
            Self::ZilSwap(_) | Self::SunSwap(_) => Ok(None),
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
        let swapper = AlloyAddress::from_str(&common.account_addr).map_err(|e| e.to_string())?;
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
                if from.token.chain_hash != to.token.chain_hash {
                    return Err("cross-chain swap not supported".to_string());
                }
                let cfg = self.router_config().ok_or_else(|| "no engine".to_string())??;
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
            Self::ZilSwap(_) | Self::SunSwap(_) => Err("provider not implemented".to_string()),
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
        let swapper = AlloyAddress::from_str(&common.account_addr).map_err(|e| e.to_string())?;
        let chain_hash = common.chain_hash;
        let icon = common.icon_asset.clone();
        match self {
            Self::Uniswap(_) | Self::PancakeSwap(_) => {
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
                    swapper,
                    chain_hash,
                    swap_title,
                    swap_info,
                    icon,
                    out_token,
                )
                .await
            }
            Self::ZilSwap(_) | Self::SunSwap(_) => Err("provider not implemented".to_string()),
        }
    }

    #[frb(ignore)]
    pub fn router_config(&self) -> Option<Result<RouterConfig, String>> {
        match self {
            Self::Uniswap(m) => Some(m.resolve()),
            Self::PancakeSwap(m) => Some(m.resolve()),
            Self::Relay(_) | Self::ZilSwap(_) | Self::SunSwap(_) => None,
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
