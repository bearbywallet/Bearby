import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/mixins/pressable_animation.dart';
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

class ButtonItem extends StatefulWidget {
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
  State<ButtonItem> createState() => _ButtonItemState();
}

class _ButtonItemState extends State<ButtonItem>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(duration: const Duration(milliseconds: 100), scaleEnd: 0.98);
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildPressable(
      onTap: widget.onTap,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
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
        ),
      ),
    );
  }
}
