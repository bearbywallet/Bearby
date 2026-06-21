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

enum _BtcAddressStatus { current, unused, used }

const int _kSegwitAddrTypeByte = 2;
const Duration _kSectionAnimationDuration = Duration(milliseconds: 150);
const int _kMaxUnusedAddresses = 10;

class _BtcAddressRow {
  final String address;
  final _BtcAddressStatus status;
  final int txCount;
  final String path;
  final String amount;
  final String fiat;

  const _BtcAddressRow({
    required this.address,
    required this.status,
    required this.txCount,
    required this.path,
    required this.amount,
    required this.fiat,
  });

  @override
  int get hashCode => Object.hash(address, status, txCount, path, amount, fiat);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BtcAddressRow &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          status == other.status &&
          txCount == other.txCount &&
          path == other.path &&
          amount == other.amount &&
          fiat == other.fiat;

  @override
  String toString() => '_BtcAddressRow(address: $address, status: $status, '
      'txCount: $txCount, path: $path, amount: $amount, fiat: $fiat)';
}

class _BtcAddressSection {
  final int addrTypeByte;
  final List<_BtcAddressRow> rows;
  final _BtcAddressSummary summary;

  const _BtcAddressSection({
    required this.addrTypeByte,
    required this.rows,
    required this.summary,
  });

  @override
  int get hashCode => Object.hash(addrTypeByte, Object.hashAll(rows), summary);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BtcAddressSection &&
          runtimeType == other.runtimeType &&
          addrTypeByte == other.addrTypeByte &&
          listEquals(rows, other.rows) &&
          summary == other.summary;

  @override
  String toString() => '_BtcAddressSection(addrTypeByte: $addrTypeByte, '
      'rows: $rows, summary: $summary)';
}

class _BtcAddressSummary {
  final int current;
  final int unused;
  final int used;

  const _BtcAddressSummary({
    required this.current,
    required this.unused,
    required this.used,
  });

  @override
  int get hashCode => Object.hash(current, unused, used);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BtcAddressSummary &&
          runtimeType == other.runtimeType &&
          current == other.current &&
          unused == other.unused &&
          used == other.used;

  @override
  String toString() =>
      '_BtcAddressSummary(current: $current, unused: $unused, used: $used)';
}

class _BtcAddressModalData {
  final List<_BtcAddressSection> sections;

  const _BtcAddressModalData({required this.sections});

  static const empty = _BtcAddressModalData(sections: <_BtcAddressSection>[]);

  @override
  int get hashCode => Object.hashAll(sections);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BtcAddressModalData &&
          runtimeType == other.runtimeType &&
          listEquals(sections, other.sections);

  @override
  String toString() => '_BtcAddressModalData(sections: $sections)';
}

class _BtcAddressesModalContent extends StatefulWidget {
  const _BtcAddressesModalContent();

  @override
  State<_BtcAddressesModalContent> createState() =>
      _BtcAddressesModalContentState();
}

class _BtcAddressesModalContentState extends State<_BtcAddressesModalContent> {
  final Set<int> _expandedSections = <int>{_kSegwitAddrTypeByte};
  _BtcAddressModalData _data = _BtcAddressModalData.empty;
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
      final data = _buildModalData(
        chains: chains,
        nativeToken: chain.ftokens.firstOrNull,
        appState: appState,
      );
      setState(() {
        _data = data;
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
            color: theme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(theme),
                _buildHeader(theme, l10n),
                if (_isLoading)
                  _buildLoading(theme)
                else if (_data.sections.isEmpty)
                  _buildEmpty(theme, l10n)
                else
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _data.sections.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _buildSection(
                        theme,
                        l10n,
                        _data.sections[index],
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

  Widget _buildHeader(AppTheme theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(
        l10n.btcAddressesModalTitle,
        textAlign: TextAlign.center,
        style: theme.titleMedium.copyWith(
          color: theme.textPrimary,
          fontWeight: FontWeight.w700,
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
    final isExpanded = _expandedSections.contains(section.addrTypeByte);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.modalBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggleSection(section.addrTypeByte),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(
                    _formatLabel(section.addrTypeByte, l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyText2.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSectionStats(theme, l10n, section.summary),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: _kSectionAnimationDuration,
                    curve: Curves.easeOutCubic,
                    child: AppIconView(
                      icon: AppIcon.chevronRight,
                      size: 16,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: _kSectionAnimationDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 1,
                        color: theme.modalBorder,
                      ),
                      ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: section.rows.length,
                        separatorBuilder: (_, __) => Container(
                          height: 1,
                          color: theme.modalBorder,
                        ),
                        itemBuilder: (_, index) => _buildAddressRow(
                          theme,
                          l10n,
                          section.rows[index],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _toggleSection(int addrTypeByte) {
    setState(() {
      if (_expandedSections.contains(addrTypeByte)) {
        _expandedSections.remove(addrTypeByte);
      } else {
        _expandedSections.add(addrTypeByte);
      }
    });
  }

  Widget _buildSectionStats(
    AppTheme theme,
    AppLocalizations l10n,
    _BtcAddressSummary summary,
  ) {
    return Text(
      '${l10n.btcAddressesModalCurrent}: ${summary.current} · '
      '${l10n.btcAddressesModalUnused}: ${summary.unused} · '
      '${l10n.btcAddressesModalUsed}: ${summary.used}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: theme.caption.copyWith(
        color: theme.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusDot(row.status, theme),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${row.path} · ${l10n.btcAddressesModalTxCount(row.txCount)}',
                    style: theme.caption.copyWith(
                      color: theme.textSecondary,
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
                    ),
                  ),
                  if (row.fiat.isNotEmpty)
                    Text(
                      row.fiat,
                      style: theme.caption.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                ],
              ),
            const SizedBox(width: 8),
            AppIconView(
              icon: isCopied ? AppIcon.check : AppIcon.copy,
              size: 18,
              color: theme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(_BtcAddressStatus status, AppTheme theme) {
    final Color color = switch (status) {
      _BtcAddressStatus.current => theme.primaryPurple,
      _BtcAddressStatus.unused => theme.success,
      _BtcAddressStatus.used => theme.textSecondary,
    };

    return Container(
      margin: const EdgeInsets.only(left: 8),
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

_BtcAddressModalData _buildModalData({
  required Map<int, AddressChainInfo> chains,
  required FTokenInfo? nativeToken,
  required AppState appState,
}) {
  const order = <int>[2, 4, 1, 0];
  final sections = <_BtcAddressSection>[];

  for (final byte in order) {
    final chain = chains[byte];
    if (chain == null) continue;

    final currentRows = <_BtcAddressRow>[];
    final unusedRows = <_BtcAddressRow>[];
    final usedRows = <_BtcAddressRow>[];

    _appendBtcRows(
      entries: chain.external_,
      isExternal: true,
      currentRows: currentRows,
      unusedRows: unusedRows,
      usedRows: usedRows,
      nativeToken: nativeToken,
      appState: appState,
    );
    _appendBtcRows(
      entries: chain.internal,
      isExternal: false,
      currentRows: currentRows,
      unusedRows: unusedRows,
      usedRows: usedRows,
      nativeToken: nativeToken,
      appState: appState,
    );

    final rowCount = currentRows.length +
        usedRows.length +
        (unusedRows.length > _kMaxUnusedAddresses
            ? _kMaxUnusedAddresses
            : unusedRows.length);
    if (rowCount == 0) continue;

    final limitedUnused = unusedRows.length > _kMaxUnusedAddresses
        ? unusedRows.sublist(0, _kMaxUnusedAddresses)
        : unusedRows;

    sections.add(
      _BtcAddressSection(
        addrTypeByte: byte,
        rows: List<_BtcAddressRow>.unmodifiable(<_BtcAddressRow>[
          ...currentRows,
          ...limitedUnused,
          ...usedRows,
        ]),
        summary: _BtcAddressSummary(
          current: currentRows.length,
          unused: unusedRows.length,
          used: usedRows.length,
        ),
      ),
    );
  }

  return _BtcAddressModalData(
    sections: List<_BtcAddressSection>.unmodifiable(sections),
  );
}

void _appendBtcRows({
  required List<BtcAddressEntryInfo> entries,
  required bool isExternal,
  required List<_BtcAddressRow> currentRows,
  required List<_BtcAddressRow> unusedRows,
  required List<_BtcAddressRow> usedRows,
  required FTokenInfo? nativeToken,
  required AppState appState,
}) {
  for (final entry in entries) {
    final isUsed = entry.history.isNotEmpty || entry.utxos.isNotEmpty;

    if (isUsed) {
      usedRows.add(
        _rowFromEntry(entry, _BtcAddressStatus.used, nativeToken, appState),
      );
    } else if (isExternal && currentRows.isEmpty) {
      currentRows.add(
        _rowFromEntry(entry, _BtcAddressStatus.current, nativeToken, appState),
      );
    } else {
      unusedRows.add(
        _rowFromEntry(entry, _BtcAddressStatus.unused, nativeToken, appState),
      );
    }
  }
}

_BtcAddressRow _rowFromEntry(
  BtcAddressEntryInfo entry,
  _BtcAddressStatus status,
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
    status: status,
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
