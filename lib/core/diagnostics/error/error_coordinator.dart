import 'package:uuid/uuid.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/error/app_failure.dart';

final class ErrorCoordinator {
  ErrorCoordinator(this.runtime);

  final DiagnosticsRuntime runtime;

  String capture(
    String module,
    AppFailure failure, {
    bool consoleAlreadyReported = false,
  }) {
    final errorId = const Uuid().v4().split('-').first.toUpperCase();
    final fields = <String, Object?>{
      ...failure.fields,
      'impact': failure.impact.name,
      'retryable': failure.retryable,
    };
    final logger = runtime.logger(module);
    final level = switch (failure.impact) {
      FailureImpact.sessionFatal ||
      FailureImpact.startupBlocked => LogSeverity.fatal,
      _ => LogSeverity.error,
    };
    if (level == LogSeverity.fatal) {
      logger.fatal(
        failure.eventCode,
        failure.message,
        fields: fields,
        error: failure.error,
        stackTrace: failure.stackTrace,
        errorId: errorId,
        consoleAlreadyReported: consoleAlreadyReported,
      );
    } else {
      logger.error(
        failure.eventCode,
        failure.message,
        fields: fields,
        error: failure.error,
        stackTrace: failure.stackTrace,
        errorId: errorId,
        consoleAlreadyReported: consoleAlreadyReported,
      );
    }
    return errorId;
  }
}
