import 'package:flutter_test/flutter_test.dart';
import 'package:bearby/utils/utils.dart';

void main() {
  group('SecureListExtension.zeroize', () {
    test('zeros all values on a growable list', () {
      final list = ['word1', 'word2', 'word3'];
      list.zeroize();
      expect(list, everyElement(isEmpty));
    });

    test('does not throw on a fixed-length list', () {
      final list = List<String>.filled(3, 'secret', growable: false);
      expect(() => list.zeroize(), returnsNormally);
    });

    test('zeros all values on a fixed-length list', () {
      final list = List<String>.filled(3, 'abandon', growable: false);
      list.zeroize();
      expect(list, everyElement(isEmpty));
    });

    test('handles an empty list without throwing', () {
      final growable = <String>[];
      expect(() => growable.zeroize(), returnsNormally);

      final fixed = List<String>.filled(0, '', growable: false);
      expect(() => fixed.zeroize(), returnsNormally);
    });

    test('zeros a 12-word mnemonic fixed-length list matching restore_bip39 pattern', () {
      // Matches the List.filled(12, '') pattern from restore_bip39.dart (now growable:true,
      // but this test ensures the old pattern is also safe via the zeroize guard).
      final mnemonic = List<String>.filled(12, '', growable: false);
      for (var i = 0; i < 12; i++) {
        mnemonic[i] = 'abandon';
      }
      expect(() => mnemonic.zeroize(), returnsNormally);
      expect(mnemonic, everyElement(isEmpty));
    });
  });
}
