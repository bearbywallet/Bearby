import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:zilpay/components/copy_content.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/modals/wallet_header.dart';

class WalletHeader extends StatefulWidget {
  final String walletName;
  final String walletAddress;
  final Color primaryPurple;
  final Color background;
  final Color textPrimary;
  final Function()? onTap;

  const WalletHeader({
    super.key,
    required this.walletName,
    required this.walletAddress,
    required this.primaryPurple,
    required this.background,
    required this.textPrimary,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
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
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.primaryPurple.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Blockies(
                      seed: widget.walletAddress,
                      color: getWalletColor(0),
                      bgColor: widget.primaryPurple,
                      spotColor: widget.background,
                      size: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.walletName,
                  style: TextStyle(
                    color: widget.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        CopyAddressButton(
          address: widget.walletAddress,
        ),
      ],
    );
  }
}
