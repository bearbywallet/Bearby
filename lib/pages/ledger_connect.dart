import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/ledger_device_card.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/ledger/transport/ble_transport.dart';
import 'package:zilpay/ledger/transport/hid_transport.dart';
import 'package:zilpay/ledger/transport/transport.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';

class LedgerConnectPage extends StatefulWidget {
  const LedgerConnectPage({super.key});
  @override
  State<LedgerConnectPage> createState() => _LedgerConnectPageState();
}

class _LedgerConnectPageState extends State<LedgerConnectPage> {
  final Set<DiscoveredDevice> _discoveredDevices = {};
  final List<StreamSubscription> _scanSubscriptions = [];
  Timer? _hidPollingTimer;
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _statusText;
  Transport? _connectedTransport;
  DiscoveredDevice? _connectingDevice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _statusText = AppLocalizations.of(context)!.ledgerConnectPageInitializing;
      _startScanning();
    });
  }

  @override
  void dispose() {
    _stopScan();
    _connectedTransport?.close();
    super.dispose();
  }

  Future<void> _startScanning() async {
    if (_isScanning || _isConnecting) return;
    final localizations = AppLocalizations.of(context)!;

    if (_connectedTransport != null) {
      await _disconnectDevice();
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        _showErrorDialog(
          localizations.ledgerConnectPagePermissionDeniedTitle,
          localizations.ledgerConnectPagePermissionDeniedContent,
          showSettingsButton: true,
        );
        return;
      }
    }

    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
      _statusText = localizations.ledgerConnectPageScanningStatus;
    });

    final bleSub = BleTransport.listen().listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _discoveredDevices
              .add(DiscoveredDevice.fromBleDevice(event.descriptor.rawDevice));
          _updateStatusText();
        });
      },
      onError: (e) => _handleScanError(e, "BLE"),
    );
    _scanSubscriptions.add(bleSub);

    if (Platform.isAndroid) {
      _startHidPolling();
    }
  }

  void _startHidPolling() {
    _hidPollingTimer?.cancel();
    _hidPollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!_isScanning || !mounted) {
        _hidPollingTimer?.cancel();
        return;
      }
      try {
        final discoveredHid = await HidTransport.list();

        setState(() {
          _discoveredDevices.addAll(discoveredHid);
          _updateStatusText();
        });
      } on PlatformException catch (e) {
        _handleScanError(e, "USB Polling ${e.code}");
      } catch (e) {
        _handleScanError(e, "USB Polling");
      } finally {
        _hidPollingTimer?.cancel();
      }
    });
  }

  void _stopScan() {
    _hidPollingTimer?.cancel();
    _hidPollingTimer = null;

    for (var sub in _scanSubscriptions) {
      sub.cancel();
    }
    _scanSubscriptions.clear();

    if (mounted && _isScanning) {
      setState(() {
        _isScanning = false;
        _updateStatusText();
      });
    }
  }

  void _updateStatusText() {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      if (_isScanning) {
        _statusText = localizations
            .ledgerConnectPageFoundDevicesStatus(_discoveredDevices.length);
      } else {
        _statusText = _discoveredDevices.isEmpty
            ? localizations.ledgerConnectPageScanFinishedNoDevices
            : localizations.ledgerConnectPageScanFinishedWithDevices(
                _discoveredDevices.length);
      }
    });
  }

  void _handleScanError(dynamic error, String type) {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    debugPrint('[$type Scan] Scan Error: $error');
    setState(() {
      _isScanning = false;
      _statusText =
          localizations.ledgerConnectPageScanErrorStatus(error.toString());
    });
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    if (_isConnecting) return;
    final localizations = AppLocalizations.of(context)!;

    if (_isScanning) {
      _stopScan();
    }

    setState(() {
      _isConnecting = true;
      _connectingDevice = device;
      _statusText = localizations.ledgerConnectPageConnectingStatus(
        device.deviceModelProducName ??
            device.name ??
            device.deviceId.toString(),
        device.connectionType.name.toUpperCase(),
      );
    });

    try {
      Transport transport;
      if (device.connectionType == ConnectionType.ble) {
        transport = await BleTransport.open(device);
      } else {
        transport = await HidTransport.open(device);
      }

      if (!mounted) {
        await transport.close();
        return;
      }

      _connectedTransport = transport;

      setState(() {
        _statusText = localizations.ledgerConnectPageConnectionSuccessStatus(
            device.deviceModelProducName ?? device.name ?? "");
      });

      Navigator.of(context).pushNamed(
        '/net_setup',
        arguments: {'transport': transport, 'device': device},
      );
    } catch (e) {
      _showErrorDialog(
        localizations.ledgerConnectPageConnectionFailedTitle,
        localizations.ledgerConnectPageConnectionFailedGenericContent(
            device.deviceModelProducName ?? device.name ?? "", e.toString()),
      );
      if (mounted) {
        setState(() {
          _statusText = localizations
              .ledgerConnectPageConnectionFailedErrorStatus(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingDevice = null;
          if (_connectedTransport == null) {
            _updateStatusText();
          }
        });
      }
    }
  }

  Future<void> _disconnectDevice() async {
    if (_connectedTransport == null) return;
    final localizations = AppLocalizations.of(context)!;
    final deviceName =
        _connectedTransport!.deviceModel?.productName ?? 'Ledger';

    try {
      await _connectedTransport!.close();
    } catch (e) {
      debugPrint("Error disconnecting: $e");
    } finally {
      if (mounted) {
        setState(() {
          _connectedTransport = null;
          _statusText =
              localizations.ledgerConnectPageDisconnectedStatus(deviceName);
        });
      }
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

  void _showErrorDialog(String title, String content,
      {bool showSettingsButton = false}) {
    if (!mounted) return;
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final localizations = AppLocalizations.of(context)!;

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
            child: Text(localizations.cancel,
                style: TextStyle(color: theme.primaryPurple)),
          ),
          if (showSettingsButton)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text(
                localizations.ledgerConnectPageGoToSettings,
                style: TextStyle(color: theme.primaryPurple),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 20);
    final theme = Provider.of<AppState>(context).currentTheme;
    final localizations = AppLocalizations.of(context)!;
    final isConnected = _connectedTransport != null;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                CustomAppBar(
                  title: localizations.ledgerConnectPageTitle,
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
                    children: [
                      Text(
                        _statusText ??
                            localizations.ledgerConnectPageInitializing,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 15,
                            height: 1.4),
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
                    child: _discoveredDevices.isEmpty && !_isScanning
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
                                      localizations
                                          .ledgerConnectPageNoDevicesFound,
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
                              final isCurrentlyConnecting = _isConnecting &&
                                  _connectingDevice?.productId ==
                                      device.productId;

                              final isCurrentlyConnected = isConnected &&
                                  _connectedTransport?.deviceModel?.id ==
                                      device.model?.id;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 4),
                                child: LedgerCard(
                                  key: ValueKey(device.productId),
                                  device: device,
                                  isConnecting: isCurrentlyConnecting,
                                  isConnected: isCurrentlyConnected,
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
                        colorFilter: ColorFilter.mode(
                          theme.buttonText,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(
                        localizations.ledgerConnectPageDisconnectButton(
                          _connectedTransport?.deviceModel?.productName ??
                              'Ledger',
                        ),
                        style: TextStyle(color: theme.buttonText),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.danger,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
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
