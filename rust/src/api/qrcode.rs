use crate::models::qrcode::{QRcodeScanResultInfo, QrConfigInfo};
pub use zilpay::qrcodes::gen::generate_qr;
pub use zilpay::qrcodes::parse::QRcodeScanResult;

#[flutter_rust_bridge::frb(dart_async)]
pub fn gen_qrcode(data: String, config: QrConfigInfo) -> Result<String, String> {
    generate_qr(&data, config.into()).map_err(|e| e.to_string())
}

#[flutter_rust_bridge::frb(dart_async)]
pub fn parse_qrcode_str(data: String) -> Result<QRcodeScanResultInfo, String> {
    let params = data
        .parse::<QRcodeScanResult>()
        .map_err(|e| e.to_string())?;

    Ok(params.into())
}
