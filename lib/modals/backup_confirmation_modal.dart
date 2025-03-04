import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

void showBackupConfirmationModal({
  required BuildContext context,
  required Function(bool) onConfirmed,
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
        child: _BackupConfirmationContent(
          onConfirmed: onConfirmed,
        ),
      );
    },
  );
}

class _BackupConfirmationContent extends StatefulWidget {
  final Function(bool) onConfirmed;

  const _BackupConfirmationContent({
    required this.onConfirmed,
  });

  @override
  State<_BackupConfirmationContent> createState() =>
      _BackupConfirmationContentState();
}

class _BackupConfirmationContentState
    extends State<_BackupConfirmationContent> {
  final Map<String, bool> _confirmations = {
    'I have written down all': false,
    'I have safely stored the backup': false,
    'I am sure I won\'t lose the backup': false,
    'I understand not to share these words with anyone': false,
  };

  void _updateConfirmation(String key, bool value) {
    setState(() {
      _confirmations[key] = value;
    });

    if (_confirmations.values.every((confirmed) => confirmed)) {
      widget.onConfirmed(true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
            padding: const EdgeInsets.all(16),
            child: Text(
              'Backup Confirmation',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._confirmations.entries.map((entry) => _ConfirmationItem(
                text: entry.key,
                isConfirmed: entry.value,
                onConfirmed: (value) => _updateConfirmation(entry.key, value),
                theme: theme,
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ConfirmationItem extends StatelessWidget {
  final String text;
  final bool isConfirmed;
  final Function(bool) onConfirmed;
  final AppTheme theme;

  const _ConfirmationItem({
    required this.text,
    required this.isConfirmed,
    required this.onConfirmed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: isConfirmed
              ? theme.background
              : theme.background.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CheckboxListTile(
          title: Text(
            text,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
          value: isConfirmed,
          onChanged: (value) => onConfirmed(value!),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: theme.primaryPurple,
        ),
      ),
    );
  }
}
