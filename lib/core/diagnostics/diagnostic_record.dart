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
    this.sourceFile,
    this.sourceLine,
    this.sourceFunction,
    this.operationId,
    this.connectionAttemptId,
    this.easyTierInstanceId,
    this.errorId,
    this.errorType,
    this.errorMessage,
    this.stackTrace,
    this.consoleAlreadyReported = false,
  }) : fields = Map.unmodifiable(fields);

  static const schemaVersion = 2;
  static const ecsVersion = '8.11.0';

  final DateTime sourceTimestampUtc;
  final DateTime ingestedTimestampUtc;
  final int ingestSequence;
  final int? sourceSequence;
  final String sessionId;
  final String origin;
  final String module;
  final String? rawTarget;
  final String? sourceFile;
  final int? sourceLine;
  final String? sourceFunction;
  final LogSeverity level;
  final String? eventCode;
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
    '@timestamp': sourceTimestampUtc.toIso8601String(),
    'ecs.version': ecsVersion,
    'message': message,
    'log.level': level.name,
    'log': {
      'logger': module,
      if (sourceFile != null || sourceLine != null || sourceFunction != null)
        'origin': {
          if (sourceFile != null || sourceLine != null)
            'file': {
              if (sourceFile != null) 'name': sourceFile,
              if (sourceLine != null) 'line': sourceLine,
            },
          if (sourceFunction != null) 'function': sourceFunction,
        },
    },
    'event': {
      'created': ingestedTimestampUtc.toIso8601String(),
      'sequence': sourceSequence ?? ingestSequence,
      'provider': origin,
      if (eventCode != null) 'code': eventCode,
    },
    'service': {'name': 'astral-ng'},
    'session': {'id': sessionId},
    if (errorId != null ||
        errorType != null ||
        errorMessage != null ||
        stackTrace != null)
      'error': {
        if (errorId != null) 'id': errorId,
        if (errorType != null) 'type': errorType,
        if (errorMessage != null) 'message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
      },
    'astral': {
      'schema_version': schemaVersion,
      'ingest_sequence': ingestSequence,
      if (sourceSequence != null) 'source_sequence': sourceSequence,
      if (rawTarget != null) 'raw_target': rawTarget,
      if (eventCode == null) 'classification': 'upstream-unclassified',
      if (fields.isNotEmpty) 'fields': fields,
      if (operationId != null) 'operation_id': operationId,
      if (connectionAttemptId != null)
        'connection_attempt_id': connectionAttemptId,
      if (easyTierInstanceId != null)
        'easytier_instance_id': easyTierInstanceId,
    },
  };
}
