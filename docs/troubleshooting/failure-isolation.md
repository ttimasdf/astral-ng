# Failure isolation

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

Expected boundary behavior:

- a critical bootstrap failure produces one `bootstrap.failed` record and keeps
  the startup host visible;
- an optional initialization failure produces `<operation>.failed` and the
  application continues;
- a Rust bridge failure leaves `AstralRust` native output active;
- a file sink failure does not disable memory or console diagnostics;
- a null Android TUN descriptor is `vpn.tun.establish.failed`, not
  `vpn.permission.revoked`;
- duplicate and rate suppression produces `logging.records.suppressed` summaries
  rather than unbounded output.

Use [Diagnostics workflow](diagnostics.md) for the timeline and
[Routing, TUN, and VPN state](routing-vpn.md) for platform boundary checks.
