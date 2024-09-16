import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../components/view_item.dart';

class AddWalletOptionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Add Wallet', style: TextStyle(color: theme.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: theme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a new wallet or add\nan existing one.',
                style: TextStyle(color: theme.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              WalletListItem(
                title: 'New Wallet',
                subtitle: 'Create new wallet',
                icon: Icons.add,
                onTap: () {/* Handle new wallet creation */},
              ),
              WalletListItem(
                title: 'Existing Wallet',
                subtitle: 'Import wallet with a 24 secret recovery words',
                icon: Icons.input,
                onTap: () {/* Handle existing wallet import */},
              ),
              WalletListItem(
                title: 'Pair with Ledger',
                subtitle: 'Hardware module, Bluetooth, limited TON features',
                icon: Icons.security,
                onTap: () {/* Handle pairing with Ledger */},
              ),
              SizedBox(height: 24),
              Text(
                'Other options',
                style: TextStyle(color: theme.textSecondary, fontSize: 14),
              ),
              SizedBox(height: 16),
              WalletListItem(
                title: 'Watch Account',
                subtitle: 'For monitor wallet activity without recovery phrase',
                icon: Icons.remove_red_eye,
                onTap: () {/* Handle watch account */},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
