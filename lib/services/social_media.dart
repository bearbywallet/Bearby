import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaService {
  static const String _telegramScheme = 'tg://';
  static const String _telegramWebUrl = 'https://telegram.org';
  static const String _telegramAndroidStore =
      'market://details?id=org.telegram.messenger';
  static const String _telegramIosStore =
      'https://apps.apple.com/app/telegram-messenger/id686449807';

  static final String _xScheme =
      Platform.isIOS ? 'twitter://' : 'com.twitter.android';
  static const String _xWebUrl = 'https://x.com';
  static const String _xAndroidStore =
      'market://details?id=com.twitter.android';
  static const String _xIosStore =
      'https://apps.apple.com/app/twitter/id333903271';

  Future<void> openTelegram({String? username, String? message}) async {
    String url = _telegramScheme;

    if (username != null) {
      url = 'tg://resolve?domain=$username';
    } else if (message != null) {
      url = 'tg://msg?text=${Uri.encodeComponent(message)}';
    }

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await _handleAppNotInstalled(
          webUrl: _telegramWebUrl,
          androidStore: _telegramAndroidStore,
          iosStore: _telegramIosStore,
        );
      }
    } catch (e) {
      debugPrint('Error launching Telegram: $e');

      await _launchUrl(_telegramWebUrl);
    }
  }

  Future<void> openX({String? username, String? tweet}) async {
    String url = _xScheme;

    if (username != null) {
      url = Platform.isIOS
          ? 'twitter://user?screen_name=$username'
          : 'com.twitter.android://user?screen_name=$username';
    } else if (tweet != null) {
      url = Platform.isIOS
          ? 'twitter://post?message=${Uri.encodeComponent(tweet)}'
          : 'com.twitter.android://post?message=${Uri.encodeComponent(tweet)}';
    }

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await _handleAppNotInstalled(
          webUrl: _xWebUrl,
          androidStore: _xAndroidStore,
          iosStore: _xIosStore,
        );
      }
    } catch (e) {
      debugPrint('Error launching X: $e');

      await _launchUrl(_xWebUrl);
    }
  }

  Future<void> _handleAppNotInstalled({
    required String webUrl,
    required String androidStore,
    required String iosStore,
  }) async {
    final Uri storeUri = Uri.parse(
      Platform.isAndroid ? androidStore : iosStore,
    );

    try {
      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri);
      } else {
        await _launchUrl(webUrl);
      }
    } catch (e) {
      debugPrint('Error opening store/web: $e');
      await _launchUrl(webUrl);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
