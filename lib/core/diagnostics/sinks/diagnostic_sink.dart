import 'package:enmesh/core/diagnostics/diagnostic_record.dart';
import 'package:enmesh/core/diagnostics/log_policy.dart';

abstract interface class DiagnosticSink {
  DiagnosticDestination get destination;

  void add(DiagnosticRecord record);

  Future<void> flush();

  Future<void> close();
}

abstract interface class DiagnosticSinkHealth {
  Map<String, Object?> get health;
}
