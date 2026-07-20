---
title: 'W83 — delete AnalysisIntensity.progressiveThreshold and its dead gate'
type: 'refactor'
created: '2026-07-20'
status: 'done'
baseline_commit: '0af2b10'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `AnalysisIntensity.progressiveThreshold: Double?` returns `0.40` for levels 6-10 and `nil` for 1-5, but its sole consumer only checks `== nil`, so the payload is never compared. The gate it drives is itself inert: `windowSizes` is the loop's only iteration source and levels 1-5 have exactly one window, so the `break` fires on a one-element loop that would have ended anyway. The public API advertises a threshold that does nothing, and two canonical docs claim the non-nil value is what enables multi-window analysis.

**Approach:** Delete the property and the `break`, leaving `windowSizes` as the single source of truth for which windows run. Correct the docs describing the removed mechanism. Pre-1.0 with no external consumers, so the source break is free; corpus floors are the regression net.

## Boundaries & Constraints

**Always:** Behavior unchanged on all ten levels — this is dead-code deletion, not an analysis change. The four corpus floors hold and the current measurement (OA300 58/82, 74/82) must not move at all. Doc edits stay within the Epic 11 authoring rules the FR-50 validator enforces (identifiers in italics not backticks, one physical line per paragraph, three-bold-lead structure).

**Ask First:** Any change to which windows run, or any behavior difference at any level. Adding a replacement property of any name or type. Touching `windowSizes` values.

**Never:** No `Bool` replacement, no `isProgressive` — both re-encode what `windowSizes` already states, and a second encoding can later diverge from the array that drives the loop. No wiring `0.40` to a real confidence-gated early stop; that is a new feature needing its own spec and corpus validation. No rewriting historical `_bmad-output/implementation-artifacts/` story specs.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Single-window levels | Intensity 1-5 | One window runs, as before; loop ends by exhaustion not `break` | N/A |
| Multi-window levels | Intensity 6, and 7-10 | Every configured window runs and merges, as before | N/A |
| Window yields no result | A window returning nil | `completed` increments, loop continues; this path never reached the `break` | N/A |
| Cancellation | Cancelled between windows | Same observation points, check precedes each window in both versions | `CancellationError` |
| Progress reporting | Any level with `onProgress` | Same update count and `windowsTotal`, driven by `windowSizes.count` | N/A |
| Public API removal | Consumer source reading the property | Compile error, intended and accepted pre-1.0 | N/A |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKit/AnalysisIntensity.swift:151` — property to delete; `:106` comment calls it one of three exhaustive per-level switches, now two.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:1181` — the dead gate; `:1177` its comment; `:1149` shows `windowSizes` is the loop's only iteration source, with no `Options` override.
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:255,271,275,302,317` — five assertions, including a per-level table at `:302` and a levels-8-10-match-7 check at `:317`.
- `README.md:98,111` — "progressive-retry threshold" and "threshold-gated retry".
- `.../Resources/Documentation/AnalysisIntensity/level6.md:5` + `level7.md:5` — the false causal claim.

## Tasks & Acceptance

**Execution:**
- [x] `AnalysisIntensity.swift` — delete the property; correct the `:106` three-switches comment to two.
- [x] `AudioAnalysisService.swift` — delete the `break` and its comment.
- [x] `BPMAnalyzerTests.swift` — remove all five assertions and the threshold column, keeping `techniqueSet` / `windowSizes` coverage intact.
- [x] `Tests/BoomBoomBoomKitTests/` — add a per-level test asserting the window count actually executed equals `windowSizes.count` for all ten levels, so the deleted gate cannot silently regress into an early stop.
- [x] `README.md` — rewrite :98 and :111 to describe multi-window analysis by window count, no threshold.
- [x] `level6.md` + `level7.md` — attribute multi-window behavior to `windowSizes`; re-check levels 1-5 and 8-10 docs for retry phrasing implying a gate.
- [x] `deferred-work.md` — mark W83 resolved, recording that BOTH the payload and the gate were inert, not just the payload as filed.

**Acceptance Criteria:**
- Given any of the ten levels, when a track is analyzed before and after, then BPM, confidence, and candidates are byte-identical (`Double.bitPattern`).
- Given `make test`, when it runs, then it passes and `grep -rn progressiveThreshold Sources/ Tests/` returns nothing.
- Given `make benchmark` and `make benchmark-giantsteps`, then all four floors hold and OA300 still measures 58/82 and 74/82.
- Given `make docc-validate`, then the FR-50 validator and the transclude check both pass.

## Design Notes

The inertness proof, verified independently twice (by me, and by Codex against the real loop):

```
level 1     windowSizes [15]        1 window   nil   -> break after the only iteration
levels 2-5  windowSizes [30]        1 window   nil   -> break after the only iteration
level 6     windowSizes [30,60]     2 windows  0.40  -> never breaks
levels 7-10 windowSizes [30,60,90]  3 windows  0.40  -> never breaks
```

The `break` can only fire where nothing remains to iterate. A nil-result window takes `continue` before reaching it. `windowSizes` is captured before the loop, so no callback can extend it. Nothing after the loop reads `completed`, and no loop-scoped `defer` differs between `break` and exhaustion.

The new window-count test matters more than the deletion: it pins the property the deleted code appeared to provide, so a future early stop cannot land without a failing test.

## Verification

**Commands:**
- `make fmt && make lint` — expected: clean, 0 serious.
- `make test` — expected: all pass, no `progressiveThreshold` under `Sources/` or `Tests/`.
- `make benchmark` — expected: OA300 58/82 and 74/82, floors hold.
- `make benchmark-giantsteps` — expected: Acc1 >= 537/661, Acc2 >= 546/661.
- `make docc-validate` — expected: validator, drift suites, and transclude check green.

## Suggested Review Order

**The deletion (start here)**

- The dead gate itself: a `break` that could only fire where nothing remained to iterate.
  [`AudioAnalysisService.swift:1173`](../../Sources/BoomBoomBoomKit/AudioAnalysisService.swift#L1173)

- The removed property, and the exhaustive-switch comment re-scoped from three switches to two.
  [`AnalysisIntensity.swift:102`](../../Sources/BoomBoomBoomKit/AnalysisIntensity.swift#L102)

- `windowSizes`, now the single source of truth for how many windows run.
  [`AnalysisIntensity.swift:136`](../../Sources/BoomBoomBoomKit/AnalysisIntensity.swift#L136)

**The regression net (the part that matters most)**

- Asserts executed windows equal `windowSizes.count` at all ten levels; fails if any early stop returns.
  [`AudioAnalysisServiceTests.swift:394`](../../Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift#L394)

- Five threshold assertions removed; `techniqueSet` and `windowSizes` coverage kept intact.
  [`BPMAnalyzerTests.swift:250`](../../Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift#L250)

**Docs that described a mechanism which never functioned**

- The false causal claim corrected: multi-window comes from the window list, not a threshold.
  [`level6.md`](../../Sources/BoomBoomBoomKit/Resources/Documentation/AnalysisIntensity/level6.md)

- Same correction at the default level, plus an explicit no-early-stop statement.
  [`level7.md`](../../Sources/BoomBoomBoomKit/Resources/Documentation/AnalysisIntensity/level7.md)

- Intensity table and pipeline prose restated in terms of window count.
  [`README.md:95`](../../README.md#L95)
