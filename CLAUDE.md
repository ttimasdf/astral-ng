# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Astral is a cross-platform P2P networking and VPN application built with Flutter (frontend) and Rust (backend). It provides simple P2P network connections and VPN services based on EasyTier, supporting Windows, macOS, Linux, Android, and iOS.

## Development Environment

### Setup with Nix (Recommended)
```bash
nix develop  # Enter development shell with all dependencies
```

The flake provides: Flutter, Rust (beta channel), protobuf, webkitgtk, and libayatana-appindicator.

### Manual Setup
Install dependencies:
- Flutter SDK 3.7+
- Rust (beta channel recommended)
- protobuf compiler
- Platform-specific dependencies (webkitgtk on Linux, etc.)

## Common Commands

### Flutter Development
```bash
# Get dependencies
flutter pub get

# Run code generation (for Isar, JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# Run the app (desktop)
flutter run -d linux    # or windows, macos
flutter run -d android  # for Android
flutter run -d ios      # for iOS

# Run tests
flutter test

# Run integration tests
flutter test integration_test/

# Analyze code
flutter analyze

# Format code
dart format .
```

### Rust Development
```bash
# Build Rust library
cd rust
cargo build

# Run Rust tests
cargo test

# Generate Flutter-Rust bridge bindings
flutter_rust_bridge_codegen generate
```

### Build for Production
```bash
# Linux
flutter build linux

# Windows
flutter build windows

# Android (multiple architectures)
flutter build apk --split-per-abi  # arm64, armv7, x86_64

# iOS
flutter build ios
```

## Architecture

Astral uses a **Features-based Architecture** with clean separation of concerns. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed documentation.

### Directory Structure
- `lib/features/` - Business feature modules (home, rooms, explore, settings, etc.)
  - Each feature contains `pages/` and `widgets/` subdirectories
  - Features should be independent and communicate through core services
- `lib/shared/` - Cross-module reusable components
  - `models/` - Shared data models
  - `utils/` - Utility functions (data, dialogs, helpers, network, ui)
  - `widgets/` - Reusable UI components (cards, common, navigation)
- `lib/core/` - Core architecture layer
  - `constants/` - App-wide constants
  - `models/` - Core data models
  - `repositories/` - Data access layer (Isar database, API)
  - `services/` - Business logic layer
  - `states/` - Reactive state management (signals_flutter)
  - `ui/` - Base UI classes (e.g., BaseSettingsPage)
- `lib/screens/` - Legacy screens (being migrated to features/)
- `lib/services/` - App-level services (app_links, etc.)
- `lib/src/rust/` - Auto-generated Rust FFI bindings
- `rust/` - Rust backend code
  - `easytier/` - EasyTier P2P networking library (git submodule)
  - Main crate: `rust_lib_astral`

### Key Architectural Patterns

1. **Service Manager**: Singleton at `lib/core/services/service_manager.dart` manages all services, states, and repositories
2. **State Management**: Uses `signals_flutter` for reactive state
3. **Data Layer**: Isar Community database for local persistence
4. **FFI Bridge**: flutter_rust_bridge connects Flutter UI to Rust backend
5. **Dependency Flow**: Features → Shared → Core (unidirectional)

### Base Classes
- `BaseSettingsPage` / `BaseStatefulSettingsPage` - Base classes for settings pages with consistent UI structure
- Helper methods: `buildSettingsCard()`, `buildDivider()`, `buildEmptyState()`

## Code Conventions

### Naming
- Files: snake_case (e.g., `user_page.dart`)
- Classes: PascalCase (e.g., `UserPage`)
- Variables: camelCase (e.g., `userName`)

### Import Paths
- Use absolute imports: `package:astral/features/...`
- Avoid relative imports

### Module Organization
- Feature-specific components go in `features/{module}/widgets/`
- Cross-module components go in `shared/widgets/`
- Business logic goes in `core/services/`
- Features should not directly depend on each other (communicate via core)

## Internationalization

Translation files are in `assets/translations/` with support for:
- Chinese (zh), English (en), German (de), Spanish (es)
- French (fr), Japanese (ja), Korean (ko), Russian (ru)

Uses `easy_localization` package. Generated keys are in `lib/generated/locale_keys.g.dart`.

## Platform-Specific Notes

### Android
- VPN service plugin: `vpn_service_plugin/`
- Requires VPN permissions in AndroidManifest.xml

### Linux
- Requires webkitgtk and libayatana-appindicator
- AppImage packaging config: `linux/packaging/appimage/make_config.yaml`

### Windows
- Uses Windows Firewall and networking APIs
- Inno Setup script: `1.iss`

## CI/CD

GitHub Actions workflows in `.github/workflows/`:
- Platform-specific builds: `linux-build.yaml`, `windows-build.yml`, `android-build-*.yaml`
- Multi-platform: `build-all-platforms.yaml`
- Dart analysis: `dart.yml`

## License

GPLv3 - This project is licensed under the GNU General Public License v3.0. You are free to use, modify, and distribute this software under the terms of the GPLv3 license. See the [LICENSE](LICENSE) file for details.

Original author: [ldoubil](https://github.com/ldoubil)
