import 'package:astral/core/diagnostics/log_severity.dart';

final class DiagnosticRecord {
  DiagnosticRecord({
    required this.sourceTimestampUtc,
    required this.ingestedTimestampUtc,
    required this.ingestSequence,
    required this.sourceSequence,
    required this.sessionId,
    required this.origin,
    required this.module,
    required this.level,
    required this.eventCode,
    required this.message,
    Map<String, Object?> fields = const {},
    this.rawTarget,
    this.operationId,
    this.connectionAttemptId,
    this.easyTierInstanceId,
    this.errorId,
    this.errorType,
    this.errorMessage,
    this.stackTrace,
    this.consoleAlreadyReported = false,
  }) : fields = Map.unmodifiable(fields);

  static const schemaVersion = 1;

  final DateTime sourceTimestampUtc;
  final DateTime ingestedTimestampUtc;
  final int ingestSequence;
  final int? sourceSequence;
  final String sessionId;
  final String origin;
  final String module;
  final String? rawTarget;
  final LogSeverity level;
  final String eventCode;
  final String message;
  final Map<String, Object?> fields;
  final String? operationId;
  final String? connectionAttemptId;
  final String? easyTierInstanceId;
  final String? errorId;
  final String? errorType;
  final String? errorMessage;
  final String? stackTrace;
  final bool consoleAlreadyReported;

  bool get isError => level.index >= LogSeverity.error.index;

  Map<String, Object?> toJson() => {
    'schema_version': schemaVersion,
    'source_timestamp_utc': sourceTimestampUtc.toIso8601String(),
    'ingested_timestamp_utc': ingestedTimestampUtc.toIso8601String(),
    'ingest_sequence': ingestSequence,
    if (sourceSequence != null) 'source_sequence': sourceSequence,
    'session_id': sessionId,
    'origin': origin,
    'module': module,
    if (rawTarget != null) 'raw_target': rawTarget,
    'level': level.name,
    'event_code': eventCode,
    'message': message,
    if (fields.isNotEmpty) 'fields': fields,
    if (operationId != null) 'operation_id': operationId,
    if (connectionAttemptId != null)
      'connection_attempt_id': connectionAttemptId,
    if (easyTierInstanceId != null) 'easytier_instance_id': easyTierInstanceId,
    if (errorId != null) 'error_id': errorId,
    if (errorType != null) 'error_type': errorType,
    if (errorMessage != null) 'error_message': errorMessage,
    if (stackTrace != null) 'stack_trace': stackTrace,
  };
}
