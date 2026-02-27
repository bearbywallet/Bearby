import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/addr.dart';
import 'package:bearby/state/app_state.dart';

class TokenTransferInfo extends StatelessWidget {
  final String fromAddress;
  final String toAddress;
  final String? fromName;
  final String? toName;
  final Color? textColor;
  final Color? secondaryColor;

  const TokenTransferInfo({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    this.fromName,
    this.toName,
    this.textColor,
    this.secondaryColor,
  });

  Widget _buildAddressInfo(
    BuildContext context,
    String address,
    String? name,
    Color textColor,
  ) {
    final state = Provider.of<AppState>(context, listen: false);
    final theme = state.currentTheme;
    final displayName = name ?? AppLocalizations.of(context)!.tokenTransferAmountUnknown;

    return Expanded(
      flex: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayName,
            style: theme.overline.copyWith(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 8,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            shortenAddress(address),
            style: theme.overline.copyWith(
              color: textColor.withValues(alpha: 0.7),
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final theme = state.currentTheme;
    final effectiveTextColor = textColor ?? theme.textPrimary;
    final effectiveSecondaryColor = secondaryColor ?? theme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: effectiveSecondaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAddressInfo(context, fromAddress, fromName, effectiveTextColor),
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
          _buildAddressInfo(context, toAddress, toName, effectiveTextColor),
        ],
      ),
    );
  }
}
