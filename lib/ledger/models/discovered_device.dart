import 'package:bearby/ledger/models/device_model.dart';

enum ConnectionType { ble, usb }

class DiscoveredDevice {
  final String? id;
  final int? vendorId;
  final int? deviceId;
  final int? productId;
  final String? deviceModelProducName;
  final String? name;
  final String? devicePath;
  final String? deviceModelId;
  final String? serviceUUID;

  final ConnectionType connectionType;
  final DeviceModel? model;
  final Map<String, dynamic> rawDevice;

  DiscoveredDevice({
    required this.connectionType,
    required this.rawDevice,
    this.id,
    this.vendorId,
    this.deviceId,
    this.productId,
    this.model,
    this.deviceModelProducName,
    this.name,
    this.devicePath,
    this.deviceModelId,
    this.serviceUUID,
  });

  factory DiscoveredDevice.fromBleDevice(Map<String, dynamic> rawData) {
    final serviceUUID = rawData['serviceUUID'] as String;
    final deviceModel = Devices.identifyBluetoothServiceUuid(serviceUUID);

    return DiscoveredDevice(
      serviceUUID: serviceUUID,
      id: rawData['id'],
      name: rawData['name'],
      model: deviceModel,
      connectionType: ConnectionType.ble,
      rawDevice: rawData,
    );
  }

  factory DiscoveredDevice.fromHidDevice(Map<String, dynamic> rawData) {
    final productId = rawData['productId'] as int;
    final deviceModel = Devices.identifyUSBProductId(productId);

    return DiscoveredDevice(
      model: deviceModel,
      vendorId: rawData['vendorId'],
      deviceId: rawData['deviceId'],
      productId: productId,
      name: rawData['name'],
      devicePath: rawData['deviceName'],
      deviceModelId: rawData['deviceModel']['id'],
      deviceModelProducName: rawData['deviceModel']['productName'],
      connectionType: ConnectionType.usb,
      rawDevice: rawData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDevice &&
          runtimeType == other.runtimeType &&
          productId == other.productId;

  @override
  int get hashCode => productId.hashCode;
}
