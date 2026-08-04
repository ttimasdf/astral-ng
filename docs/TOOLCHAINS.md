# Toolchain versions

Astral-ng treats the package versions selected by `flake.nix` and `flake.lock`
as the source of truth. Repository-root files mirror those versions for tools
that do not evaluate Nix.

| Tool | Nix source | Generated consumer file |
| --- | --- | --- |
| Rust | `nixpkgs#rustc` | `rust-toolchain.toml` |
| Flutter | `nixpkgs#flutter344` | `.fvmrc` |
| Java | `nixpkgs#jdk17` | `.java-version` |
| Android SDK/NDK | compatible versions from `nixpkgs#androidenv` | `android/toolchain.properties` |
| cargo-ndk | `nixpkgs#cargo-ndk` | `android/toolchain.properties` |

The lock file fixes the nixpkgs revision and Android artifact definitions. The
flake deliberately selects Android platform 36, Build Tools 35.0.0, CMake
3.22.1, NDK 28.2, and JDK 17 from that locked revision because these versions
match Flutter 3.44 and its current plugins. `pubspec.lock` and `rust/Cargo.lock`
lock project dependencies; they do not select SDKs. Flutter's `.metadata`
records project migration state and is not a toolchain pin.

## Synchronizing consumer files

After changing `flake.nix` or updating `flake.lock`, regenerate every mirror:

```bash
nix run .#sync-toolchains
```

Verify that committed mirrors are current without modifying them:

```bash
nix run .#sync-toolchains -- --check
```

The resolved values are also exposed as package metadata:

```bash
nix eval --json .#packages.x86_64-linux.syncToolchains.passthru.toolchainVersions
```

Do not edit `.fvmrc`, `.java-version`, `rust-toolchain.toml`, or
`android/toolchain.properties` directly. The sync application obtains exact
versions from the evaluated Nix packages and writes deterministic files.

## Local development

Enter the complete Linux development environment with:

```bash
nix develop
```

The shell includes Flutter, Flutter Rust Bridge code generation, Rust and
`rustfmt`, Java, cargo-ndk, protobuf, Python, `jq`, `lnav`, and the Android SDK
composition selected from the current lock, including the compatible platform,
build tools, CMake, and NDK versions. It exports `JAVA_HOME`, `ANDROID_HOME`,
`ANDROID_SDK_ROOT`, and `ANDROID_NDK_ROOT`, supplies Nix's `aapt2` to Gradle,
and writes ignored `android/local.properties` paths for Flutter and Android.
The flake accepts the Android SDK license and enables the unfree Android command
line tools required by this environment.

### Android Flutter commands on NixOS

Use `flutter-android` for commands that target Android from the Nix development
shell. Keep Flutter's normal subcommands and arguments:

```bash
flutter-android run -d <device>
flutter-android test
flutter-android build apk --debug
```

The helper calls the unwrapped Flutter executable with the complete pinned SDK,
removes Linux desktop compiler paths that would contaminate NDK builds, and
configures bindgen separately for every Android ABI used by Cargokit. Commands
that can build Android also stop compatible Gradle daemons first because a
Gradle daemon retains the environment from its initial invocation. Continue to
use plain `flutter` for Linux desktop development.

The helper defaults to the canary application identity and passes that channel
to both Gradle and Dart while leaving all Flutter arguments unchanged. Place an
explicit production override before the Flutter subcommand when needed:

```bash
flutter-android run -d <device>
flutter-android test
flutter-android --astral-channel production build apk --release
```

Run `flutter-android --astral-help` for wrapper options or a command-specific
Flutter help invocation such as `flutter-android run --help`. The helper warns
when less than 30 GiB is free but never removes generated output automatically;
use `flutter-android clean` when discarding incremental build artifacts is
intentional.

`eachDefaultSystem` keeps development-shell and synchronization outputs
available on the standard Linux and macOS systems. Linux-only GUI dependencies
are added conditionally. The packaged `astral-ng` derivation remains Linux-only
because nixpkgs' `buildFlutterApplication` currently states that it has no macOS
support; macOS application builds continue to use Flutter and Xcode from the
Darwin development shell rather than claiming unsupported Nix package metadata.

Outside Nix, FVM and rustup consume their generated files normally:

```bash
fvm install
fvm flutter pub get
```

## CI

`.github/actions/setup-toolchains` always installs mirrored Rust and Flutter.
Its Android setup is opt-in:

```yaml
- uses: ./.github/actions/setup-toolchains
  with:
    setup-android: 'true'
```

That option additionally installs the mirrored Java major, Android platform,
build tools, CMake, NDK, Rust Android targets, and cargo-ndk. Other jobs avoid the
Android setup cost.

## Updating a toolchain

1. Update `flake.lock`, or change the package selection in `flake.nix` when an
   intentional channel or package-family change is required.
2. Run `nix run .#sync-toolchains` and review every generated mirror.
3. Regenerate dependency lock files only when the SDK upgrade requires it.
4. Run `nix run .#sync-toolchains -- --check`, `nix build .#astral-ng`,
   application analysis, and the relevant local platform build.
5. Open a pull request with the `full-ci` label to validate Linux, Windows, and
   Android before merging.

Keep toolchain upgrades isolated and reviewable instead of allowing unrelated CI
or dependency changes to select a new SDK implicitly.
