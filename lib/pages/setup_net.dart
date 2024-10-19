import 'package:flutter/material.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gradient_bg.dart';
import '../theme/theme_provider.dart';

class BlockchainSettingsPage extends StatefulWidget {
  const BlockchainSettingsPage({
    super.key,
  });

  @override
  State<BlockchainSettingsPage> createState() => _BlockchainSettingsPageState();
}

class _BlockchainSettingsPageState extends State<BlockchainSettingsPage> {
  String _selectedNetwork = 'Mainnet';
  final TextEditingController _rpcUrlController = TextEditingController();

  @override
  void dispose() {
    _rpcUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Blockchain Settings',
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Network Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
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
    );
  }
}
