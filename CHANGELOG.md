# Changelog

## v2.8.0 (2026-03-25)

### Features
- Add connect/disconnect action to tray right-click menu
- Set up Nix flake for reproducible development environment
- Add package.nix for NixOS integration

### Bug Fixes
- Handle `ConfigPatched` and `ProxyCidrsUpdated` Rust events instead of panicking
- Stop ConnectButton animation when idle, fixing 40% CPU usage when window is active
- Fix Windows build link search path for Packet.lib

### Changes
- **Rebrand**: GUI now displays as "Astral-ng" (not "Astral")
- Change app identifier to `pw.rabit.astralng`
- Replace app icon with new design across all platforms
- Replace vendored EasyTier with git submodule at v2.5.0
- Switch Flutter package source to pub.dev
- Remove hardcoded servers from blocklist
- Remove Linux root privilege check — the app no longer requires running as root,
  but **TUN mode requires `cap_net_admin`** to be granted to the binary or it will
  silently fail to create the TUN interface. Run once after install:
  ```
  sudo setcap cap_net_admin=eip /path/to/astral
  ```
- Temporarily disable HitokotoCard widget
- Replace `.gitignore` with comprehensive generated template
- Change license from CC-BY-NC-ND 4.0 to GPL-3.0
- Add Chinese and English README with author credit and use cases
- Remove Google services from Android build
- **CI/Build Improvements**:
  - Merge 11 workflow files into unified `ci.yml` and `release.yml`
  - Switch to `flutter-actions/setup-flutter@v4` with caching
  - Add Rust cache workspace mapping
  - Remove Linux arm64 build (Flutter does not support Linux ARM64)
  - Add cross-compilation system dependencies
  - Create `third_party` symlink for EasyTier Windows build
  - Replace bash `mkdir -p` with PowerShell `New-Item` for Windows builds
  - Update Windows installer metadata

### Upstream Merge
- Merge latest changes from ldoubil/astral (v2.7.2/v2.7.3), including:
  - Network topology improvements (layout, legend, dense mode)
  - Update system enhancements (configurable mirrors, timeouts)
  - Server connection manager error handling improvements
  - Windows faketcp fixes

## v2.7.3 (2025-xx-xx)

*No changelog available for v2.7.3. See git history for details.*

## v2.7.2 (2025-xx-xx)

*No changelog available for v2.7.2. See git history for details.*

## v2.7.1 (2025-xx-xx)

*No changelog available for v2.7.1. See git history for details.*

## v2.7.0 (2025-xx-xx)

*No changelog available for v2.7.0. See git history for details.*
