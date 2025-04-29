import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/counter.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/enable_card.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/ledger/ethereum/ethereum_ledger_application.dart';
import 'package:zilpay/ledger/ethereum/models.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/services/biometric_service.dart';
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
  final _walletNameController = TextEditingController();
  final _btnController = RoundedLoadingButtonController();
  int _accountCount = 5;
  bool _loading = false;
  String _errorMessage = '';
  bool _createWallet = true;
  NetworkConfigInfo? _network;
  LedgerDevice? _ledger;
  List<EthLedgerAccount> _accounts = [];
  Map<EthLedgerAccount, bool> _selectedAccounts = {};
  bool _accountsLoaded = false;

  @override
  void initState() {
    super.initState();
    _walletNameController.text = "";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      final network = args['chain'] as NetworkConfigInfo?;
      final ledger = args['ledger'] as LedgerDevice?;
      final createWallet = args['createWallet'] as bool?;
      if (network == null || ledger == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/initial');
        });
      } else {
        setState(() {
          _network = network;
          _ledger = ledger;
          _createWallet = createWallet ?? true;
          _walletNameController.text = "${ledger.name} (${network.name})";
        });
      }
    }
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  Future<void> _onGetAccounts() async {
    final l10n = AppLocalizations.of(context)!;

    if (_walletNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.ledgerConnectDialogEmptyWalletName);
      _btnController.reset();
      return;
    }

    if (_walletNameController.text.length > 24) {
      setState(() => _errorMessage = l10n.ledgerConnectDialogWalletNameTooLong);
      _btnController.reset();
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    _btnController.start();

    try {
      if (_network == null || _ledger == null) {
        throw Exception("Network or Ledger data is missing.");
      }

      final ledgerInterface = LedgerInterface.ble(
        onPermissionRequest: (_) async => true,
      );

      final connection = await ledgerInterface.connect(_ledger!);
      final ethereumApp = EthereumLedgerApp(connection, transformer: null);
      final accounts = await ethereumApp
          .getAccounts(List<int>.generate(_accountCount, (i) => i));

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _selectedAccounts = {for (var account in accounts) account: true};

          _accountsLoaded = true;
          _loading = false;
        });

        _btnController.success();
        Future.delayed(const Duration(seconds: 1),
            () => mounted ? _btnController.reset() : null);
      }
    } on LedgerException catch (e) {
      _handleLedgerError(e);
    } catch (e) {
      setState(() =>
          _errorMessage = "An unexpected error occurred: ${e.toString()}");
      _btnController.error();
      Future.delayed(const Duration(seconds: 2),
          () => mounted ? _btnController.reset() : null);
    } finally {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  void _handleLedgerError(LedgerException e) {
    String displayError = e.toString();
    if (e is ConnectionLostException) {
      displayError = "Connection to Ledger lost. Please reconnect.";
    } else if (e is DeviceNotConnectedException) {
      displayError = "Ledger device is not connected.";
    } else if (e is LedgerDeviceException) {
      displayError = "Ledger Error ${e.errorCode}: ${e.message}";
    }
    setState(() => _errorMessage = displayError);
    _btnController.error();
    Future.delayed(const Duration(seconds: 2),
        () => mounted ? _btnController.reset() : null);
  }

  void _toggleAccount(EthLedgerAccount account, bool value) {
    setState(() {
      _selectedAccounts[account] = value;
    });
  }

  Future<void> _saveSelectedAccounts() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
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
        cipherOrders: Uint8List(0),
        argonParams: WalletArgonParamsInfo(
          iterations: 2,
          memory: 19456,
          threads: 2,
          secret: '',
        ),
        currencyConvert: "BTC",
        ipfsNode: "dweb.link",
        ensEnabled: true,
        gasControlEnabled: true,
        nodeRankingEnabled: true,
        maxConnections: 5,
        requestTimeoutSecs: 30,
        ratesApiOptions: 1,
      );

      List<FTokenInfo> ftokens = [];

      if (_createWallet) {
        EthLedgerAccount? firstAccount;
        _selectedAccounts.forEach((account, isSelected) {
          if (isSelected && firstAccount == null) {
            firstAccount = account;
          }
        });

        if (firstAccount == null) {
          throw Exception("l10n.ledgerConnectDialogNoAccountSelected");
        }

        LedgerParamsInput params = LedgerParamsInput(
          pubKey: firstAccount!.publicKey,
          walletIndex: BigInt.from(appState.wallets.length),
          walletName: _walletNameController.text,
          ledgerId: _ledger!.id,
          accountName:
              '${_walletNameController.text} ${firstAccount!.index > 0 ? firstAccount!.index + 1 : ''}',
          biometricType: AuthMethod.none.name,
          identifiers: [],
          chainHash: chainHash,
        );

        await addLedgerWallet(
          params: params,
          walletSettings: settings,
          ftokens: ftokens,
        );

        int currentWalletIndex = appState.wallets.length - 1;
        bool isFirst = true;

        for (var entry in _selectedAccounts.entries) {
          final account = entry.key;
          final isSelected = entry.value;

          if (isSelected) {
            if (isFirst && account == firstAccount) {
              isFirst = false;
              continue;
            }

            final accountName =
                '${_walletNameController.text} ${account.index > 0 ? account.index + 1 : ''}';

            await addLedgerAccount(
              walletIndex: BigInt.from(currentWalletIndex),
              accountIndex: BigInt.from(account.index),
              name: accountName,
              pubKey: account.publicKey,
              identifiers: [],
              sessionCipher: "",
            );

            isFirst = false;
          }
        }

        await appState.syncData();
        appState.setSelectedWallet(currentWalletIndex);
      } else {
        final walletIndex = appState.selectedWallet;
        final wallet = appState.wallet;

        if (wallet == null) {
          throw Exception("No wallet selected");
        }

        _selectedAccounts.forEach((account, isSelected) async {
          if (isSelected) {
            final accountName =
                '${_walletNameController.text} ${account.index > 0 ? account.index + 1 : ''}';

            await addLedgerAccount(
              walletIndex: BigInt.from(walletIndex),
              accountIndex: BigInt.from(account.index),
              name: accountName,
              pubKey: account.publicKey,
              identifiers: [],
              sessionCipher: "",
            );
          }
        });

        await appState.syncData();
      }

      setState(() {
        _loading = false;
      });

      Navigator.of(context).pushNamed("/");
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _buildDeviceInfoCard(AppTheme theme, AppLocalizations l10n) {
    if (_network == null || _ledger == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryPurple.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLedgerInfoRow(theme),
          const Divider(height: 24),
          _buildNetworkInfoRow(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildLedgerInfoRow(AppTheme theme) {
    return Row(
      children: [
        SvgPicture.asset(
          _ledger!.connectionType == ConnectionType.ble
              ? 'assets/icons/ble.svg'
              : 'assets/icons/usb.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            theme.primaryPurple,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _ledger!.name,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Connection: ${_ledger!.connectionType.name.toUpperCase()}',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        SvgPicture.asset(
          'assets/icons/check.svg',
          width: 18,
          height: 18,
          colorFilter: ColorFilter.mode(
            theme.success,
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkInfoRow(AppTheme theme, AppLocalizations l10n) {
    final isTestnet = _network!.testnet ?? false;
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: AsyncImage(
            url: viewChain(network: _network!, theme: theme.value),
            fit: BoxFit.contain,
            errorWidget: const Icon(Icons.error),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _network!.name,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isTestnet
                          ? theme.warning.withValues(alpha: 0.2)
                          : theme.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isTestnet
                          ? l10n.setupNetworkSettingsPageTestnetLabel
                          : l10n.setupNetworkSettingsPageMainnetLabel,
                      style: TextStyle(
                        color: isTestnet ? theme.warning : theme.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.setupNetworkSettingsPageTokenLabel} ${_network!.chain} (Chain ID: ${_network!.chainId})',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
          Text(
            l10n.ledgerConnectDialogWalletNameHint,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SmartInput(
            controller: _walletNameController,
            hint: l10n.ledgerConnectDialogWalletNameHint,
            fontSize: 14,
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            focusedBorderColor: theme.primaryPurple,
            disabled: _loading,
            onChanged: (_) {
              if (_errorMessage.isNotEmpty) {
                setState(() => _errorMessage = '');
              }
            },
          ),
          const SizedBox(height: 16),
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
                onPressed: (_network == null || _ledger == null || _loading)
                    ? null
                    : _onGetAccounts,
                successIcon: SvgPicture.asset(
                  'assets/icons/ok.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.buttonText,
                    BlendMode.srcIn,
                  ),
                ),
                child: Text(
                  "Get Accounts",
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
    if (!_accountsLoaded || _accounts.isEmpty) return const SizedBox();
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
          }).toList(),
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
      child: Text(
        _errorMessage,
        style: TextStyle(
          color: theme.danger,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      title: "Ledger Account",
                      onBackPressed: () => Navigator.pop(context),
                    ),
                    if (_network == null || _ledger == null)
                      Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                theme.primaryPurple),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.all(adaptivePadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDeviceInfoCard(theme, l10n),
                                const SizedBox(height: 16),
                                _buildWalletInfoCard(theme, l10n),
                                if (_accountsLoaded &&
                                    _accounts.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _buildAccountsCard(theme),
                                ],
                                if (_errorMessage.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _buildErrorMessage(theme),
                                ],
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_accountsLoaded && _accounts.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(adaptivePadding),
                      child: CustomButton(
                        text: _createWallet ? "Create" : "Add",
                        textColor: theme.buttonText,
                        backgroundColor: theme.primaryPurple,
                        onPressed: _saveSelectedAccounts,
                        disabled: _loading,
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
