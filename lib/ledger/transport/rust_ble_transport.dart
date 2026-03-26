import 'dart:async';
import 'package:bearby/src/rust/api/ledger_transport.dart';
import 'package:flutter/foundation.dart';
import 'package:bearby/ledger/models/device_model.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/ledger/transport/exceptions.dart';
import 'package:bearby/ledger/transport/transport.dart';

class RustBleTransport extends Transport {
  final String _connectionId;
  @override
  final DeviceModel? deviceModel;

  Completer<void>? _exchangeBusyPromise;
  final _eventController = StreamController<TransportEvent>.broadcast();

  RustBleTransport(this._connectionId, this.deviceModel);

  @override
  Stream<TransportEvent> get events => _eventController.stream;

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

  Future<T> _exchangeAtomic<T>(Future<T> Function() f) async {
    if (_exchangeBusyPromise != null) {
      throw TransportRaceCondition(
          'An action was already pending on the Ledger device.');
    }

    final completer = Completer<void>();
    _exchangeBusyPromise = completer;

    try {
      final res = await f();
      return res;
    } finally {
      completer.complete();
      _exchangeBusyPromise = null;
    }
  }

  @override
  Future<void> close() async {
    await _exchangeBusyPromise?.future;
    await ledgerBleClose(connectionId: _connectionId);
    await _eventController.close();
  }

  @override
  void setScrambleKey(String key) {}
}
