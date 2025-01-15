pub use zilpay::qrcodes::gen::{DataModuleShape, EyeShape, QrConfig};
pub use zilpay::qrcodes::parse::QRcodeScanResult;

pub struct QRcodeScanResultInfo {
    pub recipient: String,
    pub provider: Option<String>,
    pub token_address: Option<String>,
    pub amount: Option<String>,
}

pub struct QrConfigInfo {
    pub size: u32,
    pub gapless: bool,
    pub color: u32,
    pub eye_shape: u8,
    pub data_module_shape: u8,
}

impl From<QrConfig> for QrConfigInfo {
    fn from(value: QrConfig) -> Self {
        Self {
            size: value.size,
            gapless: value.gapless,
            color: value.color,
            eye_shape: value.eye_shape.into(),
            data_module_shape: value.data_module_shape.into(),
        }
    }
}

impl From<QrConfigInfo> for QrConfig {
    fn from(value: QrConfigInfo) -> Self {
        Self {
            size: value.size,
            gapless: value.gapless,
            color: value.color,
            eye_shape: value.eye_shape.into(),
            data_module_shape: value.data_module_shape.into(),
        }
    }
}

impl From<QRcodeScanResult> for QRcodeScanResultInfo {
    fn from(value: QRcodeScanResult) -> Self {
        Self {
            recipient: value.recipient,
            provider: value.provider,
            token_address: value.token_address,
            amount: value.amount,
        }
    }
}

impl From<QRcodeScanResultInfo> for QRcodeScanResult {
    fn from(value: QRcodeScanResultInfo) -> Self {
        Self {
            recipient: value.recipient,
            provider: value.provider,
            token_address: value.token_address,
            amount: value.amount,
        }
    }
}
