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

# Windows PowerShell
python scripts/version.py resolve
```

`resolve` defaults to a readable build identity block. Use `--format env` for
CI or `--format json` for tooling. `sync` updates the Flutter mirror;
`sync --check` fails on drift. `bump major|minor|patch` increments the semantic
version, increments `BUILD_NUMBER`, and synchronizes `pubspec.yaml`. Review and
commit the resulting two files.

## Semantic versions

Production uses the release SemVer without a prefix or build metadata:

```text
3.0.0
```

Canary artifacts use an ordered prerelease identifier and a seven-character Git
commit as build metadata:

```text
3.0.0-alpha.42+abcdef0
```

The CI run number gives canaries SemVer precedence. The commit metadata
identifies the exact source but does not affect precedence. The About hero uses
the compact `3.0.0 Canary abcdef0` form, while its installed-version row uses
`3.0.0-alpha+abcdef0`. Support bundles and update comparison use the full
ordered SemVer.

Production releases are created only from a `vMAJOR.MINOR.PATCH` Git tag whose
version exactly matches `VERSION`. The tag retains the conventional `v` prefix;
version values and artifact suffixes do not. Example files are:

```text
astral-linux-x64-3.0.0.tar.gz
astral-canary-linux-x64-3.0.0-alpha.42+abcdef0.tar.gz
astral-canary-android-debug-3.0.0-alpha.42+abcdef0.apk
```

This replaces the historical `v3.0.0-canary.42-abcdef0` and `v3.0.0` artifact
suffixes. Automation that downloads exact filenames must use the canonical
SemVer suffixes above.

## Native versions

Flutter and operating systems still require numeric transport fields. CI keeps
the release `MAJOR.MINOR.PATCH` as `FLUTTER_BUILD_NAME`, uses the production
`BUILD_NUMBER` for releases, and uses `1000000000 + GITHUB_RUN_NUMBER` for
canary Android `versionCode` and equivalent native build fields. These numeric
values preserve installation and upgrade behavior; they are not displayed as
the application version.

Debian and RPM translate canary prereleases to
`3.0.0~alpha.42+abcdef0`, because those package managers use `~` to sort a
prerelease before `3.0.0`. Production package versions and the Nix package use
`3.0.0` directly.

## Build channels

All branch and pull-request CI builds are canaries. Canary artifacts are never
attached to a GitHub Release. Successful `main` pushes whose commit subject ends
in a merged-pull-request suffix such as `(#42)` retain their Actions artifacts
for 90 days; direct pushes and pull-request builds retain them for 7 days. They
use the **AstralNG Canary** identity,
`astral-canary` executable and Linux package name, Android application ID
`pw.rabit.astralng.canary`, an independent Windows installer ID, and the
grayscale-and-gold canary icon. Production tags retain the `AstralNG`, `astral`,
and `pw.rabit.astralng` identities.

Nix development shells default Flutter build, run, drive, and test commands to
canary. The wrappers derive the seven-character commit from `HEAD` and use local
run number `0`. Prefix a command with `BUILD_CHANNEL=production` when
intentionally validating production identity.
