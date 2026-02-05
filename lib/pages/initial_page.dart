import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/state/app_state.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> with StatusBarMixin {
  bool _isLoading = true;
  bool _isRestoreAvailable = false;
  String? _vaultJson;
  String? _accountsJson;

  @override
  void initState() {
    super.initState();
    _loadingOldStorage();
  }

  Future<void> _loadingOldStorage() async {
    try {
      final (vaultJson, accountsJson) = Platform.isAndroid
          ? await loadOldDatabaseAndroid()
          : Platform.isIOS
              ? await loadOldDatabaseIos(
                  baseDir: (await getApplicationSupportDirectory()).path)
              : (null, null);

      if (mounted) {
        setState(() {
          _vaultJson = vaultJson;
          _accountsJson = accountsJson;
          _isRestoreAvailable = vaultJson != null && accountsJson != null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isRestoreAvailable = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTheme() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final newAppearance = switch (appState.state.appearances) {
      0 => PlatformDispatcher.instance.platformBrightness == Brightness.dark
          ? 2
          : 1,
      1 => 2,
      _ => 1,
    };
    await appState.setAppearancesCode(
        newAppearance, appState.state.abbreviatedNumber);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth < 600 ? double.infinity : 600.0;

    return Scaffold(
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
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/moon_sun.svg',
                          width: 30,
                          height: 30,
                          colorFilter: ColorFilter.mode(
                              theme.textPrimary, BlendMode.srcIn),
                        ),
                        onPressed: _toggleTheme,
                      ),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/language.svg',
                          width: 34,
                          height: 34,
                          colorFilter: ColorFilter.mode(
                              theme.textPrimary, BlendMode.srcIn),
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/language'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/little_dragons.svg',
                      width: 400,
                      height: 400,
                      colorFilter:
                          ColorFilter.mode(theme.textPrimary, BlendMode.srcIn),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 32),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              theme.primaryPurple),
                        )
                      : CustomButton(
                          textColor: theme.buttonText,
                          backgroundColor: theme.primaryPurple,
                          text: _isRestoreAvailable
                              ? l10n.initialPagerestoreZilPay
                              : l10n.initialPagegetStarted,
                          onPressed: () => Navigator.of(context).pushNamed(
                            _isRestoreAvailable
                                ? '/rk_restore'
                                : '/net_setup',
                            arguments: _isRestoreAvailable
                                ? {
                                    'vaultJson': _vaultJson,
                                    'accountsJson': _accountsJson
                                  }
                                : null,
                          ),
                          borderRadius: 30.0,
                          height: 56.0,
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
