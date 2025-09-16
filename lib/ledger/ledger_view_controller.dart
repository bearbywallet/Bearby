import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ethereum/eth_ledger_app.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/ledger/transport/ble_transport.dart';
import 'package:zilpay/ledger/transport/hid_transport.dart';
import 'package:zilpay/ledger/transport/transport.dart';
import 'package:zilpay/ledger/zilliqa/zilliqa_ledger_app.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/account.dart';

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

    if (Platform.isAndroid || Platform.isIOS) {
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        _updateStatus(LedgerStatus.scanError, "Permissions not granted.");
        return;
      }
    }

    _isScanning = true;
    _updateStatus(LedgerStatus.scanning);

    if (Platform.isAndroid ||
        Platform.isLinux ||
        Platform.isMacOS ||
        Platform.isWindows) {
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

  void addDevice(DiscoveredDevice device) {
    _discoveredDevices.add(device);

    if (device.connectionType == ConnectionType.ble && device.id != null) {
      _connectedTransport = BleTransport(device.id!, device.model);
    } else if (device.connectionType == ConnectionType.usb) {
      _connectedTransport =
          HidTransport(device.id!, device.productId!, device.model);
    }
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

  Future<String> signMesage({
    required String message,
    required AccountInfo account,
    required BigInt walletIndex,
  }) async {
    String? sig;

    if (account.slip44 == 313 && account.addr.startsWith("zil1")) {
      final zilliqaApp = ZilliqaLedgerApp(_connectedTransport!);
      final hashBytes = await prepareMessage(
        walletIndex: walletIndex,
        accountIndex: account.index,
        message: message,
      );
      sig = await zilliqaApp.signHash(
        account.index.toInt(),
        hashBytes,
      );
    } else {
      final evmApp = EthLedgerApp(_connectedTransport!);
      Uint8List bytes = utf8.encode(message);
      final personalSig = await evmApp.signPersonalMessage(
        index: account.index.toInt(),
        message: bytes,
      );
      sig = personalSig.toHexString();
    }

    return sig;
  }

  Future<List<LedgerAccount>> getAccounts({
    required DiscoveredDevice device,
    required int slip44,
    required int count,
    required int chainId,
    bool zilliqaLegacy = false,
  }) async {
    if (_connectedTransport == null) {
      await open(device);
    }

    List<LedgerAccount> accounts = [];

    if (zilliqaLegacy && slip44 == 313) {
      final zilliqaApp = ZilliqaLedgerApp(_connectedTransport!);
      accounts = await zilliqaApp
          .getPublicAddress(List<int>.generate(count, (i) => i));
    } else if (slip44 == 60 || slip44 == 313) {
      final evmApp = EthLedgerApp(_connectedTransport!);
      accounts = await evmApp.getAccounts(
        chainId: chainId,
        indices: List<int>.generate(count, (i) => i),
      );
    }

    return accounts;
  }

  Future<Transport?> open(DiscoveredDevice device) async {
    if (_isConnecting) return null;

    if (_isScanning) {
      stopScan();
    }

    if (_connectedTransport != null) {
      await disconnect();
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
