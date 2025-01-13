import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/src/rust/api/cache.dart';
import 'package:zilpay/state/app_state.dart';

class AsyncImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const AsyncImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<AsyncImage> createState() => _AsyncImageState();
}

class _AsyncImageState extends State<AsyncImage> {
  late final AppState _appState;
  Uint8List? _cachedImageBytes;
  String? _cachedImageExt;

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (_cachedImageBytes != null && _cachedImageExt != null) return;

    try {
      final (bytes, ext) = await getImageBytes(
        dir: _appState.cahceDir,
        url: widget.url,
      );

      if (mounted) {
        setState(() {
          _cachedImageBytes = bytes;
          _cachedImageExt = ext;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedImageBytes = null;
          _cachedImageExt = null;
        });
      }
    }
  }

  Widget _buildImage() {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

    if (_cachedImageBytes == null || _cachedImageExt == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.errorWidget ??
            Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
      );
    }

    if (_cachedImageExt == 'svg') {
      return SvgPicture.memory(
        _cachedImageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.cover,
      );
    }

    return Image.memory(
      _cachedImageBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedImageBytes == null && _cachedImageExt == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.loadingWidget ??
            const Center(
              child: CircularProgressIndicator(),
            ),
      );
    }

    return _buildImage();
  }
}
