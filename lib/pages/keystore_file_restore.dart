import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zilpay/components/biometric_switch.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/src/rust/api/auth.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/services/device.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zilpay/theme/app_theme.dart';

class RestoreKeystoreFilePage extends StatefulWidget {
  const RestoreKeystoreFilePage({super.key});

  @override
  State<RestoreKeystoreFilePage> createState() =>
      _RestoreKeystoreFilePageState();
}

class _RestoreKeystoreFilePageState extends State<RestoreKeystoreFilePage>
    with StatusBarMixin {
  static const List<int> _signature = [
    90, 73, 76, 80, 65, 89, 95, 66, 65, 67, 75, 85, 80
  ];

  bool _isLoading = true;
  bool _isProcessing = false;
  String _errorMessage = '';
  List<KeystoreFile> _backupFiles = [];
  KeystoreFile? _selectedFile;
  List<String> _authMethods = [];
  bool _useDeviceAuth = true;
  bool _obscurePassword = true;

  late AppState _appState;
  final TextEditingController _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();

  bool get _canInteract => !_isProcessing;
  bool get _canRestore =>
      _selectedFile != null &&
      _passwordController.text.isNotEmpty &&
      _canInteract;

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
    _loadBackupFiles();
    _checkAuthMethods();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthMethods() async {
    try {
      final methods = await getBiometricType();
      if (mounted) {
        setState(() => _authMethods = methods);
      }
    } catch (e) {
      debugPrint("Error checking auth methods: $e");
      if (mounted) {
        setState(() => _authMethods = []);
      }
    }
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
      final docDir = await getApplicationDocumentsDirectory();

      await _loadFilesFromDirectory(tempDir.path, files);
      await _loadFilesFromDirectory(docDir.path, files);

      if (Platform.isAndroid) {
        await _loadFilesFromDirectory('/storage/emulated/0/Download', files);
      }

      if (mounted) {
        setState(() {
          _backupFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadFilesFromDirectory(
      String dirPath, List<KeystoreFile> files) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;

      final dirFiles = dir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.zp'));

      for (final file in dirFiles) {
        try {
          final keystoreFile = await _parseKeystoreFile(file);
          if (keystoreFile != null) {
            files.add(keystoreFile);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<KeystoreFile?> _parseKeystoreFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final isValidLength = bytes.length >= _signature.length + 1;

      if (!isValidLength) {
        return _createKeystoreFile(file, isValid: false);
      }

      final signatureBytes = bytes.sublist(0, _signature.length);
      final signatureMatches = _compareByteList(
        signatureBytes,
        Uint8List.fromList(_signature),
      );

      int? version;
      if (signatureMatches) {
        version = bytes[_signature.length];
      }

      return _createKeystoreFile(
        file,
        isValid: signatureMatches,
        version: version,
      );
    } catch (e) {
      return null;
    }
  }

  KeystoreFile _createKeystoreFile(
    File file, {
    required bool isValid,
    int? version,
  }) {
    return KeystoreFile(
      file: file,
      fileName: file.path.split('/').last,
      filePath: file.path,
      lastModified: file.lastModifiedSync(),
      isValid: isValid,
      version: version,
    );
  }

  bool _compareByteList(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _selectBackupFile(KeystoreFile file) {
    if (!_canInteract) return;

    setState(() {
      _selectedFile = file;
      _errorMessage = '';
    });
  }

  Future<void> _openFilePicker() async {
    if (!_canInteract) return;

    try {
      final l10n = AppLocalizations.of(context)!;
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.isEmpty || result.files.first.path == null) {
        return;
      }

      final path = result.files.first.path!;
      if (!path.toLowerCase().endsWith('.zp')) {
        setState(() => _errorMessage = l10n.keystoreRestoreExtError);
        return;
      }

      final file = File(path);
      final keystoreFile = await _parseKeystoreFile(file);

      if (keystoreFile == null) {
        setState(() => _errorMessage = 'Failed to parse keystore file');
        return;
      }

      if (mounted) {
        setState(() {
          if (!_backupFiles.any((f) => f.filePath == keystoreFile.filePath)) {
            _backupFiles.add(keystoreFile);
          }
          _selectedFile = keystoreFile;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  void _clearError() {
    if (_errorMessage.isNotEmpty) {
      setState(() => _errorMessage = '');
    }
  }

  Future<void> _restoreFromKeystore() async {
    if (!_canRestore) return;

    final l10n = AppLocalizations.of(context)!;

    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = l10n.passwordSetupPageShortPasswordError);
      _passwordInputKey.currentState?.shake();
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    _btnController.start();

    try {
      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();
      final biometricType =
          (_useDeviceAuth && _authMethods.isNotEmpty) ? _authMethods[0] : "none";
      final fileBytes = await _selectedFile!.file.readAsBytes();

      await restoreFromKeystore(
        keystoreBytes: fileBytes,
        deviceIndicators: identifiers,
        password: _passwordController.text,
        biometricType: biometricType,
      );

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
          _isProcessing = false;
        });
        _btnController.error();
        await Future.delayed(const Duration(seconds: 1));
        _btnController.reset();
      }
    }
  }

  String _formatDate(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;

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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title: l10n.restoreWalletOptionsKeyStoreTitle,
                  onBackPressed:
                      _canInteract ? () => Navigator.pop(context) : () {},
                  actionIcon: SvgPicture.asset(
                    'assets/icons/reload.svg',
                    width: 24,
                    height: 24,
                    colorFilter:
                        ColorFilter.mode(theme.textPrimary, BlendMode.srcIn),
                  ),
                  onActionPressed: _canInteract ? _loadBackupFiles : null,
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
                            disabled: !_canInteract || _selectedFile == null,
                            obscureText: _obscurePassword,
                            rightIconPath: _obscurePassword
                                ? "assets/icons/close_eye.svg"
                                : "assets/icons/open_eye.svg",
                            onRightIconTap: _canInteract
                                ? () => setState(() => _obscurePassword = !_obscurePassword)
                                : null,
                            onChanged: _canInteract
                                ? (value) {
                                    _clearError();
                                    setState(() {});
                                  }
                                : null,
                            onSubmitted: _canRestore ? (_) => _restoreFromKeystore() : null,
                          ),
                        ),
                        if (_authMethods.isNotEmpty)
                          BiometricSwitch(
                            biometricType: _authMethods.first,
                            value: _useDeviceAuth,
                            disabled: !_canInteract,
                            onChanged: (value) =>
                                setState(() => _useDeviceAuth = value),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: RoundedLoadingButton(
                            color: theme.primaryPurple,
                            valueColor: theme.buttonText,
                            controller: _btnController,
                            onPressed: _canRestore ? _restoreFromKeystore : () {},
                            child: Text(
                              l10n.keystoreRestoreButton,
                              style: theme.titleSmall,
                            ),
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _errorMessage,
                              style:
                                  theme.bodyText2.copyWith(color: theme.danger),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        _buildFileListHeader(theme, l10n),
                        _buildFileList(theme, l10n),
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

  Widget _buildFileListHeader(AppTheme theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.keystoreRestoreFilesTitle,
            style: theme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          IconButton(
            onPressed: _canInteract ? _openFilePicker : null,
            icon: SvgPicture.asset(
              'assets/icons/plus.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                  _canInteract ? theme.textPrimary : theme.textSecondary,
                  BlendMode.srcIn),
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(AppTheme theme, AppLocalizations l10n) {
    if (_isLoading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(color: theme.primaryPurple),
        ),
      );
    }

    if (_backupFiles.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            l10n.keystoreRestoreNoFile,
            style: theme.bodyLarge.copyWith(
              color: theme.textSecondary,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _backupFiles.length,
        itemBuilder: (context, index) {
          final file = _backupFiles[index];
          final isSelected = _selectedFile?.filePath == file.filePath;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KeystoreFileCard(
              file: file,
              isSelected: isSelected,
              formattedDate: _formatDate(file.lastModified),
              theme: theme,
              disabled: !_canInteract,
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
    super.key,
    required this.file,
    required this.isSelected,
    required this.formattedDate,
    required this.theme,
    required this.onPressed,
    this.disabled = false,
  });

  String get _fileSize {
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
                        style: theme.bodyLarge.copyWith(
                          color: disabled
                              ? theme.textSecondary
                              : theme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: theme.labelSmall.copyWith(
                              color: theme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fileSize,
                            style: theme.labelSmall.copyWith(
                              color: theme.textSecondary,
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
                      style: theme.labelSmall.copyWith(
                        color: disabled
                            ? theme.textSecondary
                            : theme.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              file.filePath,
              style: theme.labelSmall.copyWith(
                color: theme.textSecondary,
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
    super.key,
    required this.child,
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    this.disabled = false,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.disabled) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.disabled) {
      setState(() => _isPressed = false);
      widget.onPressed();
    }
  }

  void _handleTapCancel() {
    if (!widget.disabled) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.disabled ? null : _handleTapDown,
      onTapUp: widget.disabled ? null : _handleTapUp,
      onTapCancel: widget.disabled ? null : _handleTapCancel,
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
