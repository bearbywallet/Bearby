import 'package:zilpay/ledger/transport/ble_transport.dart';
import 'package:zilpay/ledger/transport/hid_transport.dart';

enum ConnectionType { ble, usb }

class DiscoveredDevice {
  final String id;
  final String name;
  final ConnectionType connectionType;
  final dynamic rawDevice; // TODO: remove the dyn type

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.rawDevice,
  });

  factory DiscoveredDevice.fromBleDevice(BleDeviceInfo bleDevice) {
    return DiscoveredDevice(
      id: bleDevice.id,
      name: bleDevice.name,
      connectionType: ConnectionType.ble,
      rawDevice: bleDevice,
    );
  }

  factory DiscoveredDevice.fromHidDevice(DeviceInfo hidDevice) {
    return DiscoveredDevice(
      id: hidDevice.rawData['path'],
      name: hidDevice.deviceName,
      connectionType: ConnectionType.usb,
      rawDevice: hidDevice,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
