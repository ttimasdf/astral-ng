import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/diagnostic_message.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/diagnostic_sanitizer.dart';
import 'package:astral/core/diagnostics/diagnostic_store.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/log_policy_controller.dart';
import 'package:astral/core/diagnostics/module_logger.dart';
import 'package:astral/core/diagnostics/sinks/developer_console_sink.dart';
import 'package:astral/core/diagnostics/sinks/diagnostic_sink.dart';

final class DiagnosticsRuntime {
  DiagnosticsRuntime._({
    required this.sessionId,
    required this.policy,
    required this.store,
    required List<DiagnosticSink> sinks,
    DiagnosticSanitizer sanitizer = const DiagnosticSanitizer(),
  }) : _sinks = List.of(sinks),
       _sanitizer = sanitizer {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = Level.ALL;
    _subscription = Logger.root.onRecord.listen(_ingest);
  }

  factory DiagnosticsRuntime.bootstrap({
    LogPolicy? initialPolicy,
    List<DiagnosticSink>? additionalSinks,
  }) {
    final store = DiagnosticStore();
    final policy = LogPolicyController(
      initialPolicy ??
          (kDebugMode
              ? LogPolicy.debugDefaults()
              : LogPolicy.productionDefaults()),
    );
    return DiagnosticsRuntime._(
      sessionId: const Uuid().v4(),
      policy: policy,
      store: store,
      sinks: [DeveloperConsoleSink(), store, ...?additionalSinks],
    );
  }

  final String sessionId;
  final LogPolicyController policy;
  final DiagnosticStore store;
  final List<DiagnosticSink> _sinks;
  final DiagnosticSanitizer _sanitizer;
  final Map<String, ModuleLogger> _loggers = {};
  final Set<DiagnosticDestination> _failedDestinations = {};
  late final StreamSubscription<LogRecord> _subscription;
  int _ingestSequence = 0;
  bool _closed = false;

  ModuleLogger logger(String module) => _loggers.putIfAbsent(
    module,
    () => ModuleLogger(module: module, policy: () => policy.value),
  );

  void attachSink(DiagnosticSink sink) {
    if (_closed) {
      unawaited(sink.close());
      return;
    }
    if (_sinks.any((current) => current.destination == sink.destination)) {
      throw StateError(
        'A ${sink.destination.name} diagnostic sink is already attached',
      );
    }
    _sinks.add(sink);
  }

  void _ingest(LogRecord source) {
    if (_closed) return;
    final object = source.object;
    final message =
        object is DiagnosticMessage
            ? object
            : DiagnosticMessage(
              eventCode: 'legacy.message',
              message: source.message,
            );
    final level = LogSeverityMapping.fromLogging(source.level);
    final error = source.error;
    final errorId = message.errorId ?? (error == null ? null : _newErrorId());
    final record = DiagnosticRecord(
      sourceTimestampUtc: source.time.toUtc(),
      ingestedTimestampUtc: DateTime.now().toUtc(),
      ingestSequence: _ingestSequence++,
      sourceSequence: source.sequenceNumber,
      sessionId: sessionId,
      origin: 'dart',
      module:
          source.loggerName.isEmpty
              ? DiagnosticModules.root
              : source.loggerName,
      level: level,
      eventCode: _sanitizer.text(message.eventCode, maxLength: 128),
      message: _sanitizer.text(message.message),
      fields: _sanitizer.fields(message.fields),
      operationId: message.context.operationId,
      connectionAttemptId: message.context.connectionAttemptId,
      easyTierInstanceId: message.context.easyTierInstanceId,
      errorId: errorId,
      errorType: error?.runtimeType.toString(),
      errorMessage: error == null ? null : _sanitizer.text(error),
      stackTrace:
          source.stackTrace == null
              ? null
              : _sanitizer.text(
                source.stackTrace,
                maxLength: DiagnosticSanitizer.maxStackLength,
              ),
      consoleAlreadyReported: message.consoleAlreadyReported,
    );

    _deliver(record);
  }

  void ingestExternal({
    required DateTime sourceTimestampUtc,
    required int? sourceSequence,
    required String origin,
    required String module,
    required String? rawTarget,
    required LogSeverity level,
    required String eventCode,
    required String message,
    Map<String, Object?> fields = const {},
    String? operationId,
    String? connectionAttemptId,
    String? easyTierInstanceId,
    String? errorId,
    String? errorType,
    String? errorMessage,
    String? stackTrace,
    bool consoleAlreadyReported = false,
  }) {
    if (_closed) return;
    _deliver(
      DiagnosticRecord(
        sourceTimestampUtc: sourceTimestampUtc.toUtc(),
        ingestedTimestampUtc: DateTime.now().toUtc(),
        ingestSequence: _ingestSequence++,
        sourceSequence: sourceSequence,
        sessionId: sessionId,
        origin: origin,
        module: module,
        rawTarget: rawTarget,
        level: level,
        eventCode: _sanitizer.text(eventCode, maxLength: 128),
        message: _sanitizer.text(message),
        fields: _sanitizer.fields(fields),
        operationId: operationId,
        connectionAttemptId: connectionAttemptId,
        easyTierInstanceId: easyTierInstanceId,
        errorId: errorId,
        errorType: errorType,
        errorMessage:
            errorMessage == null ? null : _sanitizer.text(errorMessage),
        stackTrace:
            stackTrace == null
                ? null
                : _sanitizer.text(
                  stackTrace,
                  maxLength: DiagnosticSanitizer.maxStackLength,
                ),
        consoleAlreadyReported: consoleAlreadyReported,
      ),
    );
  }

  void _deliver(DiagnosticRecord record) {
    for (final sink in _sinks) {
      if (!policy.value.allows(record.module, record.level, sink.destination)) {
        continue;
      }
      try {
        sink.add(record);
      } catch (error, stack) {
        _reportSinkFailureOnce(sink.destination, error, stack);
      }
    }
  }

  void _reportSinkFailureOnce(
    DiagnosticDestination destination,
    Object error,
    StackTrace stack,
  ) {
    if (!_failedDestinations.add(destination)) return;
    developer.log(
      'Diagnostic ${destination.name} sink failed: $error',
      name: DiagnosticModules.logging,
      level: Level.SEVERE.value,
      error: error,
      stackTrace: stack,
    );
  }

  String _newErrorId() => const Uuid().v4().split('-').first.toUpperCase();

  Future<void> flush() async {
    for (final sink in _sinks) {
      try {
        await sink.flush();
      } catch (error, stack) {
        _reportSinkFailureOnce(sink.destination, error, stack);
      }
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    for (final sink in _sinks.reversed) {
      try {
        await sink.close();
      } catch (error, stack) {
        _reportSinkFailureOnce(sink.destination, error, stack);
      }
    }
    policy.dispose();
  }
}

abstract final class Diagnostics {
  static DiagnosticsRuntime? _runtime;

  static DiagnosticsRuntime initialize({LogPolicy? initialPolicy}) {
    return _runtime ??= DiagnosticsRuntime.bootstrap(
      initialPolicy: initialPolicy,
    );
  }

  static DiagnosticsRuntime get runtime => initialize();

  static ModuleLogger logger(String module) => runtime.logger(module);

  @visibleForTesting
  static Future<void> reset() async {
    final current = _runtime;
    _runtime = null;
    await current?.close();
  }
}
