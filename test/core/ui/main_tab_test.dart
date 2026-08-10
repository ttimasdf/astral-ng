import 'package:astral/core/ui/main_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Relay is the third main destination', () {
    expect(MainTab.values, [
      MainTab.home,
      MainTab.room,
      MainTab.servers,
      MainTab.tools,
      MainTab.settings,
    ]);
  });
}
