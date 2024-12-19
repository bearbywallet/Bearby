import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class InputAmount extends StatefulWidget {
  final TextEditingController? controller;
  final String? tokenLabel;
  final String? tokenIconPath;
  final String? equivalentValue;
  final VoidCallback? onMaxPressed;
  final ValueChanged<String>? onChanged;
  final bool disabled;

  const InputAmount({
    super.key,
    this.controller,
    this.tokenLabel = 'ETH',
    this.tokenIconPath,
    this.equivalentValue = '\$0.00',
    this.onMaxPressed,
    this.onChanged,
    this.disabled = false,
  });

  @override
  State<InputAmount> createState() => _InputAmountState();
}

class _InputAmountState extends State<InputAmount> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: widget.disabled
            ? theme.cardColor.withOpacity(0.5)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? theme.primaryColor : theme.dividerColor,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Token Icon
          if (widget.tokenIconPath != null)
            Image.asset(
              widget.tokenIconPath!,
              width: 24,
              height: 24,
            ),
          const SizedBox(width: 8),

          // Token Label
          Text(
            widget.tokenLabel ?? '',
            style: theme.textTheme.bodyText1,
          ),
          const SizedBox(width: 16),

          // Amount Input Field
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              enabled: !widget.disabled,
              onChanged: widget.onChanged,
              style: TextStyle(
                color: widget.disabled
                    ? theme.hintColor
                    : theme.textTheme.bodyText1?.color,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(
                  color: widget.disabled
                      ? theme.hintColor
                      : theme.textTheme.bodyText2?.color,
                ),
              ),
            ),
          ),

          // Max Button
          if (widget.onMaxPressed != null)
            GestureDetector(
              onTap: widget.disabled ? null : widget.onMaxPressed,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.disabled
                      ? theme.primaryColor.withOpacity(0.3)
                      : theme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Max',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),

          // Equivalent Value
          Text(
            widget.equivalentValue ?? '\$0.00',
            style: theme.textTheme.caption?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
