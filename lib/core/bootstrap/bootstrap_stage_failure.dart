final class BootstrapStageFailure implements Exception {
  const BootstrapStageFailure({
    required this.stage,
    required this.durationMilliseconds,
    required this.error,
    required this.stackTrace,
  });

  final String stage;
  final int durationMilliseconds;
  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() => error.toString();
}
