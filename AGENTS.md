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
4. After implementation is complete and you are preparing to wrap up the
   changes, read `docs/DOWNSTREAM_CHANGES_GUIDELINES.md`, then add or update the
   corresponding `DOWNSTREAM_CHANGES.md` entry using the same slug.
5. Read `docs/CI.md`, run the relevant checks, push the feature branch, and
   create a pull request. The pull request title must begin with `[<slug>]` so
   the slug is retained in the squash commit message (for example,
   `[tray-status-icons] Add tray status indicators`).
6. Merge a pull request only after the user explicitly approves the merge. Once
   authorized, use `/merge-pr [PR-number-or-URL]`; the prompt contains the merge
   and cleanup workflow.

## Commit Signing

Create commits in linked worktrees without signing (`git commit --no-gpg-sign`).
Create commits on `main` with signing enabled (`git commit --gpg-sign`).

## Local Android Builds

Run Android Flutter commands from the Nix development shell with
`flutter-android`, not the plain `flutter` executable. The helper prevents
nixpkgs' Linux desktop compiler paths from contaminating NDK compilation and
configures bindgen for every Android ABI used by Cargokit. Keep normal Flutter
subcommands and arguments. The helper defaults to the canary identity; place
Astral-specific overrides before the Flutter subcommand:

```bash
flutter-android run -d <device>
flutter-android test
flutter-android build apk --debug
flutter-android --astral-channel production build apk --release
```

Use plain `flutter` for Linux desktop development. The Android helper stops
compatible Gradle daemons before commands that can build the app because Gradle
daemons retain their startup environment.

## Pull Request CI

Before running checks, pushing a feature branch, or creating a pull request,
read `docs/CI.md` for validation scope, `full-ci` label behavior, expected
runner timing, and bounded waiting instructions.

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
