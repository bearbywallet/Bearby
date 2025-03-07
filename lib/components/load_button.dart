import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

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
  final Color errorColor;

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
    this.errorColor = Colors.red,
  });

  @override
  State<RoundedLoadingButton> createState() => _RoundedLoadingButtonState();
}

class _RoundedLoadingButtonState extends State<RoundedLoadingButton>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late AnimationController _resultIconController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _squeezeAnimation;
  late double _buttonWidth;

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _resultIconController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: widget.height).animate(
      CurvedAnimation(
        parent: _resultIconController,
        curve: Curves.elasticOut,
      ),
    )..addListener(() {
        setState(() {});
      });

    _buttonWidth = 0;

    widget.controller._addListeners(_start, _stop, _success, _error, _reset);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        _buttonWidth = widget.width == double.infinity
            ? constraints.maxWidth
            : widget.width;

        _squeezeAnimation = Tween<double>(
          begin: _buttonWidth,
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
            color: theme.success,
            borderRadius: BorderRadius.circular(_bounceAnimation.value / 2),
          ),
          width: _bounceAnimation.value,
          height: _bounceAnimation.value,
          child: _bounceAnimation.value > 20
              ? widget.successIcon ??
                  Icon(Icons.check, color: widget.valueColor)
              : null,
        );

        Widget errorIcon = Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.errorColor,
            borderRadius: BorderRadius.circular(_bounceAnimation.value / 2),
          ),
          width: _bounceAnimation.value,
          height: _bounceAnimation.value,
          child: _bounceAnimation.value > 20
              ? widget.failedIcon ?? Icon(Icons.close, color: widget.valueColor)
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

        Widget buttonContent = ValueListenableBuilder<ButtonState>(
          valueListenable: widget.controller._stateNotifier,
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
            backgroundColor: widget.color ?? theme.buttonBackground,
            foregroundColor: theme.buttonText,
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          onPressed: widget.onPressed,
          child: buttonContent,
        );

        return SizedBox(
          height: widget.height,
          child: ValueListenableBuilder<ButtonState>(
            valueListenable: widget.controller._stateNotifier,
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
  }

  void _start() {
    if (!mounted) return;
    _buttonController.forward();
  }

  void _stop() {
    if (!mounted) return;
    _buttonController.reverse();
  }

  void _success() {
    if (!mounted) return;
    _resultIconController.forward();
  }

  void _error() {
    if (!mounted) return;
    _resultIconController.forward();
  }

  void _reset() {
    if (!mounted) return;
    _buttonController.reverse();
    _resultIconController.reset();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _resultIconController.dispose();
    super.dispose();
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

  ButtonState get currentState => _stateNotifier.value;

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

  void start() {
    _stateNotifier.value = ButtonState.loading;
    if (_startListener != null) _startListener!();
  }

  void stop() {
    _stateNotifier.value = ButtonState.idle;
    if (_stopListener != null) _stopListener!();
  }

  void success() {
    _stateNotifier.value = ButtonState.success;
    if (_successListener != null) _successListener!();
  }

  void error() {
    _stateNotifier.value = ButtonState.error;
    if (_errorListener != null) _errorListener!();
  }

  void reset() {
    _stateNotifier.value = ButtonState.idle;
    if (_resetListener != null) _resetListener!();
  }

  void dispose() {
    _stateNotifier.dispose();
  }
}
