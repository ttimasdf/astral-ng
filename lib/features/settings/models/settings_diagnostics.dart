import 'package:astral/core/diagnostics/diagnostic_record.dart';

const _uncaughtEventCodes = {
  'flutter.framework.uncaught',
  'dart.async.uncaught',
};

String? latestUncaughtErrorId(Iterable<DiagnosticRecord> records) {
  for (final record in records.toList(growable: false).reversed) {
    if (_uncaughtEventCodes.contains(record.eventCode) &&
        record.errorId != null) {
      return record.errorId;
    }
  }
  return null;
}
