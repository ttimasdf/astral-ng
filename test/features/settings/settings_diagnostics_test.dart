import 'package:enmesh/core/diagnostics/diagnostic_modules.dart';
import 'package:enmesh/core/diagnostics/diagnostic_record.dart';
import 'package:enmesh/core/diagnostics/log_severity.dart';
import 'package:enmesh/features/settings/models/settings_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects the latest uncaught diagnostic error ID', () {
    final records = [
      _record(eventCode: 'flutter.framework.uncaught', errorId: 'ERR-OLD'),
      _record(eventCode: 'connect.failed', errorId: 'ERR-CONNECTION'),
      _record(eventCode: 'dart.async.uncaught', errorId: 'ERR-LATEST'),
    ];

    expect(latestUncaughtErrorId(records), 'ERR-LATEST');
  });

  test('ignores uncaught diagnostics without an error ID', () {
    final records = [
      _record(eventCode: 'flutter.framework.uncaught'),
      _record(eventCode: 'connect.failed', errorId: 'ERR-CONNECTION'),
    ];

    expect(latestUncaughtErrorId(records), isNull);
  });
}

DiagnosticRecord _record({required String eventCode, String? errorId}) {
  final timestamp = DateTime.utc(2026);
  return DiagnosticRecord(
    sourceTimestampUtc: timestamp,
    ingestedTimestampUtc: timestamp,
    ingestSequence: 0,
    sourceSequence: null,
    sessionId: 'session',
    origin: 'dart',
    module: DiagnosticModules.bootstrap,
    level: LogSeverity.error,
    eventCode: eventCode,
    message: 'test',
    fields: const {},
    errorId: errorId,
  );
}
