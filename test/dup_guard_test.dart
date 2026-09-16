// Source-level DRY regression guards for refactors without a testable seam.
// Each test pins a "defined exactly once" invariant that a future
// copy/paste would silently break.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('DRY guards: shared widgets & flow helpers', () {
    test('stakeing_card: flow helpers are defined exactly once', () {
      final src = _read('lib/components/stakeing_card.dart');

      for (final helper in [
        'Future<void> _ensureCorrectChain(',
        'void _navigateToHistory(',
        'void _showErrorDialog(',
      ]) {
        expect(
          helper.allMatches(src).length,
          1,
          reason: '$helper was copy-pasted into 3-4 widget classes before; '
              'it must stay defined only inside _StakeFlowHelpers',
        );
      }
      expect(src.contains('mixin _StakeFlowHelpers'), isTrue);
    });

    test('chain route-args bootstrap lives only in the mixin', () {
      final mixinSrc = _read('lib/mixins/chain_route_args.dart');
      expect(mixinSrc.contains("args?['chain'] as NetworkConfigInfo?"),
          isTrue, reason: 'mixin owns the parsing');

      // The verbatim block must not be re-copied into pages.
      // verify_bip39 (extra `bip39` argument) and password_setup (multi-arg:
      // bip39/keys/ignore_checksum) keep custom variants — 0 raw copies here.
      final pages = <String, bool>{
        'lib/pages/gen_bip39.dart': false,
        'lib/pages/restore_bip39.dart': false,
        'lib/pages/sk_gen.dart': false,
        'lib/pages/gen_wallet_options.dart': false,
        'lib/pages/new_wallet_options.dart': false,
        'lib/pages/wallet_restore_options.dart': false,
        'lib/pages/ledger_connect.dart': false,
        'lib/pages/restore_sk.dart': false,
        'lib/pages/verify_bip39.dart': true,
        'lib/pages/password_setup.dart': true,
      };
      var rawCopies = 0;
      for (final entry in pages.entries) {
        final src = _read(entry.key);
        if (src.contains("args?['chain'] as NetworkConfigInfo?")) {
          if (!entry.value) rawCopies += 1;
        } else if (!entry.value) {
          expect(src.contains('bootstrapChainArg('), isTrue,
              reason: '${entry.key} must use the shared mixin');
        }
      }
      expect(rawCopies, 0,
          reason: 'chain-arg parsing must live only in ChainRouteArgsMixin '
              'and the two documented variants');
    });

    test('dead near-copy of the argon settings modal stays deleted', () {
      // lib/modals/argon2.dart (showArgonSettingsModal, 223 lines) had zero
      // callers/imports; it was a stale copy of encryption_settings.dart.
      expect(File('lib/modals/argon2.dart').existsSync(), isFalse,
          reason: 'do not resurrect the dead copy - extend '
              'lib/modals/encryption_settings.dart instead');
    });
  });
}
