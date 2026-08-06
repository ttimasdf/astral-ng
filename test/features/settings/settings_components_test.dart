import 'package:astral/core/states/app_settings_state.dart';
import 'package:astral/core/states/display_state.dart';
import 'package:astral/core/states/window_state.dart';
import 'package:astral/features/settings/widgets/settings_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings section renders its hierarchy and controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SettingsContentView(
            children: [
              SettingsSection(
                title: 'Core network',
                description: 'Protocol and security',
                icon: Icons.hub_outlined,
                children: const [
                  ListTile(title: Text('Encryption')),
                  SwitchListTile(
                    title: Text('Latency first'),
                    value: true,
                    onChanged: null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Core network'), findsOneWidget);
    expect(find.text('Encryption'), findsOneWidget);
    expect(find.text('Latency first'), findsOneWidget);
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
  });

  testWidgets('category routes use their app bar without a duplicate header', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () {
                Navigator.of(tester.element(find.byType(FilledButton))).push(
                  MaterialPageRoute<void>(
                    builder:
                        (_) => Scaffold(
                          appBar: AppBar(title: const Text('Category')),
                          body: SettingsContentView(
                            children: const [Text('Category content')],
                          ),
                        ),
                  ),
                );
              },
              child: const Text('Open category'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open category'));
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Category content'), findsOneWidget);
  });

  testWidgets('settings link tile exposes its current value and action', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsLinkTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Application language',
            value: 'English',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.text('Language'));
    expect(tapped, isTrue);
  });

  testWidgets('disabled settings link tile does not invoke its action', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsLinkTile(
            icon: Icons.vpn_lock,
            title: 'Custom VPN segments',
            subtitle: 'Available on Android only',
            enabled: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Custom VPN segments'));
    expect(tapped, isFalse);
  });

  testWidgets('segmented choice reports the selected close behavior', (
    tester,
  ) async {
    var selected = WindowCloseBehavior.closeToTray;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsSegmentedChoice<WindowCloseBehavior>(
            title: 'When closing the window',
            description: 'Keep running in the tray',
            value: selected,
            segments: const [
              ButtonSegment(
                value: WindowCloseBehavior.closeToTray,
                label: Text('Close to tray'),
              ),
              ButtonSegment(
                value: WindowCloseBehavior.exitProgram,
                label: Text('Exit program'),
              ),
            ],
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Exit program'));
    expect(selected, WindowCloseBehavior.exitProgram);
  });

  testWidgets('scrollable segmented choice fits a compact layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsSegmentedChoice<String>(
            title: 'Preferred peer protocol',
            description: 'Choose the first protocol to try',
            value: 'tcp',
            scrollable: true,
            segments: const [
              ButtonSegment(value: 'tcp', label: Text('TCP')),
              ButtonSegment(value: 'udp', label: Text('UDP')),
              ButtonSegment(value: 'faketcp', label: Text('FakeTCP')),
              ButtonSegment(value: 'ws', label: Text('WS')),
              ButtonSegment(value: 'wss', label: Text('WSS')),
              ButtonSegment(value: 'quic', label: Text('QUIC')),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('peer cards default to the compact layout', () {
    expect(DisplayState().compactPeerCards.value, isTrue);
  });

  test('window close behavior defaults to close to tray', () {
    expect(WindowState().closeBehavior.value, WindowCloseBehavior.closeToTray);
  });

  test('connection retry limit stays between zero and ten', () {
    final state = AppSettingsState();

    state.setConnectionRetryLimit(-1);
    expect(state.connectionRetryLimit.value, 0);

    state.setConnectionRetryLimit(11);
    expect(state.connectionRetryLimit.value, 10);
  });
}
