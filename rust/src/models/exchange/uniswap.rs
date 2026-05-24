use crate::models::provider::NetworkConfigInfo;

#[derive(Debug, Default)]
pub struct MetadataUniswap;

impl MetadataUniswap {
    pub fn is_supported(_config: &NetworkConfigInfo) -> bool {
        false
    }
}
