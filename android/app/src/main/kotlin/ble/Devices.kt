package ble

import java.util.UUID

object Devices {
    private val NANO_X = BleSpec(
        UUID.fromString("13d63400-2c97-0004-0000-4c6564676572"),
        UUID.fromString("13d63400-2c97-0004-0001-4c6564676572"),
        UUID.fromString("13d63400-2c97-0004-0002-4c6564676572"),
    )
    private val STAX = BleSpec(
        UUID.fromString("13d63400-2c97-6004-0000-4c6564676572"),
        UUID.fromString("13d63400-2c97-6004-0001-4c6564676572"),
        UUID.fromString("13d63400-2c97-6004-0002-4c6564676572"),
    )

    private val serviceUuidToInfos = mapOf(
        NANO_X.serviceUuid to BluetoothInfos(DeviceModel("nanoX"), NANO_X),
        STAX.serviceUuid to BluetoothInfos(DeviceModel("stax"), STAX),
    )

    fun getBluetoothServiceUuids(): List<UUID> = serviceUuidToInfos.keys.toList()

    fun getInfosForServiceUuid(uuid: String): BluetoothInfos? =
        serviceUuidToInfos[UUID.fromString(uuid)]

    fun isLedgerService(uuid: UUID): Boolean = serviceUuidToInfos.containsKey(uuid)

    data class DeviceModel(val id: String)
    data class BleSpec(val serviceUuid: UUID, val notifyUuid: UUID, val writeUuid: UUID)
    data class BluetoothInfos(val deviceModel: DeviceModel, val spec: BleSpec) {
        val serviceUuid: UUID get() = spec.serviceUuid
        val notifyUuid: UUID get() = spec.notifyUuid
        val writeUuid: UUID get() = spec.writeUuid
    }
}