import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

void showQRScannerModal({
  required BuildContext context,
  required Function(String) onScanned,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.black,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: true,
    useSafeArea: false,
    barrierColor: Colors.black,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 1.0,
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
  bool _permissionError = false;
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
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    try {
      await Permission.camera.request();
    } on MissingPluginException {
      if (mounted) setState(() => _permissionError = true);
    } on PlatformException {
      if (mounted) setState(() => _permissionError = true);
    }
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

    HapticFeedback.selectionClick();
    widget.onScanned(code);
  }

  Future<void> _onPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    HapticFeedback.selectionClick();
    Navigator.pop(context);
    widget.onScanned(text);
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

    return Material(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_permissionError)
            _buildErrorView(null, theme, l10n)
          else
            MobileScanner(
              controller: controller,
              onDetect: _onBarcodeDetected,
              fit: BoxFit.cover,
              errorBuilder: (context, error) =>
                  _buildErrorView(error, theme, l10n),
            ),
          if (!_permissionError) ...[
            IgnorePointer(
              child: CustomPaint(
                painter: _ViewfinderPainter(color: theme.primaryPurple),
              ),
            ),
            const IgnorePointer(child: _ScanLine()),
          ],
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: _GlassButton(
                    theme: theme,
                    onPressed: () => Navigator.pop(context),
                    child: SvgPicture.asset(
                      'assets/icons/close.svg',
                      width: 22,
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                if (!_permissionError) ...[
                  Positioned(
                    bottom: 24,
                    left: 16,
                    child: _GlassButton(
                      theme: theme,
                      onPressed: _onPaste,
                      child: SvgPicture.asset(
                        'assets/icons/copy.svg',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 16,
                    child: _TorchButton(
                      controller: controller,
                      theme: theme,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(
      MobileScannerException? error, AppTheme theme, AppLocalizations l10n) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            l10n.qrScannerModalContentCameraInitError,
            textAlign: TextAlign.center,
            style: theme.bodyLarge.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;

  _ViewfinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.7;
    final left = (size.width - side) / 2;
    final top = (size.height - side) / 2;
    final rect = Rect.fromLTWH(left, top, side, side);
    final radius = const Radius.circular(20);

    final overlayPath = Path()..addRect(Offset.zero & size);
    final holePath = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
    final dimPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      holePath,
    );
    canvas.drawPath(
      dimPath,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    final bracketLen = side * 0.12;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final r = rect;
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top + bracketLen)
        ..lineTo(r.left, r.top)
        ..lineTo(r.left + bracketLen, r.top),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.right - bracketLen, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, r.top + bracketLen),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.right, r.bottom - bracketLen)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.right - bracketLen, r.bottom),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.left + bracketLen, r.bottom)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.left, r.bottom - bracketLen),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter old) => old.color != color;
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _ScanLinePainter(
          progress: _controller.value,
          color: theme.primaryPurple,
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.7;
    final left = (size.width - side) / 2;
    final top = (size.height - side) / 2;
    final inset = 12.0;
    final yMin = top + inset;
    final yMax = top + side - inset;
    final y = yMin + (yMax - yMin) * progress;

    final beamHeight = 24.0;
    final beamRect = Rect.fromLTWH(
      left + inset,
      y - beamHeight / 2,
      side - inset * 2,
      beamHeight,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(beamRect);
    canvas.drawRect(beamRect, paint);

    canvas.drawLine(
      Offset(left + inset, y),
      Offset(left + side - inset, y),
      Paint()
        ..color = color
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) =>
      old.progress != progress || old.color != color;
}

class _GlassButton extends StatefulWidget {
  final AppTheme theme;
  final VoidCallback onPressed;
  final Widget child;

  const _GlassButton({
    required this.theme,
    required this.onPressed,
    required this.child,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildPressable(
      onTap: widget.onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.theme.cardBackground.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.theme.textSecondary.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _TorchButton extends StatelessWidget {
  final MobileScannerController controller;
  final AppTheme theme;

  const _TorchButton({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (!state.isInitialized ||
            state.torchState == TorchState.unavailable) {
          return const SizedBox(width: 48, height: 48);
        }
        final on = state.torchState == TorchState.on;
        return _GlassButton(
          theme: theme,
          onPressed: () => controller.toggleTorch(),
          child: SvgPicture.asset(
            on ? 'assets/icons/torch_on.svg' : 'assets/icons/torch_off.svg',
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              on ? theme.primaryPurple : Colors.white,
              BlendMode.srcIn,
            ),
          ),
        );
      },
    );
  }
}
