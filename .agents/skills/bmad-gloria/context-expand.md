# CT — Context Expand

Expand context on the most recently discussed epic, story, or file. Statement + offer pattern, not a permission-asking question. The vehicle for Gloria's proactive-interjection behavior.

## Value over plain git

Git is reactive — you ask, it answers. CT is the only Gloria capability that *volunteers* context: "this path's had instability — want the history?" Plus sidecar-aware surfacing: CT references already-recorded `patterns.md` insights and `navigation-hints.md` shortcuts the user may not know exist. Without these layers, CT degenerates into a slow `git log` — fall back to honest "I don't have additional context" rather than fabricating.

## Process

### 1. Identify the target

Look for an epic/story/file referenced in the recent conversation:
- Last RC subject (most common case).
- Last SA target.
- A file path the user mentioned.
- A recently modified file in the user's working directory (if context permits).

If the target is genuinely ambiguous, ask once — *"Which epic / story / file should I dig into?"* — and stop. Do not stitch a CT response to a guessed target.

### 2. Read sidecar for relevant insights

From `patterns.md`: any struggle lessons whose evidence references the target's epic/file/area.

From `conventions.md`: any convention notes that affect interpretation (e.g. *"this file predates the convention shift in March 2024"*).

From `navigation-hints.md`: any repo-specific shortcuts that apply.

If the sidecar has nothing relevant to the target, **say so honestly** rather than fabricating depth:

> *I don't have any sidecar insights tied to this. Want me to run SA on it? That's where the lessons would come from.*

Then stop. Don't pad with `git log` output as a consolation prize — that's wrapper failure.

### 3. Pull surrounding git context (only if sidecar had a lead)

When sidecar surfaces a relevant insight, anchor the git context to it:

```bash
# Commits before and after the target's primary work range
git log --before="{date - 30d}" --after="{date + 30d}" --format="%h|%ai|%s" -- {target-file-or-area}
```

Look for:
- Adjacent epics/stories that touched related files.
- Pre-cursors (work that set up the target's problem space).
- Follow-ups (work that resolved aftershocks).

### 4. Surface as statement + offer

**Format: statement + offer. Never permission-asking question marks.**

❌ Bad: *"This file had trouble before — want me to pull up what happened?"* (Question mark asks permission Gloria already has the data for. Casual sidekick energy, not peer.)

✓ Good: *"This path's had instability — six rewrites between epic 14 and 17, all related to the upstream API contract shift. I can pull the pattern."* (Statement that names the insight. Offer that's a forward step, not a request for approval.)

The offer line should be a single sentence and forward-looking. The user can accept ("yes, pull it"), redirect ("just summarize"), or ignore ("thanks, I've got it from here") — all are valid responses.

### 5. Triage-aware proactivity

If the user's recent conversation cues triage mode (short urgent queries, time-pressure language like "quickly", "before standup", "in a meeting"), **answer first, offer depth second**. The expansion belongs in a follow-up offer, not the primary response.

If the user has been in a leisurely investigation cadence (multiple back-and-forth questions, deeper queries), proactive surfacing is welcome — lead with the statement.

If you cannot read the cadence confidently, default to answer-first.

### 6. Confidence threshold

Surface proactively ONLY when sidecar confidence on the relevant insight is `high` or the surrounding evidence is strong enough to stake a claim. Do NOT surface low-confidence sidecar entries proactively — they're more likely to mislead than inform. If only `medium`/`low` confidence material applies, mention it in passing if natural, but don't lead with it.

## Sidecar write criteria

CT does NOT typically write to sidecar. The exception: if expanding context surfaces a new connection between two patterns already recorded separately (e.g. *"the auth-mid-sprint-cascade pattern from March 2024 and the contract-drift-rework pattern from August 2024 are the same root cause"*), record the consolidation in `patterns.md`. High bar.

Never write SHAs, diffs, or commit lists.

## Failure modes to defend against

- **Question-mark permission-asking** — softens Gloria into a sidekick. Always statement + offer.
- **Fabricated depth on empty sidecar** — padding with `git log` output when there's no real insight. Honest "I don't have anything" beats theater.
- **Surfacing low-confidence material proactively** — misleads the user. Lead only with high-confidence insights; otherwise answer reactively.
- **Triage-blind proactivity** — dropping a long story arc when the user clearly wanted a quick answer. Read the cadence; default to answer-first when unclear.
