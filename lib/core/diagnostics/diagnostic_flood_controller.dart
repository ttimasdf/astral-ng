import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/log_severity.dart';

final class DiagnosticFloodController {
  DiagnosticFloodController({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const duplicateWindow = Duration(seconds: 1);
  static const summaryWindow = Duration(seconds: 2);
  static const _tokenCapacity = 200.0;
  static const _tokensPerSecond = 100.0;

  final DateTime Function() _clock;
  final Map<String, _TokenBucket> _buckets = {};
  final Map<String, DateTime> _duplicates = {};
  final Map<String, _Suppression> _suppressions = {};

  bool get hasPendingSummaries => _suppressions.isNotEmpty;

  bool accepts(DiagnosticRecord record) {
    final now = _clock();
    _pruneDuplicates(now);

    final fingerprint = _fingerprint(record);
    final previous = _duplicates[fingerprint];
    _duplicates[fingerprint] = now;
    if (previous != null && now.difference(previous) <= duplicateWindow) {
      _suppress(record.module, 'duplicate', now);
      return false;
    }

    if (record.level.index <= LogSeverity.info.index) {
      final bucket = _buckets.putIfAbsent(
        record.module,
        () => _TokenBucket(now, _tokenCapacity),
      );
      if (!bucket.take(now)) {
        _suppress(record.module, 'rate_limit', now);
        return false;
      }
    }

    return true;
  }

  List<DiagnosticSuppressionSummary> drain({bool force = false}) {
    final now = _clock();
    final ready = <DiagnosticSuppressionSummary>[];
    final keys = <String>[];
    for (final entry in _suppressions.entries) {
      final suppression = entry.value;
      if (!force && now.difference(suppression.lastAt) < summaryWindow) {
        continue;
      }
      ready.add(
        DiagnosticSuppressionSummary(
          module: suppression.module,
          reason: suppression.reason,
          count: suppression.count,
          window: suppression.lastAt.difference(suppression.firstAt),
        ),
      );
      keys.add(entry.key);
    }
    for (final key in keys) {
      _suppressions.remove(key);
    }
    return ready;
  }

  void _suppress(String module, String reason, DateTime now) {
    final key = '$module\u0000$reason';
    final current = _suppressions[key];
    if (current == null) {
      _suppressions[key] = _Suppression(
        module: module,
        reason: reason,
        firstAt: now,
        lastAt: now,
      );
      return;
    }
    current.count = current.count + 1;
    current.lastAt = now;
  }

  void _pruneDuplicates(DateTime now) {
    _duplicates.removeWhere(
      (_, timestamp) => now.difference(timestamp) > duplicateWindow,
    );
  }

  String _fingerprint(DiagnosticRecord record) {
    final topFrame = record.stackTrace?.split('\n').first ?? '';
    return '${record.module}\u0000${record.eventCode}\u0000'
        '${record.errorType ?? ''}\u0000$topFrame';
  }
}

final class DiagnosticSuppressionSummary {
  const DiagnosticSuppressionSummary({
    required this.module,
    required this.reason,
    required this.count,
    required this.window,
  });

  final String module;
  final String reason;
  final int count;
  final Duration window;
}

final class _Suppression {
  _Suppression({
    required this.module,
    required this.reason,
    required this.firstAt,
    required this.lastAt,
  });

  final String module;
  final String reason;
  final DateTime firstAt;
  DateTime lastAt;
  int count = 1;
}

final class _TokenBucket {
  _TokenBucket(this.lastRefill, this.tokens);

  DateTime lastRefill;
  double tokens;

  bool take(DateTime now) {
    final elapsedMicros = now.difference(lastRefill).inMicroseconds;
    if (elapsedMicros > 0) {
      tokens =
          (tokens +
                  elapsedMicros /
                      1000000 *
                      DiagnosticFloodController._tokensPerSecond)
              .clamp(0, DiagnosticFloodController._tokenCapacity)
              .toDouble();
      lastRefill = now;
    }
    if (tokens < 1) return false;
    tokens--;
    return true;
  }
}
