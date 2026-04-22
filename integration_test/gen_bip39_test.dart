import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bearby/main.dart' as app;
import 'package:bearby/components/button.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/mnemonic_word_input.dart';
import 'package:bearby/components/option_list.dart';
import 'package:bearby/components/view_item.dart';
import 'package:bearby/components/wor_count_selector.dart';
import 'package:bearby/pages/gen_bip39.dart';
import 'package:bearby/pages/password_setup.dart';
import 'package:bearby/pages/verify_bip39.dart';

Future<void> _clearStorage() async {
  final dir = await getApplicationSupportDirectory();
  for (final name in ['storage', 'local_storage']) {
    final d = Directory('${dir.path}/$name');
    if (await d.exists()) await d.delete(recursive: true);
  }
}

Future<void> _navigateToGenWalletOptions(WidgetTester tester) async {
  await tester.tap(find.byType(CustomButton));
  await tester.pumpAndSettle(const Duration(seconds: 3));

  final networkOption = find.descendant(
    of: find.byType(OptionsList),
    matching: find.byType(GestureDetector),
  );
  await tester.tap(networkOption.first);
  await tester.pumpAndSettle();

  await tester.tap(find.byType(CustomButton));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  await tester.tap(find.byType(WalletListItem).first);
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _enterGenBip39(WidgetTester tester) async {
  await tester.tap(find.byType(WalletListItem).first);
  await tester.pumpAndSettle(const Duration(seconds: 2));
  expect(find.byType(SecretPhraseGeneratorPage), findsOneWidget);
}

Future<void> _selectWordCount(WidgetTester tester, int count) async {
  if (count == 12) return;

  final countText = find.descendant(
    of: find.byType(WordCountSelector),
    matching: find.text(count.toString()),
  );
  expect(countText, findsOneWidget);
  await tester.tap(countText);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Future<List<String>> _collectGeneratedWords(
    WidgetTester tester, int count) async {
  final words = <String>[];
  final scrollable = find.descendant(
    of: find.byType(SecretPhraseGeneratorPage),
    matching: find.byType(Scrollable),
  );

  for (int i = 0; i < count; i++) {
    final key = ValueKey('gen_word_$i');

    for (int attempt = 0; attempt < 30; attempt++) {
      if (find.byKey(key).evaluate().isNotEmpty) break;
      await tester.drag(scrollable.first, const Offset(0, -300));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    }

    final widget = tester.widget<MnemonicWordInput>(find.byKey(key));
    words.add(widget.word);
  }

  return words;
}

Future<void> _confirmBackup(WidgetTester tester) async {
  final genCheckbox = find.descendant(
    of: find.byType(SecretPhraseGeneratorPage),
    matching: find.byType(CheckboxListTile),
  );
  await tester.ensureVisible(genCheckbox);
  await tester.pumpAndSettle();
  await tester.tap(genCheckbox);
  await tester.pumpAndSettle(const Duration(seconds: 1));

  final modalCheckboxes = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.byType(CheckboxListTile),
  );
  expect(modalCheckboxes, findsNWidgets(4));

  for (int i = 0; i < 4; i++) {
    await tester.tap(modalCheckboxes.at(i));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Future<void> _tapPageButton(WidgetTester tester, Type pageType) async {
  final button = find.descendant(
    of: find.byType(pageType),
    matching: find.byType(CustomButton),
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _fillVerifyInputs(
    WidgetTester tester, List<String> generatedWords) async {
  for (int i = 0; i < 4; i++) {
    final verifyFinder = find.byKey(ValueKey('verify_$i'));
    final verifyWidget = tester.widget<MnemonicWordInput>(verifyFinder);
    final wordIndex = verifyWidget.index - 1;
    final correctWord = generatedWords[wordIndex];

    await tester.ensureVisible(verifyFinder);
    await tester.pumpAndSettle();

    final textField = find.descendant(
      of: verifyFinder,
      matching: find.byType(TextField),
    );
    await tester.enterText(textField, correctWord);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}

Future<void> _popToGenWalletOptions(WidgetTester tester) async {
  final backButton = find.descendant(
    of: find.byType(PasswordSetupPage),
    matching: find.descendant(
      of: find.byType(CustomAppBar),
      matching: find.byType(IconButton),
    ),
  );
  await tester.tap(backButton.first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Future<void> _testWordCount(WidgetTester tester, int count) async {
  await _enterGenBip39(tester);
  debugPrint('  → Entered GenBip39 page');

  await _selectWordCount(tester, count);
  debugPrint('  → Selected $count words');

  final words = await _collectGeneratedWords(tester, count);
  expect(words.length, equals(count));
  debugPrint('  → Collected ${words.length} generated words');

  await _confirmBackup(tester);
  debugPrint('  → Confirmed backup');

  await _tapPageButton(tester, SecretPhraseGeneratorPage);
  expect(find.byType(SecretPhraseVerifyPage), findsOneWidget);
  debugPrint('  → Navigated to Verify page');

  await _fillVerifyInputs(tester, words);
  debugPrint('  → Filled verify inputs');

  await _tapPageButton(tester, SecretPhraseVerifyPage);
  expect(find.byType(PasswordSetupPage), findsOneWidget);
  debugPrint('  → Navigated to Password page');

  await _popToGenWalletOptions(tester);
  debugPrint('  → Popped back to GenWalletOptions');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Generate BIP39 12-24 word and verify', (tester) async {
    await _clearStorage();
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await _navigateToGenWalletOptions(tester);
    debugPrint('✓ Navigation to GenWalletOptions OK');

    await _testWordCount(tester, 12);
    debugPrint('✓ Test 1: 12-word gen + verify');

    await _testWordCount(tester, 15);
    debugPrint('✓ Test 2: 15-word gen + verify');

    await _testWordCount(tester, 18);
    debugPrint('✓ Test 3: 18-word gen + verify');

    await _testWordCount(tester, 21);
    debugPrint('✓ Test 4: 21-word gen + verify');

    await _testWordCount(tester, 24);
    debugPrint('✓ Test 5: 24-word gen + verify');
  });
}
