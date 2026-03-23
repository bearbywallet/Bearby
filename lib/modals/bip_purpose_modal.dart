import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/option_list.dart';
import 'package:bearby/components/bip_purpose_selector.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/l10n/app_localizations.dart';

void showBipPurposeModal({
  required BuildContext context,
  required int selectedIndex,
  required Function(int) onSelect,
}) {
  showModalBottomSheet(
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
        child: _BipPurposeModalContent(
          selectedIndex: selectedIndex,
          onSelect: onSelect,
        ),
      );
    },
  );
}

class _BipPurposeModalContent extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const _BipPurposeModalContent({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<_BipPurposeModalContent> createState() =>
      _BipPurposeModalContentState();
}

class _BipPurposeModalContentState extends State<_BipPurposeModalContent> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final options = BipPurposeSelector.getBipPurposeOptions(l10n);

    return Container(
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
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l10n.bipPurposeSetupPageTitle,
              style: theme.bodyLarge.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OptionsList(
              options: List.generate(
                options.length,
                (index) => OptionItem(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        options[index].name,
                        style: theme.labelLarge.copyWith(
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        options[index].description,
                        style: theme.bodyText2.copyWith(
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  isSelected: _currentIndex == index,
                  onSelect: () {
                    setState(() => _currentIndex = index);
                    Navigator.pop(context);
                    widget.onSelect(index);
                  },
                ),
              ),
              unselectedOpacity: 0.5,
            ),
          ),
          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
