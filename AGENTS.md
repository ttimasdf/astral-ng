# AGENTS.md

Guidance for AI coding agents working in this repository. For project-level
developer documentation, see `CLAUDE.md`.

---

## Feature Development Workflow

When instructed to implement a new feature, use the following workflow:

1. Choose a short, stable, kebab-case slug that identifies the feature.
2. Create a feature branch named `feature/<slug>` and a linked worktree at
   `.worktrees/<slug>` (for example,
   `git worktree add -b feature/<slug> .worktrees/<slug>`).
3. Make all feature changes in that worktree. Commit focused, reviewable units
   of work along the way instead of leaving the implementation uncommitted.
4. Add or update the corresponding `DOWNSTREAM_CHANGES.md` entry before the
   feature is considered complete, using the same slug.
5. Run the relevant checks, push the feature branch, and create a pull request.
   The pull request title must begin with `[<slug>]` so the slug is retained in
   the squash commit message (for example, `[tray-status-icons] Add tray status
   indicators`).
6. Merge a pull request only after the user explicitly approves the merge. Once
   authorized, use `/merge-pr [PR-number-or-URL]`; the prompt contains the merge
   and cleanup workflow.

### Pull request CI

CI opt-in labels are applied to pull requests, not individual commits. A normal
pull request runs application analysis and the Linux build only. Add the
`full-ci` label to immediately include Windows and Android validation; the label
persists on the pull request, so later commits continue to run all platforms
until the label is removed.

Use the pull request's **Labels** control in the GitHub sidebar, or run
`gh pr edit <number> --add-label full-ci`. Remove it with
`gh pr edit <number> --remove-label full-ci` when full-platform validation is no
longer needed.

### Waiting for CI

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

Use `CI_WAIT_TIMEOUT_SECONDS=1200` for normal PR runs and the 2,400-second
default for `full-ci`. A timeout exits 124; a failed run exits nonzero. After
completion, inspect failures with `gh run view "$RUN_ID" --log-failed` or
download artifacts with `gh run download "$RUN_ID" --dir <directory>` (add
`--name <artifact>` to select one).

## Changelog Maintenance

Follow `docs/CHANGELOG_GUIDELINES.md` whenever a change affects users,
integrators, supported platforms, or release artifacts. Add the entry to
`CHANGELOG.md` under `Unreleased` in the same pull request as
the change; do not generate entries mechanically from commit subjects.

Keep the changelog concise and user-facing, with links or a short `Developer
notes` section for implementation provenance. Every `Unreleased` and version
section must begin with the exact machine-readable bilingual highlight block
defined by the guideline, including its quoted blank separator. Maintain
`DOWNSTREAM_CHANGES.md` separately for exact fork-only behavior. Release
headings must start with
`## vMAJOR.MINOR.PATCH` so CI can extract them, and an upstream merge must not
set or imply the downstream release version.

## Fork Maintenance

This repository is a **soft fork** of an upstream project. It periodically
merges upstream tagged releases and carries a small number of intentional
downstream changes. Upstream tags are synchronization points only; they do not
determine this fork's release versions.

### Maintenance files

| File | Purpose |
|------|---------|
| `.upstream-version` | Tracks the upstream repo URL and the last merged upstream tag. Written by `/upstream-sync` on every sync. |
| `DOWNSTREAM_CHANGES.md` | Ledger of all fork-only modifications. Read by `/upstream-sync` during conflict resolution to preserve downstream behavior. |

### DOWNSTREAM_CHANGES.md format

Every entry in `DOWNSTREAM_CHANGES.md` follows this structure:

```markdown
## [slug-id]: Short description

- **Scope**: `path/to/file` (or comma-separated paths)
- **Type**: patch \| feature \| config \| override \| removal
- **Status**: active \| superseded \| removed
- **Introduced**: <slug-id>
- **Superseded by upstream**: <upstream-version or N/A>

### What this changes

Plain-English description of what the fork does differently from upstream and why.

### Files affected

- `path/to/file`: what was changed (function names, config keys, line ranges)
```

**Type values:**
- `patch` — bug fix applied downstream ahead of upstream
- `feature` — new functionality not present upstream
- `config` — configuration changes, default values, feature flags
- `override` — behavior replacement (fork's implementation supersedes upstream's)
- `removal` — upstream code intentionally removed or disabled in the fork

**Status values:**
- `active` — currently in effect
- `superseded` — upstream now implements equivalent functionality; entry kept for history
- `removed` — change reverted; entry kept for history

**Slug provenance:**
- Use the same stable slug in the entry heading, the `Introduced` field, the
  feature branch/worktree names, and the pull request title.
- Do not put commit hashes, tags, or dates in `Introduced`. The slug in the pull
  request title is retained in the squash commit message and provides the
  durable link between the ledger entry and repository history.

### When making downstream changes

Every time you make a fork-only modification — adding a feature, patching a bug,
changing a default, overriding behavior — you **must** add or update an entry in
`DOWNSTREAM_CHANGES.md`. This is not optional. Without it, `/upstream-sync` has
no way to know which changes to preserve during upstream merges, and downstream
modifications will be silently overwritten.

Routine maintenance changes that do not alter downstream behavior are exempt.
Developer-only coding-agent instructions and prompt templates, such as
`AGENTS.md` workflow guidance and `.pi/prompts/`, are also exempt when they do
not change the application, build/CI, packaging, release behavior, or
user-facing documentation. In particular, do **not** add or update ledger
entries solely for those developer-only files, dependency or fixed-output hash
refreshes (such as `cargoHash`), or project/package version bumps. If an exempt
change also introduces or modifies fork-specific product or delivery behavior,
record that behavioral change normally.

When `/upstream-sync` detects that an upstream release implements the same
feature or fix as a downstream change, it will update the entry's status to
`superseded` and note the upstream version.

### Versioning

Follow `docs/VERSIONING.md` for the version source of truth, version bump and
synchronization commands, build-number rules, and release-tag requirements.
Astral-ng uses its own release cycle and version sequence independently of
upstream. An upstream tag recorded in `.upstream-version` identifies only the
last merged upstream baseline and must not set, derive, or bump the downstream
application or package version.
