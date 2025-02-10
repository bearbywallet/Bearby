import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/address_avatar.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/src/rust/models/account.dart';
import 'package:zilpay/state/app_state.dart';

class WalletCard extends StatelessWidget {
  final AccountInfo account;
  final VoidCallback onTap;
  final bool isSelected;
  final double? width;
  final double? height;
  final double? fontSize;
  final double avatarSize;

  const WalletCard({
    super.key,
    required this.account,
    required this.onTap,
    this.isSelected = false,
    this.width,
    this.height,
    this.fontSize,
    this.avatarSize = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.primaryPurple.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AvatarAddress(
                avatarSize: avatarSize,
                account: account,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      account.name,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: fontSize ?? 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shortenAddress(account.addr, leftSize: 8, rightSize: 8),
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.5),
                        fontSize: (fontSize ?? 16) - 2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
