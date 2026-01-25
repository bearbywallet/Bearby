import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/bip_purpose_selector.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/config/web3_constants.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/biometric_switch.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/modals/confirm_password.dart';
import 'package:zilpay/modals/delete_wallet.dart';
import 'package:zilpay/modals/manage_connections.dart';
import 'package:zilpay/modals/secret_recovery_modal.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/auth.dart';
import 'package:zilpay/src/rust/api/connections.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class WalletPreferenceItem {
  final String title;
  final String iconPath;
  final bool hasSwitch;
  final bool switchValue;
  final bool switchEnabled;
  final Function(bool)? onChanged;
  final VoidCallback? onTap;

  WalletPreferenceItem({
    required this.title,
    required this.iconPath,
    this.hasSwitch = false,
    this.switchValue = false,
    this.switchEnabled = true,
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

  List<String> _authMethods = [];
  bool _biometricsAvailable = false;
  bool _isBiometricLoading = false;
  int _selectedBipPurposeIndex = 1;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _walletNameController.text = appState.wallet!.walletName;
    appState.syncConnections();
    _checkAuthMethods();
    _initializeBipPurpose(appState);
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthMethods() async {
    try {
      final methods = await getBiometricType();

      setState(() {
        _authMethods = methods;
        _biometricsAvailable = methods.isNotEmpty && methods.first != "none";
      });
    } catch (e) {
      debugPrint("Error checking auth methods: $e");
      setState(() {
        _authMethods = [];
        _biometricsAvailable = false;
      });
    }
  }

  Future<void> _initializeBipPurpose(AppState appState) async {
    if (!_isBitcoinWallet(appState) || appState.account?.addr == null) {
      return;
    }

    try {
      final addressType = await bitcoinAddressTypeFromAddress(
        addr: appState.account!.addr,
      );
      final index = _mapAddressTypeToBipIndex(addressType);

      setState(() {
        _selectedBipPurposeIndex = index;
      });
    } catch (e) {
      debugPrint("Error determining BIP purpose: $e");
    }
  }

  int _mapAddressTypeToBipIndex(String addressType) {
    switch (addressType) {
      case "p2tr":
        return 0;
      case "p2wpkh":
      case "p2wsh":
        return 1;
      case "p2sh":
        return 2;
      case "p2pkh":
      default:
        return 3;
    }
  }

  String _mapBipIndexToAddressType(int index) {
    switch (index) {
      case 0:
        return "p2tr";
      case 1:
        return "p2wpkh";
      case 2:
        return "p2sh";
      case 3:
      default:
        return "p2pkh";
    }
  }

  void _handleDappDisconnect(String url) async {
    AppState appState = Provider.of<AppState>(context, listen: false);
    await removeConnections(
      walletIndex: BigInt.from(appState.selectedWallet),
      domain: url,
    );
    await appState.syncConnections();
  }

  Future<void> _handleToggleBiometric(bool enable, AppState appState) async {
    if (_isBiometricLoading) return;

    setState(() {
      _isBiometricLoading = true;
    });

    try {
      final wallet = appState.wallet;
      if (wallet == null) {
        _resetBiometricLoading();
        return;
      }

      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();

      if (enable) {
        await _showBiometricPasswordModal(
          appState: appState,
          identifiers: identifiers,
          enable: true,
        );
      } else {
        await _disableBiometric(appState, identifiers);
      }
    } catch (e) {
      debugPrint("Error changing biometric: $e");
      _resetBiometricLoading();
    } finally {
      await appState.syncData();
    }
  }

  Future<void> _disableBiometric(
    AppState appState,
    List<String> identifiers,
  ) async {
    try {
      await setBiometric(
        walletIndex: BigInt.from(appState.selectedWallet),
        identifiers: identifiers,
        newBiometricType: "none",
      );
      _resetBiometricLoading();
    } catch (e) {
      if (mounted) {
        await _showBiometricPasswordModal(
          appState: appState,
          identifiers: identifiers,
          enable: false,
        );
      } else {
        rethrow;
      }
    }
  }

  void _resetBiometricLoading() {
    if (mounted) {
      setState(() {
        _isBiometricLoading = false;
      });
    }
  }

  Future<void> _showBiometricPasswordModal({
    required AppState appState,
    required List<String> identifiers,
    required bool enable,
  }) async {
    if (!mounted) return;

    showConfirmPasswordModal(
      context: context,
      theme: appState.currentTheme,
      onDismiss: _resetBiometricLoading,
      onConfirm: (password) async {
        try {
          await setBiometric(
            walletIndex: BigInt.from(appState.selectedWallet),
            identifiers: identifiers,
            password: password,
            newBiometricType: enable ? _authMethods.first : "none",
          );

          _resetBiometricLoading();
          await appState.syncData();
          return null;
        } catch (e) {
          return e.toString();
        }
      },
    );
  }

  Future<void> _executeBitcoinAddressChange({
    required AppState appState,
    required String newAddressType,
    required List<String> identifiers,
    required int newIndex,
    String? password,
  }) async {
    await bitcoinChangeAddressType(
      walletIndex: BigInt.from(appState.selectedWallet),
      newAddressType: newAddressType,
      identifiers: identifiers,
      password: password,
    );

    await appState.syncData();

    if (mounted) {
      setState(() {
        _selectedBipPurposeIndex = newIndex;
      });
    }
  }

  Future<void> _handleBipPurposeChange(int newIndex, AppState appState) async {
    if (newIndex == _selectedBipPurposeIndex) return;

    final newAddressType = _mapBipIndexToAddressType(newIndex);
    final wallet = appState.wallet;
    if (wallet == null) return;

    final device = DeviceInfoService();
    final identifiers = await device.getDeviceIdentifiers();
    final biometricEnabled = wallet.authType != "none";

    if (biometricEnabled && mounted) {
      await _executeBitcoinAddressChange(
        appState: appState,
        newAddressType: newAddressType,
        identifiers: identifiers,
        newIndex: newIndex,
      );
      return;
    }

    if (mounted) {
      showConfirmPasswordModal(
        context: context,
        theme: appState.currentTheme,
        onConfirm: (password) async {
          try {
            await _executeBitcoinAddressChange(
              appState: appState,
              newAddressType: newAddressType,
              identifiers: identifiers,
              newIndex: newIndex,
              password: password,
            );
            return null;
          } catch (e) {
            return e.toString();
          }
        },
      );
    }
  }

  List<WalletPreferenceItem> _getPreferenceItems(AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    final List<WalletPreferenceItem> items = [];

    items.add(
      WalletPreferenceItem(
        title: l10n.walletPageManageConnections,
        iconPath: 'assets/icons/globe.svg',
        onTap: () {
          if (appState.connections.isNotEmpty) {
            showConnectedDappsModal(
              context: context,
              onDappDisconnect: _handleDappDisconnect,
            );
          }
        },
      ),
    );

    if (!appState.wallet!.walletType.contains(WalletType.ledger.name)) {
      items.add(
        WalletPreferenceItem(
          title: l10n.walletPageBackup,
          iconPath: 'assets/icons/key.svg',
          onTap: () {
            if (!appState.wallet!.walletType.contains(WalletType.ledger.name)) {
              _handleBackup(appState.currentTheme);
            }
          },
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final Color effectiveBgColor = Theme.of(context).scaffoldBackgroundColor;
    final Brightness backgroundBrightness =
        ThemeData.estimateBrightnessForColor(effectiveBgColor);
    final Brightness statusBarIconBrightness =
        backgroundBrightness == Brightness.light
            ? Brightness.dark
            : Brightness.light;
    final Brightness statusBarBrightness = backgroundBrightness;

    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness,
    );

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: overlayStyle,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: CustomAppBar(
                      title: "",
                      onBackPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Center(child: _buildWalletHeader(theme, appState)),
                      const SizedBox(height: 16),
                      _buildWalletNameInput(theme, appState),
                      const SizedBox(height: 32),
                      _buildPreferencesSection(appState),
                      if (_isBitcoinWallet(appState)) ...[
                        const SizedBox(height: 32),
                        _buildBipPurposeSection(appState),
                      ],
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
                        _buildRemoveWalletButton(appState),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            child: AsyncImage(
              url: viewChain(network: appState.chain!, theme: theme.value),
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorWidget: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.background,
                ),
                child: SvgPicture.asset(
                  'assets/icons/warning.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    theme.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              loadingWidget: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletNameInput(AppTheme theme, AppState state) {
    return SmartInput(
      controller: _walletNameController,
      hint: AppLocalizations.of(context)!.walletPageWalletNameHint,
      onSubmitted: (_) async {
        if (_walletNameController.text.isNotEmpty) {
          await changeWalletName(
            walletIndex: BigInt.from(state.selectedWallet),
            newName: _walletNameController.text,
          );
          await state.syncData();
        }
      },
      height: 50,
      rightIconPath: "assets/icons/edit.svg",
      borderColor: theme.cardBackground,
      focusedBorderColor: theme.primaryPurple,
      fontSize: _fontSize,
    );
  }

  Widget _buildPreferencesSection(AppState appState) {
    final theme = appState.currentTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            AppLocalizations.of(context)!.walletPagePreferencesTitle,
            style: theme.bodyLarge.copyWith(
              color: theme.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Column(
            children: _buildPreferenceItems(appState),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPreferenceItems(AppState appState) {
    final theme = appState.currentTheme;
    final items = _getPreferenceItems(appState);
    final List<Widget> widgets = [];

    if (_biometricsAvailable && _authMethods.first != "none") {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: BiometricSwitch(
            biometricType: _authMethods.first,
            value: "none" != appState.wallet?.authType,
            disabled: false,
            isLoading: _isBiometricLoading,
            onChanged: (value) => _handleToggleBiometric(value, appState),
          ),
        ),
      );

      if (items.isNotEmpty) {
        widgets.add(Divider(
          height: 1,
          color: theme.textSecondary.withValues(alpha: 0.1),
        ));
      }
    }

    for (var i = 0; i < items.length; i++) {
      widgets.add(_buildPreferenceItem(theme, items[i], appState));
      if (i < items.length - 1) {
        widgets.add(Divider(
          height: 1,
          color: theme.textSecondary.withValues(alpha: 0.1),
        ));
      }
    }

    return widgets;
  }

  Widget _buildPreferenceItem(
      AppTheme theme, WalletPreferenceItem item, AppState appState) {
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
                style: theme.bodyLarge.copyWith(
                  color: theme.textPrimary,
                ),
              ),
            ),
            if (item.hasSwitch)
              Switch(
                value: item.switchValue,
                onChanged: item.switchEnabled ? item.onChanged : null,
                activeThumbColor: theme.primaryPurple,
              )
            else if (item.title ==
                AppLocalizations.of(context)!.walletPageManageConnections)
              Text(
                '${appState.connections.length}',
                style: theme.bodyLarge.copyWith(
                  color: theme.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveWalletButton(AppState appState) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        showDeleteWalletModal(context: context, state: appState);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.walletPageDeleteWallet,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: Colors.red,
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w500,
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
    showSecretRecoveryModal(context: context, theme: theme);
  }

  bool _isBitcoinWallet(AppState appState) {
    return appState.account?.slip44 == kBitcoinlip44;
  }

  Widget _buildBipPurposeSection(AppState appState) {
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            l10n.bipPurposeSetupPageTitle,
            style: theme.bodyLarge.copyWith(
              color: theme.textSecondary,
            ),
          ),
        ),
        BipPurposeSelector(
          selectedIndex: _selectedBipPurposeIndex,
          onSelect: (index) => _handleBipPurposeChange(index, appState),
          disabled: false,
        ),
      ],
    );
  }
}
