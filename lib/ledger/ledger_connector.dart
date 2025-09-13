import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/ledger_device_card.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';
import 'ledger_view_controller.dart';

class LedgerConnector extends StatelessWidget {
  final LedgerViewController controller;
  final bool disabled;
  final Function(DiscoveredDevice device)? onOpen;

  const LedgerConnector({
    super.key,
    required this.controller,
    this.onOpen,
    this.disabled = false,
  });

  String _getStatusText(BuildContext context, LedgerStatus status) {
    final localizations = AppLocalizations.of(context)!;
    switch (status) {
      case LedgerStatus.initializing:
        return localizations.ledgerConnectPageInitializing;
      case LedgerStatus.scanning:
        return localizations.ledgerConnectPageScanningStatus;
      case LedgerStatus.foundDevices:
        return localizations.ledgerConnectPageFoundDevicesStatus(
            controller.discoveredDevices.length);
      case LedgerStatus.scanFinishedNoDevices:
        return localizations.ledgerConnectPageScanFinishedNoDevices;
      case LedgerStatus.scanFinishedWithDevices:
        return localizations.ledgerConnectPageScanFinishedWithDevices(
            controller.discoveredDevices.length);
      case LedgerStatus.scanError:
        return localizations.ledgerConnectPageScanErrorStatus(
            controller.errorDetails ?? 'Unknown error');
      case LedgerStatus.connecting:
        final device = controller.connectingDevice;
        return localizations.ledgerConnectPageConnectingStatus(
          device?.deviceModelProducName ??
              device?.name ??
              device?.deviceId.toString() ??
              'device',
          device?.connectionType.name.toUpperCase() ?? '',
        );
      case LedgerStatus.connectionSuccess:
        final device = controller.connectedTransport?.deviceModel;
        return localizations.ledgerConnectPageConnectionSuccessStatus(
            device?.productName ?? 'Ledger');
      case LedgerStatus.connectionFailed:
        return localizations.ledgerConnectPageConnectionFailedErrorStatus(
            controller.errorDetails ?? 'Unknown error');
      case LedgerStatus.disconnected:
        return localizations.ledgerConnectPageDisconnectedStatus('Ledger');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 20);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final isBusy = controller.isScanning || controller.isConnecting;
        final isConnected = controller.connectedTransport != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: adaptivePadding, vertical: 16),
              child: Column(
                children: [
                  Text(
                    _getStatusText(context, controller.status),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: theme.textSecondary, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: isBusy ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      height: 4,
                      child: isBusy
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
              child: _buildDeviceList(context),
            ),
            if (isConnected)
              Padding(
                padding: EdgeInsets.all(adaptivePadding),
                child: ElevatedButton.icon(
                  icon: SvgPicture.asset('assets/icons/disconnect.svg',
                      width: 20,
                      height: 20,
                      colorFilter:
                          ColorFilter.mode(theme.buttonText, BlendMode.srcIn)),
                  label: Text(
                    AppLocalizations.of(context)!
                        .ledgerConnectPageDisconnectButton(
                      controller.connectedTransport?.deviceModel?.productName ??
                          'Ledger',
                    ),
                    style: TextStyle(color: theme.buttonText),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.danger,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0)),
                  ),
                  onPressed: controller.disconnect,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    if (controller.discoveredDevices.isEmpty && !controller.isScanning) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  AppLocalizations.of(context)!.ledgerConnectPageNoDevicesFound,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: theme.textSecondary, fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
          horizontal: AdaptiveSize.getAdaptivePadding(context, 20) - 4),
      itemCount: controller.discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = controller.discoveredDevices.elementAt(index);
        final isCurrentlyConnecting = controller.isConnecting &&
            controller.connectingDevice?.productId == device.productId;
        final isCurrentlyConnected = controller.connectedTransport != null &&
            controller.connectedTransport?.deviceModel?.id == device.model?.id;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: LedgerCard(
            key: ValueKey(device.productId),
            device: device,
            disabled: disabled,
            isConnecting: isCurrentlyConnecting,
            isConnected: isCurrentlyConnected,
            onTap: () => onOpen?.call(device),
          ),
        );
      },
    );
  }
}
