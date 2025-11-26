import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class NetworkTile extends StatelessWidget {
  final String? iconUrl;
  final String title;
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
    final isActive = !disabled;

    final textColor =
        disabled ? theme.textPrimary.withValues(alpha: 0.5) : theme.textPrimary;
    final backgroundColor = disabled
        ? theme.textSecondary.withValues(alpha: 0.05)
        : isSelected
            ? theme.primaryPurple.withValues(alpha: 0.1)
            : theme.textSecondary.withValues(alpha: 0.02);
    final borderColor = isSelected ? theme.primaryPurple : Colors.transparent;

    return Opacity(
      opacity: disabled ? 0.2 : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isActive ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            color: backgroundColor,
          ),
          margin: const EdgeInsets.all(0),
          child: ListTile(
            enabled: isActive,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildLeadingIcon(),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLabels(theme),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.bodyLarge.copyWith(
                    color: textColor,
                  ),
                ),
              ],
            ),
            trailing: _buildTrailingIcon(isActive, textColor),
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
        child: Placeholder(color: Colors.grey),
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
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildLabels(AppTheme theme) {
    if (isTestnet == null && isDefault != true) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      children: [
        if (isTestnet != null)
          _buildNetworkLabel(
            isTestnet! ? "Testnet" : "Mainnet",
            isTestnet! ? theme.warning : theme.success,
            theme,
          ),
        if (isDefault == true)
          _buildNetworkLabel(
            "Default",
            theme.primaryPurple,
            theme,
          ),
      ],
    );
  }

  Widget _buildNetworkLabel(String text, Color color, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.labelSmall.copyWith(
          color: color,
        ),
      ),
    );
  }

  Widget? _buildTrailingIcon(bool isActive, Color iconColor) {
    if (isAdded) {
      if (onEdit == null) return null;

      return IconButton(
        icon: SvgPicture.asset(
          "assets/icons/edit.svg",
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        padding: const EdgeInsets.all(8),
        onPressed: isActive ? onEdit : null,
      );
    }

    if (onAdd == null) return null;

    return IconButton(
      icon: SvgPicture.asset(
        "assets/icons/plus.svg",
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
      padding: const EdgeInsets.all(8),
      onPressed: isActive ? onAdd : null,
    );
  }
}
