import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/components/jazzicon.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class Account {
  final String name;
  final String address;
  final String? balance;
  final int type;
  final int index;

  Account({
    required this.name,
    required this.address,
    required this.type,
    required this.index,
    this.balance,
  });
}

class RestoreRKStorage extends StatefulWidget {
  const RestoreRKStorage({super.key});

  @override
  State<RestoreRKStorage> createState() => _RestoreRKStorageState();
}

class _RestoreRKStorageState extends State<RestoreRKStorage>
    with StatusBarMixin {
  List<Account> accounts = [];
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  String? _vaultJson;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context, listen: false);

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String?>?;
    if (args == null || args['vaultJson'] == null) {
      Navigator.pop(context);
      return;
    }
    _vaultJson = args['vaultJson'];
    try {
      final accountsJson = jsonDecode(args['accountsJson'] ?? '{}');
      final identities = (accountsJson['identities'] as List<dynamic>?) ?? [];

      setState(() {
        accounts = identities.map((identity) {
          final balanceMap = identity['balance'] as Map<String, dynamic>?;
          final mainnetBalance =
              balanceMap?['mainnet'] as Map<String, dynamic>?;
          final (balance, _) = formatingAmount(
            amount: mainnetBalance?['ZIL'] ?? "0",
            symbol: "ZIL",
            decimals: 12,
            rate: 0,
            appState: appState,
          );

          return Account(
            name: identity['name'] as String? ?? 'Unnamed',
            address: identity['bech32'] as String? ?? '',
            type: identity['type'] as int? ?? 0,
            index: identity['index'] as int? ?? 0,
            balance: balance,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint("Error parsing accounts JSON: $e");
      setState(() {
        accounts = [];
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRestore() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage =
          AppLocalizations.of(context)!.restoreRKStorageEnterPassword);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      String words = await tryRestoreRkstorage(
        vaultJson: _vaultJson!,
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.of(context).pushNamed('/net_setup', arguments: {
          'bip39': words.split(" "),
          'zilLegacy': true,
          'ignore_checksum': true,
        });
      }
    } catch (e) {
      setState(() => _errorMessage =
          '${AppLocalizations.of(context)!.restoreRKStorageErrorPrefix} ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final l10n = AppLocalizations.of(context)!;
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomAppBar(
                      title: l10n.restoreRKStorageTitle,
                      onBackPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (accounts.isNotEmpty) ...[
                          Text(l10n.restoreRKStorageAccountsPrompt,
                              style: theme.bodyText2.copyWith(
                                  color: theme.textSecondary)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: theme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: theme.secondaryPurple
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: accounts
                                  .map((account) =>
                                      AccountItem(account: account))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SmartInput(
                          controller: _passwordController,
                          hint: l10n.restoreRKStoragePasswordHint,
                          obscureText: _obscurePassword,
                          rightIconPath: _obscurePassword
                              ? 'assets/icons/close_eye.svg'
                              : 'assets/icons/open_eye.svg',
                          onRightIconTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          disabled: _isLoading,
                          focusedBorderColor: theme.primaryPurple,
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(_errorMessage!,
                                style: theme.bodyText2.copyWith(
                                    color: theme.danger)),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            textColor: theme.buttonText,
                            backgroundColor: theme.primaryPurple,
                            text: l10n.restoreRKStorageRestoreButton,
                            disabled: _isLoading,
                            onPressed: _handleRestore,
                            borderRadius: 30.0,
                            height: 56.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: SizedBox(
                            width: 100,
                            child: TextButton(
                              onPressed: () => Navigator.of(context)
                                  .pushNamed('/new_wallet_options'),
                              child: Text(l10n.restoreRKStorageSkipButton,
                                  style: theme.bodyText2.copyWith(
                                      color: theme.textSecondary)),
                            ),
                          ),
                        ),
                      ],
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

class AccountItem extends StatelessWidget {
  final Account account;

  const AccountItem({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Jazzicon(
                diameter: 40,
                seed: account.address.toLowerCase(),
                shapeCount: 4,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style: theme.bodyLarge.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.bold)),
                Text(account.address,
                    style: theme.bodyText2.copyWith(color: theme.textSecondary),
                    overflow: TextOverflow.ellipsis),
                Text(
                    '${l10n.accountItemBalanceLabel} ${account.balance ?? '0'} ZIL',
                    style: theme.bodyText2.copyWith(color: theme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
