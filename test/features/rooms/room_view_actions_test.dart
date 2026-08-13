import 'package:astral/features/rooms/pages/user_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final showTopology in [true, false]) {
    testWidgets(
      'copy-link action is available when topology is $showTopology',
      (tester) async {
        var copied = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: RoomViewActions(
                showTopology: showTopology,
                onToggleView: () {},
                onOpenSettings: () {},
                onCopyLink: () => copied = true,
              ),
            ),
          ),
        );

        final share = find.byKey(const ValueKey('room_copy_link'));
        expect(share, findsOneWidget);
        expect(find.byIcon(Icons.share_rounded), findsOneWidget);
        final shareTop = tester.getTopLeft(share).dy;
        final settingsTop =
            tester.getTopLeft(find.byKey(const ValueKey('room_settings'))).dy;
        final toggleTop =
            tester
                .getTopLeft(find.byKey(const ValueKey('room_view_toggle')))
                .dy;
        expect(shareTop, lessThan(settingsTop));
        expect(settingsTop, lessThan(toggleTop));
        await tester.tap(share);
        expect(copied, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('copy-link action is hidden without a selected room', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: RoomViewActions(
            showTopology: true,
            onToggleView: () {},
            onOpenSettings: () {},
            onCopyLink: null,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('room_copy_link')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
