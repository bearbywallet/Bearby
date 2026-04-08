import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/button.dart';
import 'package:bearby/components/option_list.dart';
import 'package:bearby/config/derive_path.dart';
import 'package:bearby/state/app_state.dart';

void showDerivePathModal({
  required BuildContext context,
  required DerivePathType currentType,
  required int bipPurpose,
  required int slip44,
  required Function(DerivePathType type) onChanged,
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
        child: _DerivePathModalContent(
          currentType: currentType,
          bipPurpose: bipPurpose,
          slip44: slip44,
          onChanged: onChanged,
        ),
      );
    },
  );
}

class _DerivePathModalContent extends StatefulWidget {
  final DerivePathType currentType;
  final int bipPurpose;
  final int slip44;
  final Function(DerivePathType) onChanged;

  const _DerivePathModalContent({
    required this.currentType,
    required this.bipPurpose,
    required this.slip44,
    required this.onChanged,
  });

  @override
  State<_DerivePathModalContent> createState() =>
      _DerivePathModalContentState();
}

class _DerivePathModalContentState extends State<_DerivePathModalContent> {
  late DerivePathType _type;

  @override
  void initState() {
    super.initState();
    _type = widget.currentType;
  }

  String get _pathPreview => buildDerivePath(
        type: _type,
        bipPurpose: widget.bipPurpose,
        slip44: widget.slip44,
      );

  static const _options = [
    (
      DerivePathType.root,
      'Root',
      "m/{bip}'/{coin}'",
      'Coin-level key, no account derivation',
    ),
    (
      DerivePathType.account,
      'Account',
      "m/{bip}'/{coin}'/{account}'",
      'Single account key',
    ),
    (
      DerivePathType.accountChange,
      'AccountChange',
      "m/{bip}'/{coin}'/{account}'/{change}'",
      'Account + change (Solana default)',
    ),
    (
      DerivePathType.addressIndex,
      'AddressIndex',
      "m/{bip}'/{coin}'/{account}'/{change}/{index}",
      'Full HD path (Ethereum / Bitcoin default)',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
          Text(
            'Derive Path',
            style: theme.titleLarge.copyWith(color: theme.textPrimary),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OptionsList(
                    options: _options.map((entry) {
                      final (type, name, pattern, description) = entry;
                      return OptionItem(
                        isSelected: _type == type,
                        onSelect: () => setState(() => _type = type),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.labelLarge
                                  .copyWith(color: theme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pattern,
                              style: theme.bodyText2.copyWith(
                                color: theme.primaryPurple,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: theme.bodyText2
                                  .copyWith(color: theme.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.primaryPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.primaryPurple.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _pathPreview,
                      style: theme.bodyText2.copyWith(
                        color: theme.primaryPurple,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomPadding),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                textColor: theme.buttonText,
                backgroundColor: theme.primaryPurple,
                text: 'Confirm',
                onPressed: () {
                  widget.onChanged(_type);
                  Navigator.pop(context);
                },
                borderRadius: 30.0,
                height: 50.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
