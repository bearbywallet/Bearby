use std::collections::HashMap;
use std::sync::{Arc, Mutex, RwLock};

use lazy_static::lazy_static;

use crate::ledger::ble::BleLedgerTransport;
use crate::ledger::hid::{self, HidLedgerTransport};

enum TransportEntry {
    Hid(Mutex<HidLedgerTransport>),
    Ble(tokio::sync::Mutex<BleLedgerTransport>),
}

unsafe impl Sync for TransportEntry {}
unsafe impl Send for TransportEntry {}

lazy_static! {
    static ref TRANSPORT_REGISTRY: RwLock<HashMap<String, Arc<TransportEntry>>> =
        RwLock::new(HashMap::new());
}

fn next_connection_id() -> String {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(1);
    format!("conn_{}", COUNTER.fetch_add(1, Ordering::Relaxed))
}

pub struct RustLedgerHidDevice {
    pub device_id: String,
    pub vendor_id: u16,
    pub product_id: u16,
    pub product_name: String,
    pub model_id: String,
}

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

pub fn ledger_hid_close(connection_id: String) -> Result<(), String> {
    let mut registry = TRANSPORT_REGISTRY
        .write()
        .map_err(|e| e.to_string())?;
    registry.remove(&connection_id);
    Ok(())
}

pub struct RustLedgerBleDevice {
    pub device_id: String,
    pub name: String,
    pub service_uuid: String,
    pub model_id: String,
    pub product_name: String,
}

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
