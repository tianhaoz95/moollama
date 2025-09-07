import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'counter is incremented',
    ($) async {
      await $.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('app')),
        ),
      ));

      await $.pumpAndSettle();
    },
  );
}
