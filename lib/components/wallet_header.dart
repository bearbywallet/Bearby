import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/address_avatar.dart';
import 'package:zilpay/components/copy_content.dart';
import 'package:zilpay/modals/wallet_header.dart';
import 'package:zilpay/src/rust/models/account.dart';
import 'package:zilpay/state/app_state.dart';

class WalletHeader extends StatefulWidget {
  final AccountInfo account;
  final Function()? onTap;

  const WalletHeader({
    super.key,
    required this.account,
    this.onTap,
  });

  @override
  State<WalletHeader> createState() => _WalletHeaderState();
}

class _WalletHeaderState extends State<WalletHeader>
    with SingleTickerProviderStateMixin {
  double _opacity = 1.0;
  bool _isAnimated = true;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isAnimated = false;
      _opacity = 0.5;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isAnimated = true;
      _opacity = 1.0;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isAnimated = true;
      _opacity = 1.0;
    });
  }

  void _showWalletModal() {
    showWalletModal(
      context: context,
      onManageWallet: () {
        Navigator.pushNamed(context, '/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: () {
            _showWalletModal();
            widget.onTap?.call();
          },
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: Duration(milliseconds: _isAnimated ? 150 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarAddress(
                  avatarSize: 50,
                  account: widget.account,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.account.name,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        CopyContent(
          address: widget.account.addr,
        ),
      ],
    );
  }
}
