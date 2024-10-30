import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';

enum ButtonState { idle, loading, success, error }

class RoundedLoadingButton extends StatefulWidget {
  final RoundedLoadingButtonController controller;
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final double height;
  final double width;
  final double loaderSize;
  final Color valueColor;
  final double borderRadius;
  final Widget? successIcon;
  final Widget? failedIcon;

  const RoundedLoadingButton({
    super.key,
    required this.controller,
    required this.onPressed,
    required this.child,
    this.color,
    this.height = 56.0,
    this.width = double.infinity,
    this.loaderSize = 24.0,
    this.valueColor = Colors.white,
    this.borderRadius = 30.0,
    this.successIcon,
    this.failedIcon,
  });

  @override
  State<StatefulWidget> createState() => RoundedLoadingButtonState();
}

class RoundedLoadingButtonState extends State<RoundedLoadingButton>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late AnimationController _checkButtonController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _squeezeAnimation;
  late double _actualWidth;
  late ValueNotifier<ButtonState> _stateNotifier;

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _checkButtonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: widget.height).animate(
      CurvedAnimation(
        parent: _checkButtonController,
        curve: Curves.elasticOut,
      ),
    )..addListener(() {
        setState(() {});
      });

    _actualWidth = 0;
    _stateNotifier = widget.controller._stateNotifier;
    widget.controller._addListeners(_start, _stop, _success, _error, _reset);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        _actualWidth = widget.width == double.infinity
            ? constraints.maxWidth
            : widget.width;

        _squeezeAnimation = Tween<double>(
          begin: _actualWidth,
          end: widget.height,
        ).animate(
          CurvedAnimation(
            parent: _buttonController,
            curve: Curves.easeInOutCirc,
          ),
        )..addListener(() {
            setState(() {});
          });

        Widget successIcon = Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.primaryPurple,
            borderRadius: BorderRadius.circular(_bounceAnimation.value / 2),
          ),
          width: _bounceAnimation.value,
          height: _bounceAnimation.value,
          child: _bounceAnimation.value > 20
              ? widget.successIcon ??
                  Icon(
                    Icons.check,
                    color: widget.valueColor,
                  )
              : null,
        );

        Widget errorIcon = Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(_bounceAnimation.value / 2),
          ),
          width: _bounceAnimation.value,
          height: _bounceAnimation.value,
          child: _bounceAnimation.value > 20
              ? widget.failedIcon ??
                  Icon(
                    Icons.close,
                    color: widget.valueColor,
                  )
              : null,
        );

        Widget loader = SizedBox(
          height: widget.loaderSize,
          width: widget.loaderSize,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor),
            strokeWidth: 2.0,
          ),
        );

        Widget childContent = ValueListenableBuilder<ButtonState>(
          valueListenable: _stateNotifier,
          builder: (context, state, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: state == ButtonState.loading ? loader : widget.child,
            );
          },
        );

        final button = ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(_squeezeAnimation.value, widget.height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            backgroundColor: widget.color ?? theme.primaryPurple,
            elevation: 0,
            padding: const EdgeInsets.all(0),
          ),
          onPressed: widget.onPressed,
          child: childContent,
        );

        return AnimatedBuilder(
          animation: _buttonController,
          builder: (context, child) {
            return SizedBox(
              height: widget.height,
              child: ValueListenableBuilder<ButtonState>(
                valueListenable: _stateNotifier,
                builder: (context, state, _) {
                  return Center(
                    child: state == ButtonState.error
                        ? errorIcon
                        : state == ButtonState.success
                            ? successIcon
                            : SizedBox(
                                width: _squeezeAnimation.value,
                                child: button,
                              ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _checkButtonController.dispose();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    _stateNotifier.value = ButtonState.loading;
    _buttonController.forward();
  }

  void _stop() {
    if (!mounted) return;
    _stateNotifier.value = ButtonState.idle;
    _buttonController.reverse();
  }

  void _success() {
    if (!mounted) return;
    _stateNotifier.value = ButtonState.success;
    _checkButtonController.forward();
  }

  void _error() {
    if (!mounted) return;
    _stateNotifier.value = ButtonState.error;
    _checkButtonController.forward();
  }

  void _reset() {
    if (!mounted) return;
    _stateNotifier.value = ButtonState.idle;
    _buttonController.reverse();
    _checkButtonController.reset();
  }
}

class RoundedLoadingButtonController {
  VoidCallback? _startListener;
  VoidCallback? _stopListener;
  VoidCallback? _successListener;
  VoidCallback? _errorListener;
  VoidCallback? _resetListener;

  final ValueNotifier<ButtonState> _stateNotifier =
      ValueNotifier(ButtonState.idle);

  void _addListeners(
    VoidCallback startListener,
    VoidCallback stopListener,
    VoidCallback successListener,
    VoidCallback errorListener,
    VoidCallback resetListener,
  ) {
    _startListener = startListener;
    _stopListener = stopListener;
    _successListener = successListener;
    _errorListener = errorListener;
    _resetListener = resetListener;
  }

  ButtonState get currentState => _stateNotifier.value;

  void start() {
    if (_startListener != null) _startListener!();
  }

  void stop() {
    if (_stopListener != null) _stopListener!();
  }

  void success() {
    if (_successListener != null) _successListener!();
  }

  void error() {
    if (_errorListener != null) _errorListener!();
  }

  void reset() {
    if (_resetListener != null) _resetListener!();
  }

  void dispose() {
    _stateNotifier.dispose();
  }
}
