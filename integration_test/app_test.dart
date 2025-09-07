import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:moollama/main.dart' as app;

void main() {
  patrolTest(
    'verify app starts and has a home page',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Grant microphone permission if requested
      await $.native.grantPermissionWhenInUse();

      // Verify the app starts on the home page.
      expect(find.text('Home Page'), findsOneWidget);

      // Example: Tap on a button if there was one and verify a change.
      // For now, just verify the initial state.
    },
  );
}
