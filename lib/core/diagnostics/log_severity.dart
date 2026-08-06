import 'package:logging/logging.dart';

enum LogSeverity { trace, debug, info, warning, error, fatal }

extension LogSeverityMapping on LogSeverity {
  Level get loggingLevel => switch (this) {
    LogSeverity.trace => Level.FINEST,
    LogSeverity.debug => Level.FINE,
    LogSeverity.info => Level.INFO,
    LogSeverity.warning => Level.WARNING,
    LogSeverity.error => Level.SEVERE,
    LogSeverity.fatal => Level.SHOUT,
  };

  String get token => switch (this) {
    LogSeverity.trace => 'TRC',
    LogSeverity.debug => 'DBG',
    LogSeverity.info => 'INF',
    LogSeverity.warning => 'WRN',
    LogSeverity.error => 'ERR',
    LogSeverity.fatal => 'FTL',
  };

  int get developerLevel => loggingLevel.value;

  static LogSeverity fromLogging(Level level) {
    if (level >= Level.SHOUT) return LogSeverity.fatal;
    if (level >= Level.SEVERE) return LogSeverity.error;
    if (level >= Level.WARNING) return LogSeverity.warning;
    if (level >= Level.INFO) return LogSeverity.info;
    if (level >= Level.FINE) return LogSeverity.debug;
    return LogSeverity.trace;
  }
}
