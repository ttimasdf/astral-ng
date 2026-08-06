import 'package:logging/logging.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/diagnostic_message.dart';
import 'package:astral/core/diagnostics/log_policy.dart';

final class ModuleLogger {
  ModuleLogger({
    required this.module,
    required LogPolicy Function() policy,
    Logger? logger,
  }) : _policy = policy,
       _logger = logger ?? Logger(module);

  final String module;
  final LogPolicy Function() _policy;
  final Logger _logger;

  bool isLoggable(LogSeverity level) => _policy().allowsAny(module, level);

  void trace(
    String eventCode,
    String message, {
    Map<String, Object?> fields = const {},
  }) => _publish(LogSeverity.trace, eventCode, message, fields: fields);

  void debug(
    String eventCode,
    String message, {
    Map<String, Object?> fields = const {},
  }) => _publish(LogSeverity.debug, eventCode, message, fields: fields);

  void info(
    String eventCode,
    String message, {
    Map<String, Object?> fields = const {},
  }) => _publish(LogSeverity.info, eventCode, message, fields: fields);

  void warning(
    String eventCode,
    String message, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
    String? errorId,
    bool consoleAlreadyReported = false,
  }) => _publish(
    LogSeverity.warning,
    eventCode,
    message,
    fields: fields,
    error: error,
    stackTrace: stackTrace,
    errorId: errorId,
    consoleAlreadyReported: consoleAlreadyReported,
  );

  void error(
    String eventCode,
    String message, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
    String? errorId,
    bool consoleAlreadyReported = false,
  }) => _publish(
    LogSeverity.error,
    eventCode,
    message,
    fields: fields,
    error: error,
    stackTrace: stackTrace,
    errorId: errorId,
    consoleAlreadyReported: consoleAlreadyReported,
  );

  void fatal(
    String eventCode,
    String message, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
    String? errorId,
    bool consoleAlreadyReported = false,
  }) => _publish(
    LogSeverity.fatal,
    eventCode,
    message,
    fields: fields,
    error: error,
    stackTrace: stackTrace,
    errorId: errorId,
    consoleAlreadyReported: consoleAlreadyReported,
  );

  void _publish(
    LogSeverity level,
    String eventCode,
    String message, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
    String? errorId,
    bool consoleAlreadyReported = false,
  }) {
    if (!isLoggable(level)) return;
    _logger.log(
      level.loggingLevel,
      DiagnosticMessage(
        eventCode: eventCode,
        message: message,
        fields: fields,
        errorId: errorId,
        consoleAlreadyReported: consoleAlreadyReported,
      ),
      error,
      stackTrace,
    );
  }
}
