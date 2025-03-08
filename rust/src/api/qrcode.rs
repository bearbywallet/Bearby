use crate::models::qrcode::{QRcodeScanResultInfo, QrConfigInfo};
use zilpay::qrcodes::gen::generate_qr_png;
pub use zilpay::qrcodes::gen::generate_qr_svg;
pub use zilpay::qrcodes::parse::QRcodeScanResult;

pub fn gen_svg_qrcode(data: String, config: QrConfigInfo) -> Result<String, String> {
    generate_qr_svg(&data, config.into()).map_err(|e| e.to_string())
}

pub fn gen_png_qrcode(data: String, config: QrConfigInfo) -> Result<Vec<u8>, String> {
    generate_qr_png(&data, config.into()).map_err(|e| e.to_string())
}

pub fn parse_qrcode_str(data: String) -> Result<QRcodeScanResultInfo, String> {
    let params = data
        .parse::<QRcodeScanResult>()
        .map_err(|e| e.to_string())?;

    Ok(params.into())
}
