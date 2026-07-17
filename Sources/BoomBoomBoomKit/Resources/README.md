# BoomBoomBoomKit bundled documentation

The `Documentation/<Type>/<case>.md` files in this directory are the canonical,
offline per-case documentation surfaced through `DocumentedCase.docs` and
`BoomBoomBoomKitDocs.attributedString(for:id:)`. They are rendered with
`AttributedString(markdown:options:)` in `.inlineOnlyPreservingWhitespace` mode.

## Authoring rules

Each per-case file is plain prose with a required YAML front-matter block and
exactly three bold-lead paragraphs — `**What it does.**`, `**When to pick it.**`,
and `**Tradeoff.**` — of 200-400 words total, at most 10 KB. The `Tradeoff`
paragraph must include at least one concrete failure-mode sentence.

The front-matter block carries `id:` (the exact Swift case identifier, matching the
filename stem), `title:` (a human-readable phrase), and an optional `payload:`
naming the associated-value type for cases that carry one. The accessor strips this
block before rendering.

Inline `**bold**` and `_italic_` are the only permitted markup. Do **not** use:

- fenced code blocks or inline backtick code
- tables
- images
- headings
- DocC symbol links

`.inlineOnlyPreservingWhitespace` does not render these as structure — per Apple's
documentation it includes the excluded syntax as literal, unattributed text — so
they degrade the rendered output rather than failing loudly. The Story 11.4
validator rejects them.

If a case genuinely needs a table or code sample, keep the per-case file plain and
put the richer treatment in `BoomBoomBoomKit.docc/Articles/SelectionStrategies.md`.

## Adding a case

Run `make new-case TYPE=<TypeName> CASE=<caseName>` to scaffold a new file from
`Documentation/_template.md`.
