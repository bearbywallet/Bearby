import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';

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
    final pairs = <String>[];
    for (var i = 0; i < cleanKey.length; i += 2) {
      if (i + 2 <= cleanKey.length) {
        pairs.add(cleanKey.substring(i, i + 2));
      }
    }
    return pairs;
  }

  void _startAnimation() {
    if (currentPairs.isEmpty) return;

    double delayMs = 30;
    double acceleration = 1.0; // Factor of animation

    for (var i = 0; i < currentPairs.length; i++) {
      final totalDelay =
          List.generate(i + 1, (index) => delayMs * pow(acceleration, index))
              .reduce((sum, delay) => sum + delay);

      Future.delayed(Duration(milliseconds: totalDelay.round()), () {
        if (mounted) {
          setState(() {
            animationStates[i] = true;
            currentPairs[i] = targetPairs[i];
          });

          Future.delayed(const Duration(milliseconds: 80), () {
            if (mounted) {
              setState(() {
                animationStates[i] = false;
              });
            }
          });
        }
      });
    }
  }

  int _getChunkSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) return 6;
    if (width < 905) return 8;
    if (width < 1240) return 10;

    return 12;
  }

  List<List<String>> _formatHexKey(BuildContext context) {
    if (currentPairs.isEmpty) return [];

    final chunkSize = _getChunkSize(context);
    final chunks = <List<String>>[];

    for (var i = 0; i < currentPairs.length; i += chunkSize) {
      chunks.add(currentPairs.sublist(
          i,
          i + chunkSize > currentPairs.length
              ? currentPairs.length
              : i + chunkSize));
    }

    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    if (currentPairs.isEmpty) {
      _initializePairs();
    }

    final chunks = _formatHexKey(context);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<AppState>(context).currentTheme;

    final chunkSize = _getChunkSize(context);
    final containerWidth = (45.0 * chunkSize) + adaptivePadding * 2;

    return Container(
      padding: EdgeInsets.all(adaptivePadding),
      constraints: BoxConstraints(maxWidth: containerWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: adaptivePadding),
            child: Text(
              widget.title,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...chunks.asMap().entries.map((chunkEntry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: chunkEntry.value.asMap().entries.map((pairEntry) {
                  final globalIndex =
                      chunkEntry.key * _getChunkSize(context) + pairEntry.key;
                  final isAnimating = globalIndex < animationStates.length
                      ? animationStates[globalIndex]
                      : false;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pairEntry.value,
                      style: TextStyle(
                        color: isAnimating
                            ? theme.secondaryPurple
                            : theme.textPrimary,
                        fontSize: 16,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
