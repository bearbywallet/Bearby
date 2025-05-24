import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class TokenTransferInfo extends StatelessWidget {
  final String fromAddress;
  final String toAddress;
  final String? fromName;
  final String? toName;
  final bool disabled;
  final Color? textColor;
  final Color? secondaryColor;

  const TokenTransferInfo({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    this.fromName,
    this.toName,
    this.disabled = false,
    this.textColor,
    this.secondaryColor,
  });

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  Widget _buildAddressButton(
    BuildContext context,
    String address,
    String? name,
    AppTheme theme,
    TextStyle style,
  ) {
    return Expanded(
      flex: 3,
      child: TextButton(
        onPressed: () => _copyToClipboard(context, address),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          splashFactory: NoSplash.splashFactory,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name ?? AppLocalizations.of(context)!.tokenTransferAmountUnknown,
              style: style.copyWith(
                // style is already themed addressStyle
                fontSize: 8,
                fontWeight: FontWeight.normal, // w400 is FontWeight.normal
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              shortenAddress(address),
              style: style, // style is already themed addressStyle
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;

    final effectiveTextColor = textColor ?? theme.textPrimary;
    final effectiveSecondaryColor = secondaryColor ?? theme.textSecondary;

    final addressStyle = theme.overline.copyWith(
      color: effectiveTextColor.withValues(alpha: 0.7),
      letterSpacing: 0.5,
      fontWeight: FontWeight.w500,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: effectiveSecondaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAddressButton(
            context,
            fromAddress,
            fromName,
            theme,
            addressStyle,
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: effectiveSecondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                "assets/icons/right_arrow.svg",
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  effectiveSecondaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          _buildAddressButton(
            context,
            toAddress,
            toName,
            theme,
            addressStyle,
          ),
        ],
      ),
    );
  }
}
