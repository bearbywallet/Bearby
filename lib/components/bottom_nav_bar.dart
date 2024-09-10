import 'package:flutter/material.dart';

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
      height: 56,
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
                child: Icon(
                  item.icon,
                  color: index == currentIndex ? Colors.purple : Colors.grey,
                  size: 24,
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
  final IconData icon;

  CustomBottomNavigationBarItem({required this.icon});
}

