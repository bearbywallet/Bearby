import 'package:flutter/material.dart';
import 'package:zilpay/components/network_tile.dart';
import 'package:zilpay/src/rust/models/provider.dart';

class NetworkCard extends StatefulWidget {
  final NetworkConfigInfo configInfo;
  final bool isAdded;
  final bool isDefault;
  final bool isSelected;
  final bool disabled;
  final bool isTestnet;
  final String iconUrl;
  final Function(NetworkConfigInfo) onNetworkSelect;
  final Function(NetworkConfigInfo) onNetworkEdit;
  final Function(NetworkConfigInfo) onNetworkAdd;

  const NetworkCard({
    super.key,
    required this.configInfo,
    required this.isAdded,
    required this.isDefault,
    required this.isSelected,
    this.disabled = false,
    required this.isTestnet,
    required this.iconUrl,
    required this.onNetworkSelect,
    required this.onNetworkEdit,
    required this.onNetworkAdd,
  });

  @override
  State<NetworkCard> createState() => _NetworkCardState();
}

class _NetworkCardState extends State<NetworkCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePress(bool isDown) {
    if (isDown) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleNetworkTap() {
    if (widget.disabled) return;

    if (!widget.isAdded) {
      widget.onNetworkAdd(widget.configInfo);
      widget.onNetworkSelect(widget.configInfo);
    } else {
      widget.onNetworkSelect(widget.configInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.disabled) {
            _handlePress(true);
          }
        },
        onTapUp: (_) {
          _handlePress(false);
        },
        onTapCancel: () {
          _handlePress(false);
        },
        onTap: _handleNetworkTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: NetworkTile(
            iconUrl: widget.iconUrl,
            title: widget.configInfo.name,
            isTestnet: widget.isTestnet,
            isAdded: widget.isAdded,
            isDefault: widget.isDefault,
            isSelected: widget.isSelected,
            disabled: widget.disabled,
            onTap: null,
            onAdd: widget.isAdded
                ? null
                : () => widget.onNetworkAdd(widget.configInfo),
            onEdit: widget.isAdded
                ? () => widget.onNetworkEdit(widget.configInfo)
                : null,
          ),
        ),
      ),
    );
  }
}
