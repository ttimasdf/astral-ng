# Toolchain versions

Astral-ng pins build toolchains in repository-root, tool-native files so local
development, Nix, and CI use the same releases.

| Tool | Source of truth |
| --- | --- |
| Rust | `rust-toolchain.toml` |
| Flutter | `.fvmrc` |
| Nix package set | `flake.lock` |
| Gradle | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin and Kotlin | `android/settings.gradle.kts` |
| Android NDK | `android/app/build.gradle.kts` |

`pubspec.lock` and `rust/Cargo.lock` lock project dependencies; they do not pin
the Flutter or Rust SDK. Flutter's `.metadata` records project migration state
and is not a toolchain pin.

## Using the pins

The recommended development environment is:

```bash
nix develop
```

The flake reads `rust-toolchain.toml` and checks that its Flutter package agrees
with `.fvmrc`. Outside Nix, install Rust with rustup and Flutter with FVM. Rustup
selects `rust-toolchain.toml` automatically, while FVM uses `.fvmrc`:

```bash
fvm install
fvm flutter pub get
```

GitHub Actions uses `.github/actions/setup-toolchains`, which reads both files.
Do not put SDK versions directly in workflow files or use moving values such as
`stable`, `beta`, or `latest` for release-producing builds.

## Updating a toolchain

1. Change the appropriate root pin.
2. For Flutter, update `flake.lock` only if the pinned nixpkgs revision does not
   provide the requested version. The flake evaluation deliberately fails on a
   mismatch.
3. Regenerate dependency lock files only when the SDK upgrade requires it.
4. Run `nix build .#astral-ng`, application analysis, and a Linux build locally.
5. Open a pull request with the `full-ci` label to validate Linux, Windows, and
   Android before merging.

Toolchain upgrades should be isolated, reviewable changes rather than incidental
side effects of unrelated CI or dependency updates.
