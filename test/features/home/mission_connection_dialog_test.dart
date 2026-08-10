import 'package:astral/core/models/room.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/features/home/widgets/connect_button.dart';
import 'package:astral/features/home/widgets/mission_connection_dialog.dart';
import 'package:flutter/material.dart';
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

  testWidgets('connect without a room opens an actionable dialog', (
    tester,
  ) async {
    final services = ServiceManager();
    services.roomState.selectRoom(null);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectButton())),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });
}
