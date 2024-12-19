import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockies/blockies.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/src/rust/api/settings.dart';
import 'package:zilpay/src/rust/models/notification.dart';
import 'package:zilpay/src/rust/models/wallet.dart';
import 'package:zilpay/theme/app_theme.dart';
import '../components/custom_app_bar.dart';
import '../mixins/colors.dart';
import '../state/app_state.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
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

  void _initializeServices() {}

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: 'Notifications',
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPushNotificationsSection(state, adaptivePadding),
                        const SizedBox(height: 24),
                        _buildWalletsSection(theme, adaptivePadding),
                        SizedBox(height: adaptivePadding),
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

  Widget _buildPushNotificationsSection(
      AppState state, double adaptivePadding) {
    final theme = state.currentTheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: adaptivePadding),
      padding: const EdgeInsets.all(16),
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
                value: state.state.notificationsGlobalEnabled,
                onChanged: (value) async {
                  await setGlobalNotifications(globalEnabled: value);
                  await state.syncData();
                },
                activeColor: theme.primaryPurple,
                activeTrackColor: theme.primaryPurple.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  Widget _buildWalletsSection(AppTheme theme, double adaptivePadding) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final isGlobalEnabled = appState.state.notificationsGlobalEnabled;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
          child: Opacity(
            opacity: isGlobalEnabled ? 1.0 : 0.5,
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
                const SizedBox(height: 8),
                Text(
                  'Notifications from wallets',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: adaptivePadding),
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AbsorbPointer(
                    absorbing: !isGlobalEnabled,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appState.wallets.length,
                      itemBuilder: (context, index) => _buildWalletItem(
                        appState,
                        appState.wallets[index],
                        index,
                        isLastItem: index == appState.wallets.length - 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletItem(
    AppState state,
    WalletInfo wallet,
    int index, {
    bool isLastItem = false,
  }) {
    final theme = state.currentTheme;
    final BackgroundNotificationState? walletNotify =
        state.state.notificationsWalletStates[BigInt.from(index)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(width: 12),
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
            value: walletNotify != null ? walletNotify.transactions : false,
            onChanged: (value) async {
              await setWalletNotifications(
                walletIndex: BigInt.from(index),
                transactions: value,
                price: false, // TODO: maybe set in future
                security: false,
                balance: false,
              );
              await state.syncData();
            },
            activeColor: theme.primaryPurple,
            activeTrackColor: theme.primaryPurple.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
