import 'package:flutter/foundation.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/error/app_failure.dart';
import 'package:astral/core/diagnostics/error/error_coordinator.dart';

final class ErrorHookRegistration {
  ErrorHookRegistration._({
    required FlutterExceptionHandler? previousFlutterHandler,
    required bool Function(Object, StackTrace)? previousPlatformHandler,
  }) : _previousFlutterHandler = previousFlutterHandler,
       _previousPlatformHandler = previousPlatformHandler;

  final FlutterExceptionHandler? _previousFlutterHandler;
  final bool Function(Object, StackTrace)? _previousPlatformHandler;
  bool _disposed = false;

  static ErrorHookRegistration install(ErrorCoordinator coordinator) {
    final previousFlutterHandler = FlutterError.onError;
    final previousPlatformHandler = PlatformDispatcher.instance.onError;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      coordinator.capture(
        DiagnosticModules.logging,
        AppFailure(
          eventCode: 'flutter.framework.uncaught',
          message: 'Uncaught Flutter framework error',
          error: details.exception,
          stackTrace: details.stack ?? StackTrace.current,
          impact: FailureImpact.none,
          fields: {
            if (details.library != null) 'library': details.library,
            if (details.context != null) 'context': details.context.toString(),
          },
        ),
        consoleAlreadyReported: true,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FlutterError.presentError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'PlatformDispatcher',
          context: ErrorDescription('during an uncaught asynchronous callback'),
        ),
      );
      coordinator.capture(
        DiagnosticModules.logging,
        AppFailure(
          eventCode: 'dart.async.uncaught',
          message: 'Uncaught asynchronous error',
          error: error,
          stackTrace: stack,
          impact: FailureImpact.none,
        ),
        consoleAlreadyReported: true,
      );
      return true;
    };

    return ErrorHookRegistration._(
      previousFlutterHandler: previousFlutterHandler,
      previousPlatformHandler: previousPlatformHandler,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    FlutterError.onError = _previousFlutterHandler;
    PlatformDispatcher.instance.onError = _previousPlatformHandler;
  }
}
