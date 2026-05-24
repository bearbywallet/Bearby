use crate::models::provider::NetworkConfigInfo;

#[derive(Debug, Default)]
pub struct MetadataCurveFi;

impl MetadataCurveFi {
    pub fn is_supported(_config: &NetworkConfigInfo) -> bool {
        false
    }
}
