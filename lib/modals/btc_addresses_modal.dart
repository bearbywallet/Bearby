import 'dart:ui';

import 'package:bearby/components/app_icon.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/addr.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/src/rust/models/btc_chain.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void showBtcAddressesModal({required BuildContext context}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (context) => const _BtcAddressesModalContent(),
  );
}

class _BtcAddressRow {
  final String address;
  final bool isUsed;
  final int txCount;
  final String path;
  final String amount;
  final String fiat;

  const _BtcAddressRow({
    required this.address,
    required this.isUsed,
    required this.txCount,
    required this.path,
    required this.amount,
    required this.fiat,
  });

  @override
  int get hashCode => Object.hash(address, isUsed, txCount, path, amount, fiat);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BtcAddressRow &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          isUsed == other.isUsed &&
          txCount == other.txCount &&
          path == other.path &&
          amount == other.amount &&
          fiat == other.fiat;

  @override
  String toString() => '_BtcAddressRow(address: $address, isUsed: $isUsed, '
      'txCount: $txCount, path: $path, amount: $amount, fiat: $fiat)';
}

class _BtcAddressSection {
  final int addrTypeByte;
  final List<_BtcAddressRow> rows;

  const _BtcAddressSection({
    required this.addrTypeByte,
    required this.rows,
  });

  @override
  int get hashCode => Object.hash(addrTypeByte, Object.hashAll(rows));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BtcAddressSection &&
          runtimeType == other.runtimeType &&
          addrTypeByte == other.addrTypeByte &&
          listEquals(rows, other.rows);

  @override
  String toString() =>
      '_BtcAddressSection(addrTypeByte: $addrTypeByte, rows: $rows)';
}

class _BtcAddressesModalContent extends StatefulWidget {
  const _BtcAddressesModalContent();

  @override
  State<_BtcAddressesModalContent> createState() =>
      _BtcAddressesModalContentState();
}

class _BtcAddressesModalContentState extends State<_BtcAddressesModalContent> {
  List<_BtcAddressSection> _sections = const [];
  bool _isLoading = true;
  String? _copiedAddress;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final appState = context.read<AppState>();
    final wallet = appState.wallet;
    final chain = appState.chain;
    final walletIndex = appState.selectedWalletIndexOrNull;

    if (wallet == null || chain == null || walletIndex == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final chains = await getBtcAddresses(
        walletIndex: walletIndex,
        accountIndex: wallet.selectedAccount,
        chainHash: chain.chainHash,
      );
      if (!mounted) return;
      setState(() {
        _sections = _buildSections(
          chains: chains,
          nativeToken: chain.ftokens.firstOrNull,
          appState: appState,
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('error loading btc addresses: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyAddress(String address) async {
    try {
      await Clipboard.setData(ClipboardData(text: address));
      if (!mounted) return;
      setState(() => _copiedAddress = address);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted || _copiedAddress != address) return;
      setState(() => _copiedAddress = null);
    } catch (e) {
      debugPrint('error copying btc address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().currentTheme;
    final l10n = AppLocalizations.of(context);

    if (l10n == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.cardBackground.withValues(alpha: 0.85),
                theme.cardBackground.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: theme.textSecondary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryPurple.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(theme),
                _buildTitle(theme, l10n),
                if (_isLoading)
                  _buildLoading(theme)
                else if (_sections.isEmpty)
                  _buildEmpty(theme, l10n)
                else
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _sections.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _buildSection(
                        theme,
                        l10n,
                        _sections[index],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(AppTheme theme) {
    return Container(
      width: 48,
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildTitle(AppTheme theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        l10n.btcAddressesModalTitle,
        style: theme.titleMedium.copyWith(
          color: theme.textPrimary,
          shadows: [
            Shadow(
              color: theme.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CircularProgressIndicator(color: theme.primaryPurple),
    );
  }

  Widget _buildEmpty(AppTheme theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Text(
        l10n.btcAddressesModalEmpty,
        style: theme.bodyText1.copyWith(color: theme.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSection(
    AppTheme theme,
    AppLocalizations l10n,
    _BtcAddressSection section,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, _formatLabel(section.addrTypeByte, l10n)),
        const SizedBox(height: 8),
        ...List<Widget>.generate(section.rows.length, (index) {
          final row = section.rows[index];
          return Column(
            children: [
              _buildAddressRow(theme, l10n, row),
              if (index < section.rows.length - 1) _buildDivider(theme),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSectionHeader(AppTheme theme, String label) {
    return Text(
      label,
      style: theme.bodyText2.copyWith(
        color: theme.textPrimary,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: theme.primaryPurple.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppTheme theme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.primaryPurple.withValues(alpha: 0.15),
      endIndent: 16,
    );
  }

  Widget _buildAddressRow(
    AppTheme theme,
    AppLocalizations l10n,
    _BtcAddressRow row,
  ) {
    final isCopied = _copiedAddress == row.address;

    return InkWell(
      onTap: () => _copyAddress(row.address),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.primaryPurple.withValues(alpha: 0.03),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          shortenAddress(row.address,
                              leftSize: 8, rightSize: 8),
                          style: theme.bodyText2.copyWith(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildTag(
                        row.isUsed
                            ? l10n.btcAddressesModalUsed
                            : l10n.btcAddressesModalCurrent,
                        row.isUsed
                            ? theme.textSecondary
                            : theme.primaryPurple,
                        theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${row.path} · ${l10n.btcAddressesModalTxCount(row.txCount)}',
                    style: theme.caption.copyWith(
                      color: theme.textSecondary.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (row.amount.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.amount,
                    style: theme.bodyText2.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (row.fiat.isNotEmpty)
                    Text(
                      row.fiat,
                      style: theme.caption.copyWith(
                        color: theme.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            const SizedBox(width: 8),
            AppIconView(
              icon: isCopied ? AppIcon.check : AppIcon.copy,
              size: 18,
              color: isCopied ? theme.success : theme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color, AppTheme theme) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: theme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

List<_BtcAddressSection> _buildSections({
  required Map<int, AddressChainInfo> chains,
  required FTokenInfo? nativeToken,
  required AppState appState,
}) {
  const order = <int>[2, 4, 1, 0];
  final sections = <_BtcAddressSection>[];

  for (final byte in order) {
    final chain = chains[byte];
    if (chain == null) continue;

    final rows = <_BtcAddressRow>[];
    BtcAddressEntryInfo? current;

    for (final entry in chain.external_) {
      if (entry.history.isNotEmpty) {
        rows.add(_rowFromEntry(entry, true, nativeToken, appState));
      } else {
        current ??= entry;
      }
    }

    for (final entry in chain.internal) {
      if (entry.history.isNotEmpty) {
        rows.add(_rowFromEntry(entry, true, nativeToken, appState));
      }
    }

    final currentEntry = current;
    if (currentEntry != null) {
      rows.insert(0, _rowFromEntry(currentEntry, false, nativeToken, appState));
    }

    if (rows.isNotEmpty) {
      sections.add(_BtcAddressSection(addrTypeByte: byte, rows: rows));
    }
  }

  return List<_BtcAddressSection>.unmodifiable(sections);
}

_BtcAddressRow _rowFromEntry(
  BtcAddressEntryInfo entry,
  bool isUsed,
  FTokenInfo? nativeToken,
  AppState appState,
) {
  var totalSats = BigInt.zero;
  for (final utxo in entry.utxos) {
    totalSats += utxo.value;
  }

  var amount = '';
  var fiat = '';
  if (nativeToken != null) {
    final (formattedAmount, formattedFiat) = formatingAmount(
      amount: totalSats,
      symbol: nativeToken.symbol,
      decimals: nativeToken.decimals,
      rate: nativeToken.rate,
      appState: appState,
    );
    amount = formattedAmount;
    fiat = (formattedFiat.isEmpty || formattedFiat.contains('-'))
        ? ''
        : formattedFiat;
  }

  return _BtcAddressRow(
    address: entry.address,
    isUsed: isUsed,
    txCount: entry.history.length,
    path: entry.path,
    amount: amount,
    fiat: fiat,
  );
}

String _formatLabel(int byte, AppLocalizations l10n) => switch (byte) {
      0 => l10n.btcAddressFormatLegacy,
      1 => l10n.btcAddressFormatNestedSegwit,
      2 => l10n.btcAddressFormatSegwit,
      4 => l10n.btcAddressFormatTaproot,
      _ => l10n.btcAddressFormatUnknown(byte),
    };
