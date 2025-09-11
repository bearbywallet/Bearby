import 'package:collection/collection.dart';

class BleSpec {
  final String serviceUuid;
  final String notifyUuid;
  final String writeUuid;
  final String? writeCmdUuid;

  const BleSpec({
    required this.serviceUuid,
    required this.notifyUuid,
    required this.writeUuid,
    this.writeCmdUuid,
  });
}

class DeviceModel {
  final String id;
  final String productName;
  final int productIdMM;
  final int legacyUsbProductId;
  final List<BleSpec>? bluetoothSpec;

  const DeviceModel({
    required this.id,
    required this.productName,
    required this.productIdMM,
    required this.legacyUsbProductId,
    this.bluetoothSpec,
  });
}

class Devices {
  static const List<DeviceModel> _devicesList = [
    DeviceModel(
      id: 'blue',
      productName: 'Ledger Blue',
      productIdMM: 0x00,
      legacyUsbProductId: 0x0000,
    ),
    DeviceModel(
      id: 'nanoS',
      productName: 'Ledger Nano S',
      productIdMM: 0x10,
      legacyUsbProductId: 0x0001,
    ),
    DeviceModel(
      id: 'nanoX',
      productName: 'Ledger Nano X',
      productIdMM: 0x40,
      legacyUsbProductId: 0x0004,
      bluetoothSpec: [
        BleSpec(
          serviceUuid: "13d63400-2c97-0004-0000-4c6564676572",
          notifyUuid: "13d63400-2c97-0004-0001-4c6564676572",
          writeUuid: "13d63400-2c97-0004-0002-4c6564676572",
          writeCmdUuid: "13d63400-2c97-0004-0003-4c6564676572",
        ),
      ],
    ),
    DeviceModel(
      id: 'nanoSP',
      productName: 'Ledger Nano S Plus',
      productIdMM: 0x50,
      legacyUsbProductId: 0x0005,
    ),
    DeviceModel(
      id: 'stax',
      productName: 'Ledger Stax',
      productIdMM: 0x60,
      legacyUsbProductId: 0x0006,
      bluetoothSpec: [
        BleSpec(
          serviceUuid: "13d63400-2c97-6004-0000-4c6564676572",
          notifyUuid: "13d63400-2c97-6004-0001-4c6564676572",
          writeUuid: "13d63400-2c97-6004-0002-4c6564676572",
          writeCmdUuid: "13d63400-2c97-6004-0003-4c6564676572",
        ),
      ],
    ),
  ];

  static DeviceModel? identifyUSBProductId(int usbProductId) {
    try {
      return _devicesList
          .firstWhere((d) => d.legacyUsbProductId == usbProductId);
    } catch (_) {
      final mm = usbProductId >> 8;
      try {
        return _devicesList.firstWhere((d) => d.productIdMM == mm);
      } catch (_) {
        return null;
      }
    }
  }

  static DeviceModel? identifyBluetoothServiceUuid(String uuid) {
    final lowerUuid = uuid.toLowerCase();
    return _devicesList.firstWhereOrNull((d) =>
        d.bluetoothSpec
            ?.any((spec) => spec.serviceUuid.toLowerCase() == lowerUuid) ??
        false);
  }
}
