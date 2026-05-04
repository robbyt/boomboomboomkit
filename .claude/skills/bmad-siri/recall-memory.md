# ME — Recall Memory

What I know about Apple APIs in this project — categorized memory dump organized by status. Apply Pattern D: **memory only** — zero external tool calls. This command doubles as a **standards-enforcement checkpoint**: run before starting new features to surface established patterns and rejected APIs.

## Value over plain web search

Web search and apple-docs MCP both have *no memory* of what THIS project has decided. ME is the pure sidecar value-add: cross-session institutional knowledge, organized by status (APPROVED / CAUTION / REJECTED), with staleness flags on verdicts older than 90 days. It's the answer to *"what have we already validated for this project?"*

## Process

1. **Review `memories.md`** for user preferences and project context.

2. **Review `api-decisions.md`** for all API verdicts organized by status: APPROVED, CAUTION, REJECTED.

3. **Review `project-patterns.md`** for established conventions and deployment targets.

4. **Review `wwdc-references.md`** for cited sessions catalog.

5. **Present learnings** organized by category:
   - **Approved standards** (APIs validated and recommended for use)
   - **Cautioned APIs** (APIs with caveats — beta, edge cases, performance considerations)
   - **Rejected patterns** (deprecated or anti-patterns to avoid)
   - **Established conventions** (naming, structure, deployment targets)

6. **Highlight any POTENTIALLY STALE verdicts** (`>90 days` old per the staleness threshold in `instructions.md`) that need re-validation. Flag with the staleness marker; do not silently recite stale entries as current truth.

7. **Surface established patterns** that should guide new feature work — the standards-enforcement role of this command.

## Output structure

Categorized headings, no narrative wrapper. ME is an inventory, not a memoir.

```
🍎 What I know about this project's Apple stack:

  ## Approved Standards (N entries)
  - <API> (validated YYYY-MM-DD, source: <doc URL>)
  - ...

  ## Cautioned APIs (N entries)
  - <API> ⚠ <caveat> (validated YYYY-MM-DD)
  - ...

  ## Rejected Patterns (N entries)
  - <API> — REJECTED, supersedes by <replacement>
  - ...

  ## Established Conventions
  - Deployment targets: <list>
  - Framework conventions: <bullets>

  ## Cited WWDC Sessions (N)
  - WWDCYY-NNNN: <title> (relevance: <area>)
  - ...

  ⚠ Stale verdicts (>90 days, recommend re-validation):
  - <API> — last validated YYYY-MM-DD
```

## Empty-sidecar branch

If `api-decisions.md` has no entries beyond the template scaffold AND `project-patterns.md` is empty:

```
🍎 I haven't validated any APIs for this project yet — the sidecar is empty.

  Want to start with VA on a specific API? Or LN on a framework you're learning?
```

Stop there. Do not invent verdicts.

## Sidecar write criteria

ME does NOT write insights. It is read-only by design. The only exception: ME may APPEND a session note to `memories.md` (e.g. *"YYYY-MM-DD: User invoked ME for standards review of payment-flow APIs"*).

## Failure modes to defend against

- **Confident recital of stale verdicts** — anything `>90 days` must surface the staleness flag, not be recited as current truth.
- **Narrative wrapper** — *"Over our journey together, we've come to favor SwiftUI over UIKit because..."* No. Categorized bullets. ME is an inventory.
- **Silent omission of stale entries** — show them with the staleness flag; user decides what to trust.
- **Inventing entries** — if `api-decisions.md` is empty, ME does not synthesize "probable verdicts" from general knowledge. ME is pure sidecar read.
