import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockies/blockies.dart';
import 'package:zilpay/src/rust/api/backend.dart';

import '../components/custom_app_bar.dart';
import '../mixins/colors.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart' as theme;
import '../theme/theme_provider.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool isPushNotificationsEnabled = false;
  late final AppState _appState;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _appState = Provider.of<AppState>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(
              title: 'Notifications',
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPushNotificationsSection(theme),
                    SizedBox(height: 24),
                    _buildWalletsSection(theme),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPushNotificationsSection(theme.AppTheme theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Push notifications',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: isPushNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    isPushNotificationsEnabled = value;
                  });
                },
                activeColor: theme.primaryPurple,
                activeTrackColor: theme.primaryPurple.withOpacity(0.5),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Get notifications when you receive TON, tokens and NFTs. Notifications from connected apps.',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletsSection(theme.AppTheme theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallets',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Notifications from wallets',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Consumer<AppState>(
              builder: (context, appState, _) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appState.wallets.length,
                  itemBuilder: (context, index) => _buildWalletItem(
                    theme,
                    appState.wallets[index],
                    index,
                    isLastItem: index == appState.wallets.length - 1,
                    onChanged: (value) {
                      // Here you can handle the notification toggle
                      // You might want to store this in AppState or local storage
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletItem(
    theme.AppTheme theme,
    WalletInfo wallet,
    int index, {
    required ValueChanged<bool> onChanged,
    bool isLastItem = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: !isLastItem
            ? Border(
                bottom: BorderSide(
                  color: theme.textSecondary.withOpacity(0.1),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Blockies(
                seed: wallet.walletAddress,
                color: getWalletColor(index),
                bgColor: theme.primaryPurple,
                spotColor: theme.background,
                size: 8,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              wallet.walletName.isEmpty
                  ? "Wallet ${index + 1}"
                  : wallet.walletName,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: true,
            onChanged: onChanged,
            activeColor: theme.primaryPurple,
            activeTrackColor: theme.primaryPurple.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
