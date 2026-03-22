use hidapi::HidApi;

use crate::ledger::device::{identify_usb_product_id, LEDGER_VENDOR_ID};
use crate::ledger::framing::{unwrap_hid_response, wrap_hid_apdu, HID_PACKET_SIZE, LEDGER_CHANNEL};
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
    let api = HidApi::new().map_err(|e| LedgerError::Io(e.to_string()))?;
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
        if let Some(model) = identify_usb_product_id(product_id) {
            devices.push(HidDeviceInfo {
                device_path: info.path().to_string_lossy().to_string(),
                vendor_id: info.vendor_id(),
                product_id,
                product_name: model.product_name.to_string(),
                model_id: model.id.to_string(),
            });
        }
    }

    Ok(devices)
}

pub struct HidLedgerTransport {
    device: hidapi::HidDevice,
}

impl HidLedgerTransport {
    pub fn open(device_path: &str) -> Result<Self, LedgerError> {
        let api = HidApi::new().map_err(|e| LedgerError::Io(e.to_string()))?;
        let path =
            std::ffi::CString::new(device_path).map_err(|e| LedgerError::Io(e.to_string()))?;
        let device = api
            .open_path(&path)
            .map_err(|e| LedgerError::Io(format!("Failed to open device: {}", e)))?;
        Ok(HidLedgerTransport { device })
    }

    pub fn exchange(&self, apdu: &[u8]) -> Result<Vec<u8>, LedgerError> {
        let packets = wrap_hid_apdu(LEDGER_CHANNEL, apdu, HID_PACKET_SIZE);

        // Write all packets
        for pkt in packets.iter() {
            // hidapi write expects a report ID byte prepended on some platforms
            let mut report = vec![0x00]; // Report ID 0
            report.extend_from_slice(pkt);
            self.device
                .write(&report)
                .map_err(|e| LedgerError::Io(format!("Write failed: {}", e)))?;
        }

        // Read response packets
        let mut response_data = Vec::new();
        let mut attempts = 0;
        let max_attempts = 100;

        loop {
            let mut buf = [0u8; HID_PACKET_SIZE];
            let n = self
                .device
                .read_timeout(&mut buf, READ_TIMEOUT_MS)
                .map_err(|e| LedgerError::Io(format!("Read failed: {}", e)))?;

            if n == 0 {
                attempts += 1;
                if attempts >= max_attempts {
                    return Err(LedgerError::Timeout);
                }
                continue;
            }

            response_data.extend_from_slice(&buf[..n]);

            // Try to unwrap the accumulated response
            if let Some(result) =
                unwrap_hid_response(LEDGER_CHANNEL, &response_data, HID_PACKET_SIZE)
            {
                return Ok(result);
            }
        }
    }

    pub fn close(&mut self) -> Result<(), LedgerError> {
        // hidapi::HidDevice closes on drop
        Ok(())
    }
}
