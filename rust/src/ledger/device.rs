pub const LEDGER_VENDOR_ID: u16 = 0x2c97;

#[derive(Debug, Clone)]
pub struct DeviceModelInfo {
    pub id: &'static str,
    pub product_name: &'static str,
    pub product_id_mm: u16,
    pub legacy_usb_product_id: u16,
}

pub const KNOWN_DEVICES: &[DeviceModelInfo] = &[
    DeviceModelInfo {
        id: "blue",
        product_name: "Ledger Blue",
        product_id_mm: 0x00,
        legacy_usb_product_id: 0x0000,
    },
    DeviceModelInfo {
        id: "nanoS",
        product_name: "Ledger Nano S",
        product_id_mm: 0x10,
        legacy_usb_product_id: 0x0001,
    },
    DeviceModelInfo {
        id: "nanoX",
        product_name: "Ledger Nano X",
        product_id_mm: 0x40,
        legacy_usb_product_id: 0x0004,
    },
    DeviceModelInfo {
        id: "nanoSP",
        product_name: "Ledger Nano S Plus",
        product_id_mm: 0x50,
        legacy_usb_product_id: 0x0005,
    },
    DeviceModelInfo {
        id: "stax",
        product_name: "Ledger Stax",
        product_id_mm: 0x60,
        legacy_usb_product_id: 0x0006,
    },
    DeviceModelInfo {
        id: "flex",
        product_name: "Ledger Flex",
        product_id_mm: 0x70,
        legacy_usb_product_id: 0x0007,
    },
    DeviceModelInfo {
        id: "apex",
        product_name: "Ledger Nano Gen5",
        product_id_mm: 0x80,
        legacy_usb_product_id: 0x0008,
    },
];

pub fn identify_usb_product_id(product_id: u16) -> Option<&'static DeviceModelInfo> {
    // Try legacy product ID first
    if let Some(dev) = KNOWN_DEVICES
        .iter()
        .find(|d| d.legacy_usb_product_id == product_id)
    {
        return Some(dev);
    }
    // Try MM-encoded product ID (upper byte)
    let mm = product_id >> 8;
    KNOWN_DEVICES.iter().find(|d| d.product_id_mm == mm)
}

/// BLE service UUIDs for Ledger devices that support Bluetooth
pub struct BleServiceInfo {
    pub model_id: &'static str,
    pub product_name: &'static str,
    pub service_uuid: &'static str,
    pub notify_uuid: &'static str,
    pub write_uuid: &'static str,
    pub write_cmd_uuid: &'static str,
}

pub const BLE_DEVICES: &[BleServiceInfo] = &[
    BleServiceInfo {
        model_id: "nanoX",
        product_name: "Ledger Nano X",
        service_uuid: "13d63400-2c97-0004-0000-4c6564676572",
        notify_uuid: "13d63400-2c97-0004-0001-4c6564676572",
        write_uuid: "13d63400-2c97-0004-0002-4c6564676572",
        write_cmd_uuid: "13d63400-2c97-0004-0003-4c6564676572",
    },
    BleServiceInfo {
        model_id: "stax",
        product_name: "Ledger Stax",
        service_uuid: "13d63400-2c97-6004-0000-4c6564676572",
        notify_uuid: "13d63400-2c97-6004-0001-4c6564676572",
        write_uuid: "13d63400-2c97-6004-0002-4c6564676572",
        write_cmd_uuid: "13d63400-2c97-6004-0003-4c6564676572",
    },
    BleServiceInfo {
        model_id: "flex",
        product_name: "Ledger Flex",
        service_uuid: "13d63400-2c97-3004-0000-4c6564676572",
        notify_uuid: "13d63400-2c97-3004-0001-4c6564676572",
        write_uuid: "13d63400-2c97-3004-0002-4c6564676572",
        write_cmd_uuid: "13d63400-2c97-3004-0003-4c6564676572",
    },
    BleServiceInfo {
        model_id: "apex",
        product_name: "Ledger Nano Gen5",
        service_uuid: "13d63400-2c97-8004-0000-4c6564676572",
        notify_uuid: "13d63400-2c97-8004-0001-4c6564676572",
        write_uuid: "13d63400-2c97-8004-0002-4c6564676572",
        write_cmd_uuid: "13d63400-2c97-8004-0003-4c6564676572",
    },
];

pub fn identify_ble_service_uuid(uuid: &str) -> Option<&'static BleServiceInfo> {
    let lower = uuid.to_lowercase();
    BLE_DEVICES.iter().find(|d| d.service_uuid == lower)
}
