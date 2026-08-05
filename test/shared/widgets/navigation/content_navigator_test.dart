import 'package:astral/shared/widgets/navigation/content_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pushed pages remain inside the application shell', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Application shell')),
          body: ContentNavigator(
            navigatorKey: navigatorKey,
            active: true,
            rootPage: Builder(
              builder:
                  (context) => Center(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => Scaffold(
                                  appBar: AppBar(
                                    title: const Text('Nested page'),
                                  ),
                                  body: const Center(
                                    child: Text('Nested content'),
                                  ),
                                ),
                          ),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Application shell'), findsOneWidget);
    expect(find.text('Nested page'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isTrue);
  });
}
