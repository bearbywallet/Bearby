use crate::models::provider::NetworkConfigInfo;

#[derive(Debug, Default)]
pub struct MetadataThorchain;

impl MetadataThorchain {
    pub fn is_supported(config: &NetworkConfigInfo) -> bool {
        matches!(
            config.chain.as_str(),
            "BTC" | "ETH" | "TRX" | "SOL" | "BNB" | "AVAX" | "BASE"
        )
    }
}
