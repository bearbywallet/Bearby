import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/state/app_state.dart';

class LedgerCard extends StatefulWidget {
  final DiscoveredDevice device;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  const LedgerCard({
    super.key,
    required this.device,
    this.isConnected = false,
    this.isConnecting = false,
    required this.onTap,
  });

  @override
  State<LedgerCard> createState() => _LedgerCardState();
}

class _LedgerCardState extends State<LedgerCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -1.0, max: 2.0, period: const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

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
    final bool isDisabled = widget.isConnecting;

    final cardColor = widget.isConnected
        ? theme.success.withValues(alpha: 0.15)
        : theme.cardBackground;
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
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Base Card Content
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border.all(color: borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    children: [
                      _buildDeviceIcon(theme),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDeviceInfo(theme)),
                      _buildStatusIndicator(theme),
                    ],
                  ),
                ),
              ),
              // Shimmer Overlay for Connecting State
              if (widget.isConnecting)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [
                                theme.primaryPurple.withValues(alpha: 0.0),
                                theme.primaryPurple.withValues(alpha: 0.1),
                                theme.primaryPurple.withValues(alpha: 0.2),
                                theme.primaryPurple.withValues(alpha: 0.1),
                                theme.primaryPurple.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                              transform: _ShimmerGradientTransform(
                                  percent: _shimmerController.value),
                            ).createShader(bounds);
                          },
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(dynamic theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isConnected
            ? theme.success.withOpacity(0.2)
            : theme.background,
        border: Border.all(
            color: widget.isConnected
                ? theme.success.withOpacity(0.3)
                : theme.primaryPurple.withOpacity(0.2)),
      ),
      child: Center(
        child: SvgPicture.asset(
          widget.device.connectionType == ConnectionType.ble
              ? 'assets/icons/ble.svg'
              : 'assets/icons/usb.svg',
          width: 22,
          height: 22,
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
              '(Unknown Device)',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Chip(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          backgroundColor: theme.background.withOpacity(0.5),
          label: Text(
            widget.device.connectionType.name.toUpperCase(),
            style: TextStyle(
              color: theme.textSecondary.withOpacity(0.8),
              fontSize: 11,
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
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryPurple),
        ),
      );
    } else if (widget.isConnected) {
      icon = SvgPicture.asset(
        'assets/icons/check.svg',
        key: const ValueKey('connected'),
        width: 28,
        height: 28,
        colorFilter: ColorFilter.mode(theme.success, BlendMode.srcIn),
      );
    } else {
      icon = SvgPicture.asset(
        'assets/icons/chevron_right.svg',
        key: const ValueKey('idle'),
        width: 28,
        height: 28,
        colorFilter: ColorFilter.mode(theme.textSecondary, BlendMode.srcIn),
      );
    }

    return SizedBox(
      width: 28,
      height: 28,
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

class _ShimmerGradientTransform extends GradientTransform {
  final double percent;

  const _ShimmerGradientTransform({required this.percent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Moves the gradient across the card horizontally
    return Matrix4.translationValues(bounds.width * percent, 0.0, 0.0);
  }
}
