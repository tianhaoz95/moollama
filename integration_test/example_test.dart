import 'package:moollama/main.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('Happy path', ($) async {
    await $.pumpWidget(const MyApp());

    const int platformPermissionCount = 3;

    for (var i = 0; i < platformPermissionCount; i++) {
      if (await $.native.isPermissionDialogVisible(
        timeout: Duration(seconds: 20),
      )) {
        await $.native.grantPermissionWhenInUse();
      }
    }

    await $('Yes').tap();

    await $.pumpAndSettle(timeout: Duration(minutes: 15));
  });
}
