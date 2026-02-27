import 'package:flutter/material.dart';
import 'package:bearby/theme/app_theme.dart';

class DetailGroupCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final AppTheme theme;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;

  const DetailGroupCard({
    super.key,
    required this.title,
    required this.children,
    required this.theme,
    this.headerTrailing,
    this.padding,
    this.contentPadding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.5),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: theme.modalBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: padding ??
                const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.bodyText1.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (headerTrailing != null) headerTrailing!,
              ],
            ),
          ),
          Divider(height: 1, color: theme.modalBorder.withValues(alpha: 0.3)),
          if (contentPadding != null)
            Padding(
              padding: contentPadding!,
              child: Column(children: children),
            )
          else
            Column(children: children),
        ],
      ),
    );
  }
}
