import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/counter.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/enable_card.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ledger_connector.dart';
import 'package:zilpay/ledger/ledger_view_controller.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/ledger.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/src/rust/models/settings.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/theme/app_theme.dart';

class AddLedgerAccountPage extends StatefulWidget {
  const AddLedgerAccountPage({super.key});

  @override
  State<AddLedgerAccountPage> createState() => _AddLedgerAccountPageState();
}

class _AddLedgerAccountPageState extends State<AddLedgerAccountPage> {
  late final LedgerViewController _ledgerViewController;
  final _walletNameController = TextEditingController();
  final _btnController = RoundedLoadingButtonController();
  final _createBtnController = RoundedLoadingButtonController();

  int _accountCount = 1;
  bool _loading = false;
  String _errorMessage = '';
  bool _createWallet = true;
  bool _zilliqaLegacy = false;
  NetworkConfigInfo? _network;
  List<LedgerAccount> _accounts = [];
  Map<LedgerAccount, bool> _selectedAccounts = {};

  late AuthGuard _authGuard;

  @override
  void initState() {
    super.initState();
    _ledgerViewController = LedgerViewController();
    _authGuard = Provider.of<AuthGuard>(context, listen: false);
    _walletNameController.text = "";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ledgerViewController.scan(clean: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return;
    }

    final network = args['chain'] as NetworkConfigInfo?;
    final ledger = args['ledger'] as DiscoveredDevice?;
    final createWallet = args['createWallet'] as bool?;

    if (network == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return;
    }

    setState(() {
      _network = network;
      if (ledger != null) {
        _ledgerViewController.addDevice(ledger);
        _walletNameController.text =
            "${ledger.name ?? ledger.deviceModelProducName} (${network.name})";
      }
      _createWallet = createWallet ?? true;

      final appState = context.read<AppState>();
      final isLedgerWallet = appState.selectedWallet != -1 &&
          appState.wallets.isNotEmpty &&
          appState.wallets[appState.selectedWallet].walletType
              .contains(WalletType.ledger.name);

      if (isLedgerWallet && !_createWallet) {
        final existingAccounts = appState.wallet?.accounts ?? [];
        _accounts = existingAccounts
            .map((account) => LedgerAccount(
                  index: account.index.toInt(),
                  address: account.addr,
                  publicKey: account.pubKey,
                ))
            .toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        _selectedAccounts = {for (var account in _accounts) account: true};
      }
    });
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    _btnController.dispose();
    _createBtnController.dispose();
    _ledgerViewController.dispose();
    super.dispose();
  }

  void _toggleAccount(LedgerAccount account, bool value) {
    if (_loading) return;
    setState(() {
      _selectedAccounts[account] = value;
    });
  }

  Future<void> _saveSelectedAccounts() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    _createBtnController.start();

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;
      final BigInt? chainHash;

      List<NetworkConfigInfo> chains = await getProviders();
      final matches = chains
          .where((chain) => chain.chainHash == _network!.chainHash)
          .toList();

      if (matches.isEmpty) {
        chainHash = await addProvider(providerConfig: _network!);
      } else {
        chainHash = matches.first.chainHash;
      }

      WalletSettingsInfo settings = WalletSettingsInfo(
        cipherOrders: Uint8List.fromList([]),
        argonParams: WalletArgonParamsInfo(
          iterations: 0,
          memory: 0,
          threads: 0,
          secret: '',
        ),
        currencyConvert: "BTC",
        ipfsNode: "dweb.link",
        ensEnabled: true,
        tokensListFetcher: true,
        nodeRankingEnabled: true,
        maxConnections: 5,
        requestTimeoutSecs: 30,
        ratesApiOptions: 1,
      );
      final isLegacyZilliq = _network?.slip44 == 313 &&
          _selectedAccounts.entries
              .map((entry) => entry.key)
              .every((a) => a.address.startsWith("zil1"));

      List<FTokenInfo> ftokens = [];

      if (_createWallet) {
        final selectedAccounts = _selectedAccounts.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

        if (selectedAccounts.isEmpty) {
          throw Exception(l10n.addLedgerAccountPageNoAccountsSelectedError);
        }

        final pubKeys =
            selectedAccounts.map((a) => (a.index, a.publicKey)).toList();
        final accountNames =
            selectedAccounts.map((a) => "ledger ${a.index + 1}").toList();

        DeviceInfoService device = DeviceInfoService();
        List<String> identifiers = await device.getDeviceIdentifiers();

        final (session, walletAddress) = await addLedgerWallet(
          params: LedgerParamsInput(
            pubKeys: pubKeys,
            walletIndex: BigInt.from(appState.wallets.length),
            walletName: _walletNameController.text,
            ledgerId: "",
            accountNames: accountNames,
            biometricType: AuthMethod.none.name,
            identifiers: identifiers,
            chainHash: chainHash,
            zilliqaLegacy: isLegacyZilliq,
          ),
          walletSettings: settings,
          ftokens: ftokens,
        );

        await appState.syncData();
        int currentWalletIndex = appState.wallets.length - 1;
        await _authGuard.setSession(walletAddress, session);
        await appState.syncData();
        appState.setSelectedWallet(currentWalletIndex);
        await appState.startTrackHistoryWorker();
        _createBtnController.success();
        setState(() {
          _loading = false;
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushNamed("/");
          }
        });
      } else {
        final walletIndex = appState.selectedWallet;
        final wallet = appState.wallet;

        if (wallet == null) {
          throw Exception(l10n.addLedgerAccountPageNoWalletSelectedError);
        }

        final accountsToUpdate = _selectedAccounts.entries
            .where((entry) => entry.value)
            .map((entry) => (
                  entry.key.index,
                  entry.key.publicKey,
                  "ledger ${entry.key.index + 1}"
                ))
            .toList();

        await updateLedgerAccounts(
          walletIndex: BigInt.from(walletIndex),
          accounts: accountsToUpdate,
          zilliqaLegacy: isLegacyZilliq,
        );

        await appState.syncData();
        _createBtnController.success();

        setState(() {
          _loading = false;
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushNamed("/");
          }
        });
      }
    } catch (e) {
      _createBtnController.error();
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _createBtnController.reset();
        }
      });
    }
  }

  Widget _buildWalletInfoCard(AppTheme theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Counter(
                  iconSize: 24,
                  iconColor: theme.textPrimary,
                  animationDuration: const Duration(milliseconds: 300),
                  numberStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                  minValue: 1,
                  initialValue: _accountCount,
                  disabled: _loading,
                  onChanged: !_loading
                      ? (value) {
                          setState(() {
                            _accountCount = value;
                          });
                        }
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              RoundedLoadingButton(
                color: theme.primaryPurple,
                valueColor: theme.buttonText,
                controller: _btnController,
                onPressed: () {},
                child: Text(
                  l10n.addLedgerAccountPageGetAccountsButton,
                  style: TextStyle(
                    color: theme.buttonText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsCard(AppTheme theme) {
    if (_accounts.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._accounts.map((account) {
            final shortAddress =
                "${account.address.substring(0, 6)}...${account.address.substring(account.address.length - 4)}";
            return EnableCard(
              title: "Account ${account.index + 1}",
              name: shortAddress,
              iconWidget: SvgPicture.asset(
                'assets/icons/ledger.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  theme.success,
                  BlendMode.srcIn,
                ),
              ),
              isDefault: false,
              isEnabled: _selectedAccounts[account] ?? false,
              onToggle: (value) => _toggleAccount(account, value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(AppTheme theme) {
    if (_errorMessage.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/warning.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(theme.danger, BlendMode.srcIn),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: theme.danger,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacySwitch(AppTheme theme, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                "assets/icons/scilla.svg",
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  theme.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.settingsPageZilliqaLegacy,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Switch(
            value: _zilliqaLegacy,
            onChanged: _loading
                ? null
                : (value) {
                    setState(() {
                      _zilliqaLegacy = value;
                    });
                  },
            activeThumbColor: theme.primaryPurple,
            activeTrackColor: theme.primaryPurple.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                Column(
                  children: [
                    CustomAppBar(
                      title: l10n.addLedgerAccountPageAppBarTitle,
                      onBackPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(adaptivePadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _ledgerViewController.scan,
                                color: theme.primaryPurple,
                                backgroundColor: theme.cardBackground,
                                child: LedgerConnector(
                                  disabled: _createWallet,
                                  controller: _ledgerViewController,
                                ),
                              ),
                            ),
                            if (_errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildErrorMessage(theme),
                            ],
                            const SizedBox(height: 16),
                            _buildWalletInfoCard(theme, l10n),
                            if (_network?.slip44 == 313) ...[
                              const SizedBox(height: 16),
                              _buildLegacySwitch(theme, l10n),
                            ],
                            if (_accounts.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildAccountsCard(theme),
                            ],
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // if (_accounts.isNotEmpty && !_ledgerViewController.isScanning)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(adaptivePadding),
                    child: RoundedLoadingButton(
                      controller: _createBtnController,
                      color: theme.primaryPurple,
                      valueColor: theme.buttonText,
                      onPressed: _saveSelectedAccounts,
                      successIcon: "assets/icons/ok.svg",
                      child: Text(
                        _createWallet
                            ? l10n.addLedgerAccountPageCreateButton
                            : l10n.addLedgerAccountPageAddButton,
                        style: TextStyle(
                          color: theme.buttonText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
  }
}
