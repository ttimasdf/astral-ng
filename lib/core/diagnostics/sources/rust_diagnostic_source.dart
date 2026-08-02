import 'dart:async';

import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/module_logger.dart';
import 'package:astral/src/rust/api/diagnostics.dart';

final class RustDiagnosticSource {
  RustDiagnosticSource(this.diagnostics)
    : _log = diagnostics.logger(DiagnosticModules.logging);

  final DiagnosticsRuntime diagnostics;
  final ModuleLogger _log;
  StreamSubscription<RustDiagnosticBatch>? _subscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    final filter = _buildFilter(diagnostics.policy.value);
    await initializeRustDiagnostics(filter: filter);
    _subscription = createRustDiagnosticStream().listen(
      _ingest,
      onError: (Object error, StackTrace stack) {
        _log.warning(
          'rust.bridge.failed',
          'Rust diagnostic bridge failed; native console remains active',
          error: error,
          stackTrace: stack,
        );
      },
      onDone: () {
        _log.warning(
          'rust.bridge.closed',
          'Rust diagnostic bridge closed; native console remains active',
        );
      },
    );
    diagnostics.policy.addListener(_policyChanged);
    _started = true;
    _log.info(
      'rust.bridge.ready',
      'Rust diagnostic bridge attached',
      fields: {'filter': filter},
    );
  }

  void _ingest(RustDiagnosticBatch batch) {
    for (final event in batch.events) {
      _ingestEvent(event);
    }
  }

  void _ingestEvent(RustDiagnosticEvent event) {
    diagnostics.ingestExternal(
      sourceTimestampUtc: DateTime.fromMillisecondsSinceEpoch(
        event.timestampMillis,
        isUtc: true,
      ),
      sourceSequence: event.sourceSequence.toInt(),
      origin: 'rust',
      module: event.module,
      rawTarget: event.rawTarget,
      level: _parseLevel(event.level),
      eventCode: event.eventCode,
      message: event.message,
      fields: event.fields,
      consoleAlreadyReported: event.consoleAlreadyReported,
    );
  }

  void _policyChanged() {
    unawaited(_applyPolicy());
  }

  Future<void> _applyPolicy() async {
    final filter = _buildFilter(diagnostics.policy.value);
    try {
      await setRustDiagnosticFilter(filter: filter);
      _log.info(
        'rust.filter.changed',
        'Rust diagnostic filter changed',
        fields: {'filter': filter},
      );
    } catch (error, stack) {
      _log.warning(
        'rust.filter.failed',
        'Failed to update Rust diagnostic filter',
        error: error,
        stackTrace: stack,
      );
    }
  }

  String _buildFilter(LogPolicy policy) {
    final directives = <String>[
      'warn',
      'rust_lib_astral=${_sourceLevel(policy, DiagnosticModules.root)}',
      'CORE=${_sourceLevel(policy, DiagnosticModules.easyTier)}',
      'easytier=${_sourceLevel(policy, DiagnosticModules.easyTier)}',
      'easytier::tunnel=${_sourceLevel(policy, DiagnosticModules.easyTierTunnel)}',
      'astral.bootstrap=${_sourceLevel(policy, DiagnosticModules.bootstrap)}',
      'astral.easytier=${_sourceLevel(policy, DiagnosticModules.easyTier)}',
      'astral.easytier.instance=${_sourceLevel(policy, DiagnosticModules.easyTierInstance)}',
      'astral.easytier.peer=${_sourceLevel(policy, DiagnosticModules.easyTierPeer)}',
      'astral.easytier.connection=${_sourceLevel(policy, DiagnosticModules.easyTierConnection)}',
    ];
    return directives.join(',');
  }

  String _sourceLevel(LogPolicy policy, String module) {
    LogSeverity? minimum;
    for (final destination in DiagnosticDestination.values) {
      final candidate = policy.minimumLevel(module, destination);
      if (candidate != null &&
          (minimum == null || candidate.index < minimum.index)) {
        minimum = candidate;
      }
    }
    return switch (minimum) {
      null => 'off',
      LogSeverity.trace => 'trace',
      LogSeverity.debug => 'debug',
      LogSeverity.info => 'info',
      LogSeverity.warning => 'warn',
      LogSeverity.error || LogSeverity.fatal => 'error',
    };
  }

  LogSeverity _parseLevel(String level) => switch (level.toLowerCase()) {
    'trace' => LogSeverity.trace,
    'debug' => LogSeverity.debug,
    'warn' || 'warning' => LogSeverity.warning,
    'error' => LogSeverity.error,
    'fatal' => LogSeverity.fatal,
    _ => LogSeverity.info,
  };

  Future<void> close() async {
    if (!_started) return;
    diagnostics.policy.removeListener(_policyChanged);
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
