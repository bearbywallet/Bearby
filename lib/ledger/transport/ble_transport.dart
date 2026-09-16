import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bearby/ledger/models/device_model.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/ledger/transport/exceptions.dart';
import 'package:bearby/ledger/transport/transport.dart';

class BleDescriptorEvent {
  final String type;
  final DiscoveredDevice descriptor;

  BleDescriptorEvent(this.type, this.descriptor);
}

class BleTransport extends GuardedTransport {
  final String _id;
  @override
  final DeviceModel? deviceModel;

  static const _channel = MethodChannel('ledger.com/ble');
  static const _eventChannel = EventChannel('ledger.com/ble/events');

  BleTransport(this._id, this.deviceModel);


  static Future<bool> isSupported() =>
      _channel.invokeMethod<bool>('isSupported').then((v) => v ?? false);

  static Stream<DiscoveredDevice> listen() async* {
    final Set<String> discoveredIds = {};

    try {
      final List<dynamic> connectedDevices =
          await _channel.invokeMethod('getConnectedDevices');
      for (final deviceData in connectedDevices) {
        final map = Map<String, dynamic>.from(deviceData);
        final device = DiscoveredDevice.fromBleDevice(map);
        if (discoveredIds.add(device.id!)) {
          yield device;
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Error getting connected devices: ${e.message}");
    }

    await _channel.invokeMethod('startScan');
    await for (final event in _eventChannel.receiveBroadcastStream()) {
      final eventMap = Map<String, dynamic>.from(event);
      final descriptorMap = Map<String, dynamic>.from(eventMap['descriptor']);
      final device = DiscoveredDevice.fromBleDevice(descriptorMap);
      if (discoveredIds.add(device.id!)) {
        yield device;
      }
    }
  }

  static Future<BleTransport> open(DiscoveredDevice deviceInfo) async {
    try {
      await _channel.invokeMethod('openDevice', deviceInfo.id);
      return BleTransport(deviceInfo.id!, deviceInfo.model);
    } on PlatformException catch (e) {
      debugPrint("DisconnectedDeviceException $e");
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

  Future<T> _exchangeAtomic<T>(Future<T> Function() f) =>
      guardedExchange(f);

  @override
  Future<void> close() async {
    await guardedClose(
        () => _channel.invokeMethod('closeDevice', {'deviceId': _id}));
  }

  @override
  void setScrambleKey(String key) {}
}
