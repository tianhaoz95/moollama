import 'package:flutter_test/flutter_test.dart';
import 'package:moollama/utils.dart';

void main() {
  test('isEmulator returns a boolean value', () async {
    // This test primarily checks if the function can be called without errors
    // and returns a boolean. Actual emulator detection requires a device/emulator.
    final bool result = await isEmulator();
    expect(result, isA<bool>());
  });
}
