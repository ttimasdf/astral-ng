# Toolchain versions

Astral-ng treats the package versions selected by `flake.nix` and `flake.lock`
as the source of truth. Repository-root files mirror those versions for tools
that do not evaluate Nix.

| Tool | Nix source | Generated consumer file |
| --- | --- | --- |
| Rust | `nixpkgs#rustc` | `rust-toolchain.toml` |
| Flutter | `nixpkgs#flutter344` | `.fvmrc` |
| Java | `nixpkgs#jdk` | `.java-version` |
| Android SDK/NDK | `nixpkgs#androidenv` defaults | `android/toolchain.properties` |
| cargo-ndk | `nixpkgs#cargo-ndk` | `android/toolchain.properties` |

The lock file fixes the nixpkgs revision, so moving package aliases such as the
Android environment's `latest` selection resolve reproducibly for a given
checkout. `pubspec.lock` and `rust/Cargo.lock` lock project dependencies; they
do not select SDKs. Flutter's `.metadata` records project migration state and
is not a toolchain pin.

## Synchronizing consumer files

After changing `flake.nix` or updating `flake.lock`, regenerate every mirror:

```bash
nix run .#sync-toolchains
```

Verify that committed mirrors are current without modifying them:

```bash
nix run .#sync-toolchains -- --check
```

Do not edit `.fvmrc`, `.java-version`, `rust-toolchain.toml`, or
`android/toolchain.properties` directly. The sync application obtains exact
versions from the evaluated Nix packages and writes deterministic files.

## Local development

Enter the complete Linux development environment with:

```bash
nix develop
```

The shell includes Flutter, Rust, Java, cargo-ndk, protobuf, and the Android SDK
composition selected by the current lock, including its default platform,
build tools, and NDK. It exports `JAVA_HOME`, `ANDROID_HOME`,
`ANDROID_SDK_ROOT`, and `ANDROID_NDK_ROOT`, supplies Nix's `aapt2` to Gradle,
and writes ignored `android/local.properties` paths for Flutter and Android.
The flake accepts the Android SDK license and enables the unfree Android command
line tools required by this environment.

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
build tools, NDK, Rust Android targets, and cargo-ndk. Other jobs avoid the
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
