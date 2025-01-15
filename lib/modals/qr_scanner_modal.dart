import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
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
    enableDrag: false,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _QRScannerModalContent(
            onScanned: onScanned,
          ),
        ),
      );
    },
  );
}

class _QRScannerModalContent extends StatefulWidget {
  final Function(String) onScanned;

  const _QRScannerModalContent({
    required this.onScanned,
  });

  @override
  State<_QRScannerModalContent> createState() => _QRScannerModalContentState();
}

class _QRScannerModalContentState extends State<_QRScannerModalContent> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;
  bool isLoading = true;
  String? errorMessage;
  PermissionStatus? permissionStatus;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint('Initializing camera...');

      // Сначала проверяем текущий статус
      var status = await Permission.camera.status;
      debugPrint('Current camera status: $status');

      if (!status.isGranted) {
        // На iOS сначала проверяем, доступно ли ограниченное разрешение
        if (status.isLimited) {
          debugPrint('Limited permission available, requesting...');
          status = await Permission.camera.request();
        } else {
          // Пробуем запросить полное разрешение
          debugPrint('Requesting full permission...');
          status = await Permission.camera.request();

          // Если после запроса всё ещё нет разрешения, пробуем ещё раз
          if (!status.isGranted) {
            debugPrint('Permission not granted, trying limited...');
            await Future.delayed(const Duration(milliseconds: 500));
            status = await Permission.camera.request();
          }
        }
      }

      debugPrint('Final permission status: $status');
      setState(() {
        permissionStatus = status;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      setState(() {
        errorMessage = 'Failed to initialize camera: $e';
        isLoading = false;
      });
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen(
      (scanData) {
        if (scanData.code != null && isScanning) {
          setState(() => isScanning = false);
          widget.onScanned(scanData.code!);
          Navigator.pop(context);
        }
      },
      onError: (error) {
        debugPrint('Error during scanning: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanning error: $error')),
        );
      },
    );
  }

  Widget _buildPermissionContent(AppTheme theme) {
    if (permissionStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (permissionStatus!.isPermanentlyDenied || permissionStatus!.isDenied) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Camera Access Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please enable camera access in your device settings',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              debugPrint('Opening app settings...');
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _initializeCamera,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (permissionStatus!.isDenied) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Camera Permission Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We need camera access to scan QR codes',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeCamera,
            child: const Text('Grant Permission'),
          ),
        ],
      );
    }

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: theme.primaryPurple,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: MediaQuery.of(context).size.width * 0.7,
      ),
      onPermissionSet: (ctrl, p) {
        if (!p) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission denied')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan QR Code',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(child: Text(errorMessage!))
                        : _buildPermissionContent(theme),
              ),
            ),
          ),
          if (permissionStatus?.isGranted ?? false)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 16),
              child: Text(
                'Align QR code within the frame',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
