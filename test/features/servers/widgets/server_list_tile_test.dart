import 'package:astral/core/models/server_mod.dart';
import 'package:astral/core/states/server_status_state.dart';
import 'package:astral/features/servers/widgets/server_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ServerMod server;

  setUp(() {
    server = ServerMod(
      id: 42,
      name: 'Primary server',
      url: 'tcp://example.com:11010',
      enable: true,
    );
  });

  testWidgets('mobile row hides desktop actions and opens edit on tap', (
    tester,
  ) async {
    var editCount = 0;

    await tester.pumpWidget(
      _testApp(
        ServerListTile(
          server: server,
          status: ServerStatus.online,
          useMobileActions: true,
          onEdit: () {
            editCount++;
          },
          onToggle: (_) async {},
          onConfirmDelete: () async => false,
          onDelete: () async {},
        ),
      ),
    );

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);

    await tester.tap(find.text('Primary server'));
    expect(editCount, 1);
  });

  testWidgets('desktop row keeps switch and overflow actions', (tester) async {
    await tester.pumpWidget(
      _testApp(
        ServerListTile(
          server: server,
          status: ServerStatus.online,
          useMobileActions: false,
          onEdit: () {},
          onToggle: (_) async {},
          onConfirmDelete: () async => false,
          onDelete: () async {},
        ),
      ),
    );

    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
  });

  testWidgets('left swipe toggles state without dismissing the row', (
    tester,
  ) async {
    bool? toggledValue;

    await tester.pumpWidget(
      _testApp(
        ServerListTile(
          server: server,
          status: ServerStatus.online,
          useMobileActions: true,
          onEdit: () {},
          onToggle: (value) async {
            toggledValue = value;
          },
          onConfirmDelete: () async => false,
          onDelete: () async {},
        ),
      ),
    );

    await tester.drag(find.byType(Dismissible), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(toggledValue, isFalse);
    expect(find.text('Primary server'), findsOneWidget);
  });

  testWidgets('right swipe requires confirmation before deletion', (
    tester,
  ) async {
    var confirmationCount = 0;
    var deleteCount = 0;

    await tester.pumpWidget(
      _testApp(
        ServerListTile(
          server: server,
          status: ServerStatus.online,
          useMobileActions: true,
          onEdit: () {},
          onToggle: (_) async {},
          onConfirmDelete: () async {
            confirmationCount++;
            return false;
          },
          onDelete: () async {
            deleteCount++;
          },
        ),
      ),
    );

    await tester.drag(find.byType(Dismissible), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(confirmationCount, 1);
    expect(deleteCount, 0);
    expect(find.text('Primary server'), findsOneWidget);
  });

  testWidgets('right swipe deletes after confirmation is accepted', (
    tester,
  ) async {
    var showServer = true;
    var deleteCount = 0;

    await tester.pumpWidget(
      _testApp(
        StatefulBuilder(
          builder:
              (context, setState) =>
                  showServer
                      ? ServerListTile(
                        server: server,
                        status: ServerStatus.online,
                        useMobileActions: true,
                        onEdit: () {},
                        onToggle: (_) async {},
                        onConfirmDelete: () async => true,
                        onDelete: () async {
                          deleteCount++;
                          setState(() => showServer = false);
                        },
                      )
                      : const SizedBox.shrink(),
        ),
      ),
    );

    await tester.drag(find.byType(Dismissible), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(deleteCount, 1);
    expect(find.text('Primary server'), findsNothing);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(home: Scaffold(body: SizedBox(width: 400, child: child)));
}
