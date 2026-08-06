import 'package:easy_localization/easy_localization.dart';
import 'package:easy_logger/easy_logger.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';

final class EasyLocalizationDiagnosticSource {
  EasyLocalizationDiagnosticSource._({
    required EasyLogPrinter? previousPrinter,
    required List<BuildMode> previousBuildModes,
    required List<LevelMessages> previousLevels,
  }) : _previousPrinter = previousPrinter,
       _previousBuildModes = previousBuildModes,
       _previousLevels = previousLevels;

  final EasyLogPrinter? _previousPrinter;
  final List<BuildMode> _previousBuildModes;
  final List<LevelMessages> _previousLevels;
  bool _disposed = false;

  static EasyLocalizationDiagnosticSource install(
    DiagnosticsRuntime diagnostics,
  ) {
    final packageLogger = EasyLocalization.logger;
    final registration = EasyLocalizationDiagnosticSource._(
      previousPrinter: packageLogger.printer,
      previousBuildModes: List.of(packageLogger.enableBuildModes),
      previousLevels: List.of(packageLogger.enableLevels),
    );
    final log = diagnostics.logger(DiagnosticModules.localization);

    packageLogger
      ..enableBuildModes = List.of(BuildMode.values)
      ..enableLevels = List.of(LevelMessages.values)
      ..printer = (
        Object detail, {
        String? name,
        LevelMessages? level,
        StackTrace? stackTrace,
      }) {
        final fields = <String, Object?>{
          'package': 'easy_localization',
          'detail': detail.toString(),
        };
        switch (level) {
          case LevelMessages.debug:
            log.debug(
              'localization.package.debug',
              'Localization package debug event',
              fields: fields,
            );
          case LevelMessages.info:
            log.info(
              'localization.package.info',
              'Localization package information',
              fields: fields,
            );
          case LevelMessages.error:
            log.error(
              'localization.package.error',
              'Localization package reported an error',
              fields: fields,
              stackTrace: stackTrace,
            );
          case LevelMessages.warning || null:
            log.warning(
              'localization.package.warning',
              'Localization package reported a warning',
              fields: fields,
              stackTrace: stackTrace,
            );
        }
      };

    return registration;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    EasyLocalization.logger
      ..printer = _previousPrinter
      ..enableBuildModes = List.of(_previousBuildModes)
      ..enableLevels = List.of(_previousLevels);
  }
}
