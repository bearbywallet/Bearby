use std::time::Duration;

use btleplug::api::{Central, Manager as _, Peripheral as _, ScanFilter, WriteType};
use btleplug::platform::{Adapter, Manager, Peripheral};
use futures::StreamExt;
use tokio::sync::OnceCell;
use uuid::Uuid;

use crate::ledger::device::{identify_ble_service_uuid, BLE_DEVICES};
use crate::ledger::framing::{unwrap_ble_chunk, wrap_ble_apdu, BleReceiveState};
use crate::ledger::transport::LedgerError;

const DEFAULT_MTU: usize = 156;
const MTU_NEGOTIATE_CMD: u8 = 0x08;

static ADAPTER: OnceCell<Adapter> = OnceCell::const_new();

#[derive(Debug, Clone)]
pub struct BleDeviceInfo {
    pub device_id: String,
    pub name: String,
    pub service_uuid: String,
    pub model_id: String,
    pub product_name: String,
}

async fn get_adapter() -> Result<&'static Adapter, LedgerError> {
    ADAPTER
        .get_or_try_init(|| async {
            let manager = Manager::new()
                .await
                .map_err(|e| LedgerError::Io(format!("BLE manager init failed: {}", e)))?;
            let adapters = manager
                .adapters()
                .await
                .map_err(|e| LedgerError::Io(format!("Failed to get adapters: {}", e)))?;
            let adapter = adapters
                .into_iter()
                .next()
                .ok_or_else(|| LedgerError::Io("No Bluetooth adapter found".to_string()))?;
            Ok(adapter)
        })
        .await
}

fn ledger_service_uuids() -> Vec<Uuid> {
    BLE_DEVICES
        .iter()
        .filter_map(|d| Uuid::parse_str(d.service_uuid).ok())
        .collect()
}

pub async fn scan_devices() -> Result<Vec<BleDeviceInfo>, LedgerError> {
    let adapter = get_adapter().await?;

    let service_uuids = ledger_service_uuids();
    let filter = ScanFilter {
        services: service_uuids,
    };

    adapter
        .start_scan(filter)
        .await
        .map_err(|e| LedgerError::Io(format!("Scan start failed: {}", e)))?;

    tokio::time::sleep(Duration::from_secs(5)).await;

    adapter.stop_scan().await.ok();

    let peripherals = adapter
        .peripherals()
        .await
        .map_err(|e| LedgerError::Io(format!("Failed to get peripherals: {}", e)))?;

    let mut devices = Vec::new();
    for p in peripherals {
        if let Ok(Some(props)) = p.properties().await {
            let name = props.local_name.unwrap_or_default();
            // Find which Ledger service UUID this device advertises
            for svc_uuid in &props.services {
                let uuid_str = svc_uuid.to_string().to_lowercase();
                if let Some(ble_info) = identify_ble_service_uuid(&uuid_str) {
                    devices.push(BleDeviceInfo {
                        device_id: p.id().to_string(),
                        name: name.clone(),
                        service_uuid: ble_info.service_uuid.to_string(),
                        model_id: ble_info.model_id.to_string(),
                        product_name: ble_info.product_name.to_string(),
                    });
                    break;
                }
            }
        }
    }

    Ok(devices)
}

pub struct BleLedgerTransport {
    peripheral: Peripheral,
    write_char: btleplug::api::Characteristic,
    write_cmd_char: Option<btleplug::api::Characteristic>,
    notify_char: btleplug::api::Characteristic,
    mtu: usize,
}

impl BleLedgerTransport {
    pub async fn open(device_id: &str) -> Result<Self, LedgerError> {
        let adapter = get_adapter().await?;

        let peripherals = adapter
            .peripherals()
            .await
            .map_err(|e| LedgerError::Io(e.to_string()))?;

        let peripheral = peripherals
            .into_iter()
            .find(|p| p.id().to_string() == device_id)
            .ok_or_else(|| LedgerError::Io(format!("Device {} not found", device_id)))?;

        // Connect
        peripheral
            .connect()
            .await
            .map_err(|e| LedgerError::Io(format!("Connection failed: {}", e)))?;

        // Discover services
        peripheral
            .discover_services()
            .await
            .map_err(|e| LedgerError::Io(format!("Service discovery failed: {}", e)))?;

        let services = peripheral.services();

        // Find write, write-cmd, and notify characteristics from Ledger BLE service
        let mut write_char = None;
        let mut write_cmd_char = None;
        let mut notify_char = None;

        for service in &services {
            let svc_uuid = service.uuid.to_string().to_lowercase();
            if let Some(ble_info) = identify_ble_service_uuid(&svc_uuid) {
                let write_uuid = Uuid::parse_str(ble_info.write_uuid)
                    .map_err(|e| LedgerError::Io(e.to_string()))?;
                let write_cmd_uuid = Uuid::parse_str(ble_info.write_cmd_uuid)
                    .map_err(|e| LedgerError::Io(e.to_string()))?;
                let notify_uuid = Uuid::parse_str(ble_info.notify_uuid)
                    .map_err(|e| LedgerError::Io(e.to_string()))?;

                for ch in &service.characteristics {
                    if ch.uuid == write_uuid {
                        write_char = Some(ch.clone());
                    }
                    if ch.uuid == write_cmd_uuid {
                        write_cmd_char = Some(ch.clone());
                    }
                    if ch.uuid == notify_uuid {
                        notify_char = Some(ch.clone());
                    }
                }
                break;
            }
        }

        let write_char =
            write_char.ok_or_else(|| LedgerError::Io("Write characteristic not found".into()))?;
        let notify_char =
            notify_char.ok_or_else(|| LedgerError::Io("Notify characteristic not found".into()))?;

        // Subscribe to notifications
        peripheral
            .subscribe(&notify_char)
            .await
            .map_err(|e| LedgerError::Io(format!("Subscribe failed: {}", e)))?;

        // Negotiate MTU
        let mtu = Self::negotiate_mtu(&peripheral, &write_char, &notify_char).await;

        Ok(BleLedgerTransport {
            peripheral,
            write_char,
            write_cmd_char,
            notify_char,
            mtu,
        })
    }

    async fn negotiate_mtu(
        peripheral: &Peripheral,
        write_char: &btleplug::api::Characteristic,
        _notify_char: &btleplug::api::Characteristic,
    ) -> usize {
        // Send MTU negotiation command (0x08 0x00 0x00 0x00 0x00)
        let mtu_cmd = vec![MTU_NEGOTIATE_CMD, 0x00, 0x00, 0x00, 0x00];
        if peripheral
            .write(write_char, &mtu_cmd, WriteType::WithResponse)
            .await
            .is_ok()
        {
            // Try to read the MTU response with timeout
            if let Ok(mut notifs) = peripheral.notifications().await {
                let timeout = tokio::time::timeout(Duration::from_secs(2), notifs.next()).await;
                match &timeout {
                    Ok(Some(notif)) => {
                        if notif.value.len() >= 6 && notif.value[0] == MTU_NEGOTIATE_CMD {
                            let negotiated = notif.value[5] as usize;
                            if negotiated >= 23 && negotiated <= 517 {
                                return negotiated;
                            }
                        }
                    }
                    _ => {}
                }
            }
        }
        DEFAULT_MTU
    }

    pub async fn exchange(&self, apdu: &[u8]) -> Result<Vec<u8>, LedgerError> {
        let chunks = wrap_ble_apdu(apdu, self.mtu);

        // Prefer write-without-response for faster throughput (matches Ledger Live)
        let (char_to_use, write_type) = if let Some(ref cmd_char) = self.write_cmd_char {
            (cmd_char, WriteType::WithoutResponse)
        } else {
            (&self.write_char, WriteType::WithResponse)
        };

        // Write all chunks
        for chunk in chunks.iter() {
            self.peripheral
                .write(char_to_use, chunk, write_type)
                .await
                .map_err(|e| {
                    LedgerError::Io(format!("BLE write failed: {}", e))
                })?;

            // Small delay between chunks (matching Android's 20ms)
            tokio::time::sleep(Duration::from_millis(20)).await;
        }

        // Read response notifications
        let mut notifs = self
            .peripheral
            .notifications()
            .await
            .map_err(|e| LedgerError::Io(format!("Failed to get notifications: {}", e)))?;

        let mut state = BleReceiveState::new();
        let timeout_duration = Duration::from_secs(30);

        loop {
            let notif = tokio::time::timeout(timeout_duration, notifs.next())
                .await
                .map_err(|_| {
                    LedgerError::Timeout
                })?
                .ok_or_else(|| {
                    LedgerError::Disconnected
                })?;

            // Skip non-data notifications (MTU responses, etc.)
            if notif.uuid != self.notify_char.uuid {
                continue;
            }

            match unwrap_ble_chunk(&notif.value, &mut state) {
                Ok(Some(complete)) => {
                    return Ok(complete);
                }
                Ok(None) => {
                    continue;
                }
                Err(e) => {
                    return Err(LedgerError::Framing(e));
                }
            }
        }
    }

    pub async fn close(&self) -> Result<(), LedgerError> {
        self.peripheral
            .unsubscribe(&self.notify_char)
            .await
            .ok();
        self.peripheral
            .disconnect()
            .await
            .map_err(|e| LedgerError::Io(format!("Disconnect failed: {}", e)))?;
        Ok(())
    }
}