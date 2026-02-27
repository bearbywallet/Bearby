import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/state/app_state.dart';

class LinearRefreshIndicator extends StatelessWidget {
  final double pulledExtent;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;

  const LinearRefreshIndicator({
    super.key,
    required this.pulledExtent,
    required this.refreshTriggerPullDistance,
    required this.refreshIndicatorExtent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final progress =
        (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);

    return Container(
      height: refreshIndicatorExtent,
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: 120,
        height: 3,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.cardBackground.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryPurple),
          minHeight: 3,
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
  }
}

class LinearLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const LinearLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(theme.primaryPurple),
      ),
    );
  }
}
