# Troubleshooting guide

Use the topic that matches the failure. Start with the correlated diagnostics
workflow, then move to host or network tools when the question is outside the
application control plane.

- [Diagnostics workflow](diagnostics.md): Settings → Logs, correlation IDs,
  support bundles, and pre-start flags.
- [Platform consoles](platform-console.md): desktop console, Android `logcat`,
  and Flutter DevTools.
- [Packet capture](network-capture.md): bounded `tcpdump` and Wireshark
  investigations without adding packet logs to Astral.
- [Routing, TUN, and VPN state](routing-vpn.md): Linux, Windows, macOS, and
  Android commands and failure distinctions.
- [EasyTier state and topology](easytier.md): bounded state snapshots and
  control-plane isolation.
- [Flutter performance and memory](flutter-performance.md): timeline, CPU,
  memory, and network profiling.
- [Failure isolation](failure-isolation.md): controlled dependency failures and
  expected observability behavior.

The [project-wide diagnostics catalog](../DIAGNOSTIC_CATALOG.md) lists modules,
event codes, native tags, and fallback source identities across Dart, Rust, and
Kotlin.

Astral diagnostics describe control-plane decisions and failures. They do not
record packets, replace a profiler, or dump the host configuration. Use the
narrowest tool that answers the question, and review every support bundle or
packet capture before sharing it.
