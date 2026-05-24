use crate::models::provider::NetworkConfigInfo;

#[derive(Debug, Default)]
pub struct MetadataThorchain {
    pub dummy: u8,
}

impl MetadataThorchain {
    pub fn is_supported(config: &NetworkConfigInfo) -> bool {
        matches!(
            config.chain.as_str(),
            "BTC"
                | "LTC"
                | "BCH"
                | "DOGE"
                | "ETH"
                | "BNB"
                | "AVAX"
                | "BASE"
                | "TRX"
                | "SOL"
                | "XRP"
        )
    }
}
