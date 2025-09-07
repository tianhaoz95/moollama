import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moollama/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify app bar title', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify that the AppBar title is present.
      expect(find.text('Moollama'), findsOneWidget);
    });
  });
}