import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/src/rust/models/settings.dart';
import 'package:zilpay/theme/app_theme.dart';

extension BrowserSettingsInfoExtension on BrowserSettingsInfo {
  BrowserSettingsInfo copyWith({
    int? searchEngineIndex,
    bool? cacheEnabled,
    bool? cookiesEnabled,
    int? contentBlocking,
    bool? doNotTrack,
    bool? incognitoMode,
    double? textScalingFactor,
    bool? allowGeolocation,
    bool? allowCamera,
    bool? allowMicrophone,
    bool? allowAutoPlay,
  }) {
    return BrowserSettingsInfo(
      searchEngineIndex: searchEngineIndex ?? this.searchEngineIndex,
      cacheEnabled: cacheEnabled ?? this.cacheEnabled,
      cookiesEnabled: cookiesEnabled ?? this.cookiesEnabled,
      contentBlocking: contentBlocking ?? this.contentBlocking,
      doNotTrack: doNotTrack ?? this.doNotTrack,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      textScalingFactor: textScalingFactor ?? this.textScalingFactor,
      allowGeolocation: allowGeolocation ?? this.allowGeolocation,
      allowCamera: allowCamera ?? this.allowCamera,
      allowMicrophone: allowMicrophone ?? this.allowMicrophone,
      allowAutoPlay: allowAutoPlay ?? this.allowAutoPlay,
    );
  }
}

class ButtonItem extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final String iconPath;
  final String description;
  final VoidCallback onTap;
  final String? subtitleText;

  const ButtonItem({
    super.key,
    required this.theme,
    required this.title,
    required this.iconPath,
    required this.description,
    required this.onTap,
    this.subtitleText,
  });

  @override
  Widget build(BuildContext context) {
    return _ButtonItemContent(
      theme: theme,
      title: title,
      iconPath: iconPath,
      description: description,
      onTap: onTap,
      subtitleText: subtitleText,
    );
  }
}

class _ButtonItemContent extends StatefulWidget {
  final AppTheme theme;
  final String title;
  final String iconPath;
  final String description;
  final VoidCallback onTap;
  final String? subtitleText;

  const _ButtonItemContent({
    required this.theme,
    required this.title,
    required this.iconPath,
    required this.description,
    required this.onTap,
    this.subtitleText,
  });

  @override
  State<_ButtonItemContent> createState() => _ButtonItemContentState();
}

class _ButtonItemContentState extends State<_ButtonItemContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: SizedBox(
          width: double.infinity,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                widget.iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  widget.theme.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: widget.theme.bodyText1.copyWith(
                        color: widget.theme.textPrimary,
                      ),
                    ),
                    if (widget.subtitleText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitleText!,
                        style: widget.theme.bodyText2.copyWith(
                          color: widget.theme.primaryPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SvgPicture.asset(
                'assets/icons/chevron_right.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  widget.theme.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
          if (widget.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                widget.description,
                style: widget.theme.bodyText2.copyWith(
                  color: widget.theme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
