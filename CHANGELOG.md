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

## v2.7.3 (2026-03-01)

### Features
- Add TLS 1.2 support for wss connections ([ldoubil/astral#209](https://github.com/ldoubil/astral/pull/209))

### Bug Fixes
- Fix Windows faketcp connection failure ([ldoubil/astral#208](https://github.com/ldoubil/astral/pull/208))
- Improve Windows faketcp fallback filter parameters and error messages
- Use interface name in faketcp fallback

### Changes
- Lower Linux build platform to support Ubuntu 22 x86 ([ldoubil/astral#203](https://github.com/ldoubil/astral/pull/203))
- Untrack build artifacts (1 and 1.iss) ([ldoubil/astral#205](https://github.com/ldoubil/astral/pull/205))
- Merge upstream changes from ldoubil/astral

## v2.7.2 (2026-03-01)

*No significant fork-specific changes. See upstream ldoubil/astral changelog.*

## v2.7.1 (2026-02-12)

### Features
- Set up Nix flake for reproducible development environment ([ldoubil/astral#204](https://github.com/ldoubil/astral/pull/204))

### Changes
- Lower Linux build platform to support Ubuntu 22 x86
- Untrack build artifacts (1 and 1.iss)

## v2.7.0 (2026-02-08)

### Features
- Network topology visualization and connection management
- Add TCP and UDP port whitelist configuration
- Add TCP hole punching configuration options
- Enhance network topology with layout, legend, and dense mode options

### Changes
- Update Isar library to version 3.3.0
- Update multiple dependency packages for stability and performance
- Remove network configuration flag from room model, optimize share link generation
- Use untracked instead of WidgetsBinding to optimize signal state updates
