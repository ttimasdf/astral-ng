# Changelog

## v2.8.0 (2026-03-17)

### Features
- Add connect/disconnect action to tray right-click menu
- Set up Nix flake for reproducible development environment

### Bug Fixes
- Handle `ConfigPatched` and `ProxyCidrsUpdated` Rust events instead of panicking

### Changes
- Rebrand GUI from Astral to Astral-ng
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
- Merge upstream changes from ldoubil/astral
