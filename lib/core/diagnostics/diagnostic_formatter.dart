import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/diagnostic_record.dart';

abstract final class DiagnosticFormatter {
  static String console(DiagnosticRecord record) {
    final local = record.sourceTimestampUtc.toLocal();
    final time =
        '${_two(local.hour)}:${_two(local.minute)}:'
        '${_two(local.second)}.${_three(local.millisecond)}';
    final module =
        record.module.startsWith('astral.')
            ? record.module.substring('astral.'.length)
            : record.module;
    final fields = <String, Object?>{
      ...record.fields,
      if (record.operationId != null) 'operation': record.operationId,
      if (record.connectionAttemptId != null)
        'attempt': record.connectionAttemptId,
      if (record.easyTierInstanceId != null)
        'instance': record.easyTierInstanceId,
      if (record.errorId != null) 'error_id': record.errorId,
    };
    final suffix = fields.isEmpty ? '' : ' | ${_formatFields(fields)}';
    return '$time ${record.level.token} '
        '${module.padRight(18)} ${record.eventCode.padRight(24)} '
        '${record.message}$suffix';
  }

  static String details(DiagnosticRecord record) {
    final parts = <String>[];
    if (record.errorMessage != null) parts.add(record.errorMessage!);
    if (record.stackTrace != null) parts.add(record.stackTrace!);
    return parts.join('\n');
  }

  static String _formatFields(Map<String, Object?> fields) {
    final keys = fields.keys.toList()..sort();
    return keys.map((key) => '$key=${fields[key]}').join(' ');
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
  static String _three(int value) => value.toString().padLeft(3, '0');
}
