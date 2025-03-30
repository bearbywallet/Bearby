import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';
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

  final TextEditingController _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
  }

  bool _compareByteList(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _selectBackupFile(KeystoreFile file) {
    setState(() {
      _selectedFile = file;
      _errorMessage = '';
    });
  }

  Future<void> _openFilePicker() async {
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

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // On success, navigate or show success message
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _disabled = false;
        });
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
              onBackPressed: () => Navigator.pop(context),
              actionIcon: SvgPicture.asset(
                'assets/icons/reload.svg',
                width: 24,
                height: 24,
                colorFilter:
                    ColorFilter.mode(theme.textPrimary, BlendMode.srcIn),
              ),
              onActionPressed: _loadBackupFiles,
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
                        disabled: _disabled,
                        obscureText: _obscurePassword,
                        rightIconPath: _obscurePassword
                            ? "assets/icons/close_eye.svg"
                            : "assets/icons/open_eye.svg",
                        onRightIconTap: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        onChanged: (value) {
                          setState(() {
                            _password = value;
                            if (_errorMessage.isNotEmpty) {
                              _errorMessage = '';
                            }
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryPurple,
                          foregroundColor: theme.buttonText,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          disabledBackgroundColor:
                              theme.primaryPurple.withValues(alpha: 0.5),
                          disabledForegroundColor:
                              theme.buttonText.withValues(alpha: 0.7),
                        ),
                        onPressed: (_password.isNotEmpty &&
                                _selectedFile != null &&
                                !_disabled)
                            ? _restoreFromKeystore
                            : null,
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
              colorFilter: ColorFilter.mode(theme.textPrimary, BlendMode.srcIn),
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

  KeystoreFile({
    required this.file,
    required this.fileName,
    required this.filePath,
    required this.lastModified,
    required this.isValid,
    this.version,
  });
}

class KeystoreFileCard extends StatelessWidget {
  final KeystoreFile file;
  final bool isSelected;
  final String formattedDate;
  final AppTheme theme;
  final VoidCallback onPressed;

  const KeystoreFileCard({
    Key? key,
    required this.file,
    required this.isSelected,
    required this.formattedDate,
    required this.theme,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onPressed: onPressed,
      backgroundColor: isSelected
          ? theme.primaryPurple.withValues(alpha: 0.1)
          : theme.cardBackground,
      borderColor: isSelected
          ? theme.primaryPurple
          : theme.secondaryPurple.withValues(alpha: 0.3),
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
                    file.isValid ? theme.primaryPurple : theme.textSecondary,
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
                          color: theme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (file.isValid)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'v${file.version ?? "?"}',
                      style: TextStyle(
                        color: theme.primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  'assets/icons/right_arrow.svg',
                  width: 16,
                  height: 16,
                  colorFilter:
                      ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
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

  const PressableCard({
    Key? key,
    required this.child,
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          margin: EdgeInsets.zero,
          color: widget.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: widget.borderColor,
              width: 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
