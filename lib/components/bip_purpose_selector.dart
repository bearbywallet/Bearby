import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/config/bip_purposes.dart';
import 'package:bearby/modals/bip_purpose_modal.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final options = getBipPurposeOptions(l10n);
    final selected = options[selectedIndex.clamp(0, options.length - 1)];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: disabled
            ? null
            : () => showBipPurposeModal(
                  context: context,
                  selectedIndex: selectedIndex,
                  onSelect: onSelect,
                ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.cardBackground.withValues(alpha: 0.65),
                    theme.cardBackground.withValues(alpha: 0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryPurple.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryPurple.withValues(alpha: 0.05),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.name,
                          style: theme.labelLarge.copyWith(
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selected.description,
                          style: theme.bodyText2.copyWith(
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/chevron_right.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      theme.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
