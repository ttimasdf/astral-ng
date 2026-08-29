import 'package:enmesh/core/models/room.dart';
import 'package:enmesh/features/rooms/pages/room_page.dart';
import 'package:enmesh/features/rooms/widgets/room_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disconnected room actions are vertical sort, import, add', (
    tester,
  ) async {
    var sorted = false;
    var imported = false;
    var added = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: RoomListActions(
            onSort: () => sorted = true,
            onImport: () => imported = true,
            onAdd: () => added = true,
          ),
        ),
      ),
    );

    final sort = find.byKey(const ValueKey('room_sort'));
    final import = find.byKey(const ValueKey('room_import'));
    final add = find.byKey(const ValueKey('room_add'));
    expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    expect(find.byIcon(Icons.paste), findsNothing);
    expect(tester.getCenter(sort).dx, tester.getCenter(import).dx);
    expect(tester.getCenter(import).dx, tester.getCenter(add).dx);
    expect(tester.getTopLeft(sort).dy, lessThan(tester.getTopLeft(import).dy));
    expect(tester.getTopLeft(import).dy, lessThan(tester.getTopLeft(add).dy));

    await tester.tap(sort);
    await tester.tap(import);
    await tester.tap(add);
    expect((sorted, imported, added), (true, true, true));
    expect(tester.takeException(), isNull);
  });

  for (final simpleMode in [true, false]) {
    testWidgets('room card has no redundant mode glyph in mode $simpleMode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomCard(
              room: Room(
                name: 'Room',
                simpleMode: simpleMode,
                roomName: 'mesh',
                password: 'secret',
                messageKey: '',
                tags: const [],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome), findsNothing);
      expect(find.byIcon(Icons.tune), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
