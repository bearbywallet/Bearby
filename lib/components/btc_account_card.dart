import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/src/rust/models/btc_chain.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';

class BtcAccountCard extends StatelessWidget {
  final NetworkConfigInfo network;
  final Map<int, AddressChainInfo> chains;

  const BtcAccountCard({
    super.key,
    required this.network,
    required this.chains,
  });

  @override
  Widget build(BuildContext context) {
    final nativeToken = network.ftokens.first;

    final rows = <BtcAddressEntryInfo>[];
    BtcAddressEntryInfo? firstUnusedTaproot;

    for (final chain in chains.values) {
      for (final e in chain.external_) {
        if (firstUnusedTaproot == null &&
            e.history.isEmpty &&
            e.path.startsWith("m/86'/")) {
          firstUnusedTaproot = e;
        }
        if (e.history.isNotEmpty) rows.add(e);
      }
      for (final e in chain.internal) {
        if (e.history.isNotEmpty) rows.add(e);
      }
    }

    if (firstUnusedTaproot != null) rows.add(firstUnusedTaproot);

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows
            .map((e) => _AddressRow(
                  entry: e,
                  symbol: nativeToken.symbol,
                  decimals: nativeToken.decimals,
                  rate: nativeToken.rate,
                ))
            .toList(),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final BtcAddressEntryInfo entry;
  final String symbol;
  final int decimals;
  final double rate;

  const _AddressRow({
    required this.entry,
    required this.symbol,
    required this.decimals,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

    var totalSats = BigInt.zero;
    for (final u in entry.utxos) {
      totalSats += u.value;
    }

    final (formattedAmount, fiat) = formatingAmount(
      amount: totalSats,
      symbol: symbol,
      decimals: decimals,
      rate: rate,
      appState: appState,
    );

    final addr = entry.address;
    final shortAddress = addr.length > 14
        ? "${addr.substring(0, 8)}…${addr.substring(addr.length - 6)}"
        : addr;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              shortAddress,
              style: theme.bodyLarge.copyWith(
                color: theme.textPrimary,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedAmount,
                style: theme.bodyLarge.copyWith(
                  color: theme.textPrimary,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (fiat.isNotEmpty && !fiat.contains('-'))
                Text(
                  fiat,
                  style: theme.caption.copyWith(
                    color: theme.textSecondary.withValues(alpha: 0.7),
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
