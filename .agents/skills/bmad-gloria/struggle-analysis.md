# SA — Struggle Analysis

Synthesize a *pattern + implication for future work* from struggle indicators (reverts, fix-cycles, repeated file edits, late-night clusters). Primary producer of sidecar-worthy lessons. Frame as illumination, never blame — three late-night commits tell a story of determination, not failure.

## Value over plain git

`git log --grep="revert\|fix"` lists commits matching keywords. SA adds: causal synthesis (WHY work was hard — design problem? mid-sprint API change? requirements drift?), per-author timezone baselining (so "late-night" is computed against each contributor's home timezone, not raw UTC), squash-merge calibration warnings (so silent false-negatives don't masquerade as "no struggles"), and write-back of repeatable lessons to `patterns.md`. A bare list of revert SHAs is not SA's product — it's git wrapper failure.

## Process

### 1. Parse the user's input

Extract the epic/story ID or file path:
- `SA 18-4` → analyze story 18-4
- `SA epic 18` → analyze the whole epic
- `SA src/auth/middleware.go` → analyze a specific file's struggle history
- `SA` (no arg) → ask which epic/story/file

### 2. Read sidecar context first

From `conventions.md`:
- `merge_strategy` — drives the squash-cliff calibration warning.
- `id_format` and `id_namespace_collision` — feeds RC-style anchored regex.
- `tag_scheme` — for boundary-scoping when applicable.

From `patterns.md`:
- Existing struggle lessons. If this analysis would duplicate an already-recorded lesson, say so and ask if user wants re-validation rather than re-deriving.

### 3. Squash-cliff calibration (mandatory check)

If `merge_strategy` is `squash`:

> ⚠ **Calibration**: this repo uses squash-merge. Individual struggle commits (reverts, fix-cycles) are erased by history rewrite — SA's signals here are likely suppressed. PR descriptions and issue refs are the more reliable channel for this team's struggle history. SA will still surface what it can from squashed PR titles, but absence of signal does not mean absence of struggle.

Surface this caveat BEFORE running the analysis, not as a footer. The user needs to know the data is calibrated before reading the conclusion.

If `merge_strategy` is `mixed` (some merges squashed, some not), surface a softer version: *"SA accuracy varies by phase since merge strategy is mixed."*

### 4. Find candidate commits

Build the anchored regex per RC's algorithm. Then:

```bash
# All commits for the target
git log --grep="<anchored-regex>" -E --format="%h|%ai|%an|%ae|%s"

# Reverts and fix commits
git log --grep="<anchored-regex>" -E --grep="revert\|fix\|hotfix" --all-match --format="%h|%ai|%s"

# File-touch frequency (if file path was given)
git log --follow --format="%h|%ai|%an|%s" -- {file}
```

### 5. Detect struggle indicators

For the candidate set, identify:

#### a. Reverts
Commits with `Revert "..."` subject pattern. For each, identify what was reverted (`git show --stat {sha}`) — what was rolled back? Was it later re-applied with a different approach (= pivot moment) or just dropped (= dead end)?

#### b. Fix-cycles
Commits with `fix:` / `hotfix:` prefix or "fix" in subject, especially clusters within hours of each other on the same file. A pattern like `feat → fix → fix → fix` over a single file in 24 hours is a struggle signal.

#### c. Repeated file edits
Same file touched in 4+ commits across the epic, especially if `git diff` between commits shows churn (additions undone in next commit). Use:

```bash
git log --format="%h|%ai|%s" -- {suspect-file}
```

Then count distinct touches.

#### d. Late-night clusters — per-author timezone baselined

**Critical:** raw UTC offsets give wrong answers. A commit at 02:00 UTC from a London contributor is late-night; the same UTC time from a Bangalore contributor is mid-morning. Compute each author's modal timezone offset from their earliest 10 commits as a baseline:

```bash
# For each author appearing in the candidate set:
git log --author="{author-email}" --format="%ai" -10 | <extract offset, take mode>
```

Then classify a commit's local hour relative to the author's modal offset:
- Local hour `0–6` → "late-night" (struggle signal candidate).
- Local hour `7–22` → normal working window.
- Local hour `23` → "evening burn" (softer signal).

Cluster: 3+ late-night commits from a single author within a week = strong struggle signal. Single late-night commits are not — people work weird hours sometimes.

#### e. Rapid commit sequences
3+ commits from the same author within 30 minutes on the same file. Often signals frustration / "this isn't working" iteration.

### 6. Synthesize a *pattern + implication*

The output is NOT a list of indicators. The output is a synthesis:

> 📜 **Pattern**: the auth middleware caused cascading test failures whenever the upstream API contract shifted mid-sprint — `OrderProcessor.swift` was rewritten three times across epic 17, with two reverts, before settling on the circuit-breaker approach in epic 18. Late-night work clustered around the second revert (2024-03-12, two contributors).
>
> **Implication for future work**: when touching auth-adjacent code mid-sprint, surface API-contract dependencies in the planning doc *before* the work starts — most of the rework here came from discovering contract drift after implementation was underway.

If you cannot construct a *pattern + implication*, you do not have an SA result yet. Either:
- Drill deeper (more commits, longer time window).
- Output a calibration message: *"signals here are too thin to call a pattern — three minor fixes over two months, no clustering. No SA writeback today."* Honest > fabricated.

### 7. Sidecar write criteria — **selective, not automatic**

Most SA runs should NOT trigger a sidecar write. The bar is:

- The lesson is **repeatable** — applies beyond this single story/file.
- The lesson is **actionable** — informs future decisions, not just a historical observation.
- The lesson is **specific** — "auth-adjacent code is risky mid-sprint" is too vague; "touching `*Auth*` files in the same sprint as upstream API contract changes causes cascading test failures" is specific.

When the bar is met, write to `patterns.md`:

```markdown
## YYYY-MM-DD — auth-mid-sprint-cascade

**Pattern**: <one-line summary>
**Evidence**: <where it surfaced — epic refs, time range — but never SHAs>
**Implication**: <actionable guidance for future work>
**discovered_at**: YYYY-MM-DD
**last_validated**: YYYY-MM-DD
**confidence**: high|medium|low
```

Never write commit SHAs, diffs, or file inventories. The pattern is the product; the underlying git data stays in git.

### 8. Provenance footer

Single footer line for non-trivial analyses:

> *(derived from 23 commits across `v1.17.0-0..v1.18.0-0`, late-night classification baselined against 4 contributors' modal timezones)*

## Failure modes to defend against

- **Squash-cliff false negative** — silently reporting "no struggles found" on a squash repo. Always lead with the calibration caveat.
- **UTC-only late-night classification** — false-positive rate ~40% for distributed teams. Always baseline per author.
- **Indicator-list output** — listing reverts and fix commits without synthesis. That's wrapper failure. Output is pattern + implication.
- **Sidecar write spam** — writing every analysis to `patterns.md`. Most SA runs should produce zero writes; the bar is repeatable + actionable + specific.
- **Blame language** — "the team failed to..." / "this developer caused...". Frame as illumination: *what happened* and *what to watch for next time*. Never assign fault.
