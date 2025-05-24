import 'dart:ui';
import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/state/app_state.dart';

class WalletOption extends StatelessWidget {
  final String title;
  final String address;
  final int walletIndex;
  final bool isSelected;
  final VoidCallback onTap;
  final List<String>? icons;
  final EdgeInsetsGeometry? padding;

  const WalletOption({
    super.key,
    required this.title,
    required this.address,
    required this.isSelected,
    required this.onTap,
    required this.walletIndex,
    this.icons,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Provider.of<AppState>(context).currentTheme;
    final wallet = appState.wallets[walletIndex];
    final chain = appState.getChain(wallet.defaultChainHash);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackground.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryPurple : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: padding!,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AsyncImage(
                      url: viewChain(theme: theme.value, network: chain!),
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorWidget: Blockies(
                        seed: appState.wallet!.walletAddress,
                        color: theme.secondaryPurple,
                        bgColor: theme.primaryPurple,
                        spotColor: theme.background,
                        size: 8,
                      ),
                      loadingWidget: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.bodyText1.copyWith(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address,
                          style: theme.bodyText2.copyWith(
                            color: theme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (icons != null) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: icons!
                          .map((iconPath) => Padding(
                                padding: const EdgeInsets.all(4),
                                child: SvgPicture.asset(
                                  iconPath,
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                      isSelected
                                          ? theme.primaryPurple
                                          : theme.textPrimary,
                                      BlendMode.srcIn),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
