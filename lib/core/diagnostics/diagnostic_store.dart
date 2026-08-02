import 'package:flutter/foundation.dart';
import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/sinks/diagnostic_sink.dart';

final class DiagnosticStore extends ValueNotifier<List<DiagnosticRecord>>
    implements DiagnosticSink, DiagnosticSinkHealth {
  DiagnosticStore({this.capacity = 1000}) : super(const []);

  final int capacity;
  int _evictedRecords = 0;

  int get errorCount => value.where((record) => record.isError).length;
  int get evictedRecords => _evictedRecords;

  @override
  Map<String, Object?> get health => {
    'healthy': true,
    'records': value.length,
    'capacity': capacity,
    'evicted_records': _evictedRecords,
  };

  @override
  DiagnosticDestination get destination => DiagnosticDestination.memory;

  @override
  void add(DiagnosticRecord record) {
    final next = <DiagnosticRecord>[...value, record];
    if (next.length > capacity) {
      final overflow = next.length - capacity;
      next.removeRange(0, overflow);
      _evictedRecords += overflow;
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
