import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class LinearRefreshIndicator extends StatefulWidget {
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
  State<LinearRefreshIndicator> createState() => _LinearRefreshIndicatorState();
}

class _LinearRefreshIndicatorState extends State<LinearRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasStartedLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(LinearRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pulledExtent >= widget.refreshTriggerPullDistance &&
        !_hasStartedLoading) {
      _hasStartedLoading = true;
      _controller.forward();
    }

    if (widget.pulledExtent < widget.refreshTriggerPullDistance) {
      _hasStartedLoading = false;
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final double progress =
        (widget.pulledExtent / widget.refreshTriggerPullDistance)
            .clamp(0.0, 1.0);

    return SizedBox(
      height: widget.refreshIndicatorExtent,
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: 2.0,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Center(
                child: Container(
                  height: 2.0,
                  width: (MediaQuery.of(context).size.width * 0.6) *
                      progress *
                      _animation.value,
                  decoration: BoxDecoration(
                    color: theme.primaryPurple,
                    borderRadius: BorderRadius.circular(2),
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
