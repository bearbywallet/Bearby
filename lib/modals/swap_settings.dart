import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/state/exchange_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

void showSwapSettingsModal({
  required BuildContext context,
  required ExchangeProvider activeProvider,
  required ExchangeState exchangeState,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (_) => _SwapSettingsContent(
      activeProvider: activeProvider,
      exchangeState: exchangeState,
    ),
  );
}

class _SwapSettingsContent extends StatefulWidget {
  final ExchangeProvider activeProvider;
  final ExchangeState exchangeState;

  const _SwapSettingsContent({
    required this.activeProvider,
    required this.exchangeState,
  });

  @override
  State<_SwapSettingsContent> createState() => _SwapSettingsContentState();
}

class _SwapSettingsContentState extends State<_SwapSettingsContent> {
  late double _protection;

  @override
  void initState() {
    super.initState();
    _protection = widget.exchangeState.slippageFor(widget.activeProvider) / 100.0;
  }

  void _reset() {
    setState(() => _protection = widget.activeProvider.defaultSlippageBps / 100.0);
  }

  void _save() {
    final bps = (_protection * 100).round().clamp(10, 500);
    widget.exchangeState.setSlippage(widget.activeProvider.common.displayName, bps);
    Navigator.pop(context);
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        Text(
                          '${widget.activeProvider.common.displayName} Settings',
                          style: theme.titleMedium.copyWith(color: theme.textPrimary),
                        ),
                        const SizedBox(height: 20),
                        _buildProtectionSection(theme, l10n),
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
            onTap: _save,
            filled: true,
          ),
        ),
      ],
    );
  }

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
        Expanded(child: Text(title, style: style, overflow: TextOverflow.ellipsis)),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Text(trailing, style: style),
        ],
      ],
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
          color: filled ? theme.primaryPurple : theme.textSecondary.withValues(alpha: 0.12),
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
