import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/config/bip_purposes.dart';
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

    return Column(
      children: List.generate(
        options.length,
        (index) => _GlassOptionTile(
          key: ValueKey(index),
          name: options[index].name,
          description: options[index].description,
          isSelected: selectedIndex == index,
          hasSelection: selectedIndex >= 0,
          disabled: disabled,
          onTap: () => onSelect(index),
          theme: theme,
        ),
      ),
    );
  }
}

class _GlassOptionTile extends StatelessWidget {
  final String name;
  final String description;
  final bool isSelected;
  final bool hasSelection;
  final bool disabled;
  final VoidCallback onTap;
  final dynamic theme;

  const _GlassOptionTile({
    super.key,
    required this.name,
    required this.description,
    required this.isSelected,
    required this.hasSelection,
    required this.disabled,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled
            ? 0.5
            : hasSelection && !isSelected
                ? 0.5
                : 1.0,
        child: GestureDetector(
          onTap: disabled ? null : onTap,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0, end: isSelected ? 1.0 : 0.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.cardBackground
                              .withValues(alpha: 0.65 + value * 0.15),
                          theme.cardBackground
                              .withValues(alpha: 0.75 + value * 0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color.lerp(
                          theme.primaryPurple.withValues(alpha: 0.15),
                          disabled
                              ? theme.textSecondary
                              : theme.primaryPurple,
                          value,
                        )!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryPurple
                              .withValues(alpha: 0.05 + value * 0.05),
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
                                name,
                                style: theme.labelLarge.copyWith(
                                  color: theme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: theme.bodyText2.copyWith(
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? disabled
                                      ? theme.textSecondary
                                      : theme.primaryPurple
                                  : theme.primaryPurple
                                      .withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: isSelected ? 1.0 : 0.0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: disabled
                                      ? theme.textSecondary
                                      : theme.primaryPurple,
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
            },
          ),
        ),
      ),
    );
  }
}
