import 'dart:convert';
import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/button.dart';

class Account {
  final String name;
  final String address;

  Account({required this.name, required this.address});
}

class RestoreRKStorage extends StatefulWidget {
  const RestoreRKStorage({super.key});

  @override
  State<RestoreRKStorage> createState() => _RestoreRKStorageState();
}

class _RestoreRKStorageState extends State<RestoreRKStorage> {
  List<Account> accounts = [];
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  String? _vaultJson;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String?>?;
    if (args == null ||
        args['vaultJson'] == null ||
        args['accountsJson'] == null) {
      Navigator.pop(context);
      return;
    }

    try {
      _vaultJson = args['vaultJson'];
      final accountsJson = jsonDecode(args['accountsJson']!);
      final identities = accountsJson['identities'] as List<dynamic>;
      setState(() {
        accounts = identities
            .map((identity) => Account(
                  name: identity['name'] as String,
                  address: identity['bech32'] as String,
                ))
            .toList();
      });
    } catch (e) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRestore() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Migration completed successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Migrate ZilPay 1.0 to ZilPay 2.0!',
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The following accounts will be migrated to ZilPay 2.0. Enter password to confirm.',
                      style:
                          TextStyle(color: theme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                theme.secondaryPurple.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: accounts
                                .map((account) => AccountItem(account: account))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SmartInput(
                      controller: _passwordController,
                      hint: 'Password',
                      obscureText: _obscurePassword,
                      rightIconPath: _obscurePassword
                          ? 'assets/icons/close_eye.svg'
                          : 'assets/icons/open_eye.svg',
                      onRightIconTap: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      disabled: _isLoading,
                      focusedBorderColor: theme.primaryPurple,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.danger, fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Restore',
                      onPressed: _isLoading ? null : _handleRestore,
                      backgroundColor: theme.primaryPurple,
                      borderRadius: 30.0,
                      height: 56.0,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    final theme = Provider.of<AppState>(context).currentTheme;
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
              child: Blockies(
                seed: account.address.toLowerCase(),
                size: 8,
                color: theme.secondaryPurple,
                bgColor: theme.primaryPurple,
                spotColor: theme.background,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  account.address,
                  style: TextStyle(color: theme.textSecondary, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
