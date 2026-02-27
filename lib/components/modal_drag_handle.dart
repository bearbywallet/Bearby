import 'package:flutter/material.dart';
import 'package:bearby/theme/app_theme.dart';

class ModalDragHandle extends StatelessWidget {
  final AppTheme theme;

  const ModalDragHandle({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.modalBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
