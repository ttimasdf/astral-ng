import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:astral/core/bootstrap/bootstrap_stage_failure.dart';
import 'package:astral/core/diagnostics/diagnostic_formatter.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/error/app_failure.dart';
import 'package:astral/core/diagnostics/error/error_coordinator.dart';

final class StartupHost extends StatefulWidget {
  const StartupHost({
    required this.diagnostics,
    required this.bootstrap,
    super.key,
  });

  final DiagnosticsRuntime diagnostics;
  final Future<Widget> Function() bootstrap;

  @override
  State<StartupHost> createState() => _StartupHostState();
}

final class _StartupHostState extends State<StartupHost> {
  Widget? _readyApp;
  Object? _failure;
  StackTrace? _stackTrace;
  String? _errorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      final app = await widget.bootstrap();
      if (!mounted) return;
      setState(() => _readyApp = app);
    } catch (error, stack) {
      final stageFailure = error is BootstrapStageFailure ? error : null;
      final capturedError = stageFailure?.error ?? error;
      final capturedStack = stageFailure?.stackTrace ?? stack;
      final errorId = ErrorCoordinator(widget.diagnostics).capture(
        DiagnosticModules.bootstrap,
        AppFailure(
          eventCode: 'bootstrap.failed',
          message: 'Application bootstrap failed',
          error: capturedError,
          stackTrace: capturedStack,
          impact: FailureImpact.startupBlocked,
          fields: {
            if (stageFailure != null) ...{
              'stage': stageFailure.stage,
              'duration_ms': stageFailure.durationMilliseconds,
            },
          },
        ),
      );
      if (!mounted) return;
      setState(() {
        _failure = capturedError;
        _stackTrace = capturedStack;
        _errorId = errorId;
      });
    }
  }

  Future<void> _copyDiagnostics() async {
    final records = widget.diagnostics.store.value;
    final text = records
        .map((record) {
          final details = DiagnosticFormatter.details(record);
          return details.isEmpty
              ? DiagnosticFormatter.console(record)
              : '${DiagnosticFormatter.console(record)}\n$details';
        })
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final ready = _readyApp;
    if (ready != null) return ready;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child:
                    _failure == null
                        ? const _LoadingContent()
                        : _FailureContent(
                          error: _failure!,
                          stackTrace: _stackTrace!,
                          errorId: _errorId!,
                          onCopy: _copyDiagnostics,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hub_outlined, size: 64),
        SizedBox(height: 24),
        Text('AstralNG', style: TextStyle(fontSize: 28)),
        SizedBox(height: 24),
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Starting…'),
      ],
    );
  }
}

final class _FailureContent extends StatelessWidget {
  const _FailureContent({
    required this.error,
    required this.stackTrace,
    required this.errorId,
    required this.onCopy,
  });

  final Object error;
  final StackTrace stackTrace;
  final String errorId;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 20),
          Text(
            'AstralNG could not start',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('启动失败 · Diagnostic ID: $errorId', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(error.toString()),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Technical details'),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          stackTrace.toString(),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy),
            label: const Text('Copy diagnostics / 复制诊断信息'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Restart the application after copying diagnostics. Retry is only '
            'offered for initialization stages proven safe to repeat.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
