import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary;
import 'package:path/path.dart' as p;
import 'package:astral/app.dart';
import 'package:astral/core/app_links/app_link_registry.dart';
import 'package:astral/core/bootstrap/startup_host.dart';
import 'package:astral/core/database/app_data.dart';
import 'package:astral/core/diagnostics/diagnostic_context.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/error/error_coordinator.dart';
import 'package:astral/core/diagnostics/error/error_hook_registration.dart';
import 'package:astral/core/diagnostics/module_logger.dart';
import 'package:astral/core/diagnostics/sinks/rotating_jsonl_sink.dart';
import 'package:astral/core/diagnostics/sources/rust_diagnostic_source.dart';
import 'package:astral/core/platform/app_info.dart';
import 'package:astral/core/platform/startup_url_scheme.dart';
import 'package:astral/core/platform/window_manager.dart';
import 'package:astral/core/services/connection_connect_guard.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/src/rust/api/utils.dart';
import 'package:astral/src/rust/frb_generated.dart';
import 'package:uuid/uuid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final diagnostics = Diagnostics.initialize();
  ErrorHookRegistration.install(ErrorCoordinator(diagnostics));
  WidgetsBinding.instance.addObserver(
    _DiagnosticsLifecycleObserver(diagnostics),
  );
  diagnostics
      .logger(DiagnosticModules.bootstrap)
      .info(
        'session.start',
        'AstralNG diagnostic session started',
        fields: {
          'session': diagnostics.sessionId,
          'build_mode': kDebugMode ? 'debug' : 'release',
          'policy': diagnostics.policy.value.name,
          'platform': defaultTargetPlatform.name,
        },
      );

  runApp(
    StartupHost(
      diagnostics: diagnostics,
      bootstrap: () => _bootstrapApp(diagnostics),
    ),
  );
}

/// Initializes the FRB dynamic library.
///
/// Desktop builds open the Cargokit library beside the running executable.
/// This prevents a stale development library on `LD_LIBRARY_PATH` or under
/// `rust/target/release` from being paired with current Dart bindings.
Future<void> _initRustLib() async {
  if (!kIsWeb) {
    final executableDirectory = File(Platform.resolvedExecutable).parent.path;
    final bundledPath = switch (Platform.operatingSystem) {
      'windows' => p.join(executableDirectory, 'rust_lib_astral.dll'),
      'linux' => p.join(executableDirectory, 'lib', 'librust_lib_astral.so'),
      'macos' => p.normalize(
        p.join(
          executableDirectory,
          '..',
          'Frameworks',
          'librust_lib_astral.dylib',
        ),
      ),
      _ => null,
    };
    if (bundledPath != null && File(bundledPath).existsSync()) {
      await RustLib.init(externalLibrary: ExternalLibrary.open(bundledPath));
      return;
    }
  }
  await RustLib.init();
}

Future<Widget> _bootstrapApp(DiagnosticsRuntime diagnostics) {
  final operationId = const Uuid().v4().split('-').first.toUpperCase();
  return DiagnosticContext.run(
    DiagnosticContext(operationId: operationId),
    () => _bootstrapAppWithinContext(diagnostics),
  );
}

Future<Widget> _bootstrapAppWithinContext(
  DiagnosticsRuntime diagnostics,
) async {
  final log = diagnostics.logger(DiagnosticModules.bootstrap);
  log.info('bootstrap.start', 'Application bootstrap started');

  await _criticalStage(log, 'rust', _initRustLib);
  await _optional(
    diagnostics.logger(DiagnosticModules.logging),
    'rust-diagnostics.initialize',
    () => RustDiagnosticSource(diagnostics).start(),
  );

  if (Platform.isMacOS) {
    final elevated = await _criticalStage(log, 'macos.elevation', checkSudo);
    if (!elevated) {
      log.warning(
        'bootstrap.macos.elevation.relaunch',
        'Current macOS process is not elevated; exiting after relaunch request',
      );
      exit(0);
    }
  }

  await _criticalStage(log, 'localization', EasyLocalization.ensureInitialized);
  await _criticalStage(log, 'database', AppDatabase().init);

  final services = ServiceManager();
  await _criticalStage(
    log,
    'services',
    () =>
        services.init(runStartupActions: false, initializePlatformHooks: false),
  );

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await _criticalStage(log, 'window', WindowManagerUtils.initializeWindow);
  }

  log.info('bootstrap.complete', 'Critical bootstrap completed');
  unawaited(_initializeOptionalServices(diagnostics, services));

  return EasyLocalization(
    supportedLocales: const [Locale('zh'), Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('zh'),
    child: const KevinApp(),
  );
}

Future<T> _criticalStage<T>(
  ModuleLogger log,
  String stage,
  Future<T> Function() action,
) async {
  final stopwatch = Stopwatch()..start();
  final timeline =
      developer.TimelineTask()
        ..start('bootstrap.$stage', arguments: {'stage': stage});
  log.debug(
    'bootstrap.stage.start',
    'Bootstrap stage started',
    fields: {'stage': stage},
  );
  try {
    final result = await action();
    log.info(
      'bootstrap.stage.complete',
      'Bootstrap stage completed',
      fields: {'stage': stage, 'duration_ms': stopwatch.elapsedMilliseconds},
    );
    return result;
  } catch (error, stack) {
    log.error(
      'bootstrap.stage.failed',
      'Bootstrap stage failed',
      fields: {'stage': stage, 'duration_ms': stopwatch.elapsedMilliseconds},
      error: error,
      stackTrace: stack,
    );
    rethrow;
  } finally {
    timeline.finish(arguments: {'duration_ms': stopwatch.elapsedMilliseconds});
  }
}

Future<void> _initializeOptionalServices(
  DiagnosticsRuntime diagnostics,
  ServiceManager services,
) async {
  await _optional(
    diagnostics.logger(DiagnosticModules.logging),
    'logging.file.initialize',
    () async => diagnostics.attachSink(await RotatingJsonlSink.open()),
  );
  if (Platform.isAndroid) {
    await _optional(
      diagnostics.logger(DiagnosticModules.vpn),
      'vpn.hooks.initialize',
      services.vpn.initAndroidHooks,
    );
  }
  await _optional(
    diagnostics.logger(DiagnosticModules.widgets),
    'widgets.initialize',
    () async => services.widgets.initialize(),
  );
  if (Platform.isAndroid) {
    await _optional(
      diagnostics.logger(DiagnosticModules.widgets),
      'widgets.sync',
      () => services.widgets.syncAll().timeout(const Duration(seconds: 5)),
    );
  }

  await _optional(
    diagnostics.logger(DiagnosticModules.bootstrap),
    'metadata.initialize',
    () => AppInfoUtil.init().timeout(const Duration(seconds: 3)),
  );
  await _optional(
    diagnostics.logger(DiagnosticModules.appLinks),
    'url-scheme.register',
    () async {
      final registered = await UrlSchemeRegistrar.registerUrlScheme().timeout(
        const Duration(seconds: 5),
      );
      if (!registered) throw StateError('URL scheme registration failed');
    },
  );
  await _optional(
    diagnostics.logger(DiagnosticModules.appLinks),
    'app-links.initialize',
    () => AppLinkRegistry().initialize().timeout(const Duration(seconds: 5)),
  );
  await _optional(
    diagnostics.logger(DiagnosticModules.connection),
    'startup-auto-connect',
    ConnectionConnectGuard.tryStartupAutoConnect,
  );
}

final class _DiagnosticsLifecycleObserver with WidgetsBindingObserver {
  _DiagnosticsLifecycleObserver(this.diagnostics);

  final DiagnosticsRuntime diagnostics;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(diagnostics.flush());
    }
  }
}

Future<void> _optional(
  ModuleLogger log,
  String operation,
  Future<void> Function() action,
) {
  final operationId = const Uuid().v4().split('-').first.toUpperCase();
  return DiagnosticContext.run(
    DiagnosticContext(operationId: operationId),
    () => _optionalWithinContext(log, operation, action),
  );
}

Future<void> _optionalWithinContext(
  ModuleLogger log,
  String operation,
  Future<void> Function() action,
) async {
  final stopwatch = Stopwatch()..start();
  final timeline =
      developer.TimelineTask()
        ..start('optional.$operation', arguments: {'operation': operation});
  try {
    await action();
    log.info(
      '$operation.complete',
      'Optional initialization completed',
      fields: {
        'operation': operation,
        'duration_ms': stopwatch.elapsedMilliseconds,
      },
    );
  } catch (error, stack) {
    log.warning(
      '$operation.failed',
      'Optional initialization failed; continuing',
      fields: {
        'operation': operation,
        'duration_ms': stopwatch.elapsedMilliseconds,
      },
      error: error,
      stackTrace: stack,
    );
  } finally {
    timeline.finish(arguments: {'duration_ms': stopwatch.elapsedMilliseconds});
  }
}
