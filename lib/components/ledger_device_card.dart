import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/state/app_state.dart';

class LedgerCard extends StatefulWidget {
  final DiscoveredDevice device;
  final bool disabled;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  const LedgerCard({
    super.key,
    required this.device,
    required this.onTap,
    this.isConnected = false,
    this.isConnecting = false,
    this.disabled = false,
  });

  @override
  State<LedgerCard> createState() => _LedgerCardState();
}

class _LedgerCardState extends State<LedgerCard> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (widget.isConnecting || widget.isConnected) return;
    setState(() {
      _isPressed = pressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final scale = !_isPressed ? 1.0 : 0.97;
    final bool isDisabled = widget.isConnecting || widget.disabled;

    final cardColor = widget.isConnected
        ? theme.success.withValues(alpha: 0.15)
        : theme.buttonBackground.withValues(alpha: 0.1);
    final borderColor = widget.isConnected
        ? theme.success.withValues(alpha: 0.7)
        : theme.cardBackground.withValues(alpha: 0.5);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        if (!isDisabled) {
          Future.delayed(const Duration(milliseconds: 120), () {
            if (mounted) widget.onTap();
          });
        }
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: borderColor, width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _buildDeviceIcon(theme),
                const SizedBox(width: 12),
                Expanded(child: _buildDeviceInfo(theme)),
                _buildStatusIndicator(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(dynamic theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isConnected
            ? theme.success.withOpacity(0.2)
            : theme.background,
        border: Border.all(
            color: widget.isConnected
                ? theme.success.withOpacity(0.4)
                : theme.primaryPurple.withOpacity(0.3)),
      ),
      child: Center(
        child: SvgPicture.asset(
          widget.device.connectionType == ConnectionType.ble
              ? 'assets/icons/ble.svg'
              : 'assets/icons/usb.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
              widget.isConnected ? theme.success : theme.primaryPurple,
              BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.device.deviceModelProducName ??
              widget.device.name ??
              widget.device.deviceModelId ??
              "",
          style: theme.labelLarge.copyWith(
            color: theme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Chip(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          backgroundColor: theme.background.withOpacity(0.6),
          label: Text(
            widget.device.connectionType.name.toUpperCase(),
            style: theme.overline.copyWith(
              color: theme.textSecondary.withOpacity(0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(dynamic theme) {
    Widget icon;

    if (widget.isConnecting) {
      icon = SizedBox(
        key: const ValueKey('connecting'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryPurple),
        ),
      );
    } else if (widget.isConnected) {
      icon = SvgPicture.asset(
        'assets/icons/check.svg',
        key: const ValueKey('connected'),
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(theme.success, BlendMode.srcIn),
      );
    } else {
      icon = SvgPicture.asset(
        'assets/icons/chevron_right.svg',
        key: const ValueKey('idle'),
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(theme.textSecondary, BlendMode.srcIn),
      );
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: icon,
      ),
    );
  }
}
