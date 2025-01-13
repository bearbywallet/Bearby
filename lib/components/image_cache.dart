import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
  }

  Future<(Uint8List, String)> _loadImage() async {
    try {
      final (bytes, ext) = await getImageBytes(
        dir: _appState.cahceDir,
        url: widget.url,
      );
      return (bytes, ext);
    } catch (e) {
      debugPrint('Error loading image: $e');
      throw Exception('Failed to load image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

    return FutureBuilder<(Uint8List, String)>(
      future: _loadImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: widget.loadingWidget ??
                const Center(
                  child: CircularProgressIndicator(),
                ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
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

        final (bytes, format) = snapshot.data!;

        if (format == 'svg') {
          return SvgPicture.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit ?? BoxFit.cover,
          );
        }

        return Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      },
    );
  }
}
