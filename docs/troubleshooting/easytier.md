# EasyTier state and topology

Use Astral's room topology and network status views, backed by EasyTier's
running-info APIs, to answer questions about peers, routes, and topology. These
state APIs are preferable to enabling tunnel trace globally because they provide
a bounded snapshot rather than an event flood.

Useful distinctions:

- no peer in the topology: inspect `astral.easytier.connection` lifecycle
  records and server reachability;
- peer exists but route is absent: inspect the route/topology state and platform
  route table;
- route exists but traffic fails: use tcpdump/Wireshark at both relevant
  interfaces;
- repeated tunnel noise: keep packet internals off and temporarily enable only
  the specific EasyTier lifecycle target needed for the control-plane question.

The Rust integration maps EasyTier targets into `astral.easytier.*` modules and
retains explicit API event codes such as `easytier.connection.start`,
`easytier.tun.ready`, and `easytier.instance.configure`. See the
[project-wide diagnostics catalog](../DIAGNOSTIC_CATALOG.md) for the complete
inventory and filter examples.

Never copy complete EasyTier configuration, room passwords, message keys, or
network credentials into an issue. Room links and compressed room payloads are
redacted by Astral's diagnostics sanitizer, but the source configuration and
state views still require careful review before sharing.
