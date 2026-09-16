import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bearby/router.dart';
import 'package:bearby/src/rust/models/provider.dart';

/// Shared route-args bootstrap for wallet-creation pages.
///
/// `gen_bip39`, `sk_gen` and `restore_bip39` used to carry a verbatim copy
/// of the same `didChangeDependencies` block: read the optional
/// [NetworkConfigInfo] from the GoRouter `extra` arguments and bounce the
/// user to the network-setup page when it is missing. The logic now lives
/// exactly once in [bootstrapChainArg] (DRY).
mixin ChainRouteArgsMixin<T extends StatefulWidget> on State<T> {
  /// Applies the `chain` route argument via [apply] the first time it is
  /// seen; schedules a post-frame redirect to [AppRoutes.netSetup] when the
  /// argument is absent. Returns `true` when the chain was newly applied.
  @protected
  bool bootstrapChainArg(
    NetworkConfigInfo? current,
    void Function(NetworkConfigInfo chain) apply,
  ) {
    final args = GoRouterState.of(context).extra as Map<String, Object?>?;
    final chain = args?['chain'] as NetworkConfigInfo?;

    if (chain == null && current == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement(AppRoutes.netSetup);
      });
      return false;
    }
    if (current == null && chain != null) {
      apply(chain);
      return true;
    }
    return false;
  }
}
