import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/log_severity.dart';

const _defaultDiagnosticLevels = <String, LogSeverity>{
  DiagnosticModules.connection: LogSeverity.trace,
  DiagnosticModules.vpn: LogSeverity.trace,
  DiagnosticModules.easyTier: LogSeverity.debug,
  DiagnosticModules.easyTierTunnel: LogSeverity.warning,
};

enum DiagnosticLaunchPreset { production, debug, diagnostic }

final class DiagnosticLaunchOptions {
  DiagnosticLaunchOptions._({
    required this.preset,
    required this.moduleLevels,
    required this.diagnosticDuration,
    required this.invalidOptionCount,
  });

  factory DiagnosticLaunchOptions.parse(List<String> arguments) {
    DiagnosticLaunchPreset? preset;
    var diagnosticDuration = const Duration(minutes: 15);
    var invalidOptionCount = 0;
    final moduleLevels = <String, LogSeverity?>{};

    for (final argument in arguments) {
      if (argument.startsWith('--log-preset=')) {
        final value = argument.substring('--log-preset='.length);
        final parsed =
            DiagnosticLaunchPreset.values
                .where((candidate) => candidate.name == value)
                .firstOrNull;
        if (parsed == null) {
          invalidOptionCount++;
        } else {
          preset = parsed;
        }
        continue;
      }
      if (argument.startsWith('--log-module=')) {
        final value = argument.substring('--log-module='.length);
        final separator = value.lastIndexOf('=');
        if (separator <= 0 || separator == value.length - 1) {
          invalidOptionCount++;
          continue;
        }
        final module = value.substring(0, separator);
        final level = _parseLevel(value.substring(separator + 1));
        if (!_validModule(module) || level == _invalidLevel) {
          invalidOptionCount++;
          continue;
        }
        moduleLevels[module] = level as LogSeverity?;
        continue;
      }
      if (argument.startsWith('--log-duration=')) {
        final parsed = _parseDuration(
          argument.substring('--log-duration='.length),
        );
        if (parsed == null) {
          invalidOptionCount++;
        } else {
          diagnosticDuration = parsed;
        }
        continue;
      }
      if (argument.startsWith('--log-')) invalidOptionCount++;
    }

    return DiagnosticLaunchOptions._(
      preset: preset,
      moduleLevels: Map.unmodifiable(moduleLevels),
      diagnosticDuration: diagnosticDuration,
      invalidOptionCount: invalidOptionCount,
    );
  }

  final DiagnosticLaunchPreset? preset;
  final Map<String, LogSeverity?> moduleLevels;
  final Duration diagnosticDuration;
  final int invalidOptionCount;

  bool get startsDiagnosticSession =>
      preset == DiagnosticLaunchPreset.diagnostic;

  LogPolicy initialPolicy({required bool debugBuild}) {
    final selected = switch (preset) {
      DiagnosticLaunchPreset.production => LogPolicy.productionDefaults(),
      DiagnosticLaunchPreset.debug ||
      DiagnosticLaunchPreset.diagnostic => LogPolicy.debugDefaults(),
      null =>
        debugBuild ? LogPolicy.debugDefaults() : LogPolicy.productionDefaults(),
    };
    var policy = selected.withName(
      preset == null ? selected.name : 'launch-${preset!.name}',
    );
    for (final entry in moduleLevels.entries) {
      policy = policy.withModuleLevel(entry.key, entry.value);
    }
    return policy;
  }

  void applyTo(DiagnosticsRuntime diagnostics) {
    if (startsDiagnosticSession) {
      diagnostics.policy.startDiagnosticSession(
        duration: diagnosticDuration,
        moduleLevels: {..._defaultDiagnosticLevels, ...moduleLevels},
      );
    }
    if (invalidOptionCount > 0) {
      diagnostics
          .logger(DiagnosticModules.logging)
          .warning(
            'launch-options.invalid',
            'Invalid diagnostic launch options were ignored',
            fields: {'invalid_option_count': invalidOptionCount},
          );
    }
  }

  Map<String, Object?> get safeSummary => {
    'launch_preset': preset?.name ?? 'default',
    'module_override_count': moduleLevels.length,
    if (startsDiagnosticSession)
      'diagnostic_duration_seconds': diagnosticDuration.inSeconds,
    if (invalidOptionCount > 0) 'invalid_option_count': invalidOptionCount,
  };

  static const Object _invalidLevel = Object();

  static Object? _parseLevel(String value) => switch (value) {
    'off' => null,
    'trace' => LogSeverity.trace,
    'debug' => LogSeverity.debug,
    'info' => LogSeverity.info,
    'warning' || 'warn' => LogSeverity.warning,
    'error' => LogSeverity.error,
    'fatal' => LogSeverity.fatal,
    _ => _invalidLevel,
  };

  static bool _validModule(String value) =>
      value == DiagnosticModules.root ||
      (value.startsWith('${DiagnosticModules.root}.') &&
          RegExp(r'^[a-z0-9.-]+$').hasMatch(value));

  static Duration? _parseDuration(String value) {
    final match = RegExp(r'^(\d+)(s|m)$').firstMatch(value);
    if (match == null) return null;
    final amount = int.tryParse(match.group(1)!);
    if (amount == null) return null;
    final duration =
        match.group(2) == 'm'
            ? Duration(minutes: amount)
            : Duration(seconds: amount);
    if (duration < const Duration(seconds: 30) ||
        duration > const Duration(hours: 1)) {
      return null;
    }
    return duration;
  }
}
