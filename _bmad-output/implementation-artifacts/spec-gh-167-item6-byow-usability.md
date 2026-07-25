---
title: 'GH-167 item 6 — BYOW usability (#144, #150, #124)'
type: 'bugfix'
created: '2026-07-25'
status: 'done'
review_loop_iteration: 0
baseline_commit: 'e92445d'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** BYOW is the only shipped ML path, and its three sharpest edges each hand the consumer a wall. Abstain thresholds are `internal static let`s reachable only through a `@testable` process-global `Mutex`, so a conservatively-confident consumer model abstains near-totally with no recourse short of reimplementing `MLTechnique` (#144). `BNNSGraphHandle.deinit` calls `free(graph.data)` on the strength of a single 2026-05-13 probe run against a model that no longer ships, with no runtime check and no API contract behind it (#150). And `MLDiagnosticSnapshot`'s public init imposes `BNNSTechnique`'s control-flow graph on every foreign conformer via 10 trapping calls — two of its own public `CaseIterable` cases being guaranteed traps (#124).

**Approach:** Move the thresholds onto the instance and delete the global override seam outright; gate both `free` sites on a runtime allocator-zone check that leaks deliberately rather than corrupting the heap; and restructure `MLDiagnosticSnapshot` so illegal shapes are unrepresentable rather than trapped, with computed projections so every read site compiles unchanged.

## Boundaries & Constraints

**Always:**
- Every existing *read* of `MLDiagnosticSnapshot` compiles unchanged. The five computed projections (`decodedBPM`, `softmaxMax`, `softmaxSecondMax`, `failureStage`, `gateFired`) are the compatibility surface — the FR-18 harness's authoritative `decodedBPM` signal must draw from all three decode-bearing outcomes.
- `make test` stays green with no corpus env. Baseline is **929 tests / 160 suites / 4 known issues**; it may rise, never fall.
- Every new guard bite-proven by temporary mutation, reverted from a scratchpad copy — never `git checkout`.
- The zone-gate failure path is observable (`os_log`), never silent.
- `AudioAnalysisResult` / DSP output byte-identical; no accuracy floor moves.

**Ask First:** Any change to `MLTechnique` / `MLDiagnosticTechnique` protocol signatures (frozen, Story 4-5 DD #18). Any new environment variable. Any new `MLTechniqueError` case.

**Never:** Deprecation shims, BC aliases, or `@available(*, deprecated)` cycles — pre-1.0, breaking is the point. Positional-argument sprawl on any public initializer. Retaining `precondition` on a public initializer reachable by a foreign conformer. Touching the DSP pipeline or the benchmark floors.

**Decisions frozen at planning (operator, 2026-07-25):**
1. All three issues ship in **one PR**. #124 is promoted out of the #167 "API consistency pass" bucket.
2. Non-finite thresholds **throw**; finite out-of-range thresholds **clamp** silently to `[0, 1]`.
3. `MLDiagnosticSnapshot` becomes checksum + a payload-carrying `Outcome` enum. Codex ranked the minimal total-init variant first; **overruled on API-quality grounds** — a six-argument public init of `Double?`/`Optional` values lets a caller transpose arguments silently.
4. `.featuresAbsent` / `.featureVersionMismatch` are **removed**, not legalized: `inputFeatureChecksum` is non-optional and those paths have no features to checksum. The benchmark gets its own private outcome-key enum, replacing today's bare string literals.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Threshold defaults | `init(modelURL:)`, no threshold args | `confidenceThreshold == 0.50`, `marginThreshold == 0.10` | n/a |
| Consumer tuning | `0.2` / `0.05` | stored verbatim; both gates read the instance | n/a |
| Threshold out of range | `1.5` / `-0.2` | clamped to `1.0` / `0.0`; init succeeds | silent, documented |
| Threshold non-finite | `.nan` / `.infinity` | init **throws** | `MLTechniqueError`, no new case |
| Gate evaluation | any configured instance | both gates read `self`, single instance read | mixed-state race structurally impossible |
| Graph free, default zone | `malloc_zone_from_ptr` == default zone | `free(graph.data)` | n/a |
| Graph free, foreign/nil zone | probe returns other zone or NULL | **deliberate leak** + `os_log` fault naming the zone | non-fatal; never frees |
| Snapshot, win | `.win(Decode)` | `decodedBPM`/`softmaxMax`/`softmaxSecondMax` non-nil, `failureStage` nil, `gateFired` nil | n/a |
| Snapshot, pre-decode abstain | `.featurizeRejected` / `.graphFailed` | all decode projections nil, `gateFired` nil | n/a |
| Snapshot, decode rejected | `.decodeRejectedNonFinite` vs `.decodeRejectedOutOfRange(Decode)` | both project `failureStage == .decodeRejected`; only the latter carries decode values | n/a |
| Snapshot, gate abstain | `.confidenceGateRejected(Decode, gate:)` | decode projections non-nil, `gateFired` non-nil | n/a |
| Snapshot, illegal shape | e.g. gate fired with no decode | **does not compile** | structural, not runtime |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` — `:107-140` the two `internal static let` thresholds + the `thresholdOverride` `Mutex`; `:142-174` `effectiveThresholds` / `effectiveConfidenceThreshold` / `effectiveMarginThreshold`; `:264` the sole public init; `:299` **first** `free` site (validateContract throw path); `:437-451` the two gate reads inside the *private instance* method `evaluateInternal`; `:378-475` the 7 snapshot constructions; `:1113-1142` `BNNSGraphHandle` + `:1140` **second** `free` site.
- `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift` — `:171-263` the public init with 9 `precondition` + 1 `preconditionFailure`; `:134-160` `FailureStage` (6 cases, 2 unconstructible); `:162-169` `Gate`; `:265-277` `description`.
- `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift:111-113` — non-throwing protocol requirement. **Read-only**: it is why the producer cannot propagate a throw.
- `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift` — `:556-571` the cross-suite-race caveat that the fix retires; `:604/659/716` override set+`defer`; `:643` reads the static constant.
- `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift` — `:384-412` env-driven override + `defer`; `:654-666` the bare `"featuresAbsent"` / `"featureVersionMismatch"` string literals.
- `Tests/BoomBoomBoomKitBenchmarkTests/FR18EvaluationHarnessTests.swift:230` — reads `snapshot.decodedBPM`. Must compile unchanged.
- `Demo/.../TraceExport.swift:563-587`, `TraceView.swift:288-315` — snapshot readers; must compile unchanged and keep byte-identical JSON.
- `_bmad-output/implementation-artifacts/4-5-allocator-probe.log` — the entire evidentiary basis for #150. One run, 2026-05-13, against a removed model.

## Tasks & Acceptance

**Execution:**
- [x] `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` — added `public let confidenceThreshold` / `marginThreshold`; statics renamed to `public static let defaultConfidenceThreshold` / `defaultMarginThreshold`; init extended with defaulted params (isFinite-first throw, then `[0,1]` clamp); both gates read `self`. Deleted `thresholdOverride`, `effectiveThresholds`, `effectiveConfidenceThreshold`, `effectiveMarginThreshold`, and the now-unused `import Synchronization`.
- [x] `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` — added `releaseGraphData(_:) -> Bool`, called at **both** free sites (init throw path + `BNNSGraphHandle.deinit`). Returns the decision so a wrongly-refusing guard is observable rather than a silent leak.
- [x] `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift` — restructured to `inputFeatureChecksum` + `Outcome`; nested `Decode` added; all 10 trap sites deleted; the two unconstructible `FailureStage` cases removed; five computed projections added; matrix doc rewritten as *`BNNSTechnique`'s emission matrix*.
- [x] `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` — 7 snapshot constructions migrated to `Outcome` cases.
- [x] `Sources/BoomBoomBoomKit/MLTechnique.swift` — added `invalidThreshold(reason:)` (operator-authorized mid-flight, see Change Log) and corrected the stale "four cases" doc.
- [x] `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift`, `BPMDiagnosticTrace.swift` — doc comments naming the two removed cases corrected.
- [x] `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift` — 3 override+`defer` sites replaced with construction-time thresholds; the 16-line race caveat and the `.serialized` trait it justified both removed; assertion retargeted to `t.confidenceThreshold`.
- [x] `Tests/BoomBoomBoomKitTests/MLDiagnosticSnapshotTests.swift`, `MLDiagnosticSnapshotPathCoverageTests.swift`, `AudioAnalysisServiceInoutTraceTests.swift` — 15 constructions migrated; `allCases` retargeted to 4; shape-rule tests rewritten as projection tests (the rules they asserted are now type errors).
- [x] `Tests/BoomBoomBoomKitTests/BNNSTechniqueDiagnosticTests.swift` — producer-contract test added: drives the real fixture across gate-rejection, win, and pre-featurize, asserting each carries exactly its stage's evidence.
- [x] `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift` — env thresholds threaded through the constructor; the 9 bare string keys replaced by a private `OutcomeKey` enum whose `allCases` now drives the histogram seed, the bucket assignment and the print loop (previously three hand-maintained lists).
- [x] `Tests/BoomBoomBoomKitTests/` — new cases for defaults, verbatim storage, clamping, non-finite throw, per-instance independence, and both zone-gate branches.
- [x] `_bmad-output/implementation-artifacts/deferred-work.md` — 4 item-6 entries with re-open triggers.

**Acceptance Criteria:**
- Given a BYOW consumer with a conservatively-confident model, when they construct `BNNSTechnique(modelURL:confidenceThreshold:marginThreshold:)`, then both gates honour their values with no `@testable` access and no global state.
- Given two `BNNSTechnique` instances with different thresholds, when both evaluate concurrently, then neither observes the other's values.
- Given a `graph.data` pointer outside the default malloc zone, when the handle deinits, then nothing is freed and a fault is logged naming the zone.
- Given any consumer `MLDiagnosticTechnique` conformer, when it constructs a snapshot, then no input can trap or throw, and no illegal shape compiles.
- Given the FR-18 harness and the Demo, when built against the new shape, then they compile unchanged and the exported JSON is byte-identical.

## Spec Change Log

**2026-07-25 — `MLTechniqueError.invalidThreshold` added (operator-authorized).**
The frozen I/O matrix said "`MLTechniqueError`, no new case" and Boundaries gated
any new case under **Ask First**. Implementation hit that boundary immediately:
none of the five existing cases describes a bad *argument* — all five describe a
bad *model*. Reusing `.modelLoadFailed` would tell a consumer their model failed
to load when the model was fine. Operator authorized the sixth case. The stale
"four cases" doc comment on the enum (it declared five) was corrected in the same
edit. Known-bad state avoided: a consumer catching `.modelLoadFailed` and
re-exporting a perfectly good model.

**2026-07-25 — adversarial review pass (two lenses), 8 patches applied, 5 deferred.**
No `intent_gap` or `bad_spec` finding — nothing challenged the frozen intent, so
no loopback. The two findings that mattered:

1. **The zone tests did not test the zone policy.** The refusal case used only a
   stack pointer, whose zone is `nil`, so weakening the guard to `zone != nil` —
   dropping the default-zone comparison entirely — passed every test. Closed with
   a `malloc_create_zone` case that is genuinely malloc-owned and genuinely not
   the default zone. **KEEP on re-derivation:** the refusal branch needs BOTH an
   unowned pointer and a foreign-zone allocation; either alone leaves a hole.
2. **`marginThreshold` was stored but never exercised.** The fixture fails gate 1
   at production thresholds, so gate 2 never decided anything and `if margin < 0.0`
   would have passed the suite. Closed with a gate-1-open / gate-2-varied case
   asserting `gateFired == .gate2Margin`.

Also patched: the benchmark recorded *requested* rather than *applied* thresholds
(an env override of 1.5 ran inference at 1.0 while the JSON claimed 1.5 — a sweep
artifact misdescribing its own configuration); the `1.0 always abstains` claim in
three places, false because the gates compare with `<`; stale type-level docs
still describing an unconditional `free` and fixed 0.50/0.10 thresholds; the
initializer's undocumented new parameters and throw; a broken DocC link to the
old `init(modelURL:)` label; the `inputFeatureChecksum` doc naming the log-mel
stream when normal inference hashes the post-featurize tensor; and six stale
comments describing the deleted global override.

**2026-07-25 — `releaseGraphData` returns `Bool`.**
The first version returned `Void`, which made `freesDefaultZoneAllocation` assert
nothing: a guard that wrongly refused would leak silently and the test would still
pass. That is the measure-nothing shape GH-167 item 4 exists to close, reintroduced
inside item 6's own fix. The function now returns whether it freed, and both tests
assert the decision. **KEEP on re-derivation:** the return value exists for
observability, not for callers — `deinit` discards it.

## Design Notes

**Why the thresholds move to the instance rather than gaining a second override path.** `evaluateInternal` is a *private instance* method, so `self` is already in scope — no signature change. The existing `Mutex` seam exists only because the constants were static, and it carries a documented cross-suite race (`BNNSTechniqueTests.swift:556-571`) that survives today purely on invocation topology. Per-instance state retires the P13 mixed-state race structurally: both gates read one `self`, so there is no window to observe a half-updated pair.

**Why the zone gate rather than a re-run probe.** #150 asks for an availability check per probed OS release, but the SDK still ships no graph destructor — `BNNSGraphCompileOptionsDestroy` and `BNNSGraphContextDestroy` exist; there is no `BNNSGraphDestroy` (verified against the Xcode 26 SDK headers, 2026-07-25). An OS allowlist would need editing every release and says nothing about a graph compiled with `SetOutputPath`, which the Story 4-5 notes flag as possibly `mmap`'d. A runtime zone check answers the actual question at the actual moment, on every instance, on every OS. Leaking a graph is bounded and survivable; `free`-ing framework memory is not.

**Why unrepresentable beats throwing for the snapshot.** `MLFeatureFrames`' invariants are load-bearing — its dimensions size buffers handed to `vDSP_mtrans` as raw pointers, so a short payload reads out of bounds. Nothing indexes a snapshot; every field is already `Optional` and every reader is optional-safe. Worse, the init enforces facts it cannot know: it never sees the paired `MLEvaluation?`, cannot verify the checksum describes the documented buffer, and does not check the softmax ranges it documents — partial validation presented as a complete contract, with process termination as the failure mode.

## Verification

**Results (2026-07-25, baseline `e92445d`):**

| Check | Result |
|---|---|
| `swift build` | Clean, zero new warnings |
| `make fmt && make lint` | 6 violations, 0 serious — all pre-existing, in build artifacts |
| `make test` (no corpus env) | **941 tests / 161 suites, 4 known issues, green** (baseline 929/160/4; +12 tests, +1 suite) |
| `make demo-build` | `** BUILD SUCCEEDED **`, 0 errors — confirms the computed projections hold every Demo read site unchanged |
| `make benchmark` | 11/11 pass. **Acc1 58/82 (70.7%), Acc2 74/82 (90.2%)** — floors 57/73 hold, and the values match those documented in CLAUDE.md. Not asserted as a before/after delta (no measured `e92445d` run exists to compare against); the basis for expecting no change is that no DSP production behaviour was touched |

The 4 known issues are the untouched `AccuracyFloorTests` octave ratchets from
item 5. No accuracy floor moved.

**Bite proofs** — each mutated, observed, then reverted from a scratchpad copy
(never `git checkout`), with SHA-256 re-verification of the restored file:

| Guard | Mutation | Result |
|---|---|---|
| Non-finite thresholds throw | `guard true` in place of the `isFinite` pair | fails, 3 recorded issues |
| Out-of-range clamps | clamp replaced by pass-through | fails: `(high.confidenceThreshold → 1.5) == 1.0` |
| Zone gate frees default-zone storage | guard forced to always refuse | fails: `releaseGraphData(p)` returned false |
| **Zone gate is load-bearing** | guard removed entirely | **process aborts, signal 6 (SIGABRT)** — `free()` on a non-malloc pointer kills the runner |
| Illegal snapshot shapes | 3 formerly-legal, formerly-trapping calls appended | all 3 are **compile errors**: missing `Decode` argument ×2, `no member 'featuresAbsent'` |
| Zone policy is default-zone-only | guard weakened to `zone != nil` | fails: the `malloc_create_zone` case refuses to accept a foreign-zone allocation |
| Gate 2 reads `marginThreshold` | gate 2 threshold replaced with a `0.0` literal | fails: `gateFired` is not `.gate2Margin` |

The SIGABRT proof is the one that matters for #150: it establishes that removing
the guard is dangerous, not merely different.

**Manual checks:**
- `grep -rn 'thresholdOverride' Sources/ Tests/` — zero matches.
- `Sources/BoomBoomBoomKit/` diff outside `MLDiagnosticSnapshot.swift` / `MLTechnique.swift` is doc-comment-only.

## Suggested Review Order

**#124 — the shape that makes traps unnecessary (start here)**

- The design intent in one declaration: each case admits only its own evidence.
  [`MLDiagnosticSnapshot.swift:170`](../../Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift#L170)

- Total init — nothing to validate, so nothing can trap or throw.
  [`MLDiagnosticSnapshot.swift:124`](../../Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift#L124)

- The compatibility surface: every existing reader goes through here unchanged.
  [`MLDiagnosticSnapshot.swift:199`](../../Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift#L199)

- Grouping the three co-produced values is what kills the all-nil-or-none rule.
  [`MLDiagnosticSnapshot.swift:139`](../../Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift#L139)

- Four cases, not six: the two removed had no checksum to carry.
  [`MLDiagnosticSnapshot.swift:261`](../../Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift#L261)

**#144 — thresholds move to the instance**

- Per-instance `let`s; the mixed-state race becomes impossible, not guarded.
  [`BNNSTechnique.swift:141`](../../Sources/BoomBoomBoomKitML/BNNSTechnique.swift#L141)

- isFinite-first, then clamp — a caller bug throws, saturating intent does not.
  [`BNNSTechnique.swift:254`](../../Sources/BoomBoomBoomKitML/BNNSTechnique.swift#L254)

- Both gates read one `self`; no accessor, no lock, no snapshot window.
  [`BNNSTechnique.swift:423`](../../Sources/BoomBoomBoomKitML/BNNSTechnique.swift#L423)

- Shipped defaults, now public and documented as a starting point, not advice.
  [`BNNSTechnique.swift:124`](../../Sources/BoomBoomBoomKitML/BNNSTechnique.swift#L124)

- A bad argument is not a bad model — the two have unrelated remedies.
  [`MLTechnique.swift:214`](../../Sources/BoomBoomBoomKit/MLTechnique.swift#L214)

**#150 — the graph release is checked, not assumed**

- Frees only default-zone storage; returns the decision so refusal is observable.
  [`BNNSTechnique.swift:1124`](../../Sources/BoomBoomBoomKitML/BNNSTechnique.swift#L1124)

- The deinit site — one of two; the other is the init's validation-failure path.
  [`BNNSTechnique.swift:1172`](../../Sources/BoomBoomBoomKitML/BNNSTechnique.swift#L1172)

**Tests that would fail if the guards were weakened**

- Foreign-zone allocation: without this, `zone != nil` would pass everything.
  [`BNNSTechniqueTests.swift:692`](../../Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift#L692)

- Gate 2 in isolation; the fixture otherwise never lets it decide anything.
  [`BNNSTechniqueTests.swift:794`](../../Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift#L794)

- Two instances disagreeing on one input — unexpressible with a global.
  [`BNNSTechniqueTests.swift:770`](../../Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift#L770)

- The matrix asserted against the producer that actually claims it.
  [`BNNSTechniqueDiagnosticTests.swift:98`](../../Tests/BoomBoomBoomKitTests/BNNSTechniqueDiagnosticTests.swift#L98)

- Non-finite rejection across all four NaN/Inf argument positions.
  [`BNNSTechniqueTests.swift:118`](../../Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift#L118)

**Peripheral**

- Harness taxonomy replacing nine bare strings across three parallel lists.
  [`BNNSImpactTests.swift:156`](../../Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift#L156)
