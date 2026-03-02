# Astral

English | [中文](README.md)

> Built upon the original work by [ldoubil](https://github.com/ldoubil). Huge thanks to the original author for laying the groundwork that made this project possible.

Astral is a cross-platform P2P networking and VPN application built on [EasyTier](https://github.com/EasyTier/EasyTier), with a Flutter frontend and Rust backend.

## Features

- P2P peer-to-peer networking
- VPN service
- Cross-platform: Windows, macOS, Linux, Android, iOS
- Multi-language support (Chinese, English, Japanese, Korean, French, German, Spanish, Russian)

## Use Cases

- Build a virtual LAN across remote devices for accessing home/office networks
- Multiplayer gaming without public IPs or port forwarding
- Remote development and debugging with secure access to internal services
- Cross-platform file sharing and collaboration between devices

## Development Setup

### Using Nix (Recommended)

```bash
nix develop
```

### Manual Setup

Requirements:
- Flutter SDK 3.7+
- Rust (beta channel)
- protobuf compiler
- Platform-specific dependencies (webkitgtk and libayatana-appindicator on Linux)

## Build & Run

```bash
# Install dependencies
flutter pub get

# Code generation
dart run build_runner build --delete-conflicting-outputs

# Run (desktop)
flutter run -d linux    # or windows, macos

# Run (mobile)
flutter run -d android
flutter run -d ios

# Production builds
flutter build linux
flutter build windows
flutter build apk --split-per-abi
flutter build ios
```

### Rust Backend

```bash
cd rust
cargo build
cargo test
```

## Tech Stack

- Frontend: Flutter + signals_flutter (state management) + Isar (local database)
- Backend: Rust + EasyTier
- Bridge: flutter_rust_bridge

## License

[GPLv3](LICENSE)
