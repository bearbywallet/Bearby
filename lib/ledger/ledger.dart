import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zilpay/ledger/apps.dart';

/// Service to manage Ledger device interactions
class LedgerService {
  Ledger? _ledger;
  StreamSubscription? _scanSubscription;
  final List<LedgerDevice> _devices = [];
  LedgerDevice? _connectedDevice;
  bool _isScanning = false;

  // Stream controllers
  final _devicesController = StreamController<List<LedgerDevice>>.broadcast();
  final _scanningController = StreamController<bool>.broadcast();
  final _connectionController = StreamController<LedgerDevice?>.broadcast();

  // Streams
  Stream<List<LedgerDevice>> get devices => _devicesController.stream;
  Stream<bool> get isScanning => _scanningController.stream;
  Stream<LedgerDevice?> get connectedDevice => _connectionController.stream;

  // Constructor
  LedgerService() {
    _initLedger();
  }

  void _initLedger() {
    try {
      final options = LedgerOptions(
        maxScanDuration: const Duration(milliseconds: 5000),
        scanMode: ScanMode.lowLatency,
      );

      _ledger = Ledger(
        options: options,
        onPermissionRequest: _handlePermissionRequest,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize Ledger: $e');
      }
    }
  }

  Future<bool> _handlePermissionRequest(BleStatus status) async {
    final statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    if (status != BleStatus.ready) return false;

    return statuses.values.where((status) => status.isDenied).isEmpty;
  }

  Future<void> startScanning() async {
    if (_isScanning || _ledger == null) return;

    _isScanning = true;
    _devices.clear();
    _scanningController.add(true);
    _devicesController.add(_devices);

    try {
      if (Platform.isAndroid) {
        // Check for USB devices first
        try {
          final usbDevices = await _ledger!.listUsbDevices();
          _devices.addAll(usbDevices);
          _devicesController.add(_devices);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to list USB devices: $e');
          }
        }
      }

      // Start BLE scanning
      _scanSubscription?.cancel();
      _scanSubscription = _ledger!.scan().listen(
        (device) {
          if (!_devices.contains(device)) {
            _devices.add(device);
            _devicesController.add(_devices);
          }
        },
        onError: (error) {
          print('Scan error: $error');
          stopScanning();
        },
        onDone: stopScanning,
      );
    } catch (e) {
      print('Failed to start scanning: $e');
      stopScanning();
    }
  }

  void stopScanning() {
    _scanSubscription?.cancel();
    _ledger?.stopScanning();
    _isScanning = false;
    _scanningController.add(false);
  }

  Future<void> connectToDevice(LedgerDevice device) async {
    try {
      await _ledger?.connect(device);
      _connectedDevice = device;
      _connectionController.add(device);
    } catch (e) {
      print('Failed to connect: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _ledger?.disconnect(_connectedDevice!);
        _connectedDevice = null;
        _connectionController.add(null);
      } catch (e) {
        print('Failed to disconnect: $e');
        rethrow;
      }
    }
  }

  Future<List<LedgerInstalledApp>> getInstalledApps() async {
    if (_connectedDevice == null || _ledger == null) {
      throw Exception('No device connected');
    }

    try {
      return await _ledger!.sendOperation<List<LedgerInstalledApp>>(
        _connectedDevice!,
        GetInstalledAppsOperation(),
      );
    } catch (e) {
      print('Failed to get installed apps: $e');
      rethrow;
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _devicesController.close();
    _scanningController.close();
    _connectionController.close();
    disconnect();
  }
}
