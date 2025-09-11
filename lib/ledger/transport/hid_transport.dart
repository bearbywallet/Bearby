import 'dart:async';
import 'package:flutter/services.dart';
import 'package:zilpay/ledger/models/device_model.dart';
import 'package:zilpay/ledger/transport/exceptions.dart';
import 'package:zilpay/ledger/transport/transport.dart';

class DeviceInfo {
  final Map<String, dynamic> rawData;
  final DeviceModel? deviceModel;

  DeviceInfo(this.rawData)
      : deviceModel = Devices.identifyUSBProductId(rawData['productId'] as int);

  int get vendorId => rawData['vendorId'] as int;
  int get deviceId => rawData['deviceId'] as int;
  int get productId => rawData['productId'] as int;
  String get name => rawData['name'] as String;
  String get devicePath => rawData['deviceName'] as String;
  String get deviceModelId => rawData['deviceModel']['id'] as String;
  String get deviceModelProducName =>
      rawData['deviceModel']['productName'] as String;
}

class DescriptorEvent {
  final String type;
  final DeviceInfo descriptor;

  DescriptorEvent(this.type, this.descriptor);
}

class HidTransport extends Transport {
  final String _id;
  @override
  final DeviceModel? deviceModel;

  Completer<void>? _exchangeBusyPromise;
  Timer? _unresponsiveTimer;
  final _eventController = StreamController<TransportEvent>.broadcast();

  static const _channel = MethodChannel('ledger.com/hid');
  static const _eventChannel = EventChannel('ledger.com/hid/events');
  static const _ledgerUSBVendorId = 0x2c97;

  static final _disconnectedErrors = [
    'I/O error',
    'DISCONNECTED',
    'PERMISSION_DENIED',
    'DEVICE_NOT_FOUND',
  ];

  HidTransport._(this._id, int productId)
      : deviceModel = Devices.identifyUSBProductId(productId);

  @override
  Stream<TransportEvent> get events => _eventController.stream;

  static Future<bool> isSupported() async => true;

  static Future<List<DeviceInfo>> list() async {
    final List<dynamic> devices = await _channel.invokeMethod('getDeviceList');
    return devices
        .map((d) => DeviceInfo(Map<String, dynamic>.from(d)))
        .where((d) => d.vendorId == _ledgerUSBVendorId)
        .toList();
  }

  static Stream<DescriptorEvent> listen() {
    final controller = StreamController<DescriptorEvent>();

    list().then((devices) {
      for (final device in devices) {
        controller.add(DescriptorEvent('add', device));
      }
    });

    _eventChannel.receiveBroadcastStream().listen((event) {
      final eventMap = Map<String, dynamic>.from(event);
      final descriptorMap = Map<String, dynamic>.from(eventMap['descriptor']);
      final deviceInfo = DeviceInfo(descriptorMap);
      controller.add(DescriptorEvent(eventMap['type'] as String, deviceInfo));
    });

    return controller.stream;
  }

  static Future<HidTransport> open(DeviceInfo deviceInfo) async {
    try {
      final Map<dynamic, dynamic> nativeObj =
          await _channel.invokeMethod('openDevice', deviceInfo.rawData);
      return HidTransport._(nativeObj['id'] as String, deviceInfo.productId);
    } on PlatformException catch (e) {
      if (_disconnectedErrors.contains(e.code) ||
          (_disconnectedErrors
              .any((msg) => e.message?.contains(msg) ?? false))) {
        throw DisconnectedDeviceException(e.toString());
      }
      rethrow;
    }
  }

  @override
  Future<Uint8List> exchange(Uint8List apdu) async {
    return _exchangeAtomic(() async {
      try {
        final apduHex =
            apdu.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
        final resultHex = await _channel.invokeMethod<String>('exchange', {
          'deviceId': _id,
          'apduHex': apduHex,
        });
        if (resultHex == null) {
          throw DisconnectedDeviceDuringOperationException(
              'Empty response from native');
        }

        final res = Uint8List.fromList(List<int>.generate(
          resultHex.length ~/ 2,
          (i) => int.parse(resultHex.substring(i * 2, i * 2 + 2), radix: 16),
        ));
        return res;
      } on PlatformException catch (e) {
        if (_disconnectedErrors.contains(e.code) ||
            (_disconnectedErrors
                .any((msg) => e.message?.contains(msg) ?? false))) {
          throw DisconnectedDeviceDuringOperationException(e.toString());
        }
        rethrow;
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
    await _channel.invokeMethod('closeDevice', {'deviceId': _id});
    await _eventController.close();
  }

  @override
  void setScrambleKey(String key) {}
}
