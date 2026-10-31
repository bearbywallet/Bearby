import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/jazzicon.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/src/rust/models/wallet.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

class Bip39DiscoverySection extends StatelessWidget {
  final List<Bip39DiscoveredAccountInfo> accounts;
  final NetworkConfigInfo? primaryChain;
  final List<NetworkConfigInfo> scanChains;
  final bool isScanning;
  final int scannedCount;
  final int totalTarget;

  const Bip39DiscoverySection({
    super.key,
    required this.accounts,
    required this.primaryChain,
    required this.scanChains,
    required this.isScanning,
    required this.scannedCount,
    required this.totalTarget,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final progress = totalTarget > 0
        ? (scannedCount / totalTarget).clamp(0.0, 1.0)
        : 0.0;

    final Map<BigInt, NetworkConfigInfo> chainByHash = {
      for (final c in scanChains) c.chainHash: c,
      if (primaryChain != null) primaryChain!.chainHash: primaryChain!,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _DiscoveryHeader(
          title: l10n.addressSelectModalContentMyAccounts,
          discoveredCount: accounts.length,
          isScanning: isScanning,
          scannedCount: scannedCount,
          totalTarget: totalTarget,
          progress: progress,
          theme: theme,
        ),
        const SizedBox(height: 10),
        ...accounts.asMap().entries.map((entry) {
          final idx = entry.key;
          final account = entry.value;
          final activeNetworks = <NetworkConfigInfo>[];
          final seenHashes = <BigInt>{};

          for (final cb in account.chainBalances) {
            final net = chainByHash[cb.chainHash];
            if (net != null && seenHashes.add(net.chainHash)) {
              activeNetworks.add(net);
            }
          }
          if (activeNetworks.isEmpty && primaryChain != null) {
            activeNetworks.add(primaryChain!);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DiscoveredAccountCard(
              key: ValueKey('discovered_acc_${account.index}'),
              account: account,
              orderIndex: idx,
              networks: activeNetworks,
              theme: theme,
            ),
          );
        }),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isScanning
              ? _CreativeDiscoverySkeleton(
                  key: const ValueKey('discovery_skeleton_active'),
                  scannedCount: scannedCount,
                  totalTarget: totalTarget,
                  theme: theme,
                )
              : const SizedBox.shrink(
                  key: ValueKey('discovery_skeleton_done'),
                ),
        ),
      ],
    );
  }
}

class _DiscoveryHeader extends StatelessWidget {
  final String title;
  final int discoveredCount;
  final bool isScanning;
  final int scannedCount;
  final int totalTarget;
  final double progress;
  final AppTheme theme;

  const _DiscoveryHeader({
    required this.title,
    required this.discoveredCount,
    required this.isScanning,
    required this.scannedCount,
    required this.totalTarget,
    required this.progress,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isScanning
              ? theme.primaryPurple.withValues(alpha: 0.28)
              : theme.textSecondary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _PulsingStatusDot(
                isScanning: isScanning,
                theme: theme,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyText1.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryPurple.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$discoveredCount',
                        style: theme.caption.copyWith(
                          color: theme.primaryPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.background.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.textSecondary.withValues(alpha: 0.14),
                  ),
                ),
                child: Text(
                  '$scannedCount / $totalTarget',
                  style: theme.caption.copyWith(
                    color: isScanning
                        ? theme.primaryPurple
                        : theme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          if (isScanning) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: theme.textSecondary.withValues(alpha: 0.12),
                    ),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.04, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryPurple.withValues(alpha: 0.55),
                              theme.primaryPurple,
                              theme.secondaryPurple,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingStatusDot extends StatefulWidget {
  final bool isScanning;
  final AppTheme theme;

  const _PulsingStatusDot({
    required this.isScanning,
    required this.theme,
  });

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isScanning
        ? widget.theme.primaryPurple
        : widget.theme.success;

    if (!widget.isScanning) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeColor,
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.45),
              blurRadius: 6,
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 8 + (t * 6),
                height: 8 + (t * 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor.withValues(alpha: (1.0 - t) * 0.38),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiscoveredAccountCard extends StatelessWidget {
  final Bip39DiscoveredAccountInfo account;
  final int orderIndex;
  final List<NetworkConfigInfo> networks;
  final AppTheme theme;

  const _DiscoveredAccountCard({
    super.key,
    required this.account,
    required this.orderIndex,
    required this.networks,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFunded = account.hasActivity || account.chainBalances.isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 240 + (orderIndex.clamp(0, 6) * 35)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 10),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFunded
                ? theme.primaryPurple.withValues(alpha: 0.38)
                : theme.textSecondary.withValues(alpha: 0.14),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ClipOval(
              child: Jazzicon(
                diameter: 34,
                seed: account.addr.isEmpty
                    ? 'account_${account.index}'
                    : account.addr,
                shapeCount: 4,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.addAccountPageDefaultName(account.index),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyText1.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryPurple.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${account.index}',
                      style: theme.caption.copyWith(
                        color: theme.primaryPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _OverlappingChainIcons(
              networks: networks,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlappingChainIcons extends StatelessWidget {
  static const int _maxVisible = 5;
  static const double _iconSize = 28.0;
  static const double _overlapStep = 19.0;

  final List<NetworkConfigInfo> networks;
  final AppTheme theme;

  const _OverlappingChainIcons({
    required this.networks,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (networks.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = networks.take(_maxVisible).toList();
    final extraCount = networks.length - visible.length;
    final totalItems = visible.length + (extraCount > 0 ? 1 : 0);
    final totalWidth = _iconSize + ((totalItems - 1) * _overlapStep);

    return SizedBox(
      width: totalWidth,
      height: _iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * _overlapStep,
              child: Container(
                width: _iconSize,
                height: _iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.background,
                  border: Border.all(
                    color: theme.cardBackground,
                    width: 2.2,
                  ),
                ),
                child: ClipOval(
                  child: AsyncImage(
                    url: viewChain(network: visible[i], theme: theme.value),
                    width: _iconSize - 4,
                    height: _iconSize - 4,
                    fit: BoxFit.cover,
                    errorWidget: Icon(
                      Icons.toll_rounded,
                      size: 15,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: visible.length * _overlapStep,
              child: Container(
                width: _iconSize,
                height: _iconSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryPurple,
                  border: Border.all(
                    color: theme.cardBackground,
                    width: 2.2,
                  ),
                ),
                child: Text(
                  '+$extraCount',
                  style: theme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreativeDiscoverySkeleton extends StatefulWidget {
  final int scannedCount;
  final int totalTarget;
  final AppTheme theme;

  const _CreativeDiscoverySkeleton({
    super.key,
    required this.scannedCount,
    required this.totalTarget,
    required this.theme,
  });

  @override
  State<_CreativeDiscoverySkeleton> createState() =>
      _CreativeDiscoverySkeletonState();
}

class _CreativeDiscoverySkeletonState extends State<_CreativeDiscoverySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = _controller.value;

        return Column(
          children: [
            _buildGhostCard(
              phase: phase,
              scale: 1.0,
              opacity: 1.0,
              theme: theme,
              isPrimary: true,
            ),
            const SizedBox(height: 8),
            _buildGhostCard(
              phase: (phase + 0.35) % 1.0,
              scale: 0.96,
              opacity: 0.52,
              theme: theme,
              isPrimary: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGhostCard({
    required double phase,
    required double scale,
    required double opacity,
    required AppTheme theme,
    required bool isPrimary,
  }) {
    final sweepPos = -1.2 + (phase * 3.4);

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment(sweepPos - 0.8, -0.4),
              end: Alignment(sweepPos + 0.8, 0.4),
              colors: [
                theme.cardBackground.withValues(alpha: 0.65),
                theme.primaryPurple.withValues(alpha: isPrimary ? 0.16 : 0.08),
                theme.cardBackground.withValues(alpha: 0.65),
              ],
            ),
            border: Border.all(
              color: theme.primaryPurple.withValues(
                alpha: isPrimary
                    ? (0.18 + 0.14 * math.sin(phase * math.pi * 2).abs())
                    : 0.10,
              ),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CustomPaint(
                  painter: _OrbitalRadarPainter(
                    progress: phase,
                    primaryColor: theme.primaryPurple,
                    secondaryColor: theme.secondaryPurple,
                  ),
                  child: Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryPurple.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    _shimmerBar(
                      width: isPrimary ? 92 : 76,
                      height: 14,
                      phase: phase,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _shimmerBar(
                      width: 28,
                      height: 14,
                      phase: (phase + 0.15) % 1.0,
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 47,
                height: 28,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: _shimmerCircle(
                        size: 28,
                        phase: (phase + 0.25) % 1.0,
                        theme: theme,
                      ),
                    ),
                    Positioned(
                      left: 19,
                      child: _shimmerCircle(
                        size: 28,
                        phase: (phase + 0.45) % 1.0,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerCircle({
    required double size,
    required double phase,
    required AppTheme theme,
  }) {
    final shift = -1.5 + (phase * 3.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.cardBackground, width: 2.2),
        gradient: LinearGradient(
          begin: Alignment(shift - 0.6, 0),
          end: Alignment(shift + 0.6, 0),
          colors: [
            theme.textSecondary.withValues(alpha: 0.12),
            theme.primaryPurple.withValues(alpha: 0.28),
            theme.textSecondary.withValues(alpha: 0.12),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBar({
    required double width,
    required double height,
    required double phase,
    required AppTheme theme,
    double borderRadius = 6,
  }) {
    final shift = -1.5 + (phase * 3.0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(shift - 0.6, 0),
          end: Alignment(shift + 0.6, 0),
          colors: [
            theme.textSecondary.withValues(alpha: 0.10),
            theme.primaryPurple.withValues(alpha: 0.24),
            theme.textSecondary.withValues(alpha: 0.10),
          ],
        ),
      ),
    );
  }
}

class _OrbitalRadarPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _OrbitalRadarPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;

    final baseRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = primaryColor.withValues(alpha: 0.16);
    canvas.drawCircle(center, radius, baseRingPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = progress * math.pi * 2;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: GradientRotation(startAngle),
        colors: [
          primaryColor.withValues(alpha: 0.0),
          primaryColor,
          secondaryColor,
        ],
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, math.pi * 1.15, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitalRadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor;
  }
}
