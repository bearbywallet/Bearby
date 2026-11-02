import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

enum MnemonicValidation { none, valid, invalid }

class MnemonicWordInput extends StatefulWidget {
  final int index;
  final String word;
  final bool isEditable;
  final bool hasError;
  final MnemonicValidation validation;
  final double opacity;
  final Function(int, String)? onChanged;
  final bool compact;
  final bool isActive;
  final bool obscureWhenUnfocused;
  final VoidCallback? onTap;
  final ValueChanged<int>? onFocusIndex;
  final ValueChanged<int>? onNextRequested;

  const MnemonicWordInput({
    super.key,
    required this.index,
    required this.word,
    this.onChanged,
    this.opacity = 1,
    this.isEditable = false,
    this.hasError = false,
    this.validation = MnemonicValidation.none,
    this.compact = false,
    this.isActive = false,
    this.obscureWhenUnfocused = true,
    this.onTap,
    this.onFocusIndex,
    this.onNextRequested,
  });

  @override
  State<MnemonicWordInput> createState() => _MnemonicWordInputState();
}

class _MnemonicWordInputState extends State<MnemonicWordInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _shouldUpdateText = true;
  bool _isObscured = true;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.word);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _isObscured = widget.isEditable && widget.obscureWhenUnfocused;
  }

  void _handleFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused) {
      widget.onFocusIndex?.call(widget.index - 1);
    }
    if (widget.isEditable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasFocus = focused;
            _isObscured = widget.obscureWhenUnfocused &&
                !focused &&
                _controller.text.isNotEmpty;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(MnemonicWordInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldForceUpdate = widget.word != _controller.text &&
        (_shouldUpdateText || !widget.word.contains(_controller.text));

    if (shouldForceUpdate) {
      _controller.text = widget.word;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _isObscured = widget.isEditable &&
          widget.obscureWhenUnfocused &&
          !_focusNode.hasFocus &&
          widget.word.isNotEmpty;
    }

    if (widget.isActive && !oldWidget.isActive && widget.isEditable) {
      if (!_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.isActive && !_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    }
    _shouldUpdateText = true;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color _getBorderColor(AppTheme theme) {
    if (widget.hasError) return theme.danger;
    if (_hasFocus || widget.isActive) return theme.primaryPurple;
    switch (widget.validation) {
      case MnemonicValidation.valid:
        return theme.success;
      case MnemonicValidation.invalid:
        return theme.danger;
      case MnemonicValidation.none:
        return theme.modalBorder;
    }
  }

  Color _getTextColor(AppTheme theme) {
    if (widget.hasError) return theme.danger;
    switch (widget.validation) {
      case MnemonicValidation.valid:
        return theme.textPrimary;
      case MnemonicValidation.invalid:
        return theme.danger;
      case MnemonicValidation.none:
        return theme.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final textColor = _getTextColor(theme);
    final activeOrFocused = _hasFocus || widget.isActive;
    final hasValidation = widget.hasError ||
        activeOrFocused ||
        widget.validation != MnemonicValidation.none;
    final borderColor = _getBorderColor(theme);

    if (widget.compact) {
      return GestureDetector(
        onTap: widget.onTap ??
            (widget.isEditable ? () => _focusNode.requestFocus() : null),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: theme.cardBackground.withValues(alpha: 0.75 * widget.opacity),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activeOrFocused
                  ? theme.primaryPurple.withValues(alpha: 0.8)
                  : widget.hasError
                      ? theme.danger.withValues(alpha: 0.7)
                      : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Text(
                '${widget.index}',
                style: theme.caption.copyWith(
                  color: widget.hasError
                      ? theme.danger
                      : activeOrFocused
                          ? theme.primaryPurple
                          : theme.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  style: theme.bodyText2.copyWith(
                    color: textColor,
                    fontSize: 13.5,
                  ),
                  enabled: widget.isEditable,
                  obscureText: _isObscured,
                  enableInteractiveSelection: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) {
                    widget.onNextRequested?.call(widget.index - 1);
                  },
                  onChanged: (value) {
                    _shouldUpdateText = false;
                    if (widget.isEditable) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _isObscured = widget.obscureWhenUnfocused &&
                                !_focusNode.hasFocus &&
                                value.isNotEmpty;
                          });
                        }
                      });
                    }
                    widget.onChanged?.call(widget.index, value);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: 0.8 * widget.opacity),
        borderRadius: BorderRadius.circular(12),
        border: hasValidation
            ? Border.all(color: borderColor.withValues(alpha: 0.6), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Text(
            '${widget.index}',
            style: theme.bodyText2.copyWith(color: theme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: theme.bodyText1.copyWith(color: textColor),
              enabled: widget.isEditable,
              obscureText: _isObscured,
              enableInteractiveSelection: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                _shouldUpdateText = false;
                if (widget.isEditable) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _isObscured = widget.obscureWhenUnfocused &&
                            !_focusNode.hasFocus &&
                            value.isNotEmpty;
                      });
                    }
                  });
                }
                widget.onChanged?.call(widget.index, value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
