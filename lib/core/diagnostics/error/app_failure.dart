enum FailureImpact {
  none,
  backgroundDegraded,
  operationFailed,
  featureUnavailable,
  startupBlocked,
  sessionFatal,
}

final class AppFailure {
  const AppFailure({
    required this.eventCode,
    required this.message,
    required this.error,
    required this.stackTrace,
    required this.impact,
    this.retryable = false,
    this.fields = const {},
  });

  final String eventCode;
  final String message;
  final Object error;
  final StackTrace stackTrace;
  final FailureImpact impact;
  final bool retryable;
  final Map<String, Object?> fields;
}
