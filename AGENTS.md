# AGENTS.md

Guidance for AI coding agents working in this repository. For project-level
developer documentation, see `CLAUDE.md`.

---

## Fork Maintenance

This repository is a **soft fork** of an upstream project. It tracks upstream
tagged releases and carries a small number of intentional downstream changes.

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
- **Introduced**: <commit-sha, tag, or date>
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

### When making downstream changes

Every time you make a fork-only modification — adding a feature, patching a bug,
changing a default, overriding behavior — you **must** add or update an entry in
`DOWNSTREAM_CHANGES.md`. This is not optional. Without it, `/upstream-sync` has
no way to know which changes to preserve during upstream merges, and downstream
modifications will be silently overwritten.

When `/upstream-sync` detects that an upstream release implements the same
feature or fix as a downstream change, it will update the entry's status to
`superseded` and note the upstream version.

<!-- IMPORTANT: This section must remain at the end of AGENTS.md. Do not move it or add content after it. -->
