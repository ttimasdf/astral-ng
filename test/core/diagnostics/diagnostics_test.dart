import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/core/bootstrap/startup_host.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostic_sanitizer.dart';
import 'package:astral/core/diagnostics/diagnostic_store.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/sinks/rotating_jsonl_sink.dart';

void main() {
  group('LogPolicy', () {
    test('uses longest configured module prefix', () {
      final policy = LogPolicy.debugDefaults();

      expect(
        policy.minimumLevel(
          '${DiagnosticModules.easyTierTunnel}.udp',
          DiagnosticDestination.console,
        ),
        LogSeverity.warning,
      );
      expect(
        policy.minimumLevel(
          DiagnosticModules.connection,
          DiagnosticDestination.console,
        ),
        LogSeverity.debug,
      );
    });

    test('always preserves errors in console and memory', () {
      final policy = LogPolicy.productionDefaults();
      final module = '${DiagnosticModules.easyTierTunnel}.udp';

      expect(
        policy.allows(module, LogSeverity.debug, DiagnosticDestination.console),
        isFalse,
      );
      expect(
        policy.allows(module, LogSeverity.error, DiagnosticDestination.console),
        isTrue,
      );
      expect(
        policy.allows(module, LogSeverity.error, DiagnosticDestination.memory),
        isTrue,
      );
    });
  });

  test(
    'runtime normalizes structured records and errors synchronously',
    () async {
      final runtime = DiagnosticsRuntime.bootstrap(
        initialPolicy: LogPolicy.debugDefaults(),
      );
      addTearDown(runtime.close);

      runtime
          .logger(DiagnosticModules.connection)
          .error(
            'connect.failed',
            'Connection failed',
            fields: {'attempt': '42'},
            error: StateError('not connected'),
            stackTrace: StackTrace.fromString('#0 connect'),
          );

      expect(runtime.store.value, hasLength(1));
      final record = runtime.store.value.single;
      expect(record.eventCode, 'connect.failed');
      expect(record.fields['attempt'], '42');
      expect(record.errorId, isNotNull);
      expect(record.errorType, 'StateError');
      expect(record.stackTrace, contains('#0 connect'));
    },
  );

  test('diagnostic store evicts the oldest record', () {
    final source = DiagnosticsRuntime.bootstrap(
      initialPolicy: LogPolicy.debugDefaults(),
    );
    addTearDown(source.close);
    final store = DiagnosticStore(capacity: 2);
    addTearDown(store.close);

    final logger = source.logger(DiagnosticModules.bootstrap);
    logger.info('one', 'one');
    logger.info('two', 'two');
    logger.info('three', 'three');
    for (final record in source.store.value) {
      store.add(record);
    }

    expect(store.value.map((record) => record.eventCode), ['two', 'three']);
  });

  test('sanitizer redacts sensitive keys and inline credentials', () {
    const sanitizer = DiagnosticSanitizer();

    expect(
      sanitizer.fields({
        'password': 'hunter2',
        'detail': 'Authorization=Bearer-secret',
      }),
      {'password': '<redacted>', 'detail': 'Authorization=<redacted>'},
    );
  });

  test('rotating JSONL sink persists structured bounded records', () async {
    final directory = await Directory.systemTemp.createTemp('astral-logs-');
    addTearDown(() => directory.delete(recursive: true));
    final sink = await RotatingJsonlSink.open(
      directory: directory,
      maxBytes: 900,
      retainedFiles: 2,
    );
    addTearDown(sink.close);
    final runtime = DiagnosticsRuntime.bootstrap(
      initialPolicy: LogPolicy.debugDefaults(),
      additionalSinks: [sink],
    );
    addTearDown(runtime.close);

    for (var index = 0; index < 12; index++) {
      runtime
          .logger(DiagnosticModules.bootstrap)
          .info(
            'rotation.$index',
            'Structured record $index ${'x' * 80}',
            fields: {'index': index},
          );
    }
    await runtime.flush();

    final files =
        await directory
            .list()
            .where((entity) => entity is File)
            .cast<File>()
            .toList();
    expect(files.length, lessThanOrEqualTo(3));
    expect(files, isNotEmpty);
    final lines = await files.last.readAsLines();
    expect(lines, isNotEmpty);
    final decoded = jsonDecode(lines.last) as Map<String, dynamic>;
    expect(decoded['schema_version'], 1);
    expect(decoded['module'], DiagnosticModules.bootstrap);
    expect(decoded['fields'], isA<Map<String, dynamic>>());
  });

  testWidgets('StartupHost renders before bootstrap completes', (tester) async {
    final runtime = DiagnosticsRuntime.bootstrap();
    addTearDown(runtime.close);
    final completer = Completer<Widget>();

    await tester.pumpWidget(
      StartupHost(diagnostics: runtime, bootstrap: () => completer.future),
    );

    expect(find.text('AstralNG'), findsOneWidget);
    expect(find.text('Starting…'), findsOneWidget);

    completer.complete(const MaterialApp(home: Text('Ready')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('StartupHost renders diagnostics for a critical failure', (
    tester,
  ) async {
    final runtime = DiagnosticsRuntime.bootstrap();
    addTearDown(runtime.close);

    await tester.pumpWidget(
      StartupHost(
        diagnostics: runtime,
        bootstrap: () async => throw StateError('database unavailable'),
      ),
    );
    await tester.pump();

    expect(find.text('AstralNG could not start'), findsOneWidget);
    expect(find.textContaining('database unavailable'), findsOneWidget);
    expect(find.textContaining('Diagnostic ID:'), findsOneWidget);
    expect(
      runtime.store.value.any(
        (record) => record.eventCode == 'bootstrap.failed',
      ),
      isTrue,
    );
  });
}
