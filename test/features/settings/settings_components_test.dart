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
}
