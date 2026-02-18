import 'package:zilpay/components/jazzicon.dart';
import 'package:flutter/material.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class HoverableWalletSection extends StatefulWidget {
  final AppTheme theme;
  final AppState appState;

  const HoverableWalletSection(
      {super.key, required this.theme, required this.appState});

  @override
  State<HoverableWalletSection> createState() => _HoverableWalletSectionState();
}

class _HoverableWalletSectionState extends State<HoverableWalletSection> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final chain = widget.appState.chain!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pushNamed(context, '/wallet'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? widget.theme.primaryPurple
                  : widget.theme.modalBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.theme.modalBorder,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AsyncImage(
                  url: viewChain(network: chain, theme: widget.theme.value),
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorWidget: Jazzicon(
                    seed: widget.appState.wallet!.walletAddress,
                    diameter: 40,
                  ),
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.appState.wallet!.walletName,
                      style: widget.theme.caption.copyWith(
                        color: widget.theme.textSecondary,
                      )),
                  Text(
                    widget.appState.chain?.name ?? "",
                    style: widget.theme.headline2.copyWith(
                      color: widget.theme.textPrimary,
                      fontSize: 21,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
