import 'package:flutter/widgets.dart';
import 'package:bearby/components/copy_content.dart';
import 'package:bearby/theme/app_theme.dart';

class DetailItem extends StatelessWidget {
  final String label;
  final dynamic value;
  final AppTheme theme;
  final bool isCopyable;
  final Widget? valueWidget;

  const DetailItem({
    super.key,
    required this.label,
    this.value,
    required this.theme,
    this.isCopyable = false,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.bodyText2.copyWith(
                color: theme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (valueWidget != null)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: valueWidget!,
                    ),
                  )
                else if (isCopyable)
                  CopyContent(
                    address: value.toString(),
                    isShort: true,
                  )
                else
                  Expanded(
                    child: value is Widget
                        ? value
                        : Text(
                            value?.toString() ?? '',
                            style: theme.bodyText2.copyWith(
                              color: theme.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
