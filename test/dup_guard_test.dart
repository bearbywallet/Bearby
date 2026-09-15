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
      // verify_bip39 keeps a custom variant (extra `bip39` argument) — 1 hit.
      final pages = <String>[
        'lib/pages/gen_bip39.dart',
        'lib/pages/restore_bip39.dart',
        'lib/pages/sk_gen.dart',
        'lib/pages/verify_bip39.dart',
      ];
      var rawCopies = 0;
      for (final p in pages) {
        final src = _read(p);
        if (src.contains("args?['chain'] as NetworkConfigInfo?")) {
          rawCopies += 1;
        }
        if (p != 'lib/pages/verify_bip39.dart') {
          expect(src.contains('bootstrapChainArg('), isTrue,
              reason: '$p must use the shared mixin');
        }
      }
      expect(rawCopies, 1,
          reason: 'only verify_bip39 (variant with bip39 arg) may parse '
              'chain args inline');
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
