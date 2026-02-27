import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bearby/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end app testing', () {
    testWidgets('Test app launch and initialization',
        (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      expect(true, true);
    });
  });
}
