import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/counter.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
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

  int _index = 0;
  bool _loading = false;
  String _errorMessage = '';
  NetworkConfigInfo? _network;
  LedgerDevice? _ledger;

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

  Future<void> _onConnect() async {
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

      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        _btnController.success();
        // TODO: Implement actual account adding logic here
        // This might involve:
        // 1. Sending another operation to get the public key/address for the selected index.
        // 2. Saving the account details (name, address, index, deviceId, network) locally.

        // Navigator.of(context).pushReplacementNamed('/');
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
      print("Generic Error during connection/operation: $e");
      setState(() =>
          _errorMessage = "An unexpected error occurred: ${e.toString()}");
      _btnController.error();

      // Reset button after error animation
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
            child: Column(
              children: [
                CustomAppBar(
                  title: "Ledger account",
                  onBackPressed: () => Navigator.pop(context),
                ),
                if (_network == null || _ledger == null)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primaryPurple),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          errorWidget: const Icon(Icons.error),
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
                                                      color: theme.textPrimary,
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
                                                    color: (_network!.testnet ??
                                                            false)
                                                        ? theme.warning
                                                            .withValues(
                                                                alpha: 0.2)
                                                        : theme.success
                                                            .withValues(
                                                                alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    (_network!.testnet ?? false)
                                                        ? l10n
                                                            .setupNetworkSettingsPageTestnetLabel
                                                        : l10n
                                                            .setupNetworkSettingsPageMainnetLabel,
                                                    style: TextStyle(
                                                      color:
                                                          (_network!.testnet ??
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
                                      Text(
                                        "Account Index",
                                        style: TextStyle(
                                          color: theme.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Center(
                                        child: Counter(
                                          iconSize: 24,
                                          iconColor: theme.textPrimary,
                                          animationDuration:
                                              const Duration(milliseconds: 300),
                                          numberStyle: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textPrimary,
                                          ),
                                          initialValue: 0,
                                          disabled: _loading,
                                          onChanged: !_loading
                                              ? (value) {
                                                  setState(() {
                                                    _index = value;
                                                  });
                                                }
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (_errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
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
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(adaptivePadding),
                  child: RoundedLoadingButton(
                    color: theme.primaryPurple,
                    valueColor: theme.buttonText,
                    controller: _btnController,
                    onPressed: (_network == null || _ledger == null || _loading)
                        ? null
                        : _onConnect,
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
                      "Add Account",
                      style: TextStyle(
                        color: theme.buttonText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
