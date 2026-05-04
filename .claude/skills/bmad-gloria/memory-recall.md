# ME — Memory Recall

Recall what Gloria has learned about this repository — categorized bullets, no narrative wrapper, with freshness and staleness flags. Pure sidecar read; zero git invocations.

## Value over plain git

Git literally cannot produce this output. Git has no memory layer. ME is the pure sidecar value-add: cross-session insights that compound over time, surfaced organized by category with provenance per entry. If the user wants a per-epic narrative, they want RC; if they want struggle synthesis, they want SA. ME is the standards-enforcement checkpoint and discovery prompt — *"what do we already know?"*

## Process

### 1. Read all sidecar files

```
{project-root}/_bmad/_memory/gloria-sidecar/conventions.md
{project-root}/_bmad/_memory/gloria-sidecar/patterns.md
{project-root}/_bmad/_memory/gloria-sidecar/navigation-hints.md
{project-root}/_bmad/_memory/gloria-sidecar/memories.md
```

(Skip `instructions.md` — it's the protocol layer, not user-facing memory.)

### 2. Empty-sidecar branch

If `conventions.md` has no `Detected (YYYY-MM-DD)` block AND `patterns.md` has no entries beyond the template scaffold:

```
📜 I haven't learned anything about this repo yet — the sidecar is empty.

  Want me to run SC? It scans the commit history to detect:
  - commit conventions (with confidence scoring)
  - tag scheme (or flags as tagless)
  - ID-namespace scheme (whether epic IDs collide with PR numbers)
  - merge strategy (squash / merge-commits / rebase)
  - convention drift across history

  After SC, RC and SA give you their best work.
```

Stop there. Do not invent observations to fill the empty file.

### 3. Compute freshness for each entry

For every entry that carries a `discovered_at` field, compute age in months from today:

- `age < 6 months` → fresh, recite confidently.
- `6 months ≤ age < 12 months` → ageing, surface the date inline.
- `age ≥ 12 months` → **stale** — surface explicit staleness flag: *"observed N months ago — validate before relying on it."*

Read the staleness threshold from `instructions.md` (default 12 months) — `instructions.md` is authoritative if it specifies a different threshold.

### 4. Categorize and present

Format: **categorized bullets with no narrative wrapper.** ME is not a storytelling command. The story already happened.

```
📜 What I've learned about this repo:

  ## Conventions (discovered YYYY-MM-DD)
  - Commit format: <pattern> (confidence: high|medium|low)
  - Tag scheme: <pattern> | tagless
  - ID format: <hyphen|dot|bare-integer> [⚠ namespace collision] (if applicable)
  - Merge strategy: <strategy> [⚠ squash cliff caveat] (if squash)

  ## Struggle Lessons (N entries)
  - **<pattern-name>** (discovered YYYY-MM-DD, confidence: high|medium|low):
    <one-line summary>. Implication: <implication>.
  - **<pattern-name>** ⚠ observed 14 months ago — validate before relying on it.
    <one-line summary>.
  - ... (more)

  ## Navigation Shortcuts (N entries)
  - <hint>
  - <hint>

  ## Recent Activity (last 5 sessions, from memories.md)
  - YYYY-MM-DD: <session note>
  - YYYY-MM-DD: <session note>
  - ...
```

If a category has zero entries, omit the section heading rather than printing *"(none)"* — keep the output tight.

### 5. Stale-entry handling

For each entry flagged stale:

- Display the entry with the `⚠ observed N months ago` prefix.
- Append a one-line note: *"Re-run SC to refresh, or invoke SA on the relevant area to re-validate the pattern."*
- Do NOT silently omit stale entries — staleness is information; absence is misinformation.

### 6. End with a cadence cue

A single closing line that points at the most likely next move:

- If many recent additions: *"Most recent learning: <pattern> on YYYY-MM-DD."*
- If staleness is dominant: *"Several patterns are over a year old — SC re-run would tell us if they still hold."*
- If sparse: *"Want me to run SA on a specific epic to grow this list?"*

Keep it to one line. ME is an inventory; the cadence cue is a soft nudge, not a story.

## Sidecar write criteria

ME does NOT write to sidecar. It is read-only by design. The only exception: ME may APPEND a session note to `memories.md` (e.g. *"YYYY-MM-DD: User invoked ME, requested re-validation of auth-mid-sprint-cascade pattern."*). That's a session-log append, not an insight write.

## Failure modes to defend against

- **Confident recital of stale insights** — the failure mode the freshness layer exists to prevent. Always surface staleness; never recite a 14-month-old pattern as current truth.
- **Narrative wrapper** — *"Over the months, I've come to see this repo as..."* No. Categorized bullets. ME is an inventory, not a memoir.
- **Inventing entries** — if `conventions.md` is empty, ME does not synthesize "probable conventions" from running git in the background. ME is pure sidecar read. Empty means empty.
- **Silent staleness omission** — quietly dropping old entries to keep the output tidy. Show them with the staleness flag; user decides what to trust.
