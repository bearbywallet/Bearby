use zilpay::background::Background;

use crate::api::bg;
use crate::frb_generated::StreamSink;

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(sync)]
pub fn start_background_service(sink: StreamSink<String>) -> Result<(), String> {
    bg::start_background_service(sink)
}

#[flutter_rust_bridge::frb(sync)]
pub fn stop_background_service() -> Result<(), String> {
    bg::stop_background_service()
}

#[flutter_rust_bridge::frb(sync)]
pub fn send_message_to_service(message: String) -> Result<(), String> {
    bg::send_message_to_service(message)
}

#[flutter_rust_bridge::frb(sync)]
pub fn generate_wallet(message: String) -> Result<String, String> {
    let mut bg = Background::from_storage_path("/data/data/com.zilpaymobile").unwrap();
    let key = bg.wallet_from_bip39("test", &message, &[0, 1, 2, 3]);

    Ok(key)
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
