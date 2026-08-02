# AstralNG troubleshooting

Use the narrowest tool that answers the question. Astral diagnostics describe
control-plane decisions and failures; they do not record packets, replace a
profiler, or dump the host configuration.

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
The sanitizer removes known credentials, but approved network identifiers may
remain. Review the bundle before sharing it.

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

## Console diagnostics

### Linux, Windows, and macOS

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

### Android

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
Astral-controlled body and correlation IDs, not host-added prefixes.

## Packets: tcpdump and Wireshark

Astral deliberately does not log packet payloads or per-packet forwarding.
Capture packets only with the user's knowledge and only on the relevant
interface/host. Packet captures can contain private application traffic.

On Linux, identify the Astral/TUN interface and capture a bounded reproduction:

```sh
ip -brief address
ip route
sudo tcpdump -i <interface> -s 0 -w astral-repro.pcap
```

Stop the capture immediately after reproducing the issue and inspect the pcap in
Wireshark. Prefer a host/port/protocol capture filter when known.

On Windows or macOS, select the Astral/TUN interface in Wireshark. Use the route
commands below to confirm which interface should carry the traffic before
capturing.

On Android, packet capture normally requires an explicitly prepared test device
or a user-approved VPN capture application. Do not add packet capture to the
Astral application or support bundle.

## Routing, TUN, and VPN state

### Linux

```sh
ip -details address
ip route show table all
ip rule show
ss -lntup
```

### Windows PowerShell

```powershell
Get-NetAdapter
Get-NetIPConfiguration
Get-NetRoute | Sort-Object RouteMetric
Get-NetTCPConnection
```

### macOS

```sh
ifconfig
netstat -rn
route -n get default
```

### Android

```sh
adb shell ip -details address
adb shell ip route show table all
adb shell dumpsys connectivity
adb shell dumpsys package <application-id>
```

Use the `vpn.permission.*`, `vpn.tun.configuration.*`, and
`vpn.tun.establish.*` events to distinguish user authorization, invalid route
or address input, and TUN creation failure. A TUN establishment failure is not a
permission-revocation event.

## EasyTier state and topology

Use Astral's room topology and network status views, backed by EasyTier's
running-info APIs, to answer questions about peers, routes, and topology. These
state APIs are preferable to enabling tunnel trace globally because they
provide a bounded snapshot rather than an event flood.

Useful distinctions:

- no peer in the topology: inspect `easytier.connection` lifecycle records and
  server reachability;
- peer exists but route is absent: inspect the route/topology state and platform
  route table;
- route exists but traffic fails: use tcpdump/Wireshark at both relevant
  interfaces;
- repeated tunnel noise: keep packet internals off and temporarily enable only
  the specific EasyTier lifecycle target needed for the control-plane question.

Never copy complete EasyTier configuration, room passwords, message keys, or
network credentials into an issue.

## Flutter performance and memory

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

## Failure-isolation checklist

When intentionally testing observability, fail one dependency at a time:

- Rust library initialization;
- database open/migration;
- optional metadata, app-link, widget, or file-sink initialization;
- VPN permission and TUN establishment;
- EasyTier server connection;
- Rust-to-Dart diagnostic bridge.

Verify that the owning record has a stable event code, safe fields, correlation
ID where applicable, and one stack; the user surface remains available; and an
optional sink/bridge failure does not hide native console errors or stop the
network runtime.
