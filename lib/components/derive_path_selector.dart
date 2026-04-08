import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/config/derive_path.dart';
import 'package:bearby/modals/derive_path_modal.dart';
import 'package:bearby/state/app_state.dart';

class DerivePathSelector extends StatelessWidget {
  final DerivePathType type;
  final int bipPurpose;
  final int slip44;
  final Function(DerivePathType type) onChanged;
  final bool disabled;

  const DerivePathSelector({
    super.key,
    required this.type,
    required this.bipPurpose,
    required this.slip44,
    required this.onChanged,
    this.disabled = false,
  });

  static String typeName(DerivePathType type) {
    switch (type) {
      case DerivePathType.root:
        return 'Root';
      case DerivePathType.account:
        return 'Account';
      case DerivePathType.accountChange:
        return 'AccountChange';
      case DerivePathType.addressIndex:
        return 'AddressIndex';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final pathPreview = buildDerivePath(
      type: type,
      bipPurpose: bipPurpose,
      slip44: slip44,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: disabled
            ? null
            : () => showDerivePathModal(
                  context: context,
                  currentType: type,
                  bipPurpose: bipPurpose,
                  slip44: slip44,
                  onChanged: onChanged,
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
                          typeName(type),
                          style: theme.labelLarge.copyWith(
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pathPreview,
                          style: theme.bodyText2.copyWith(
                            color: theme.textSecondary,
                            fontFamily: 'monospace',
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
