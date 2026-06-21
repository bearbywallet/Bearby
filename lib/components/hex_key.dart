import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/state/app_state.dart';

class HexKeyDisplay extends StatefulWidget {
  final String hexKey;
  final String title;

  const HexKeyDisplay({
    super.key,
    required this.hexKey,
    required this.title,
  });

  @override
  State<HexKeyDisplay> createState() => _HexKeyDisplayState();
}

class _HexKeyDisplayState extends State<HexKeyDisplay> {
  List<bool> animationStates = [];
  List<String> currentPairs = [];
  List<String> targetPairs = [];

  @override
  void initState() {
    super.initState();
    _initializePairs();
  }

  void _initializePairs() {
    currentPairs = _getPairs(widget.hexKey);
    targetPairs = List.from(currentPairs);
    animationStates = List.generate(currentPairs.length, (_) => false);
  }

  @override
  void didUpdateWidget(HexKeyDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hexKey != widget.hexKey) {
      targetPairs = _getPairs(widget.hexKey);
      if (targetPairs.length != currentPairs.length) {
        currentPairs = List.from(targetPairs);
        animationStates = List.generate(currentPairs.length, (_) => false);
      }
      _startAnimation();
    }
  }

  List<String> _getPairs(String key) {
    if (key.isEmpty) return [];

    final cleanKey = key.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    final pairCount = cleanKey.length ~/ 2;
    final pairs = List<String>.filled(pairCount, '');

    for (var i = 0; i < pairCount; i++) {
      pairs[i] = cleanKey.substring(i * 2, i * 2 + 2);
    }
    return pairs;
  }

  void _startAnimation() {
    if (currentPairs.isEmpty) return;

    const stepDelayMs = 30;
    const revealFlashDuration = Duration(milliseconds: 80);

    for (var i = 0; i < currentPairs.length; i++) {
      final totalDelay = stepDelayMs * (i + 1);
      Future.delayed(Duration(milliseconds: totalDelay), () {
        if (!mounted) return;
        setState(() {
          animationStates[i] = true;
          currentPairs[i] = targetPairs[i];
        });

        Future.delayed(revealFlashDuration, () {
          if (!mounted) return;
          setState(() {
            animationStates[i] = false;
          });
        });
      });
    }
  }

  /// Number of hex pairs per row, derived from the [width] actually available
  /// to this widget (not the screen width).
  int _getChunkSize(double width) {
    if (width < 360) return 4;
    if (width < 420) return 6;
    if (width < 600) return 8;
    if (width < 905) return 10;
    return 12;
  }

  List<List<String>> _chunkPairs(int chunkSize) {
    if (currentPairs.isEmpty) return [];

    final chunks = <List<String>>[];
    for (var i = 0; i < currentPairs.length; i += chunkSize) {
      final end = i + chunkSize > currentPairs.length
          ? currentPairs.length
          : i + chunkSize;
      chunks.add(currentPairs.sublist(i, end));
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = context.read<AppState>().currentTheme;

    return Container(
      padding: EdgeInsets.all(adaptivePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: adaptivePadding),
            child: Text(
              widget.title,
              style: theme.titleSmall.copyWith(
                color: theme.textSecondary,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final chunkSize = _getChunkSize(constraints.maxWidth);
              final chunks = _chunkPairs(chunkSize);
              final itemWidth = constraints.maxWidth / chunkSize;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: chunks.asMap().entries.map((chunkEntry) {
                  final rowOffset = chunkEntry.key * chunkSize;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: chunkEntry.value.asMap().entries.map((pairEntry) {
                        final globalIndex = rowOffset + pairEntry.key;
                        final isAnimating = globalIndex < animationStates.length
                            ? animationStates[globalIndex]
                            : false;

                        return SizedBox(
                          width: itemWidth,
                          child: Text(
                            pairEntry.value,
                            textAlign: TextAlign.center,
                            style: theme.bodyText1.copyWith(
                              color: isAnimating
                                  ? theme.secondaryPurple
                                  : theme.textPrimary,
                              fontFamily: 'Courier',
                              fontSize: itemWidth < 40 ? 14 : 16,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
