class DeviceModel {
  final String id;
  final String productName;
  final int productIdMM;
  final int legacyUsbProductId;

  const DeviceModel({
    required this.id,
    required this.productName,
    required this.productIdMM,
    required this.legacyUsbProductId,
  });
}

class Devices {
  static const List<DeviceModel> _devicesList = [
    DeviceModel(
        id: 'blue',
        productName: 'Ledger Blue',
        productIdMM: 0x00,
        legacyUsbProductId: 0x0000),
    DeviceModel(
        id: 'nanoS',
        productName: 'Ledger Nano S',
        productIdMM: 0x10,
        legacyUsbProductId: 0x0001),
    DeviceModel(
        id: 'nanoX',
        productName: 'Ledger Nano X',
        productIdMM: 0x40,
        legacyUsbProductId: 0x0004),
    DeviceModel(
        id: 'nanoSP',
        productName: 'Ledger Nano S Plus',
        productIdMM: 0x50,
        legacyUsbProductId: 0x0005),
    DeviceModel(
        id: 'stax',
        productName: 'Ledger Stax',
        productIdMM: 0x60,
        legacyUsbProductId: 0x0006),
    DeviceModel(
        id: 'europa',
        productName: 'Ledger Flex',
        productIdMM: 0x70,
        legacyUsbProductId: 0x0007),
    DeviceModel(
        id: 'apex',
        productName: 'Ledger Apex',
        productIdMM: 0x80,
        legacyUsbProductId: 0x0008),
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
}
