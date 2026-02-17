import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class LinearRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const LinearRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: theme.primaryPurple,
      backgroundColor: theme.cardBackground.withValues(alpha: 0.9),
      strokeWidth: 2.0,
      semanticsLabel: 'Refreshing',
      semanticsValue: 'Pull to refresh',
      child: child,
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
