import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart'; // Import patrol
import 'package:moollama/main.dart' as app;

void main() {
  PatrolBinding.ensureInitialized(); // Use PatrolBinding

  group('end-to-end test', () {
    patrolTest('verify app bar title and grant permissions', ($) async { // Use patrolTest
      app.main();
      await $.pumpAndSettle();

      // Grant permissions (example: camera and microphone)
      await $.pumpAndSettle(); // Wait for any permission dialogs to appear
      await $.native.grantPermissionWhenInUse(); // Grant permissions when in use

      // Verify that the AppBar title is present.
      expect(find.text('Moollama'), findsOneWidget);
    });
  });
}