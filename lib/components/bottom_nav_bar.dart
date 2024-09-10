import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final List<CustomBottomNavigationBarItem> items;
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomNavigationBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.black,
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
                  color: index == currentIndex ? Colors.purple : Colors.grey,
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CustomBottomNavigationBarItem {
  final String iconPath;

  CustomBottomNavigationBarItem({required this.iconPath});
}

