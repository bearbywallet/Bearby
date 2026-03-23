import 'dart:ui';
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
    setState(() => _isPressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final bool isDisabled = widget.isConnecting || widget.disabled;

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
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0, end: widget.isConnected ? 1.0 : 0.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            final accentColor = Color.lerp(
              theme.primaryPurple,
              theme.success,
              value,
            )!;

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.cardBackground
                            .withValues(alpha: 0.65 + value * 0.15),
                        theme.cardBackground
                            .withValues(alpha: 0.75 + value * 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(
                        alpha: 0.35 + value * 0.45,
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(
                          alpha: 0.08 + value * 0.12,
                        ),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildDeviceIcon(theme, accentColor),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDeviceInfo(theme)),
                      _buildStatusIndicator(theme),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(dynamic theme, Color accentColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.cardBackground.withValues(alpha: 0.5),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: SvgPicture.asset(
          widget.device.connectionType == ConnectionType.ble
              ? 'assets/icons/ble.svg'
              : 'assets/icons/usb.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.cardBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.device.connectionType.name.toUpperCase(),
            style: theme.overline.copyWith(
              color: theme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
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
      icon = const SizedBox.shrink(key: ValueKey('connected'));
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
