# Changelog guidelines

`CHANGELOG.md` describes notable changes in Astral-ng releases. Its first
reader is an application user deciding whether to upgrade; its second reader is
a developer who needs to trace a statement back to its implementation.

The changelog is not a commit log, a substitute for a pull request, or the
fork-maintenance ledger.

## Source hierarchy

Verify an entry against the strongest available source before writing it:

1. Current behavior, tests, and configuration in the repository.
2. The Astral-ng pull request or issue that introduced the change.
3. `DOWNSTREAM_CHANGES.md` for intentional differences from upstream.
4. The merged upstream tag, pull request, issue, or commit.
5. Commit messages, used only when stronger sources are unavailable.

Do not infer user impact from a commit title alone. If the available evidence
is ambiguous, inspect the implementation or omit the claim until it can be
verified.

## Document structure

Keep an `Unreleased` section at the top and released versions in reverse
chronological order:

```markdown
# Changelog

## Unreleased

> **Highlight:** Connect more reliably with automatic retries and clearer setup.
>
> **版本亮点：** 自动重试与更清晰的设置流程让连接更加可靠。

### Added

- Added a SOCKS5 listener for NO-TUN mode. ([upstream-#229])

### Fixed

- Fixed Android VPN routes not refreshing when a peer advertises a new subnet.
  ([upstream-#231])

### Developer notes

- Synced the upstream baseline through `v2.9.9`. ([upstream-v2.9.9])

## v2.8.7 - 2026-07-30

> **Highlight:** Connect more reliably with automatic retries and clearer setup.
>
> **版本亮点：** 自动重试与更清晰的设置流程让连接更加可靠。

...
```

Release automation extracts notes by matching a heading that starts with
`## v<version>`. Every release heading must therefore use exactly:

```text
## vMAJOR.MINOR.PATCH - YYYY-MM-DD
```

Use the GitHub publication date in UTC for an existing release. Use the actual
release date when preparing a new one. Astral-ng has its own version sequence;
never derive a release heading from `.upstream-version`.

## Release highlights

Every `Unreleased` and released-version section must begin with exactly one
English/Chinese highlight block as its first content:

```markdown
> **Highlight:** Connect more reliably with automatic retries and clearer setup.
>
> **版本亮点：** 自动重试与更清晰的设置流程让连接更加可靠。
```

The quoted blank line creates a reliable visual paragraph break while keeping
both translations in one blockquote. The block is also a stable
machine-readable field with this exact grammar:

```regex
^> \*\*Highlight:\*\* ([^\r\n]+)\r?\n>\r?\n> \*\*版本亮点：\*\* ([^\r\n]+)$
```

The parser must first select the requested `## Unreleased` or
`## vMAJOR.MINOR.PATCH` section, then require exactly one block match. Capture
group 1 is English and capture group 2 is Chinese; both are suitable for a
future release manifest after normal JSON string escaping. A future manifest
should expose them by locale:

```json
{
  "version": "2.8.7",
  "highlights": {
    "en": "Connect more reliably with automatic retries and clearer setup.",
    "zh": "自动重试与更清晰的设置流程让连接更加可靠。"
  }
}
```

Highlight rules:

- use exactly one physical line per language;
- limit each captured value to 160 Unicode characters;
- end the English sentence with a period and the Chinese sentence with `。`;
- describe the release's most important user outcome, not its implementation;
- translate the meaning naturally and keep product names and technical terms
  consistent between languages;
- do not include Markdown, links, issue numbers, commit hashes, or raw URLs;
- reset an empty `Unreleased` section with `No notable changes yet.` and
  `暂无重要更新。`.

Both markers, their capitalization, punctuation, spacing, order, blockquote
prefixes, and the quoted blank separator are part of the format. Do not
translate, reorder, or reflow them.

Use only the headings that have entries:

- `Added` for new capabilities.
- `Changed` for changed user-visible behavior or defaults.
- `Fixed` for corrected behavior.
- `Security` for security-relevant corrections or mitigations.
- `Deprecated` for supported behavior scheduled for removal.
- `Removed` for capabilities, platforms, languages, or compatibility that no
  longer exist.
- `Developer notes` for concise migration, packaging, API, upstream-baseline,
  or build information that materially affects maintainers and integrators.

## Entry style

Each user-facing bullet should answer, in this order:

1. What changed?
2. What outcome does the user observe?
3. Which platform, mode, or condition is affected, if not universal?
4. Where can a developer verify it?

Prefer one sentence and one observable change per bullet. Start with a
past-tense verb such as "Added", "Improved", "Fixed", or "Removed". Name a
platform or condition early when it limits the scope.

Good:

```markdown
- Fixed Android VPN routes not refreshing when a connected peer advertises a
  new proxy subnet. ([upstream-#231])
```

Too vague:

```markdown
- Fixed networking.
```

Too implementation-heavy for a user section:

```markdown
- Added `proxyCidrs` to `KVNodeInfo` and called `VpnManager.start()` again from
  `ServerConnectionManager`.
```

Put necessary implementation detail in `Developer notes`, the pull request, or
`DOWNSTREAM_CHANGES.md` instead.

### Breaking and migration entries

Begin a breaking entry with `**Breaking:**` and state:

- who is affected;
- what stops working or changes;
- the exact action needed to migrate.

Do not label a change breaking merely because internal APIs or files were
refactored.

### Links and provenance

When a durable reference is available and useful, end the entry with the best
one. Tightly related bullets may share one release link or a grouped developer
note instead of repeating the same reference:

- Astral-ng pull request for downstream changes;
- upstream pull request or issue for merged upstream behavior;
- an exact upstream tag for a summarized synchronization note;
- a commit only when no issue or pull request exists.

Use descriptive reference labels such as `[#3]`, `[upstream-#231]`, and
`[upstream-v2.9.9]`; do not expose unexplained raw URLs in bullets.

When summarizing an upstream merge:

- list notable user-visible outcomes as normal entries;
- record the exact merged baseline once under `Developer notes`;
- do not adopt the upstream version as Astral-ng's release version;
- distinguish a forward-port or cherry-pick from an ancestry-preserving merge.

## What belongs in the changelog

Include changes that affect at least one of the following:

- application behavior, workflow, or visible UI;
- compatibility, supported platforms, or supported languages;
- configuration defaults or required migration steps;
- performance or reliability users can observe;
- security or privacy;
- packages, release artifacts, or developer-facing interfaces.

Usually exclude:

- formatting and comment-only edits;
- test-only changes;
- refactors with no observable effect;
- dependency or fixed-output hash refreshes with no compatibility impact;
- CI maintenance that does not alter produced artifacts or contributor
  workflow;
- merge bookkeeping already represented by an upstream-baseline note.

Do not use catch-all bullets such as "miscellaneous fixes", and do not paste a
list generated from commit subjects.

## Relationship to maintenance records

The files have different responsibilities:

| File | Audience and purpose |
| --- | --- |
| `CHANGELOG.md` | Users and integrators; concise release impact. |
| `DOWNSTREAM_CHANGES.md` | Maintainers; fork differences needed during sync. |
| Pull request | Reviewers; design, implementation, and validation. |
| Commits | Developers; focused implementation history. |

A downstream behavior change normally needs both an `Unreleased` changelog
entry and a `DOWNSTREAM_CHANGES.md` entry. Routine maintenance may need neither.
Do not copy the full ledger entry into the changelog.

## Workflow

### While developing

1. Add the user-facing entry to `Unreleased` in the same pull request as the
   behavior change.
2. Update both `Unreleased` highlight lines when the release's main user
   outcome changes.
3. Add or update `DOWNSTREAM_CHANGES.md` when the change is fork-only.
4. Link the changelog entry to the pull request or upstream source.
5. Re-read the bullet from the perspective of someone who has not seen the
   implementation.

### When releasing

1. Confirm `VERSION` and the release tag follow `docs/VERSIONING.md`.
2. Finalize the bilingual `Unreleased` highlight pair and verify its meaning,
   length, order, and grammar.
3. Move that highlight pair and the relevant entries under the new release
   heading.
4. Use the release date, not the merge date of the oldest included change.
5. Remove empty categories and deduplicate entries describing the same outcome.
6. Reset `Unreleased` with `No notable changes yet.` and `暂无重要更新。`, with
   no empty categories.
7. Verify the release section has exactly one bilingual highlight pair and is
   non-empty; CI rejects a tag without a matching changelog section.
8. After publication, add or verify the GitHub release link when maintaining
   link references.

## Review checklist

Before merging a changelog update, verify that:

- every claim matches current behavior and is not based only on a commit title;
- user-facing entries describe outcomes rather than implementation;
- platform and mode limitations are explicit;
- removals, compatibility losses, and migration steps are not hidden under
  `Changed`;
- downstream and upstream provenance is distinguishable;
- links resolve to the intended repository and item;
- release headings match `## vMAJOR.MINOR.PATCH - YYYY-MM-DD`;
- every release section has exactly one valid bilingual highlight pair, with
  each value at most 160 characters;
- dates and versions belong to Astral-ng, not its upstream baseline;
- internal maintenance noise has been omitted;
- `DOWNSTREAM_CHANGES.md` was updated when required.
