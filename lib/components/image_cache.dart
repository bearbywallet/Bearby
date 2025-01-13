import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class FastImage extends StatelessWidget {
  final Future<Uint8List> Function() loadImage;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const FastImage({
    super.key,
    required this.loadImage,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: loadImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: loadingWidget ??
                const Center(
                  child: CircularProgressIndicator(),
                ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: errorWidget ??
                const Center(
                  child: Icon(Icons.error_outline),
                ),
          );
        }

        return Image.memory(
          snapshot.data!,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}
