# Versioning

`VERSION` is Astral-ng's single human-edited application version source. It
contains the release `VERSION` and the production `BUILD_NUMBER`.
`pubspec.yaml` is a Flutter-required mirror; it is never an independent version
source.

## Version tool

Use Python 3, which is available on GitHub-hosted Linux and Windows runners and
is supported for local development on every target platform:

```bash
# Linux/macOS
python3 scripts/version.py resolve
python3 scripts/version.py sync --check
python3 scripts/version.py bump patch --dry-run
python3 scripts/version.py bump minor
python3 scripts/version.py bump build

# Windows PowerShell
python scripts/version.py resolve
```

`resolve` defaults to a readable build identity block. Use `--format env` for
optional shell tooling, `--format output` for GitHub step outputs, or
`--format json` for structured tooling. CI reads resolved versions, names, and
artifact retention directly from `steps.resolve-version.outputs.*`; it does not
publish the complete result through `GITHUB_ENV`. Build steps map only
`BUILD_CHANNEL` into their process environment because Gradle and CMake use it
for native canary identity. Packaging steps receive only their own required
values. `sync` updates the Flutter mirror; `sync --check` fails on drift.
`bump major|minor|patch` increments the semantic version and `BUILD_NUMBER`.
`bump build` increments only `BUILD_NUMBER`; use it before every signed RC and
final tag so Android can upgrade through the sequence. Every bump synchronizes
`pubspec.yaml`; review and commit both changed files before tagging.

## Semantic versions

Build stages follow this ordered progression:

```text
3.1.0-alpha.42+abcdef0   # labeled pull-request build
3.1.0-beta.57+1234567    # main-branch build
3.1.0-rc.1               # signed GitHub prerelease
3.1.0                    # signed final release
```

Alpha and beta builds use the GitHub Actions run number for SemVer precedence
and the seven-character commit as non-ordering build metadata. Both retain the
AstralNG Canary application identity. RC and final builds use production
identity and Android signing credentials.

Signed releases are created from either `vMAJOR.MINOR.PATCH-rc.N` or
`vMAJOR.MINOR.PATCH`, and the base version must exactly match `VERSION`. RC
numbers start at 1. GitHub marks RC tags as prereleases and final tags as stable
releases. Example artifacts are:

```text
astral-canary-linux-x64-3.1.0-alpha.42+abcdef0.tar.gz
astral-canary-android-debug-3.1.0-beta.57+1234567.apk
astral-linux-x64-3.1.0-rc.1.tar.gz
astral-linux-x64-3.1.0.tar.gz
```

The `v` prefix belongs only to Git tags; application versions and artifact
suffixes use canonical SemVer without it.

## Native versions

Flutter and operating systems still require numeric transport fields. CI keeps
the release `MAJOR.MINOR.PATCH` as `FLUTTER_BUILD_NAME`, uses the production
`BUILD_NUMBER` for signed RC/final builds, and uses
`1000000000 + GITHUB_RUN_NUMBER` for alpha/beta Android `versionCode` and
corresponding native build fields. Increment `BUILD_NUMBER` before every signed
tag; reusing it prevents Android upgrades from an RC to a later RC or final.

Debian and RPM translate prereleases to values such as
`3.1.0~beta.57+1234567` and `3.1.0~rc.1`, because `~` sorts before the final
`3.1.0`. Final production packages use the base version directly.

## Build channels

Labeled pull-request artifacts are alpha builds; `main` artifacts are beta
builds. Both use the **AstralNG Canary** identity, `astral-canary` executable and
Linux package, Android application ID `pw.rabit.astralng.canary`, independent
Windows installer ID, and grayscale-and-gold icon. They are never attached to a
GitHub Release. Normal preview artifacts are retained for 30 days; successful
merged-PR pushes to `main` retain beta artifacts for 90 days.

RC tags use production identity and signing but publish GitHub prereleases.
Final tags publish stable releases. Signed artifacts are retained for 90 days.

Nix development shells default Flutter build, run, drive, and test commands to
canary. The wrappers derive the seven-character commit from `HEAD` and use local
run number `0`. Prefix a command with `BUILD_CHANNEL=production` when
intentionally validating production identity.
