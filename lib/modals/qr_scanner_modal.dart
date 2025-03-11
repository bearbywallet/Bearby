import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

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
  MobileScannerController? controller;
  bool hasError = false;
  String errorMessage = '';
  bool isPermissionGranted = false;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();

    if (status.isGranted) {
      setState(() {
        isPermissionGranted = true;
      });
      _initializeScanner();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        hasError = true;
        errorMessage = 'Camera permission permanently denied';
      });
      _initializeScanner();
    } else {
      setState(() {
        hasError = true;
        errorMessage = 'Camera permission denied';
      });
      _initializeScanner();
    }
  }

  Future<void> _initializeScanner() async {
    try {
      controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      setState(() {
        isCameraInitialized = true;
        hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        hasError = true;
        errorMessage = 'Camera initialization error: ${e.toString()}';
      });
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await controller?.toggleTorch();
      setState(() {});
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to toggle torch: ${e.toString()}';
      });
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        controller?.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        controller?.stop();
        break;
      default:
        break;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        widget.onScanned(code);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.cardBackground.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          const SizedBox(height: 20),
          hasError ? _buildErrorView(theme) : _buildScannerView(theme),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader(AppTheme theme) {
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
                'Scan',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
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

  Widget _buildErrorView(AppTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/camera.svg',
              width: 64,
              height: 64,
              colorFilter:
                  ColorFilter.mode(theme.secondaryPurple, BlendMode.srcIn),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Permission Required',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Open Settings',
              textColor: theme.buttonText,
              backgroundColor: theme.secondaryPurple,
              onPressed: _openAppSettings,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _requestCameraPermission,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: theme.secondaryPurple,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView(AppTheme theme) {
    return Expanded(
      child: Column(
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
              child: controller != null && isCameraInitialized
                  ? MobileScanner(
                      controller: controller!,
                      onDetect: _onDetect,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: controller?.torchEnabled == true
                    ? SvgPicture.asset(
                        'assets/icons/torch_on.svg',
                        width: 32,
                        height: 32,
                        colorFilter: ColorFilter.mode(
                            theme.textPrimary, BlendMode.srcIn),
                      )
                    : SvgPicture.asset(
                        'assets/icons/torch_off.svg',
                        width: 32,
                        height: 32,
                        colorFilter: ColorFilter.mode(
                            theme.textPrimary, BlendMode.srcIn),
                      ),
                onPressed: _toggleTorch,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
