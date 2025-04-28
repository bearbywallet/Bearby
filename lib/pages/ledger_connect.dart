import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:async/async.dart';

class LedgerModel {
  final String deviceId;
  final String deviceName;
  final String connectionType;
  final LedgerConnection ledgerConnection;

  LedgerModel({
    required this.deviceId,
    required this.deviceName,
    required this.connectionType,
    required this.ledgerConnection,
  });

  factory LedgerModel.fromDevice({
    required LedgerDevice device,
    required LedgerConnection connection,
  }) {
    return LedgerModel(
      deviceId: device.id,
      deviceName: device.name,
      connectionType: device.connectionType.name,
      ledgerConnection: connection,
    );
  }
}

class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final Duration duration;
  final double pressedScale;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 100),
    this.pressedScale = 0.96,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (!widget.enabled) return;
    setState(() {
      _isPressed = pressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.enabled && _isPressed ? widget.pressedScale : 1.0;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        if (widget.enabled && widget.onTap != null) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && widget.onTap != null) {
              widget.onTap!();
            }
          });
        }
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

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
      _checkAuthMethods();
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

  Future<void> _checkAuthMethods() async {
    debugPrint('Checking auth methods...');
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
      _ledgerUsb = LedgerInterface.usb();

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

    if (status == AvailabilityState.poweredOff ||
        status == AvailabilityState.unauthorized ||
        status == AvailabilityState.unsupported) {
      setState(() {
        _statusText = 'Bluetooth Error: $status';
      });
      _showErrorDialog('Bluetooth Issue',
          'Bluetooth seems to be $status. Please check your Bluetooth settings and app permissions.');
      return false;
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    bool allGranted = statuses.values.every((s) => s.isGranted);

    if (!allGranted) {
      if (!mounted) return false;
      setState(() {
        _statusText = 'Permissions denied. Cannot scan via BLE.';
      });
      _showErrorDialog('Permission Denied',
          'Bluetooth permissions are required to scan for Ledger devices via BLE. Please grant permissions in settings.');
    }

    return allGranted;
  }

  Future<void> _startScanning() async {
    if (_isScanning ||
        _isConnecting ||
        _ledgerBle == null ||
        _ledgerUsb == null) {
      debugPrint(
          'Scan aborted: Already scanning, connecting, or Ledger not initialized.');
      return;
    }

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
      if (bleStatus != AvailabilityState.poweredOn) {
        final granted = await _handlePermissionRequest(bleStatus);
        if (!granted) {
          if (!mounted) return;
          setState(() {
            _isScanning = false;
          });
          return;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final bleStream = _ledgerBle!.scan();
      final usbStream = _ledgerUsb!.scan();
      final combinedStream = StreamGroup.merge([bleStream, usbStream]);

      debugPrint("[Scan] Starting combined BLE and USB scan.");
      _scanSubscription = combinedStream.listen(
        (device) {
          if (!mounted) return;
          debugPrint(
              "[Scan] Discovered device: ${device.name} (${device.id}) via ${device.connectionType.name}");
          setState(() {
            bool added = _discoveredDevices.add(device);
            if (added) {
              _statusText = 'Found ${_discoveredDevices.length} device(s)...';
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          debugPrint('[Scan] Scan Error: $error');
          String errorMessage = 'An error occurred during scanning.';
          if (error is PermissionException) {
            errorMessage = 'Permission error during scan: ${error}';
          } else if (error is LedgerException) {
            errorMessage = 'Ledger Error during scan: ${error}';
          } else {
            errorMessage = 'Scan Error: ${error.toString()}';
          }

          setState(() {
            _isScanning = false;
            _statusText = errorMessage;
          });
          _showErrorDialog('Scan Error', errorMessage);
        },
        onDone: () {
          if (!mounted) return;
          debugPrint("[Scan] Scan stream done.");
          setState(() {
            _isScanning = false;
            if (!_isConnecting && _ledgerConnection == null) {
              _statusText = _discoveredDevices.isEmpty
                  ? 'Scan finished. No devices found.'
                  : 'Scan finished. Found ${_discoveredDevices.length} device(s). Select one to connect.';
            }
          });
        },
        cancelOnError: true,
      );

      Future.delayed(const Duration(seconds: 16), () {
        if (mounted && _isScanning) {
          debugPrint("[Scan] Stopping scan due to timeout.");
          _stopScan();
        }
      });
    } catch (e, s) {
      if (!mounted) return;
      debugPrint('[Scan] Error starting scan: $e\n$s');
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

  Future<void> _connectToDevice(LedgerDevice device) async {
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
    const connectionTimeout = Duration(seconds: 25);

    try {
      debugPrint(
          '[Connect] Calling ${device.connectionType.name}.connect() with ${connectionTimeout.inSeconds}s timeout...');

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

      debugPrint('[Connect] Navigating to /net_setup with device info');

      final ledgerModel = LedgerModel.fromDevice(
        device: device,
        connection: _ledgerConnection!,
      );

      Navigator.of(context).pushNamed(
        '/net_setup',
        arguments: {
          'ledger': ledgerModel,
        },
      );

      debugPrint('[Connect] Setting up disconnect listener for ${device.id}');
      _listenForDisconnection(device.id);
      debugPrint('[Connect] Disconnect listener setup initiated.');
    } on LedgerException catch (e) {
      debugPrint('[Connect] LedgerException caught: ${e}');
      if (!mounted) return;
      setState(() {
        _statusText = 'Connection Failed: ${e}';
        _ledgerConnection = null;
      });
      _showErrorDialog('Connection Failed', 'Ledger Error: ${e}');
    } on TimeoutException catch (e) {
      debugPrint('[Connect] TimeoutException caught: ${e.message}');
      if (!mounted) return;
      setState(() {
        _statusText = 'Connection Failed: Timed out';
        _ledgerConnection = null;
      });
      _showErrorDialog('Connection Failed',
          'Connection timed out (${connectionTimeout.inSeconds}s). Please ensure the device is unlocked, the correct app is open (if necessary), and try again.');
    } catch (e, s) {
      debugPrint('[Connect] Generic Exception caught: $e\n$s');
      if (!mounted) return;

      String errorString = e.toString();
      bool isStreamListenedError = errorString
          .contains('Bad state: Stream has already been listened to.');

      String failureMsg = 'Connection Failed: $e';
      String dialogContent = 'Could not connect to ${device.name}.\nError: $e';
      String dialogTitle = 'Connection Failed';
      bool showErrorDialog = true;

      if (isStreamListenedError) {
        debugPrint(
            '[Connect] Skipping error dialog for stream listener error.');
        showErrorDialog = false;
        if (_ledgerConnection != null) {
          failureMsg =
              'Connected to ${_ledgerConnection!.device.name} (listener error)';
        } else {
          failureMsg = 'Connection Failed: $e';
          showErrorDialog = true;
        }
      } else {
        _ledgerConnection = null;
      }

      if (mounted) {
        setState(() {
          _statusText = failureMsg;
        });
        if (showErrorDialog) {
          _showErrorDialog(dialogTitle, dialogContent);
        }
      }
    } finally {
      debugPrint('[Connect] Entering finally block.');
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingDevice = null;
          debugPrint('[Connect] Resetting connecting state in finally block.');
        });
      }
      debugPrint('[Connect] Exiting finally block.');
    }
    debugPrint('[Connect] Exiting _connectToDevice function.');
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

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: theme.textPrimary)),
          content: Text(content, style: TextStyle(color: theme.textSecondary)),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: theme.primaryPurple)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 20);
    final theme = Provider.of<AppState>(context).currentTheme;
    final bool isConnected = _ledgerConnection != null;
    final String pageTitle =
        AppLocalizations.of(context)?.ledgerConnectPageTitle ??
            'Connect Ledger';

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
                          : theme.primaryPurple,
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
                                      'No devices found. Ensure Ledger is powered on, unlocked, and Bluetooth/USB is enabled.\n\nPull down or use refresh icon to scan again.',
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
                              final bool isDisabled =
                                  isCurrentlyConnected || _isConnecting;

                              final cardChild = Card(
                                elevation: 0,
                                margin: EdgeInsets.zero,
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0)),
                                color: theme.cardBackground,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 16),
                                  leading: SvgPicture.asset(
                                    device.connectionType == ConnectionType.ble
                                        ? 'assets/icons/ble.svg'
                                        : 'assets/icons/usb.svg',
                                    width: 24,
                                    height: 24,
                                    colorFilter: ColorFilter.mode(
                                      isCurrentlyConnected
                                          ? theme.success
                                          : theme.primaryPurple,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  title: Text(
                                    device.name.isEmpty
                                        ? '(Unknown Device)'
                                        : device.name,
                                    style: TextStyle(
                                      fontWeight: isCurrentlyConnected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isDisabled &&
                                              !isCurrentlyConnecting &&
                                              !isCurrentlyConnected
                                          ? theme.textSecondary.withAlpha(180)
                                          : theme.textPrimary,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'ID: ${device.id.length > 12 ? '${device.id.substring(0, 6)}...${device.id.substring(device.id.length - 6)}' : device.id}\nType: ${device.connectionType.name.toUpperCase()}',
                                    style: TextStyle(
                                        color: theme.textSecondary,
                                        fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: isCurrentlyConnecting
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      theme.primaryPurple)),
                                        )
                                      : isCurrentlyConnected
                                          ? SvgPicture.asset(
                                              'assets/icons/check.svg',
                                              width: 26,
                                              height: 26,
                                              colorFilter: ColorFilter.mode(
                                                  theme.success,
                                                  BlendMode.srcIn),
                                            )
                                          : SvgPicture.asset(
                                              'assets/icons/chevron_right.svg',
                                              width: 24,
                                              height: 24,
                                              colorFilter: ColorFilter.mode(
                                                  theme.textSecondary,
                                                  BlendMode.srcIn),
                                            ),
                                ),
                              );

                              return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 4),
                                  child: PressableCard(
                                    key: ValueKey(device.id),
                                    enabled: !isDisabled,
                                    onTap: () => _connectToDevice(device),
                                    child: cardChild,
                                  ));
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
