import 'dart:async';
import 'package:bearby/src/rust/api/ledger_transport.dart';
import 'package:flutter/foundation.dart';
import 'package:bearby/ledger/models/device_model.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/ledger/transport/exceptions.dart';
import 'package:bearby/ledger/transport/transport.dart';

class RustHidTransport extends GuardedTransport {
  final String _connectionId;
  @override
  final DeviceModel? deviceModel;

  RustHidTransport(this._connectionId, this.deviceModel);


  static Future<List<DiscoveredDevice>> list() async {
    final devices = await ledgerHidList();
    return devices.map((d) => DiscoveredDevice.fromRustHidDevice(d)).toList();
  }

  static Future<RustHidTransport> open(DiscoveredDevice deviceInfo) async {
    try {
      final connectionId =
          await ledgerHidOpen(deviceId: deviceInfo.devicePath!);
      return RustHidTransport(connectionId, deviceInfo.model);
    } catch (e) {
      throw DisconnectedDeviceException(e.toString());
    }
  }

  @override
  Future<Uint8List> exchange(Uint8List apdu) async {
    return guardedExchange(() async {
      try {
        final result = await ledgerHidExchange(
          connectionId: _connectionId,
          apdu: apdu.toList(),
        );
        return Uint8List.fromList(result);
      } catch (e) {
        throw DisconnectedDeviceDuringOperationException(e.toString());
      }
    }, unresponsiveAfter: const Duration(seconds: 15));
  }

  @override
  Future<void> close() async {
    await guardedClose(
        () => ledgerHidClose(connectionId: _connectionId));
  }

  @override
  void setScrambleKey(String key) {}
}
