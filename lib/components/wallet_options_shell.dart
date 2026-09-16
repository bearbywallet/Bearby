import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';

/// Shared page shell for the wallet create/restore option screens.
/// The Scaffold + transparent app bar + chain-guard + centered list column
/// used to be copy-pasted into gen/new/restore wallet-options pages (DRY).
class WalletOptionsShell extends StatelessWidget {
  final bool loading; // true while the route chain argument is missing
  final List<Widget> options;
  final String title;

  const WalletOptionsShell({
    super.key,
    required this.title,
    this.loading = false,
    this.options = const [],
  });

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: StatusBarUtils.getOverlayStyle(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: title,
                    onBackPressed: () => context.pop(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: options,
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
