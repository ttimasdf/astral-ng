# Changelog

This file records notable changes to Astral-ng. User-facing entries describe
observable outcomes; concise developer notes and links provide implementation
provenance. Astral-ng release versions are independent of the upstream Astral
baseline.

## Unreleased

> **Highlight:** AstralNG Canary snapshots now install separately from production releases.
>
> **版本亮点：** AstralNG Canary 快照版本现可与正式版本独立安装。

### Added

- Added an Android Quick Settings tile that shows the current connection state
  and connects or disconnects Astral-ng with one tap. ([#10])
- Added automatic connection retries with a configurable retry limit.
  ([upstream-auto-retry])
- Added a local SOCKS5 listener for accessing the virtual network in NO-TUN
  mode, including a configurable listen port. ([upstream-#229])
- Added UDP broadcast relay support on Windows. ([upstream-udp-relay])
- Added an option to hide the desktop system-tray icon for the current session.
  ([upstream-#74])
- Added a reduced-animation mode that lowers topology and connection animation
  updates while the window is hidden or minimized. ([upstream-topology])

### Changed

- Separated canary snapshots from production installs with the AstralNG Canary
  name, `astral-canary` command, distinct package identities, and a
  grayscale-and-gold icon on Linux, Windows, and Android.
- Renamed the visible application, widget, notification, installer, and Quick
  Settings tile branding to AstralNG across supported platforms.
- Improved Android and iOS server management with short, spring-back gestures:
  tap a row to edit, swipe right to enable or disable it, swipe left to request
  confirmed deletion, and identify enabled or disabled rows by their green or
  red indicator. ([#11])
- Replaced the desktop server switch and overflow menu with direct toggle and
  delete icon buttons; clicking the row opens editing. ([#11])
- Added version suffixes to downloadable CI snapshots and release assets, and
  made workflow artifacts downloadable without an additional ZIP wrapper.
- Renamed room credential choices to **Simple** and **Advanced**. Simple mode
  generates credentials; Advanced mode accepts shared credentials. This choice
  is separate from network-traffic encryption. ([#3])
- Replaced the Explore area with a focused Tools page for NAT testing, port
  whitelists, and the Windows Magic Wall. ([upstream-v2.9.9])
- Improved update downloads with selectable mirrors and automatic mirror
  benchmarking. ([upstream-#226])
- Improved Android home-screen widgets with theme-aware layouts, more reliable
  status refreshes, and one-tap connection toggling. ([upstream-widgets])
- Connection attempts now check for a selected room, an enabled server, and the
  Windows Npcap driver before starting, and report the specific missing
  prerequisite. ([upstream-connect-guard])

### Fixed

- Fixed Android VPN routes not refreshing when a connected peer advertises or
  changes a proxy subnet. ([upstream-#231])
- Fixed room member filtering when switching between user and server types.
  ([upstream-#236])
- Fixed low frame rates and delayed window closing on Windows.
  ([upstream-windows-fps], [upstream-window-close])
- Fixed Linux DEB and RPM artifacts reporting version `1.0.0`, allowing package
  managers to recognize upgrades correctly. ([upstream-#237])

### Removed

- Removed German, Spanish, French, Japanese, Korean, and Russian translations.
  The interface currently supports English and Chinese. ([upstream-v2.9.9])

### Developer notes

- Merged upstream Astral through `v2.9.9` while preserving Astral-ng's
  independent application version and active downstream behavior.
  ([upstream-v2.9.9])
- Pinned EasyTier to release tag `v2.6.4`; Windows builds obtain the Npcap SDK
  separately rather than from a vendored EasyTier tree. ([#2])
- Made `VERSION` the source of truth for production versions and build numbers;
  CI now labels non-release artifacts as canary builds and validates production
  tags. ([#4])
- Consolidated validation and release packaging into tiered CI: pull requests
  run analysis and Linux by default, while the `full-ci` label adds Windows and
  Android; main-branch pushes now retain the same short-lived test artifacts.
  ([#5], [#6])
- Updated the Nix development and packaging environment to Flutter 3.44 for
  Dart 3.12 source compatibility. ([nix-flutter-3.44])
- Made the locked nixpkgs package set authoritative for development toolchains,
  added a complete local Android SDK/NDK environment, and synchronized versions
  for standard local tools and CI. ([#9])

## v2.8.1 - 2026-03-31

> **Highlight:** Android widgets put connection status on your home screen.
>
> **版本亮点：** Android 主屏幕小组件可直接显示连接状态。

Published release: [v2.8.1-release].

### Added

- Added small, medium, and large Android home-screen widgets with connection
  status and tap-to-open behavior.
- Added a setting to enable or disable persistent Android connection
  notifications.

### Fixed

- Fixed Magic Wall startup so rules are synchronized before the engine starts.
- Fixed Magic Wall shutdown leaving firewall rules or its in-memory rule store
  active.

### Developer notes

- Forward-ported selected Android widget, notification, and Magic Wall changes
  from upstream `v2.7.8`. The original release was a forward-port; an
  ancestry-preserving upstream merge was completed later.
  ([v2.8.1-forward-port], [v2.7.8-merge])

## v2.8.0 - 2026-03-26

> **Highlight:** Astral became Astral-ng with its own independent identity.
>
> **版本亮点：** Astral 正式更名为 Astral-ng，并启用独立的应用标识。

Published release: [v2.8.0-release].

### Added

- Added a dynamic Connect/Disconnect action to the desktop tray menu.

### Changed

- Rebranded the application, installer metadata, and platform icons from Astral
  to Astral-ng.
- Changed the application identifier to `pw.rabit.astralng`, allowing Astral-ng
  to install independently of upstream Astral.
- Removed the Linux startup requirement to run the entire GUI as root. The
  selected network mode and package must still provide any privileges required
  to create a TUN interface.
- Removed Google Services from the Android build.
- Removed the built-in server blocklist and temporarily hid the home-page
  Hitokoto quote card.
- Relicensed the fork from CC BY-NC-ND 4.0 to GPL-3.0.

### Fixed

- Fixed crashes when EasyTier emitted `ConfigPatched` or `ProxyCidrsUpdated`
  events.
- Fixed the Connect button animating continuously while idle, which could cause
  high CPU usage while the application window was active.
- Fixed Windows builds failing to locate the Npcap `Packet.lib` library.

### Developer notes

- Added a Nix flake, development shell, and NixOS package definition.
- Replaced the vendored EasyTier source with a git submodule pinned to
  `v2.5.0`; the Unreleased changes later replace that submodule with the current
  `v2.6.4` release-tag dependency.
- Replaced the upstream platform-specific workflow collection with unified
  validation and release automation.

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
[v2.8.0-release]: https://github.com/ttimasdf/astral-ng/releases/tag/v2.8.0
[v2.8.1-release]: https://github.com/ttimasdf/astral-ng/releases/tag/v2.8.1
[v2.8.1-forward-port]: https://github.com/ttimasdf/astral-ng/commit/73ff014c5d71e16df6226bfd46c9c806141af3f9
