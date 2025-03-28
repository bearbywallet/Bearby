import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

void showWatchAssetModal({
  required BuildContext context,
  required String tokenName,
  required String tokenSymbol,
  String? tokenIconUrl,
  required String tokenAddress,
  required String appTitle,
  required String appIcon,
  required Function(FTokenInfo) onConfirm,
  required Function() onCancel,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _WatchAssetModalContent(
          tokenAddress: tokenAddress,
          tokenName: tokenName,
          tokenSymbol: tokenSymbol,
          tokenIconUrl: tokenIconUrl,
          appTitle: appTitle,
          appIcon: appIcon,
          onConfirm: onConfirm,
          onCancel: onCancel,
        ),
      );
    },
  ).then((_) => onCancel.call());
}

class _WatchAssetModalContent extends StatefulWidget {
  final String tokenName;
  final String tokenSymbol;
  final String? tokenIconUrl;
  final String tokenAddress;
  final String appTitle;
  final String appIcon;
  final Function(FTokenInfo) onConfirm;
  final Function() onCancel;

  const _WatchAssetModalContent({
    required this.tokenName,
    required this.tokenAddress,
    required this.tokenSymbol,
    required this.appTitle,
    required this.appIcon,
    required this.onConfirm,
    required this.onCancel,
    this.tokenIconUrl,
  });

  @override
  State<_WatchAssetModalContent> createState() =>
      _WatchAssetModalContentState();
}

class _WatchAssetModalContentState extends State<_WatchAssetModalContent>
    with SingleTickerProviderStateMixin {
  bool _isLoadingBalance = true;
  FTokenInfo? _ftoken;
  String? _errorMessage;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _loadBalance();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      FTokenInfo meta = await fetchTokenMeta(
        addr: widget.tokenAddress,
        walletIndex: BigInt.from(appState.selectedWallet),
      );

      if (mounted) {
        setState(() {
          _ftoken = FTokenInfo(
            name: meta.name,
            symbol: meta.symbol,
            decimals: meta.decimals,
            addr: meta.addr,
            addrType: meta.addrType,
            balances: meta.balances,
            default_: meta.default_,
            rate: 0,
            native: false,
            chainHash: meta.chainHash,
            logo: widget.tokenIconUrl ?? appState.wallet?.tokens.first.logo,
          );
          _isLoadingBalance = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingBalance = false;
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _loadBalance();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final primaryColor = theme.primaryPurple;
    final secondaryColor = theme.textSecondary;
    final textColor = theme.textPrimary;
    final selectedAccount = appState.wallet?.selectedAccount ?? BigInt.zero;
    final (balance, convertedBalance) = formatingAmount(
      amount: BigInt.tryParse(_ftoken?.balances[selectedAccount] ?? '0') ??
          BigInt.zero,
      symbol: _ftoken?.symbol ?? '',
      decimals: _ftoken?.decimals ?? 18,
      rate: _ftoken?.rate ?? 0,
      appState: appState,
    );
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: theme.modalBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.modalBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.watchAssetModalContentTitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.watchAssetModalContentDescription,
                    style: TextStyle(color: secondaryColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          secondaryColor.withValues(alpha: 0.1),
                          primaryColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (widget.appIcon.isNotEmpty)
                          Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: AsyncImage(
                                url: widget.appIcon,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                loadingWidget: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: secondaryColor,
                                ),
                                errorWidget: Icon(
                                  Icons.link,
                                  color: secondaryColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        Text(
                          widget.appTitle,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.watchAssetModalContentTokenLabel,
                        style: TextStyle(color: secondaryColor, fontSize: 14),
                      ),
                      Text(
                        l10n.watchAssetModalContentBalanceLabel,
                        style: TextStyle(color: secondaryColor, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _isLoadingBalance
                      ? AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            double w = MediaQuery.of(context).size.width - 32;
                            double start = 10;
                            double end = w - 250 - 10;
                            double left =
                                start + (_animation.value * (end - start));
                            return SizedBox(
                              height: 64,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  child!,
                                  Positioned(
                                    left: left,
                                    child: Container(
                                      height: 64,
                                      width: 250,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.white.withValues(alpha: 0.4),
                                            Colors.transparent,
                                          ],
                                          stops: [0.0, 0.5, 1.0],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  if (_ftoken != null)
                                    AsyncImage(
                                      url: processTokenLogo(
                                        token: _ftoken!,
                                        shortName:
                                            appState.chain?.shortName ?? '',
                                        theme: theme.value,
                                      ),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _ftoken?.name ?? widget.tokenName,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    balance,
                                    style: TextStyle(
                                        color: textColor, fontSize: 16),
                                  ),
                                  Text(
                                    convertedBalance,
                                    style: TextStyle(
                                        color: secondaryColor, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                AsyncImage(
                                  url: processTokenLogo(
                                    token: _ftoken!,
                                    shortName: appState.chain?.shortName ?? '',
                                    theme: theme.value,
                                  ),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.tokenName,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  balance,
                                  style:
                                      TextStyle(color: textColor, fontSize: 16),
                                ),
                                Text(
                                  convertedBalance,
                                  style: TextStyle(
                                      color: secondaryColor, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomPadding),
              child: Column(
                children: [
                  SwipeButton(
                    text: _isLoadingBalance
                        ? l10n.watchAssetModalContentLoadingButton
                        : l10n.watchAssetModalContentAddButton,
                    disabled: _isLoadingBalance || _errorMessage != null,
                    backgroundColor: primaryColor,
                    textColor: textColor,
                    onSwipeComplete: () async {
                      if (_ftoken != null) {
                        widget.onConfirm(_ftoken!);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
