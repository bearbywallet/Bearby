pub use ledger_lib::{Device, Filters, LedgerInfo, LedgerProvider, Transport, DEFAULT_TIMEOUT};

#[flutter_rust_bridge::frb(dart_async)]
pub async fn scan_ledger_devices() -> Result<Vec<LedgerInfo>, String> {
    let mut provider = LedgerProvider::init().await;
    let devices = provider
        .list(Filters::Ble)
        .await
        .map_err(|e| format!("Failed to list devices: {}", e))?;

    Ok(devices)
}
