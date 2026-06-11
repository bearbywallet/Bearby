import 'package:bearby/components/app_icon.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:bearby/components/btc_account_card.dart';
import 'package:bearby/components/counter.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/config/argon.dart';
import 'package:bearby/config/bip_purposes.dart';
import 'package:bearby/config/cipher.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/utils/utils.dart';
import 'package:bearby/ledger/common.dart';
import 'package:bearby/ledger/ledger_connector.dart';
import 'package:bearby/ledger/ledger_view_controller.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/api/ledger.dart';
import 'package:bearby/src/rust/api/provider.dart';
import 'package:bearby/src/rust/models/btc_chain.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/src/rust/models/settings.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/router.dart';

class AddLedgerAccountPage extends StatefulWidget {
  const AddLedgerAccountPage({super.key});

  @override
  State<AddLedgerAccountPage> createState() => _AddLedgerAccountPageState();
}

class _AddLedgerAccountPageState extends State<AddLedgerAccountPage>
    with StatusBarMixin {
  final _walletNameController = TextEditingController();
  final _btnController = RoundedLoadingButtonController();
  final _createBtnController = RoundedLoadingButtonController();

  int _ledgerIndex = 0;
  bool _loading = false;
  String _errorMessage = '';
  bool _createWallet = true;
  NetworkConfigInfo? _network;
  Map<int, LedgerAccount> _accounts = {};
  Map<int, Map<int, AddressChainInfo>> _btcChains = {};
  bool _initialized = false;
  late final LedgerViewController _ledger;

  bool get _isBtcFlow => _network?.slip44 == kBitcoinlip44;

  bool _indexExists(AppState appState) {
    return _accounts.keys.any(
        (i) => appState.accounts.any((a) => a.index.toInt() == i));
  }

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _ledger = appState.ledgerViewController;

    if (!_ledger.isScanning &&
        !_ledger.isConnecting &&
        _ledger.connectedTransport == null) {
      _ledger
          .scanAndAutoConnect(timeout: const Duration(seconds: 60))
          .then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final appState = context.read<AppState>();
    final discoveredDevice = _ledger.discoveredDevices.firstOrNull;
    final productName = _ledger.connectedTransport?.deviceModel?.productName ??
        discoveredDevice?.deviceModelProducName ??
        discoveredDevice?.name ??
        discoveredDevice?.deviceModelId ??
        "Ledger";

    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (args == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      _initialized = true;
      return;
    }

    final network = args['chain'] as NetworkConfigInfo?;
    final createWallet = args['createWallet'] as bool?;

    if (network == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      _initialized = true;
      return;
    }

    _network = network;
    _createWallet = createWallet ?? true;
    _walletNameController.text =
        _createWallet ? productName : appState.wallet?.walletName ?? "";

    if (!_createWallet) {
      _ledgerIndex = appState.accounts.length;
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    _btnController.dispose();
    _createBtnController.dispose();
    super.dispose();
  }

  Future<void> _onDeviceOpen(DiscoveredDevice device) async {
    await _ledger.open(device);
    if (mounted) setState(() {});
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
      final model = _ledger.connectedTransport?.deviceModel;

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
        cipherOrders:
            CipherDefaults.getCipherOrders(CipherDefaults.defaultCipherIndex),
        argonParams: Argon2DefaultParams.owaspDefault(),
        currencyConvert: detectDeviceCurrency(),
        ipfsNode: "dweb.link",
        ensEnabled: true,
        tokensListFetcher: true,
        nodeRankingEnabled: true,
        maxConnections: 5,
        requestTimeoutSecs: 30,
        ratesApiOptions: 1,
      );
      List<FTokenInfo> ftokens = [];

      if (_createWallet) {
        if (_accounts.isEmpty) {
          throw Exception(l10n.addLedgerAccountPageNoAccountsSelectedError);
        }

        final pubKeys = _accounts.entries
            .map((e) => (e.key, e.value.publicKey ?? ''))
            .toList();
        final accountNames = _accounts.entries
            .map((e) =>
                "${model?.productName ?? 'ledger'} ${e.key + 1}")
            .toList();
        final isZilliqaApp = _ledger.isZilliqaApp;

        await addLedgerWallet(
          params: LedgerParamsInput(
            pubKeys: pubKeys,
            walletIndex: BigInt.from(appState.wallets.length),
            walletName: _walletNameController.text,
            ledgerId: model?.id ?? "",
            accountNames: accountNames,
            biometricType: "none",
            chainHash: chainHash,
            zilliqaLegacy: isZilliqaApp,
            btcChains: _isBtcFlow
                ? _btcChains
                : <int, Map<int, AddressChainInfo>>{},
          ),
          walletSettings: settings,
          ftokens: ftokens,
        );

        await appState.syncData();
        int currentWalletIndex = appState.wallets.length - 1;
        await appState.syncData();
        appState.setSelectedWallet(currentWalletIndex);
        await appState.startTrackHistoryWorker();
        _createBtnController.success();
        setState(() {
          _loading = false;
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.go(AppRoutes.home);
          }
        });
      } else {
        final walletIndex = appState.selectedWallet;
        final wallet = appState.wallet;

        if (wallet == null) {
          throw Exception(l10n.addLedgerAccountPageNoWalletSelectedError);
        }

        if (_accounts.isEmpty) {
          throw Exception(l10n.addLedgerAccountPageNoAccountsSelectedError);
        }
        if (_indexExists(appState)) {
          throw Exception(l10n.addAccountPageIndexExists(_ledgerIndex));
        }

        for (final entry in _accounts.entries) {
          await addLedgerAccount(
            walletIndex: BigInt.from(walletIndex),
            ledgerIndex: entry.key,
            name: "ledger ${entry.key + 1}",
            keyOrAddr: _isBtcFlow ? null : entry.value.publicKey,
            zilliqaLegacy: _ledger.isZilliqaApp,
            btcChain: _isBtcFlow ? _btcChains[entry.key] : null,
          );
        }

        await appState.syncData();
        _createBtnController.success();

        setState(() {
          _loading = false;
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.go(AppRoutes.home);
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

  Widget _buildWalletInfoCard(AppState appState, AppLocalizations l10n) {
    final theme = appState.currentTheme;

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
          if (_createWallet) ...[
            SmartInput(
              controller: _walletNameController,
              hint: l10n.walletPageWalletNameHint,
              rightIcon: AppIcon.edit,
              disabled: _loading,
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.secondaryPurple),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addLedgerAccountPageLedgerIndex,
                  style: theme.bodyLarge.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Counter(
                  initialValue: _ledgerIndex,
                  minValue: 0,
                  maxValue: 2147483647,
                  disabled: _loading,
                  iconColor: theme.primaryPurple,
                  numberStyle: theme.bodyLarge.copyWith(
                    color: theme.textPrimary,
                  ),
                  onChanged: !_loading
                      ? (value) {
                          if (value == _ledgerIndex) return;
                          setState(() {
                            _ledgerIndex = value;
                            _errorMessage = '';
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _ledger,
            builder: (context, _) {
              final isConnected = _ledger.connectedTransport != null;
              return RoundedLoadingButton(
                color: theme.primaryPurple,
                valueColor: theme.buttonText,
                controller: _btnController,
                onPressed: isConnected
                    ? () async {
                        if (!_createWallet && _indexExists(appState)) {
                          setState(() {
                            _errorMessage =
                                l10n.addAccountPageIndexExists(_ledgerIndex);
                          });
                          return;
                        }

                        setState(() {
                          _errorMessage = '';
                        });

                        _btnController.start();

                        try {
                          final bipPurpose =
                              _isBtcFlow ? kBip86Purpose : kBip44Purpose;
                          final accounts = await _ledger.getAccounts(
                            device: _ledger.discoveredDevices.first,
                            slip44: _network!.slip44,
                            indices: [_ledgerIndex],
                            chainId: _network!.chainId.toInt(),
                            bipPurpose: bipPurpose,
                          );

                          if (accounts.isEmpty) {
                            throw Exception(
                                l10n.addLedgerAccountPageNoAccountsSelectedError);
                          }

                          final account = accounts.first;

                          Map<int, AddressChainInfo>? btcChain;
                          if (_isBtcFlow) {
                            final btcApp = _ledger.btcApp;
                            if (btcApp == null) {
                              throw Exception(
                                  'Ledger transport not connected');
                            }
                            final xpubs = await btcApp.getAccountXpubs(
                                accountIndex: account.index);
                            btcChain = await scanBtcAccountHistory(
                              xpubs: xpubs,
                              ledgerIndex: account.index,
                              chainHash: _network!.chainHash,
                            );
                          }

                          setState(() {
                            _accounts[account.index] = account;
                            if (btcChain != null) {
                              _btcChains[account.index] = btcChain;
                            }
                          });
                          _btnController.success();
                        } catch (e) {
                          _btnController.error();
                          setState(() {
                            _errorMessage = e.toString();
                          });
                        } finally {
                          _btnController.reset();
                        }
                      }
                    : null,
                child: Text(
                  l10n.addLedgerAccountPageGetAccountsButton,
                  style: theme.titleSmall.copyWith(
                    color: theme.buttonText,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAccountCard(AppTheme theme, LedgerAccount account) {
    if (_isBtcFlow) {
      final btcChain = _btcChains[account.index];
      if (btcChain == null) return const SizedBox();

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
        child: BtcAccountCard(
          network: _network!,
          chains: btcChain,
        ),
      );
    }

    final addr = account.address;
    final shortAddress =
        "${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}";
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
      child: Row(
        children: [
          AppIconView(
            icon: AppIcon.ledger,
            size: 20,
            color: theme.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Account ${account.index + 1}",
                  style: theme.bodyLarge.copyWith(color: theme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  shortAddress,
                  style:
                      theme.bodyText2.copyWith(color: theme.textSecondary),
                ),
              ],
            ),
          ),
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
          AppIconView(
            icon: AppIcon.warning,
            size: 24,
            color: theme.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: theme.labelMedium.copyWith(
                color: theme.danger,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: adaptivePadding),
                      child: CustomAppBar(
                        onBackPressed: () => context.pop(),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _ledger.scan,
                        color: theme.primaryPurple,
                        backgroundColor: theme.cardBackground,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.all(adaptivePadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LedgerConnector(
                                  controller: _ledger,
                                  onOpen: _onDeviceOpen,
                                ),
                                if (_errorMessage.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _buildErrorMessage(theme),
                                ],
                                const SizedBox(height: 16),
                                _buildWalletInfoCard(appState, l10n),
                                ..._accounts.entries.map((entry) => Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: _buildSingleAccountCard(theme, entry.value),
                                )),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_accounts.isNotEmpty)
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
                        successIcon: AppIcon.ok,
                        child: Text(
                          _createWallet
                              ? l10n.addLedgerAccountPageCreateButton
                              : l10n.addLedgerAccountPageAddButton,
                          style: theme.titleSmall.copyWith(
                            color: theme.buttonText,
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
