# Downstream Changes

This file is the source of truth for all intentional fork-only modifications.
The upstream-sync skill reads it during merge conflict resolution to preserve
fork behavior. Update this file every time you add, modify, or remove a
fork-only change.

The fork branched from upstream tag `v2.7.3` (commit `75f033e`, 2026-03-01).
All entries below are fork-only and exist only in `ttimasdf/astral-ng`.

---

## [rebrand-astral-ng]: Rebrand GUI from Astral to Astral-ng

- **Scope**: `lib/core/states/`, `lib/features/settings/`, `lib/shared/`, `ios/`, `windows/`, `android/`, `assets/`, `scripts/`
- **Type**: override
- **Status**: active
- **Introduced**: `70a02b9`, `f74e5a0`
- **Superseded by upstream**: N/A

### What this changes

Replaces all user-facing "Astral" branding with "Astral-ng" across the GUI:
app name in state management, about page title, Android notification channel
and titles, Windows window title and tray tooltip, iOS display name, and room
sharing messages. Also ships a new app icon set (squircle design with baked
drop shadow on macOS, transparent ICO on Windows, plain square on iOS/Android,
maskable variants on web) plus a `scripts/generate_icons.py` generator that
rebuilds them from `assets/icon_raw.png`.

### Files affected

- `lib/core/states/app_settings_state.dart`, `lib/core/states/ui_state.dart`: app name string
- `lib/core/services/notification_service.dart`: Android notification channel/titles
- `lib/features/settings/pages/general/about_page.dart`: about page title
- `lib/shared/utils/data/room_share_helper.dart`: room sharing message text
- `lib/shared/widgets/common/windows_controls.dart`: window title
- `windows/runner/main.cpp`, `ios/Runner/Info.plist`: platform display name
- `assets/icon.ico`, `assets/icon_raw.png`, `assets/icon_tray.png`, `assets/logo.png`: new icons
- `android/app/src/main/res/mipmap-*/ic_launcher.png`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`, `macos/Runner/Assets.xcassets/AppIcon.appiconset/*`: platform icon assets
- `scripts/generate_icons.py`: icon regeneration script

---

## [app-identifier-pw-rabit-astralng]: Change app identifier to pw.rabit.astralng

- **Scope**: `android/app/build.gradle.kts`, `ios/Runner.xcodeproj/`, `macos/Runner*`, `linux/CMakeLists.txt`, `lib/core/services/vpn_manager.dart`
- **Type**: config
- **Status**: active
- **Introduced**: `fe516ba`
- **Superseded by upstream**: N/A

### What this changes

Replaces the upstream bundle/package identifier `com.kevin.astral` with
`pw.rabit.astralng` across all platform config files so the fork installs
side-by-side with upstream and ships under the fork's own identity. The hyphen
is omitted from the identifier because Android package names don't support
hyphens. The Android service package path is renamed accordingly (see also the
v2.7.3→v2.7.8 merge, which moved `MainActivity.kt` into the new package).

### Files affected

- `android/app/build.gradle.kts`: `applicationId` / `namespace`
- `ios/Runner.xcodeproj/project.pbxproj`: `PRODUCT_BUNDLE_IDENTIFIER`
- `macos/Runner.xcodeproj/project.pbxproj`, `macos/Runner/Configs/AppInfo.xcconfig`: macOS bundle id
- `linux/CMakeLists.txt`: Linux application id
- `lib/core/services/vpn_manager.dart`: service identifier reference

---

## [license-gpl3]: Relicense from CC-BY-NC-ND 4.0 to GPL-3.0

- **Scope**: `LICENSE`, `vpn_service_plugin/LICENSE`
- **Type**: override
- **Status**: active
- **Introduced**: `503d85a`
- **Superseded by upstream**: N/A

### What this changes

Replaces the upstream Creative Commons Attribution-NonCommercial-NoDerivatives
4.0 license with the GNU General Public License v3.0, allowing derivative works
and aligning with standard open-source practice. The `vpn_service_plugin` had a
duplicate LICENSE symlink/reference that is removed.

### Files affected

- `LICENSE`: full replacement (CC-BY-NC-ND 4.0 → GPL-3.0 text)
- `vpn_service_plugin/LICENSE`: removed

---

## [easytier-git-submodule]: Replace vendored EasyTier with a git submodule

- **Scope**: `rust/easytier`, `.gitmodules`, `rust/Cargo.toml`, `flake.nix`
- **Type**: override
- **Status**: active
- **Introduced**: `a8e300d`, `30e2353`, `5f664df`, `5fa9f23`
- **Superseded by upstream**: N/A

### What this changes

Upstream ships EasyTier as a vendored copy under `rust/easytier/`. The fork
removes the vendored tree and adds `EasyTier/EasyTier` as a git submodule under
`rust/easytier`, pinned to specific commits (currently `443c3ca`; originally
`88a45d1` / v2.5.0). This lets the fork track EasyTier releases independently of
the GUI upstream and avoids carrying a large vendored diff. The Cargo path is
updated from `./easytier` to `./easytier/easytier` because the submodule is the
full EasyTier repo. The Nix shell gains `clang`/`libclang` for kcp-sys bindgen.

Also removes the now-unused `linux-syscall-support` and `bare-kit` submodule
references. `Cargo.lock` is regenerated whenever the submodule pin moves.

### Files affected

- `rust/easytier`: converted from vendored tree → git submodule (gitlink)
- `.gitmodules`: add EasyTier entry; remove `lss` and `bare-kit` entries
- `rust/Cargo.toml`: path `./easytier` → `./easytier/easytier`
- `flake.nix`: add `clang`, `libclang` to `buildInputs`
- `rust/Cargo.lock`: regenerated on submodule bump

---

## [nix-flake-packaging]: Add Nix flake, package definition, and dev shell

- **Scope**: `flake.nix`, `flake.lock`, `package.nix`, `.envrc`, `.gitignore`
- **Type**: feature
- **Status**: active
- **Introduced**: `29074ef`, `2d5c6e9`, `a6370c9`, `fac110d`
- **Superseded by upstream**: N/A

### What this changes

Adds reproducible Nix-based development and packaging. `flake.nix` exposes a
dev shell (Flutter, Rust, protobuf, webkitgtk, libayatana-appindicator, plus
`act` for running GitHub Actions locally with `ACT_DISABLE_VERSION_CHECK` set)
and a `package.nix` that builds the Flutter/Rust app via Cargokit and installs
the Linux desktop item. `.envrc` enables direnv automatic shell switching.
`/result` (Nix build output symlink) is gitignored.

### Files affected

- `flake.nix`: dev shell + package output
- `flake.lock`: pinned nixpkgs input
- `package.nix`: Flutter/Rust build derivation, Cargokit integration, desktop item
- `.envrc`: `use flake`
- `.gitignore`: ignore `/result`

---

## [ci-overhaul]: Replace 11 platform workflows with unified ci.yml (+release)

- **Scope**: `.github/workflows/`, `scripts/install_*.{sh,ps1}`
- **Type**: override
- **Status**: active
- **Introduced**: `9759107`, `3d0c98c`, `1668853`, `62ce3de`, `ac21953`, `7be7a3c`, `f4cce97`, `e77a928`, `663dd73`, `6f728a3`, `e8fc9fc`, `50fcb14`, `c49aa02`, `30fe346`, `8f06925`
- **Superseded by upstream**: N/A

### What this changes

Deletes the upstream collection of per-platform workflow files
(`android-build-*.yaml`, `linux-build.yaml`, `linux-arm-build.yaml`,
`windows-build*.yml`, `build-all-platforms.yaml`, `dart.yml`, plus custom
`install_rust.sh/ps1` and `install_flutter.sh/ps1` scripts) and replaces them
with a single unified `.github/workflows/ci.yml` that builds every target
(linux x64, windows x64/setup, android arm64/armv7/universal) using a
cross-compilation matrix, `flutter-actions/setup-flutter@v4` with caching,
`Swatinem/rust-cache` with workspace mapping, and pub caching. Linux arm64 is
dropped (Flutter doesn't support it). The Android NDK is reverted to Flutter's
default version.

A separate `release.yml` (later folded into `ci.yml` as a tag-push job) extracts
release notes from `CHANGELOG.md` on tag push. The Windows installer metadata
(app name, publisher) is updated for the fork. Windows-specific fixes: install
Npcap SDK / system deps for cross-compilation, create a `third_party` symlink
for the EasyTier build, correct the `Packet.lib` link search path, and replace
`bash mkdir -p` with PowerShell `New-Item` on Windows runners.

### Files affected

- `.github/workflows/ci.yml`: unified build + (later) release job (added)
- `.github/workflows/release.yml`: added then removed (folded into ci.yml)
- `.github/workflows/android-build-{arm64,armv7,universal}.yaml`, `linux-build.yaml`, `linux-arm-build.yaml`, `windows-build.yml`, `windows-build-Setup.yml`, `build-all-platforms.yaml`, `dart.yml`, `Stop All Workflows.yaml`: deleted
- `scripts/install_flutter.{sh,ps1}`, `scripts/install_rust.{sh,ps1}`: deleted

---

## [tray-connect-disconnect]: Add connect/disconnect action to tray menu

- **Scope**: `lib/shared/widgets/common/windows_controls.dart`
- **Type**: feature
- **Status**: active
- **Introduced**: `6449708`
- **Superseded by upstream**: N/A

### What this changes

Adds a dynamic connect/disconnect item to the system tray context menu. The
label updates reactively based on connection state: idle → "连接", connecting →
"连接中..." (disabled), connected → "断开连接".

### Files affected

- `lib/shared/widgets/common/windows_controls.dart`: tray menu item + state binding

---

## [rust-event-handling-fix]: Handle EasyTier GlobalCtxEvent variants instead of panicking

- **Scope**: `rust/src/api/simple.rs`, `rust/src/api/p2p.rs`
- **Type**: patch
- **Status**: active
- **Introduced**: `6e20130`, `fab9e20`
- **Superseded by upstream**: N/A

### What this changes

Upstream's FFI bridge left `GlobalCtxEvent::ConfigPatched` and
`GlobalCtxEvent::ProxyCidrsUpdated` as `todo!()` stubs, causing a runtime panic
whenever EasyTier fired them. The fork replaces them with log-and-forward
handlers consistent with all other event arms. A follow-up keeps the bridge in
sync with EasyTier API drift: add a `CredentialChanged` handler, add
`peer_public_key` to `PeerConfig`, switch `set_tun_fd` to use
`get_tun_fd_sender`, and ignore the unused `Result` from `add_proxy_cidr`.

### Files affected

- `rust/src/api/simple.rs`: replace `todo!()` arms with handlers; add `CredentialChanged`
- `rust/src/api/p2p.rs`: `peer_public_key` field; `set_tun_fd`/`add_proxy_cidr` updates

---

## [remove-google-services]: Remove Google services from the Android build

- **Scope**: `android/app/build.gradle.kts`, `android/build.gradle.kts`, `android/app/google-services.json`
- **Type**: removal
- **Status**: active
- **Introduced**: `25d8e6a`
- **Superseded by upstream**: N/A

### What this changes

Removes Firebase / Google services integration from the Android build: deletes
`google-services.json`, the Gradle plugin, and its dependency. The fork ships
without any Google telemetry/crash-reporting dependency.

### Files affected

- `android/app/google-services.json`: deleted
- `android/app/build.gradle.kts`: remove plugin + `google-services` apply
- `android/build.gradle.kts`: remove plugin classpath dependency

---

## [clean-blocklist]: Remove hardcoded servers from the blocklist

- **Scope**: `lib/shared/utils/network/blocked_servers.dart`
- **Type**: removal
- **Status**: active
- **Introduced**: `41fd8b0`
- **Superseded by upstream**: N/A

### What this changes

Removes specific hardcoded entries (notably `629957.xyz`) from the blocked-URL
list. The fork no longer ships an opinionated blocklist of specific upstream
servers.

### Files affected

- `lib/shared/utils/network/blocked_servers.dart`: drop hardcoded entries

---

## [disable-hitokoto-card]: Temporarily disable the HitokotoCard widget

- **Scope**: `lib/features/home/pages/home_page.dart`
- **Type**: removal
- **Status**: active
- **Introduced**: `d5e92ea`
- **Superseded by upstream**: N/A

### What this changes

Disables the Hitokoto (一言) quote card on the home page. Marked temporary;
re-enable by reverting the single-line change.

### Files affected

- `lib/features/home/pages/home_page.dart`: comment out / disable widget

---

## [remove-linux-root-check]: Remove the Linux root privilege check

- **Scope**: `lib/main.dart`
- **Type**: removal
- **Status**: active
- **Introduced**: `f80f1f7`
- **Superseded by upstream**: N/A

### What this changes

Removes the startup check that required the app to run as root on Linux. The
fork runs unprivileged (VPN privileges are handled by the platform/EasyTier
rather than by elevating the whole GUI).

### Files affected

- `lib/main.dart`: remove root-check block (~12 lines)

---

## [connectbutton-animation-fix]: Stop ConnectButton animation when idle

- **Scope**: `lib/shared/widgets/common/home/connect_button.dart`
- **Type**: patch
- **Status**: active
- **Introduced**: `6483a91`
- **Superseded by upstream**: N/A

### What this changes

The `AnimationController` ran `repeat(reverse: true)` continuously from
`initState`, causing constant CPU usage even when the app was idle. The
animation is only meaningful during the connecting state, so it is now started
and stopped around that state only. Fixes upstream issue #192.

### Files affected

- `lib/shared/widgets/common/home/connect_button.dart`: scope animation to connecting state

---

## [docs-readme-changelog-gitignore]: Replace README, add CHANGELOG, comprehensive .gitignore, and CLAUDE.md

- **Scope**: `README.md`, `README_en.md`, `CHANGELOG.md`, `.gitignore`, `CLAUDE.md`
- **Type**: feature
- **Status**: active
- **Introduced**: `a7aa44c`, `6cd9a8f`, `10543e2`, `73f0551`, `c68cbd0`
- **Superseded by upstream**: N/A

### What this changes

Replaces the upstream README with fork-specific Chinese and English READMEs
that credit the original author (`ldoubil`) and document the fork's use cases.
Adds a `CHANGELOG.md` (v2.7.0 → v2.8.0 entries, later expanded with full CI
changes and upstream-merge details, and backfilled with v2.7.0–v2.7.3 entries).
Replaces the minimal `.gitignore` with a comprehensive gitignore.io-generated
template covering Dart, Flutter, Flatpak, IntelliJ, Android Studio, VS Code,
direnv, and Claude Code local settings. Adds `CLAUDE.md` with fork-specific
development guidance.

### Files affected

- `README.md`: rewritten (zh) with author credit and use cases
- `README_en.md`: new English README
- `CHANGELOG.md`: new, with v2.7.0–v2.8.0 entries
- `.gitignore`: replaced with comprehensive template
- `CLAUDE.md`: new, fork dev guidance

---

## [merge-upstream-v2.7.3-to-v2.7.8]: Forward-port upstream v2.7.3 → v2.7.8 features

- **Scope**: `android/app/src/main/`, `lib/core/models/`, `lib/core/services/`, `assets/translations/`
- **Type**: patch
- **Status**: active
- **Introduced**: `73ff014`
- **Superseded by upstream**: N/A

### What this changes

Manually merges selected features from upstream's v2.7.3 → v2.7.8 range into
the fork (rather than taking all of v2.7.8 wholesale): Android home screen
widgets (small/medium/large), a connection notification toggle setting, a
Magic Wall refactor that syncs rules before starting the engine and clears
`RULE_STORE` on stop, and updated translations for the new notification
setting. This is an intermediate forward-port; the next `/upstream-sync` run
should reconcile it against the actual v2.7.8+ upstream tags.

### Files affected

- `android/app/src/main/AndroidManifest.xml`: widget declarations
- `android/app/src/main/kotlin/.../AstralWidgetProvider{,Medium,Large}.kt`: widget providers
- `android/app/src/main/res/{drawable,layout,xml}/widget_*`: widget resources
- `lib/core/models/all_settings.dart`, `all_settings.g.dart`: notification setting
- `lib/core/models/converters/all_settings_converter.dart`: converter
- `lib/core/repositories/app_settings_repository.dart`, `lib/core/services/app_settings_service.dart`: setting persistence
- `lib/core/services/server_connection_manager.dart`, `lib/core/services/widget_service.dart`: widget + connection hooks
- `assets/translations/*.json`: notification-setting strings

---

<!-- Add new entries below using the format described in AGENTS.md. -->
