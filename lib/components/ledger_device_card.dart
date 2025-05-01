import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class LedgerCard extends StatefulWidget {
  final LedgerDevice device;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  const LedgerCard({
    super.key,
    required this.device,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
  });

  @override
  State<LedgerCard> createState() => _LedgerCardState();
}

class _LedgerCardState extends State<LedgerCard> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (widget.isConnected || widget.isConnecting) return;
    setState(() {
      _isPressed = pressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final scale =
        !(widget.isConnected || widget.isConnecting) && _isPressed ? 0.96 : 1.0;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        if (!(widget.isConnected || widget.isConnecting)) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              widget.onTap();
            }
          });
        }
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          color: theme.cardBackground,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: SvgPicture.asset(
              widget.device.connectionType == ConnectionType.ble
                  ? 'assets/icons/ble.svg'
                  : 'assets/icons/usb.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                widget.isConnected ? theme.success : theme.primaryPurple,
                BlendMode.srcIn,
              ),
            ),
            title: Text(
              widget.device.name.isEmpty
                  ? '(Unknown Device)'
                  : widget.device.name,
              style: TextStyle(
                fontWeight:
                    widget.isConnected ? FontWeight.bold : FontWeight.normal,
                color: (widget.isConnected || widget.isConnecting)
                    ? theme.textSecondary.withAlpha(180)
                    : theme.textPrimary,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'ID: ${widget.device.id.length > 12 ? '${widget.device.id.substring(0, 6)}...${widget.device.id.substring(widget.device.id.length - 6)}' : widget.device.id}\nType: ${widget.device.connectionType.name.toUpperCase()}',
              style: TextStyle(color: theme.textSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: widget.isConnecting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.primaryPurple),
                    ),
                  )
                : widget.isConnected
                    ? SvgPicture.asset(
                        'assets/icons/check.svg',
                        width: 26,
                        height: 26,
                        colorFilter:
                            ColorFilter.mode(theme.success, BlendMode.srcIn),
                      )
                    : SvgPicture.asset(
                        'assets/icons/chevron_right.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                            theme.textSecondary, BlendMode.srcIn),
                      ),
          ),
        ),
      ),
    );
  }
}
