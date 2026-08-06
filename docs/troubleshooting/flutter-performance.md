# Flutter performance and memory

Logs retain milestone durations; detailed performance belongs in Flutter
DevTools.

- **Performance**: record a timeline while reproducing startup or UI jank.
  Bootstrap stages and connection attempts appear as timeline tasks.
- **CPU Profiler**: identify expensive Dart stacks instead of adding loop logs.
- **Memory**: compare snapshots and use allocation tracing for suspected growth.
- **Network**: use it for Dart HTTP traffic such as update checks; it does not
  replace TUN packet capture.

Run in profile mode when measuring representative performance. Debug-mode
assertions and instrumentation distort timings.

For startup/connection logs, use the same `operationId` or
`connectionAttemptId` to line up DevTools timeline tasks with Settings → Logs.
Do not increase high-frequency loop logging to diagnose a performance problem;
use a bounded trace policy for the owning module and the profiler instead.
