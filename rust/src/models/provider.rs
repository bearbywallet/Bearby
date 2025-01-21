use zilpay::{errors::address::AddressError, proto::address::Address};
pub use zilpay::{
    errors::network::NetworkErrors,
    rpc::network_config::{ChainConfig, Explorer},
};

pub struct ExplorerInfo {
    pub name: String,
    pub url: String,
    pub icon: Option<String>,
    pub standard: u16,
}

pub struct NetworkConfigInfo {
    pub name: String,
    pub chain: String,
    pub icon: String,
    pub rpc: Vec<String>,
    pub features: Vec<u16>,
    pub chain_id: u64,
    pub slip_44: u32,
    pub chain_hash: u64,
    pub ens: String,
    pub explorers: Vec<ExplorerInfo>,
    pub fallback_enabled: bool,
}

impl From<ExplorerInfo> for Explorer {
    fn from(value: ExplorerInfo) -> Self {
        Explorer {
            name: value.name,
            url: value.url,
            icon: value.icon,
            standard: value.standard,
        }
    }
}

impl From<Explorer> for ExplorerInfo {
    fn from(value: Explorer) -> Self {
        Self {
            name: value.name,
            url: value.url,
            icon: value.icon,
            standard: value.standard,
        }
    }
}

impl From<ChainConfig> for NetworkConfigInfo {
    fn from(value: ChainConfig) -> Self {
        let chain_hash = value.hash();
        let explorers = value
            .explorers
            .into_iter()
            .map(ExplorerInfo::from)
            .collect();

        Self {
            chain_hash,
            name: value.name,
            chain: value.chain,
            icon: value.icon,
            rpc: value.rpc,
            features: value.features,
            chain_id: value.chain_id,
            slip_44: value.slip_44,
            ens: value.ens.auto_format(),
            explorers,
            fallback_enabled: value.fallback_enabled,
        }
    }
}

impl TryFrom<NetworkConfigInfo> for ChainConfig {
    type Error = AddressError;

    fn try_from(value: NetworkConfigInfo) -> Result<Self, Self::Error> {
        let explorers = value.explorers.into_iter().map(Explorer::from).collect();
        let ens = Address::from_str_hex(&value.ens)?;

        Ok(ChainConfig {
            name: value.name,
            chain: value.chain,
            icon: value.icon,
            rpc: value.rpc,
            features: value.features,
            chain_id: value.chain_id,
            slip_44: value.slip_44,
            ens,
            explorers,
            fallback_enabled: value.fallback_enabled,
        })
    }
}
