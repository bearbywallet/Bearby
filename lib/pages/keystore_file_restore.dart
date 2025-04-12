import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zilpay/components/biometric_switch.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/device.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zilpay/theme/app_theme.dart';

class RestoreKeystoreFilePage extends StatefulWidget {
  const RestoreKeystoreFilePage({super.key});

  @override
  State<RestoreKeystoreFilePage> createState() =>
      _RestoreKeystoreFilePageState();
}

class _RestoreKeystoreFilePageState extends State<RestoreKeystoreFilePage> {
  static const List<int> SIGNATURE = [
    90,
    73,
    76,
    80,
    65,
    89,
    95,
    66,
    65,
    67,
    75,
    85,
    80
  ];

  String _password = '';
  bool _disabled = false;
  String _errorMessage = '';
  bool _isLoading = true;
  List<KeystoreFile> _backupFiles = [];
  KeystoreFile? _selectedFile;

  final AuthService _authService = AuthService();
  late AuthGuard _authGuard;
  late AppState _appState;
  List<AuthMethod> _authMethods = [AuthMethod.none];
  bool _useDeviceAuth = true;

  final TextEditingController _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();

    _authGuard = Provider.of<AuthGuard>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);
    _checkAuthMethods();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthMethods() async {
    final methods = await _authService.getAvailableAuthMethods();
    setState(() {
      _authMethods = methods;
    });
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
      _backupFiles = [];
      _errorMessage = '';
    });

    try {
      final List<KeystoreFile> files = [];

      final tempDir = await getTemporaryDirectory();
      await _loadFilesFromDirectory(tempDir.path, files);

      final docDir = await getApplicationDocumentsDirectory();
      await _loadFilesFromDirectory(docDir.path, files);

      if (Platform.isAndroid) {
        await _loadFilesFromDirectory('/storage/emulated/0/Download', files);
      }

      setState(() {
        _backupFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadFilesFromDirectory(
      String dirPath, List<KeystoreFile> files) async {
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        final dirFiles = dir
            .listSync()
            .where((entity) => entity is File && entity.path.endsWith('.zp'))
            .map((entity) => entity as File);

        for (final file in dirFiles) {
          try {
            final keystoreFile = await _parseKeystoreFile(file);
            if (keystoreFile != null) {
              files.add(keystoreFile);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<KeystoreFile?> _parseKeystoreFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < SIGNATURE.length + 1) {
        return KeystoreFile(
          file: file,
          fileName: file.path.split('/').last,
          filePath: file.path,
          lastModified: file.lastModifiedSync(),
          isValid: false,
        );
      }

      final signatureBytes = bytes.sublist(0, SIGNATURE.length);
      final signatureMatches =
          _compareByteList(signatureBytes, Uint8List.fromList(SIGNATURE));

      int? version;
      if (signatureMatches && bytes.length > SIGNATURE.length) {
        version = bytes[SIGNATURE.length];
      }

      return KeystoreFile(
        file: file,
        fileName: file.path.split('/').last,
        filePath: file.path,
        lastModified: file.lastModifiedSync(),
        isValid: signatureMatches,
        version: version,
      );
    } catch (e) {
      return null;
    }
  }

  bool _compareByteList(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _selectBackupFile(KeystoreFile file) {
    if (_disabled) return;

    setState(() {
      _selectedFile = file;
      _errorMessage = '';
    });
  }

  Future<void> _openFilePicker() async {
    if (_disabled) return;

    try {
      final l10n = AppLocalizations.of(context)!;
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        final path = result.files.first.path!;
        if (path.toLowerCase().endsWith('.zp')) {
          try {
            final file = File(path);
            final keystoreFile = await _parseKeystoreFile(file);

            if (keystoreFile != null) {
              setState(() {
                if (!_backupFiles
                    .any((f) => f.filePath == keystoreFile.filePath)) {
                  _backupFiles.add(keystoreFile);
                }
                _selectedFile = keystoreFile;
                _errorMessage = '';
              });
            }
          } catch (e) {
            setState(() => _errorMessage = e.toString());
          }
        } else {
          setState(() => _errorMessage = l10n.keystoreRestoreExtError);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  Future<void> _restoreFromKeystore() async {
    setState(() {
      _disabled = true;
      _errorMessage = '';
    });

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.passwordSetupPageShortPasswordError;
        _disabled = false;
      });
      _passwordInputKey.currentState?.shake();
      _btnController.reset();
      return;
    }

    try {
      _btnController.start();

      if (_useDeviceAuth) {
        final authenticated = await _authService.authenticate(
          allowPinCode: true,
          reason: AppLocalizations.of(context)!.passwordSetupPageAuthReason,
        );
        setState(() => _useDeviceAuth = authenticated);
        if (!authenticated) {
          setState(() {
            _disabled = false;
          });
          _btnController.reset();
          return;
        }
      }

      DeviceInfoService device = DeviceInfoService();
      List<String> identifiers = await device.getDeviceIdentifiers();

      AuthMethod biometricType = AuthMethod.none;
      if (_useDeviceAuth) {
        biometricType = _authMethods[0];
      }

      final fileBytes = await _selectedFile!.file.readAsBytes();
      final (String, String) session = await restoreFromKeystore(
        keystoreBytes: fileBytes,
        deviceIndicators: identifiers,
        password: _passwordController.text,
        biometricType: biometricType.name,
      );

      if (_useDeviceAuth) {
        await _authGuard.setSession(session.$2, session.$1);
      }

      await _appState.syncData();
      await _appState.startTrackHistoryWorker();

      _appState.setSelectedWallet(_appState.wallets.length - 1);

      _btnController.success();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _disabled = false;
        });
        _btnController.error();
        await Future.delayed(const Duration(seconds: 1));
        _btnController.reset();
      }
    }
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: l10n.restoreWalletOptionsKeyStoreTitle,
              onBackPressed: _disabled ? () {} : () => Navigator.pop(context),
              actionIcon: SvgPicture.asset(
                'assets/icons/reload.svg',
                width: 24,
                height: 24,
                colorFilter:
                    ColorFilter.mode(theme.textPrimary, BlendMode.srcIn),
              ),
              onActionPressed: _disabled ? null : _loadBackupFiles,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: SmartInput(
                        key: _passwordInputKey,
                        controller: _passwordController,
                        hint: l10n.keystorePasswordHint,
                        height: 50.0,
                        fontSize: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        focusedBorderColor: theme.primaryPurple,
                        disabled: _disabled || _selectedFile == null,
                        obscureText: _obscurePassword,
                        rightIconPath: _obscurePassword
                            ? "assets/icons/close_eye.svg"
                            : "assets/icons/open_eye.svg",
                        onRightIconTap: _disabled
                            ? null
                            : () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                        onChanged: _disabled
                            ? null
                            : (value) {
                                setState(() {
                                  _password = value;
                                  if (_errorMessage.isNotEmpty) {
                                    _errorMessage = '';
                                  }
                                });
                              },
                      ),
                    ),
                    BiometricSwitch(
                      biometricType: _authMethods.first,
                      value: _useDeviceAuth,
                      disabled: _disabled,
                      onChanged: (value) async {
                        setState(() => _useDeviceAuth = value);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: RoundedLoadingButton(
                        color: theme.primaryPurple,
                        valueColor: theme.buttonText,
                        controller: _btnController,
                        onPressed: (_password.isNotEmpty &&
                                _selectedFile != null &&
                                !_disabled)
                            ? _restoreFromKeystore
                            : () {},
                        successIcon: SvgPicture.asset(
                          'assets/icons/ok.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            theme.buttonText,
                            BlendMode.srcIn,
                          ),
                        ),
                        child: Text(
                          l10n.keystoreRestoreButton,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: theme.danger,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    _buildFileListHeader(theme),
                    _buildFileList(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListHeader(AppTheme theme) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.keystoreRestoreFilesTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          IconButton(
            onPressed: _disabled ? null : _openFilePicker,
            icon: SvgPicture.asset(
              'assets/icons/plus.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                  _disabled ? theme.textSecondary : theme.textPrimary,
                  BlendMode.srcIn),
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(AppTheme theme) {
    if (_isLoading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(color: theme.primaryPurple),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    return Expanded(
      child: _backupFiles.isEmpty
          ? Center(
              child: Text(
                l10n.keystoreRestoreNoFile,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _backupFiles.length,
              itemBuilder: (context, index) {
                final file = _backupFiles[index];
                final isSelected = _selectedFile?.filePath == file.filePath;
                final formattedDate = _getFormattedDate(file.lastModified);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KeystoreFileCard(
                    file: file,
                    isSelected: isSelected,
                    formattedDate: formattedDate,
                    theme: theme,
                    disabled: _disabled,
                    onPressed: () => _selectBackupFile(file),
                  ),
                );
              },
            ),
    );
  }
}

class KeystoreFile {
  final File file;
  final String fileName;
  final String filePath;
  final DateTime lastModified;
  final bool isValid;
  final int? version;
  final int fileSize;

  KeystoreFile({
    required this.file,
    required this.fileName,
    required this.filePath,
    required this.lastModified,
    required this.isValid,
    this.version,
  }) : fileSize = file.lengthSync();
}

class KeystoreFileCard extends StatelessWidget {
  final KeystoreFile file;
  final bool isSelected;
  final String formattedDate;
  final AppTheme theme;
  final bool disabled;
  final VoidCallback onPressed;

  const KeystoreFileCard({
    Key? key,
    required this.file,
    required this.isSelected,
    required this.formattedDate,
    required this.theme,
    required this.onPressed,
    this.disabled = false,
  }) : super(key: key);

  String _formatFileSize() {
    final sizeInKB = (file.fileSize / 1024).toStringAsFixed(1);
    return '$sizeInKB KB';
  }

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onPressed: disabled ? () {} : onPressed,
      backgroundColor: isSelected
          ? theme.primaryPurple.withValues(alpha: 0.1)
          : theme.cardBackground,
      borderColor: isSelected
          ? theme.primaryPurple
          : theme.secondaryPurple.withValues(alpha: 0.3),
      disabled: disabled,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/document.svg',
                  width: 32,
                  height: 32,
                  colorFilter: ColorFilter.mode(
                    file.isValid
                        ? (disabled ? theme.textSecondary : theme.primaryPurple)
                        : theme.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fileName,
                        style: TextStyle(
                          color: disabled
                              ? theme.textSecondary
                              : theme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatFileSize(),
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (file.isValid)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryPurple
                          .withValues(alpha: disabled ? 0.1 : 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'v${file.version ?? "?"}',
                      style: TextStyle(
                        color: disabled
                            ? theme.textSecondary
                            : theme.primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              file.filePath,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final bool disabled;

  const PressableCard({
    Key? key,
    required this.child,
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    this.disabled = false,
  }) : super(key: key);

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.disabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.disabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            },
      onTapCancel:
          widget.disabled ? null : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: (_isPressed && !widget.disabled) ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          margin: EdgeInsets.zero,
          color: widget.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: widget.disabled
                  ? widget.borderColor.withValues(alpha: 0.5)
                  : widget.borderColor,
              width: 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
