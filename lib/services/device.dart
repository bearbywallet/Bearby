import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<List<String>> getDeviceIdentifiers() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final biometrics = canCheckBiometrics
        ? (await _localAuth.getAvailableBiometrics())
        : <BiometricType>[];

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
        biometrics.isNotEmpty ? biometrics.first.toString() : 'none'
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
        biometrics.isNotEmpty ? biometrics.first.toString() : 'none'
      ];
    }

    throw UnsupportedError('Unsupported platform');
  }

  Future<Map<String, String>> getDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final biometrics = canCheckBiometrics
        ? (await _localAuth.getAvailableBiometrics())
        : <BiometricType>[];

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
        'biometricType':
            biometrics.isNotEmpty ? biometrics.first.toString() : 'none'
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
        'biometricType':
            biometrics.isNotEmpty ? biometrics.first.toString() : 'none'
      };
    }

    throw UnsupportedError('Unsupported platform');
  }
}
