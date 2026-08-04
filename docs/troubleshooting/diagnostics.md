# Diagnostics workflow

## Start with a correlated timeline

1. Open **Settings → Logs**.
2. Reproduce the problem once.
3. Pause live updates.
4. Filter by `connectionAttemptId`, `operationId`, or `errorId` from the
   relevant record. A connection attempt ID follows the Dart connection flow,
   Android VPN service, and embedded EasyTier runtime.
5. Expand the owning error record for its one stored stack trace.
6. If normal levels are insufficient, open the module controls and start the
   15-minute connection diagnostic preset. Enable only the affected module.

The Logs page shows records suppressed by duplicate/rate controls and records
evicted from its bounded memory ring. The module panel shows console, memory,
and file sink health. Errors and fatal records remain visible in the emergency
console and memory even when a module is disabled.

Use **Copy support bundle** to copy redacted JSON containing the current session,
build/platform metadata, effective policy, sink health, and diagnostic records.
The sanitizer removes known credentials, room links/payloads, ANSI escapes, and
local paths, but approved network identifiers may remain. Review the bundle
before sharing it.

See the [diagnostics catalog](../DIAGNOSTIC_CATALOG.md) for event codes and
module names.

## Canonical JSONL timeline

The rotating `astral.jsonl` set is the canonical diagnostic interface for both
agents and humans. It contains ECS-compatible records from Dart, Rust/EasyTier,
and the Android VPN adapter after their bounded bridges attach. Native consoles
remain immediate/emergency fallbacks; do not merge DevTools and `logcat` output
when the JSONL artifact is available.

From the Nix development shell, validate or merge a desktop rotation set:

```sh
python3 scripts/diagnostic_jsonl.py validate <application-support>/logs
python3 scripts/diagnostic_jsonl.py merge \
  <application-support>/logs \
  --output /tmp/astral-diagnostics.jsonl
lnav /tmp/astral-diagnostics.jsonl
```

On Linux the production identity normally stores the set under
`~/.local/share/pw.rabit.astralng/logs`; the canary identity uses the adjacent
`pw.rabit.astralng.canary` directory. Pass the explicit directory instead of
assuming this location on other desktop platforms.

For a debuggable Android build, retrieve private current and rotated files in
chronological order with:

```sh
python3 scripts/diagnostic_jsonl.py pull-android \
  --package pw.rabit.astralng.canary \
  --output /tmp/astral-diagnostics.jsonl
lnav /tmp/astral-diagnostics.jsonl
```

Use `--device <adb-serial>` when more than one device is connected. Android
release storage is intentionally unavailable to `adb run-as`; use the reviewed
in-app support workflow instead. Every persisted rotation set has one Astral
schema version. An incompatible pre-ECS set is discarded on migration rather
than mixed with the new contract.

Semantic events have stable `event.code` values. Ordinary upstream traces omit
that field and expose compact provenance under `log.origin`; agents should
filter those by `log.logger`, message, and source only when a semantic event is
not available.

## Pre-start diagnostic flags

Launch overrides apply to the current process only. They are parsed before the
first diagnostic record, and invalid values fall back to safe defaults. A
`diagnostic` preset expires after 15 minutes unless a bounded duration from 30
seconds through 60 minutes is supplied.

Supported entrypoint arguments:

```text
--log-preset=production|debug|diagnostic
--log-module=<astral.module>=off|trace|debug|info|warning|error|fatal
--log-duration=<30s..3600s|1m..60m>
```

Repeat `--log-module` for multiple overrides. Explicit module overrides win over
the diagnostic preset. Packet logging remains unavailable.

For a built desktop executable:

```sh
./astral \
  --log-preset=diagnostic \
  --log-module=astral.easytier.connection=trace \
  --log-duration=15m
```

When using Flutter tooling on desktop, repeat its entrypoint-argument option:

```sh
flutter run -d linux \
  --dart-entrypoint-args=--log-preset=diagnostic \
  --dart-entrypoint-args=--log-module=astral.localization=debug \
  --dart-entrypoint-args=--log-duration=15m
```

Android accepts equivalent Activity extras only when the installed APK is
debuggable (debug/profile builds). Force-stop first so a new Flutter engine
receives the pre-start arguments:

```sh
adb shell am start -S \
  -n <application-id>/pw.rabit.astralng.MainActivity \
  --es astral.log-preset diagnostic \
  --esa astral.log-modules astral.connection=trace,astral.easytier.connection=debug \
  --es astral.log-duration 15m
```

Release builds ignore these Activity extras; use the in-app expiring diagnostic
session instead.
