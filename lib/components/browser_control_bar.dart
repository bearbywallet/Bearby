import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/address_avatar.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/copy_content.dart';
import 'package:bearby/components/hover_icon.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

class BrowserControlBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final String currentUrl;
  final bool canGoBack;
  final bool canGoForward;
  final bool isLoading;
  final double progress;
  final bool isConnected;
  final bool urlBarTop;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onRefresh;
  final Future<void> Function() onCopyLink;
  final VoidCallback onShare;
  final ValueChanged<bool> onUrlBarPositionChanged;
  final VoidCallback onClose;

  const BrowserControlBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.currentUrl,
    required this.canGoBack,
    required this.canGoForward,
    required this.isLoading,
    required this.progress,
    required this.isConnected,
    required this.urlBarTop,
    required this.onBack,
    required this.onForward,
    required this.onRefresh,
    required this.onCopyLink,
    required this.onShare,
    required this.onUrlBarPositionChanged,
    required this.onClose,
  });

  @override
  State<BrowserControlBar> createState() => _BrowserControlBarState();
}

class _BrowserControlBarState extends State<BrowserControlBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  final FocusNode _urlFocusNode = FocusNode();

  bool _isExpanded = false;
  bool _isFocused = false;
  bool _copiedLink = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _urlFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() {
      _isFocused = _urlFocusNode.hasFocus;
    });
    if (_urlFocusNode.hasFocus && _isExpanded) {
      _collapse();
    }
  }

  void _toggleExpanded() {
    if (_isExpanded) {
      _collapse();
    } else {
      _urlFocusNode.unfocus();
      setState(() => _isExpanded = true);
      _expandController.forward();
    }
  }

  void _collapse() {
    if (!_isExpanded) return;
    setState(() => _isExpanded = false);
    _expandController.reverse();
  }

  @override
  void dispose() {
    _urlFocusNode.removeListener(_handleFocusChange);
    _urlFocusNode.dispose();
    _expandController.dispose();
    super.dispose();
  }

  String _extractHost(String rawUrl) {
    final source = rawUrl.isNotEmpty ? rawUrl : widget.controller.text;
    final uri = Uri.tryParse(source);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host.replaceFirst(RegExp(r'^www\.'), '');
    }
    return source;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final screenWidth = mediaQuery.size.width;
    final isWide = screenWidth >= 600;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, _) {
        final t = _expandAnimation.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (t > 0.0)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_isExpanded,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _collapse,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.36 * t),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                topPadding + 8,
                8,
                bottomPadding + 8,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                alignment: widget.urlBarTop
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 560 : 460),
                  child: _buildMorphingIsland(
                    context: context,
                    appState: appState,
                    theme: theme,
                    l10n: l10n,
                    t: t,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMorphingIsland({
    required BuildContext context,
    required AppState appState,
    required AppTheme theme,
    required AppLocalizations l10n,
    required double t,
  }) {
    final isDark = theme.value == 'Dark';
    final highlightProgress = (_isFocused ? 1.0 : t).clamp(0.0, 1.0);

    final radius = lerpDouble(26, 22, t)!;
    final borderColor = Color.lerp(
      isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.black.withValues(alpha: 0.10),
      theme.primaryPurple.withValues(alpha: 0.55),
      highlightProgress,
    )!;

    final topSurfaceAlpha = lerpDouble(
      isDark ? 0.78 : 0.86,
      isDark ? 0.94 : 0.96,
      t,
    )!;
    final bottomSurfaceAlpha = lerpDouble(
      isDark ? 0.66 : 0.78,
      isDark ? 0.88 : 0.92,
      t,
    )!;

    final traySection = SizeTransition(
      sizeFactor: _expandAnimation,
      alignment: Alignment(0.0, widget.urlBarTop ? -1.0 : 1.0),
      child: FadeTransition(
        opacity: _expandAnimation,
        child: _buildExpandedTray(
          context: context,
          appState: appState,
          theme: theme,
          l10n: l10n,
        ),
      ),
    );

    final barRow = _buildCompactBarRow(theme, t);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: lerpDouble(
                isDark ? 0.28 : 0.14,
                isDark ? 0.48 : 0.24,
                t,
              )!,
            ),
            blurRadius: lerpDouble(16, 32, t)!,
            spreadRadius: lerpDouble(0, 2, t)!,
            offset: Offset(0, lerpDouble(6, 12, t)!),
          ),
          if (highlightProgress > 0.01)
            BoxShadow(
              color: theme.primaryPurple.withValues(
                alpha: 0.16 * highlightProgress,
              ),
              blurRadius: 20,
              spreadRadius: 0,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.cardBackground.withValues(alpha: topSurfaceAlpha),
                  theme.cardBackground.withValues(alpha: bottomSurfaceAlpha),
                ],
              ),
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading && widget.progress < 1.0 && widget.urlBarTop)
                  _buildProgressBar(theme),
                if (widget.urlBarTop) ...[
                  barRow,
                  traySection,
                ] else ...[
                  traySection,
                  barRow,
                ],
                if (widget.isLoading &&
                    widget.progress < 1.0 &&
                    !widget.urlBarTop)
                  _buildProgressBar(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(AppTheme theme) {
    return SizedBox(
      height: 2.5,
      child: LinearProgressIndicator(
        value: widget.progress.clamp(0.05, 1.0),
        backgroundColor: Colors.transparent,
        color: theme.primaryPurple,
        minHeight: 2.5,
      ),
    );
  }

  Widget _buildCompactBarRow(AppTheme theme, double t) {
    final iconColor = theme.textPrimary;
    final iconDisabledColor = theme.textSecondary.withValues(alpha: 0.38);

    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            HoverIcon(
              icon: AppIcon.arrowLeft,
              onTap: widget.canGoBack
                  ? () {
                      _collapse();
                      widget.onBack();
                    }
                  : () {},
              color: widget.canGoBack ? iconColor : iconDisabledColor,
              size: 22,
              padding: const EdgeInsets.all(6),
            ),
            HoverIcon(
              icon: AppIcon.arrowRight,
              onTap: widget.canGoForward
                  ? () {
                      _collapse();
                      widget.onForward();
                    }
                  : () {},
              color: widget.canGoForward ? iconColor : iconDisabledColor,
              size: 22,
              padding: const EdgeInsets.all(6),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _urlFocusNode,
                keyboardType: TextInputType.url,
                onSubmitted: (value) {
                  _urlFocusNode.unfocus();
                  _collapse();
                  widget.onSubmitted(value);
                },
                style: theme.bodyText1.copyWith(
                  color: theme.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                ),
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.go,
              ),
            ),
            _buildMenuTriggerButton(theme, t),
            HoverIcon(
              icon: AppIcon.close,
              onTap: () {
                _collapse();
                widget.onClose();
              },
              color: iconColor,
              size: 22,
              padding: const EdgeInsets.all(6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTriggerButton(AppTheme theme, double t) {
    final bgColor = Color.lerp(
      theme.textPrimary.withValues(alpha: 0.0),
      theme.primaryPurple.withValues(alpha: 0.18),
      t,
    )!;
    final iconColor = Color.lerp(
      theme.textPrimary,
      theme.primaryPurple,
      t,
    )!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleExpanded,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: t * 1.57079632679,
              child: AppIconView(
                icon: AppIcon.dots,
                size: 22,
                color: iconColor,
              ),
            ),
            if (widget.isConnected && t < 0.2)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedTray({
    required BuildContext context,
    required AppState appState,
    required AppTheme theme,
    required AppLocalizations l10n,
  }) {
    final divider = Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.textSecondary.withValues(alpha: 0.0),
            theme.textSecondary.withValues(alpha: 0.18),
            theme.textSecondary.withValues(alpha: 0.0),
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.urlBarTop) divider,
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAccountHeaderCard(appState, theme),
              const SizedBox(height: 12),
              _buildQuickActionsRow(theme, l10n),
              const SizedBox(height: 10),
              _buildUrlBarPositionTile(theme, l10n),
            ],
          ),
        ),
        if (!widget.urlBarTop) divider,
      ],
    );
  }

  Widget _buildAccountHeaderCard(AppState appState, AppTheme theme) {
    final account = appState.account;
    if (account == null) {
      return const SizedBox.shrink();
    }

    final host = _extractHost(widget.currentUrl);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isConnected
              ? theme.success.withValues(alpha: 0.28)
              : theme.textPrimary.withValues(alpha: 0.07),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isConnected
                    ? theme.success.withValues(alpha: 0.65)
                    : theme.primaryPurple.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: AvatarAddress(avatarSize: 40, account: account),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyText1.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (host.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isConnected
                              ? theme.success.withValues(alpha: 0.14)
                              : theme.textSecondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isConnected) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: theme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                host,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.caption.copyWith(
                                  color: widget.isConnected
                                      ? theme.success
                                      : theme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                CopyContent(address: account.addr, isShort: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(AppTheme theme, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _BentoActionTile(
            theme: theme,
            icon: AppIcon.reload,
            label: l10n.browserActionMenuRefresh,
            onTap: () {
              _collapse();
              widget.onRefresh();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BentoActionTile(
            theme: theme,
            icon: _copiedLink ? AppIcon.check : AppIcon.copy,
            accentColor: _copiedLink ? theme.success : null,
            label: l10n.browserActionMenuCopyLink,
            onTap: () async {
              await widget.onCopyLink();
              if (!mounted) return;
              setState(() => _copiedLink = true);
              Future.delayed(const Duration(milliseconds: 650), () {
                if (!mounted) return;
                _collapse();
                setState(() => _copiedLink = false);
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BentoActionTile(
            theme: theme,
            icon: AppIcon.share,
            label: l10n.browserActionMenuShare,
            onTap: () {
              _collapse();
              widget.onShare();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUrlBarPositionTile(AppTheme theme, AppLocalizations l10n) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final next = !widget.urlBarTop;
        _collapse();
        widget.onUrlBarPositionChanged(next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: theme.primaryPurple.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: AppIconView(
                icon: AppIcon.nav,
                size: 16,
                color: theme.primaryPurple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.browserActionMenuUrlBarTop,
                style: theme.bodyText2.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              height: 32,
              child: Switch(
                value: widget.urlBarTop,
                onChanged: (value) {
                  _collapse();
                  widget.onUrlBarPositionChanged(value);
                },
                activeTrackColor: theme.primaryPurple.withValues(alpha: 0.5),
                activeThumbColor: theme.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoActionTile extends StatefulWidget {
  final AppTheme theme;
  final AppIcon icon;
  final String label;
  final VoidCallback onTap;
  final Color? accentColor;

  const _BentoActionTile({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentColor,
  });

  @override
  State<_BentoActionTile> createState() => _BentoActionTileState();
}

class _BentoActionTileState extends State<_BentoActionTile>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(
      duration: const Duration(milliseconds: 120),
      scaleEnd: 0.95,
      opacityEnd: 0.85,
    );
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final tint = widget.accentColor ?? theme.primaryPurple;

    return buildPressableWithOpacity(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.accentColor != null
                ? widget.accentColor!.withValues(alpha: 0.4)
                : theme.textPrimary.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AppIconView(
                icon: widget.icon,
                size: 18,
                color: tint,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.caption.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
