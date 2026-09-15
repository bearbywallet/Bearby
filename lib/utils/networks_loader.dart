import 'package:flutter/services.dart' show rootBundle;

import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/src/rust/api/provider.dart' show getNetworks;
import 'package:bearby/src/rust/models/provider.dart' show NetworkConfigInfo;

/// Loads the bundled chain registries and parses them through the Rust
/// bridge. Used to be a copy-pasted 6-line block in five call sites
/// (network.dart, setup_net.dart, eip_1193.dart x2, tron_web3.dart - DRY).
///
/// The ~23KB + ~16KB JSON payloads are parsed on the Rust worker thread,
/// so the UI thread is never blocked (heavy-task rule).
typedef BundledNetworks = (
  List<NetworkConfigInfo> mainnet,
  List<NetworkConfigInfo> testnet
);

Future<BundledNetworks> loadBundledNetworks() async {
  final String mainnetJsonData =
      await rootBundle.loadString(kMainnetChainsPath);
  final String testnetJsonData =
      await rootBundle.loadString(kTestnetChainsPath);
  return getNetworks(
    mainnetJson: mainnetJsonData,
    testnetJson: testnetJsonData,
  );
}
