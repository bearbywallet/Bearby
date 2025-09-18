import Foundation
import CoreBluetooth

struct DeviceModel {
    let id: String
}

struct BleSpec {
    let serviceUuid: CBUUID
    let notifyUuid: CBUUID
    let writeUuid: CBUUID
}

struct BluetoothInfos {
    let deviceModel: DeviceModel
    let spec: BleSpec

    var serviceUuid: CBUUID { spec.serviceUuid }
    var notifyUuid: CBUUID { spec.notifyUuid }
    var writeUuid: CBUUID { spec.writeUuid }
}

class Devices {
    private static let NANO_X = BleSpec(
        serviceUuid: CBUUID(string: "13d63400-2c97-0004-0000-4c6564676572"),
        notifyUuid: CBUUID(string: "13d63400-2c97-0004-0001-4c6564676572"),
        writeUuid: CBUUID(string: "13d63400-2c97-0004-0002-4c6564676572")
    )
    private static let STAX = BleSpec(
        serviceUuid: CBUUID(string: "13d63400-2c97-6004-0000-4c6564676572"),
        notifyUuid: CBUUID(string: "13d63400-2c97-6004-0001-4c6564676572"),
        writeUuid: CBUUID(string: "13d63400-2c97-6004-0002-4c6564676572")
    )

    private static let serviceUuidToInfos: [CBUUID: BluetoothInfos] = [
        NANO_X.serviceUuid: BluetoothInfos(deviceModel: DeviceModel(id: "nanoX"), spec: NANO_X),
        STAX.serviceUuid: BluetoothInfos(deviceModel: DeviceModel(id: "stax"), spec: STAX),
    ]

    static func getBluetoothServiceUuids() -> [CBUUID] {
        return Array(serviceUuidToInfos.keys)
    }

    static func getInfosForServiceUuid(uuid: CBUUID) -> BluetoothInfos? {
        return serviceUuidToInfos[uuid]
    }

    static func isLedgerService(uuid: CBUUID) -> Bool {
        return serviceUuidToInfos.keys.contains(uuid)
    }
}
