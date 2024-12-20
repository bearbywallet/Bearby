import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/modals/select_address.dart';
import 'package:zilpay/state/app_state.dart';

class WalletSelectionCard extends StatefulWidget {
  final String? initedWalletName;
  final String? initedAddress;

  const WalletSelectionCard({
    super.key,
    this.initedWalletName,
    this.initedAddress,
  });

  @override
  State<WalletSelectionCard> createState() => _WalletSelectionCardState();
}

class _WalletSelectionCardState extends State<WalletSelectionCard> {
  late String _name;
  late String _address;
  bool isPressed = false;

  @override
  void initState() {
    super.initState();

    if (widget.initedWalletName != null) {
      _name = widget.initedWalletName!;
    } else {
      _name = "";
    }

    if (widget.initedAddress != null) {
      _address = widget.initedAddress!;
    } else {
      _address = "";

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
                ? theme.cardBackground.withOpacity(0.6)
                : Colors.transparent,
            border: Border.all(
              color: theme.textSecondary.withOpacity(0.2),
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
                    color: theme.primaryPurple.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: Blockies(
                    seed: _address,
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
                      _name,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _address,
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

  void _showAccountsModal() {
    showAddressSelectModal(
      context: context,
      onAddressSelected: (String address, String name) {
        setState(() {
          _name = name;
          _address = address;
        });
      },
    );
  }
}
