import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/state/app_state.dart';

class WalletSelectionCard extends StatefulWidget {
  final String walletName;
  final int transferCount;
  final VoidCallback onTap;
  final String address;

  const WalletSelectionCard({
    super.key,
    required this.walletName,
    required this.transferCount,
    required this.onTap,
    required this.address,
  });

  @override
  State<WalletSelectionCard> createState() => _WalletSelectionCardState();
}

class _WalletSelectionCardState extends State<WalletSelectionCard> {
  bool isHovered = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: theme.textSecondary.withOpacity(
                isPressed ? 0.8 : (isHovered ? 0.4 : 0.2),
              ),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryPurple.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: Blockies(
                    seed: widget.address,
                    color: getWalletColor(0),
                    bgColor: theme.primaryPurple,
                    spotColor: theme.background,
                    size: 8,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.walletName,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.transferCount} previous transfers',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 14,
                      ),
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
