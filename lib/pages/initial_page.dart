import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/state/app_state.dart';

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
        // iOS-specific code
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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16.0,
              left: 16.0,
              child: IconButton(
                icon: Icon(Icons.wb_sunny, color: theme.textPrimary),
                onPressed: () {},
              ),
            ),
            Positioned(
              top: 16.0,
              right: 16.0,
              child: IconButton(
                icon: Icon(Icons.language, color: theme.textPrimary),
                onPressed: () => Navigator.of(context).pushNamed('/language'),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/imgs/zilpay.svg',
                    width: 120.0,
                    height: 120.0,
                    colorFilter:
                        ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primaryPurple))
                  else if (_isRestoreAvailable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryPurple,
                          foregroundColor: theme.textPrimary,
                          minimumSize: const Size(double.infinity, 56.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/rk_restore',
                            arguments: {
                              'vaultJson': _vaultJson,
                              'accountsJson': _accountsJson,
                            },
                          );
                        },
                        child: const Text("Restore ZilPay 1.0!",
                            style: TextStyle(fontSize: 18.0)),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryPurple,
                          foregroundColor: theme.textPrimary,
                          minimumSize: const Size(double.infinity, 56.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)),
                        ),
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed('/new_wallet_options');
                        },
                        child: const Text("Let's Start",
                            style: TextStyle(fontSize: 18.0)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
