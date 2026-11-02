import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/modal_drag_handle.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

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
    'writtenDown': false,
    'safelyStored': false,
    'wontLose': false,
    'notShare': false,
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
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: theme.modalBorder.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: ModalDragHandle(theme: theme)),
              const SizedBox(height: 14),
              Text(
                l10n.backupConfirmationContentTitle,
                textAlign: TextAlign.center,
                style: theme.subtitle1.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.backupConfirmationWarning,
                textAlign: TextAlign.center,
                style: theme.bodyText2.copyWith(
                  color: theme.danger,
                ),
              ),
              const SizedBox(height: 14),
              _ConfirmationItem(
                text: l10n.backupConfirmationContentWrittenDown,
                isConfirmed: _confirmations['writtenDown']!,
                onConfirmed: (value) =>
                    _updateConfirmation('writtenDown', value),
                theme: theme,
              ),
              _ConfirmationItem(
                text: l10n.backupConfirmationContentSafelyStored,
                isConfirmed: _confirmations['safelyStored']!,
                onConfirmed: (value) =>
                    _updateConfirmation('safelyStored', value),
                theme: theme,
              ),
              _ConfirmationItem(
                text: l10n.backupConfirmationContentWontLose,
                isConfirmed: _confirmations['wontLose']!,
                onConfirmed: (value) => _updateConfirmation('wontLose', value),
                theme: theme,
              ),
              _ConfirmationItem(
                text: l10n.backupConfirmationContentNotShare,
                isConfirmed: _confirmations['notShare']!,
                onConfirmed: (value) => _updateConfirmation('notShare', value),
                theme: theme,
              ),
            ],
          ),
        ),
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
    return Material(
      color: Colors.transparent,
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            text,
            style: theme.bodyText2.copyWith(
              color: isConfirmed ? theme.textPrimary : theme.textSecondary,
            ),
          ),
          value: isConfirmed,
          onChanged: (value) => onConfirmed(value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: theme.primaryPurple,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
