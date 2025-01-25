import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class NodeData {
  final String name;
  final String url;

  NodeData(this.name, this.url);
}

class NodeSelectionModal extends StatefulWidget {
  final AppTheme theme;
  final bool isMainnet;
  final String selectedMainnetNode;
  final String selectedTestnetNode;
  final Function(String) onNodeSelected;

  const NodeSelectionModal({
    super.key,
    required this.theme,
    required this.isMainnet,
    required this.selectedMainnetNode,
    required this.selectedTestnetNode,
    required this.onNodeSelected,
  });

  @override
  State<NodeSelectionModal> createState() => _NodeSelectionModalState();
}

class _NodeSelectionModalState extends State<NodeSelectionModal> {
  final List<NodeData> mainnetNodes = [
    NodeData('Zilliqa mainnet', 'api.zilliqa.com'),
    NodeData('Zilliqa mainnet backup', 'api-backup.zilliqa.com'),
  ];

  final List<NodeData> testnetNodes = [
    NodeData('Zilliqa testnet', 'dev-api.zilliqa.com'),
    NodeData('Zilliqa testnet backup', 'dev-api-backup.zilliqa.com'),
  ];

  @override
  Widget build(BuildContext context) {
    final nodes = widget.isMainnet ? mainnetNodes : testnetNodes;
    final selectedNode = widget.isMainnet
        ? widget.selectedMainnetNode
        : widget.selectedTestnetNode;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Close indicator
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: widget.theme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: nodes.length,
                itemBuilder: (context, index) {
                  final node = nodes[index];
                  final isSelected = node.url == selectedNode;
                  final isLastItem = index == nodes.length - 1;

                  return _buildNodeItem(
                    widget.theme,
                    node,
                    isSelected,
                    isLastItem,
                    onTap: () {
                      widget.onNodeSelected(node.url);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeItem(
    AppTheme theme,
    NodeData node,
    bool isSelected,
    bool isLastItem, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: !isLastItem
              ? Border(
                  bottom: BorderSide(
                    color: theme.textSecondary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              node.name,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    node.url,
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: isSelected
                      ? SvgPicture.asset(
                          'assets/icons/ok.svg',
                          colorFilter: ColorFilter.mode(
                            theme.primaryPurple,
                            BlendMode.srcIn,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
