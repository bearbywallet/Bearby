import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/src/rust/api/qrcode.dart';
import 'package:zilpay/src/rust/models/qrcode.dart';
import 'package:zilpay/state/app_state.dart';

enum EyeShape {
  square(0),
  circle(1);

  final int value;
  const EyeShape(this.value);
}

enum DataModuleShape {
  square(0),
  circle(1);

  final int value;
  const DataModuleShape(this.value);
}

class AsyncQRcode extends StatefulWidget {
  final int size;
  final String data;
  final EyeShape eyeShape;
  final bool gapless;
  final Color color;
  final DataModuleShape dataModuleShape;
  final BoxFit? fit;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const AsyncQRcode({
    super.key,
    required this.data,
    required this.color,
    this.size = 200,
    this.gapless = false,
    this.eyeShape = EyeShape.circle,
    this.dataModuleShape = DataModuleShape.circle,
    this.fit = BoxFit.cover,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<AsyncQRcode> createState() => _AsyncQRcodeState();
}

class _AsyncQRcodeState extends State<AsyncQRcode> {
  late final AppState _appState;
  String? _svgString;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      QrConfigInfo config = QrConfigInfo(
        size: widget.size,
        gapless: widget.gapless,
        color: widget.color.value,
        eyeShape: widget.eyeShape.value,
        dataModuleShape: widget.dataModuleShape.value,
      );
      final svg = await genQrcode(data: widget.data, config: config);

      if (mounted) {
        setState(() {
          _svgString = svg;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _svgString = null;
          _hasError = true;
        });
      }
    }
  }

  Widget _buildImage() {
    if (_hasError) {
      return SizedBox(
        width: widget.size.toDouble(),
        height: widget.size.toDouble(),
        child: widget.errorWidget ??
            Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _appState.currentTheme.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
      );
    }

    return SvgPicture.string(
      _svgString!,
      width: widget.size.toDouble(),
      height: widget.size.toDouble(),
      fit: widget.fit ?? BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_svgString == null && !_hasError) {
      return SizedBox(
        width: widget.size.toDouble(),
        height: widget.size.toDouble(),
        child: widget.loadingWidget ??
            const Center(
              child: CircularProgressIndicator(),
            ),
      );
    }

    return _buildImage();
  }
}
