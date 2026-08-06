import 'dart:developer' as developer;

import 'package:astral/core/diagnostics/diagnostic_formatter.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/sinks/diagnostic_sink.dart';

final class DeveloperConsoleSink implements DiagnosticSink {
  @override
  DiagnosticDestination get destination => DiagnosticDestination.console;

  @override
  void add(DiagnosticRecord record) {
    if (record.consoleAlreadyReported) return;
    developer.log(
      DiagnosticFormatter.console(record),
      name: record.module,
      level: record.level.developerLevel,
      error: record.errorMessage,
      stackTrace:
          record.stackTrace == null
              ? null
              : StackTrace.fromString(record.stackTrace!),
      sequenceNumber: record.ingestSequence,
      time: record.sourceTimestampUtc,
    );
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}
}
