import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:provider/provider.dart';
import 'package:bearby/components/linear_refresh_indicator.dart';
import 'package:bearby/components/transaction_item.dart';
import 'package:bearby/components/hover_icon.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/glass_search_bar.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/history_amount.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/mixins/transaction_parsing.dart';
import 'package:bearby/modals/btc_transaction_details_modal.dart';
import 'package:bearby/modals/evm_transaction_details_modal.dart';
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/models/transactions/history.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

enum SortType { date, status }

enum HistoryFilterType {
  all,
  sent,
  received,
  tokens,
  contract,
  signed,
  pending,
  failed,
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with StatusBarMixin {
  List<HistoricalTransactionInfo> _history = [];
  bool _isLoading = true;
  bool _sortAscending = false;
  HistoryFilterType _selectedFilter = HistoryFilterType.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialHistory() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.wallet == null || appState.account == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      final history = await getHistory(
        walletIndex: appState.selectedWalletIndex,
      );
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error syncing history: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkPendingTransactions(AppState appState) async {
    try {
      final history = await checkPendingTranasctions(
        walletIndex: appState.selectedWalletIndex,
      );
      if (mounted) {
        setState(() {
          _history = history;
        });
      }
    } catch (e) {
      debugPrint("Error syncing pending transactions: $e");
    }
  }

  Future<void> _clearAllTransactions(AppState appState) async {
    try {
      await clearHistory(
        walletIndex: appState.selectedWalletIndex,
      );
      if (mounted) {
        setState(() {
          _history = [];
        });
      }
    } catch (e) {
      debugPrint("Error clearing transactions: $e");
    }
  }

  bool _matchesSearchAndChain(
    HistoricalTransactionInfo transaction,
    BigInt? currentChainHash,
    String searchText,
  ) {
    if (currentChainHash != null &&
        transaction.metadata.chainHash != currentChainHash) {
      return false;
    }
    if (searchText.isEmpty) return true;
    return [
      transaction.transactionHash,
      transaction.amount,
      transaction.sender,
      transaction.recipient,
      transaction.contractAddress ?? '',
      transaction.title ?? '',
      transaction.error ?? '',
      transaction.tokenInfo?.symbol ?? '',
      transaction.chainType,
    ].any((field) => field.toLowerCase().contains(searchText));
  }

  bool _matchesFilterType(
    HistoricalTransactionInfo tx,
    HistoryFilterType filter,
    String? accountAddr,
  ) {
    switch (filter) {
      case HistoryFilterType.all:
        return true;
      case HistoryFilterType.sent:
        return !tx.isSignedMessage &&
            resolveTxFlow(transaction: tx, accountAddress: accountAddr) ==
                TxFlow.outgoing;
      case HistoryFilterType.received:
        return !tx.isSignedMessage &&
            resolveTxFlow(transaction: tx, accountAddress: accountAddr) ==
                TxFlow.incoming;
      case HistoryFilterType.tokens:
        return !tx.isSignedMessage && tx.tokenInfo != null;
      case HistoryFilterType.contract:
        return !tx.isSignedMessage &&
            ((tx.title != null && tx.title!.isNotEmpty) ||
                (tx.contractAddress != null &&
                    tx.contractAddress!.isNotEmpty) ||
                resolveTxFlow(transaction: tx, accountAddress: accountAddr) ==
                    TxFlow.neutral);
      case HistoryFilterType.signed:
        return tx.isSignedMessage;
      case HistoryFilterType.pending:
        return tx.status == TransactionStatusInfo.pending;
      case HistoryFilterType.failed:
        return tx.status == TransactionStatusInfo.failed;
    }
  }

  List<HistoricalTransactionInfo> _getBaseHistory(AppState appState) {
    final currentChainHash = appState.chain?.chainHash;
    final searchText = _searchController.text.toLowerCase().trim();
    return _history
        .where((tx) => _matchesSearchAndChain(tx, currentChainHash, searchText))
        .toList();
  }

  List<HistoricalTransactionInfo> _getSortedAndFilteredHistory(
      AppState appState) {
    final accountAddr = appState.account?.addr;
    final filteredHistory = _getBaseHistory(appState)
        .where((tx) => _matchesFilterType(tx, _selectedFilter, accountAddr))
        .toList();

    filteredHistory.sort((a, b) => _sortAscending
        ? a.timestamp.compareTo(b.timestamp)
        : b.timestamp.compareTo(a.timestamp));
    return filteredHistory;
  }

  String _filterLabel(AppLocalizations l10n, HistoryFilterType filter) {
    final isRu = l10n.localeName.toLowerCase().startsWith('ru');
    switch (filter) {
      case HistoryFilterType.all:
        return isRu ? 'Все' : 'All';
      case HistoryFilterType.sent:
        return l10n.historyItemSent;
      case HistoryFilterType.received:
        return l10n.historyItemReceived;
      case HistoryFilterType.tokens:
        return l10n.chainInfoModalContentTokenTitle;
      case HistoryFilterType.contract:
        return l10n.signMessageModalContentContract;
      case HistoryFilterType.signed:
        return l10n.signMessageModalContentSign;
      case HistoryFilterType.pending:
        return l10n.amountSection_pending;
      case HistoryFilterType.failed:
        return isRu ? 'Ошибка' : 'Failed';
    }
  }

  AppIcon? _filterIcon(HistoryFilterType filter) {
    switch (filter) {
      case HistoryFilterType.all:
        return null;
      case HistoryFilterType.sent:
        return AppIcon.send;
      case HistoryFilterType.received:
        return AppIcon.receive;
      case HistoryFilterType.tokens:
        return null;
      case HistoryFilterType.contract:
        return null;
      case HistoryFilterType.signed:
        return AppIcon.edit;
      case HistoryFilterType.pending:
        return null;
      case HistoryFilterType.failed:
        return AppIcon.warning;
    }
  }

  Color _filterAccentColor(AppTheme theme, HistoryFilterType filter) {
    switch (filter) {
      case HistoryFilterType.all:
      case HistoryFilterType.sent:
        return theme.primaryPurple;
      case HistoryFilterType.received:
        return theme.success;
      case HistoryFilterType.tokens:
        return const Color(0xFF3B82F6);
      case HistoryFilterType.contract:
        return const Color(0xFF00D1B2);
      case HistoryFilterType.signed:
        return const Color(0xFFF59E0B);
      case HistoryFilterType.pending:
        return theme.warning;
      case HistoryFilterType.failed:
        return theme.danger;
    }
  }

  Widget _buildHeader(AppState appState, double adaptivePadding) {
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final baseHistory = _getBaseHistory(appState);
    final accountAddr = appState.account?.addr;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        adaptivePadding,
        14,
        adaptivePadding,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.historyPageTitle,
                style: theme.titleMedium.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.textPrimary.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _sortAscending ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: HoverIcon(
                        icon: AppIcon.arrowDown,
                        size: 20,
                        padding: const EdgeInsets.all(4),
                        onTap: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                        },
                        color: _sortAscending
                            ? theme.primaryPurple
                            : theme.textSecondary.withValues(alpha: 0.75),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: theme.textPrimary.withValues(alpha: 0.08),
                    ),
                    HoverIcon(
                      icon: AppIcon.minus,
                      size: 20,
                      padding: const EdgeInsets.all(4),
                      onTap: () {
                        _clearAllTransactions(appState);
                      },
                      color: theme.danger,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HistoryFilterType.values.map((filter) {
                final count = baseHistory
                    .where((tx) => _matchesFilterType(tx, filter, accountAddr))
                    .length;
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _HistoryFilterChip(
                    label: _filterLabel(l10n, filter),
                    icon: _filterIcon(filter),
                    count: count,
                    isSelected: isSelected,
                    accentColor: _filterAccentColor(theme, filter),
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppState appState, double adaptivePadding) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: appState.currentTheme.primaryPurple,
        ),
      );
    }
    final sortedHistory = _getSortedAndFilteredHistory(appState);
    if (sortedHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.historyPageNoTransactions,
              style: appState.currentTheme.bodyLarge.copyWith(
                color: appState.currentTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(adaptivePadding, 0, adaptivePadding, 16),
      child: Column(
        children: sortedHistory.asMap().entries.map((entry) {
          final transaction = entry.value;
          final isLast = entry.key == sortedHistory.length - 1;
          return HistoryItem(
            key: ValueKey('${entry.key}_${transaction.transactionHash}'),
            transaction: transaction,
            showDivider: !isLast,
            onTap: () {
              if (transaction.isBtcTransaction) {
                showBtcTransactionDetailsModal(
                  context: context,
                  transaction: transaction,
                );
              } else {
                showEvmTransactionDetailsModal(
                  context: context,
                  transaction: transaction,
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    final slivers = [
      if (isIOS)
        CupertinoSliverRefreshControl(
          onRefresh: () => _checkPendingTransactions(appState),
          builder: (
            BuildContext context,
            RefreshIndicatorMode refreshState,
            double pulledExtent,
            double refreshTriggerPullDistance,
            double refreshIndicatorExtent,
          ) {
            return LinearRefreshIndicator(
              pulledExtent: pulledExtent,
              refreshTriggerPullDistance: refreshTriggerPullDistance,
              refreshIndicatorExtent: refreshIndicatorExtent,
            );
          },
        ),
      SliverToBoxAdapter(
        child: Column(
          children: [
            _buildHeader(appState, adaptivePadding),
            _buildContent(appState, adaptivePadding),
          ],
        ),
      ),
    ];

    Widget scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    );

    if (!isIOS) {
      scrollView = RefreshIndicator(
        onRefresh: () => _checkPendingTransactions(appState),
        child: scrollView,
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 960;
    final isDesktop = screenWidth >= 960;
    final isWideLayout = screenWidth >= 600;
    final double maxWidth = isDesktop
        ? 920.0
        : isTablet
            ? 760.0
            : double.infinity;

    return Scaffold(
      backgroundColor: appState.currentTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                Expanded(child: scrollView),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    adaptivePadding,
                    4,
                    adaptivePadding,
                    8,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    heightFactor: 1.0,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWideLayout ? 560 : double.infinity,
                      ),
                      child: GlassSearchBar(
                        controller: _searchController,
                        hint:
                            AppLocalizations.of(context)!.historyPageSearchHint,
                        rightIcon: AppIcon.close,
                        onChanged: (value) {
                          setState(() {});
                        },
                        onRightIconTap: () {
                          _searchController.text = "";
                          setState(() {});
                        },
                        onSubmitted: (value) {},
                      ),
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
}

class _HistoryFilterChip extends StatefulWidget {
  final String label;
  final AppIcon? icon;
  final int count;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _HistoryFilterChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_HistoryFilterChip> createState() => _HistoryFilterChipState();
}

class _HistoryFilterChipState extends State<_HistoryFilterChip>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(
      duration: const Duration(milliseconds: 110),
      scaleEnd: 0.96,
      opacityEnd: 0.9,
    );
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final active = widget.isSelected;
    final accent = widget.accentColor;

    final textColor = active
        ? theme.textPrimary
        : isHovered
            ? theme.textPrimary.withValues(alpha: 0.88)
            : theme.textSecondary.withValues(alpha: 0.82);

    return buildPressable(
      onTap: widget.onTap,
      enableHover: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [
                    Color.lerp(theme.cardBackground, accent, 0.22)!,
                    Color.lerp(theme.cardBackground, accent, 0.10)!,
                  ]
                : [
                    Color.lerp(
                      theme.cardBackground,
                      accent,
                      isHovered ? 0.10 : 0.03,
                    )!,
                    theme.cardBackground,
                  ],
          ),
          border: Border.all(
            color: active
                ? accent.withValues(alpha: 0.65)
                : isHovered
                    ? accent.withValues(alpha: 0.38)
                    : theme.textPrimary.withValues(alpha: 0.08),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              AppIconView(
                icon: widget.icon!,
                size: 13,
                color: active ? accent : textColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: theme.caption.copyWith(
                color: textColor,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (widget.count > 0 || active) ...[
              const SizedBox(width: 6),
              Text(
                '${widget.count}',
                style: theme.overline.copyWith(
                  color: active
                      ? accent
                      : theme.textSecondary.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

