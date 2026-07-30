# Versioning

`VERSION` is Astral-ng's single human-edited application version source. It has
one release version (`VERSION`) and one production build number
(`BUILD_NUMBER`). `pubspec.yaml` mirrors these values because Flutter requires
them; verify it with:

```bash
./scripts/sync-version.sh --check
```

After changing `VERSION`, synchronize the mirror with `./scripts/sync-version.sh`
and commit both files.

Production releases are created only from a `vMAJOR.MINOR.PATCH` tag whose
version exactly matches `VERSION`. CI passes that version and `BUILD_NUMBER` to
Flutter and uses the derived package version for Linux and Windows packages.

All branch and pull-request CI builds are canaries. They retain the release
marketing version for native platform compatibility, but use a unique Android/
Apple build number (`1000000000 + GITHUB_RUN_NUMBER`) and an artifact label such
as `v2.8.7-canary.42-abc123`. The in-app version dialog identifies these builds
as canaries. Canary artifacts are never attached to a GitHub Release.
