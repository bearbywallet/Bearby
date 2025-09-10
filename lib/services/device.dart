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

    List<String> platformSpecificIdentifiers = [];

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      platformSpecificIdentifiers = [
        info.brand,
        info.manufacturer,
        info.hardware,
        info.model,
        info.product,
        info.device,
        info.board,
        info.isPhysicalDevice.toString(),
      ];
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      platformSpecificIdentifiers = [
        info.model,
        info.localizedModel,
        info.utsname.machine,
        info.isPhysicalDevice.toString(),
      ];
    } else if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      platformSpecificIdentifiers = [
        info.computerName,
        info.model,
        info.arch,
        info.osRelease,
        info.systemGUID ?? 'N/A',
      ];
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      platformSpecificIdentifiers = [
        info.computerName,
        info.productName,
        info.numberOfCores.toString(),
        info.systemMemoryInMegabytes.toString(),
      ];
    } else if (Platform.isLinux) {
      final info = await _deviceInfo.linuxInfo;
      platformSpecificIdentifiers = [
        info.name,
        info.version ?? "",
        info.id,
        info.prettyName,
      ];
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    return [
      ...platformSpecificIdentifiers,
      packageInfo.packageName,
      packageInfo.buildSignature,
      ...methods
    ];
  }

  Future<Map<String, String>> getDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    Map<String, String> platformSpecificInfo = {};

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      platformSpecificInfo = {
        'brand': info.brand,
        'manufacturer': info.manufacturer,
        'hardware': info.hardware,
        'model': info.model,
        'product': info.product,
        'device': info.device,
        'board': info.board,
        'isPhysicalDevice': info.isPhysicalDevice.toString(),
      };
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      platformSpecificInfo = {
        'model': info.model,
        'localizedModel': info.localizedModel,
        'machine': info.utsname.machine,
        'isPhysicalDevice': info.isPhysicalDevice.toString(),
      };
    } else if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      platformSpecificInfo = {
        'computerName': info.computerName,
        'hostName': info.hostName,
        'arch': info.arch,
        'model': info.model,
        'kernelVersion': info.kernelVersion,
        'osRelease': info.osRelease,
        'activeCPUs': info.activeCPUs.toString(),
        'memorySize': info.memorySize.toString(),
        'cpuFrequency': info.cpuFrequency.toString(),
        'systemGUID': info.systemGUID ?? 'N/A',
      };
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      platformSpecificInfo = {
        'computerName': info.computerName,
        'productName': info.productName,
        'numberOfCores': info.numberOfCores.toString(),
        'systemMemoryInMegabytes': info.systemMemoryInMegabytes.toString(),
      };
    } else if (Platform.isLinux) {
      final info = await _deviceInfo.linuxInfo;
      platformSpecificInfo = {
        'name': info.name,
        'version': info.version ?? "",
        'id': info.id,
        'idLike': info.idLike?.join(', ') ?? '',
        'versionCodename': info.versionCodename ?? "",
        'versionId': info.versionId ?? "",
        'prettyName': info.prettyName,
      };
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    platformSpecificInfo.addAll({
      'appId': packageInfo.packageName,
      'buildSignature': packageInfo.buildSignature,
    });

    return platformSpecificInfo;
  }
}
