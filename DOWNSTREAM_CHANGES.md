# Downstream Changes

This file is the source of truth for all intentional fork-only modifications.
The upstream-sync skill reads it during merge conflict resolution to preserve
fork behavior. Update this file every time you add, modify, or remove a
fork-only change.

The fork branched from upstream tag `v2.7.3` (commit `75f033e`, 2026-03-01).
All entries below are fork-only and exist only in `ttimasdf/astral-ng`.

---

## [rebrand-astral-ng]: Rebrand GUI from Astral to AstralNG

- **Scope**: `lib/core/states/`, `lib/features/settings/`, `lib/shared/`, `ios/`, `windows/`, `android/`, `assets/`, `scripts/`
- **Type**: override
- **Status**: active
- **Introduced**: `70a02b9`, `f74e5a0`
- **Superseded by upstream**: N/A

### What this changes

Replaces all user-facing "Astral" branding with "AstralNG" across the GUI:
app name in state management, Android notification channel and titles, Windows
window title, tray tooltip, executable metadata, and installer, iOS/macOS
application display names, Linux desktop and AppImage metadata, Android home
widgets and Quick Settings tile, and room sharing messages. It preserves the
stable `pw.rabit.astralng` identifiers, executable/artifact names, and
`astral://` deep-link scheme. The fork also ships a new app icon set (squircle
design with baked drop shadow on macOS, transparent ICO on Windows, plain
square on iOS/Android, maskable variants on web) plus a
`scripts/generate_icons.py` generator that rebuilds them from
`assets/icon_raw.png`.

### Files affected

- `lib/core/states/app_settings_state.dart`, `lib/core/services/notification_service.dart`, `lib/core/room/room_share_codec.dart`, `lib/shared/widgets/common/windows_controls.dart`: GUI, notification, share, and tray branding
- `android/app/src/main/`: launcher, widget, and Quick Settings tile labels
- `ios/Runner/Info.plist`, `macos/Runner/Configs/AppInfo.xcconfig`: Apple platform display names
- `windows/runner/main.cpp`, `windows/runner/Runner.rc`, `.github/workflows/build-and-release.yml`: Windows window, executable metadata, and installer name
- `linux/runner/my_application.cc`, `linux/packaging/`: Linux window, desktop, and AppImage display names
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

## [easytier-git-release-dependency]: Pin EasyTier dependency to a git release tag

- **Scope**: `rust/Cargo.toml`, `rust/build.rs`, `.github/workflows/build-and-release.yml`, `flake.nix`, `.gitmodules`, `rust/easytier`
- **Type**: override
- **Status**: active
- **Introduced**: `a8e300d`, `30e2353`, `5f664df`, `5fa9f23`; updated during upstream sync to `v2.8.7` and reviewed against upstream `v2.9.9`
- **Superseded by upstream**: Partially (`v2.9.9`)

### What this changes

Upstream `v2.9.9` now obtains EasyTier directly from the
`EasyTier/EasyTier` git repository rather than carrying a checked-out EasyTier
tree, superseding the fork's earlier submodule-removal rationale. Astral-ng
intentionally retains an explicit EasyTier release-tag pin (`v2.6.4`) in
`rust/Cargo.toml`, whereas upstream tracks the repository's default git ref.
The pin makes builds reproducible against a known-compatible EasyTier API and
prevents upstream EasyTier changes from silently changing the dependency used by
a given Astral-ng source revision.

The historical downstream submodule at `rust/easytier` remains removed. Because
its `easytier/third_party/` directory is unavailable, Windows Npcap linking is
supplied explicitly by CI through `NPCAP_SDK_LIB`, with a fork-controlled local
fallback at `third_party/npcap-sdk/Lib/x64`. `rust/build.rs` does not probe
EasyTier dependency source/cache paths for `third_party`. The Nix shell keeps
`clang` and `libclang` for bindgen-capable builds.

### Files affected

- `rust/easytier`: removed historical EasyTier submodule / gitlink
- `.gitmodules`: removed EasyTier submodule entry
- `rust/Cargo.toml`: pin EasyTier git dependency to tag `v2.6.4`; upstream `v2.9.9` uses the same git source without a tag
- `rust/build.rs`: Npcap search limited to `NPCAP_SDK_LIB` and `third_party/npcap-sdk/Lib/x64`
- `.github/workflows/build-and-release.yml`: Windows CI installs Npcap SDK and exports `NPCAP_SDK_LIB`
- `flake.nix`: retain `clang` and `libclang` in `buildInputs`
- `rust/Cargo.lock`: regenerated when the EasyTier source/tag changes

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

## [ci-overhaul]: Use tiered CI and release builds

- **Scope**: `.github/workflows/`, `scripts/install_*.{sh,ps1}`
- **Type**: override
- **Status**: active
- **Introduced**: `ci-overhaul`
- **Superseded by upstream**: N/A

### What this changes

Deletes the upstream collection of per-platform workflow files
(`android-build-*.yaml`, `linux-build.yaml`, `linux-arm-build.yaml`,
`windows-build*.yml`, `build-all-platforms.yaml`, `dart.yml`, plus custom
`install_rust.sh/ps1` and `install_flutter.sh/ps1` scripts) and replaces them
with a single tiered workflow, now located at
`.github/workflows/build-and-release.yml`. Pull requests analyze the
application's Dart sources and build Linux; pushes to `main` additionally
validate Windows and an unsigned multi-ABI Android debug build. Applying the
`full-ci` label opts a pull request into those platform builds and uploads
Linux tar/DEB/RPM, Windows ZIP/installer, and Android debug APK artifacts for
testing. Full-CI artifacts use exact output paths and expire after seven days.
Each package is uploaded as a direct single-file artifact without an additional
ZIP wrapper. Snapshot and release filenames end with the resolved
`ASSET_VERSION`, so canary files include their CI build identity and production
files use the `vX.Y.Z` suffix.
Superseded non-release runs are cancelled, while tag builds are never
cancelled.

Only `v*` tag pushes access release signing secrets and publish release
artifacts (linux x64, windows x64/setup, android arm64/armv7/universal), then
extract release notes from `CHANGELOG.md` and publish the GitHub release.
Workflow tokens otherwise default to read-only repository contents, and
checkout credentials are not persisted in the worktree. Android split APKs are
built in one invocation. `flutter-actions/setup-flutter@v4` and
`Swatinem/rust-cache` retain SDK, pub, and Rust caching. Linux arm64 remains
dropped because Flutter does not support it. The Windows installer metadata
(app name, publisher) is updated for the fork. Windows-specific fixes: install
Npcap SDK / system deps for cross-compilation from an immutable Wayback Machine
capture with SHA-256 verification, create a `third_party` symlink for the
EasyTier build, correct the `Packet.lib` link search path, and replace `bash
mkdir -p` with PowerShell `New-Item` on Windows runners.

### Files affected

- `.github/workflows/build-and-release.yml`: tiered PR/main/tag/manual validation, stale-run cancellation, direct version-suffixed snapshot and release files, short-lived full-CI test artifacts, read-only default permissions, non-persisted checkout credentials, and tag-only production signing/release; Windows downloads the Npcap SDK from a pinned, SHA-256-verified Wayback Machine capture
- `.github/workflows/release.yml`: added then removed (folded into the unified workflow, now `build-and-release.yml`)
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
- **Status**: superseded
- **Introduced**: `6e20130`, `fab9e20`
- **Superseded by upstream**: `v2.8.7`

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
- **Status**: superseded
- **Introduced**: `6483a91`
- **Superseded by upstream**: `v2.8.7`

### What this changes

The `AnimationController` ran `repeat(reverse: true)` continuously from
`initState`, causing constant CPU usage even when the app was idle. The
animation is only meaningful during the connecting state, so it is now started
and stopped around that state only. Fixes upstream issue #192.

### Files affected

- `lib/shared/widgets/common/home/connect_button.dart`: scope animation to connecting state

---

## [docs-readme-changelog-gitignore]: Maintain fork documentation and changelog standards

- **Scope**: `README.md`, `README_en.md`, `CHANGELOG.md`, `docs/CHANGELOG_GUIDELINES.md`, `AGENTS.md`, `.gitignore`, `CLAUDE.md`
- **Type**: feature
- **Status**: active
- **Introduced**: `a7aa44c`, `6cd9a8f`, `10543e2`, `73f0551`, `c68cbd0`
- **Superseded by upstream**: N/A

### What this changes

Replaces the upstream README with fork-specific Chinese and English READMEs
that credit the original author (`ldoubil`) and document the fork's use cases.
Adds and maintains `CHANGELOG.md` as a concise record of Astral-ng release
impact, with developer provenance kept in links and optional developer notes.
Each release section starts with English `> **Highlight:** ...` and Chinese
`> **版本亮点：** ...` summaries separated by a blank blockquote line; the stable
block grammar supports localized release-manifest generation. Adds
`docs/CHANGELOG_GUIDELINES.md` as the writing, verification, and release
standard and references it from `AGENTS.md`. Replaces the minimal `.gitignore`
with a comprehensive gitignore.io-generated template covering Dart, Flutter,
Flatpak, IntelliJ, Android Studio, VS Code, direnv, and Claude Code local
settings. Adds `CLAUDE.md` with fork-specific development guidance.

### Files affected

- `README.md`: rewritten (zh) with author credit and use cases
- `README_en.md`: new English README
- `CHANGELOG.md`: Astral-ng release history and current `Unreleased` changes,
  written for users with linked developer provenance and bilingual release
  highlights
- `docs/CHANGELOG_GUIDELINES.md`: changelog structure, bilingual highlight
  grammar, evidence hierarchy, entry style, provenance, release workflow, and
  checklist
- `AGENTS.md`: requires changelog updates to follow the guideline
- `.gitignore`: replaced with comprehensive template
- `CLAUDE.md`: new, fork dev guidance

---

## [dlls-folder-documentation]: Document Windows DLL bundle contents

- **Scope**: `dlls/README.md`
- **Type**: feature
- **Status**: active
- **Introduced**: 2026-06-29
- **Superseded by upstream**: N/A

### What this changes

Adds a README to the Windows DLL bundle explaining which files are useful,
why they are probably present, and where the build or runtime paths consume
them. This documents the fork's Windows packaging mirror for EasyTier runtime
DLLs, calls out non-runtime files such as `Packet.lib`, and records Binary
Ninja findings that `Ak.dll` is an active Winsock-hooking DLL rather than a
normal Astral-ng runtime dependency.

### Files affected

- `dlls/README.md`: new inventory of DLL/sys/lib files, direct packaging
  references, likely runtime owners, and maintenance notes

---

## [room-modes]: Rename room credential modes

- **Scope**: `assets/translations/`, `lib/core/room/`, `lib/features/home/widgets/canvas_jump.dart`, `lib/features/rooms/`, `lib/generated/locale_keys.g.dart`
- **Type**: override
- **Status**: active
- **Introduced**: room-modes
- **Superseded by upstream**: N/A

### What this changes

Replaces the ambiguous protected/unprotected (and encrypted/public) room labels
with Simple and Advanced modes. Simple mode generates the EasyTier room
credentials automatically; Advanced mode lets the user enter shared credentials.
This clarifies that the choice does not control the separate network-traffic
encryption setting.

### Files affected

- `assets/translations/en.json`, `assets/translations/zh.json`: localized room-mode labels and descriptions
- `lib/core/room/room_mode.dart`: centralized localized display name for the stored room-mode flag
- `lib/core/room/room_share_codec.dart`: mode-aware sharing summary and validation message
- `lib/features/rooms/dialogs/add_room_dialog.dart`: explicit Simple/Advanced selector
- `lib/features/rooms/dialogs/edit_room_dialog.dart`, `lib/features/rooms/widgets/room_card.dart`, `lib/features/rooms/widgets/room_reorder_sheet.dart`, `lib/features/home/widgets/canvas_jump.dart`: mode labels in room UI
- `lib/generated/locale_keys.g.dart`: regenerated localization keys

---

## [version-source]: Establish Astral-ng-owned release and canary versioning

- **Scope**: `VERSION`, `pubspec.yaml`, `scripts/version.py`, `.github/workflows/build-and-release.yml`, `lib/core/platform/app_info.dart`, `lib/features/settings/widgets/update_settings_actions.dart`, `docs/VERSIONING.md`
- **Type**: config
- **Status**: active
- **Introduced**: `version-source`
- **Superseded by upstream**: N/A

### What this changes

Makes `VERSION` the only human-edited source for Astral-ng's application version and production build number. The cross-platform Python tool validates the Flutter mirror, derives package and installer versions, supports semantic version bumps, and logs an observable build identity. CI requires production tags to match the source and gives canary builds a separate CI-unique build number and artifact label.

### Files affected

- `VERSION`, `scripts/version.py`: cross-platform version source management, derivation, bumping, and mirror validation
- `pubspec.yaml`: Flutter-required mirror of the source version
- `.github/workflows/build-and-release.yml`: production-tag validation and version-derived build/package metadata
- `lib/core/platform/app_info.dart`, `lib/features/settings/widgets/update_settings_actions.dart`: identify canary builds in the version dialog
- `docs/VERSIONING.md`: maintainer workflow and versioning contract

---

## [main-ci-artifacts]: Publish test artifacts from main-branch builds

- **Scope**: `.github/workflows/build-and-release.yml`
- **Type**: config
- **Status**: active
- **Introduced**: `main-ci-artifacts`
- **Superseded by upstream**: N/A

### What this changes

Renames the unified workflow from `CI` / `ci.yml` to `Build and Release` /
`build-and-release.yml`. Pushes to `main` now package and retain the same Linux,
Windows, and Android test outputs as pull requests labeled `full-ci`. Linux and
Windows use one event-independent upload path because those packages are not
code-signed. Android debug builds use one short-lived test upload, while
production keystore setup and signed release APKs remain restricted to `v*` tag
pushes. Packaged files are uploaded directly without an extra ZIP wrapper, use
the same naming scheme for every event, and end with `ASSET_VERSION`, identifying
the exact canary or production build.

### Files affected

- `.github/workflows/build-and-release.yml`: renamed workflow; package and directly upload main-branch test builds with version-suffixed filenames; preserve tag-only Android signing and release publication

---

## [android-vpn-revocation]: Synchronize system VPN revocation with connection state

- **Scope**: `vpn_service_plugin/android/src/main/kotlin/com/plugin/vpn_service_plugin/TauriVpnService.kt`, `vpn_service_plugin/android/src/main/kotlin/com/plugin/vpn_service_plugin/VpnServicePlugin.kt`, `lib/core/services/vpn_manager.dart`
- **Type**: patch
- **Status**: active
- **Introduced**: android-vpn-revocation
- **Superseded by upstream**: N/A

### What this changes

Android permits only one active VPN. When another VPN takes ownership, the
system invokes `VpnService.onRevoke()`. Astral-ng handles that callback on the
main thread, closes and stops its VPN service, emits one distinct `revoked`
event even if the TUN is already closed, and disconnects the EasyTier backend
and UI state. Application-requested stops and route refreshes remain local and
do not trigger this disconnect path. Route refreshes establish the replacement
TUN before closing the previous descriptor, and the service does not restart
without the packet-processing backend after process death.

### Files affected

- `vpn_service_plugin/android/src/main/kotlin/com/plugin/vpn_service_plugin/TauriVpnService.kt`: serialize system revocation onto the main thread, deduplicate revocation events independently of TUN state, perform seamless TUN replacement, and use a non-sticky lifecycle
- `vpn_service_plugin/android/src/main/kotlin/com/plugin/vpn_service_plugin/VpnServicePlugin.kt`: stop the service through Android lifecycle APIs, refresh routes without a static service reference, and clear the Flutter callback when the event channel detaches
- `lib/core/services/vpn_manager.dart`: subscribe to revocation events and disconnect the active connection

---

## [toolchain-pinning]: Derive development toolchains from locked nixpkgs

- **Scope**: `flake.nix`, `flake.lock`, `package.nix`, `scripts/sync_toolchains.py`, `rust-toolchain.toml`, `.fvmrc`, `.java-version`, `android/`, `.github/`, `rust_builder/cargokit/`, `.gitignore`, `CLAUDE.md`, `docs/TOOLCHAINS.md`
- **Type**: config
- **Status**: active
- **Introduced**: `toolchain-pinning`
- **Superseded by upstream**: N/A

### What this changes

Makes the versions selected by `flake.nix` and the locked nixpkgs revision the
source of truth for Rust, Flutter, Java, cargo-ndk, and Android tooling. A Nix
application deterministically synchronizes those package versions to standard
consumer files used by rustup, FVM, Java tools, Gradle, and CI. The Nix shell
includes compatible historical Android components available from the locked
nixpkgs revision (platform 36, Build Tools 35.0.0, CMake 3.22.1, NDK 28.2, and
JDK 17), exports Android and Java paths, and supports local APK builds.
Cargokit's default build path respects rustup's active project toolchain instead
of bypassing the synchronized pin with `stable`, and explicitly uses rustup's
cross-target compiler when nixpkgs' host compiler appears first in `PATH`.

### Files affected

- `flake.nix`, `flake.lock`, `package.nix`: select canonical development packages from nixpkgs, compose the default Android SDK/NDK, expose resolved versions only through the synchronization package passthru, add the sync app/check, keep default-system development outputs, and leave the application package dependent only on nixpkgs inputs
- `scripts/sync_toolchains.py`: generate or verify deterministic tool-specific mirrors from Nix-provided versions
- `rust-toolchain.toml`, `.fvmrc`, `.java-version`, `android/toolchain.properties`: generated mirrors consumed outside Nix
- `android/app/build.gradle.kts`, `android/build.gradle.kts`: consume synchronized platform, build-tools, target, CMake, and NDK versions and apply them consistently to third-party Android subprojects
- `.github/actions/setup-toolchains/action.yml`, `.github/workflows/build-and-release.yml`: install synchronized Rust/Flutter versions and optionally set up the complete Android toolchain
- `.github/ci-versions.yml`: remove the unused upstream CI-only version reference
- `rust_builder/cargokit/build_tool/lib/src/builder.dart`, `rust_builder/cargokit/build_tool/lib/src/rustup.dart`: preserve exact-version rustup toolchains, use the active project override, and select rustup's compiler explicitly for cross-target builds inside the Nix shell
- `.gitignore`: ignore FVM's generated project directory
- `CLAUDE.md`, `docs/TOOLCHAINS.md`: document Nix ownership, local Android setup, consumer mirrors, and upgrades

---

## [android-quick-settings-tile]: Add an Android Quick Settings connection tile

- **Scope**: `android/app/src/main/`, `lib/core/app_links/`, `lib/core/services/widget_service.dart`, `lib/core/constants/home_widget_keys.dart`, `lib/shared/widgets/common/home_widget_refresh_binder.dart`, `vpn_service_plugin/android/src/main/kotlin/com/plugin/vpn_service_plugin/VpnServicePlugin.kt`
- **Type**: feature
- **Status**: active
- **Introduced**: android-quick-settings-tile
- **Superseded by upstream**: N/A

### What this changes

Adds an Android 7.0+ Quick Settings tile that displays Astral-ng's persisted
connection state and toggles the selected room. When the primary Flutter engine
is running, the native tile sends its action directly to that engine so the GUI,
Rust backend, VPN, and tile share one connection state. When the app is not
running, the tile opens Astral-ng with the same action as an app link. The tile
supports both VPN and NO-TUN configurations and opens the app when Android
still needs initial VPN consent. Home-widget background engines initialize the
Rust bridge without applying normal app-start auto-connect behavior, while the
VPN plugin uses application context after consent so widget operations do not
require an attached Activity.

### Files affected

- `android/app/src/main/AndroidManifest.xml`: registers the active, toggleable Quick Settings tile service
- `android/app/src/main/kotlin/pw/rabit/astralng/AstralQuickSettingsTileService.kt`: renders tile state and delivers actions to the primary engine or app-link fallback without leaving the tile unavailable
- `android/app/src/main/kotlin/pw/rabit/astralng/MainActivity.kt`, `lib/core/services/widget_service.dart`: establish the native-to-primary-Flutter toggle channel
- `lib/core/app_links/`: handles the same toggle action when the tile must launch the app
- `android/app/src/main/res/`: adds the monochrome tile icon and English/Chinese status strings
- `lib/core/constants/home_widget_keys.dart`, `lib/shared/widgets/common/home_widget_refresh_binder.dart`: persist and refresh connection and VPN-mode state for native surfaces
- `lib/core/services/service_manager.dart`: allows background entry points to skip normal startup actions
- `vpn_service_plugin/android/src/main/kotlin/com/plugin/vpn_service_plugin/VpnServicePlugin.kt`: allows already-authorized VPN start and stop calls from a background Flutter engine

---

## [mobile-server-swipe-actions]: Optimize mobile server list gestures

- **Scope**: `lib/features/servers/pages/server_page.dart`, `lib/features/servers/widgets/server_list_tile.dart`, `test/features/servers/widgets/server_list_tile_test.dart`
- **Type**: feature
- **Status**: active
- **Introduced**: mobile-server-swipe-actions
- **Superseded by upstream**: N/A

### What this changes

Replaces the Android and iOS server row switch and overflow menu with direct
mobile gestures. Tapping a row opens editing, swiping right toggles its enabled
state, and swiping left opens a confirmation dialog before deletion. Swipe
travel is capped to part of the row width and springs back after triggering an
action. Mobile reordering uses a long press so horizontal actions do not compete
with row reordering. Each row places its text directly beside a green
enabled-state indicator or red disabled-state indicator. Desktop rows open
editing on click and use direct toggle and delete icon buttons instead of a
switch and overflow menu. Semantic actions keep toggle and deletion available
to assistive technologies.

### Files affected

- `lib/features/servers/pages/server_page.dart`: select mobile actions by platform, route edit/toggle/delete callbacks, and use long-press mobile reordering
- `lib/features/servers/widgets/server_list_tile.dart`: render mobile bounded spring-back swipe actions, desktop icon actions, enabled-state indicator and spacing, confirmation flow, and accessibility actions
- `test/features/servers/widgets/server_list_tile_test.dart`: cover mobile tap/swipe behavior and maximum travel, indicator color and spacing, delete confirmation, and desktop icon actions

---

## [canary-branding]: Give canary builds a separate install identity

- **Scope**: `.github/workflows/build-and-release.yml`, `scripts/`, `assets/`, `lib/core/`, `lib/shared/`, `android/`, `linux/`, `windows/`
- **Type**: feature
- **Status**: active
- **Introduced**: canary-branding
- **Superseded by upstream**: N/A

### What this changes

Brands non-tag CI artifacts as AstralNG Canary and gives them identities that
are separate from production releases. Canary builds use the `astral-canary`
executable and Linux package, Android application ID
`pw.rabit.astralng.canary`, an independent Windows installer and single-instance
mutex, and grayscale-and-gold launcher and tray icons. This allows canary and
production builds to be installed and launched side by side while production
tags preserve the existing names and identifiers.

### Files affected

- `scripts/version.py`, `docs/VERSIONING.md`: resolve and document channel-specific display, executable, package, and installer identities
- `.github/workflows/build-and-release.yml`: pass the build channel into Flutter, generate Linux wrapper and desktop entries from the resolved identity, and package canary artifacts separately
- `lib/core/platform/build_brand.dart`, `lib/core/states/app_settings_state.dart`, `lib/core/platform/window_manager.dart`, `lib/shared/widgets/common/windows_controls.dart`: select canary runtime names and icons at compile time
- `lib/core/services/vpn_manager.dart`: exclude the active channel's Android package from its own VPN
- `scripts/generate_icons.py`, `assets/`, `android/app/src/main/res/mipmap-*`, `windows/runner/resources/`: generate and ship the grayscale-and-gold icon set
- `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`: select the canary application ID, launcher name, and icon
- `linux/CMakeLists.txt`, `linux/runner/`: select the canary executable, GTK application ID, and window name
- `windows/CMakeLists.txt`, `windows/runner/`: select the canary executable, metadata, icon, window title, and single-instance boundary

---

<!-- Add new entries below using the format described in AGENTS.md. -->
