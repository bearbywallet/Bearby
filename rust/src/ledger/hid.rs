use hidapi::HidApi;

use crate::ledger::device::{identify_usb_product_id, LEDGER_VENDOR_ID};
use crate::ledger::framing::{
    unwrap_hid_response, wrap_hid_apdu, HID_PACKET_SIZE, LEDGER_CHANNEL,
};
use crate::ledger::transport::LedgerError;

const READ_TIMEOUT_MS: i32 = 5000;

#[derive(Debug)]
pub struct HidDeviceInfo {
    pub device_path: String,
    pub vendor_id: u16,
    pub product_id: u16,
    pub product_name: String,
    pub model_id: String,
}

pub fn list_devices() -> Result<Vec<HidDeviceInfo>, LedgerError> {
    println!("[Ledger HID] Listing USB devices...");
    let api = HidApi::new().map_err(|e| {
        println!("[Ledger HID] HidApi init failed: {}", e);
        LedgerError::Io(e.to_string())
    })?;
    let mut devices = Vec::new();

    for info in api.device_list() {
        if info.vendor_id() != LEDGER_VENDOR_ID {
            continue;
        }
        // Only enumerate HID interfaces (usage_page 0xFFA0 on macOS/Windows, or interface 0)
        #[cfg(target_os = "macos")]
        if info.usage_page() != 0xFFA0 {
            continue;
        }
        #[cfg(not(target_os = "macos"))]
        if info.interface_number() != 0 {
            continue;
        }

        let product_id = info.product_id();
        println!(
            "[Ledger HID] Found Ledger USB device: path={}, pid=0x{:04x}",
            info.path().to_string_lossy(),
            product_id
        );
        if let Some(model) = identify_usb_product_id(product_id) {
            println!(
                "[Ledger HID] Identified as: {} ({})",
                model.product_name, model.id
            );
            devices.push(HidDeviceInfo {
                device_path: info.path().to_string_lossy().to_string(),
                vendor_id: info.vendor_id(),
                product_id,
                product_name: model.product_name.to_string(),
                model_id: model.id.to_string(),
            });
        } else {
            println!(
                "[Ledger HID] Unknown product id 0x{:04x}, skipping",
                product_id
            );
        }
    }

    println!("[Ledger HID] Found {} Ledger HID devices", devices.len());
    Ok(devices)
}

pub struct HidLedgerTransport {
    device: hidapi::HidDevice,
}

impl HidLedgerTransport {
    pub fn open(device_path: &str) -> Result<Self, LedgerError> {
        println!("[Ledger HID] Opening device: {}", device_path);
        let api = HidApi::new().map_err(|e| {
            println!("[Ledger HID] HidApi init failed: {}", e);
            LedgerError::Io(e.to_string())
        })?;
        let path = std::ffi::CString::new(device_path)
            .map_err(|e| LedgerError::Io(e.to_string()))?;
        let device = api
            .open_path(&path)
            .map_err(|e| {
                println!("[Ledger HID] Failed to open device: {}", e);
                LedgerError::Io(format!("Failed to open device: {}", e))
            })?;
        println!("[Ledger HID] Device opened successfully");
        Ok(HidLedgerTransport { device })
    }

    pub fn exchange(&self, apdu: &[u8]) -> Result<Vec<u8>, LedgerError> {
        println!(
            "[Ledger HID] Exchange: sending APDU ({} bytes): {:02x?}",
            apdu.len(),
            apdu
        );
        let packets = wrap_hid_apdu(LEDGER_CHANNEL, apdu, HID_PACKET_SIZE);
        println!("[Ledger HID] APDU split into {} packets", packets.len());

        // Write all packets
        for (i, pkt) in packets.iter().enumerate() {
            // hidapi write expects a report ID byte prepended on some platforms
            let mut report = vec![0x00]; // Report ID 0
            report.extend_from_slice(pkt);
            println!(
                "[Ledger HID] Writing packet {}/{} ({} bytes)",
                i + 1,
                packets.len(),
                report.len()
            );
            self.device
                .write(&report)
                .map_err(|e| {
                    println!("[Ledger HID] Write failed on packet {}: {}", i + 1, e);
                    LedgerError::Io(format!("Write failed: {}", e))
                })?;
        }

        println!("[Ledger HID] All packets sent, reading response...");

        // Read response packets
        let mut response_data = Vec::new();
        let mut attempts = 0;
        let max_attempts = 100;

        loop {
            let mut buf = [0u8; HID_PACKET_SIZE];
            let n = self
                .device
                .read_timeout(&mut buf, READ_TIMEOUT_MS)
                .map_err(|e| {
                    println!("[Ledger HID] Read failed: {}", e);
                    LedgerError::Io(format!("Read failed: {}", e))
                })?;

            if n == 0 {
                attempts += 1;
                if attempts % 10 == 0 {
                    println!(
                        "[Ledger HID] No data yet, attempt {}/{}",
                        attempts, max_attempts
                    );
                }
                if attempts >= max_attempts {
                    println!("[Ledger HID] Read timed out after {} attempts", max_attempts);
                    return Err(LedgerError::Timeout);
                }
                continue;
            }

            println!(
                "[Ledger HID] Read {} bytes: {:02x?}",
                n,
                &buf[..n]
            );
            response_data.extend_from_slice(&buf[..n]);

            // Try to unwrap the accumulated response
            if let Some(result) = unwrap_hid_response(LEDGER_CHANNEL, &response_data, HID_PACKET_SIZE) {
                println!(
                    "[Ledger HID] Response complete ({} bytes): {:02x?}",
                    result.len(),
                    result
                );
                return Ok(result);
            }
        }
    }

    pub fn close(&mut self) -> Result<(), LedgerError> {
        println!("[Ledger HID] Closing device");
        // hidapi::HidDevice closes on drop
        Ok(())
    }
}
