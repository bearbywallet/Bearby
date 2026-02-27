import 'dart:ui';
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

  const MnemonicWordInput({
    super.key,
    required this.index,
    required this.word,
    this.onChanged,
    this.opacity = 1,
    this.isEditable = false,
    this.hasError = false,
    this.validation = MnemonicValidation.none,
  });

  @override
  State<MnemonicWordInput> createState() => _MnemonicWordInputState();
}

class _MnemonicWordInputState extends State<MnemonicWordInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _shouldUpdateText = true;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.word);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _isObscured = widget.isEditable;
  }

  void _handleFocusChange() {
    if (widget.isEditable) {
      setState(() {
        _isObscured = !_focusNode.hasFocus && _controller.text.isNotEmpty;
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
      _isObscured =
          widget.isEditable && !_focusNode.hasFocus && widget.word.isNotEmpty;
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
        return theme.success;
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
    final hasValidation =
        widget.hasError || widget.validation != MnemonicValidation.none;
    final borderColor = hasValidation ? _getBorderColor(theme) : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardBackground.withValues(alpha: 0.6 * widget.opacity),
            borderRadius: BorderRadius.circular(12),
            border: hasValidation
                ? Border.all(
                    color: borderColor!.withValues(alpha: 0.6), width: 1)
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    _shouldUpdateText = false;
                    if (widget.isEditable) {
                      setState(() {
                        _isObscured = !_focusNode.hasFocus && value.isNotEmpty;
                      });
                    }
                    widget.onChanged?.call(widget.index, value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
