import 'package:flutter_test/flutter_test.dart';
import 'package:bearby/mixins/amount.dart';

void main() {
  group('percentOfBalance', () {
    const balance = 100000000; // 1.0 with 8 decimals

    test('0% clears to zero', () {
      expect(
        percentOfBalance(balance: BigInt.from(balance), percent: 0),
        BigInt.zero,
      );
    });

    test('25% returns a quarter of the balance', () {
      expect(
        percentOfBalance(balance: BigInt.from(balance), percent: 25),
        BigInt.from(25000000),
      );
    });

    test('50% returns half of the balance', () {
      expect(
        percentOfBalance(balance: BigInt.from(balance), percent: 50),
        BigInt.from(50000000),
      );
    });

    test('75% returns three quarters of the balance', () {
      expect(
        percentOfBalance(balance: BigInt.from(balance), percent: 75),
        BigInt.from(75000000),
      );
    });

    test('100% returns the full balance', () {
      expect(
        percentOfBalance(balance: BigInt.from(balance), percent: 100),
        BigInt.from(balance),
      );
    });

    test('uses integer division (truncates remainder)', () {
      expect(
        percentOfBalance(balance: BigInt.from(3), percent: 50),
        BigInt.one,
      );
    });

    test('zero balance always yields zero', () {
      for (final percent in <int>[0, 25, 50, 75, 100]) {
        expect(
          percentOfBalance(balance: BigInt.zero, percent: percent),
          BigInt.zero,
        );
      }
    });
  });
}
