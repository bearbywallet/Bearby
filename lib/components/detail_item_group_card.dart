import 'package:flutter/widgets.dart';
import 'package:zilpay/components/copy_content.dart';
import 'package:zilpay/theme/app_theme.dart';

class DetailItem extends StatelessWidget {
  final String label;
  final dynamic value;
  final AppTheme theme;
  final bool isCopyable;

  const DetailItem({
    super.key,
    required this.label,
    required this.value,
    required this.theme,
    this.isCopyable = false,
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
              style: TextStyle(
                color: theme.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isCopyable)
                  CopyContent(
                    address: value.toString(),
                    isShort: true,
                  )
                else
                  Expanded(
                    child: value is Widget
                        ? value
                        : Text(
                            value.toString(),
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
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
