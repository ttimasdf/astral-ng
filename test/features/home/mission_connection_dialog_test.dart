import 'package:enmesh/core/models/room.dart';
import 'package:enmesh/core/services/service_manager.dart';
import 'package:enmesh/features/home/widgets/connect_button.dart';
import 'package:enmesh/features/home/widgets/mission_connection_dialog.dart';
import 'package:enmesh/shared/utils/network/mesh_peer_identity.dart';
import 'package:enmesh/shared/widgets/network/mesh_peer_badge.dart';
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

  testWidgets('peer emoji follows the draft username', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MissionConnectionDialog())),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'Live Preview Peer',
    );
    await tester.pump();

    final badge = tester.widget<MeshPeerBadge>(
      find.byKey(const ValueKey('connection-peer-emoji')),
    );
    expect(badge.username, 'Live Preview Peer');
    expect(
      find.text(
        MeshPeerIdentity.emojiFor(username: badge.username, ip: badge.ip),
      ),
      findsWidgets,
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
