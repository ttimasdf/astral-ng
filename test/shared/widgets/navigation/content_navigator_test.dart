import 'dart:async';

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

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Application shell'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('consecutive system backs unwind the full nested stack', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        home: ContentNavigator(
          navigatorKey: navigatorKey,
          active: true,
          rootPage: const Scaffold(body: Text('Root page')),
        ),
      ),
    );

    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Category page')),
        ),
      ),
    );
    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Detail page')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Category page'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Root page'), findsOneWidget);
  });
}
