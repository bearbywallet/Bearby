import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/components/transaction_item.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);

      if (appState.wallet == null || appState.account == null) {
        Navigator.of(context).pop();
        return;
      }

      _syncHistory(appState);
    });
  }

  Future<void> _syncHistory(AppState appState) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final history = await getHistory(
        walletIndex: BigInt.from(appState.selectedWallet),
      );

      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("error sync history: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildContent(AppState appState, double adaptivePadding) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
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
                  await _syncHistory(appState);
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
