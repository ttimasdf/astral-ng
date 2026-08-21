# Continuous Integration

Read this guide before running final checks, pushing a feature branch, or
creating a pull request.

## Pull request CI

Every pull request runs the shared `test` job. Platform build jobs are selected
by changed paths, with labels available as explicit overrides:

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
beta canary artifacts for the update API. Manual dispatch runs platform builds
without uploading artifacts. Signed RC and final tags use `release.yml`.

## PR update API previews

The Vercel project has automatic Git deployments disabled. A labeled, trusted
same-repository pull request runs the `preview-update-api` job in the protected
`Preview` environment only when it changes `update-server/**`. The job fetches
project settings through Vercel's project-scoped REST API, builds from the
repository root, deploys the prebuilt server with the Vercel CLI, and verifies
the preview endpoint. It passes the exact preview URL to labeled platform builds
through `UPDATE_API_BASE_URL`. Other pull requests use the configured base URL
(the production API by default).

Configure the Vercel project-scoped credentials as environment-scoped GitHub
values. Obtain `orgId` and `projectId` from `update-server/.vercel/project.json`
after running `vercel link --cwd update-server` locally, then create a
project-scoped Vercel token using the Vercel dashboard or:

```bash
vercel tokens add "AstralNG GitHub Preview" --project <project-id>
```

Store the token only as the `Preview` environment secret, and store the
identifiers as `Preview` environment variables:

```bash
gh secret set VERCEL_TOKEN --env Preview
printf '%s' '<org-id>' | gh variable set VERCEL_ORG_ID --env Preview
printf '%s' '<project-id>' | gh variable set VERCEL_PROJECT_ID --env Preview
```

The Vercel token owner must have project Developer access, and the token should
be scoped to this project. The workflow intentionally bypasses `vercel pull`,
which currently fails with project-scoped tokens, and obtains only that
project's settings and Preview environment before `vercel build`. It sets
`VERCEL_TELEMETRY_DISABLED=1` for Vercel CLI invocations.

Preview Deployment Protection must remain disabled because compiled clients
call the deployment without credentials. Keep GitHub Actions and Vercel runtime
credentials separate: the Vercel Preview environment needs its own read-only
`GITHUB_TOKEN` for the update API’s GitHub queries.

## Release credential boundary

Build validation lives in `.github/workflows/build.yml`. It runs on pull
requests, `main`, and manual dispatches, and has read-only repository
permissions. Its platform jobs call the shared composite actions under
`.github/actions/build-*`; it does not reference signing secrets.

Release work lives in `.github/workflows/release.yml`, which accepts canonical
`vMAJOR.MINOR.PATCH-rc.N` and `vMAJOR.MINOR.PATCH` tag pushes and calls the same
shared platform actions. RC tags publish GitHub prereleases; final tags publish
stable releases. Increment and commit `BUILD_NUMBER` before every signed tag so
installed RC builds can upgrade to later candidates and the final release.

The Android signing job is attached to the protected GitHub Environment named
`Production`. Both `Preview` and `Production` require approval from `ttimasdf`;
administrator bypass is disabled. `Preview` permits ordinary branch refs and
GitHub's `refs/pull/*/merge` refs because the workflow applies the
trusted-author and `platform-*` label gates. `Production` accepts only release
tags (`v*`). Configure signing secrets in `Production`,
not `Preview` or repository-level Actions secrets:

```bash
gh secret set KEYSTORE_BASE64 --env Production < upload-keystore.base64
printf '%s' '<alias>' | gh secret set KEY_ALIAS --env Production
printf '%s' '<store-password>' | gh secret set STORE_PASSWORD --env Production
printf '%s' '<key-password>' | gh secret set KEY_PASSWORD --env Production
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
