import 'package:flutter/material.dart';

import 'package:bearby/components/image_cache.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

/// Circular token logo with an optional chain network badge in the bottom-right
/// corner.  Uses [AsyncImage] for the logo and falls back to a broken-image icon
/// when the URL fails to load.
class TokenAvatar extends StatelessWidget {
  final FTokenInfo? token;
  final double size;
  final AppState appState;
  final bool showNetworkBadge;
  final String? iconUrl;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final Color? borderColor;
  final double borderWidth;
  final bool showBorder;
  final BoxFit fit;

  const TokenAvatar({
    super.key,
    required this.token,
    this.size = 24,
    required this.appState,
    this.showNetworkBadge = true,
    this.iconUrl,
    this.errorWidget,
    this.loadingWidget,
    this.borderColor,
    this.borderWidth = 1.5,
    this.showBorder = true,
    this.fit = BoxFit.cover,
  });

  /// Builds a small chain-network badge widget for [token], or null when the
  /// chain cannot be resolved.  Used internally by [TokenAvatar] and can be
  /// called directly when composing custom avatar layouts (e.g. TokenSelectItem).
  static double defaultBadgeSize(double avatarSize) => avatarSize * 0.25;

  static Widget? buildNetworkBadge(
    AppState appState,
    AppTheme theme,
    FTokenInfo token, {
    double? badgeSize,
  }) {
    final NetworkConfigInfo? chain;
    try {
      chain = appState.getChain(token.chainHash);
    } catch (_) {
      return null;
    }
    final double effectiveBadgeSize = badgeSize ?? defaultBadgeSize(40);
    if (chain == null) return null;
    return Container(
      width: effectiveBadgeSize,
      height: effectiveBadgeSize,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(color: theme.cardBackground, width: 1.5),
      ),
      child: ClipOval(
        child: AsyncImage(
          url: viewChain(network: chain, theme: theme.value),
          width: effectiveBadgeSize,
          height: effectiveBadgeSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = appState.currentTheme;
    final badge = switch ((showNetworkBadge, token)) {
      (true, final t?) => buildNetworkBadge(
          appState, theme, t,
          badgeSize: defaultBadgeSize(size)),
      _ => null,
    };

    final String? resolvedUrl = iconUrl ?? switch (token) {
      final t? => processTokenLogo(
          token: t,
          shortName: appState.chain?.shortName ?? '',
          theme: theme.value,
        ),
      _ => null,
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: showBorder
                  ? Border.all(
                      color:
                          borderColor ?? theme.textPrimary.withValues(alpha: 0.2),
                      width: borderWidth,
                    )
                  : null,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: AsyncImage(
                url: resolvedUrl,
                width: size,
                height: size,
                fit: fit,
                errorWidget: errorWidget ?? _brokenIcon(theme),
                loadingWidget: loadingWidget ??
                    Center(
                      child: SizedBox(
                        width: size * 0.5,
                        height: size * 0.5,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: badge,
            ),
        ],
      ),
    );
  }

  Widget _brokenIcon(AppTheme theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.background,
      ),
      child: Icon(
        Icons.broken_image,
        size: size * 0.6,
        color: theme.textSecondary,
      ),
    );
  }
}
