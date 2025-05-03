import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/ledger_device_card.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:async/async.dart';

class LedgerConnectPage extends StatefulWidget {
  const LedgerConnectPage({super.key});
  @override
  State<LedgerConnectPage> createState() => _LedgerConnectPageState();
}

class _LedgerConnectPageState extends State<LedgerConnectPage> {
  LedgerInterface? _ledgerBle;
  LedgerInterface? _ledgerUsb;
  final Set<LedgerDevice> _discoveredDevices = {};
  StreamSubscription? _scanSubscription;
  bool _isScanning = false;
  bool _isConnecting = false;
  LedgerDevice? _connectingDevice;
  LedgerConnection? _ledgerConnection;
  String _statusText = 'Initializing...';
  StreamSubscription? _disconnectionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLedger();
      Future.delayed(const Duration(milliseconds: 500), _startScanning);
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _disconnectionSubscription?.cancel();
    _ledgerConnection
        ?.disconnect()
        .catchError((e) => debugPrint('Error disconnecting on dispose: $e'));
    _ledgerBle
        ?.dispose()
        .catchError((e) => debugPrint('Error disposing BLE: $e'));
    _ledgerUsb
        ?.dispose()
        .catchError((e) => debugPrint('Error disposing USB: $e'));
    super.dispose();
  }

  void _initLedger() {
    if (!mounted) return;
    try {
      _ledgerBle = LedgerInterface.ble(
        onPermissionRequest: _handlePermissionRequest,
        bleOptions: BluetoothOptions(
          maxScanDuration: const Duration(seconds: 15),
        ),
      );
      _ledgerUsb = Platform.isAndroid ? LedgerInterface.usb() : null;
      setState(() {
        _statusText = 'Ready to scan. Press refresh button.';
      });
    } catch (e) {
      debugPrint('Error initializing Ledger: $e');
      if (!mounted) return;
      setState(() {
        _statusText = 'Error initializing Ledger: $e';
      });
      _showErrorDialog(
          'Initialization Error', 'Failed to initialize Ledger interfaces: $e');
    }
  }

  Future<bool> _handlePermissionRequest(AvailabilityState status) async {
    if (!mounted) return false;

    if (status == AvailabilityState.poweredOff) {
      setState(() {
        _statusText =
            'Bluetooth is turned off. Please enable Bluetooth on your device.';
      });
      _showErrorDialog('Bluetooth Off',
          'Please turn on Bluetooth in your device settings and try again.');
      return false;
    }

    if (status == AvailabilityState.unauthorized) {
      setState(() {
        _statusText = 'Bluetooth permission denied. Please enable in settings.';
      });

      if (Platform.isIOS) {
        _showErrorDialog('Permission Required',
            'This app requires Bluetooth permission to scan for Ledger devices. Please enable Bluetooth permission in your device settings.',
            showSettingsButton: true);
      } else {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ].request();

        final allGranted = statuses.values.every((s) => s.isGranted);
        if (!allGranted && mounted) {
          _showErrorDialog('Permission Denied',
              'Bluetooth permissions are required to scan for Ledger devices. Please grant permissions in settings.',
              showSettingsButton: true);
          return false;
        }
      }
      return false;
    }

    if (status == AvailabilityState.unsupported) {
      setState(() {
        _statusText = 'Bluetooth LE is not supported on this device.';
      });
      _showErrorDialog('Unsupported Device',
          'This device does not support Bluetooth Low Energy, which is required to connect to Ledger devices wirelessly.');
      return false;
    }

    if (Platform.isIOS) {
      return true;
    }

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every((s) => s.isGranted);

    if (!allGranted && mounted) {
      setState(() {
        _statusText = 'Permissions denied. Cannot scan via BLE.';
      });

      _showErrorDialog('Permission Denied',
          'Bluetooth permissions are required to scan for Ledger devices via BLE. Please grant permissions in settings.',
          showSettingsButton: true);
      return false;
    }

    return true;
  }

  Future<void> _startScanning() async {
    if (_isScanning || _isConnecting || _ledgerBle == null) return;

    await _disconnectDevice();
    if (!mounted) return;

    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
      _statusText = 'Scanning for Ledger devices...';
    });

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    try {
      final bleStatus = await _ledgerBle!.status;
      debugPrint('[Scan] Current BLE status: $bleStatus');

      if (bleStatus != AvailabilityState.poweredOn) {
        debugPrint('[Scan] BLE not powered on, current state: $bleStatus');
        final granted = await _handlePermissionRequest(bleStatus);
        if (!granted) {
          setState(() => _isScanning = false);
          return;
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final bleStream = _ledgerBle!.scan();
      final usbStream = Platform.isAndroid ? _ledgerUsb?.scan() : null;

      final combinedStream = StreamGroup.merge([
        bleStream,
        if (usbStream != null) usbStream,
      ]);

      _scanSubscription = combinedStream.listen(
        (device) {
          if (!mounted) return;
          setState(() {
            _discoveredDevices.add(device);
            _statusText = 'Found ${_discoveredDevices.length} device(s)...';
          });
        },
        onError: (error) {
          if (!mounted) return;
          debugPrint('[Scan] Scan Error: $error');
          setState(() {
            _isScanning = false;
            _statusText = 'Scan Error: $error';
          });
          _showErrorDialog('Scan Error', 'Scan Error: $error');
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isScanning = false;
            _statusText = _discoveredDevices.isEmpty
                ? 'Scan finished. No devices found.'
                : 'Scan finished. Found ${_discoveredDevices.length} device(s). Select one to connect.';
          });
        },
      );

      Future.delayed(const Duration(seconds: 16), () {
        if (mounted && _isScanning) {
          _stopScan();
        }
      });
    } catch (e, s) {
      debugPrint('[Scan] Error starting scan: $e\n$s');
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusText = 'Failed to start scan: $e';
      });
      _showErrorDialog('Scan Error', 'Failed to start scan: $e');
    }
  }

  Future<void> _stopScan() async {
    debugPrint("[Scan] Stopping scan...");
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (mounted && _isScanning) {
      setState(() {
        _isScanning = false;
        if (!_isConnecting && _ledgerConnection == null) {
          _statusText = _discoveredDevices.isEmpty
              ? 'Scan stopped.'
              : 'Scan stopped. Found ${_discoveredDevices.length} device(s).';
        }
      });
      debugPrint("[Scan] Scan stopped and state updated.");
    }
  }

  Future<void> _connectToDevice(LedgerDevice device, {int retries = 2}) async {
    if (_isConnecting || _ledgerConnection != null) {
      debugPrint('[Connect] Attempt aborted: Already connecting or connected.');
      return;
    }
    if (_isScanning) {
      await _stopScan();
    }
    if (!mounted) return;
    debugPrint(
        '[Connect] Attempting connection to ${device.name} (${device.id}) via ${device.connectionType.name}');
    setState(() {
      _isConnecting = true;
      _connectingDevice = device;
      _statusText =
          'Connecting to ${device.name} (${device.connectionType.name.toUpperCase()})...';
    });
    LedgerConnection? tempConnection;
    const connectionTimeout = Duration(seconds: 30);
    int attempt = 0;

    while (attempt < retries) {
      try {
        debugPrint(
            '[Connect] Calling ${device.connectionType.name}.connect() with ${connectionTimeout.inSeconds}s timeout... (Attempt ${attempt + 1} of $retries)');
        if (device.connectionType == ConnectionType.ble && _ledgerBle != null) {
          tempConnection = await _ledgerBle!.connect(device).timeout(
            connectionTimeout,
            onTimeout: () {
              debugPrint('[Connect] BLE connection timed out.');
              throw TimeoutException(
                  'Connection timed out after ${connectionTimeout.inSeconds} seconds');
            },
          );
        } else if (device.connectionType == ConnectionType.usb &&
            _ledgerUsb != null) {
          tempConnection = await _ledgerUsb!.connect(device).timeout(
            connectionTimeout,
            onTimeout: () {
              debugPrint('[Connect] USB connection timed out.');
              throw TimeoutException(
                  'Connection timed out after ${connectionTimeout.inSeconds} seconds');
            },
          );
        } else {
          throw Exception('Appropriate Ledger interface not available.');
        }
        debugPrint(
            '[Connect] Connection call successful for ${device.id}. Connection object present:');
        if (!mounted) {
          debugPrint(
              '[Connect] Widget unmounted after connection success, disconnecting.');
          await tempConnection.disconnect().catchError((e) => debugPrint(
              '[Connect] Error disconnecting after widget disposed: $e'));
          return;
        }
        _ledgerConnection = tempConnection;
        setState(() {
          debugPrint('[Connect] Setting state to connected.');
          _statusText = 'Successfully connected to ${device.name}!';
        });
        Navigator.of(context).pushNamed(
          '/net_setup',
          arguments: {
            'ledger': device,
          },
        );
        debugPrint('[Connect] Setting up disconnect listener for ${device.id}');
        _listenForDisconnection(device.id);
        debugPrint('[Connect] Disconnect listener setup initiated.');
        return;
      } on TimeoutException catch (e) {
        debugPrint('[Connect] TimeoutException caught: ${e.message}');
        attempt++;
        if (attempt >= retries) {
          if (!mounted) return;
          setState(() {
            _statusText =
                'Connection Failed: Timed out after $attempt attempts';
            _ledgerConnection = null;
          });
          _showErrorDialog('Connection Failed',
              'Connection timed out after $attempt attempts. Please ensure the device is unlocked and try again.');
        } else {
          debugPrint(
              '[Connect] Retrying connection (attempt ${attempt + 1} of $retries)');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } on LedgerException catch (e) {
        debugPrint('[Connect] LedgerException caught: $e');
        if (!mounted) return;
        setState(() {
          _statusText = 'Connection Failed: $e';
          _ledgerConnection = null;
        });
        _showErrorDialog('Connection Failed', 'Ledger Error: $e');
        return;
      } catch (e, s) {
        debugPrint('[Connect] Generic Exception caught: $e\n$s');
        if (!mounted) return;
        setState(() {
          _statusText = 'Connection Failed: $e';
          _ledgerConnection = null;
        });
        _showErrorDialog('Connection Failed',
            'Could not connect to ${device.name}.\nError: $e');
        return;
      } finally {
        if (mounted && attempt >= retries) {
          setState(() {
            _isConnecting = false;
            _connectingDevice = null;
          });
        }
      }
    }
  }

  void _listenForDisconnection(String deviceId) {
    _disconnectionSubscription?.cancel();
    _disconnectionSubscription = null;
    final manager = (_ledgerConnection?.connectionType == ConnectionType.ble)
        ? _ledgerBle
        : _ledgerUsb;
    if (manager == null || _ledgerConnection == null) {
      debugPrint(
          "[Disconnect Listener] Cannot listen: Manager or connection is null.");
      return;
    }
    debugPrint("[Disconnect Listener] Setting up listener for $deviceId");
    try {
      _disconnectionSubscription =
          manager.deviceStateChanges(deviceId).listen((state) {
        debugPrint("[Disconnect Listener] State changed for $deviceId: $state");
        bool isDisconnected = false;
        if (manager == _ledgerBle) {
          isDisconnected = state == BleConnectionState.disconnected;
        }
        if (isDisconnected &&
            mounted &&
            _ledgerConnection?.device.id == deviceId) {
          debugPrint(
              '[Disconnect Listener] Device $deviceId disconnected externally.');
          _handleDisconnectionUI('Device disconnected.');
        }
      }, onError: (e) {
        debugPrint('[Disconnect Listener] Error in stream for $deviceId: $e');
        if (mounted) {}
      }, onDone: () {
        debugPrint('[Disconnect Listener] Stream done for $deviceId.');
        if (mounted && _ledgerConnection?.device.id == deviceId) {
          _handleDisconnectionUI('Listener stopped.');
        }
      });
    } catch (e) {
      debugPrint(
          "[Disconnect Listener] Error setting up listener for $deviceId: $e");
      if (mounted) {
        setState(() {
          if (_ledgerConnection != null) {
            _statusText = 'Failed to monitor disconnects.';
          }
        });
      }
    }
  }

  Future<void> _disconnectDevice() async {
    debugPrint("[Disconnect] Initiating disconnection...");
    await _disconnectionSubscription?.cancel();
    _disconnectionSubscription = null;
    if (_ledgerConnection == null) {
      debugPrint("[Disconnect] No active connection to disconnect.");
      return;
    }
    final deviceName = _ledgerConnection?.device.name ?? 'Ledger';
    final deviceId = _ledgerConnection?.device.id ?? 'unknown';
    debugPrint("[Disconnect] Disconnecting from $deviceName ($deviceId)");
    final connectionToClose = _ledgerConnection;
    _ledgerConnection = null;
    if (mounted) {
      _handleDisconnectionUI('Disconnecting from $deviceName...');
    }
    try {
      await connectionToClose!.disconnect();
      debugPrint('[Disconnect] Successfully disconnected from $deviceName.');
      if (mounted) {
        _handleDisconnectionUI('Disconnected from $deviceName.');
      }
    } catch (e) {
      debugPrint('[Disconnect] Error during disconnect: $e');
      if (mounted) {
        _handleDisconnectionUI('Error disconnecting from $deviceName.');
      }
    }
  }

  void _handleDisconnectionUI(String statusMsg) {
    debugPrint(
        "[Disconnect Handler] Handling disconnection UI update. Message: $statusMsg");
    if (!mounted) return;
    _disconnectionSubscription?.cancel();
    _disconnectionSubscription = null;
    setState(() {
      _ledgerConnection = null;
      _isConnecting = false;
      _connectingDevice = null;
      _statusText = statusMsg;
    });
  }

  void _showErrorDialog(String title, String content,
      {bool showSettingsButton = false}) {
    if (!mounted) return;
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: TextStyle(color: theme.textPrimary)),
        content: Text(content, style: TextStyle(color: theme.textSecondary)),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Cancel', style: TextStyle(color: theme.primaryPurple)),
          ),
          if (showSettingsButton)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text('Go to Settings',
                  style: TextStyle(color: theme.primaryPurple)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 20);
    final theme = Provider.of<AppState>(context).currentTheme;
    final bool isConnected = _ledgerConnection != null;
    final String pageTitle = "Connect Ledger";

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                CustomAppBar(
                  title: pageTitle,
                  onBackPressed: () => Navigator.pop(context),
                  actionIcon: SvgPicture.asset(
                    'assets/icons/reload.svg',
                    width: 28,
                    height: 28,
                    colorFilter: ColorFilter.mode(
                      (_isScanning || _isConnecting)
                          ? theme.textSecondary.withAlpha(128)
                          : theme.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onActionPressed:
                      (_isScanning || _isConnecting) ? null : _startScanning,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: adaptivePadding, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedOpacity(
                        opacity: (_isScanning || _isConnecting) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: SizedBox(
                          height: 4,
                          child: (_isScanning || _isConnecting)
                              ? LinearProgressIndicator(
                                  backgroundColor:
                                      theme.primaryPurple.withAlpha(51),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.primaryPurple),
                                )
                              : Container(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _startScanning,
                    color: theme.primaryPurple,
                    backgroundColor: theme.cardBackground,
                    child: _discoveredDevices.isEmpty &&
                            !_isScanning &&
                            !_isConnecting &&
                            !isConnected
                        ? LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30.0),
                                    child: Text(
                                      'No devices found. Ensure Ledger is powered on, unlocked, and Bluetooth/USB is enabled.\nPull down or use refresh icon to scan again.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: theme.textSecondary,
                                          fontSize: 16,
                                          height: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                                horizontal: adaptivePadding - 4),
                            itemCount: _discoveredDevices.length,
                            itemBuilder: (context, index) {
                              final device =
                                  _discoveredDevices.elementAt(index);
                              final bool isCurrentlyConnected = isConnected &&
                                  _ledgerConnection!.device.id == device.id;
                              final bool isCurrentlyConnecting =
                                  _isConnecting &&
                                      _connectingDevice?.id == device.id;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 4),
                                child: LedgerCard(
                                  key: ValueKey(device.id),
                                  device: device,
                                  isConnected: isCurrentlyConnected,
                                  isConnecting: isCurrentlyConnecting,
                                  onTap: () => _connectToDevice(device),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                if (isConnected)
                  Padding(
                    padding: EdgeInsets.all(adaptivePadding),
                    child: ElevatedButton.icon(
                      icon: SvgPicture.asset(
                        'assets/icons/disconnect.svg',
                        width: 20,
                        height: 20,
                        colorFilter:
                            ColorFilter.mode(theme.buttonText, BlendMode.srcIn),
                      ),
                      label: Text(
                          'Disconnect from ${_ledgerConnection?.device.name ?? 'Unknown'}',
                          style: TextStyle(color: theme.buttonText)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.danger,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                        elevation: 3.0,
                      ),
                      onPressed: _disconnectDevice,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
