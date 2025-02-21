import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

void showAppConnectModal({
  required BuildContext context,
  required String title,
  required String uuid,
  required String iconUrl,
  required Function(bool) onDecision,
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
  );
}

class _AppConnectModalContent extends StatelessWidget {
  final String title;
  final String uuid;
  final String iconUrl;
  final Function(bool) onDecision;

  const _AppConnectModalContent({
    required this.title,
    required this.uuid,
    required this.iconUrl,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(theme),
          _buildIcon(theme),
          _buildTitle(theme),
          _buildDescription(theme),
          _buildButtons(theme, context),
          SizedBox(height: bottomPadding + 16),
        ],
      ),
    );
  }

  Widget _buildDragHandle(AppTheme theme) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildIcon(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
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
            url: iconUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: theme.textSecondary.withValues(alpha: 0.1),
              child: Icon(
                Icons.apps,
                color: theme.textSecondary,
                size: 32,
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
    );
  }

  Widget _buildTitle(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDescription(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'This app wants to connect to your wallet to view your address and request transactions.',
        style: TextStyle(
          color: theme.textSecondary,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildButtons(AppTheme theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Connect',
              onPressed: () {
                onDecision(true);
                Navigator.pop(context);
              },
              backgroundColor: theme.primaryPurple,
              textColor: theme.textPrimary,
              height: 48,
            ),
          ),
        ],
      ),
    );
  }
}
