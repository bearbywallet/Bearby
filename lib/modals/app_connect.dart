import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

void showAppConnectModal({
  required BuildContext context,
  required String title,
  required String uuid,
  required String iconUrl,
  required Function(bool, List<int>) onDecision,
  VoidCallback? onDismiss,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AppConnectModalContent(
          title: title,
          uuid: uuid,
          iconUrl: iconUrl,
          onDecision: onDecision,
        ),
      );
    },
  ).then((_) => onDismiss?.call());
}

class _AppConnectModalContent extends StatefulWidget {
  final String title;
  final String uuid;
  final String iconUrl;
  final Function(bool, List<int>) onDecision;

  const _AppConnectModalContent({
    required this.title,
    required this.uuid,
    required this.iconUrl,
    required this.onDecision,
  });

  @override
  State<_AppConnectModalContent> createState() =>
      _AppConnectModalContentState();
}

class _AppConnectModalContentState extends State<_AppConnectModalContent> {
  Map<int, bool> _selectedAccounts = {};

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.wallet != null) {
      _selectedAccounts = Map.fromEntries(appState.wallet!.accounts
          .asMap()
          .entries
          .map((entry) => MapEntry(entry.key, true)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.textSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primaryPurple.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AsyncImage(
                  url: widget.iconUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: theme.textSecondary.withValues(alpha: 0.1),
                    child: HoverSvgIcon(
                      assetName: 'assets/icons/warning.svg',
                      width: 64,
                      height: 64,
                      onTap: () {},
                      color: theme.textSecondary,
                    ),
                  ),
                  loadingWidget: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryPurple,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              widget.title,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildAccountList(appState, theme),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    onPressed: () {
                      widget.onDecision(false, []);
                      Navigator.pop(context);
                    },
                    backgroundColor: theme.danger.withValues(alpha: 0.1),
                    textColor: theme.danger,
                    height: 48,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Connect',
                    onPressed: _selectedAccounts.values
                            .any((selected) => selected)
                        ? () {
                            final selectedIndices = _selectedAccounts.entries
                                .where((entry) => entry.value)
                                .map((entry) => entry.key)
                                .toList();
                            widget.onDecision(true, selectedIndices);
                            Navigator.pop(context);
                          }
                        : null,
                    backgroundColor: theme.primaryPurple,
                    textColor: theme.textPrimary,
                    height: 48,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: bottomPadding + 16),
        ],
      ),
    );
  }

  Widget _buildAccountList(AppState appState, AppTheme theme) {
    if (appState.wallet == null || appState.wallet!.accounts.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No accounts available',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: appState.wallet!.accounts.length,
        itemBuilder: (context, index) {
          final account = appState.wallet!.accounts[index];
          final isSelected = _selectedAccounts[index] ?? false;

          return CheckboxListTile(
            title: Text(
              account.name,
              style: TextStyle(color: theme.textPrimary),
            ),
            subtitle: Text(
              account.addr,
              style: TextStyle(color: theme.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                _selectedAccounts[index] = value ?? false;
              });
            },
            activeColor: theme.primaryPurple,
            checkColor: theme.textPrimary,
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      ),
    );
  }
}
