import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:bearby/ledger/models/device_model.dart';
import 'package:bearby/ledger/transport/exceptions.dart';

enum TransportEvent { unresponsive, responsive }

/// Shared single-flight exchange guard + ordered close for all transports.
///
/// The exact same guard logic used to be copy-pasted into all four transport
/// implementations (`ble_transport`, `hid_transport`, `rust_ble_transport`,
/// `rust_hid_transport`). This base keeps it in ONE place (DRY) and adds the
/// missing closed-state check: after [guardedClose] starts, further exchanges
/// are rejected instead of racing against an already-closing device.
abstract class GuardedTransport extends Transport {
  final _eventController = StreamController<TransportEvent>.broadcast();

  Completer<void>? _exchangeBusyPromise;
  Timer? _unresponsiveTimer;
  bool _closed = false;

  @override
  Stream<TransportEvent> get events => _eventController.stream;

  /// Serializes device access: concurrent exchanges throw
  /// [TransportRaceCondition]; exchanges after [guardedClose] throw
  /// [DisconnectedDeviceDuringOperationException]. When [unresponsiveAfter]
  /// is non-null a [TransportEvent.unresponsive] is emitted after the
  /// timeout while the exchange is still running (and `responsive` after
  /// late completion) - HID devices need this, BLE does not.
  @protected
  Future<T> guardedExchange<T>(
    Future<T> Function() f, {
    Duration? unresponsiveAfter,
  }) async {
    if (_closed) {
      throw DisconnectedDeviceDuringOperationException(
          'Transport is closed.');
    }
    if (_exchangeBusyPromise != null) {
      throw TransportRaceCondition(
          'An action was already pending on the Ledger device.');
    }

    final completer = Completer<void>();
    _exchangeBusyPromise = completer;

    bool unresponsiveReached = false;
    if (unresponsiveAfter != null) {
      _unresponsiveTimer = Timer(unresponsiveAfter, () {
        unresponsiveReached = true;
        _eventController.add(TransportEvent.unresponsive);
      });
    }

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

  /// Waits for the in-flight exchange, then runs the transport-specific
  /// [rawClose] and finally closes the event stream. Sets the closed flag
  /// FIRST so no new exchange can start while the device is closing.
  @protected
  Future<void> guardedClose(Future<void> Function() rawClose) async {
    _closed = true;
    await _exchangeBusyPromise?.future;
    await rawClose();
    await _eventController.close();
  }
}

abstract class Transport {
  DeviceModel? get deviceModel;

  Stream<TransportEvent> get events;

  void setScrambleKey(String key);

  Future<Uint8List> exchange(Uint8List apdu);

  Future<void> close();

  Future<Uint8List> send(
    int cla,
    int ins,
    int p1,
    int p2,
    Uint8List data, [
    TransportStatusError? Function(int)? statusCodeChecker,
  ]) async {
    if (data.length > 255) {
      throw TransportException(
        'data.length exceed 255 bytes limit',
        'DataLengthTooBig',
      );
    }

    final apdu = Uint8List.fromList([cla, ins, p1, p2, data.length, ...data]);
    final response = await exchange(apdu);

    if (response.length < 2) {
      throw TransportException(
        'Response is too short',
        'InvalidResponseLength',
      );
    }

    final sw =
        (response[response.length - 2] << 8) | response[response.length - 1];

    debugPrint("Status code: 0x${sw.toRadixString(16)}");

    if (sw != 0x9000) {
      if (statusCodeChecker != null) {
        final exception = statusCodeChecker(sw);
        if (exception != null) {
          throw exception;
        }
      }
      throw TransportStatusError(sw, 'Status code: 0x${sw.toRadixString(16)}');
    }

    return response.sublist(0, response.length - 2);
  }
}
