import 'package:astral/core/app_links/definitions/app_link_definitions.dart';
import 'package:astral/core/diagnostics/diagnostic_context.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/app_links/handlers/link_handlers.dart';
import 'package:uuid/uuid.dart';

typedef SimpleHandler = Future<void> Function(Uri uri);

class AppLinkRegistry {
  static final AppLinkRegistry _instance = AppLinkRegistry._internal();
  factory AppLinkRegistry() => _instance;
  AppLinkRegistry._internal();

  final AppLinkDefinitions _linkDefinitions = AppLinkDefinitions();
  final Map<String, SimpleHandler> _handlers = {};

  bool _isInitialized = false;

  void _registerHandler(String host, SimpleHandler handler) {
    _handlers[host] = handler;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _linkDefinitions.initialize();
    _registerDefaultHandlers();
    await _handleInitialLink();
    _registerLinkStream();

    _isInitialized = true;
  }

  void _registerDefaultHandlers() {
    _registerHandler('debug', LinkHandlers.handleDebug);
    _registerHandler('room', LinkHandlers.handleRoom);
    _registerHandler('toggle_connection', LinkHandlers.handleConnectionToggle);
  }

  Future<void> _handleInitialLink() async {
    final initialLink = await _linkDefinitions.getInitialLink();
    if (initialLink != null) {
      await _processLink(initialLink);
    }
  }

  void _registerLinkStream() {
    _linkDefinitions.linkStream.listen(
      _processLink,
      onError: (Object error, StackTrace stack) {
        Diagnostics.logger(DiagnosticModules.appLinks).warning(
          'app-links.stream.failed',
          'Application link stream failed',
          error: error,
          stackTrace: stack,
        );
      },
    );
  }

  Future<void> _processLink(Uri uri) {
    if (!_linkDefinitions.isValidAstralLink(uri)) return Future.value();

    final handler = _handlers[uri.host];
    if (handler == null) return Future.value();

    final operationId = const Uuid().v4().split('-').first.toUpperCase();
    return DiagnosticContext.run(
      DiagnosticContext(operationId: operationId),
      () => _dispatchLink(uri, handler),
    );
  }

  Future<void> _dispatchLink(Uri uri, SimpleHandler handler) async {
    final log = Diagnostics.logger(DiagnosticModules.appLinks);
    final stopwatch = Stopwatch()..start();
    log.info(
      'app-links.dispatch.start',
      'Application link dispatch started',
      fields: {'handler': uri.host},
    );
    try {
      await handler(uri);
      log.info(
        'app-links.dispatch.complete',
        'Application link dispatch completed',
        fields: {
          'handler': uri.host,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );
    } catch (error, stack) {
      log.error(
        'app-links.dispatch.failed',
        'Application link dispatch failed',
        fields: {
          'handler': uri.host,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
        error: error,
        stackTrace: stack,
      );
    }
  }
}
