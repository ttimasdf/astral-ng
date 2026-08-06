import 'dart:async';

final class DiagnosticContext {
  const DiagnosticContext({
    this.operationId,
    this.connectionAttemptId,
    this.easyTierInstanceId,
  });

  final String? operationId;
  final String? connectionAttemptId;
  final String? easyTierInstanceId;

  DiagnosticContext merge(DiagnosticContext other) => DiagnosticContext(
    operationId: other.operationId ?? operationId,
    connectionAttemptId: other.connectionAttemptId ?? connectionAttemptId,
    easyTierInstanceId: other.easyTierInstanceId ?? easyTierInstanceId,
  );

  static final Object _zoneKey = Object();

  static DiagnosticContext get current =>
      Zone.current[_zoneKey] as DiagnosticContext? ?? const DiagnosticContext();

  static R run<R>(DiagnosticContext context, R Function() body) {
    return runZoned(body, zoneValues: {_zoneKey: current.merge(context)});
  }
}
