import 'package:bearby/components/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/state/app_state.dart';

/// Shared bottom-sheet shell used by token-selection modals.
///
/// Handles the identical container, handle bar, search input, and
/// [ListView.separated] scaffolding. Each modal owns its own search state and
/// domain filtering; this widget just renders the common chrome.
class TokenSelectSheet extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;

  const TokenSelectSheet({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchHint,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const headerHeight = 84.0;
    const searchBarHeight = 80.0;
    const tokenItemHeight = 72.0;

    final totalContentHeight = headerHeight +
        searchBarHeight +
        (itemCount * tokenItemHeight) +
        bottomPadding;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final containerHeight = totalContentHeight.clamp(0.0, maxHeight);

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
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
            child: SmartInput(
              controller: searchController,
              hint: searchHint,
              leftIcon: AppIcon.search,
              onChanged: onSearchChanged,
              borderColor: theme.textPrimary,
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: itemCount,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: theme.textSecondary.withValues(alpha: 0.1),
              ),
              itemBuilder: itemBuilder,
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
