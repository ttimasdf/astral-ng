import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/platform/app_info.dart';

abstract final class SupportBundle {
  static const schemaVersion = 3;

  static String encode({
    required DiagnosticsRuntime diagnostics,
    required List<DiagnosticRecord> records,
    String? appVersion,
    String? buildNumber,
    String? platform,
    String? buildMode,
    DateTime? generatedAt,
  }) {
    final policy = diagnostics.policy.value;
    final modules = <String>{...DiagnosticModules.all, ...policy.modules.keys}
      ..remove(DiagnosticModules.root);
    final sortedModules = modules.toList()..sort();

    final bundle = <String, Object?>{
      'support_bundle_schema_version': schemaVersion,
      'generated_at_utc':
          (generatedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'notice':
          'Diagnostics are redacted, but may contain approved network '
          'identifiers. Review before sharing.',
      'session': {
        'session_id': diagnostics.sessionId,
        'app_version': appVersion ?? AppInfoUtil.getVersion(),
        'build_number': buildNumber ?? AppInfoUtil.getBuildNumber(),
        'platform': platform ?? Platform.operatingSystem,
        'build_mode': buildMode ?? (kDebugMode ? 'debug' : 'release'),
        'policy': policy.name,
      },
      'policy': {
        for (final module in sortedModules)
          module: {
            for (final destination in DiagnosticDestination.values)
              destination.name:
                  policy.minimumLevel(module, destination)?.name ?? 'off',
          },
      },
      'sink_health': diagnostics.sinkHealth,
      'record_count': records.length,
      'records': records
          .map((record) => record.toJson())
          .toList(growable: false),
    };
    return const JsonEncoder.withIndent('  ').convert(bundle);
  }
}
