import 'package:astral/core/diagnostics/diagnostic_context.dart';

final class DiagnosticMessage {
  DiagnosticMessage({
    required this.eventCode,
    required this.message,
    Map<String, Object?> fields = const {},
    DiagnosticContext? context,
    this.errorId,
    this.consoleAlreadyReported = false,
  }) : fields = Map.unmodifiable(fields),
       context = context ?? DiagnosticContext.current;

  final String eventCode;
  final String message;
  final Map<String, Object?> fields;
  final DiagnosticContext context;
  final String? errorId;
  final bool consoleAlreadyReported;

  @override
  String toString() => message;
}
