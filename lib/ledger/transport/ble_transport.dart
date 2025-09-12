import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zilpay/ledger/models/device_model.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/ledger/transport/exceptions.dart';
import 'package:zilpay/ledger/transport/transport.dart';

class BleDescriptorEvent {
  final String type;
  final DiscoveredDevice descriptor;

  BleDescriptorEvent(this.type, this.descriptor);
}

class BleTransport extends Transport {
  final String _id;
  @override
  final DeviceModel? deviceModel;

  Completer<void>? _exchangeBusyPromise;
  final _eventController = StreamController<TransportEvent>.broadcast();

  static const _channel = MethodChannel('ledger.com/ble');
  static const _eventChannel = EventChannel('ledger.com/ble/events');

  BleTransport._(this._id, this.deviceModel);

  @override
  Stream<TransportEvent> get events => _eventController.stream;

  static Future<bool> isSupported() =>
      _channel.invokeMethod<bool>('isSupported').then((v) => v ?? false);

  static Stream<BleDescriptorEvent> listen() {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final eventMap = Map<String, dynamic>.from(event);
      final descriptorMap = Map<String, dynamic>.from(eventMap['descriptor']);
      final deviceInfo = DiscoveredDevice.fromBleDevice(descriptorMap);
      return BleDescriptorEvent(eventMap['type'] as String, deviceInfo);
    });
  }

  static Future<BleTransport> open(DiscoveredDevice deviceInfo) async {
    try {
      await _channel.invokeMethod('openDevice', deviceInfo.id);
      return BleTransport._(deviceInfo.id!, deviceInfo.model);
    } on PlatformException catch (e) {
      throw DisconnectedDeviceException(e.toString());
    }
  }

  @override
  Future<Uint8List> exchange(Uint8List apdu) async {
    return _exchangeAtomic(() async {
      try {
        final result = await _channel.invokeMethod<Uint8List>('exchange', {
          'deviceId': _id,
          'apdu': apdu,
        });

        if (result == null) {
          throw DisconnectedDeviceDuringOperationException(
              'Empty response from native');
        }

        return result;
      } on PlatformException catch (e) {
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
    await _channel.invokeMethod('closeDevice', {'deviceId': _id});
    await _eventController.close();
  }

  @override
  void setScrambleKey(String key) {}
}
