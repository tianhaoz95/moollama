import 'package:flutter_test/flutter_test.dart';
import 'package:moollama/utils.dart';

void main() {
  testWidgets('isEmulator returns correct value', (WidgetTester tester) async {
    final bool emulator = await isEmulator();
    print('Is this an emulator? \$emulator');
    // You can add an expectation here if you know the test environment
    // For example, if running on a known emulator:
    // expect(emulator, isTrue);
  });
}
