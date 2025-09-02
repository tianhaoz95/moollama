import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:secret_agent/main.dart' as app; // Assuming your main.dart is in lib/

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify app launches and finds text', (tester) async {
      app.main(); // Start the app
      await tester.pumpAndSettle(); // Wait for the app to render

      // Verify that a specific text is present on the screen
      expect(find.text('Secret Agent'), findsOneWidget);
    });
  });
}