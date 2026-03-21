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
            println!("[Ledger BLE] Initializing BLE manager...");
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
            println!("[Ledger BLE] Adapter initialized successfully");
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
    println!("[Ledger BLE] Starting scan...");
    let adapter = get_adapter().await?;

    let service_uuids = ledger_service_uuids();
    println!(
        "[Ledger BLE] Scanning with {} service UUID filters",
        service_uuids.len()
    );
    let filter = ScanFilter {
        services: service_uuids,
    };

    adapter
        .start_scan(filter)
        .await
        .map_err(|e| LedgerError::Io(format!("Scan start failed: {}", e)))?;

    println!("[Ledger BLE] Scan started, waiting 5 seconds...");
    tokio::time::sleep(Duration::from_secs(5)).await;

    adapter.stop_scan().await.ok();
    println!("[Ledger BLE] Scan stopped, collecting peripherals...");

    let peripherals = adapter
        .peripherals()
        .await
        .map_err(|e| LedgerError::Io(format!("Failed to get peripherals: {}", e)))?;

    println!(
        "[Ledger BLE] Found {} peripherals total",
        peripherals.len()
    );

    let mut devices = Vec::new();
    for p in peripherals {
        if let Ok(Some(props)) = p.properties().await {
            let name = props.local_name.unwrap_or_default();
            println!(
                "[Ledger BLE] Peripheral: id={}, name='{}', services={:?}",
                p.id(),
                name,
                props.services
            );
            // Find which Ledger service UUID this device advertises
            for svc_uuid in &props.services {
                let uuid_str = svc_uuid.to_string().to_lowercase();
                if let Some(ble_info) = identify_ble_service_uuid(&uuid_str) {
                    println!(
                        "[Ledger BLE] Matched device: model={}, product={}",
                        ble_info.model_id, ble_info.product_name
                    );
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

    println!("[Ledger BLE] Scan complete: {} Ledger devices found", devices.len());
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
        println!("[Ledger BLE] Opening connection to device: {}", device_id);
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
        println!("[Ledger BLE] Connecting...");
        peripheral
            .connect()
            .await
            .map_err(|e| LedgerError::Io(format!("Connection failed: {}", e)))?;
        println!("[Ledger BLE] Connected successfully");

        // Discover services
        println!("[Ledger BLE] Discovering services...");
        peripheral
            .discover_services()
            .await
            .map_err(|e| LedgerError::Io(format!("Service discovery failed: {}", e)))?;

        let services = peripheral.services();
        println!("[Ledger BLE] Found {} services", services.len());
        for svc in &services {
            println!(
                "[Ledger BLE]   Service: {} ({} characteristics)",
                svc.uuid,
                svc.characteristics.len()
            );
            for ch in &svc.characteristics {
                println!(
                    "[Ledger BLE]     Char: {} properties={:?}",
                    ch.uuid, ch.properties
                );
            }
        }

        // Find write, write-cmd, and notify characteristics from Ledger BLE service
        let mut write_char = None;
        let mut write_cmd_char = None;
        let mut notify_char = None;

        for service in &services {
            let svc_uuid = service.uuid.to_string().to_lowercase();
            if let Some(ble_info) = identify_ble_service_uuid(&svc_uuid) {
                println!(
                    "[Ledger BLE] Found Ledger service: {} ({})",
                    ble_info.product_name, svc_uuid
                );
                let write_uuid = Uuid::parse_str(ble_info.write_uuid)
                    .map_err(|e| LedgerError::Io(e.to_string()))?;
                let write_cmd_uuid = Uuid::parse_str(ble_info.write_cmd_uuid)
                    .map_err(|e| LedgerError::Io(e.to_string()))?;
                let notify_uuid = Uuid::parse_str(ble_info.notify_uuid)
                    .map_err(|e| LedgerError::Io(e.to_string()))?;

                for ch in &service.characteristics {
                    if ch.uuid == write_uuid {
                        println!("[Ledger BLE] Found write characteristic: {}", ch.uuid);
                        write_char = Some(ch.clone());
                    }
                    if ch.uuid == write_cmd_uuid {
                        println!("[Ledger BLE] Found write-cmd characteristic: {}", ch.uuid);
                        write_cmd_char = Some(ch.clone());
                    }
                    if ch.uuid == notify_uuid {
                        println!("[Ledger BLE] Found notify characteristic: {}", ch.uuid);
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

        if write_cmd_char.is_none() {
            println!("[Ledger BLE] Warning: write-cmd characteristic not found, will use write-with-response");
        }

        // Subscribe to notifications
        println!("[Ledger BLE] Subscribing to notifications...");
        peripheral
            .subscribe(&notify_char)
            .await
            .map_err(|e| LedgerError::Io(format!("Subscribe failed: {}", e)))?;
        println!("[Ledger BLE] Subscribed to notifications");

        // Negotiate MTU
        println!("[Ledger BLE] Negotiating MTU...");
        let mtu = Self::negotiate_mtu(&peripheral, &write_char, &notify_char).await;
        println!("[Ledger BLE] MTU negotiated: {}", mtu);

        let write_mode = if write_cmd_char.is_some() {
            "WriteWithoutResponse"
        } else {
            "WriteWithResponse"
        };
        println!(
            "[Ledger BLE] Connection open: device={}, mtu={}, write_mode={}",
            device_id, mtu, write_mode
        );

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
        println!("[Ledger BLE] Sending MTU negotiate cmd: {:02x?}", mtu_cmd);
        if peripheral
            .write(write_char, &mtu_cmd, WriteType::WithResponse)
            .await
            .is_ok()
        {
            println!("[Ledger BLE] MTU cmd sent, waiting for response...");
            // Try to read the MTU response with timeout
            if let Ok(mut notifs) = peripheral.notifications().await {
                let timeout = tokio::time::timeout(Duration::from_secs(2), notifs.next()).await;
                match &timeout {
                    Ok(Some(notif)) => {
                        println!(
                            "[Ledger BLE] MTU response received: {:02x?} (len={})",
                            notif.value,
                            notif.value.len()
                        );
                        if notif.value.len() >= 6 && notif.value[0] == MTU_NEGOTIATE_CMD {
                            let negotiated = notif.value[5] as usize;
                            println!("[Ledger BLE] MTU parsed value: {}", negotiated);
                            if negotiated >= 23 && negotiated <= 517 {
                                println!("[Ledger BLE] MTU accepted: {}", negotiated);
                                return negotiated;
                            }
                            println!(
                                "[Ledger BLE] MTU value {} out of range [23..517], using default",
                                negotiated
                            );
                        } else {
                            println!(
                                "[Ledger BLE] MTU response invalid: len={}, first_byte=0x{:02x} (expected 0x{:02x})",
                                notif.value.len(),
                                notif.value.first().copied().unwrap_or(0),
                                MTU_NEGOTIATE_CMD
                            );
                        }
                    }
                    Ok(None) => {
                        println!("[Ledger BLE] MTU notification stream ended (no response)");
                    }
                    Err(_) => {
                        println!("[Ledger BLE] MTU response timed out (2s)");
                    }
                }
            } else {
                println!("[Ledger BLE] Failed to get notification stream for MTU");
            }
        } else {
            println!("[Ledger BLE] Failed to send MTU negotiate cmd");
        }
        println!("[Ledger BLE] Using default MTU: {}", DEFAULT_MTU);
        DEFAULT_MTU
    }

    pub async fn exchange(&self, apdu: &[u8]) -> Result<Vec<u8>, LedgerError> {
        println!(
            "[Ledger BLE] Exchange: sending APDU ({} bytes): {:02x?}",
            apdu.len(),
            apdu
        );
        let chunks = wrap_ble_apdu(apdu, self.mtu);
        println!(
            "[Ledger BLE] APDU split into {} chunks (mtu={})",
            chunks.len(),
            self.mtu
        );

        // Prefer write-without-response for faster throughput (matches Ledger Live)
        let (char_to_use, write_type) = if let Some(ref cmd_char) = self.write_cmd_char {
            (cmd_char, WriteType::WithoutResponse)
        } else {
            (&self.write_char, WriteType::WithResponse)
        };

        // Write all chunks
        for (i, chunk) in chunks.iter().enumerate() {
            println!(
                "[Ledger BLE] Writing chunk {}/{} ({} bytes): {:02x?}",
                i + 1,
                chunks.len(),
                chunk.len(),
                chunk
            );
            self.peripheral
                .write(char_to_use, chunk, write_type)
                .await
                .map_err(|e| {
                    println!("[Ledger BLE] Write failed on chunk {}: {}", i + 1, e);
                    LedgerError::Io(format!("BLE write failed: {}", e))
                })?;

            // Small delay between chunks (matching Android's 20ms)
            tokio::time::sleep(Duration::from_millis(20)).await;
        }

        println!("[Ledger BLE] All chunks sent, waiting for response...");

        // Read response notifications
        let mut notifs = self
            .peripheral
            .notifications()
            .await
            .map_err(|e| LedgerError::Io(format!("Failed to get notifications: {}", e)))?;

        let mut state = BleReceiveState::new();
        let timeout_duration = Duration::from_secs(30);
        let mut chunk_count = 0u32;

        loop {
            let notif = tokio::time::timeout(timeout_duration, notifs.next())
                .await
                .map_err(|_| {
                    println!(
                        "[Ledger BLE] Response timed out after 30s (received {} chunks so far)",
                        chunk_count
                    );
                    LedgerError::Timeout
                })?
                .ok_or_else(|| {
                    println!(
                        "[Ledger BLE] Notification stream ended (received {} chunks)",
                        chunk_count
                    );
                    LedgerError::Disconnected
                })?;

            // Skip non-data notifications (MTU responses, etc.)
            if notif.uuid != self.notify_char.uuid {
                println!(
                    "[Ledger BLE] Skipping notification from uuid={} (expected {})",
                    notif.uuid, self.notify_char.uuid
                );
                continue;
            }

            chunk_count += 1;
            println!(
                "[Ledger BLE] Received response chunk #{} ({} bytes): {:02x?}",
                chunk_count,
                notif.value.len(),
                notif.value
            );

            match unwrap_ble_chunk(&notif.value, &mut state) {
                Ok(Some(complete)) => {
                    println!(
                        "[Ledger BLE] Response complete ({} bytes): {:02x?}",
                        complete.len(),
                        complete
                    );
                    return Ok(complete);
                }
                Ok(None) => {
                    println!(
                        "[Ledger BLE] Chunk #{} processed, waiting for more (have {}/{} bytes)",
                        chunk_count, state.data.len(), state.expected_length
                    );
                    continue;
                }
                Err(e) => {
                    println!("[Ledger BLE] Framing error on chunk #{}: {}", chunk_count, e);
                    return Err(LedgerError::Framing(e));
                }
            }
        }
    }

    pub async fn close(&self) -> Result<(), LedgerError> {
        println!("[Ledger BLE] Closing connection...");
        self.peripheral
            .unsubscribe(&self.notify_char)
            .await
            .ok();
        self.peripheral
            .disconnect()
            .await
            .map_err(|e| LedgerError::Io(format!("Disconnect failed: {}", e)))?;
        println!("[Ledger BLE] Connection closed");
        Ok(())
    }
}
