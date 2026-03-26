import 'dart:async';
import 'package:bearby/src/rust/api/ledger_transport/desktop_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:bearby/ledger/models/device_model.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/ledger/transport/exceptions.dart';
import 'package:bearby/ledger/transport/transport.dart';

class RustHidTransport extends Transport {
  final String _connectionId;
  @override
  final DeviceModel? deviceModel;

  Completer<void>? _exchangeBusyPromise;
  Timer? _unresponsiveTimer;
  final _eventController = StreamController<TransportEvent>.broadcast();

  RustHidTransport(this._connectionId, this.deviceModel);

  @override
  Stream<TransportEvent> get events => _eventController.stream;

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
    return _exchangeAtomic(() async {
      try {
        final result = await ledgerHidExchange(
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

    bool unresponsiveReached = false;
    _unresponsiveTimer = Timer(const Duration(seconds: 15), () {
      unresponsiveReached = true;
      _eventController.add(TransportEvent.unresponsive);
    });

    try {
      final res = await f();
      if (unresponsiveReached) {
        _eventController.add(TransportEvent.responsive);
      }
      return res;
    } finally {
      _unresponsiveTimer?.cancel();
      completer.complete();
      _exchangeBusyPromise = null;
    }
  }

  @override
  Future<void> close() async {
    await _exchangeBusyPromise?.future;
    await ledgerHidClose(connectionId: _connectionId);
    await _eventController.close();
  }

  @override
  void setScrambleKey(String key) {}
}
