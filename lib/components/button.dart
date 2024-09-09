import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final Color color;
  final double width;
  final double height;
  final double borderRadius;
  final double fontSize;
  final Future<void> Function() onPressed;
  final Color loaderColor;

  const CustomButton({
    Key? key,
    required this.text,
    this.color = const Color(0xFF9C27B0),
    this.width = double.infinity,
    this.height = 48,
    this.borderRadius = 24,
    this.fontSize = 16,
    required this.onPressed,
    this.loaderColor = const Color(0xFFFFFFFF),
  }) : super(key: key);

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isLoading = false;

  void _handlePress() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _handlePress,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: widget.height / 2,
                  height: widget.height / 2,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(widget.loaderColor),
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  widget.text,
                  style: TextStyle(
                    color: const Color(0xFFFFFFFF),
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
