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
            title: 'Network & Connection',
            description: 'Connection defaults',
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

    expect(find.text('Network & Connection'), findsOneWidget);
    expect(find.text('Core network'), findsOneWidget);
    expect(find.text('Encryption'), findsOneWidget);
    expect(find.text('Latency first'), findsOneWidget);
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
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

  test('window close behavior defaults to close to tray', () {
    expect(WindowState().closeBehavior.value, WindowCloseBehavior.closeToTray);
  });
}
