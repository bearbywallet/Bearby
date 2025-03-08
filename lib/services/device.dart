import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zilpay/services/biometric_service.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<List<String>> getDeviceIdentifiers() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final AuthService authService = AuthService();
    final methods =
        (await authService.getAvailableAuthMethods()).map((e) => e.name);

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return [
        info.brand,
        info.manufacturer,
        info.hardware,
        info.model,
        info.product,
        info.device,
        info.board,
        info.isPhysicalDevice.toString(),
        packageInfo.packageName,
        packageInfo.buildSignature,
        ...methods
      ];
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return [
        info.model,
        info.localizedModel,
        info.utsname.machine,
        info.isPhysicalDevice.toString(),
        packageInfo.packageName,
        packageInfo.buildSignature,
        ...methods
      ];
    }

    throw UnsupportedError('Unsupported platform');
  }

  Future<Map<String, String>> getDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return {
        'brand': info.brand,
        'manufacturer': info.manufacturer,
        'hardware': info.hardware,
        'model': info.model,
        'product': info.product,
        'device': info.device,
        'board': info.board,
        'isPhysicalDevice': info.isPhysicalDevice.toString(),
        'appId': packageInfo.packageName,
        'buildSignature': packageInfo.buildSignature,
      };
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return {
        'model': info.model,
        'localizedModel': info.localizedModel,
        'machine': info.utsname.machine,
        'isPhysicalDevice': info.isPhysicalDevice.toString(),
        'appId': packageInfo.packageName,
        'buildSignature': packageInfo.buildSignature,
      };
    }

    throw UnsupportedError('Unsupported platform');
  }
}
