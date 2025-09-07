import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  final String adbPath = path.join(
    '/home/tianhaoz/Android/Sdk',
    'platform-tools',
    Platform.isWindows ? 'adb.exe' : 'adb',
  );

  const String packageName = 'com.moollama.moollama';
  final List<String> permissions = [
    'android.permission.RECORD_AUDIO',
    'android.permission.BLUETOOTH_CONNECT',
  ];

  for (final permission in permissions) {
    await Process.run(adbPath, ['shell', 'pm', 'grant', packageName, permission]);
  }

  await integrationDriver();
}