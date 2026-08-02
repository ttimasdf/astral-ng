import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/log_policy.dart';

abstract interface class DiagnosticSink {
  DiagnosticDestination get destination;

  void add(DiagnosticRecord record);

  Future<void> flush();

  Future<void> close();
}
