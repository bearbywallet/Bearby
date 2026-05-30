import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

/// Swap settings bottom sheet (Price Protection + TWAP). Layout-only for now: the
/// sliders give drag feedback but nothing is persisted — Save just closes, Reset
/// restores the local defaults.
void showSwapSettingsModal({required BuildContext context}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (_) => const _SwapSettingsContent(),
  );
}

class _SwapSettingsContent extends StatefulWidget {
  const _SwapSettingsContent();

  @override
  State<_SwapSettingsContent> createState() => _SwapSettingsContentState();
}

class _SwapSettingsContentState extends State<_SwapSettingsContent> {
  static const double _defaultProtection = 0.1;
  static const double _defaultSubSwaps = 0;
  static const double _defaultTimeBetween = 0;

  double _protection = _defaultProtection;
  double _subSwaps = _defaultSubSwaps;
  double _timeBetween = _defaultTimeBetween;

  void _reset() {
    setState(() {
      _protection = _defaultProtection;
      _subSwaps = _defaultSubSwaps;
      _timeBetween = _defaultTimeBetween;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.cardBackground.withValues(alpha: 0.85),
                  theme.cardBackground.withValues(alpha: 0.95),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: theme.textSecondary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHandle(theme),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProtectionSection(theme, l10n),
                        _divider(theme),
                        _buildTwapSection(theme, l10n),
                        const SizedBox(height: 24),
                        _buildActions(theme, l10n),
                      ],
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

  // --- sections -----------------------------------------------------------

  Widget _buildProtectionSection(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          theme,
          l10n.exchangeSettingsPriceProtection,
          trailing: '${_protection.toStringAsFixed(1)}%',
        ),
        Slider(
          value: _protection,
          min: 0.1,
          max: 5,
          activeColor: theme.success,
          inactiveColor: theme.textSecondary.withValues(alpha: 0.2),
          onChanged: (v) => setState(() => _protection = v),
        ),
      ],
    );
  }

  Widget _buildTwapSection(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(theme, l10n.exchangeSettingsTwap),
        const SizedBox(height: 16),
        _sectionHeader(
          theme,
          l10n.exchangeSettingsSubSwaps,
          trailing: _subSwaps.round().toString(),
        ),
        Slider(
          value: _subSwaps,
          max: 100,
          divisions: 100,
          activeColor: theme.textSecondary.withValues(alpha: 0.2),
          inactiveColor: theme.textSecondary.withValues(alpha: 0.2),
          onChanged: (v) => setState(() => _subSwaps = v),
        ),
        const SizedBox(height: 16),
        _sectionHeader(
          theme,
          l10n.exchangeSettingsTimeBetween,
          trailing: l10n.exchangeSettingsBlocks(_timeBetween.round()),
        ),
        Slider(
          value: _timeBetween,
          max: 3,
          divisions: 3,
          activeColor: theme.textSecondary.withValues(alpha: 0.2),
          inactiveColor: theme.textSecondary.withValues(alpha: 0.2),
          onChanged: (v) => setState(() => _timeBetween = v),
        ),
      ],
    );
  }

  Widget _buildActions(AppTheme theme, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            theme,
            label: l10n.exchangeSettingsReset,
            onTap: _reset,
            filled: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _actionButton(
            theme,
            label: l10n.exchangeSettingsSave,
            onTap: () => Navigator.pop(context),
            filled: true,
          ),
        ),
      ],
    );
  }

  // --- small pieces -------------------------------------------------------

  Widget _buildHandle(AppTheme theme) {
    return Container(
      width: 48,
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _sectionHeader(AppTheme theme, String title, {String? trailing}) {
    final style = theme.bodyLarge.copyWith(
      color: theme.textPrimary,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        Expanded(
          child: Text(title, style: style, overflow: TextOverflow.ellipsis),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Text(trailing, style: style),
        ],
      ],
    );
  }

  Widget _divider(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(
        height: 1,
        color: theme.textSecondary.withValues(alpha: 0.15),
      ),
    );
  }

  Widget _actionButton(
    AppTheme theme, {
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? theme.primaryPurple
              : theme.textSecondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: theme.titleSmall.copyWith(
            color: filled ? theme.buttonText : theme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
