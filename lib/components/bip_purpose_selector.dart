import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/config/bip_purposes.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class BipPurposeOption {
  final int purpose;
  final String name;
  final String description;

  BipPurposeOption({
    required this.purpose,
    required this.name,
    required this.description,
  });
}

class BipPurposeSelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  final bool disabled;

  const BipPurposeSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.disabled = false,
  });

  static List<BipPurposeOption> getBipPurposeOptions(AppLocalizations l10n) {
    return [
      BipPurposeOption(
        purpose: kBip86Purpose,
        name: l10n.bip86Name,
        description: l10n.bip86Description,
      ),
      BipPurposeOption(
        purpose: kBip84Purpose,
        name: l10n.bip84Name,
        description: l10n.bip84Description,
      ),
      BipPurposeOption(
        purpose: kBip49Purpose,
        name: l10n.bip49Name,
        description: l10n.bip49Description,
      ),
      BipPurposeOption(
        purpose: kBip44Purpose,
        name: l10n.bip44Name,
        description: l10n.bip44Description,
      ),
    ];
  }

  OptionItem _buildPurposeItem(
    BipPurposeOption option,
    AppTheme theme,
    int index,
  ) {
    return OptionItem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.name,
            style: theme.labelLarge.copyWith(
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            option.description,
            style: theme.bodyText2.copyWith(
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
      isSelected: selectedIndex == index,
      onSelect: () => onSelect(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final options = getBipPurposeOptions(l10n);

    return OptionsList(
      options: List.generate(
        options.length,
        (index) => _buildPurposeItem(options[index], theme, index),
      ),
      unselectedOpacity: 0.5,
      disabled: disabled,
    );
  }
}
