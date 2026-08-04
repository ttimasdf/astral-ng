# Platform consoles and profiling

## Linux, Windows, and macOS

Run the application from the project development shell for immediate Dart and
Rust console feedback:

```sh
nix develop
flutter run -d linux
```

Use the appropriate Flutter desktop device on Windows or macOS. Flutter
DevTools receives Dart records through `dart:developer`; Rust also writes a
native fallback to process stderr. These streams are not the canonical merged
artifact. Use the ECS JSONL workflow for cross-origin ordering and filtering.

For the available modules and event codes, see the
[project-wide diagnostics catalog](../DIAGNOSTIC_CATALOG.md).

## Android

Build and run through the repository helper so the Rust Android build receives
the correct toolchain environment:

```sh
nix develop
flutter-android run -d <device-id>
```

Capture only Astral's normal native tags when possible:

```sh
adb logcat -v threadtime -s Astral AstralRust flutter
```

For service-restart investigations, first clear stale output, reproduce once,
and then save the bounded result:

```sh
adb logcat -c
adb logcat -v threadtime -s Astral AstralRust flutter > astral-logcat.txt
```

Android adds its own timestamps, process IDs, priorities, and tags. `Astral`
is the Kotlin VPN adapter tag, `AstralRust` is the Rust native tag, and Flutter
Dart output can be visible through the `flutter` tag or DevTools depending on
the runtime. No individual console is guaranteed to contain every origin. Use
the canonical JSONL retrieval workflow for agent analysis; use `logcat` for
pre-bridge, bridge-failure, and Android service investigations.

## DevTools

Use Flutter DevTools for Dart timeline and CPU/memory questions. Logs retain
milestone durations and correlation IDs, but they are not a substitute for a
profiler. See [Flutter performance and memory](flutter-performance.md).
