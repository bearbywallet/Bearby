import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bearby/config/bip_purposes.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/ledger/bitcoin/btc_ledger_app.dart';
import 'package:bearby/ledger/common.dart';
import 'package:bearby/ledger/ethereum/eth_ledger_app.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/ledger/transport/ble_transport.dart';
import 'package:bearby/ledger/transport/hid_transport.dart';
import 'package:bearby/ledger/transport/rust_ble_transport.dart';
import 'package:bearby/ledger/transport/rust_hid_transport.dart';
import 'package:bearby/ledger/transport/transport.dart';
import 'package:bearby/ledger/tron/tron_ledger_app.dart';
import 'package:bearby/ledger/zilliqa/zilliqa_ledger_app.dart';
import 'package:bearby/mixins/eip712.dart';
import 'package:bearby/src/rust/api/btc_ledger.dart' as btc_ffi;
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/models/account.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';

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

enum LedgerAppType {
  unknown,
  zilliqa,
  ethereum,
  tron,
  bitcoin,
}

class LedgerAppDetectionError implements Exception {
  final String message;
  LedgerAppDetectionError(this.message);

  @override
  String toString() => message;
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
  LedgerAppType _detectedAppType = LedgerAppType.unknown;

  bool get _useRustTransport =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  Set<DiscoveredDevice> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  DiscoveredDevice? get connectingDevice => _connectingDevice;
  Transport? get connectedTransport => _connectedTransport;
  LedgerStatus get status => _status;
  String? get errorDetails => _errorDetails;
  LedgerAppType get detectedAppType => _detectedAppType;
  bool get isZilliqaApp => _detectedAppType == LedgerAppType.zilliqa;
  bool get isEthApp => _detectedAppType == LedgerAppType.ethereum;
  bool get isTronApp => _detectedAppType == LedgerAppType.tron;
  bool get isBtcApp => _detectedAppType == LedgerAppType.bitcoin;

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

    if (_useRustTransport) {
      _startRustBleScan();
    } else {
      final bleSub = BleTransport.listen().listen(
        (event) {
          _discoveredDevices
              .add(DiscoveredDevice.fromBleDevice(event.rawDevice));
          _updateStatus(LedgerStatus.foundDevices);
        },
        onError: (e) => _handleScanError(e, "BLE"),
      );
      _scanSubscriptions.add(bleSub);
    }
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
        final discoveredHid = _useRustTransport
            ? await RustHidTransport.list()
            : await HidTransport.list();
        _discoveredDevices.addAll(discoveredHid);
        _updateStatus(LedgerStatus.foundDevices);
      } on PlatformException catch (e) {
        _handleScanError(e, "USB Polling ${e.code}");
      } catch (e) {
        _handleScanError(e, "USB Polling");
      }
    });
  }

  void _startRustBleScan() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isScanning) {
        timer.cancel();
        return;
      }
      try {
        final bleDevices = await RustBleTransport.scan();
        _discoveredDevices.addAll(bleDevices);
        if (bleDevices.isNotEmpty) {
          _updateStatus(LedgerStatus.foundDevices);
        }
      } catch (e) {
        _handleScanError(e, "BLE Rust");
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

  Future<String> signEIP712HashedMessage({
    required TypedDataEip712 typedData,
    required AccountInfo account,
    required int slip44,
  }) async {
    if (slip44 == kTronSlip44) {
      final tronApp = TronLedgerApp(_connectedTransport!);
      final typedDataJson = jsonEncode(typedData.toJson());
      final eip712Hashes =
          await prepareEip712Message(typedDataJson: typedDataJson);

      final sig = await tronApp.signTIP712HashedMessage(
        index: account.index.toInt(),
        domainSeparator: eip712Hashes.domainSeparator,
        hashStructMessage: eip712Hashes.hashStructMessage,
      );

      return sig.toHexString();
    } else if (slip44 == kEthereumSlip44 || slip44 == kZilliqaSlip44) {
      final evmApp = EthLedgerApp(_connectedTransport!);
      final typedDataJson = jsonEncode(typedData.toJson());
      final eip712Hashes =
          await prepareEip712Message(typedDataJson: typedDataJson);

      final sig = await evmApp.signEIP712HashedMessage(
        index: account.index.toInt(),
        domainSeparator: eip712Hashes.domainSeparator,
        hashStructMessage: eip712Hashes.hashStructMessage,
      );

      return sig.toHexString();
    } else {
      throw "Invlid slip44";
    }
  }

  Future<Uint8List> signTransaction({
    required TransactionRequestInfo transaction,
    required int walletIndex,
    required int accountIndex,
    required AccountInfo account,
    int bipPurpose = kBip86Purpose,
  }) async {
    if (transaction.scilla != null) {
      final zilliqaApp = ZilliqaLedgerApp(_connectedTransport!);
      final sig = await zilliqaApp.signTxn(
        keyIndex: account.index.toInt(),
        transaction: transaction,
        walletIndex: walletIndex,
        accountIndex: accountIndex,
      );

      return sig;
    } else if (transaction.evm != null) {
      final evmApp = EthLedgerApp(_connectedTransport!);
      final sig = await evmApp.clearSignTransaction(
        transaction: transaction,
        walletIndex: walletIndex,
        accountIndex: account.index.toInt(),
        slip44: kEthereumSlip44,
      );

      return sig.toBytes();
    } else if (transaction.tron != null) {
      final tronApp = TronLedgerApp(_connectedTransport!);
      final sig = await tronApp.clearSignTransaction(
        transaction: transaction,
        walletIndex: walletIndex,
        accountIndex: accountIndex,
      );

      return sig.toBytes();
    } else if (transaction.btc != null) {
      final btcApp = BtcLedgerApp(_connectedTransport!);

      final psbtBytes = await btc_ffi.btcLedgerBuildPsbtFromTx(
        txHex: transaction.btc!,
        witnessUtxosJson: transaction.metadata.btcWitnessUtxos ?? '[]',
      );

      // Get fingerprint & xpub to prepare the PSBT with bip32_derivation
      final fingerprint = await btcApp.getMasterFingerprint();
      final accountPath = "m/$bipPurpose'/0'/$accountIndex'";
      final xpub = await btcApp.getExtendedPubkey(path: accountPath);

      // Prepare PSBT: populates bip32_derivation (pubkeys) for non-Taproot
      final preparedPsbt = await btc_ffi.btcLedgerPreparePsbt(
        psbtBytes: psbtBytes,
        masterFingerprint: fingerprint,
        bipPurpose: bipPurpose,
        accountIndex: accountIndex,
        xpub: xpub,
      );

      final signatures = await btcApp.signPsbt(
        psbtBytes: preparedPsbt,
        bipPurpose: bipPurpose,
        accountIndex: accountIndex,
      );

      final ledgerSigs = <btc_ffi.LedgerInputSignature>[];
      for (int i = 0; i < signatures.length; i++) {
        ledgerSigs.add(btc_ffi.LedgerInputSignature(
          inputIndex: i,
          signature: signatures[i],
          pubkey: Uint8List(0),
        ));
      }

      final finalized = await btc_ffi.btcLedgerFinalizePsbtWithSigs(
        psbtBytes: preparedPsbt,
        sigs: ledgerSigs,
        addrType: bipPurpose,
      );

      return Uint8List.fromList(finalized.psbtBytes);
    } else {
      throw "invalid tx";
    }
  }

  Future<String> signMesage({
    required String message,
    required AccountInfo account,
    required BigInt walletIndex,
    required int slip44,
    int bipPurpose = kBip86Purpose,
  }) async {
    String? sig;

    if (slip44 == kZilliqaSlip44 && account.addrType == 0) {
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
    } else if (slip44 == kTronSlip44) {
      final tronApp = TronLedgerApp(_connectedTransport!);
      Uint8List bytes = utf8.encode(message);
      final personalSig = await tronApp.signPersonalMessage(
        index: account.index.toInt(),
        message: bytes,
      );
      sig = personalSig.toHexString();
    } else if (slip44 == kZilliqaSlip44 || slip44 == kEthereumSlip44) {
      final evmApp = EthLedgerApp(_connectedTransport!);
      Uint8List bytes = utf8.encode(message);
      final personalSig = await evmApp.signPersonalMessage(
        index: account.index.toInt(),
        message: bytes,
      );
      sig = personalSig.toHexString();
    } else if (slip44 == kBitcoinlip44) {
      final btcApp = BtcLedgerApp(_connectedTransport!);
      final sigBytes = await btcApp.signMessage(
        message: message,
        bipPurpose: bipPurpose,
        index: account.index.toInt(),
      );
      sig = sigBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    } else {
      throw "Invalid slip44";
    }

    return sig;
  }

  Future<LedgerAppType> detectLedgerApp() async {
    if (_connectedTransport == null) {
      throw LedgerAppDetectionError('Not connected to Ledger device');
    }

    try {
      final zilliqaApp = ZilliqaLedgerApp(_connectedTransport!);
      final version = await zilliqaApp.getVersion();
      if (version != null) {
        _detectedAppType = LedgerAppType.zilliqa;
        notifyListeners();
        return LedgerAppType.zilliqa;
      }
    } catch (_) {}

    try {
      final tronApp = TronLedgerApp(_connectedTransport!);
      await tronApp.getAppConfiguration();
      final account = await tronApp.getAddress(index: 0);
      if (account.address.startsWith('T')) {
        _detectedAppType = LedgerAppType.tron;
        notifyListeners();
        return LedgerAppType.tron;
      }
    } catch (_) {}

    try {
      final btcApp = BtcLedgerApp(_connectedTransport!);
      final fingerprint = await btcApp.getMasterFingerprint();
      if (fingerprint.length == 4) {
        _detectedAppType = LedgerAppType.bitcoin;
        notifyListeners();
        return LedgerAppType.bitcoin;
      }
    } catch (_) {}

    try {
      final ethApp = EthLedgerApp(_connectedTransport!);
      final config = await ethApp.getAppConfiguration();
      if (config != null) {
        _detectedAppType = LedgerAppType.ethereum;
        notifyListeners();
        return LedgerAppType.ethereum;
      }
    } catch (_) {}

    _detectedAppType = LedgerAppType.unknown;
    notifyListeners();
    throw LedgerAppDetectionError(
        'Failed to detect Ledger app. Please open Zilliqa, Ethereum, Tron, or Bitcoin app on your Ledger device.');
  }

  Future<List<LedgerAccount>> getAccounts({
    required DiscoveredDevice device,
    required int slip44,
    required int count,
    required int chainId,
    int bipPurpose = kBip86Purpose,
  }) async {
    if (_connectedTransport == null) {
      await open(device);
    }

    await detectLedgerApp();

    List<LedgerAccount> accounts = [];

    if (_detectedAppType == LedgerAppType.zilliqa && slip44 == kZilliqaSlip44) {
      final zilliqaApp = ZilliqaLedgerApp(_connectedTransport!);
      accounts = await zilliqaApp
          .getPublicAddress(List<int>.generate(count, (i) => i));
    } else if (_detectedAppType == LedgerAppType.tron &&
        slip44 == kTronSlip44) {
      final tronApp = TronLedgerApp(_connectedTransport!);
      accounts = await tronApp.getAccounts(
        indices: List<int>.generate(count, (i) => i),
      );
    } else if (_detectedAppType == LedgerAppType.bitcoin &&
        slip44 == kBitcoinlip44) {
      final btcApp = BtcLedgerApp(_connectedTransport!);
      accounts = await btcApp.getAccounts(
        indices: List<int>.generate(count, (i) => i),
        bipPurpose: bipPurpose,
      );
    } else if (slip44 == kEthereumSlip44 || slip44 == kZilliqaSlip44) {
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
      if (_useRustTransport) {
        if (device.connectionType == ConnectionType.ble) {
          transport = await RustBleTransport.open(device);
        } else {
          transport = await RustHidTransport.open(device);
        }
      } else if (device.connectionType == ConnectionType.ble) {
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
      _detectedAppType = LedgerAppType.unknown;
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
