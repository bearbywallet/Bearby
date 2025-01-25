import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

Widget networkLabel({
  required String text,
  required Color backgroundColor,
  required Color textColor,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: backgroundColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    ),
  );
}

class NetworkTile extends StatelessWidget {
  final String? iconUrl;
  final String title;
  final bool isEnabled;
  final bool isAdded;
  final bool isSelected;
  final bool disabled;
  final bool? isTestnet;
  final bool? isDefault;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAdd;

  const NetworkTile({
    super.key,
    required this.title,
    this.iconUrl,
    this.isEnabled = false,
    this.isAdded = false,
    this.isSelected = false,
    this.disabled = false,
    this.isTestnet = false,
    this.isDefault = false,
    this.onTap,
    this.onEdit,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: (isEnabled && !disabled) ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.primaryPurple
                  : theme.textSecondary.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            color: _getBackgroundColor(theme),
          ),
          child: ListTile(
            enabled: isEnabled && !disabled,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildLeadingIcon(),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (isTestnet != null)
                      networkLabel(
                        text: isTestnet! ? "Testnet" : "Mainnet",
                        backgroundColor:
                            isTestnet! ? theme.warning : theme.success,
                        textColor: isTestnet! ? theme.warning : theme.success,
                      ),
                    if (isTestnet != null && isDefault == true)
                      const SizedBox(width: 8),
                    if (isDefault == true)
                      networkLabel(
                        text: "Default",
                        backgroundColor: theme.primaryPurple,
                        textColor: theme.primaryPurple,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getTextColor(theme),
                  ),
                ),
              ],
            ),
            trailing: _buildTrailingButton(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    if (iconUrl == null) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Placeholder(
          color: Colors.grey,
        ),
      );
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: AsyncImage(
        url: iconUrl!,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        loadingWidget: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget? _buildTrailingButton(AppTheme theme) {
    if (isAdded) {
      return onEdit != null
          ? IconButton(
              icon: SvgPicture.asset(
                "assets/icons/edit.svg",
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  _getIconColor(theme),
                  BlendMode.srcIn,
                ),
              ),
              padding: const EdgeInsets.all(8),
              onPressed:
                  (isEnabled && !disabled && onEdit != null) ? onEdit : null,
            )
          : null;
    }

    return onAdd != null
        ? IconButton(
            icon: SvgPicture.asset(
              "assets/icons/plus.svg",
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                _getIconColor(theme),
                BlendMode.srcIn,
              ),
            ),
            padding: const EdgeInsets.all(8),
            onPressed: (isEnabled && !disabled) ? onAdd : null,
          )
        : null;
  }

  Color? _getBackgroundColor(AppTheme theme) {
    if (!isEnabled) {
      return theme.textSecondary.withValues(alpha: 0.05);
    }
    if (isSelected) {
      return theme.primaryPurple.withValues(alpha: 0.1);
    }
    return theme.textSecondary.withValues(alpha: 0.02);
  }

  Color _getTextColor(AppTheme theme) {
    if (!isEnabled) {
      return theme.textSecondary.withValues(alpha: 0.5);
    }
    return theme.textSecondary;
  }

  Color _getIconColor(AppTheme theme) {
    if (!isEnabled) {
      return theme.textSecondary.withValues(alpha: 0.5);
    }
    return theme.textSecondary;
  }
}
