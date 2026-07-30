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

`resolve` defaults to a readable build identity block. Use
`--format env` for CI or `--format json` for tooling. `sync` updates the Flutter
mirror; `sync --check` fails on drift. `bump major|minor|patch` increments the
semantic version, increments `BUILD_NUMBER`, and synchronizes `pubspec.yaml`.
Review and commit the resulting two files.

## Release and canary builds

Production releases are created only from a `vMAJOR.MINOR.PATCH` tag whose
version exactly matches `VERSION`. CI passes that version and `BUILD_NUMBER` to
Flutter and uses the derived package version for Linux and Windows packages.

All branch and pull-request CI builds are canaries. They retain the numeric
release marketing version for native platform compatibility, but use a unique
Android/Apple build number (`1000000000 + GITHUB_RUN_NUMBER`) and an artifact
label such as `v2.8.7-canary.42-abc123`. CI logs the full resolved identity,
including source version, channel, build number, package version, artifact
label, Git ref, and commit. Canary artifacts are never attached to a GitHub
Release.
