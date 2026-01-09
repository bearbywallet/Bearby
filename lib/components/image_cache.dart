import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/src/rust/api/cache.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class AsyncImage extends StatefulWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const AsyncImage({
    super.key,
    this.url,
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
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
    if (widget.url != null && widget.url!.isNotEmpty) {
      _loadImage();
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void didUpdateWidget(AsyncImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.url != oldWidget.url) {
      if (widget.url != null && widget.url!.isNotEmpty) {
        _cachedImageBytes = null;
        _cachedImageExt = null;
        _loadImage();
      } else {
        setState(() {
          _cachedImageBytes = null;
          _cachedImageExt = null;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadImage() async {
    if (_cachedImageBytes != null && _cachedImageExt != null) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final (bytes, ext) = await getImageBytes(
        dir: _appState.cahceDir,
        url: widget.url!,
      );

      if (!mounted) return;

      setState(() {
        _cachedImageBytes = bytes;
        _cachedImageExt = ext;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cachedImageBytes = null;
        _cachedImageExt = null;
        _isLoading = false;
        _hasError = true;
      });

      debugPrint('Error loading image from ${widget.url}: $e');
    }
  }

  Widget _buildImage(AppTheme theme) {
    if (_hasError || _cachedImageBytes == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.errorWidget ??
            Center(
              child: Container(
                width: widget.width ?? 24,
                height: widget.height ?? 24,
                decoration: BoxDecoration(
                  color: theme.danger.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.broken_image,
                  size: (widget.width ?? 24) * 0.6,
                  color: theme.danger,
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
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Center(
              child: Container(
                width: widget.width ?? 24,
                height: widget.height ?? 24,
                decoration: BoxDecoration(
                  color: theme.danger.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.broken_image,
                  size: (widget.width ?? 24) * 0.6,
                  color: theme.danger,
                ),
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;

    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.loadingWidget ??
            Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primaryPurple,
              ),
            ),
      );
    }

    return _buildImage(theme);
  }
}
