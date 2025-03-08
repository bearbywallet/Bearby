import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/address_avatar.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/components/enable_card.dart';

void showAppConnectModal({
  required BuildContext context,
  required String title,
  required String uuid,
  required String iconUrl,
  ColorsInfo? colors,
  required Function(List<int>) onConfirm,
  required VoidCallback onReject,
}) {
  showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return _AppConnectModalContent(
        title: title,
        uuid: uuid,
        iconUrl: iconUrl,
        colors: colors,
        onConfirm: onConfirm,
      );
    },
  ).then((result) {
    if (result == null) {
      onReject();
    }
  });
}

class _AppConnectModalContent extends StatefulWidget {
  final String title;
  final String uuid;
  final String iconUrl;
  final ColorsInfo? colors;
  final Function(List<int>) onConfirm;

  const _AppConnectModalContent({
    required this.title,
    required this.uuid,
    required this.iconUrl,
    this.colors,
    required this.onConfirm,
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

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final primaryColor =
        _parseColor(widget.colors?.primary) ?? theme.primaryPurple;
    final secondaryColor =
        _parseColor(widget.colors?.secondary) ?? theme.textSecondary;
    final textColor = _parseColor(widget.colors?.text) ?? theme.buttonText;

    return Container(
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
            margin: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.modalBorder,
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
                    color: primaryColor.withValues(alpha: 0.2), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AsyncImage(
                  url: widget.iconUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: secondaryColor.withValues(alpha: 0.1),
                    child: HoverSvgIcon(
                      assetName: 'assets/icons/warning.svg',
                      width: 64,
                      height: 64,
                      onTap: () {},
                      color: secondaryColor,
                    ),
                  ),
                  loadingWidget: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: primaryColor),
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
                  color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          _buildAccountList(appState, theme),
          Padding(
            padding: EdgeInsets.all(16),
            child: SwipeButton(
              text: 'Swipe to Connect',
              disabled: !_selectedAccounts.values.any((selected) => selected),
              backgroundColor: primaryColor,
              textColor: textColor,
              onSwipeComplete: () async {
                final selectedIndices = _selectedAccounts.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .toList();
                widget.onConfirm(selectedIndices);
                Navigator.pop(context, true);
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildAccountList(AppState appState, AppTheme theme) {
    final secondaryColor =
        _parseColor(widget.colors?.secondary) ?? theme.textSecondary;

    if (appState.wallet == null || appState.wallet!.accounts.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No accounts available',
          style: TextStyle(color: secondaryColor, fontSize: 14),
        ),
      );
    }

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: appState.wallet!.accounts.length,
        itemBuilder: (context, index) {
          final account = appState.wallet!.accounts[index];
          final isSelected = _selectedAccounts[index] ?? false;

          return EnableCard(
            title: account.name,
            name: account.addr,
            iconWidget: AvatarAddress(
              avatarSize: 32.0,
              account: account,
            ),
            isDefault: false,
            isEnabled: isSelected,
            onToggle: (value) {
              setState(() {
                _selectedAccounts[index] = value;
              });
            },
          );
        },
      ),
    );
  }
}
