import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zilpay/src/rust/models/connection.dart';

class Web3Utils {
  static Future<Map<String, Object?>> extractPageInfo(
      WebViewController controller) async {
    try {
      final descriptionResult = await controller.runJavaScriptReturningResult(
          'document.querySelector("meta[name=\'description\']")?.content || ""');
      final primaryColorResult = await controller.runJavaScriptReturningResult(
          'getComputedStyle(document.body).backgroundColor || "#FFFFFF"');

      final description = descriptionResult is String
          ? descriptionResult.replaceAll('"', '')
          : '';
      final primaryColor = primaryColorResult is String
          ? _parseColor(primaryColorResult)
          : '#FFFFFF';

      return {
        'description': description,
        'colors': {
          'primary': primaryColor,
          'secondary': null,
          'background': null,
          'text': null,
        },
      };
    } catch (e) {
      debugPrint('Failed to extract page info: $e');
      return {
        'description': '',
        'colors': {
          'primary': '#FFFFFF',
          'secondary': null,
          'background': null,
          'text': null
        },
      };
    }
  }

  static bool isDomainConnected(
      String currentDomain, List<ConnectionInfo> connections) {
    for (final conn in connections) {
      final connDomain = conn.domain;
      if (currentDomain == connDomain ||
          (currentDomain.endsWith('.$connDomain') &&
              currentDomain.split('.').length ==
                  connDomain.split('.').length + 1)) {
        return true;
      }
    }
    return false;
  }

  static String _parseColor(String color) {
    if (color.startsWith('rgb')) {
      final rgb = color
          .replaceAll(RegExp(r'[^0-9,]'), '')
          .split(',')
          .map(int.parse)
          .toList();
      return '#${rgb[0].toRadixString(16).padLeft(2, '0')}${rgb[1].toRadixString(16).padLeft(2, '0')}${rgb[2].toRadixString(16).padLeft(2, '0')}';
    }
    return color;
  }
}
