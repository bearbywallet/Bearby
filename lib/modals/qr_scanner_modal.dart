import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

void showQRScannerModal({
  required BuildContext context,
  required Function(String) onScanned,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.94,
        child: _QRScannerModalContent(onScanned: onScanned),
      );
    },
  );
}

class _QRScannerModalContent extends StatefulWidget {
  final Function(String) onScanned;

  const _QRScannerModalContent({required this.onScanned});

  @override
  State<_QRScannerModalContent> createState() => _QRScannerModalContentState();
}

class _QRScannerModalContentState extends State<_QRScannerModalContent>
    with WidgetsBindingObserver {
  late final MobileScannerController controller;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const Duration _scanCooldown = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _requestCameraPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted) {
          unawaited(controller.start());
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(controller.stop());
        break;
      default:
        break;
    }
  }

  Future<void> _requestCameraPermission() async {
    await Permission.camera.request();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!mounted) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    final now = DateTime.now();

    if (_lastScannedCode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < _scanCooldown) {
      return;
    }

    _lastScannedCode = code;
    _lastScanTime = now;

    widget.onScanned(code);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
      ),
      child: Column(
        children: [
          _buildHeader(theme, l10n),
          const SizedBox(height: 20),
          Expanded(child: _buildScannerArea(theme, l10n)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader(AppTheme theme, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.modalBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.qrScannerModalContentTitle,
                style: theme.titleMedium.copyWith(color: theme.textPrimary),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: SvgPicture.asset(
                  'assets/icons/close.svg',
                  width: 24,
                  height: 24,
                  colorFilter:
                      ColorFilter.mode(theme.textPrimary, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScannerArea(AppTheme theme, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.width * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: MobileScanner(
              controller: controller,
              onDetect: _onBarcodeDetected,
              fit: BoxFit.cover,
              errorBuilder: (context, error) =>
                  _buildErrorView(error, theme, l10n),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildTorchButton(theme),
      ],
    );
  }

  Widget _buildTorchButton(AppTheme theme) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized ||
            state.torchState == TorchState.unavailable) {
          return const SizedBox(height: 48);
        }

        return IconButton(
          iconSize: 32,
          icon: SvgPicture.asset(
            state.torchState == TorchState.on
                ? 'assets/icons/torch_on.svg'
                : 'assets/icons/torch_off.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(theme.textPrimary, BlendMode.srcIn),
          ),
          onPressed: () => controller.toggleTorch(),
        );
      },
    );
  }

  Widget _buildErrorView(
      MobileScannerException error, AppTheme theme, AppLocalizations l10n) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.qrScannerModalContentCameraInitError,
                textAlign: TextAlign.center,
                style: theme.bodyLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
