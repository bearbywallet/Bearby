import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:provider/provider.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/components/transaction_item.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/modals/transaction_details_modal.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/transactions/history.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

enum SortType { date, status }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoricalTransactionInfo> _history = [];
  bool _isLoading = true;
  SortType _sortType = SortType.date;
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
        walletIndex: BigInt.from(appState.selectedWallet),
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
        walletIndex: BigInt.from(appState.selectedWallet),
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
        walletIndex: BigInt.from(appState.selectedWallet),
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

  List<HistoricalTransactionInfo> _getSortedAndFilteredHistory() {
    List<HistoricalTransactionInfo> filteredHistory =
        _history.where((transaction) {
      final searchText = _searchController.text.toLowerCase();
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
    }).toList();
    if (_sortType == SortType.date) {
      filteredHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      filteredHistory.sort((a, b) => a.status.index.compareTo(b.status.index));
    }
    return filteredHistory;
  }

  Widget _buildHeader(AppState appState, double adaptivePadding) {
    return Padding(
      padding: EdgeInsets.all(adaptivePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.historyPageTitle,
            style: TextStyle(
              color: appState.currentTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              HoverSvgIcon(
                assetName: 'assets/icons/down_arrow.svg',
                width: 24,
                height: 24,
                onTap: () {
                  setState(() {
                    _sortType = _sortType == SortType.date
                        ? SortType.status
                        : SortType.date;
                  });
                },
                color: appState.currentTheme.textPrimary,
              ),
              HoverSvgIcon(
                assetName: 'assets/icons/minus.svg',
                width: 24,
                height: 24,
                onTap: () {
                  _clearAllTransactions(appState);
                },
                color: appState.currentTheme.danger,
              ),
            ],
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
    final sortedHistory = _getSortedAndFilteredHistory();
    if (sortedHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.historyPageNoTransactions,
              style: TextStyle(
                color: appState.currentTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(adaptivePadding),
      child: Column(
        children: sortedHistory.asMap().entries.map((entry) {
          final transaction = entry.value;
          final isLast = entry.key == sortedHistory.length - 1;
          return HistoryItem(
            transaction: transaction,
            showDivider: !isLast,
            onTap: () {
              showTransactionDetailsModal(
                context: context,
                transaction: transaction,
              );
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

    return Scaffold(
      backgroundColor: appState.currentTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(child: scrollView),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: SmartInput(
                    controller: _searchController,
                    hint: AppLocalizations.of(context)!.historyPageSearchHint,
                    leftIconPath: 'assets/icons/search.svg',
                    rightIconPath: "assets/icons/close.svg",
                    onChanged: (value) {
                      setState(() {});
                    },
                    onRightIconTap: () {
                      _searchController.text = "";
                    },
                    onSubmitted: (value) {},
                    borderColor: appState.currentTheme.textPrimary,
                    focusedBorderColor: appState.currentTheme.primaryPurple,
                    height: 48,
                    fontSize: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    autofocus: false,
                    keyboardType: TextInputType.text,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
