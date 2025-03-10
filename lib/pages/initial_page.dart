import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  bool _isLoading = true;
  bool _isRestoreAvailable = false;
  String? _vaultJson;
  String? _accountsJson;

  @override
  void initState() {
    super.initState();
    _loadingOldStorage();
  }

  void _loadingOldStorage() async {
    try {
      if (Platform.isAndroid) {
        final (vaultJson, accountsJson) = await loadOldDatabaseAndroid();
        setState(() {
          _vaultJson = vaultJson;
          _accountsJson = accountsJson;
          _isRestoreAvailable = true;
        });
      } else if (Platform.isIOS) {
        final appDocDir = await getApplicationSupportDirectory();
        final (vaultJson, accountsJson) =
            await loadOldDatabaseIos(baseDir: appDocDir.path);
        setState(() {
          _vaultJson = vaultJson;
          _accountsJson = accountsJson;
          _isRestoreAvailable = true;
        });
      }
    } catch (_) {
      setState(() {
        _isRestoreAvailable = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildButton(AppTheme theme) {
    if (_isLoading) {
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
      );
    } else if (_isRestoreAvailable) {
      return CustomButton(
        textColor: theme.buttonText,
        backgroundColor: theme.primaryPurple,
        text: "Restore ZilPay 1.0!",
        onPressed: () {
          Navigator.of(context).pushNamed(
            '/rk_restore',
            arguments: {
              'vaultJson': _vaultJson,
              'accountsJson': _accountsJson,
            },
          );
        },
      );
    } else {
      return CustomButton(
        textColor: theme.buttonText,
        backgroundColor: theme.primaryPurple,
        text: "Get Started",
        onPressed: () {
          Navigator.of(context).pushNamed('/new_wallet_options');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/moon_sun.svg',
                      colorFilter: ColorFilter.mode(
                        theme.textPrimary,
                        BlendMode.srcIn,
                      ),
                      width: 30.0,
                      height: 30.0,
                    ),
                    onPressed: () async {
                      final appState =
                          Provider.of<AppState>(context, listen: false);

                      switch (appState.state.appearances) {
                        case 0:
                          final Brightness systemBrightness =
                              PlatformDispatcher.instance.platformBrightness;
                          if (systemBrightness == Brightness.dark) {
                            await appState.setAppearancesCode(
                              2,
                              appState.state.abbreviatedNumber,
                            );
                          } else {
                            await appState.setAppearancesCode(
                              1,
                              appState.state.abbreviatedNumber,
                            );
                          }
                          break;
                        case 1:
                          await appState.setAppearancesCode(
                            2,
                            appState.state.abbreviatedNumber,
                          );
                          break;
                        case 2:
                          await appState.setAppearancesCode(
                            1,
                            appState.state.abbreviatedNumber,
                          );
                          break;
                      }
                    },
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/language.svg',
                      colorFilter:
                          ColorFilter.mode(theme.textPrimary, BlendMode.srcIn),
                      width: 34.0,
                      height: 34.0,
                    ),
                    onPressed: () {},
                    // onPressed: () =>
                    //     Navigator.of(context).pushNamed('/language'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/little_dragons.svg',
                  width: 400.0,
                  height: 400.0,
                  colorFilter: ColorFilter.mode(
                    theme.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
              child: _buildButton(theme),
            ),
          ],
        ),
      ),
    );
  }
}
