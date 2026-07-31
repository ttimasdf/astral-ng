# Continuous Integration

Read this guide before running final checks, pushing a feature branch, or
creating a pull request.

## Pull request CI

CI opt-in labels are applied to pull requests, not individual commits. A normal
pull request runs application analysis and the Linux build only. Add the
`full-ci` label to immediately include Windows and Android validation. The label
persists on the pull request, so later commits continue to run all platforms
until the label is removed.

Use the pull request's **Labels** control in the GitHub sidebar, or run:

```bash
gh pr edit <number> --add-label full-ci
```

Remove the label when full-platform validation is no longer needed:

```bash
gh pr edit <number> --remove-label full-ci
```

## Waiting for CI

GitHub-hosted runner timing measured on PR #6 provides these planning estimates:

| CI path | Approximate wall time | Agent timeout |
|---------|-----------------------|---------------|
| Normal pull request (analysis + Linux) | 8 minutes | 1,200 seconds (20 minutes) |
| Pull request with `full-ci` | 24 minutes | 2,400 seconds (40 minutes) |
| `v*` tag release | Not yet measured | 3,600 seconds (60 minutes) |

Poll every 30 seconds by default; 30–60 seconds is appropriate for long-running
builds. The timeout margins cover runner queues, cold caches, and normal build
variance. Set `RUN_ID` to the Actions workflow run ID and use this bounded loop:

```bash
run_id="${RUN_ID:?set RUN_ID to the Actions workflow run ID}"
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
2,400-second default for `full-ci`. A timeout exits 124; a failed run exits
nonzero. After completion, inspect failures with:

```bash
gh run view "$RUN_ID" --log-failed
```

Download artifacts with:

```bash
gh run download "$RUN_ID" --dir <directory>
```

Add `--name <artifact>` to select one artifact.
