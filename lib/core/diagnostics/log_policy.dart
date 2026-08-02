import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';

const Object _inheritThreshold = Object();

enum DiagnosticDestination { console, memory, file }

final class ModuleThresholds {
  const ModuleThresholds({
    this.console = _inheritThreshold,
    this.memory = _inheritThreshold,
    this.file = _inheritThreshold,
  });

  final Object? console;
  final Object? memory;
  final Object? file;

  LogSeverity? resolve(
    DiagnosticDestination destination,
    LogSeverity? inherited,
  ) {
    final value = switch (destination) {
      DiagnosticDestination.console => console,
      DiagnosticDestination.memory => memory,
      DiagnosticDestination.file => file,
    };
    if (identical(value, _inheritThreshold)) return inherited;
    return value as LogSeverity?;
  }
}

final class LogPolicy {
  LogPolicy({
    required Map<String, ModuleThresholds> modules,
    required this.name,
  }) : modules = Map.unmodifiable(modules) {
    if (!this.modules.containsKey(DiagnosticModules.root)) {
      throw ArgumentError('A policy must configure ${DiagnosticModules.root}');
    }
  }

  factory LogPolicy.debugDefaults() => LogPolicy(
    name: 'debug',
    modules: const {
      DiagnosticModules.root: ModuleThresholds(
        console: LogSeverity.debug,
        memory: LogSeverity.debug,
        file: LogSeverity.info,
      ),
      DiagnosticModules.easyTier: ModuleThresholds(
        console: LogSeverity.info,
        memory: LogSeverity.info,
        file: LogSeverity.info,
      ),
      DiagnosticModules.easyTierTunnel: ModuleThresholds(
        console: LogSeverity.warning,
        memory: LogSeverity.warning,
        file: LogSeverity.warning,
      ),
    },
  );

  factory LogPolicy.productionDefaults() => LogPolicy(
    name: 'production',
    modules: const {
      DiagnosticModules.root: ModuleThresholds(
        console: LogSeverity.info,
        memory: LogSeverity.info,
        file: LogSeverity.warning,
      ),
      DiagnosticModules.easyTier: ModuleThresholds(
        console: LogSeverity.warning,
        memory: LogSeverity.warning,
        file: LogSeverity.warning,
      ),
      DiagnosticModules.easyTierTunnel: ModuleThresholds(
        console: null,
        memory: null,
        file: null,
      ),
    },
  );

  final String name;
  final Map<String, ModuleThresholds> modules;

  LogSeverity? minimumLevel(String module, DiagnosticDestination destination) {
    LogSeverity? effective;
    for (final name in _ancestors(module)) {
      final configured = modules[name];
      if (configured != null) {
        effective = configured.resolve(destination, effective);
      }
    }
    return effective;
  }

  bool allows(
    String module,
    LogSeverity level,
    DiagnosticDestination destination,
  ) {
    if (level.index >= LogSeverity.error.index &&
        destination != DiagnosticDestination.file) {
      return true;
    }
    final minimum = minimumLevel(module, destination);
    return minimum != null && level.index >= minimum.index;
  }

  bool allowsAny(String module, LogSeverity level) => DiagnosticDestination
      .values
      .any((destination) => allows(module, level, destination));

  Iterable<String> _ancestors(String module) sync* {
    final parts = module.split('.');
    for (var index = 1; index <= parts.length; index++) {
      yield parts.take(index).join('.');
    }
  }
}
