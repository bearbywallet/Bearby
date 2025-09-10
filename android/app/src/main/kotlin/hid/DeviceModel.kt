package hid

data class DeviceModel(
    val id: String,
    val productName: String,
    val productIdMM: Int,
    val legacyUsbProductId: Int
)

object Devices {
    private val devicesList = listOf(
        DeviceModel("blue", "Ledger Blue", 0x00, 0x0000),
        DeviceModel("nanoS", "Ledger Nano S", 0x10, 0x0001),
        DeviceModel("nanoX", "Ledger Nano X", 0x40, 0x0004),
        DeviceModel("nanoSP", "Ledger Nano S Plus", 0x50, 0x0005),
        DeviceModel("stax", "Ledger Stax", 0x60, 0x0006),
        DeviceModel("europa", "Ledger Flex", 0x70, 0x0007),
        DeviceModel("apex", "Ledger Apex", 0x80, 0x0008)
    )

    fun identifyUSBProductId(usbProductId: Int): DeviceModel? {
        val legacy = devicesList.find { it.legacyUsbProductId == usbProductId }
        if (legacy != null) return legacy
        val mm = usbProductId shr 8
        return devicesList.find { it.productIdMM == mm }
    }
}