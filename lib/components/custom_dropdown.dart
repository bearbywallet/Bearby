import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class CustomDropdown extends StatefulWidget {
  final List<dynamic> items;
  final int selectedItem;
  final Function(int) onChanged;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late OverlayEntry _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return GestureDetector(
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.primaryPurple,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.selectedItem.toString(),
              style: TextStyle(color: theme.textPrimary, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Icon(
              _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDropdown() {
    if (_isExpanded) {
      _animationController.reverse().then((_) {
        if (_overlayEntry.mounted) {
          _overlayEntry.remove();
        }
      });
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry);
      _animationController.forward();
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) {
        final theme = Provider.of<ThemeProvider>(context).currentTheme;
        return GestureDetector(
          onTap: () => _toggleDropdown(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height,
                width: size.width,
                child: SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: 1,
                  child: Material(
                    elevation: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: widget.items.map((item) {
                          return InkWell(
                            onTap: () {
                              widget.onChanged(item);
                              _toggleDropdown();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: Text(
                                item.toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
