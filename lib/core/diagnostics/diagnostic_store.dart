import 'package:flutter/foundation.dart';
import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/sinks/diagnostic_sink.dart';

final class DiagnosticStore extends ValueNotifier<List<DiagnosticRecord>>
    implements DiagnosticSink {
  DiagnosticStore({this.capacity = 1000}) : super(const []);

  final int capacity;

  int get errorCount => value.where((record) => record.isError).length;

  @override
  DiagnosticDestination get destination => DiagnosticDestination.memory;

  @override
  void add(DiagnosticRecord record) {
    final next = <DiagnosticRecord>[...value, record];
    if (next.length > capacity) {
      next.removeRange(0, next.length - capacity);
    }
    value = List.unmodifiable(next);
  }

  void clear() {
    value = const [];
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {
    dispose();
  }
}
