import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class TokenTransferAmount extends StatelessWidget {
  final String fromAddress;
  final String toAddress;
  final String amount;
  final String symbol;
  final String? fromName;
  final String? toName;
  final bool disabled;
  final Color? textColor;
  final Color? secondaryColor;

  const TokenTransferAmount({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.symbol,
    this.fromName,
    this.toName,
    this.disabled = false,
    this.textColor,
    this.secondaryColor,
  });

  String _formatAddress(String address) {
    return shortenAddress(address);
  }

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
              name ?? 'Unknown',
              style: style.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _formatAddress(address),
              style: style,
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

    final addressStyle = TextStyle(
      fontSize: 10,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        amount,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: effectiveTextColor,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: effectiveSecondaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
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
