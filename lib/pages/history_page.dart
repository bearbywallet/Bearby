import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/components/transaction_item.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/modals/transaction_details_modal.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/transactions/history.dart';
import 'package:zilpay/state/app_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoricalTransactionInfo> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialHistory();
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

  Widget _buildContent(AppState appState, double adaptivePadding) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: appState.currentTheme.primaryPurple,
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No transactions yet',
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
        children: _history.asMap().entries.map((entry) {
          final transaction = entry.value;
          final isLast = entry.key == _history.length - 1;

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

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await _checkPendingTransactions(appState);
                },
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
                    _buildContent(appState, adaptivePadding),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
