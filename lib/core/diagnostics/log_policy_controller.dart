import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/log_severity.dart';

final class LogPolicyController extends ValueNotifier<LogPolicy> {
  LogPolicyController(super.value) : _baseline = value;

  LogPolicy _baseline;
  Timer? _diagnosticTimer;
  DateTime? _diagnosticExpiresAt;

  DateTime? get diagnosticExpiresAt => _diagnosticExpiresAt;
  bool get isDiagnosticSession => _diagnosticTimer != null;

  void replace(LogPolicy policy, {bool updateBaseline = true}) {
    _diagnosticTimer?.cancel();
    _diagnosticTimer = null;
    _diagnosticExpiresAt = null;
    if (updateBaseline) _baseline = policy;
    value = policy;
  }

  void setModuleLevel(String module, LogSeverity? level) {
    replace(value.withModuleLevel(module, level));
  }

  void startDiagnosticSession({
    required Map<String, LogSeverity?> moduleLevels,
    Duration duration = const Duration(minutes: 15),
  }) {
    _diagnosticTimer?.cancel();
    var diagnostic = _baseline.withName('diagnostic');
    for (final entry in moduleLevels.entries) {
      diagnostic = diagnostic.withModuleLevel(entry.key, entry.value);
    }
    _diagnosticExpiresAt = DateTime.now().add(duration);
    value = diagnostic;
    _diagnosticTimer = Timer(duration, stopDiagnosticSession);
    notifyListeners();
  }

  void stopDiagnosticSession() {
    _diagnosticTimer?.cancel();
    _diagnosticTimer = null;
    _diagnosticExpiresAt = null;
    value = _baseline;
  }

  @override
  void dispose() {
    _diagnosticTimer?.cancel();
    super.dispose();
  }
}
