import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/sinks/diagnostic_sink.dart';

final class RotatingJsonlSink implements DiagnosticSink {
  RotatingJsonlSink._({
    required Directory directory,
    required this.maxBytes,
    required this.retainedFiles,
    required this.maxQueueRecords,
  }) : _directory = directory,
       _currentFile = File(p.join(directory.path, 'astral.jsonl'));

  static Future<RotatingJsonlSink> open({
    Directory? directory,
    int maxBytes = 2 * 1024 * 1024,
    int retainedFiles = 2,
    int maxQueueRecords = 2000,
  }) async {
    final resolvedDirectory =
        directory ??
        Directory(
          p.join((await getApplicationSupportDirectory()).path, 'logs'),
        );
    await resolvedDirectory.create(recursive: true);
    final sink = RotatingJsonlSink._(
      directory: resolvedDirectory,
      maxBytes: maxBytes,
      retainedFiles: retainedFiles,
      maxQueueRecords: maxQueueRecords,
    );
    await sink._initialize();
    return sink;
  }

  final Directory _directory;
  final int maxBytes;
  final int retainedFiles;
  final int maxQueueRecords;
  final Queue<_QueuedLine> _queue = Queue();
  File _currentFile;
  IOSink? _output;
  Future<void>? _drainFuture;
  Timer? _flushTimer;
  int _currentBytes = 0;
  int _droppedRecords = 0;
  bool _closed = false;
  bool _healthy = true;

  bool get isHealthy => _healthy;
  int get droppedRecords => _droppedRecords;
  String get directoryPath => _directory.path;

  @override
  DiagnosticDestination get destination => DiagnosticDestination.file;

  Future<void> _initialize() async {
    await _removeExpiredFiles();
    if (await _currentFile.exists()) {
      _currentBytes = await _currentFile.length();
    }
    _output = _currentFile.openWrite(mode: FileMode.append);
    _flushTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(flush()),
    );
  }

  @override
  void add(DiagnosticRecord record) {
    if (_closed || !_healthy) return;
    final line = '${jsonEncode(record.toJson())}\n';
    final queued = _QueuedLine(
      line: line,
      bytes: utf8.encode(line).length,
      severity: record.level,
    );
    if (_queue.length >= maxQueueRecords) {
      if (record.level.index < LogSeverity.warning.index) {
        _droppedRecords++;
        return;
      }
      final lowPriority = _queue.cast<_QueuedLine?>().firstWhere(
        (item) => item!.severity.index < LogSeverity.warning.index,
        orElse: () => null,
      );
      if (lowPriority != null) {
        _queue.remove(lowPriority);
      } else {
        _queue.removeFirst();
      }
      _droppedRecords++;
    }
    _queue.addLast(queued);
    _scheduleDrain();
  }

  void _scheduleDrain() {
    if (_drainFuture != null || _closed || !_healthy) return;
    final future = _drain();
    _drainFuture = future;
    unawaited(
      future
          .then<void>(
            (_) {},
            onError: (Object error, StackTrace stack) {
              _healthy = false;
              _queue.clear();
              developer.log(
                'Rotating diagnostic file sink failed: $error',
                name: DiagnosticModules.logging,
                level: 1000,
                error: error,
                stackTrace: stack,
              );
            },
          )
          .whenComplete(() {
            _drainFuture = null;
            if (_queue.isNotEmpty) _scheduleDrain();
          }),
    );
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty && !_closed) {
      final queued = _queue.removeFirst();
      if (_currentBytes > 0 && _currentBytes + queued.bytes > maxBytes) {
        await _rotate();
      }
      _output!.add(utf8.encode(queued.line));
      _currentBytes += queued.bytes;
    }
    await _output?.flush().timeout(const Duration(seconds: 2));
  }

  Future<void> _rotate() async {
    await _output?.flush().timeout(const Duration(seconds: 2));
    await _output?.close().timeout(const Duration(seconds: 2));

    final oldest = File('${_currentFile.path}.$retainedFiles');
    if (await oldest.exists()) await oldest.delete();
    for (var index = retainedFiles - 1; index >= 1; index--) {
      final source = File('${_currentFile.path}.$index');
      if (await source.exists()) {
        await source.rename('${_currentFile.path}.${index + 1}');
      }
    }
    if (retainedFiles > 0 && await _currentFile.exists()) {
      await _currentFile.rename('${_currentFile.path}.1');
    } else if (await _currentFile.exists()) {
      await _currentFile.delete();
    }

    _currentFile = File(p.join(_directory.path, 'astral.jsonl'));
    _output = _currentFile.openWrite(mode: FileMode.append);
    _currentBytes = 0;
  }

  Future<void> _removeExpiredFiles() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    await for (final entity in _directory.list()) {
      if (entity is! File ||
          !p.basename(entity.path).startsWith('astral.jsonl')) {
        continue;
      }
      if ((await entity.lastModified()).isBefore(cutoff)) {
        await entity.delete();
      }
    }
  }

  @override
  Future<void> flush() async {
    if (_closed || !_healthy) return;
    _scheduleDrain();
    await _drainFuture;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _flushTimer?.cancel();
    await flush();
    _closed = true;
    await _output?.flush().timeout(const Duration(seconds: 2));
    await _output?.close().timeout(const Duration(seconds: 2));
  }
}

final class _QueuedLine {
  const _QueuedLine({
    required this.line,
    required this.bytes,
    required this.severity,
  });

  final String line;
  final int bytes;
  final LogSeverity severity;
}
