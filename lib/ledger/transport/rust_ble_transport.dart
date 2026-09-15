import 'dart:async';
import 'package:bearby/src/rust/api/ledger_transport.dart';
import 'package:flutter/foundation.dart';
import 'package:bearby/ledger/models/device_model.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/ledger/transport/exceptions.dart';
import 'package:bearby/ledger/transport/transport.dart';

class RustBleTransport extends GuardedTransport {
  final String _connectionId;
  @override
  final DeviceModel? deviceModel;

  RustBleTransport(this._connectionId, this.deviceModel);


  static Future<List<DiscoveredDevice>> scan() async {
    final devices = await ledgerBleScan();
    return devices.map((d) => DiscoveredDevice.fromRustBleDevice(d)).toList();
  }

  static Future<RustBleTransport> open(DiscoveredDevice deviceInfo) async {
    try {
      final connectionId = await ledgerBleOpen(deviceId: deviceInfo.id!);
      return RustBleTransport(connectionId, deviceInfo.model);
    } catch (e) {
      throw DisconnectedDeviceException(e.toString());
    }
  }

  @override
  Future<Uint8List> exchange(Uint8List apdu) async {
    return _exchangeAtomic(() async {
      try {
        final result = await ledgerBleExchange(
          connectionId: _connectionId,
          apdu: apdu.toList(),
        );
        return Uint8List.fromList(result);
      } catch (e) {
        throw DisconnectedDeviceDuringOperationException(e.toString());
      }
    });
  }

  Future<T> _exchangeAtomic<T>(Future<T> Function() f) =>
      guardedExchange(f);

  @override
  Future<void> close() async {
    await guardedClose(() => ledgerBleClose(connectionId: _connectionId));
  }

  @override
  void setScrambleKey(String key) {}
}
