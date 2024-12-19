import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/modals/manage_connections.dart';
import 'package:zilpay/modals/secret_recovery_modal.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart';

class WalletPreferenceItem {
  final String title;
  final String iconPath;
  final bool hasSwitch;
  final bool switchValue;
  final Function(bool)? onChanged;
  final VoidCallback? onTap;

  WalletPreferenceItem({
    required this.title,
    required this.iconPath,
    this.hasSwitch = false,
    this.switchValue = false,
    this.onChanged,
    this.onTap,
  });
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final TextEditingController _walletNameController = TextEditingController();
  static const double _avatarSize = 80.0;
  static const double _borderRadius = 12.0;
  static const double _iconSize = 24.0;
  static const double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _walletNameController.text = appState.wallet!.walletName;
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    super.dispose();
  }

  void _handleDappDisconnect(String url) {
    // final appState = Provider.of<app_state.AppState>(context, listen: false);
    // Implement disconnect logic here
    debugPrint('Disconnecting DApp: $url');
  }

  List<WalletPreferenceItem> _getPreferenceItems(
      BuildContext context, AppTheme theme) {
    final appState = Provider.of<AppState>(context);

    return [
      WalletPreferenceItem(
        title: 'Use Face ID',
        iconPath: 'assets/icons/face_id.svg',
        hasSwitch: true,
        switchValue: true,
        onChanged: (value) => debugPrint("enable face id $value"),
      ),
      WalletPreferenceItem(
        title: 'Zilliqa legacy',
        iconPath: 'assets/icons/scilla.svg',
        hasSwitch: true,
        switchValue: true,
        onChanged: (value) => debugPrint("enable Zilliqa legacy mode"),
      ),
      WalletPreferenceItem(
          title: 'Manage connections',
          iconPath: 'assets/icons/globe.svg',
          onTap: () {
            if (appState.connections.length > 0) {
              showConnectedDappsModal(
                context: context,
                onDappDisconnect: _handleDappDisconnect,
              );
            }
          }),
      if (!appState.wallet!.walletType.contains(WalletType.ledger.name))
        WalletPreferenceItem(
          title: 'Backup',
          iconPath: 'assets/icons/key.svg',
          onTap: () {
            if (!appState.wallet!.walletType.contains(WalletType.ledger.name)) {
              _handleBackup(theme);
            }
          },
        ),
    ];
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
              title: '',
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Center(child: _buildWalletHeader(theme, appState)),
                        const SizedBox(height: 16),
                        _buildWalletNameInput(theme),
                        const SizedBox(height: 32),
                        _buildPreferencesSection(theme),
                      ]),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: adaptivePadding,
                        right: adaptivePadding,
                        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildRemoveWalletButton(theme),
                        ],
                      ),
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

  Widget _buildWalletHeader(AppTheme theme, AppState appState) {
    return SizedBox(
      width: _avatarSize,
      height: _avatarSize,
      child: Container(
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(_avatarSize / 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_avatarSize / 2),
          child: Transform.scale(
            scale: 1.0,
            child: Blockies(
              seed: appState.account!.addr,
              color: getWalletColor(0),
              bgColor: theme.primaryPurple,
              spotColor: theme.background,
              size: 8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletNameInput(AppTheme theme) {
    return SmartInput(
      controller: _walletNameController,
      hint: 'Wallet name',
      onChanged: (value) {
        // Implement wallet name change logic
      },
      height: 50,
      rightIconPath: "assets/icons/edit.svg",
      borderColor: theme.cardBackground,
      focusedBorderColor: theme.primaryPurple,
      fontSize: _fontSize,
    );
  }

  Widget _buildPreferencesSection(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            'Wallet preferences',
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
            children: _buildPreferenceItems(theme),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPreferenceItems(AppTheme theme) {
    final items = _getPreferenceItems(context, theme);
    final List<Widget> widgets = [];

    for (var i = 0; i < items.length; i++) {
      widgets.add(_buildPreferenceItem(theme, items[i]));
      if (i < items.length - 1) {
        widgets.add(Divider(
          height: 1,
          color: theme.textSecondary.withOpacity(0.1),
        ));
      }
    }

    return widgets;
  }

  Widget _buildPreferenceItem(AppTheme theme, WalletPreferenceItem item) {
    final appState = Provider.of<AppState>(context);

    return GestureDetector(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              item.iconPath,
              width: _iconSize,
              height: _iconSize,
              colorFilter: ColorFilter.mode(
                theme.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: _fontSize,
                ),
              ),
            ),
            if (item.hasSwitch)
              Switch(
                value: item.switchValue,
                onChanged: item.onChanged,
                activeColor: theme.primaryPurple,
              )
            else if (item.title == 'Manage connections')
              Text(
                '${appState.connections.length}',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: _fontSize,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveWalletButton(AppTheme theme) {
    return GestureDetector(
      onTap: () async {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Delete Wallet',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: _fontSize,
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icons/logout.svg',
              colorFilter: const ColorFilter.mode(
                Colors.red,
                BlendMode.srcIn,
              ),
              width: _iconSize,
              height: _iconSize,
            ),
          ],
        ),
      ),
    );
  }

  void _handleBackup(AppTheme theme) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.cardBackground,
      isScrollControlled: true,
      builder: (context) => SecretRecoveryModal(
        theme: theme,
      ),
    );
  }
}
