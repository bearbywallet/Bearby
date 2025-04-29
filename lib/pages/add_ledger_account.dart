import 'package:flutter/material.dart';
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
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class AddLedgerAccountPage extends StatefulWidget {
  const AddLedgerAccountPage({
    super.key,
  });

  @override
  State<AddLedgerAccountPage> createState() => _AddLedgerAccountPageState();
}

class _AddLedgerAccountPageState extends State<AddLedgerAccountPage> {
  final _walletNameController = TextEditingController();
  final _btnController = RoundedLoadingButtonController();

  int _accountCount = 5;
  bool _loading = false;
  String _errorMessage = '';
  NetworkConfigInfo? _network;
  LedgerDevice? _ledger;

  List<String> _accounts = [];
  Map<String, bool> _selectedAccounts = {};
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

      if (network == null || ledger == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/initial');
        });
      } else {
        setState(() {
          _network = network;
          _ledger = ledger;
          _walletNameController.text = "${ledger.name} (${_network?.name})";
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
    if (_walletNameController.text.trim().isEmpty) {
      setState(() => _errorMessage =
          AppLocalizations.of(context)!.ledgerConnectDialogEmptyWalletName);
      _btnController.reset();
      return;
    }

    if (_walletNameController.text.length > 24) {
      setState(() => _errorMessage =
          AppLocalizations.of(context)!.ledgerConnectDialogWalletNameTooLong);
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
        onPermissionRequest: (status) async => true,
      );

      final connection = await ledgerInterface.connect(_ledger!);

      final ethereumApp = EthereumLedgerApp(
        connection,
      );

      final indices = List<int>.generate(_accountCount, (i) => i);
      final accounts = await ethereumApp.getAccounts(indices);

      if (accounts.isEmpty) {
        throw Exception("Could not retrieve Ethereum accounts");
      }

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _selectedAccounts = {for (var account in accounts) account: true};
          _accountsLoaded = true;
          _loading = false;
        });

        _btnController.success();

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _btnController.reset();
          }
        });
      }
    } on LedgerException catch (e) {
      print("Ledger Error during operation: $e");
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

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _btnController.reset();
        }
      });
    } catch (e) {
      setState(() =>
          _errorMessage = "An unexpected error occurred: ${e.toString()}");
      _btnController.error();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _btnController.reset();
        }
      });
    } finally {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  void _toggleAccount(String address, bool value) {
    setState(() {
      _selectedAccounts[address] = value;
    });
  }

  void _saveSelectedAccounts() {
    final List<Map<String, dynamic>> selectedAccounts = [];

    _selectedAccounts.forEach((address, isSelected) {
      if (isSelected) {
        final index = _accounts.indexOf(address);
        if (index != -1) {
          selectedAccounts.add({
            'name':
                '${_walletNameController.text} ${index > 0 ? index + 1 : ''}',
            'address': address,
            'index': index,
            'deviceId': _ledger!.id,
            'network': _network!.name,
            'chainId': _network!.chainId,
          });
        }
      }
    });

    Navigator.of(context).pop(selectedAccounts);
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
                      title: "Ledger account",
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
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.cardBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.primaryPurple
                                          .withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            _ledger!.connectionType ==
                                                    ConnectionType.ble
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                      ),
                                      const Divider(height: 24),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: AsyncImage(
                                              url: viewChain(
                                                  network: _network!,
                                                  theme: theme.value),
                                              fit: BoxFit.contain,
                                              errorWidget:
                                                  const Icon(Icons.error),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _network!.name,
                                                        style: TextStyle(
                                                          color:
                                                              theme.textPrimary,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: (_network!
                                                                    .testnet ??
                                                                false)
                                                            ? theme.warning
                                                                .withValues(
                                                                    alpha: 0.2)
                                                            : theme.success
                                                                .withValues(
                                                                    alpha: 0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Text(
                                                        (_network!.testnet ??
                                                                false)
                                                            ? l10n
                                                                .setupNetworkSettingsPageTestnetLabel
                                                            : l10n
                                                                .setupNetworkSettingsPageMainnetLabel,
                                                        style: TextStyle(
                                                          color: (_network!
                                                                      .testnet ??
                                                                  false)
                                                              ? theme.warning
                                                              : theme.success,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
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
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.cardBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.textSecondary
                                          .withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        hint: AppLocalizations.of(context)!
                                            .ledgerConnectDialogWalletNameHint,
                                        fontSize: 14,
                                        height: 45,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        focusedBorderColor: theme.primaryPurple,
                                        disabled: _loading,
                                        onChanged: (value) {
                                          if (_errorMessage.isNotEmpty) {
                                            setState(() => _errorMessage = '');
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Center(
                                            child: Counter(
                                              iconSize: 24,
                                              iconColor: theme.textPrimary,
                                              animationDuration: const Duration(
                                                  milliseconds: 300),
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
                                            onPressed: (_network == null ||
                                                    _ledger == null ||
                                                    _loading)
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
                                ),
                                if (_accountsLoaded &&
                                    _accounts.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.cardBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.textSecondary
                                            .withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Select accounts to add",
                                          style: TextStyle(
                                            color: theme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ...List.generate(_accounts.length,
                                            (index) {
                                          final address = _accounts[index];
                                          final shortAddress =
                                              "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
                                          return EnableCard(
                                            title: "Account ${index + 1}",
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
                                            isEnabled:
                                                _selectedAccounts[address] ??
                                                    false,
                                            onToggle: (value) =>
                                                _toggleAccount(address, value),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_errorMessage.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.danger.withValues(alpha: 0.1),
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
                                  ),
                                ],
                                const SizedBox(
                                    height:
                                        80), // Add extra space at the bottom
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
                        text: "Save Selected Accounts",
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
