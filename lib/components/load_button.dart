import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final String? successIcon;
  final String? failedSvgAsset;
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
    this.successIcon = 'assets/icons/ok.svg',
    this.failedSvgAsset = 'assets/icons/close.svg',
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

        Widget successIcon = ClipRRect(
          borderRadius: BorderRadius.circular(_bounceAnimation.value / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.success.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(_bounceAnimation.value / 2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              width: _bounceAnimation.value,
              height: _bounceAnimation.value,
              child: _bounceAnimation.value > 20
                  ? SvgPicture.asset(
                      widget.successIcon!,
                      width: widget.loaderSize,
                      height: widget.loaderSize,
                      colorFilter: ColorFilter.mode(
                        widget.valueColor,
                        BlendMode.srcIn,
                      ),
                    )
                  : null,
            ),
          ),
        );

        Widget errorIcon = ClipRRect(
          borderRadius: BorderRadius.circular(_bounceAnimation.value / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.errorColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(_bounceAnimation.value / 2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              width: _bounceAnimation.value,
              height: _bounceAnimation.value,
              child: _bounceAnimation.value > 20
                  ? SvgPicture.asset(
                      widget.failedSvgAsset!,
                      width: widget.loaderSize,
                      height: widget.loaderSize,
                      colorFilter: ColorFilter.mode(
                        widget.valueColor,
                        BlendMode.srcIn,
                      ),
                    )
                  : null,
            ),
          ),
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

        final button = Container(
          decoration: BoxDecoration(
            color: widget.color ?? theme.buttonBackground,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: (widget.color ?? theme.buttonBackground)
                    .withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(_squeezeAnimation.value, widget.height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: theme.buttonText,
              elevation: 0,
              padding: EdgeInsets.zero,
              shadowColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: Colors.transparent,
            ),
            onPressed: widget.onPressed,
            child: buttonContent,
          ),
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
