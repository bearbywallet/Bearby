import 'package:flutter/material.dart';
import 'package:zilpay/components/network_tile.dart';
import 'package:zilpay/mixins/pressable_animation.dart';
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
  final Function(NetworkConfigInfo)? onNetworkEdit;

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
    this.onNetworkEdit,
  });

  @override
  State<NetworkCard> createState() => _NetworkCardState();
}

class _NetworkCardState extends State<NetworkCard>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(
        duration: const Duration(milliseconds: 100), scaleEnd: 0.97);
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: buildPressable(
        onTap: widget.disabled
            ? null
            : () => widget.onNetworkSelect(widget.configInfo),
        disabled: widget.disabled,
        child: NetworkTile(
          iconUrl: widget.iconUrl,
          title: widget.configInfo.name,
          isTestnet: widget.isTestnet,
          isAdded: widget.isAdded,
          isDefault: widget.isDefault,
          isSelected: widget.isSelected,
          disabled: widget.disabled,
          onTap: null,
          onEdit: widget.onNetworkEdit == null
              ? null
              : () => widget.onNetworkEdit!(widget.configInfo),
        ),
      ),
    );
  }
}
