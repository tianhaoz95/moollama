import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:moollama/main.dart' as app;

void main() {
  group('simple test', () {
    patrolTest(
      'counter increments smoke test',
      ($) async {
        await $.pumpWidgetAndSettle(const app.MyApp());

        // Verify that our counter starts at 0.
        expect(find.text('0'), findsOneWidget);
        expect(find.text('1'), findsNothing);

        // Tap the '+' icon and trigger a frame.
        await $.tap(find.byIcon(Icons.add));
        await $.pump();

        // Verify that our counter has incremented.
        expect(find.text('0'), findsNothing);
        expect(find.text('1'), findsOneWidget);
      },
    );
  });
}
