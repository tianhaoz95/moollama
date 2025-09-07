import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moollama/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify listening popup', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 120));

      // Long press to trigger speech recognition
      await tester.longPress(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Verify that the listening popup is visible
      expect(find.text('Listening...'), findsOneWidget);
    });
  });
}
