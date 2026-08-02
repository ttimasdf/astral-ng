# Platform consoles and profiling

## Linux, Windows, and macOS

Run the application from the project development shell so Dart and Rust native
console records remain together:

```sh
nix develop
flutter run -d linux
```

Use the appropriate Flutter desktop device on Windows or macOS. The controlled
record body has the same level, module, event code, message, and safe fields on
all desktop targets. Flutter DevTools also receives Dart records through
`dart:developer`.

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

Android adds its own timestamps, process IDs, priorities, and tags. Compare the
Astral-controlled body and correlation IDs, not host-added prefixes. `Astral`
is the Kotlin VPN adapter tag and `AstralRust` is the Rust native tag; both feed
the same structured schema when the Flutter bridge is attached.

## DevTools

Use Flutter DevTools for Dart timeline and CPU/memory questions. Logs retain
milestone durations and correlation IDs, but they are not a substitute for a
profiler. See [Flutter performance and memory](flutter-performance.md).
