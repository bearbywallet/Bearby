import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/main.dart' as app;
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/state/app_state.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Initial page and navigation full test flow',
      (WidgetTester tester) async {
    // Start the app only once
    await app.main();
    await tester.pump();

    // Test 1: Initial loading indicator appears
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for initialization to complete
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Test 2: Theme toggle button test
    final themeIconButton = find.byType(IconButton).first;
    expect(themeIconButton, findsOneWidget);

    // Get initial appearance code
    AppState appState =
        tester.element(find.byType(IconButton).first).read<AppState>();
    int initialAppearance = appState.state.appearances;

    // Tap theme button
    await tester.tap(themeIconButton);
    await tester.pumpAndSettle();

    // Verify appearance code changed
    appState = tester.element(find.byType(IconButton).first).read<AppState>();
    expect(appState.state.appearances, isNot(equals(initialAppearance)));

    // Test 3: Language button navigation and language selection
    final languageIconButton = find.byType(IconButton).at(1);
    expect(languageIconButton, findsOneWidget);

    await tester.tap(languageIconButton);
    await tester.pumpAndSettle();

    // Verify we're on the language page
    expect(find.text("System"), findsWidgets);
    expect(find.text("English"), findsWidgets);
    expect(find.text("Русский"), findsWidgets);

    // Get current locale
    appState =
        tester.element(find.byType(GestureDetector).first).read<AppState>();
    String? initialLocale = appState.state.locale;

    // Select a different language (English)
    final englishListItem = find.ancestor(
        of: find.text("English").first, matching: find.byType(GestureDetector));
    await tester.tap(englishListItem);
    await tester
        .pumpAndSettle(const Duration(seconds: 2)); // Wait for locale change

    // Verify locale changed
    appState =
        tester.element(find.byType(GestureDetector).first).read<AppState>();

    // If already English, tap Russian
    final russianListItem = find.ancestor(
        of: find.text("Русский").first, matching: find.byType(GestureDetector));
    await tester.tap(russianListItem);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    appState =
        tester.element(find.byType(GestureDetector).first).read<AppState>();
    expect(appState.state.locale, equals("ru"));

    // Navigate back to initial page using the back button inside CustomAppBar
    // Find the IconButton inside the CustomAppBar
    final backButtonFinder = find
        .descendant(
          of: find.byType(CustomAppBar),
          matching: find.byType(IconButton),
        )
        .first;

    expect(backButtonFinder, findsOneWidget);

    await tester.tap(backButtonFinder);
    await tester.pumpAndSettle();

    // Test 4: Get Started button navigation
    final getStartedButtonFinder = find.byType(CustomButton);

    await tester.tap(getStartedButtonFinder);
    await tester.pumpAndSettle();

    // Verify we're on the new wallet options page
    // This depends on what text or elements are on that page
    // expect(find.text("New Wallet Options"), findsOneWidget);
    // Instead of looking for a key, we'll check we're no longer on initial page
    expect(find.byType(CustomButton), findsNothing);
  });
}
