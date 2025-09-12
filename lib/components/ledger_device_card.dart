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
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (widget.isConnecting) return;
    setState(() {
      _isPressed = pressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final scale = !_isPressed ? 1.0 : 0.97;
    final bool isDisabled = widget.isConnecting;

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
            color: theme.cardBackground,
            border: Border.all(
              color: widget.isConnected
                  ? theme.success.withValues(alpha: 0.7)
                  : theme.cardBackground.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.cardBackground.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
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
                                theme.primaryPurple.withValues(alpha: 0.0),
                              ],
                              stops: const [0.4, 0.5, 0.6],
                              begin: Alignment(-1.0, -0.3),
                              end: Alignment(1.0, 0.3),
                              tileMode: TileMode.clamp,
                              transform: _ShimmerGradientTransform(
                                  percent: _shimmerController.value),
                            ).createShader(bounds);
                          },
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
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
        color: theme.background,
        border: Border.all(color: theme.primaryPurple.withOpacity(0.2)),
      ),
      child: Center(
        child: SvgPicture.asset(
          widget.device.connectionType == ConnectionType.ble
              ? 'assets/icons/ble.svg'
              : 'assets/icons/usb.svg',
          width: 22,
          height: 22,
          colorFilter: ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
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
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.device.connectionType.name.toUpperCase(),
          style: TextStyle(
            color: theme.textSecondary.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(dynamic theme) {
    return SizedBox(
      width: 28,
      height: 28,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: widget.isConnecting
            ? SizedBox(
                key: const ValueKey('connecting'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.primaryPurple),
                ),
              )
            : widget.isConnected
                ? SvgPicture.asset(
                    'assets/icons/check.svg',
                    key: const ValueKey('connected'),
                    width: 28,
                    height: 28,
                    colorFilter:
                        ColorFilter.mode(theme.success, BlendMode.srcIn),
                  )
                : SvgPicture.asset(
                    'assets/icons/chevron_right.svg',
                    key: const ValueKey('idle'),
                    width: 28,
                    height: 28,
                    colorFilter:
                        ColorFilter.mode(theme.textSecondary, BlendMode.srcIn),
                  ),
      ),
    );
  }
}

class _ShimmerGradientTransform extends GradientTransform {
  final double percent;

  const _ShimmerGradientTransform({required this.percent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0.0, 0.0);
  }
}
