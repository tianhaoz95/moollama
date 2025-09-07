import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:moollama/main.dart' as app;

void main() {
  group('end-to-end test', () {
    patrolTest(
      'verify app bar title and grant permissions',
      ($) async {
        await $.pumpWidgetAndSettle(const app.MyApp());

        // Grant permissions (example: camera and microphone)
        await $.native.grantPermissionWhenInUse();

        // Verify that the AppBar title is present.
        expect(find.text('Moollama'), findsOneWidget);
      },
    );
  });
}
