import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/enable_card.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/components/swipe_button.dart';
import 'package:bearby/l10n/app_localizations.dart';

void showAddChainModal({
  required BuildContext context,
  required String title,
  required String appIcon,
  required NetworkConfigInfo chain,
  required Function(List<String>) onConfirm,
  required VoidCallback onReject,
}) {
  showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (context) => _AddChainModalContent(
      onConfirm: onConfirm,
      title: title,
      appIcon: appIcon,
      chain: chain,
    ),
  ).then((selectedRpcs) {
    if (selectedRpcs == null) {
      onReject();
    }
  });
}

class _AddChainModalContent extends StatefulWidget {
  final String title;
  final String appIcon;
  final NetworkConfigInfo chain;
  final Function(List<String>) onConfirm;

  const _AddChainModalContent({
    required this.title,
    required this.appIcon,
    required this.chain,
    required this.onConfirm,
  });

  @override
  State<_AddChainModalContent> createState() => _AddChainModalContentState();
}

class _AddChainModalContentState extends State<_AddChainModalContent> {
  late List<bool> rpcSelections;

  @override
  void initState() {
    super.initState();
    rpcSelections = List.filled(widget.chain.rpc.length, true);
  }

  String _extractDomain(String url) {
    Uri uri = Uri.parse(url);
    return uri.host.isNotEmpty ? uri.host : url;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.modalBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
            child: Text(
              widget.title,
              style: theme.subtitle1.copyWith(color: theme.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryPurple.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: AsyncImage(
                    url: widget.appIcon,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    loadingWidget: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryPurple,
                      ),
                    ),
                    errorWidget: Icon(
                      Icons.broken_image,
                      color: theme.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SvgPicture.asset(
                  'assets/icons/right_circle_arrow.svg',
                  width: 32,
                  height: 32,
                  colorFilter:
                      ColorFilter.mode(theme.textSecondary, BlendMode.srcIn),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryPurple.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: AsyncImage(
                    url: viewChain(network: widget.chain, theme: theme.value),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    loadingWidget: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryPurple,
                      ),
                    ),
                    errorWidget: SvgPicture.asset(
                      'assets/icons/warning.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        theme.warning,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.chain.name,
            style: theme.bodyText1.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.05),
                border: Border.all(
                  color: theme.textSecondary.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.addChainModalContentDetails,
                    style: theme.bodyText1.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    l10n.addChainModalContentNetworkName,
                    widget.chain.name,
                    theme,
                  ),
                  _buildDetailRow(
                    l10n.addChainModalContentCurrencySymbol,
                    widget.chain.shortName,
                    theme,
                  ),
                  _buildDetailRow(
                    l10n.addChainModalContentChainId,
                    widget.chain.chainId.toString(),
                    theme,
                  ),
                  if (widget.chain.explorers.isNotEmpty)
                    _buildDetailRow(
                      l10n.addChainModalContentBlockExplorer,
                      widget.chain.explorers.first.url,
                      theme,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
              itemCount: widget.chain.rpc.length,
              itemBuilder: (context, index) {
                final rpc = widget.chain.rpc[index];
                final domain = _extractDomain(rpc);
                return EnableCard(
                  title: domain,
                  name: rpc,
                  isDefault: false,
                  isEnabled: rpcSelections[index],
                  onToggle: (value) {
                    setState(() {
                      rpcSelections[index] = value;
                    });
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              adaptivePadding,
              12,
              adaptivePadding,
              12 + bottomPadding,
            ),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              border: Border(
                top: BorderSide(color: theme.modalBorder, width: 1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  l10n.addChainModalContentWarning,
                  style: theme.caption.copyWith(color: theme.danger),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SwipeButton(
                  text: l10n.addChainModalContentApprove,
                  onSwipeComplete: () async {
                    final selected = widget.chain.rpc
                        .asMap()
                        .entries
                        .where((entry) => rpcSelections[entry.key])
                        .map((entry) => entry.value)
                        .toList();
                    widget.onConfirm(selected);
                    Navigator.pop(context, selected);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: theme.bodyText2.copyWith(color: theme.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.bodyText2.copyWith(color: theme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
