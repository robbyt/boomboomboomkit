# RC — Recall Epic/Story History

Narrate an epic or story as an inflection-point story arc, not a chronological commit dump. Anchored ID disambiguation, cross-artifact correlation when planning docs exist, tag-boundary scoping when available. Append `--mode=tabular` for a clean SHA|date|message table only (no prose).

## Value over plain git

Plain `git log --grep="18-4"` gives you a substring match on commit messages — which silently mismatches when the ID `18` collides with PR #180 or issue 218. RC adds: anchored regex disambiguation against the sidecar's recorded `id_namespace_scheme`, tag-boundary scoping, cross-reference to planning artifacts (when present), and inflection-point synthesis ("the rough part was March, but it landed clean April 4") that no chronological log dump can produce. If RC cannot synthesize, it falls back to tabular mode honestly rather than wrapping a plain `git log` in narrative theater.

## Process

### 1. Parse the user's input

Extract the epic/story ID and optional `--mode=tabular` flag. Examples:
- `RC 18-4` → narrative mode, ID `18-4`
- `RC epic 18` → narrative mode, ID `18` (epic-level)
- `RC 18-4 --mode=tabular` → tabular mode, ID `18-4`
- `RC` (no arg) → ask which epic/story, suggest recent ones if memory has them

### 2. Build the anchored regex against `id_namespace_scheme`

Read `conventions.md` from the sidecar. Build the search regex per format:

| `id_format` | Regex |
|-------------|-------|
| `hyphen` (e.g. `18-4`) | `\b{id}[-\.][0-9]+\b` for story; `\b{id}\b(?![-\.0-9])` for epic-only |
| `dot` (e.g. `18.4`) | `\b{id}[-\.][0-9]+\b` for story; `\b{id}\b(?![-\.0-9])` for epic-only |
| `bare-integer` | `\b{id}\b` — but **see disambiguation below** |
| `multiple` | union of above |

Never use unanchored substring grep. `git log --grep="18"` matches commit messages containing 118, 180, 218, etc. — silent misattribution.

### 3. Disambiguate on namespace collision

If `id_namespace_collision: true` is recorded in `conventions.md` (e.g. epic IDs share number space with PR numbers), do NOT silently pick one interpretation:

```
📜 ID `42` is ambiguous in this repo:
  - Epic 42 (used in commit messages)
  - PR #42 (referenced in squash-merge subjects)

  Which do you mean? [epic | pr | both]
```

After clarification, anchor the regex to the chosen namespace (e.g. require `Epic-42` literal vs `(#42)` literal).

### 4. Run the search

```bash
git log --grep="<anchored-regex>" -E --format="%h|%ai|%an|%s"
```

Count results before deciding output mode:
- **0 results** — say so honestly. Check `id_namespace_scheme` for format mismatch (user typed `18.4` but repo uses `18-4`?). Suggest the alternative format. If still nothing, suggest the user check the ID.
- **1–20 results** — full narrative mode (next step).
- **21+ results** — summary mode: lead with key inflection points, offer to drill into a phase.

### 5. Tag-boundary scoping (when `tag_scheme` allows)

If `conventions.md` records a tag scheme like `v1.{epic}.{bugfix}-{build}`, derive the epic boundary:

```bash
git log --grep="<regex>" --format="%h|%ai|%an|%s" v1.{prev-epic}.0-0..v1.{epic}.0-0
```

This filters the result set to commits within the epic's tagged window — much cleaner than a global grep on long histories. Skip this step on tagless repos.

### 6. Cross-artifact correlation (when `artifact_paths` present)

If `_bmad-output/implementation-artifacts/` (or analogous path from `conventions.md`) exists, search for documentation matching the epic/story ID:

```bash
find {artifact_path} -type f -name "*{id}*" 2>/dev/null
grep -rl "{id}" {artifact_path} 2>/dev/null
```

If found, RC's narrative anchors to the artifact's stated acceptance criteria / goals — not just commit messages. This is a major value-add over plain git: the answer to *"why did we build it this way?"* often lives in the planning doc, not the commit.

### 7. Synthesize the narrative — inflection-point lead

**Lead with the inflection point, never chronology.** A floppy lead like *"This epic began when the team decided to refactor authentication..."* is dead on arrival. A punchy lead lets the reader decide in 1.5 seconds whether this is their story:

> 📜 Auth refactor shipped in three phases — the rough part was March (5 reverts, 2 authors), but it landed clean on April 4.

Structure: **inflection summary → phases (setup / complication / resolution) → optional offer to drill in.**

Reference at least one of:
- A tag boundary (e.g. *"scoped between `v1.17.0-0` and `v1.18.0-0`"*).
- A known struggle pattern from `patterns.md` (e.g. *"this overlaps with the auth-mid-sprint-pivot pattern recorded in March 2024"*).
- A planning artifact (e.g. *"acceptance criteria from `_bmad-output/implementation-artifacts/epic-18.md` set the original scope at X; the actual implementation diverged when..."*).
- A cross-commit pattern (e.g. *"three commits touched `OrderProcessor.swift` repeatedly between phases — usually a sign of unsettled design"*).

If you cannot reference at least one of those, **fall back to tabular mode honestly** — print the SHA|date|message table without narrative wrapping. The narrative is the value-add; if the repo doesn't have the signal to support it, don't fabricate.

### 8. Tabular mode (`--mode=tabular`)

Pure data, no prose. The silence IS the register shift.

```
SHA      | DATE                | MESSAGE
a4f91c3  | 2024-04-04 14:22:13 | EPIC-18 wire payment retry to circuit breaker
3e8f211  | 2024-04-02 09:15:42 | EPIC-18 fix flaky test on race condition
...
```

No narrative summary, no inflection-point line, no offer to drill in. Tabular mode is for copy-paste and linking; if the user wanted narrative, they'd have left the flag off.

### 9. Provenance footer (narrative mode only)

Append a single footer line when synthesis was non-trivial:

> *(narrative derived from 14 commits across `v1.17.0-0..v1.18.0-0`, cross-referenced with `_bmad-output/implementation-artifacts/epic-18.md`)*

Suppress this footer when the dataset is small (<5 commits) or the answer is fully obvious. Provenance earns inline real estate only when confidence is low or the claim is surprising.

## Sidecar write criteria

RC does NOT typically write to sidecar. Most epic recalls don't surface a *repeatable lesson* — they surface a single epic's story. Sidecar is for cross-epic patterns, not per-epic narratives.

The exception: if RC discovers a structural insight that applies beyond this single epic (e.g. *"every auth-related epic in this repo follows the same three-phase shape"*), write it to `patterns.md` with `discovered_at`. High bar — most RC runs produce zero sidecar writes.

## Failure modes to defend against

- **Confident confabulation on namespace collision** — silently picking one interpretation of an ambiguous ID. Always disambiguate.
- **Substring grep** — `git log --grep="18"` matching everything containing `18`. Always anchor.
- **Floppy chronological lead** — "This epic began when..." Always lead with the inflection point.
- **Narrative theater on thin data** — wrapping 4 commits in story-arc framing when the table would say more. Fall back to tabular honestly.
- **Stale artifact references** — if `_bmad-output/...` was deleted or restructured since `discovered_at`, the cross-reference may be stale. Surface the artifact's freshness if old.
