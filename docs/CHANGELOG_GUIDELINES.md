# Changelog guidelines

`CHANGELOG.md` records notable Astral-ng releases. Its first reader is an
application user deciding whether to upgrade; its second reader is a developer
who needs to trace a statement back to implementation, a pull request, or a
release.

The changelog is not a commit log or a substitute for a pull request.

## Source hierarchy

Verify an entry against the strongest available source before writing it:

1. Current behavior, tests, and configuration in the repository.
2. The Astral-ng pull request or issue that introduced the change.
3. A release, issue, or commit directly relevant to the behavior.
4. Commit messages, only when stronger sources are unavailable.

Do not infer user impact from a commit title alone. If the available evidence is
ambiguous, inspect the implementation or omit the claim until it can be
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

- **NO-TUN SOCKS5 access.** Added a configurable local listener for reaching
  the virtual network. ([#229])

### Fixed

- **Android VPN routes.** Fixed route refresh when a peer advertises a new
  subnet. ([#231])

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
release date when preparing a new one.

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
future release manifest after normal JSON string escaping:

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
- `Developer notes` for concise migration, packaging, API, or build information
  that materially affects maintainers and integrators.

## Entry style

Every list entry begins with a bold, sentence-case navigation brief:

```markdown
- **Android VPN routes.** Fixed route refresh when a connected peer advertises
  a new proxy subnet. ([#231])
```

The brief must:

- summarize the entry in two to seven words;
- be specific enough to scan without reading the description;
- end with a period inside the bold span;
- avoid generic labels such as `Update`, `Improvement`, or `Fix`.

After the brief, answer in this order:

1. What changed?
2. What outcome does the user observe?
3. Which platform, mode, or condition is affected, if not universal?
4. Where can a developer verify it?

Use one or at most two short sentences and one observable outcome per entry.
Keep the complete entry, including its brief and provenance link, at or below
300 Unicode characters. Move extra rationale and implementation detail to the
pull request or developer documentation.

Order entries for readers deciding whether to upgrade:

1. security notices and breaking migrations;
2. user-facing workflows, UI/UX, reliability, and platform behavior;
3. operational and developer-facing changes such as diagnostics, logs,
   packaging, build systems, and toolchains.

Good:

```markdown
- **Android VPN routes.** Fixed route refresh when a connected peer advertises
  a new proxy subnet. ([#231])
```

Too vague:

```markdown
- **Networking fix.** Fixed networking.
```

Too implementation-heavy for a user section:

```markdown
- **Proxy CIDR events.** Added `proxyCidrs` to `KVNodeInfo` and called
  `VpnManager.start()` again from `ServerConnectionManager`.
```

### Breaking and migration entries

Make a breaking entry visually distinct by beginning its bold brief with
`⚠ BREAKING —`:

```markdown
- **⚠ BREAKING — Data directory.** Existing installs may appear reset. Desktop
  users must move all Isar files into Application Support's `db` directory;
  other platforms must reconfigure.
```

The entry must state who is affected, what stops working or changes, and the
exact migration action. It remains subject to the 300-character limit; use a
durable migration document when more detail is essential. Do not label a change
breaking merely because internal APIs or files were refactored.

### Links and provenance

When a durable reference is available and useful, end the entry with the best
one. Tightly related bullets may share one release link or a grouped developer
note instead of repeating the same reference:

- Astral-ng pull request or issue;
- a related external issue or pull request;
- a commit only when no issue or pull request exists.

Use descriptive reference labels such as `[#3]`; do not expose unexplained raw
URLs in bullets.

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
- merge bookkeeping.

Do not use catch-all bullets such as "miscellaneous fixes", and do not paste a
list generated from commit subjects.

## Workflow

### While developing

1. Add the user-facing entry to `Unreleased` in the same pull request as the
   behavior change.
2. Do not create or revise the `Unreleased` highlight during routine feature,
   fix, or maintenance work.
3. Link the changelog entry to the pull request or other durable source when it
   is useful.
4. Re-read the bullet from the perspective of someone who has not seen the
   implementation.

### When releasing

1. Begin only after the user explicitly requests a version bump.
2. Inspect the accumulated entries and apply an exact bilingual highlight to
   `CHANGELOG.md` as an uncommitted draft.
3. Show the user the target version and both highlight lines. Wait for explicit
   confirmation or revision of that exact wording before changing `VERSION`.
4. After confirmation, bump the version using `scripts/version.py`, then move
   the approved highlight and relevant entries under the new release heading.
5. Use the release date, not the merge date of the oldest included change.
6. Remove empty categories and deduplicate entries describing the same outcome.
7. Reset `Unreleased` with `No notable changes yet.` and `暂无重要更新。`, with
   no empty categories.
8. Verify the release section has exactly one bilingual highlight pair and is
   non-empty; CI rejects a tag without a matching changelog section.
9. Tag or publish only when separately authorized. After publication, add or
   verify the GitHub release link when maintaining link references.

## Review checklist

Before merging a changelog update, verify that:

- every claim matches current behavior and is not based only on a commit title;
- user-facing entries describe outcomes rather than implementation;
- every entry begins with a specific bold brief and stays within 300 characters;
- user-facing changes precede operational and developer-facing entries;
- platform and mode limitations are explicit;
- removals, compatibility losses, and migration steps are not hidden under
  `Changed`;
- links resolve to the intended repository and item;
- release headings match `## vMAJOR.MINOR.PATCH - YYYY-MM-DD`;
- every release section has exactly one valid bilingual highlight pair, with
  each value at most 160 characters;
- internal maintenance noise has been omitted.
