import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/transactions/history.dart';
import 'package:zilpay/state/app_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncHistory();
    });
  }

  Future<void> _syncHistory() async {
    final appState = Provider.of<AppState>(context, listen: false);

    List<HistoricalTransactionInfo> history =
        await getHistory(walletIndex: BigInt.from(appState.selectedWallet));

    for (var transaction in history) {
      print('ID: ${transaction.id}');
      print('Amount: ${transaction.amount}');
      print('Sender: ${transaction.sender}');
      print('Recipient: ${transaction.recipient}');
      print('TEG: ${transaction.teg ?? 'null'}');
      print('Status: ${transaction.status}');
      print('Confirmed: ${transaction.confirmed ?? 'null'}');
      print('Timestamp: ${transaction.timestamp}');
      print('Fee: ${transaction.fee}');
      print('Icon: ${transaction.icon ?? 'null'}');
      print('Title: ${transaction.title ?? 'null'}');
      print('Nonce: ${transaction.nonce}');
      print('Token Info: ${transaction.tokenInfo ?? 'null'}');
      print('\n'); // Print a newline for separation
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Center(child: Text('history Page')),
        ],
      ),
    );
  }
}
