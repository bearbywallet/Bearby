import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/jazzicon.dart';
import 'package:zilpay/modals/select_address.dart';
import 'package:zilpay/src/rust/models/qrcode.dart';
import 'package:zilpay/state/app_state.dart';

class WalletSelectionCard extends StatefulWidget {
  final String? walletName;
  final String? address;
  final Function(QRcodeScanResultInfo, String) onChange;

  const WalletSelectionCard({
    super.key,
    this.walletName,
    this.address,
    required this.onChange,
  });

  @override
  State<WalletSelectionCard> createState() => _WalletSelectionCardState();
}

class _WalletSelectionCardState extends State<WalletSelectionCard> {
  bool isPressed = false;

  @override
  void initState() {
    super.initState();

    if (widget.address == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAccountsModal();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => isPressed = true),
      onExit: (_) => setState(() => isPressed = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        onTap: _showAccountsModal,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPressed
                ? theme.cardBackground.withValues(alpha: 0.6)
                : Colors.transparent,
            border: Border.all(
              color: theme.textSecondary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryPurple.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: widget.address != null
                      ? Jazzicon(
                          diameter: 30,
                          seed: widget.address!,
                          theme: theme,
                          shapeCount: 4,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.walletName ?? "",
                      style: theme.subtitle1.copyWith(
                        color: theme.textPrimary,
                        fontSize: 18, // subtitle1 is 20, adjusting
                        fontWeight: FontWeight.w600, // subtitle1 is w500
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.address ?? "",
                      style: theme.caption.copyWith(
                        color: theme.textSecondary,
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

  void _showAccountsModal() {
    showAddressSelectModal(
      context: context,
      onAddressSelected: widget.onChange,
    );
  }
}
