import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/ledger/transport/ble_transport.dart';
import 'package:zilpay/ledger/transport/hid_transport.dart';
import 'package:zilpay/ledger/transport/transport.dart';

enum LedgerStatus {
  initializing,
  scanning,
  foundDevices,
  scanFinishedNoDevices,
  scanFinishedWithDevices,
  scanError,
  connecting,
  connectionSuccess,
  connectionFailed,
  disconnected,
}

class LedgerViewController extends ChangeNotifier {
  final Set<DiscoveredDevice> _discoveredDevices = {};
  final List<StreamSubscription> _scanSubscriptions = [];
  Timer? _hidPollingTimer;

  bool _isScanning = false;
  bool _isConnecting = false;
  String? _errorDetails;
  Transport? _connectedTransport;
  DiscoveredDevice? _connectingDevice;
  LedgerStatus _status = LedgerStatus.initializing;

  Set<DiscoveredDevice> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  DiscoveredDevice? get connectingDevice => _connectingDevice;
  Transport? get connectedTransport => _connectedTransport;
  LedgerStatus get status => _status;
  String? get errorDetails => _errorDetails;

  Future<void> scan() async {
    if (_isScanning || _isConnecting) return;

    if (_connectedTransport != null) {
      await disconnect();
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        _updateStatus(LedgerStatus.scanError, "Permissions not granted.");
        return;
      }
    }

    _isScanning = true;
    _discoveredDevices.clear();
    _updateStatus(LedgerStatus.scanning);

    if (Platform.isAndroid) {
      _startHidPolling();
    }

    final bleSub = BleTransport.listen().listen(
      (event) {
        _discoveredDevices.add(DiscoveredDevice.fromBleDevice(event.rawDevice));
        _updateStatus(LedgerStatus.foundDevices);
      },
      onError: (e) => _handleScanError(e, "BLE"),
    );
    _scanSubscriptions.add(bleSub);
  }

  void _startHidPolling() {
    _hidPollingTimer?.cancel();
    _hidPollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!_isScanning) {
        _hidPollingTimer?.cancel();
        return;
      }
      try {
        final discoveredHid = await HidTransport.list();
        _discoveredDevices.addAll(discoveredHid);
        _updateStatus(LedgerStatus.foundDevices);
      } on PlatformException catch (e) {
        _handleScanError(e, "USB Polling ${e.code}");
      } catch (e) {
        _handleScanError(e, "USB Polling");
      }
    });
  }

  void _handleScanError(dynamic error, String type) {
    debugPrint('[$type Scan] Scan Error: $error');
    _updateStatus(LedgerStatus.scanError, error.toString());
    stopScan();
  }

  void stopScan() {
    _hidPollingTimer?.cancel();
    _hidPollingTimer = null;

    for (var sub in _scanSubscriptions) {
      sub.cancel();
    }
    _scanSubscriptions.clear();

    if (_isScanning) {
      _isScanning = false;
      _updateStatus(_discoveredDevices.isEmpty
          ? LedgerStatus.scanFinishedNoDevices
          : LedgerStatus.scanFinishedWithDevices);
    }
  }

  Future<Transport?> open(DiscoveredDevice device) async {
    if (_isConnecting) return null;

    if (_isScanning) {
      stopScan();
    }

    _isConnecting = true;
    _connectingDevice = device;
    _updateStatus(LedgerStatus.connecting);

    try {
      Transport transport;
      if (device.connectionType == ConnectionType.ble) {
        transport = await BleTransport.open(device);
      } else {
        transport = await HidTransport.open(device);
      }

      _connectedTransport = transport;
      _updateStatus(LedgerStatus.connectionSuccess);
      return transport;
    } catch (e) {
      _updateStatus(LedgerStatus.connectionFailed, e.toString());
      return null;
    } finally {
      _isConnecting = false;
      _connectingDevice = null;
      if (_connectedTransport == null) {
        _updateStatus(_discoveredDevices.isEmpty
            ? LedgerStatus.scanFinishedNoDevices
            : LedgerStatus.scanFinishedWithDevices);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> disconnect() async {
    if (_connectedTransport == null) return;
    try {
      await _connectedTransport!.close();
    } catch (e) {
      debugPrint("Error disconnecting: $e");
    } finally {
      _connectedTransport = null;
      _updateStatus(LedgerStatus.disconnected);
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isIOS) return true;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  void _updateStatus(LedgerStatus newStatus, [String? error]) {
    _status = newStatus;
    _errorDetails = error;
    notifyListeners();
  }

  @override
  void dispose() {
    stopScan();
    _connectedTransport?.close();
    super.dispose();
  }
}
