import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class StableDeviceData {
  final String model;
  final String manufacturer;
  final bool isPhysicalDevice;
  final String hardwareId;
  final String appId;
  final String buildSignature;

  StableDeviceData({
    required this.model,
    required this.manufacturer,
    required this.isPhysicalDevice,
    required this.hardwareId,
    required this.appId,
    required this.buildSignature,
  });

  Map<String, String> toMap() => {
        'model': model,
        'manufacturer': manufacturer,
        'isPhysicalDevice': isPhysicalDevice.toString(),
        'hardwareId': hardwareId,
        'appId': appId,
        'buildSignature': buildSignature,
      };

  @override
  String toString() =>
      'StableDeviceData(model: $model, manufacturer: $manufacturer, '
      'isPhysicalDevice: $isPhysicalDevice, hardwareId: $hardwareId, '
      'appId: $appId, buildSignature: $buildSignature)';
}

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PackageInfo? _packageInfo;

  Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  Future<Map<String, String>> getStableDeviceInfo() async {
    if (_packageInfo == null) {
      await initialize();
    }

    final baseInfo = await _getPlatformInfo();
    return {
      ...baseInfo,
      'appId': _packageInfo!.packageName,
      'buildSignature': _packageInfo!.buildSignature,
      'buildNumber': _packageInfo!.buildNumber,
    };
  }

  Future<Map<String, String>> _getPlatformInfo() async {
    if (Platform.isAndroid) {
      final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
      return {
        'brand': info.brand,
        'manufacturer': info.manufacturer,
        'hardware': info.hardware,
        'model': info.model,
        'product': info.product,
        'device': info.device,
        'board': info.board,
        'isPhysicalDevice': info.isPhysicalDevice.toString(),
      };
    }

    if (Platform.isIOS) {
      final IosDeviceInfo info = await _deviceInfo.iosInfo;
      return {
        'model': info.model,
        'localizedModel': info.localizedModel,
        'isPhysicalDevice': info.isPhysicalDevice.toString(),
        'utsname.machine': info.utsname.machine,
      };
    }

    throw UnsupportedError('Unsupported platform');
  }

  Future<String> getStableDeviceIdentifier() async {
    if (_packageInfo == null) {
      await initialize();
    }

    final deviceInfo = await _getPlatformInfo();
    final appSignature = _packageInfo!.buildSignature;

    if (Platform.isAndroid) {
      return '${deviceInfo['hardware']}_${deviceInfo['brand']}_${deviceInfo['model']}_${_packageInfo!.packageName}_$appSignature'
          .toLowerCase()
          .replaceAll(' ', '_');
    }

    if (Platform.isIOS) {
      return '${deviceInfo['utsname.machine']}_${_packageInfo!.packageName}_$appSignature'
          .toLowerCase();
    }

    throw UnsupportedError('Unsupported platform');
  }

  Future<StableDeviceData> getBasicStableInfo() async {
    if (_packageInfo == null) {
      await initialize();
    }

    if (Platform.isAndroid) {
      final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
      return StableDeviceData(
        model: info.model,
        manufacturer: info.manufacturer,
        isPhysicalDevice: info.isPhysicalDevice,
        hardwareId: info.hardware,
        appId: _packageInfo!.packageName,
        buildSignature: _packageInfo!.buildSignature,
      );
    }

    if (Platform.isIOS) {
      final IosDeviceInfo info = await _deviceInfo.iosInfo;
      return StableDeviceData(
        model: info.model,
        manufacturer: 'Apple',
        isPhysicalDevice: info.isPhysicalDevice,
        hardwareId: info.utsname.machine,
        appId: _packageInfo!.packageName,
        buildSignature: _packageInfo!.buildSignature,
      );
    }

    throw UnsupportedError('Unsupported platform');
  }
}
