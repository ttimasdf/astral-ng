# Continuous Integration

Read this guide before running final checks, pushing a feature branch, or
creating a pull request.

## Build CI

Every pull request and every push to `main` runs the shared `test` job. Platform
build jobs are selected by changed paths, with labels available as explicit
pull-request overrides. Main-branch beta artifacts are therefore produced only
when application or platform paths require them:

- Linux changes (`linux/**`, Linux packaging, or its build action) run Linux.
- Windows changes (`windows/**`, Windows packaging, DLLs, or its build action)
  run Windows.
- Android changes (`android/**` or its build action) run Android.
- Shared application, dependency, toolchain, or CI-action changes run all three.
- `platform-linux`, `platform-windows`, `platform-android`, and `platform-all`
  force the corresponding build(s), regardless of changed paths.

Use the pull request's **Labels** control in the GitHub sidebar, or run:

```bash
gh pr edit <number> --add-label platform-all
```

Remove labels when the explicit override is no longer needed:

```bash
gh pr edit <number> --remove-label platform-all
```

Labeled pull requests upload alpha canary artifacts; pushes to `main` upload
beta canary artifacts for the update API only when the selected platform jobs
run. Update-server-only and documentation-only main pushes run tests without
creating beta artifacts. Manual dispatch runs all platform builds without
uploading artifacts. Signed RC and final tags use `release.yml`.

## Update API deployments

The update API deploys through the Vercel Git integration, not GitHub Actions.
The Vercel project builds `update-server/` on every push to `main`
(Production) and creates Preview deployments for pull requests that change
`update-server/**`. No GitHub Actions workflow deploys the update API, and no
deployment environment approval gates it.

### Vercel project setup

Create the Vercel project from this repository, then configure it in the
project dashboard. Under **Settings → Build and Deployment**:

- **Framework Preset:** `Other`. The checked-in `update-server/vercel.json`
  also disables framework auto-detection.
- **Root Directory:** `update-server/`.
- **Ignored Build Step:** select *Custom* and enter the following command:

  ```bash
  bash scripts/vercel-build-check.sh
  ```

  Vercel runs the command from the Root Directory, and the script derives
  `update-server/` from its own location. Exit code 0 skips the build; any
  other exit code continues it. The script decides as follows:

  - `VERCEL_ENV` is `production` and the pushed branch is not the default
    branch (`main`): error and cancel the deployment.
  - `VERCEL_GIT_PREVIOUS_SHA` is empty (first deployment): warn and build.
  - `VERCEL_GIT_PREVIOUS_SHA` is unusable on a production deployment (invalid
    or missing from the shallow clone): warn and build, because the changed
    paths cannot be determined.
  - `VERCEL_GIT_PREVIOUS_SHA` is unusable on any other deployment: warn, fall
    back to diffing against `main` (fetching it with `--depth=1` when the
    shallow clone lacks it), and build if `main` cannot be resolved.
  - Otherwise: diff `update-server/` between the previous and pushed commits,
    covering every commit in a multi-commit push. A clean diff (exit 0) skips
    the build; changes (exit 1) continue it. A diff error also continues the
    build, so the deployment never fails closed.

  The script replaces an earlier inline command that crashed with
  `fatal: bad object` when the shallow clone did not contain
  `VERCEL_GIT_PREVIOUS_SHA`, as happened on the v3.0.0 release push.
- **Deployment Retention:** canceled deployments `1 day`, errored deployments
  `1 week`, pre-production deployments `2 weeks`, production deployments
  `30 days`.

Then under **Settings → Git**, enable pull request comments and commit
comments so deployment URLs are posted where changes originate, and enable
**Require Verified Commits** so Vercel only builds commits whose signatures
GitHub has verified.

Keep Vercel Deployment Protection disabled because compiled clients call the
API without credentials. Configure the runtime variables (including
`GITHUB_TOKEN`) in the Vercel project dashboard for Production and Preview;
see `docs/UPDATE_API.md` for the full variable list and deployment details.

## Release credential boundary

Build validation lives in `.github/workflows/build.yml`. It runs on pull
requests, `main`, and manual dispatches, and has read-only repository
permissions. Its platform jobs call the shared composite actions under
`.github/actions/build-*`; it does not reference signing secrets.

Release work lives in `.github/workflows/release.yml`, which accepts canonical
`vMAJOR.MINOR.PATCH-rc.N` and `vMAJOR.MINOR.PATCH` tag pushes and calls the same
shared platform actions. RC tags publish GitHub prereleases; final tags publish
stable releases. Release notes are reflowed at publication time so source
line wrapping does not become visible as extra breaks in GitHub Releases; Markdown block
structure, code blocks, and reference links are preserved. Increment and
commit `BUILD_NUMBER` before every signed tag so installed RC builds can
upgrade to later candidates and the final release.

The Android signing job is attached to the protected `Production Signing`
GitHub Environment; it is the only GitHub Environment the workflows use.
Administrator bypass is disabled for `Production Signing`, which accepts only
release tags. Configure signing secrets in `Production Signing`, not
repository-level Actions secrets:

```bash
gh secret set ANDROID_KEYSTORE_BASE64 --env 'Production Signing' < upload-keystore.base64
printf '%s' '<alias>' | gh secret set ANDROID_KEY_ALIAS --env 'Production Signing'
printf '%s' '<store-password>' | gh secret set ANDROID_STORE_PASSWORD --env 'Production Signing'
printf '%s' '<key-password>' | gh secret set ANDROID_KEY_PASSWORD --env 'Production Signing'
```

Also protect `v*` tags in
the repository ruleset so only authorized release maintainers can create or
move a tag. The release publication job alone receives `contents: write`; all
other jobs use read-only contents permissions.

## Waiting for CI

GitHub-hosted runner timing measured on PR #6 provides these planning estimates:

| CI path | Approximate wall time | Agent timeout |
|---------|-----------------------|---------------|
| Normal pull request (tests) | 8 minutes | 1,200 seconds (20 minutes) |
| Pull request with `platform-all` | 24 minutes | 2,400 seconds (40 minutes) |
| `v*` tag release | Not yet measured | 3,600 seconds (60 minutes) |

Poll every 30 seconds by default; 30–60 seconds is appropriate for long-running
builds. The timeout margins cover runner queues, cold caches, and normal build
variance. Set `RUN_ID` to the Actions workflow run ID and use this bounded loop:

```bash
run_id="${RUN_ID:?set RUN_ID to the GitHub Actions workflow run ID}"
repo="${GH_REPO:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
poll_seconds="${CI_WAIT_POLL_SECONDS:-30}"
timeout "${CI_WAIT_TIMEOUT_SECONDS:-2400}" bash -c '
while [[ "$(gh run view "$1" -R "$2" --json status --jq .status)" != completed ]]; do
  sleep "$3"
done
gh run view "$1" -R "$2" --exit-status
' _ "$run_id" "$repo" "$poll_seconds"
```

Use `CI_WAIT_TIMEOUT_SECONDS=1200` for normal pull request runs and the
2,400-second default for `platform-all`. A timeout exits 124; a failed run
exits nonzero. After completion, inspect failures with:

```bash
gh run view "$RUN_ID" --log-failed
```

Download artifacts with:

```bash
gh run download "$RUN_ID" --dir <directory>
```
