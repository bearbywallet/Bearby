import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/token_card.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart';

class AddTokenPage extends StatefulWidget {
  const AddTokenPage({super.key});

  @override
  State<AddTokenPage> createState() => _AddTokenPageState();
}

class _AddTokenPageState extends State<AddTokenPage> {
  static const double _borderRadius = 12.0;
  static const double _fontSize = 16.0;
  static const double _inputHeight = 50.0;

  final TextEditingController _tokenTextController = TextEditingController();
  List<FTokenInfo> tokens = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Add Token',
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 24),
                        _buildInputSection(theme, appState),
                        if (_errorMessage != null) _buildErrorMessage(theme),
                        const SizedBox(height: 32),
                        if (tokens.isNotEmpty)
                          _buildTokensList(theme, appState),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _buildErrorMessage(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Text(
        _errorMessage ?? '',
        style: TextStyle(
          color: theme.danger,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInputSection(AppTheme theme, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            'Token Information',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: _fontSize,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SmartInput(
                  controller: _tokenTextController,
                  onChanged: (value) async {
                    // Clear error message when user starts typing
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                    await _onChange(value, appState.selectedWallet);
                  },
                  hint: "Address, name, symbol",
                  height: _inputHeight,
                  borderColor: Colors.transparent,
                  focusedBorderColor: Colors.transparent,
                  fontSize: _fontSize,
                  disabled: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTokensList(AppTheme theme, AppState appState) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Container(
      padding: EdgeInsets.all(adaptivePadding),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tokens.length; i++)
            TokenCard(
              ftoken: tokens[i],
              tokenAmount:
                  tokens[i].balances[appState.wallet?.selectedAccount] ?? "0",
              showDivider: i < tokens.length - 1,
              onTap: () => _onAddToken(
                i,
                appState.selectedWallet,
                appState,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onAddToken(
    int tokenIndex,
    int walletIndex,
    AppState appState,
  ) async {
    try {
      setState(() {
        _errorMessage = null;
      });
      String? templateUrl = appState.wallets[walletIndex].tokens.first.logo;
      FTokenInfo meta = FTokenInfo(
        name: tokens[tokenIndex].name,
        symbol: tokens[tokenIndex].symbol,
        decimals: tokens[tokenIndex].decimals,
        addr: tokens[tokenIndex].addr,
        addrType: tokens[tokenIndex].addrType,
        balances: tokens[tokenIndex].balances,
        rate: tokens[tokenIndex].rate,
        default_: tokens[tokenIndex].default_,
        native: tokens[tokenIndex].native,
        chainHash: tokens[tokenIndex].chainHash,
        logo: tokens[tokenIndex].logo ?? templateUrl,
      );

      await addFtoken(
        meta: meta,
        walletIndex: BigInt.from(walletIndex),
      );
      await appState.syncData();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add token: ${e.toString()}';
      });
      debugPrint("error: $e");
    }
  }

  Future<void> _onChange(String value, int walletIndex) async {
    if (value.length >= 42) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        FTokenInfo meta = await fetchTokenMeta(
          addr: value,
          walletIndex: BigInt.from(walletIndex),
        );

        setState(() {
          if (!tokens.any((token) => token.addr == meta.addr)) {
            tokens = [meta, ...tokens];
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Invalid token address or network error';
        });
        debugPrint("error: $e");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
