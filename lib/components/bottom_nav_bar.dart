import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:bearby/state/app_state.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final List<CustomBottomNavigationBarItem> items;
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Container(
      width: double.infinity,
      height: 80,
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: 600,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10.0,
                sigmaY: 10.0,
              ),
              child: SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: items.asMap().entries.map((entry) {
                    int index = entry.key;
                    CustomBottomNavigationBarItem item = entry.value;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(index),
                        child: Container(
                          color: Colors.transparent,
                          child: SvgPicture.asset(
                            item.iconPath,
                            colorFilter: ColorFilter.mode(
                              index == currentIndex
                                  ? theme.primaryPurple
                                  : theme.textSecondary,
                              BlendMode.srcIn,
                            ),
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomBottomNavigationBarItem {
  final String iconPath;

  CustomBottomNavigationBarItem({required this.iconPath});
}
