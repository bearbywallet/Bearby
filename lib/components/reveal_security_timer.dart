import 'package:flutter/material.dart';
import 'package:bearby/config/settings.dart';
import 'package:bearby/theme/app_theme.dart';

/// Minimal countdown — just the clock and progress bar. No labels.
class RevealSecurityTimer extends StatelessWidget {
  final AppTheme theme;
  final int remainingSeconds;

  const RevealSecurityTimer({
    super.key,
    required this.theme,
    required this.remainingSeconds,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final buffer = StringBuffer()
      ..write(minutes.toString().padLeft(2, '0'))
      ..write(':')
      ..write(secs.toString().padLeft(2, '0'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final total = SecuritySettings.revealDelaySeconds;
    final progress = total <= 0
        ? 1.0
        : 1 - (remainingSeconds / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(remainingSeconds),
            style: theme.displayLarge.copyWith(
              color: theme.primaryPurple,
              fontFamily: 'monospace',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.background,
              valueColor: AlwaysStoppedAnimation(theme.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}
