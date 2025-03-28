import 'dart:io';

import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zilpay/components/async_qrcode.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/mixins/qrcode.dart';
import 'package:zilpay/modals/select_token.dart';
import 'package:zilpay/src/rust/api/qrcode.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/src/rust/models/qrcode.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  bool isCopied = false;
  bool isPressedToken = false;
  int selectedToken = 0;
  String amount = "0";
  Key _imageKey = UniqueKey();
  String? legacyAddress;
  bool useLegacyAddress = false;

  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final chain = appState.chain!;

    _amountController.text = amount;
    _accountNameController.text = appState.account?.name ?? "";

    if (chain.slip44 == 313) {
      zilliqaGetNFormat(
        walletIndex: BigInt.from(appState.selectedWallet),
        accountIndex: appState.wallet!.selectedAccount,
      ).then((addr) {
        setState(() {
          legacyAddress = addr;
        });
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> handleCopy(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    setState(() {
      isCopied = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isCopied = false;
    });
  }

  void handlePressedChanged(bool pressed) {
    setState(() {
      isPressedToken = pressed;
    });
  }

  void handleSelectToken() {
    showTokenSelectModal(
      context: context,
      onTokenSelected: (index) {
        setState(() {
          selectedToken = index;
          _imageKey = UniqueKey();
        });
      },
    );
  }

  Future<void> handleShare(
    FTokenInfo token,
    String addr,
    AppTheme theme,
    NetworkConfigInfo chain,
  ) async {
    QrConfigInfo config = QrConfigInfo(
      size: 600,
      gapless: false,
      color: theme.primaryPurple.toARGB32(),
      eyeShape: EyeShape.circle.value,
      dataModuleShape: DataModuleShape.circle.value,
    );
    String data = generateCryptoUrl(
      address: addr,
      chain: chain.shortName,
      token: token.addr,
      amount: amount,
    );

    try {
      final pngBytes = await genPngQrcode(data: data, config: config);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/qrcode.png');
      await tempFile.writeAsBytes(pngBytes);
      final xFile = XFile(tempFile.path, mimeType: 'image/png');
      await Share.shareXFiles(
        [xFile],
        text: '$addr, amount: $amount',
      );
      await tempFile.delete();
    } catch (e) {
      debugPrint("error share: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final chain = appState.chain!;
    final token = appState.wallet!.tokens[selectedToken];
    final currentAddress = useLegacyAddress && legacyAddress != null
        ? legacyAddress!
        : appState.account!.addr;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: l10n.receivePageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: adaptivePadding),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(
                                      vertical: adaptivePadding),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/warning.svg",
                                        width: 24,
                                        height: 24,
                                        colorFilter: ColorFilter.mode(
                                          theme.warning,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          l10n.receivePageWarning(
                                              chain.name, token.symbol),
                                          style: TextStyle(
                                            color: theme.warning,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(adaptivePadding),
                                  decoration: BoxDecoration(
                                    color: theme.cardBackground,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildTokenSelector(appState, token),
                                      const SizedBox(height: 24),
                                      if (appState.account != null)
                                        SizedBox(
                                          width: 220,
                                          height: 220,
                                          child: AsyncQRcode(
                                            data: generateCryptoUrl(
                                              address: currentAddress,
                                              chain: chain.shortName,
                                              token: token.addr,
                                              amount: amount,
                                            ),
                                            color: theme.primaryPurple,
                                            size: 220,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      Text(
                                        currentAddress,
                                        style: TextStyle(
                                          color: theme.textSecondary,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SmartInput(
                                  controller: _accountNameController,
                                  hint: l10n.receivePageAccountNameHint,
                                  onSubmitted: (_) async {
                                    if (_accountNameController
                                        .text.isNotEmpty) {
                                      await changeAccountName(
                                        walletIndex: BigInt.from(
                                            appState.selectedWallet),
                                        accountIndex:
                                            appState.wallet!.selectedAccount,
                                        newName: _accountNameController.text,
                                      );
                                      await appState.syncData();
                                    }
                                  },
                                  height: 50,
                                  rightIconPath: "assets/icons/edit.svg",
                                  borderColor: theme.cardBackground,
                                  focusedBorderColor: theme.primaryPurple,
                                  fontSize: 14,
                                ),
                                const SizedBox(height: 16),
                                _buildActionButtons(
                                    theme, chain, context, currentAddress),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildTokenSelector(AppState appState, FTokenInfo token) {
    final theme = appState.currentTheme;

    return GestureDetector(
      onTapDown: (_) => handlePressedChanged(true),
      onTapUp: (_) => handlePressedChanged(false),
      onTapCancel: () => handlePressedChanged(false),
      onTap: handleSelectToken,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isPressedToken ? 0.6 : 1.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Center(
                child: AsyncImage(
                  key: _imageKey,
                  url: processTokenLogo(
                    token: token,
                    shortName: appState.chain?.shortName ?? "",
                    theme: theme.value,
                  ),
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorWidget: Blockies(
                    seed: token.addr,
                    color: theme.secondaryPurple,
                    bgColor: theme.primaryPurple,
                    spotColor: theme.background,
                    size: 8,
                  ),
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              token.name,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              "(${token.symbol})",
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    AppTheme theme,
    NetworkConfigInfo chain,
    BuildContext context,
    String currentAddress,
  ) {
    final appState = Provider.of<AppState>(context);
    final token = appState.wallet!.tokens[selectedToken];
    final account = appState.account;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TileButton(
          icon: SvgPicture.asset(
            isCopied ? "assets/icons/check.svg" : "assets/icons/copy.svg",
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
          ),
          disabled: false,
          onPressed: () async {
            await handleCopy(currentAddress);
          },
          backgroundColor: theme.cardBackground,
          textColor: theme.primaryPurple,
        ),
        TileButton(
          icon: SvgPicture.asset(
            "assets/icons/hash.svg",
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
          ),
          disabled: false,
          onPressed: _handleAmountDialog,
          backgroundColor: theme.cardBackground,
          textColor: theme.primaryPurple,
        ),
        if (account != null && chain.slip44 == 313)
          TileButton(
            icon: SvgPicture.asset(
              useLegacyAddress
                  ? "assets/icons/scilla.svg"
                  : "assets/icons/solidity.svg",
              width: 24,
              height: 24,
              colorFilter:
                  ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
            ),
            disabled: legacyAddress == null || account.addrType == 0,
            onPressed: () {
              if (legacyAddress != null) {
                setState(() {
                  useLegacyAddress = !useLegacyAddress;
                });
              }
            },
            backgroundColor: theme.cardBackground,
            textColor: theme.primaryPurple,
          ),
        TileButton(
          icon: SvgPicture.asset(
            "assets/icons/share.svg",
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
          ),
          disabled: false,
          onPressed: () async {
            await handleShare(token, currentAddress, theme, chain);
          },
          backgroundColor: theme.cardBackground,
          textColor: theme.primaryPurple,
        ),
      ],
    );
  }

  Future<void> _handleAmountDialog() async {
    _amountController.text = amount;
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final theme = Provider.of<AppState>(context).currentTheme;

        return AlertDialog(
          backgroundColor: theme.cardBackground,
          title: Text(
            l10n.receivePageAmountDialogTitle,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\,\.]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return TextEditingValue(
                  text: newValue.text.replaceAll(',', '.'),
                  selection: newValue.selection,
                );
              }),
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                if (newValue.text.split('.').length > 2) return oldValue;
                return newValue;
              }),
            ],
            decoration: InputDecoration(
              hintText: l10n.receivePageAmountDialogHint,
              hintStyle: TextStyle(color: theme.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.primaryPurple),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.primaryPurple, width: 2),
              ),
            ),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.receivePageAmountDialogCancel,
                style: TextStyle(color: theme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_amountController.text.isEmpty) {
                  _amountController.text = '0';
                }
                Navigator.pop(context, _amountController.text);
              },
              child: Text(
                l10n.receivePageAmountDialogConfirm,
                style: TextStyle(
                  color: theme.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        amount = result;
      });
    }
  }
}
