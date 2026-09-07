# Project-wide diagnostics catalog

This is the cross-language inventory of EasyTier Enmesh-controlled diagnostic modules,
event codes, and native console tags. It is intended for troubleshooting,
filter construction, and code review. Event codes are the stable query keys;
messages may change with wording or localization.

The catalog covers records emitted by the application and its EasyTier/VPN
integration. Third-party EasyTier tracing without a semantic classification
has no `event.code`; its logger, message, and source provenance remain
queryable. Update this file in the same change that adds a new user-facing
diagnostic event.

## Common record schema

Persisted records use Elastic Common Schema-compatible JSON Lines. Standard ECS
fields provide direct `lnav` detection, while the `enmesh` object carries the
versioned application extension:

| Field | Meaning |
| --- | --- |
| `@timestamp` | UTC source timestamp used to merge records |
| `log.level` | `trace`, `debug`, `info`, `warning`, `error`, or `fatal` |
| `log.logger` | Hierarchical policy/filtering module, normally beginning with `enmesh.` |
| `log.origin.*` | Compact source file, line, and function provenance when available |
| `event.code` | Optional stable semantic event identity; never a source location |
| `event.created` | UTC time EasyTier Enmesh ingested the source record |
| `event.sequence` | Source sequence, falling back to EasyTier Enmesh ingest sequence |
| `event.provider` | `dart`, `rust`, or `android` |
| `message` | Human-readable, non-secret description |
| `error.*` | Owning error ID, type, message, and one stack when available |
| `session.id` | Process diagnostic session correlation |
| `enmesh.fields` | Bounded, sanitized component-specific scalar context |
| `enmesh.operation_id` | Short-lived operation correlation when applicable |
| `enmesh.connection_attempt_id` | Connection/VPN/EasyTier attempt correlation when applicable |
| `enmesh.easytier_instance_id` | EasyTier instance correlation when applicable |
| `enmesh.ingest_sequence` | Total ordering within one process session |
| `enmesh.schema_version` | Version of the EasyTier Enmesh ECS extension |

Dart records are produced by `ModuleLogger` and normalized by
`DiagnosticsRuntime`. Rust records are produced by the EasyTier Enmesh
`tracing_subscriber` layer. Android VPN records are produced by `NativeLogger`
and forwarded through the Flutter event channel. The native adapters differ,
but the record body, levels, module policy, correlation, redaction, and flood
controls are shared.

`event.code` follows `<domain>.<entity>.<state-or-past-tense-action>`. Ordinary
upstream logs are not assigned codes derived from message wording, hashes,
files, or line numbers. Their `enmesh.classification` is
`upstream-unclassified`.

## Native console tags

| Platform/component | Native tag | Output |
| --- | --- | --- |
| Android Kotlin VPN plugin | `EasyTier Enmesh` | `NativeLogger` records from `TauriVpnService`, `VpnServicePlugin`, and the native logger itself |
| Android Rust library | `EnmeshRust` | Rust `tracing` records and Rust diagnostics emergency output |
| Desktop Rust library | process stderr | The same formatted Rust record body; no ANSI color is added |
| Dart desktop/mobile | Flutter/Dart console and `dart:developer` | Normalized EasyTier Enmesh records, subject to destination policy |

Use `adb logcat -v threadtime -s EasyTier Enmesh EnmeshRust flutter` to capture the
controlled Android streams. `adb` prefixes are platform metadata, not EasyTier Enmesh
event fields.

## Module and policy tags

These are the values accepted by `--log-module=<module>=<level>` and the in-app
module controls. A child module inherits its nearest configured parent policy.

| Module | Primary component | Typical concerns |
| --- | --- | --- |
| `enmesh` | root/default | Root policy and uncategorized Rust/Dart records |
| `enmesh.bootstrap` | Dart bootstrap | Startup stages, optional initialization, startup failures |
| `enmesh.database` | Dart database | Database initialization boundary |
| `enmesh.localization` | Dart + `easy_localization` adapter | Localization package debug/info/warning/error output |
| `enmesh.connection` | Dart connection manager | Connection attempts, retries, room network config |
| `enmesh.vpn` | Dart VPN manager | Flutter VPN lifecycle and Android bridge ingestion |
| `enmesh.vpn.android` | Kotlin Android VPN plugin | Native service, TUN, permission, and native logging events |
| `enmesh.easytier` | Rust/EasyTier | General EasyTier API and target output |
| `enmesh.easytier.instance` | Rust EasyTier instance | Instance lifecycle and configuration |
| `enmesh.easytier.peer` | Rust EasyTier peer | Peer add/remove state |
| `enmesh.easytier.connection` | Rust EasyTier connection | Connection lifecycle and server/listener state |
| `enmesh.easytier.tunnel` | Rust EasyTier tunnel | Tunnel-target records, including UDP target output |
| `enmesh.widgets` | Dart widgets/background services | Widget initialization, sync, and background work |
| `enmesh.app-links` | Dart app links and URL schemes | Deep-link dispatch, import, registration, and startup schemes |
| `enmesh.updates` | Dart update checker | Update service and metadata check failures |
| `enmesh.magic-wall` | Dart + Rust Magic Wall | Rule, filter, process, WFP, and status operations |
| `enmesh.firewall` | Dart firewall service | Firewall initialization, read, and set failures |
| `enmesh.window` | Dart desktop window integration | Window initialization boundary |
| `enmesh.logging` | Dart/Rust diagnostics infrastructure | Sinks, bridge, filters, suppression, and export |

For a focused connection investigation, these are usually the most useful
module overrides:

```text
enmesh.connection=trace
enmesh.vpn=debug
enmesh.vpn.android=debug
enmesh.easytier.connection=trace
enmesh.easytier.instance=debug
enmesh.easytier.peer=debug
enmesh.localization=debug
```

Avoid enabling `enmesh.easytier` or `enmesh.easytier.tunnel` at trace globally
for a long session. Use topology/state APIs and packet tools for packet-level
questions.

## Dart and Flutter event codes

The level shown below is the normal emission level. An error boundary may
upgrade a failure to `error` or `fatal` while retaining the same event code.
Optional initialization uses `<operation>.complete` at `info` and
`<operation>.failed` at `warning`.

### Bootstrap and application boundaries

| Event code | Normal level | Component and meaning |
| --- | --- | --- |
| `bootstrap.start` | info | Main bootstrap began |
| `bootstrap.stage.start` | debug | One critical startup stage began; `stage` field |
| `bootstrap.stage.complete` | info | One critical startup stage completed; duration field |
| `bootstrap.complete` | info | Critical bootstrap completed |
| `bootstrap.failed` | fatal | Startup is blocked; owning error ID and stack are retained |
| `bootstrap.macos.elevation.relaunch` | warning | macOS elevation/relaunch request was required |
| `launch-options.invalid` | warning | One or more pre-start diagnostic arguments were ignored |
| `session.start` | info | Process diagnostic session initialized |
| `legacy.message` | info/debug | Compatibility record for an unstructured legacy message |
| `flutter.framework.uncaught` | error | Flutter framework error hook captured an uncaught error |
| `dart.async.uncaught` | error | `PlatformDispatcher` captured an uncaught async error |
| `service.initialize.failed` | warning/error | Service manager initialization boundary failed |
| `services.hydration.degraded` | warning | Service state hydration continued in degraded mode |

### Connection and room configuration

| Event code | Normal level | Component and meaning |
| --- | --- | --- |
| `connect.start` | info | A connection attempt began |
| `connect.complete` | info | A connection attempt succeeded |
| `connect.cancelled` | info | A connection attempt was cancelled |
| `connect.failed` | warning/error | A connection attempt failed |
| `connect.vpn.failed` | error | EasyTier became ready but Android VPN setup or TUN handoff failed |
| `connect.retry.failed` | warning | One retry iteration failed; `retry` field |
| `connect.room-config.invalid` | warning | Room network configuration could not be parsed |
| `connection.attempt` | timeline label | DevTools timeline task name, not a persisted event code |
| `server.add.failed` | warning/error | Server configuration add operation failed |
| `nat-test.failed` | error | NAT test operation failed |

### VPN and Android bridge

| Event code | Normal level | Component and meaning |
| --- | --- | --- |
| `vpn.hooks.initialize.complete` | info | Android VPN hooks initialized successfully |
| `vpn.hooks.ready` | info | Android VPN diagnostic streams and policy sync are ready |
| `vpn.service.failed` | error | Kotlin VPN service reported a failure to Dart |
| `vpn.revocation.disconnect` | warning | Android revoked VPN permission and disconnect is being performed |
| `vpn.logging.configure.failed` | warning | Native Android log policy update failed |
| `vpn.native.event` | varies | Fallback code when an external native event has no code |

The concrete Kotlin-side `vpn.*` event inventory appears in the Android table
below. Dart ingests those records without renaming them.

### Logging and Rust bridge

| Event code | Normal level | Component and meaning |
| --- | --- | --- |
| `rust-diagnostics.initialize.complete` | info | Rust diagnostics source initialized |
| `rust-diagnostics.initialize.failed` | warning | Optional Rust diagnostics initialization failed |
| `rust.bridge.ready` | info | Rust stream attached to the Dart runtime |
| `rust.bridge.failed` | warning | Rust stream failed; native output remains active |
| `rust.bridge.closed` | warning | Rust stream closed; native output remains active |
| `rust.filter.changed` | info | Rust filter was reloaded |
| `rust.filter.failed` | warning | Rust filter reload failed |
| `logging.file.initialize.complete` | info | JSONL file sink attached |
| `logging.file.initialize.failed` | warning | JSONL file sink could not attach |
| `logging.records.suppressed` | warning | Duplicate, rate, bridge, or sink flood summary; inspect `reason` and `count` |
| `support-bundle.copied` | info | Redacted support bundle was copied |

The Rust side also emits `rust.diagnostics.ready`,
`rust.bridge.lock_failed`, `rust.bridge.worker_failed`, and `rust.panic`; see
the Rust inventory.

### Localization, widgets, metadata, and URL startup

| Event code | Normal level | Component and meaning |
| --- | --- | --- |
| `localization.package.debug` | debug | `easy_localization` package debug output |
| `localization.package.info` | info | `easy_localization` package information |
| `localization.package.warning` | warning | `easy_localization` package warning |
| `localization.package.error` | error | `easy_localization` package error and optional stack |
| `widgets.initialize.complete` / `.failed` | info/warning | Widget service initialization result |
| `widgets.sync.complete` / `.failed` | info/warning | Android widget synchronization result |
| `widgets.background.start` | info | Home-widget background operation began |
| `widgets.background.complete` | info | Home-widget background operation completed |
| `widgets.background.failed` | error | Home-widget background operation failed |
| `metadata.initialize.complete` / `.failed` | info/warning | App metadata initialization result |
| `url-scheme.register.complete` / `.failed` | info/warning | Desktop URL scheme registration result |
| `app-links.initialize.complete` / `.failed` | info/warning | App-link registry initialization result |
| `startup-auto-connect.complete` / `.failed` | info/warning | Startup auto-connect result |
| `app-links.dispatch.start` | info | Deep-link handler dispatch began |
| `app-links.dispatch.complete` | info | Deep-link handler dispatch completed |
| `app-links.dispatch.failed` | error | Deep-link handler failed |
| `app-links.stream.failed` | warning | Deep-link stream failed |
| `app-links.scheme.registration.failed` | warning | Windows URL scheme registration step failed |
| `room-share.decode.failed` | warning | Compressed room share payload could not be decoded |
| `room-navigation.failed` | warning | Navigation to a room failed |
| `room-import.clipboard.read.failed` | warning | Clipboard read failed during room import |
| `room-import.failed` | error | Room import operation failed |
| `room-import.network-config.apply.failed` | warning | Imported network configuration could not be applied |
| `startup.legacy-shortcut.remove.failed` | warning | Legacy Windows startup shortcut removal failed |
| `startup.registration.failed` | warning | Windows startup registration failed |
| `startup.unregistration.failed` | warning | Windows startup unregistration failed |

The optional initialization codes are generated from the operation name by the
shared `_optional` boundary. They always carry `operation` and `duration_ms`
fields and never include the original command or user configuration.

### Firewall, updates, and Magic Wall

| Event code | Normal level | Component and meaning |
| --- | --- | --- |
| `firewall.initialize.failed` | warning | Firewall service initialization failed |
| `firewall.read.failed` | warning | Firewall state read failed |
| `firewall.set.failed` | error | Firewall state update failed |
| `update.download.failed` | error | Update artifact download failed |
| `magic-wall.configuration.load.failed` | warning/error | Magic Wall configuration load failed |
| `magic-wall.event.persist.failed` | warning | Magic Wall event persistence failed |
| `magic-wall.paths.repair.failed` | warning | Magic Wall path repair failed |
| `magic-wall.process-path.resolve.failed` | warning | Process path resolution failed |
| `magic-wall.process-rule.add.failed` | warning | Process rule add failed |
| `magic-wall.process-rule.remove.failed` | warning | Process rule removal failed |
| `magic-wall.rule.add.failed` | error | Magic Wall rule add failed |
| `magic-wall.rule.remove.failed` | error | Magic Wall rule removal failed |
| `magic-wall.rule.sync.failed` | warning | Magic Wall rule synchronization failed |
| `magic-wall.status.read.failed` | warning | Magic Wall status read failed |

Magic Wall also uses the explicit Rust event codes listed below for engine,
WFP, filter, and rule state transitions.

## Kotlin Android VPN event codes

The Kotlin plugin uses module `enmesh.vpn.android`, native tag `EasyTier Enmesh`, and the
same six levels as Dart. Error records include a native type/message and stack
when a `Throwable` is available.

| Event code | Level | Source/meaning |
| --- | --- | --- |
| `vpn.logging.configured` | info | Native minimum level was applied |
| `vpn.service.restart.without_config` | warning | Android restarted the service without configuration |
| `vpn.service.create` | debug | VPN service was created |
| `vpn.service.destroy` | info | VPN service was destroyed |
| `vpn.service.failed` | error | Plugin/service callback reported a failure |
| `vpn.plugin.call.failed` | error | A Flutter method call threw in the plugin |
| `vpn.permission.revoked` | warning | Android invoked `onRevoke` |
| `vpn.revocation.disconnect` | warning | Dart is disconnecting after revocation |
| `vpn.tun.establish.start` | info | TUN establishment began |
| `vpn.tun.configuration.ready` | debug | Address/routes were validated before establish |
| `vpn.tun.configuration.invalid` | error | Address/route/TUN configuration threw |
| `vpn.tun.establish.failed` | error | `Builder.establish()` returned no descriptor |
| `vpn.tun.establish.complete` | info | TUN descriptor was established |
| `vpn.tun.teardown.start` | info | Requested TUN teardown began |
| `vpn.tun.teardown.complete` | info | Requested TUN teardown completed |
| `vpn.interface.close.failed` | warning | Existing TUN descriptor could not be closed |

A null descriptor from `VpnService.Builder.establish()` is intentionally an
establishment failure, not a permission-revocation record.

## Rust and EasyTier event codes

Rust emits through `tracing`. Explicit `event_code` fields are listed here;
ordinary EasyTier tracing output is retained without `event.code`, using its
mapped logger and compact source provenance instead.

### Diagnostics infrastructure

| Event code | Typical level | Source/meaning |
| --- | --- | --- |
| `rust.diagnostics.ready` | info | Rust subscriber initialized |
| `logging.records.suppressed` | warning | Rust-to-Dart bounded bridge dropped records |
| `rust.bridge.lock_failed` | error | Rust bridge sink lock was poisoned |
| `rust.bridge.worker_failed` | error | Rust bridge worker could not start |
| `rust.panic` | fatal | Rust panic hook emergency record |

### EasyTier instance, peer, connection, and state APIs

| Event codes | Source |
| --- | --- |
| `easytier.instance.start`, `easytier.instance.configure`, `easytier.instance.stop` | Instance lifecycle |
| `easytier.peer.add`, `easytier.peer.remove` | Peer state stream |
| `easytier.connection.add`, `easytier.connection.remove`, `easytier.connection.accept`, `easytier.connection.start`, `easytier.connection.failed` | Connection state stream and connection startup |
| `easytier.listener.add`, `easytier.listener.failed` | Listener state |
| `easytier.tun.ready`, `easytier.tun.failed` | TUN state |
| `easytier.vpn-portal.start`, `easytier.vpn-portal.client.add`, `easytier.vpn-portal.client.remove` | VPN portal state |
| `easytier.dhcp.changed`, `easytier.dhcp.conflict` | DHCP state |
| `easytier.port-forward.add` | Port forwarding state |
| `easytier.config.changed`, `easytier.proxy-cidrs.changed`, `easytier.credential.changed` | Configuration state changes |
| `easytier.events.closed`, `easytier.events.lagged` | State event stream health |

### Forwarding, multicast, and FMCS

| Event codes | Source |
| --- | --- |
| `forward.server.start`, `forward.server.stop`, `forward.servers.stop` | Forward server lifecycle |
| `multicast.sender.start`, `multicast.sender.stop`, `multicast.senders.stop` | Multicast sender lifecycle |
| `fmcs.services.start` | FMCS service startup |

These are service/control-plane events. They do not contain packet payloads or
per-packet forwarding records.

### Magic Wall Rust engine

| Event codes | Source |
| --- | --- |
| `magic-wall.engine.start`, `magic-wall.engine.stop`, `magic-wall.status.read` | Engine lifecycle/status |
| `magic-wall.wfp.session.open`, `magic-wall.wfp.session.close` | Windows Filtering Platform session |
| `magic-wall.rule.restore.failed`, `magic-wall.rule.add.existing`, `magic-wall.rule.add.disabled` | Rule restoration and add decisions |
| `magic-wall.rule.apply.start`, `magic-wall.rule.apply.complete`, `magic-wall.rule.apply.deferred`, `magic-wall.rule.apply.failed` | Rule application lifecycle |
| `magic-wall.rule.path.convert.failed` | Rule path conversion |
| `magic-wall.rule.remove.start`, `magic-wall.rule.remove.complete`, `magic-wall.rule.remove.missing` | Rule removal lifecycle |
| `magic-wall.rule.update.start`, `magic-wall.rule.update.complete` | Rule update lifecycle |
| `magic-wall.filter.remove.complete`, `magic-wall.filter.remove.failed` | Single filter removal |
| `magic-wall.filters.remove.complete`, `magic-wall.filters.rollback` | Filter group removal/rollback |
| `magic-wall.filters.tracker.missing` | Filter tracking state missing |
| `magic-wall.filter.ipv4.failed`, `magic-wall.filter.ipv6.failed` | Address-family filter failure |

### Target mapping and unclassified provenance

Rust targets are mapped into the module hierarchy as follows:

| Rust target | EasyTier Enmesh module |
| --- | --- |
| `CORE::INSTANCE::CONNECTION` | `enmesh.easytier.connection` |
| `CORE::INSTANCE` | `enmesh.easytier.instance` |
| other `CORE...` | `enmesh.easytier` |
| `easytier::tunnel::<name>` | `enmesh.easytier.tunnel.<name>` |
| other `easytier::...` | `enmesh.easytier.<...>` |
| `rust_lib_enmesh::...` | `enmesh.rust.<...>` |

When a tracing event has no explicit code, `event.code` is omitted. The compact
crate-relative path and line are stored under `log.origin.file`, and the Rust
module path is stored under `log.origin.function`. For example:

```json
{"log":{"logger":"enmesh.easytier.connection","origin":{"file":{"name":"easytier/connector/manual.rs","line":213},"function":"easytier::connector::manual"}},"enmesh":{"classification":"upstream-unclassified"}}
```

Absolute build paths and checkout hashes are never retained. Use semantic event
codes for operational filters and source provenance only for code-level
investigation within a specific build.

## Adding a new event

1. Choose a lowercase dotted code describing the state transition or boundary,
   not a user value. Keep the code stable across message wording changes.
2. Emit it through the owning component's structured logger (`ModuleLogger`,
   `tracing`, or `NativeLogger`).
3. Put IDs and bounded safe facts in fields; never put packets, credentials,
   room payloads, executable paths, raw registry commands, or Magic Wall user
   details in the message/fields.
4. Add the code to this catalog and the relevant troubleshooting topic.
5. Add a focused test when the event affects error ownership, redaction,
   correlation, filtering, or flood behavior.
