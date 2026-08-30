# Changelog

This file records notable changes to EasyTier Enmesh. User-facing entries
describe
observable outcomes; concise developer notes and links provide implementation
provenance.

## Unreleased

## [v3.0.0-rc.3] - 2026-08-30

> **Highlight:** Enmesh 3.0: a new name, calmer control — rebuilt Mission Control, a route-aware topology view, and clearer, more trustworthy diagnostic logs.
>
> **版本亮点：** Enmesh 3.0：名称焕新，掌控更从容——重塑的任务控制台、路径感知拓扑界面、更清晰可信的诊断日志。

### Added

- **Android Quick Settings.** Added a tile that shows connection state and
  connects or disconnects AstralNG with one tap. ([#10])
- **Upstream additions.**
  - **Automatic retries.** Added a configurable retry limit for failed
    connections. ([upstream-auto-retry])
  - **NO-TUN SOCKS5 access.** Added a configurable local listener for reaching
    the virtual network. ([upstream-#229])
  - **Windows UDP relay.** Added UDP broadcast forwarding on Windows.
    ([upstream-udp-relay])
  - **Tray visibility.** Added an option to hide the desktop tray icon for the
    current session. ([upstream-#74])
  - **Reduced animation.** Added a mode that lowers topology and connection
    animation updates while the window is hidden. ([upstream-topology])
- **Structured diagnostics.** Added redacted desktop and mobile logs with
  runtime controls, bounded persistence, correlation filters, and reviewable
  support-bundle exports. ([#15])
- **Troubleshooting toolkit.** Added pre-start diagnostic flags and guides for
  application, network, routing, EasyTier, module, event-code, and native-log
  investigations. ([#15])

### Changed

- **⚠ BREAKING — Package identity.** Enmesh installs as `pw.rabit.enmesh`
  (canary: `pw.rabit.enmesh.canary`). Existing installs no longer receive
  updates; uninstall the old app, install Enmesh, and set up rooms again.
- **⚠ BREAKING — Share links.** Room links and QR codes now use `enmesh://`.
  Previously shared `astral://` links stop opening; re-share rooms from
  Enmesh.
- **⚠ BREAKING — Canary artifacts.** Update artifacts are now named
  `enmesh-canary-*` and served from the rebranded update API. Existing canary
  clients see no further updates; install Enmesh manually once.
- **Rebranded to EasyTier Enmesh.** The app is now Enmesh: short names in the
  GUI, "EasyTier Enmesh" in the About hero and documentation. The stored
  Windows adapter preference resets to its default.
- **Selective beta builds.** Main-branch update-server and documentation
  changes now skip platform artifacts, with Production deployment available as
  an approved manual action.
- **⚠ BREAKING — Main artifacts.** Download scripts matching main builds must
  replace `-alpha.RUN+SHA` with `-beta.RUN+SHA`; pull-request artifacts remain
  alpha.
- **⚠ BREAKING — Android settings.** Android users must back up room and relay
  credentials, uninstall the previous APK, install 3.0.0, and restore their
  configuration after the settings schema reset. ([#12])
- **⚠ BREAKING — Data directories.** Existing installs may appear reset.
  Desktop users must move every Isar file into Application Support's `db`
  directory; other platforms must reconfigure. Old logs are not migrated. ([#15])
- **⚠ BREAKING — Artifact names.** Download automation must replace legacy
  `v3.0.0-canary.*` and `v3.0.0` suffixes with canonical SemVer names such as
  `3.0.0-alpha.CI_RUN+SHORTREF` and `3.0.0`. ([#4])
- **Selectable update channels.** Settings now offers Stable, Beta, and Alpha.
  Choosing Beta or Alpha enables automatic checks initially while leaving the
  switch under user control.
- **Update service home.** New builds use `astral-ng.rabit.pw`; its service root
  now introduces Astral-NG in English and Chinese with a source link.
- **Alpha artifact matching.** PR builds now identify the source commit instead
  of GitHub's synthetic merge commit, so successful Alpha artifacts appear in
  updates.
- **Responsive settings.** Redesigned desktop and mobile navigation, status
  descriptions, and Network & Connection controls with clearer segmented
  choices and dependency guidance. ([#12])
- **Nested app navigation.** Settings and Tools stay inside the app shell,
  Android Back unwinds nested views, and engine exit now stops the VPN service.
  ([#12])
- **Mission Control.** Redesigned Home around live session summaries and
  per-room route, connectivity, and Windows LAN controls; connected edits remain
  staged until Reconnect and apply. ([#13])
- **Network topology.** Added deterministic route-aware placement, stable emoji
  identities, solid direct paths, dashed forwarded paths, responsive layouts,
  and complete relay routes in Rooms. ([#13])
- **Mesh metrics and NAT.** Added peer counts, median latency and loss, a shared
  NAT-family palette and legend, and consistent NAT presentation across
  topology and list views. ([#13])
- **Room action rails.** Unified connected and disconnected action stacks,
  added quick link copying, retained list view, and removed duplicate room-mode
  glyphs. ([#13])
- **Relay navigation.** Renamed Server to Relay, moved it ahead of Tools, and
  made desktop rows directly editable and toggleable. ([#11], [#13])
- **Canary identity.** Canary builds now use separate names, commands, package
  identities, icons, and SemVer displays across Linux, Windows, and Android.
  ([#14])
- **AstralNG branding.** Unified visible application, widget, notification,
  installer, and Quick Settings branding across supported platforms. ([#14])
- **Mobile relay gestures.** Tap edits, right swipe toggles, and left swipe asks
  before deletion on Android and iOS. ([#11])
- **Desktop relay controls.** Replaced the switch and overflow menu with direct
  toggle and delete actions; clicking a row opens editing. ([#11])
- **Update notifications.** Update checks now use repository-managed stable and
  beta metadata, then open the trusted GitHub page instead of downloading or
  installing artifacts inside the app. ([#17])
- **Dedicated update service.** Builds use the dedicated update server by
  default, while `UPDATE_API_BASE_URL` remains an optional compile-time
  override. ([#17])
- **Production update API.** Release tags now deploy the update server through
  the protected Production environment after GitHub Release publication.
- **Npcap guidance.** Windows FakeTCP setup now links to the official Npcap
  download page. ([#17])
- **Artifact retention.** Canary artifacts remain available for 30 days;
  production and merged-PR main builds remain available for 90 days. ([#17])
- **CI artifact downloads.** Snapshot and release artifacts now download
  directly instead of arriving inside an additional ZIP wrapper. ([#5])
- **Room credential modes.** Renamed credential choices to **Simple** and
  **Advanced**, independent of network-traffic encryption. ([#3])
- **Upstream changes.**
  - **Focused Tools page.** Replaced Explore with NAT testing, port whitelists,
    and Windows Magic Wall tools. ([upstream-v2.9.9])
  - **Update mirrors.** Added selectable download mirrors and automatic mirror
    benchmarking. ([upstream-#226])
  - **Android widgets.** Improved widget themes, status refresh, and one-tap
    connection control. ([upstream-widgets])
  - **Connection prerequisites.** Connection attempts now identify a missing
    room, enabled relay, or Windows Npcap driver before starting.
    ([upstream-connect-guard])

### Fixed

- **Stable release highlights.** Stable update metadata now reads bilingual
  highlights from canonical bracketed changelog headings.
- **Android VPN readiness.** Connection now appears only after consent, TUN
  creation, and descriptor handoff; setup failures and requested disconnects
  clean up the VPN interface and service. ([#15])
- **Canary launch screen.** Android canary builds no longer remain on the white
  launch screen while resolving home-widget providers. ([#14])
- **Upstream fixes.**
  - **Android VPN routes.** Fixed route refresh when a connected peer advertises
    or changes a proxy subnet. ([upstream-#231])
  - **Room member filters.** Fixed switching between user and relay member
    types. ([upstream-#236])
  - **Windows responsiveness.** Fixed low frame rates and delayed window
    closing. ([upstream-windows-fps], [upstream-window-close])
  - **Linux package versions.** DEB and RPM packages now report the real version
    instead of `1.0.0`, allowing package managers to recognize upgrades.
    ([upstream-#237])
- **Android VPN diagnostics.** Startup now preserves the original failure and
  correlation details when VPN interface creation returns null. ([#15])
- **Alpha update discovery.** PR builds now remain discoverable when GitHub
  omits pull-request metadata from workflow-list responses.

### Removed

- **Language catalog.** Removed German, Spanish, French, Japanese, Korean, and
  Russian translations; the interface now supports English and Chinese.
  ([upstream-v2.9.9])

### Developer notes

- **Staged preview versions.** Pull-request artifacts use alpha versions,
  `main` artifacts use beta versions, and signed `-rc.N` tags publish GitHub
  prereleases with distinct update-history metadata.
- **PR preview API.** Trusted labeled PR builds deploy a Vercel preview API
  after Preview approval and compile its URL into platform artifacts.
- **Release pipeline split.** Shared platform actions use explicit Android
  debug/release modes and unified/split APK layouts.
- **Release credential isolation.** Android signing secrets are scoped to the
  protected `Production Signing` environment; update deployment remains in
  `Production`.
- **EasyTier dependency.** Pinned release `v2.6.4`; Windows obtains the Npcap SDK
  separately instead of from a vendored EasyTier tree. ([#2])
- **Version source.** `VERSION` now controls production versions and build
  numbers; CI labels non-release artifacts as canaries and validates tags.
  ([#4])
- **Tiered CI.** Pull requests run tests by default; `platform-*` labels opt
  into Linux, Windows, Android, or all platform artifacts, while main retains
  canary artifacts. ([#5], [#6])
- **Flutter toolchain.** Updated Nix development and packaging to Flutter 3.44
  for Dart 3.12 compatibility. ([nix-flutter-3.44])
- **Reproducible toolchains.** Locked nixpkgs now supplies local and CI tools,
  including the Android SDK and NDK. ([#9])
- **Android build helper.** Added `flutter-android` for canary defaults and
  isolated NDK builds on NixOS.
- **Update API project.** Added a standalone `update-server/` Vercel project and
  compile-time `UPDATE_API_BASE_URL` overrides for local and CI builds. ([#17])
- **EasyTier diagnostics.** Added the pinned CLI to the development shell for
  local no-TUN and end-to-end network investigations.

## [v2.8.1] - 2026-03-31

> **Highlight:** Android widgets put connection status on your home screen.
>
> **版本亮点：** Android 主屏幕小组件可直接显示连接状态。

### Added

- **Android home widgets.** Added small, medium, and large widgets with
  connection status and tap-to-open behavior.
- **Connection notifications.** Added a setting for persistent Android
  connection notifications.

### Fixed

- **Magic Wall startup.** Rules now synchronize before the engine starts.
- **Magic Wall cleanup.** Shutdown now removes firewall rules and clears the
  in-memory rule store.

### Developer notes

- **Upstream forward-port.** Forward-ported Android widget, notification, and
  Magic Wall changes from `v2.7.8`; an ancestry-preserving merge followed later.
  ([v2.8.1-forward-port], [v2.7.8-merge])

## [v2.8.0] - 2026-03-26

> **Highlight:** Astral became Astral-ng with its own independent identity.
>
> **版本亮点：** Astral 正式更名为 Astral-ng，并启用独立的应用标识。

### Added

- **Desktop tray control.** Added a dynamic Connect or Disconnect action to the
  tray menu.

### Changed

- **Application identity.** Rebranded application metadata and icons from
  Astral to Astral-ng.
- **Independent installation.** Changed the application ID to
  `pw.rabit.astralng`, allowing installation alongside upstream Astral.
- **Linux privileges.** The GUI no longer requires root at startup; the selected
  network mode must still have permission to create its TUN interface.
- **Android services.** Removed Google Services from the Android build.
- **Home and relays.** Removed the built-in relay blocklist and temporarily hid
  the Hitokoto card.
- **Project license.** Relicensed the fork from CC BY-NC-ND 4.0 to GPL-3.0.

### Fixed

- **EasyTier events.** Fixed crashes from `ConfigPatched` and
  `ProxyCidrsUpdated` events.
- **Idle Connect animation.** Stopped continuous idle animation that could raise
  CPU usage while the window was active.
- **Windows Npcap builds.** Fixed lookup of the Npcap `Packet.lib` library.

### Developer notes

- **Nix environment.** Added a flake, development shell, and NixOS package.
- **EasyTier source.** Replaced vendored source with a `v2.5.0` submodule; later
  Unreleased work moves to the `v2.6.4` release dependency.
- **Release automation.** Replaced platform-specific workflows with unified
  validation and packaging.

## Earlier upstream history

Astral-ng forked from upstream Astral `v2.7.3`. Releases `v2.7.3` and earlier
belong to the upstream project; consult its release and tag history for those
changes. ([upstream-v2.7.3])

[#2]: https://github.com/ttimasdf/astral-ng/pull/2
[#3]: https://github.com/ttimasdf/astral-ng/pull/3
[#4]: https://github.com/ttimasdf/astral-ng/pull/4
[#5]: https://github.com/ttimasdf/astral-ng/pull/5
[#6]: https://github.com/ttimasdf/astral-ng/pull/6
[#9]: https://github.com/ttimasdf/astral-ng/pull/9
[#10]: https://github.com/ttimasdf/astral-ng/pull/10
[#11]: https://github.com/ttimasdf/astral-ng/pull/11
[#12]: https://github.com/ttimasdf/astral-ng/pull/12
[#13]: https://github.com/ttimasdf/astral-ng/pull/13
[#14]: https://github.com/ttimasdf/astral-ng/pull/14
[#15]: https://github.com/ttimasdf/astral-ng/pull/15
[#17]: https://github.com/ttimasdf/astral-ng/pull/17
[nix-flutter-3.44]: https://github.com/ttimasdf/astral-ng/commit/b5969b66ff7e2db6e8517413ccf01b9b2a6720a2
[upstream-#74]: https://github.com/ldoubil/astral/issues/74
[upstream-#226]: https://github.com/ldoubil/astral/issues/226
[upstream-#229]: https://github.com/ldoubil/astral/issues/229
[upstream-#231]: https://github.com/ldoubil/astral/pull/231
[upstream-#236]: https://github.com/ldoubil/astral/issues/236
[upstream-#237]: https://github.com/ldoubil/astral/issues/237
[upstream-auto-retry]: https://github.com/ldoubil/astral/commit/0812b53c3b784cf26b3cad7f1b2791cbc3f6c184
[upstream-connect-guard]: https://github.com/ldoubil/astral/commit/3e30b145f4bc63d2924ee6c6d9b2198604b630f2
[upstream-topology]: https://github.com/ldoubil/astral/commit/4579cd72326e2074f4b14b3aea8c63362f02482c
[upstream-udp-relay]: https://github.com/ldoubil/astral/commit/b27b93e6a1eeffb16fb041ce0578e880be23ec03
[upstream-v2.7.3]: https://github.com/ldoubil/astral/releases/tag/v2.7.3
[upstream-v2.9.9]: https://github.com/ldoubil/astral/releases/tag/v2.9.9
[upstream-widgets]: https://github.com/ldoubil/astral/commit/b43ad374ca6b40ef481727777a1e05219e53c1e7
[upstream-window-close]: https://github.com/ldoubil/astral/commit/e6f42be69152a24f16cd47fd36cb1a32c394e1d3
[upstream-windows-fps]: https://github.com/ldoubil/astral/commit/eb08c820630e7d14e1611e36e4017e0986fe3ec8
[v2.7.8-merge]: https://github.com/ttimasdf/astral-ng/commit/27a4d3e7f7585dea3423c0b2ea64b5b37ada63bf
[v2.8.0]: https://github.com/ttimasdf/astral-ng/releases/tag/v2.8.0
[v2.8.1]: https://github.com/ttimasdf/astral-ng/releases/tag/v2.8.1
[v3.0.0-rc.3]: https://github.com/ttimasdf/enmesh/releases/tag/v3.0.0-rc.3
[v2.8.1-forward-port]: https://github.com/ttimasdf/astral-ng/commit/73ff014c5d71e16df6226bfd46c9c806141af3f9
