# AstralNG troubleshooting

This page is the stable entry point for the troubleshooting guide. The detailed
material is split by investigation type so a platform or networking procedure
can evolve without making every other workflow harder to find.

- [Diagnostics workflow](troubleshooting/diagnostics.md): Settings → Logs,
  correlation IDs, support bundles, and pre-start flags.
- [Platform consoles](troubleshooting/platform-console.md): desktop console,
  Android `logcat`, and Flutter DevTools.
- [Packet capture](troubleshooting/network-capture.md): bounded `tcpdump` and
  Wireshark investigations.
- [Routing, TUN, and VPN state](troubleshooting/routing-vpn.md): platform route
  and VPN checks.
- [EasyTier state and topology](troubleshooting/easytier.md): bounded state
  snapshots and control-plane isolation.
- [Flutter performance and memory](troubleshooting/flutter-performance.md):
  timeline, CPU, memory, and network profiling.
- [Failure isolation](troubleshooting/failure-isolation.md): controlled
  dependency failures and expected boundary behavior.
- [Project-wide diagnostics catalog](DIAGNOSTIC_CATALOG.md): modules, event
  codes, native tags, and Rust fallback identities.

Astral diagnostics describe control-plane decisions and failures. They do not
record packets, replace a profiler, or dump the host configuration. Use the
narrowest tool that answers the question, and review every support bundle or
packet capture before sharing it.
