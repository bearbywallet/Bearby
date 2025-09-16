import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/ledger/ledger_connector.dart';
import 'package:zilpay/ledger/ledger_view_controller.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:permission_handler/permission_handler.dart';

class LedgerConnectPage extends StatefulWidget {
  const LedgerConnectPage({super.key});

  @override
  State<LedgerConnectPage> createState() => _LedgerConnectPageState();
}

class _LedgerConnectPageState extends State<LedgerConnectPage> {
  @override
  void initState() {
    super.initState();

    final appState = context.read<AppState>();
    appState.ledgerViewController.addListener(_handleControllerEvents);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      appState.ledgerViewController.scan();
    });
  }

  @override
  void dispose() {
    final appState = context.read<AppState>();
    appState.ledgerViewController.removeListener(_handleControllerEvents);
    appState.ledgerViewController.dispose();
    super.dispose();
  }

  void _handleControllerEvents() {
    final appState = context.read<AppState>();

    if (appState.ledgerViewController.status == LedgerStatus.connectionFailed) {
      final device = appState.ledgerViewController.connectingDevice;
      final error =
          appState.ledgerViewController.errorDetails ?? 'Unknown error';
      final localizations = AppLocalizations.of(context)!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showErrorDialog(
            localizations.ledgerConnectPageConnectionFailedTitle,
            localizations.ledgerConnectPageConnectionFailedGenericContent(
              device?.deviceModelProducName ?? device?.name ?? 'Device',
              error,
            ),
          );
        }
      });
    }
  }

  void _showErrorDialog(String title, String content,
      {bool showSettingsButton = false}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
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
            onPressed: () => Navigator.of(context).pop(),
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

  Future<void> _onDeviceOpen(DiscoveredDevice device) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final transport = await appState.ledgerViewController.open(device);

    if (transport != null && mounted) {
      Navigator.of(context).pushNamed(
        '/net_setup',
        arguments: {
          "ledger": device,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final localizations = AppLocalizations.of(context)!;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 20);

    return AnimatedBuilder(
      animation: appState.ledgerViewController,
      builder: (context, child) {
        final isBusy = appState.ledgerViewController.isScanning ||
            appState.ledgerViewController.isConnecting;

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
                          isBusy
                              ? theme.textSecondary.withAlpha(128)
                              : theme.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                      onActionPressed:
                          isBusy ? null : appState.ledgerViewController.scan,
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: appState.ledgerViewController.scan,
                        color: theme.primaryPurple,
                        backgroundColor: theme.cardBackground,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: adaptivePadding, vertical: 16),
                          child: LedgerConnector(
                            controller: appState.ledgerViewController,
                            onOpen: _onDeviceOpen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
