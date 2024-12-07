import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/state/app_state.dart' as app_state;
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final TextEditingController _walletNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final appState = Provider.of<app_state.AppState>(context, listen: false);
    _walletNameController.text = appState.wallet!.walletName;
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final appState = Provider.of<app_state.AppState>(context);

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
                        SmartInput(
                          controller: _walletNameController,
                          hint: 'Wallet name',
                          onChanged: (value) {
                            // Implement wallet name change logic
                          },
                          height: 50,
                          rightIconPath: "assets/icons/edit.svg",
                          borderColor: theme.cardBackground,
                          focusedBorderColor: theme.primaryPurple,
                          fontSize: 16,
                        ),
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

  Widget _buildWalletHeader(AppTheme theme, app_state.AppState appState) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Container(
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(40),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Transform.scale(
            scale: 1.0, // Adjust this value if needed to fine-tune the size
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
              fontSize: 16,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildPreferenceItem(
                theme,
                'Zilliqa legacy',
                'assets/icons/scilla.svg',
                true,
                (value) {
                  debugPrint("enable Zilliqa legacy mode");
                },
              ),
              Divider(
                height: 1,
                color: theme.textSecondary.withOpacity(0.1),
              ),
              _buildPreferenceItem(
                theme,
                'Manage connections',
                'assets/icons/globe.svg',
                false,
                null,
                onTap: () => Navigator.pushNamed(context, '/connections'),
              ),
              Divider(
                height: 1,
                color: theme.textSecondary.withOpacity(0.1),
              ),
              _buildPreferenceItem(
                theme,
                'Backup',
                'assets/icons/key.svg',
                false,
                null,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(
    AppTheme theme,
    String title,
    String iconPath,
    bool hasSwitch,
    Function(bool)? onChanged, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                theme.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
            if (hasSwitch)
              Switch(
                value: true,
                onChanged: onChanged,
                activeColor: theme.primaryPurple,
              )
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Delete Wallet',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icons/logout.svg',
              colorFilter: const ColorFilter.mode(
                Colors.red,
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
