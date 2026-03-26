pub struct RustLedgerHidDevice {
    pub device_id: String,
    pub vendor_id: u16,
    pub product_id: u16,
    pub product_name: String,
    pub model_id: String,
}

pub struct RustLedgerBleDevice {
    pub device_id: String,
    pub name: String,
    pub service_uuid: String,
    pub model_id: String,
    pub product_name: String,
}

// ---- Desktop implementation ----

#[cfg(not(any(target_os = "android", target_os = "ios")))]
use std::collections::HashMap;
#[cfg(not(any(target_os = "android", target_os = "ios")))]
use std::sync::{Arc, Mutex, RwLock};

#[cfg(not(any(target_os = "android", target_os = "ios")))]
use lazy_static::lazy_static;

#[cfg(not(any(target_os = "android", target_os = "ios")))]
use crate::ledger::ble::BleLedgerTransport;
#[cfg(not(any(target_os = "android", target_os = "ios")))]
use crate::ledger::hid::{self, HidLedgerTransport};

#[cfg(not(any(target_os = "android", target_os = "ios")))]
enum TransportEntry {
    Hid(Mutex<HidLedgerTransport>),
    Ble(tokio::sync::Mutex<BleLedgerTransport>),
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
unsafe impl Sync for TransportEntry {}
#[cfg(not(any(target_os = "android", target_os = "ios")))]
unsafe impl Send for TransportEntry {}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
lazy_static! {
    static ref TRANSPORT_REGISTRY: RwLock<HashMap<String, Arc<TransportEntry>>> =
        RwLock::new(HashMap::new());
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
fn next_connection_id() -> String {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(1);
    format!("conn_{}", COUNTER.fetch_add(1, Ordering::Relaxed))
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub fn ledger_hid_list() -> Result<Vec<RustLedgerHidDevice>, String> {
    let devices = hid::list_devices().map_err(|e| e.to_string())?;
    Ok(devices
        .into_iter()
        .map(|d| RustLedgerHidDevice {
            device_id: d.device_path,
            vendor_id: d.vendor_id,
            product_id: d.product_id,
            product_name: d.product_name,
            model_id: d.model_id,
        })
        .collect())
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub fn ledger_hid_open(device_id: String) -> Result<String, String> {
    let transport = HidLedgerTransport::open(&device_id).map_err(|e| e.to_string())?;
    let conn_id = next_connection_id();
    let mut registry = TRANSPORT_REGISTRY
        .write()
        .map_err(|e| e.to_string())?;
    registry.insert(
        conn_id.clone(),
        Arc::new(TransportEntry::Hid(Mutex::new(transport))),
    );
    Ok(conn_id)
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub fn ledger_hid_exchange(connection_id: String, apdu: Vec<u8>) -> Result<Vec<u8>, String> {
    let entry = {
        let registry = TRANSPORT_REGISTRY
            .read()
            .map_err(|e| e.to_string())?;
        registry
            .get(&connection_id)
            .cloned()
            .ok_or_else(|| format!("Connection {} not found", connection_id))?
    };
    match entry.as_ref() {
        TransportEntry::Hid(mutex) => {
            let transport = mutex.lock().map_err(|e| e.to_string())?;
            let result = transport.exchange(&apdu).map_err(|e| e.to_string())?;
            Ok(result)
        }
        _ => Err("Connection is not HID".to_string()),
    }
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub fn ledger_hid_close(connection_id: String) -> Result<(), String> {
    let mut registry = TRANSPORT_REGISTRY
        .write()
        .map_err(|e| e.to_string())?;
    registry.remove(&connection_id);
    Ok(())
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub async fn ledger_ble_scan() -> Result<Vec<RustLedgerBleDevice>, String> {
    let devices = crate::ledger::ble::scan_devices()
        .await
        .map_err(|e| e.to_string())?;
    Ok(devices
        .into_iter()
        .map(|d| RustLedgerBleDevice {
            device_id: d.device_id,
            name: d.name,
            service_uuid: d.service_uuid,
            model_id: d.model_id,
            product_name: d.product_name,
        })
        .collect())
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub async fn ledger_ble_open(device_id: String) -> Result<String, String> {
    let transport = BleLedgerTransport::open(&device_id)
        .await
        .map_err(|e| e.to_string())?;
    let conn_id = next_connection_id();
    let mut registry = TRANSPORT_REGISTRY
        .write()
        .map_err(|e| e.to_string())?;
    registry.insert(
        conn_id.clone(),
        Arc::new(TransportEntry::Ble(tokio::sync::Mutex::new(transport))),
    );
    Ok(conn_id)
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub async fn ledger_ble_exchange(connection_id: String, apdu: Vec<u8>) -> Result<Vec<u8>, String> {
    let entry = {
        let registry = TRANSPORT_REGISTRY
            .read()
            .map_err(|e| e.to_string())?;
        registry
            .get(&connection_id)
            .cloned()
            .ok_or_else(|| format!("Connection {} not found", connection_id))?
    };
    match entry.as_ref() {
        TransportEntry::Ble(mutex) => {
            let transport = mutex.lock().await;
            let result = transport.exchange(&apdu).await.map_err(|e| e.to_string())?;
            Ok(result)
        }
        _ => Err("Connection is not BLE".to_string()),
    }
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub async fn ledger_ble_close(connection_id: String) -> Result<(), String> {
    let entry = {
        let mut registry = TRANSPORT_REGISTRY
            .write()
            .map_err(|e| e.to_string())?;
        registry.remove(&connection_id)
    };
    if let Some(entry) = entry {
        if let TransportEntry::Ble(mutex) = entry.as_ref() {
            let transport = mutex.lock().await;
            transport.close().await.map_err(|e| e.to_string())?;
        }
    }
    Ok(())
}

// ---- Mobile stubs ----

#[cfg(any(target_os = "android", target_os = "ios"))]
const NOT_SUPPORTED: &str = "Ledger HID/BLE transport not supported on mobile";

#[cfg(any(target_os = "android", target_os = "ios"))]
pub fn ledger_hid_list() -> Result<Vec<RustLedgerHidDevice>, String> {
    Err(NOT_SUPPORTED.to_string())
}

#[cfg(any(target_os = "android", target_os = "ios"))]
pub fn ledger_hid_open(_device_id: String) -> Result<String, String> {
    Err(NOT_SUPPORTED.to_string())
}

#[cfg(any(target_os = "android", target_os = "ios"))]
pub fn ledger_hid_exchange(_connection_id: String, _apdu: Vec<u8>) -> Result<Vec<u8>, String> {
    Err(NOT_SUPPORTED.to_string())
}

#[cfg(any(target_os = "android", target_os = "ios"))]
pub fn ledger_hid_close(_connection_id: String) -> Result<(), String> {
    Err(NOT_SUPPORTED.to_string())
}

#[cfg(any(target_os = "android", target_os = "ios"))]
pub async fn ledger_ble_scan() -> Result<Vec<RustLedgerBleDevice>, String> {
    Err(NOT_SUPPORTED.to_string())
}

#[cfg(any(target_os = "android", target_os = "ios"))]
pub async fn ledger_ble_open(_device_id: String) -> Result<String, String> {
    Err(NOT_SUPPORTED.to_string())
}

#[cfg(any(target_os = "android", target_os = "ios"))]
pub async fn ledger_ble_exchange(_connection_id: String, _apdu: Vec<u8>) -> Result<Vec<u8>, String> {
    Err(NOT_SUPPORTED.to_string())
}

#[cfg(any(target_os = "android", target_os = "ios"))]
pub async fn ledger_ble_close(_connection_id: String) -> Result<(), String> {
    Err(NOT_SUPPORTED.to_string())
}
