import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/ledger/ledger_connector.dart';
import 'package:bearby/ledger/ledger_view_controller.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/router.dart';

class LedgerConnectPage extends StatefulWidget {
  const LedgerConnectPage({super.key});

  @override
  State<LedgerConnectPage> createState() => _LedgerConnectPageState();
}

class _LedgerConnectPageState extends State<LedgerConnectPage>
    with StatusBarMixin {
  NetworkConfigInfo? _chain;
  late final AppState _appState;

  @override
  void initState() {
    super.initState();

    _appState = context.read<AppState>();
    _appState.ledgerViewController.addListener(_handleControllerEvents);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appState.ledgerViewController.scan();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final chain = args?['chain'] as NetworkConfigInfo?;

    if (chain == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement(AppRoutes.netSetup);
      });
    } else if (_chain == null) {
      setState(() {
        _chain = chain;
      });
    }
  }

  @override
  void dispose() {
    _appState.ledgerViewController.removeListener(_handleControllerEvents);
    super.dispose();
  }

  void _handleControllerEvents() {
    if (_appState.ledgerViewController.status ==
        LedgerStatus.connectionFailed) {
      final device = _appState.ledgerViewController.connectingDevice;
      final error =
          _appState.ledgerViewController.errorDetails ?? 'Unknown error';
      final localizations = AppLocalizations.of(context)!;

      debugPrint("[LEDGER CONNECT]: $error");

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
        title: Text(title,
            style: theme.titleMedium.copyWith(color: theme.textPrimary)),
        content: Text(content,
            style: theme.bodyText2.copyWith(color: theme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel,
                style: theme.button.copyWith(color: theme.primaryPurple)),
          ),
          if (showSettingsButton)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text(
                localizations.ledgerConnectPageGoToSettings,
                style: theme.button.copyWith(color: theme.primaryPurple),
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
      context.push(AppRoutes.addLedgerAccount, extra: {
        'chain': _chain,
        'ledger': device,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
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
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 0,
            systemOverlayStyle: getSystemUiOverlayStyle(context),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: adaptivePadding),
                      child: CustomAppBar(
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
