import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/state/app_state.dart';

class ListItem {
  final String title;
  final String? subtitle;
  final String? iconPath;

  ListItem({
    required this.title,
    this.subtitle,
    this.iconPath,
  });
}

void showListSelectorModal({
  required BuildContext context,
  required String title,
  required List<ListItem> items,
  required int selectedIndex,
  required Function(int) onItemSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ListSelectorModalContent(
          title: title,
          items: items,
          selectedIndex: selectedIndex,
          onItemSelected: onItemSelected,
        ),
      );
    },
  );
}

class _ListSelectorModalContent extends StatefulWidget {
  final String title;
  final List<ListItem> items;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const _ListSelectorModalContent({
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<_ListSelectorModalContent> createState() =>
      _ListSelectorModalContentState();
}

class _ListSelectorModalContentState extends State<_ListSelectorModalContent> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.modalBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.title,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: widget.items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: theme.textSecondary.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = _selectedIndex == index;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    widget.onItemSelected(index);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        if (item.iconPath != null) ...[
                          SvgPicture.asset(
                            item.iconPath!,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              theme.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              if (item.subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle!,
                                  style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          SvgPicture.asset(
                            'assets/icons/ok.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
