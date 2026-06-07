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
  final FTokenInfo token;
  final double size;
  final AppState appState;
  final bool showNetworkBadge;

  const TokenAvatar({
    super.key,
    required this.token,
    this.size = 24,
    required this.appState,
    this.showNetworkBadge = true,
  });

  /// Builds a small chain-network badge widget for [token], or null when the
  /// chain cannot be resolved.  Used internally by [TokenAvatar] and can be
  /// called directly when composing custom avatar layouts (e.g. TokenSelectItem).
  static Widget? buildNetworkBadge(
    AppState appState,
    AppTheme theme,
    FTokenInfo token, {
    double badgeSize = 14,
  }) {
    final NetworkConfigInfo? chain;
    try {
      chain = appState.getChain(token.chainHash);
    } catch (_) {
      return null;
    }
    if (chain == null) return null;
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(color: theme.cardBackground, width: 1.5),
      ),
      child: ClipOval(
        child: AsyncImage(
          url: viewChain(network: chain, theme: theme.value),
          width: badgeSize,
          height: badgeSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = appState.currentTheme;
    final badge = showNetworkBadge ? buildNetworkBadge(appState, theme, token) : null;

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
              border: Border.all(
                color: theme.textPrimary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: AsyncImage(
                url: processTokenLogo(
                  token: token,
                  shortName: appState.chain?.shortName ?? '',
                  theme: theme.value,
                ),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: _brokenIcon(theme),
                loadingWidget: Center(
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
