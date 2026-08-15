# Continuous Integration

Read this guide before running final checks, pushing a feature branch, or
creating a pull request.

## Pull request CI

Every pull request runs the shared `test` job. Platform build jobs are opt-in
through labels applied to the pull request:

- `platform-linux`: Linux build and artifacts
- `platform-windows`: Windows build and artifacts
- `platform-android`: Android build and artifacts
- `platform-all`: all three platform builds and artifacts

Use the pull request's **Labels** control in the GitHub sidebar, or run:

```bash
gh pr edit <number> --add-label platform-all
```

For a single platform, add the corresponding `platform-*` label instead. Remove
labels when platform validation is no longer needed:

```bash
gh pr edit <number> --remove-label platform-all
```

Pushes to `main` continue to build and retain canary artifacts for the update
API. Manual dispatch runs platform builds without uploading artifacts. Release
tags use the separate `release.yml` workflow.

## Release credential boundary

Build validation lives in `.github/workflows/build.yml`. It runs on pull
requests, `main`, and manual dispatches, and has read-only repository
permissions. Its platform jobs call the shared composite actions under
`.github/actions/build-*`; it does not reference signing secrets.

Release work lives in `.github/workflows/release.yml`, which triggers only for
`v*` tag pushes and calls the same shared platform actions. The Android signing
job is attached to the protected GitHub Environment named `production`; put
these values in that environment, not in repository-level Actions secrets:

- `KEYSTORE_BASE64`
- `KEY_ALIAS`
- `STORE_PASSWORD`
- `KEY_PASSWORD`

Configure required reviewers for the `production` environment and restrict its
deployment branch/tag policy to release tags (`v*`). Also protect `v*` tags in
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
