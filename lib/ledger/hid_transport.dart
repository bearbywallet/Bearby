import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'device_model.dart';
import 'exceptions.dart';

class DeviceInfo {
  final Map<String, dynamic> rawData;
  final DeviceModel? deviceModel;

  DeviceInfo(this.rawData)
      : deviceModel = Devices.identifyUSBProductId(rawData['productId'] as int);

  int get vendorId => rawData['vendorId'] as int;
  int get productId => rawData['productId'] as int;
  String get deviceName => rawData['deviceName'] as String;
}

class DescriptorEvent {
  final String type;
  final DeviceInfo descriptor;

  DescriptorEvent(this.type, this.descriptor);
}

class HidTransport {
  final String _id;
  final DeviceModel? deviceModel;
  Completer<void>? _exchangeBusyPromise;
  Timer? _unresponsiveTimer;

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

  Future<Uint8List> send(int cla, int ins, int p1, int p2, Uint8List data,
      [List<int> statusList = const [StatusCodes.ok]]) async {
    if (data.length > 255) {
      throw TransportException(
          'data.length exceed 255 bytes limit', 'DataLengthTooBig');
    }

    final apdu = Uint8List.fromList([cla, ins, p1, p2, data.length, ...data]);
    final response = await exchange(apdu);

    final sw =
        response.buffer.asByteData().getUint16(response.length - 2, Endian.big);
    if (!statusList.contains(sw)) {
      throw TransportStatusError(sw);
    }

    return response.sublist(0, response.length - 2);
  }

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
      // You can emit an event here if needed, e.g. using a StreamController
    });

    try {
      final res = await f();
      if (unresponsiveReached) {
        // Emit responsive event if needed
      }
      return res;
    } finally {
      _unresponsiveTimer?.cancel();
      completer.complete();
      _exchangeBusyPromise = null;
    }
  }

  Future<void> close() async {
    await _exchangeBusyPromise?.future;
    await _channel.invokeMethod('closeDevice', {'deviceId': _id});
  }

  void setScrambleKey(String key) {}
}
