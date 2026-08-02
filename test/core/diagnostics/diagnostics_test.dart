import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/core/bootstrap/bootstrap_stage_failure.dart';
import 'package:astral/core/bootstrap/startup_host.dart';
import 'package:astral/features/settings/pages/general/logs_page.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/diagnostic_launch_options.dart';
import 'package:astral/core/diagnostics/diagnostic_context.dart';
import 'package:astral/core/diagnostics/diagnostic_flood_controller.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/diagnostic_sanitizer.dart';
import 'package:astral/core/diagnostics/diagnostic_store.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/error/error_coordinator.dart';
import 'package:astral/core/diagnostics/error/error_hook_registration.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/sinks/rotating_jsonl_sink.dart';
import 'package:astral/core/diagnostics/sources/easy_localization_diagnostic_source.dart';
import 'package:astral/core/diagnostics/support_bundle.dart';

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
    'launch options apply a bounded diagnostic preset and overrides',
    () async {
      final options = DiagnosticLaunchOptions.parse(const [
        '--autostart',
        '--log-preset=diagnostic',
        '--log-module=astral.connection=info',
        '--log-module=astral.easytier.peer=trace',
        '--log-duration=45s',
      ]);
      final runtime = DiagnosticsRuntime.bootstrap(
        initialPolicy: options.initialPolicy(debugBuild: false),
      );
      addTearDown(runtime.close);
      options.applyTo(runtime);

      expect(runtime.policy.value.name, 'diagnostic');
      expect(runtime.policy.isDiagnosticSession, isTrue);
      expect(
        runtime.policy.value.minimumLevel(
          DiagnosticModules.connection,
          DiagnosticDestination.console,
        ),
        LogSeverity.info,
      );
      expect(
        runtime.policy.value.minimumLevel(
          DiagnosticModules.easyTierPeer,
          DiagnosticDestination.console,
        ),
        LogSeverity.trace,
      );
      expect(options.diagnosticDuration, const Duration(seconds: 45));
      expect(options.invalidOptionCount, 0);
    },
  );

  test(
    'invalid launch options fall back safely without echoing values',
    () async {
      final options = DiagnosticLaunchOptions.parse(const [
        '--log-preset=everything',
        '--log-module=other.secret=trace',
        '--log-duration=7d',
        '--unrelated=value',
      ]);
      final runtime = DiagnosticsRuntime.bootstrap(
        initialPolicy: options.initialPolicy(debugBuild: false),
      );
      addTearDown(runtime.close);
      options.applyTo(runtime);

      expect(options.invalidOptionCount, 3);
      expect(runtime.policy.value.name, 'production');
      final warning = runtime.store.value.single;
      expect(warning.eventCode, 'launch-options.invalid');
      expect(warning.fields, {'invalid_option_count': 3});
    },
  );

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

  test('runtime carries operation and connection correlation from context', () {
    final runtime = DiagnosticsRuntime.bootstrap(
      initialPolicy: LogPolicy.debugDefaults(),
    );
    addTearDown(runtime.close);

    DiagnosticContext.run(
      const DiagnosticContext(
        operationId: 'OP1',
        connectionAttemptId: 'ATTEMPT1',
      ),
      () => runtime
          .logger(DiagnosticModules.connection)
          .info('connect.start', 'Connection started'),
    );

    final record = runtime.store.value.single;
    expect(record.operationId, 'OP1');
    expect(record.connectionAttemptId, 'ATTEMPT1');
  });

  test('global error hooks install once and dispose cleanly', () async {
    final runtime = DiagnosticsRuntime.bootstrap();
    addTearDown(runtime.close);
    final coordinator = ErrorCoordinator(runtime);

    final first = ErrorHookRegistration.install(coordinator);
    final second = ErrorHookRegistration.install(coordinator);
    expect(identical(first, second), isTrue);
    first.dispose();
  });

  test('easy_localization warnings use Astral diagnostics', () async {
    final runtime = DiagnosticsRuntime.bootstrap(
      initialPolicy: LogPolicy.debugDefaults(),
    );
    addTearDown(runtime.close);
    final source = EasyLocalizationDiagnosticSource.install(runtime);
    addTearDown(source.dispose);

    EasyLocalization.logger.debug('routine package chatter');
    expect(runtime.store.value, isEmpty);

    EasyLocalization.logger.warning(
      '\u001b[34mmissing localization key\u001b[0m',
    );
    final record = runtime.store.value.single;
    expect(record.module, DiagnosticModules.localization);
    expect(record.eventCode, 'localization.package.warning');
    expect(record.message, 'Localization package reported a warning');
    expect(record.fields['detail'], 'missing localization key');

    runtime.policy.setModuleLevel(
      DiagnosticModules.localization,
      LogSeverity.debug,
    );
    EasyLocalization.logger.debug('localization initialized');
    expect(runtime.store.value.last.eventCode, 'localization.package.debug');
  });

  test('flood controller coalesces duplicates and reports suppression', () {
    var now = DateTime.utc(2026);
    final controller = DiagnosticFloodController(clock: () => now);
    final record = _record(now, eventCode: 'peer.state');

    expect(controller.accepts(record), isTrue);
    expect(controller.accepts(record), isFalse);
    now = now.add(const Duration(seconds: 3));

    final summary = controller.drain().single;
    expect(summary.module, DiagnosticModules.connection);
    expect(summary.reason, 'duplicate');
    expect(summary.count, 1);
  });

  test('flood controller rate-limits low-level module noise', () {
    final now = DateTime.utc(2026);
    final controller = DiagnosticFloodController(clock: () => now);

    for (var index = 0; index < 200; index++) {
      expect(
        controller.accepts(_record(now, eventCode: 'peer.$index')),
        isTrue,
      );
    }
    expect(
      controller.accepts(_record(now, eventCode: 'peer.overflow')),
      isFalse,
    );
  });

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
    expect(store.evictedRecords, 1);
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
    expect(sanitizer.text('\u001b[31mfailed\u001b[0m'), 'failed');
  });

  test('support bundle contains metadata and redacted records', () async {
    final runtime = DiagnosticsRuntime.bootstrap(
      initialPolicy: LogPolicy.debugDefaults(),
    );
    addTearDown(runtime.close);
    runtime
        .logger(DiagnosticModules.connection)
        .warning(
          'connect.failed',
          'Connection failed',
          fields: {'password': 'hunter2', 'attempt': 'A1'},
        );

    final encoded = SupportBundle.encode(
      diagnostics: runtime,
      records: runtime.store.value,
      appVersion: '3.0.0',
      buildNumber: '42',
      platform: 'test',
      buildMode: 'debug',
      generatedAt: DateTime.utc(2026),
    );
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    final records = decoded['records'] as List<dynamic>;
    final fields = (records.single as Map<String, dynamic>)['fields'];

    expect(decoded['support_bundle_schema_version'], 1);
    expect(
      (decoded['session'] as Map<String, dynamic>)['app_version'],
      '3.0.0',
    );
    expect(fields['password'], '<redacted>');
    expect(encoded, isNot(contains('hunter2')));
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

  testWidgets('LogsPage links to an error and exposes advanced filters', (
    tester,
  ) async {
    await Diagnostics.reset();
    final runtime = Diagnostics.initialize(
      initialPolicy: LogPolicy.debugDefaults(),
    );
    addTearDown(Diagnostics.reset);
    runtime
        .logger(DiagnosticModules.connection)
        .error(
          'connect.failed',
          'Connection failed',
          error: StateError('offline'),
        );
    runtime
        .logger(DiagnosticModules.updates)
        .warning('update.failed', 'Update failed');
    final errorId = runtime.store.value.first.errorId;

    await tester.pumpWidget(
      MaterialApp(home: LogsPage(initialErrorId: errorId)),
    );

    expect(find.textContaining('connect.failed'), findsOneWidget);
    expect(find.textContaining('update.failed'), findsNothing);
    await tester.tap(find.byTooltip('关联和来源筛选'));
    await tester.pumpAndSettle();
    expect(find.text('连接尝试 ID'), findsOneWidget);
    expect(find.text('错误 ID'), findsOneWidget);
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

  testWidgets('StartupHost owns a staged bootstrap failure once', (
    tester,
  ) async {
    final runtime = DiagnosticsRuntime.bootstrap();
    addTearDown(runtime.close);
    final original = StateError('Rust unavailable');
    final originalStack = StackTrace.fromString('#0 rustInit');

    await tester.pumpWidget(
      StartupHost(
        diagnostics: runtime,
        bootstrap:
            () async =>
                throw BootstrapStageFailure(
                  stage: 'rust',
                  durationMilliseconds: 42,
                  error: original,
                  stackTrace: originalStack,
                ),
      ),
    );
    await tester.pump();

    final errors =
        runtime.store.value.where((record) => record.isError).toList();
    expect(errors, hasLength(1));
    expect(errors.single.eventCode, 'bootstrap.failed');
    expect(errors.single.fields, containsPair('stage', 'rust'));
    expect(errors.single.fields, containsPair('duration_ms', 42));
    expect(errors.single.errorMessage, contains('Rust unavailable'));
    expect(errors.single.stackTrace, contains('#0 rustInit'));
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

DiagnosticRecord _record(DateTime timestamp, {required String eventCode}) {
  return DiagnosticRecord(
    sourceTimestampUtc: timestamp,
    ingestedTimestampUtc: timestamp,
    ingestSequence: 0,
    sourceSequence: null,
    sessionId: 'session',
    origin: 'dart',
    module: DiagnosticModules.connection,
    level: LogSeverity.debug,
    eventCode: eventCode,
    message: 'test record',
  );
}
