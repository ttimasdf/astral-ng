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
3. Enter the project development shell with `nix develop` from the linked
   worktree. Develop and iterate locally with Flutter tools such as focused
   analysis, tests, formatting, and `flutter run`. Commit focused, reviewable
   units along the way instead of leaving the implementation uncommitted.
4. Reserve `nix build` and remote CI for final validation. During development,
   use the fastest relevant Flutter feedback loop and exercise the affected
   behavior locally.
5. When the implementation appears complete, demonstrate its current state by
   launching the app on an available target: normally Linux desktop with
   `flutter run -d linux`, or a connected Android device when mobile behavior
   is relevant. Ask the user to confirm the result or provide more suggestions.
   If the user requests changes, continue local development and repeat the
   demonstration. Do not push or create a pull request until the user confirms
   that there are no further suggestions.
6. After the user confirms, begin final wrap-up. Read
   `docs/DOWNSTREAM_CHANGES_GUIDELINES.md`, then add or update the corresponding
   `DOWNSTREAM_CHANGES.md` entry using the same slug. Apply the changelog policy
   below when the change is user-facing.
7. Run final local validation from the Nix development shell with Flutter tools
   such as `flutter analyze lib` and `flutter test`, then run
   `nix build .#astral-ng`. Resolve failures locally, repeat the demonstration
   if behavior changed, and commit the wrap-up.
8. Read `docs/CI.md`, push the feature branch, and create a pull request. The
   pull request title must begin with `[<slug>]` so the slug is retained in the
   squash commit message (for example,
   `[tray-status-icons] Add tray status indicators`). Enable `full-ci`, watch
   the required checks to completion, and then present the passing pull request
   for review.
9. Merge a pull request only after the user explicitly approves the merge. Once
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

Canary Android builds are disposable testing artifacts, not production upgrade
artifacts. Install them as the canary package (`pw.rabit.astralng.canary`) and
keep production installs separate. If Android rejects a canary APK because of a
version, downgrade, or signature mismatch, uninstall the canary package from
the target device and install the APK again:

```sh
adb uninstall pw.rabit.astralng.canary
adb install <canary-apk>
```

Only remove the production package when the user explicitly requests a clean
production reset.

## Pull Request CI

Treat remote CI as final cross-platform validation, not as the ordinary local
iteration loop. After the user accepts the local demonstration and final local
checks pass, read `docs/CI.md` for `full-ci` label behavior, expected runner
timing, and bounded waiting instructions.

## Breaking Changes and Compatibility

Do not preserve backward compatibility by default when a requested change
replaces an obsolete path, format, interface, default, or workflow. Before
implementing an intentional compatibility break:

1. Warn the user explicitly that the proposed change is breaking.
2. State who or what is affected, what will stop working or become inaccessible,
   and the exact migration or cleanup action required.
3. Wait for explicit user authorization of that breaking scope. Approval of the
   broader feature is not implicit approval of a newly discovered break.
4. After authorization, implement the simpler canonical behavior without a
   compatibility shim unless the user specifically requests one.
5. Add a `**Breaking:**` entry under `Unreleased` in `CHANGELOG.md` following
   `docs/CHANGELOG_GUIDELINES.md`, including affected users and migration steps.
6. Record the behavior in `DOWNSTREAM_CHANGES.md` when it is a downstream
   application, build, packaging, release, or documentation difference.

Developer-only instruction changes remain exempt from the downstream ledger as
described below.

## Changelog Maintenance

Follow `docs/CHANGELOG_GUIDELINES.md` whenever a change affects users,
integrators, supported platforms, or release artifacts. Add the entry to
`CHANGELOG.md` under `Unreleased` in the same pull request as
the change; do not generate entries mechanically from commit subjects.

Keep the changelog concise and user-facing, with links or a short `Developer
notes` section for implementation provenance. Every entry must begin with a
bold two-to-seven-word navigation brief and remain at or below 300 characters.
Within `Added`, `Changed`, and `Fixed`, collect upstream-derived entries under
the corresponding nested upstream group. Order security and breaking notices
first, user-facing workflow and UI/UX changes next, and operational or
developer-facing changes such as logs, packaging, and toolchains last. Format
breaking briefs with the prominent `⚠ BREAKING —` marker and retain an exact
migration action.

Every `Unreleased` and version section must retain the exact machine-readable
bilingual highlight block defined by the guideline, including its quoted blank
separator. Routine feature, fix, maintenance, and upstream-sync work may add
factual entries under `Unreleased`, but must not create, replace, or revise that
section's highlight.

Write a new release highlight only when the user explicitly requests a version
bump. Treat the highlight as release content requiring separate review:

1. Inspect the accumulated `Unreleased` entries and draft an exact bilingual
   highlight block that follows `docs/CHANGELOG_GUIDELINES.md`.
2. Apply the proposed block to `CHANGELOG.md` as an uncommitted draft and show
   the user the target version and both highlight lines.
3. Ask the user to confirm or revise that exact draft. A general feature,
   release, or bump request is not confirmation of agent-authored highlight
   wording.
4. Only after explicit confirmation, run the version bump command, finalize the
   release section, commit the release preparation, and proceed with any
   separately authorized tag or publication workflow.

Maintain `DOWNSTREAM_CHANGES.md` separately for exact fork-only behavior.
Release headings must start with `## vMAJOR.MINOR.PATCH` so CI can extract them,
and an upstream merge must not set or imply the downstream release version.

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
