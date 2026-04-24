import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bearby/main.dart' as app;
import 'package:bearby/components/button.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/glass_message.dart';
import 'package:bearby/components/mnemonic_word_input.dart';
import 'package:bearby/components/option_list.dart';
import 'package:bearby/components/view_item.dart';
import 'package:bearby/pages/restore_bip39.dart';

const _kMnemonic12 =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const _kMnemonic15 =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
const _kMnemonic18 =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
const _kMnemonic21 =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
const _kMnemonic24 =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
const _kMnemonicBadChecksum =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon';
const _kMnemonicInvalid =
    'zzzzz abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const _kMnemonic5Words = 'abandon abandon abandon abandon abandon';
const _kMnemonic11Words =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon';

final _rng = Random();
const _kMaxVisibleIndex = 5;

Future<void> _clearStorage() async {
  final dir = await getApplicationSupportDirectory();
  for (final name in ['storage', 'local_storage']) {
    final d = Directory('${dir.path}/$name');
    if (await d.exists()) await d.delete(recursive: true);
  }
}

Future<void> _goBackToRestoreOptions(WidgetTester tester) async {
  final back = find.descendant(
    of: find.byType(CustomAppBar),
    matching: find.byType(IconButton),
  );
  expect(back, findsOneWidget);
  await tester.tap(back.first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Future<void> _enterRestoreBip39(WidgetTester tester) async {
  await tester.tap(find.byType(WalletListItem).first);
  await tester.pumpAndSettle(const Duration(seconds: 2));
  expect(find.byType(RestoreSecretPhrasePage), findsOneWidget);
}

Future<void> _pasteIntoRandomInput(WidgetTester tester, String phrase) async {
  final targetIndex = _rng.nextInt(_kMaxVisibleIndex + 1);
  final targetInput = find.byKey(ValueKey('word_$targetIndex'));

  await tester.ensureVisible(targetInput);
  await tester.pumpAndSettle();

  final textField = find.descendant(
    of: targetInput,
    matching: find.byType(TextField),
  );
  await tester.tap(textField, warnIfMissed: false);
  await tester.pump();
  await tester.enterText(textField, phrase);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  debugPrint('    pasted into word_$targetIndex');
}

bool _isRestoreEnabled(WidgetTester tester) {
  final b = find.byType(CustomButton);
  if (b.evaluate().isEmpty) return false;
  return !tester.widget<CustomButton>(b.last).disabled;
}

Future<void> _bypassChecksumIfNeeded(WidgetTester tester) async {
  if (find.byType(GlassMessage).evaluate().isNotEmpty) {
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
  }
}

void _verifyVisibleWords(WidgetTester tester, List<String> expected) {
  for (int i = 0; i < expected.length; i++) {
    final f = find.byKey(ValueKey('word_$i'));
    if (f.evaluate().isEmpty) continue;
    final w = tester.widget<MnemonicWordInput>(f);
    expect(w.word, equals(expected[i]),
        reason: 'word_$i: expected "${expected[i]}" got "${w.word}"');
  }
}

Future<void> _scrollToLastWord(WidgetTester tester, int lastIndex) async {
  final scrollable = find.descendant(
    of: find.byType(RestoreSecretPhrasePage),
    matching: find.byType(Scrollable),
  );
  for (int attempt = 0; attempt < 30; attempt++) {
    if (find.byKey(ValueKey('word_$lastIndex')).evaluate().isNotEmpty) return;
    await tester.drag(scrollable.first, const Offset(0, -300));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }
  expect(find.byKey(ValueKey('word_$lastIndex')), findsOneWidget,
      reason: 'word_$lastIndex should appear after scrolling');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bitcoin BIP39 restore page', (tester) async {
    await _clearStorage();
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Navigate to RestoreSecretPhrasePage
    await tester.tap(find.byType(CustomButton));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final net = find.descendant(
      of: find.byType(OptionsList),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(net.first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CustomButton));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byType(WalletListItem).at(1));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await _enterRestoreBip39(tester);
    debugPrint('✓ Navigation OK');

    // Test 1: Invalid word error
    await _pasteIntoRandomInput(tester, _kMnemonicInvalid);
    {
      final scrollable = find.descendant(
        of: find.byType(RestoreSecretPhrasePage),
        matching: find.byType(Scrollable),
      );
      for (int a = 0; a < 10; a++) {
        if (find.byKey(const ValueKey('word_0')).evaluate().isNotEmpty) break;
        await tester.drag(scrollable.first, const Offset(0, 300));
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
      }
      final w = tester
          .widget<MnemonicWordInput>(find.byKey(const ValueKey('word_0')));
      expect(w.hasError, isTrue);
      expect(_isRestoreEnabled(tester), isFalse);
      debugPrint('✓ Test 1: Invalid word error');
    }

    // Test 2: 5-word incomplete
    await _goBackToRestoreOptions(tester);
    await _enterRestoreBip39(tester);
    await _pasteIntoRandomInput(tester, _kMnemonic5Words);
    expect(_isRestoreEnabled(tester), isFalse);
    debugPrint('✓ Test 2: 5-word incomplete');

    // Test 3: 11-word incomplete
    await _goBackToRestoreOptions(tester);
    await _enterRestoreBip39(tester);
    await _pasteIntoRandomInput(tester, _kMnemonic11Words);
    expect(_isRestoreEnabled(tester), isFalse);
    debugPrint('✓ Test 3: 11-word incomplete');

    // Test 4: Checksum bypass
    await _goBackToRestoreOptions(tester);
    await _enterRestoreBip39(tester);
    await _pasteIntoRandomInput(tester, _kMnemonicBadChecksum);
    expect(find.byType(GlassMessage), findsWidgets);
    expect(_isRestoreEnabled(tester), isFalse);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_isRestoreEnabled(tester), isTrue);
    debugPrint('✓ Test 4: Checksum bypass');

    // Test 5: 12-word
    await _goBackToRestoreOptions(tester);
    await _enterRestoreBip39(tester);
    await _pasteIntoRandomInput(tester, _kMnemonic12);
    await _bypassChecksumIfNeeded(tester);
    expect(_isRestoreEnabled(tester), isTrue);
    _verifyVisibleWords(tester, _kMnemonic12.split(' '));
    debugPrint('✓ Test 5: 12-word');

    // Test 6: 15-word
    await _goBackToRestoreOptions(tester);
    await _enterRestoreBip39(tester);
    await _pasteIntoRandomInput(tester, _kMnemonic15);
    await _bypassChecksumIfNeeded(tester);
    expect(_isRestoreEnabled(tester), isTrue);
    await _scrollToLastWord(tester, 14);
    _verifyVisibleWords(tester, _kMnemonic15.split(' '));
    debugPrint('✓ Test 6: 15-word');

    // Test 7: 18-word
    await _goBackToRestoreOptions(tester);
    await _enterRestoreBip39(tester);
    await _pasteIntoRandomInput(tester, _kMnemonic18);
    await _bypassChecksumIfNeeded(tester);
    expect(_isRestoreEnabled(tester), isTrue);
    await _scrollToLastWord(tester, 17);
    _verifyVisibleWords(tester, _kMnemonic18.split(' '));
    debugPrint('✓ Test 7: 18-word');

    // Test 8: 21-word
    await _goBackToRestoreOptions(tester);
    await _enterRestoreBip39(tester);
    await _pasteIntoRandomInput(tester, _kMnemonic21);
    await _bypassChecksumIfNeeded(tester);
    expect(_isRestoreEnabled(tester), isTrue);
    await _scrollToLastWord(tester, 20);
    _verifyVisibleWords(tester, _kMnemonic21.split(' '));
    debugPrint('✓ Test 8: 21-word');

    // Test 9: 24-word
    await _goBackToRestoreOptions(tester);
    await _enterRestoreBip39(tester);
    await _pasteIntoRandomInput(tester, _kMnemonic24);
    await _bypassChecksumIfNeeded(tester);
    expect(_isRestoreEnabled(tester), isTrue);
    await _scrollToLastWord(tester, 23);
    _verifyVisibleWords(tester, _kMnemonic24.split(' '));
    debugPrint('✓ Test 9: 24-word');
  });
}
