import 'package:astral/core/models/room.dart';
import 'package:astral/features/home/widgets/mission_connection_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonicalizes a selected room to the list instance', () {
    final selected = Room(id: 7, name: 'Orion');
    final listed = Room(id: 7, name: 'Orion');

    expect(canonicalRoomSelection(selected, [listed]), same(listed));
  });

  test('returns null when the selected room is no longer listed', () {
    final selected = Room(id: 7, name: 'Orion');

    expect(
      canonicalRoomSelection(selected, [Room(id: 8, name: 'Lyra')]),
      isNull,
    );
  });
}
