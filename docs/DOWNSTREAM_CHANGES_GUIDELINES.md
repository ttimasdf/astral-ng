# Downstream Changes Guidelines

Read this guide after completing implementation and before wrapping up a
fork-specific change. Record the change in `DOWNSTREAM_CHANGES.md` using the
same stable slug used by the feature branch, worktree, and pull request.

## Entry format

Every entry in `DOWNSTREAM_CHANGES.md` follows this structure:

```markdown
## [slug-id]: Short description

- **Scope**: `path/to/file` (or comma-separated paths)
- **Type**: patch | feature | config | override | removal
- **Status**: active | superseded | removed
- **Introduced**: <slug-id>
- **Superseded by upstream**: <upstream-version or N/A>

### What this changes

Plain-English description of what the fork does differently from upstream and why.

### Files affected

- `path/to/file`: what was changed (function names, config keys, line ranges)
```

## Type values

- `patch` — bug fix applied downstream ahead of upstream
- `feature` — new functionality not present upstream
- `config` — configuration changes, default values, feature flags
- `override` — behavior replacement where the fork's implementation supersedes
  upstream's
- `removal` — upstream code intentionally removed or disabled in the fork

## Status values

- `active` — currently in effect
- `superseded` — upstream now implements equivalent functionality; the entry is
  kept for history
- `removed` — change reverted; the entry is kept for history

## Slug provenance

Use the same stable slug in the entry heading, the `Introduced` field, the
feature branch and worktree names, and the pull request title.

Do not put commit hashes, tags, or dates in `Introduced`. The slug in the pull
request title is retained in the squash commit message and provides the durable
link between the ledger entry and repository history.
