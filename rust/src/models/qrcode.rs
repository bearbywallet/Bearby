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
    pub eye_shape: EyeShape,
    pub data_module_shape: DataModuleShape,
}

pub enum EyeShapeInfo {
    Square,
    Circle,
}

pub enum DataModuleShapeInfo {
    Square,
    Circle,
}

impl From<EyeShape> for EyeShapeInfo {
    fn from(value: EyeShape) -> Self {
        match value {
            EyeShape::Square => EyeShapeInfo::Square,
            EyeShape::Circle => EyeShapeInfo::Circle,
        }
    }
}

impl From<DataModuleShape> for DataModuleShapeInfo {
    fn from(value: DataModuleShape) -> Self {
        match value {
            DataModuleShape::Square => DataModuleShapeInfo::Square,
            DataModuleShape::Circle => DataModuleShapeInfo::Circle,
        }
    }
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
impl From<EyeShapeInfo> for EyeShape {
    fn from(value: EyeShapeInfo) -> Self {
        match value {
            EyeShapeInfo::Square => EyeShape::Square,
            EyeShapeInfo::Circle => EyeShape::Circle,
        }
    }
}

impl From<DataModuleShapeInfo> for DataModuleShape {
    fn from(value: DataModuleShapeInfo) -> Self {
        match value {
            DataModuleShapeInfo::Square => DataModuleShape::Square,
            DataModuleShapeInfo::Circle => DataModuleShape::Circle,
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
