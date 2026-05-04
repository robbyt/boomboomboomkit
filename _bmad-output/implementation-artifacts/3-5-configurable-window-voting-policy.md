# Story 3.5: Configurable Window Voting Policy

Status: done

## Key Design Decisions

1. **`VotingPolicy` parameterizes the existing `.windowVoting` merge strategy — it does NOT add new `CandidateMergeStrategy` cases.** The epic AC says "the window voting logic uses the specified policy at runtime." Adding a `windowVotingConfidenceWeighted`, `windowVotingThresholdGated`, etc. would explode `CandidateMergeStrategy.allCases` (currently 8) by 3× and double-encode the same axis — once at the strategy level (which clustering family), again as policy variants of one family. Keep `CandidateMergeStrategy.allCases.count == 8` (regression guard) and introduce `VotingPolicy` as a sibling axis: `(strategy = .windowVoting) × (policy ∈ {.simpleMajority, .confidenceWeighted, .thresholdGated})`. Other strategies ignore policy/threshold (the parameters are window-voting-specific). This matches the precedent in Story 3-4 where `durationHint` added a new Options field rather than a new `DSPTechnique` case (DD#1 of 3-4).

2. **Default policy is `.simpleMajority` — preserves the post-Story-3-3a baseline byte-for-byte.** Current `mergeByWindowVoting` (CandidateMergeStrategy.swift:123-148) implements simple-majority semantics: group windows by 2% BPM tolerance, take the largest group with ≥ 2 windows, break ties within the group by max confidence, fall back to `maxConfidence` overall when no consensus. The new `.simpleMajority` case must reproduce this exactly. AC #4 is the unconditional-`#expect` regression gate: `Options()` with `mergeStrategy = .windowVoting` produces the same `BPMResult` as the pre-Story-3-5 implementation across both corpora.

3. **Three policy semantics, one shared tolerance.** All three policies cluster windows using the same 2% relative tolerance (`isNearMatch`, CandidateMergeStrategy.swift:247-251) — this is the project-wide BPM tolerance (matches Acc1, matches `Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift:7`, matches Story 3-4's `durationHintTolerance`). Policies differ only in the SCORING/GATING after clusters are built:
   - **`.simpleMajority`** — pick the cluster with the most windows (`indices.count >= 2` required); break ties between equal-count clusters by max single-window confidence within the cluster; otherwise fall back to `maxConfidence` overall. **No threshold.** Equivalent to current behavior.
   - **`.confidenceWeighted`** — pick the cluster with the highest summed confidence; break ties between equal-summed-confidence clusters by max single-window confidence within the cluster, then by lowest original window index (per DD#16). **If the picked cluster is a singleton, fall back to `mergeMaxConfidence(results)`** (a singleton's summed confidence equals its single window's confidence, so there's no consensus benefit — fall back for clarity rather than returning a result indistinguishable from `.maxConfidence`). **No threshold.** Permits a 2-vs-1 tie to be decided by confidence sums rather than picking the larger group.
   - **`.thresholdGated`** — like `.simpleMajority` but the chosen cluster's max single-window confidence must be `>= votingThreshold`; if not, fall back to `maxConfidence` overall. **`votingThreshold ∈ [0.0, 1.0]`**, default `0.0` (gate is permissive — equivalent to `.simpleMajority`). Sweepable via the benchmark loop without recompiling.

4. **`votingThreshold` is a separate `Double` parameter on `Options`, NOT an associated value on the enum.** The epic AC explicitly forbids associated values: "`VotingPolicy` conforms to `CaseIterable`, `Sendable`, `Hashable` (no associated values -- threshold is a separate parameter)." This decision is identity-of-the-type: enums with associated values cannot synthesize `CaseIterable`, and `allCases` is what makes the benchmark sweep tractable. The threshold is consulted ONLY by `.thresholdGated` — the other two policies ignore it. This matches Story 3-4's pattern where `durationHintMinFileSeconds: Double` lives next to `durationHint: Bool` rather than being parameterized into the Bool's "on" state.

5. **Public API surface lands on `AudioAnalysisService.Options` per ADR-11.** Two new fields:
   - `public var votingPolicy: VotingPolicy = .simpleMajority` (non-optional with default — same shape as `mergeStrategy: CandidateMergeStrategy = .maxConfidence`)
   - `public var votingThreshold: Double = 0.0` (non-optional with default — same shape as `durationHintMinFileSeconds: Double = 180`)

   No new method overloads. No new positional parameters on `analyzeBPM`. The fields only take effect when `mergeStrategy == .windowVoting` — for any other strategy they are ignored (documented in field doc-comments). Similar precedent: `durationHintMinFileSeconds` only takes effect when `durationHint == true` (Story 3-4). The Field-style convention doc-block in `AudioAnalysisService.Options` must be updated to list both new fields under "always-present configuration with a sensible default."

6. **Internal `merge(...)` signature gets two new defaulted parameters; `mergeByWindowVoting` is refactored, NOT renamed.** The internal helper at `CandidateMergeStrategy.merge(windowResults:candidateCount:strategy:)` adds two trailing parameters: `votingPolicy: VotingPolicy = .simpleMajority` and `votingThreshold: Double = 0.0`. Default values preserve the current call sites (zero-touch for callers that don't care). The private static `mergeByWindowVoting(_:)` becomes `mergeByWindowVoting(_:policy:threshold:)`. The dispatcher inside `merge(...)` switches on policy:
   ```swift
   case .windowVoting:
     return mergeByWindowVoting(windowResults, policy: votingPolicy, threshold: votingThreshold)
   ```
   The other 7 cases drop the new parameters (they don't apply). Internal call site is `AudioAnalysisService.analyzeBPM` (AudioAnalysisService.swift:234-238): pass `votingPolicy: options.votingPolicy, votingThreshold: options.votingThreshold`.

7. **Tiebreakers within the chosen cluster stay deterministic — via EXPLICIT index secondary, not implicit `max(by:)` stability.** For all three policies, once the winning cluster is chosen, the representative window is selected by:
   ```swift
   let bestIndex = cluster.indices.min { lhs, rhs in
     let lConf = results[lhs].confidence
     let rConf = results[rhs].confidence
     if lConf != rConf { return lConf > rConf }    // higher confidence wins
     return lhs < rhs                                // lower original index wins
   }!
   ```
   Apple's `max(by:)` / `min(by:)` documentation defines a strict-weak-ordering contract but does NOT promise first-equal stability; relying on undocumented stability is fragile (Codex FMA 2026-04-28). The explicit `lhs < rhs` secondary key is the same hardening pattern Story 3-3 DD#6 applied to the candidate-sort tiebreaker and Story 3-4 DD#10 applied to the boost-sort tiebreaker. Apply the same shape to ALL three policy-helper tiebreaker sites: cluster selection (when sizes / summed-confidences tie), and within-cluster window selection (when confidences tie). See DD#16 for the cross-helper rule.

8. **Fallback path is uniform across policies — `maxConfidence` over ALL windows, not just the failing cluster.** Same as today's `mergeByWindowVoting`: when no cluster qualifies under the policy's gating rule, dispatch to `mergeMaxConfidence(results)`. This makes the policy boundaries crisp: each policy is a SUPERSET of `maxConfidence` (every input that produces a non-fallback result under the policy could also be answered by `maxConfidence`, but the policy may pick differently). Crucial for AC #4's "default `.simpleMajority` matches pre-Story-3-5 baseline" gate — fallback semantics are identical to today.

9. **`votingThreshold` validation: silent clamp to `[0.0, 1.0]`, NaN/Inf falls back to 0.0 — normalization happens INSIDE `resolveThresholdGated`, not in the dispatcher.** Mirrors Story 3-4 Patch #6 (`durationHintMinFileSeconds` NaN → default, negative → clamp to 0). Inside `resolveThresholdGated(results:groups:threshold:)` as the FIRST line of the helper:
   ```swift
   let effectiveThreshold: Double =
     threshold.isFinite ? min(max(threshold, 0.0), 1.0) : 0.0
   ```
   Out-of-range threshold values (e.g., `2.0`, `-0.5`, `.nan`, `.infinity`, `.signalingNaN`, `-0.0`) silently degrade to a useful default. `-0.0` clamps to `0.0` via `max(threshold, 0.0)`. `.signalingNaN` is non-finite (just like `.nan`) so falls back to `0.0`. The NaN-falls-back-to-0 path means no consumer can accidentally suppress all consensus by passing a malformed threshold. Tested explicitly per AC #6.

   **Why inside the helper, not the dispatcher**: keeping the clamp inside `resolveThresholdGated` means the helper has a self-contained precondition ("any Double accepted; semantics defined for all finite + non-finite values"). If a future caller invokes the helper directly (e.g., a unit test or a future merge variant), the clamp still fires. The dispatcher (Task 2.3) passes the raw `votingThreshold` through untouched.

10. **Trace fields stay nil — voting policy is observed via the result, not via diagnostics.** The current `mergeByWindowVoting` doesn't populate any trace key; the new policy doesn't either. The benchmark's per-policy print loop is the observation mechanism. Adding a `votingDetail` trace field would expand the `BPMDiagnosticTrace` API surface for a feature whose primary use case is benchmark sweeps, not field debugging. Defer to a future story if production observability becomes important. The policy can still be inferred from the result by consumers who care: pass each policy in turn and compare `result.bpm`.

11. **Benchmark-iteration pattern: pre-read audio once, iterate `(policy, threshold)` pairs.** Mirrors `benchmarkMergeStrategies` (`OA300BenchmarkTests.swift:243-315`): pre-read all OA300 audio into `[TrackAudio]`, then iterate `(policy, threshold)` pairs in nested loops. For `.simpleMajority` and `.confidenceWeighted`, threshold is irrelevant — emit ONE row per policy. For `.thresholdGated`, sweep thresholds `[0.0, 0.25, 0.5, 0.75]` — emit FOUR rows. Total rows: `2 + 4 = 6`. Acc1/Acc2 printed per row in a table identical in shape to `benchmarkMergeStrategies`'s output. The sweep set is hardcoded (no env var override) — the default is the published table; if a future story wants to fuzz a denser range, add env-var control then.

12. **CaseIterable count regression guard.** `VotingPolicy.allCases.count == 3` is asserted in tests as a regression gate, mirroring `CandidateMergeStrategy.allCases.count == 8` (Story 3-3 close-out / current `BPMAnalyzerTests.swift:822`-equivalent). Adding a fourth voting policy (e.g., `.unanimousOnly`) would require explicit story authorization plus an updated assertion. Same gate-pattern as `DSPTechnique.allCases.count == 7` after Story 3-3.

13. **No `BPMAnalyzer` changes. No `DSPTechnique` changes. No `AnalysisIntensity.techniqueSet` changes.** This story is strictly merge-layer / public-Options work. The DSP pipeline is untouched. `BPMAnalyzer.estimateBPM(...)` produces the same per-window `BPMResult` it always has; only the cross-window MERGE behavior is parameterized. Files NOT to touch: `BPMAnalyzer.swift`, `DSPTechnique.swift` (also defines `TechniqueSet`), `AnalysisIntensity.swift`, `BPMDiagnosticTrace.swift`, `PCMBufferReader.swift`, `MelFilterbank.swift`, `LUFSAnalyzer.swift`. Skipping `BPMDiagnosticTrace.swift` is intentional per DD#10.

14. **Best-performing policy's Acc1 ≥ current windowVoting Acc1 is INFORMATIONAL, not a #expect floor.** The epic AC says "the best-performing policy's Acc1 >= current `windowVoting` Acc1" — but `make benchmark` already runs `benchmarkMergeStrategies` which prints `windowVoting` accuracy. The new `benchmarkVotingPolicies` prints policy-specific accuracy. The comparison is reproducible from the printed tables; codifying it as a `#expect` would require either (a) hardcoding the current `windowVoting` baseline as a magic number that drifts when DSP changes, or (b) running both benchmarks in the same test and comparing — which couples two benchmark suites. Neither is worth the test infrastructure cost. Keep the floor as a Completion Notes assertion (mirrors Story 3-4 AC #10's informational treatment).

15. **Returned-result contract: policy helpers return the EXACT selected `BPMResult`, byte-for-byte.** When a policy picks a window from a cluster, the returned `BPMResult` IS that window's full `BPMResult` — `bpm`, `confidence`, `candidates`, AND `trace` come from the selected window unchanged. NO recomputation. NO global-max overlay. NO mixing fields across windows. The fallback path (`mergeMaxConfidence(results)`) does the same: returns the selected window's `BPMResult` verbatim (CandidateMergeStrategy.swift:99 — `results.max(by: { $0.confidence < $1.confidence })!`). The other clustered strategies (`.dedup`, `.quorum`, etc.) DO recompute fields (synthetic `bpm` from cluster representative, `bestConfidence` as cross-window max — CandidateMergeStrategy.swift:114-116, 209-213); window voting policies do NOT. This was implicit in the current `mergeByWindowVoting` (line 143: `return results[bestIndex]`) but the spec must say it explicitly so AC #5's expected `result.confidence` values are unambiguously the selected window's confidence, not some aggregated number (Codex FMA finding on AC #5).

   **Test-side comparison strategy.** `BPMResult` does NOT conform to `Equatable` (BPMAnalyzer.swift:11-21), and `BPMResult.candidates` is `[(bpm: Double, score: Float)]` — a tuple-array which does NOT support `==` directly. Therefore tests asserting "returned `BPMResult` IS `windows[N]`" MUST use a field-by-field comparison helper. Specification:
   ```swift
   /// Asserts two BPMResult values are byte-for-byte identical (per DD#15).
   /// Use this in tests instead of `==` (BPMResult is not Equatable, and
   /// the `candidates` tuple-array cannot be compared with `==` directly).
   func assertSameBPMResult(_ got: BPMResult, _ expected: BPMResult,
                            sourceLocation: SourceLocation = #_sourceLocation) {
     #expect(got.bpm == expected.bpm, sourceLocation: sourceLocation)
     #expect(got.confidence == expected.confidence, sourceLocation: sourceLocation)
     #expect(got.candidates.count == expected.candidates.count, sourceLocation: sourceLocation)
     for (gotCand, expCand) in zip(got.candidates, expected.candidates) {
       #expect(gotCand.bpm == expCand.bpm, sourceLocation: sourceLocation)
       #expect(gotCand.score == expCand.score, sourceLocation: sourceLocation)
     }
     // Trace identity: both nil OR both non-nil with identical content.
     // BPMDiagnosticTrace is also not Equatable; use ObjectIdentifier-style
     // pointer equality is impossible for value types — fall back to:
     // (a) when enableTrace == false in tests (typical), both should be nil.
     // (b) when enableTrace == true, compare the trace fields the test cares
     //     about (typically just nil-vs-nil for these tests).
     #expect((got.trace == nil) == (expected.trace == nil), sourceLocation: sourceLocation)
   }
   ```
   The helper lives in `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift` near `makeBPMResult`. Task 5's tests use this helper exclusively for the "IS windows[N]" assertions; do NOT use bare `==` on `BPMResult` or `result.candidates`. To avoid the candidates-array-as-proxy unreliability flagged by Codex Self-Consistency, EACH synthetic `BPMResult` constructed in Task 5 tests MUST carry a UNIQUE candidates fingerprint (e.g., add a sentinel candidate `(bpm: 1.0, score: Float(windowIndex))` that uniquely identifies the source window) so two windows with otherwise-similar candidates cannot be confused for one another.

16. **Explicit deterministic tie-breakers in NEW policy helpers — never rely on `max(by:)` first-equal stability.** Wherever a NEW policy helper picks among equally-ranked options (equal-size clusters, equal-summed-confidence clusters, equal-confidence windows in `resolveSimpleMajority`/`resolveConfidenceWeighted`/`resolveThresholdGated`), break ties with an explicit secondary key on lowest original index. Apple's `Sequence.max(by:)` / `Sequence.min(by:)` docs define strict-weak-ordering but do NOT document first-equal behavior — relying on it is fragile.

   **Carve-out: the existing `mergeMaxConfidence(_:)` helper (CandidateMergeStrategy.swift:99) keeps its current `max(by:)` tie behavior unchanged.** The fallback path is a SHARED helper used by all 8 strategies (not just `.windowVoting`); modifying its tiebreaker would change observable behavior for the other 7 strategies and break AC #4's byte-equality regression gate. The fallback's equal-confidence tie behavior is "current Swift `max(by:)` behavior" — not contractually deterministic, but stable in practice on Apple platforms for the corpus inputs. If a future story wants to harden `mergeMaxConfidence`, that's a separate scope. **DD#16's "everywhere" rule applies to the THREE NEW helpers only.**

   Concrete sites where DD#16's explicit chain applies:
   - `.simpleMajority` cluster pick when 2+ clusters have equal `indices.count` ≥ 2 → pick the cluster whose max-confidence window has the highest confidence; if those tie too, pick the cluster whose lowest original index is smallest.
   - `.confidenceWeighted` cluster pick when 2+ clusters tie on summed confidence → same secondary (max single confidence) and tertiary (lowest original index) key chain.
   - Within-cluster window selection (all three policies) → highest confidence, then lowest original index. Code shape per DD#7.

   Determinism guarantees: same `[BPMResult]` input always produces the same `BPMResult` output regardless of platform, Swift version, or build configuration. Same hardening shape Story 3-3 DD#6 and Story 3-4 DD#10 applied to candidate-sort tiebreakers.

17. **Confidence input precondition: `BPMResult.confidence` is assumed finite in `[0.0, 1.0]`.** Policy helpers do NOT defensively normalize confidence values — they trust the upstream contract. `BPMAnalyzer.estimateBPM` produces confidences in this range (no internal NaN paths after Story 3-4 Patch #2 fixed the sort comparator); `mergeMaxConfidence` already trusts this. If a future BPMAnalyzer change ever leaks a non-finite confidence, the policy helpers will misbehave (NaN comparisons silently break the comparator) — but defending against that here would mean adding NaN guards to a hot path for a contract violation that doesn't exist today. Document the precondition; do NOT defensively normalize. Same posture Story 3-4 DD#9 took for the duration helper's threshold input (defensive validation only at the public-API boundary, not at every internal call site). NOTE: `votingThreshold` IS validated (DD#9) because it crosses the public-API boundary; `BPMResult.confidence` is internal-pipeline state that the policy helpers receive AFTER all the upstream guarantees apply.

18. **Benchmark computation model: precompute per-track `[BPMResult]` ONCE, then iterate policy/threshold pairs over the cached merge inputs.** Naive shape — analyze 3 windows per track per (policy, threshold) pair — would do 6× redundant DSP work for a sweep over 6 pairs. Correct shape: outer loop over tracks, analyze 3 windows once into a stored `[BPMResult]`, inner loop over the 6 pairs calling ONLY `CandidateMergeStrategy.merge(...)` on the cached results. Total cost: N tracks × 3 window analyses + N × 6 sub-microsecond merge passes. The merge-pass cost is rounding noise vs the analysis cost — wall-clock is therefore approximately **1/8 of `benchmarkMergeStrategies`'s wall-clock** (because `benchmarkMergeStrategies` re-analyzes per strategy without caching, doing 8× the DSP work; `benchmarkVotingPolicies` does 1× the DSP work plus negligible merge work). The original FMA-round claim of "75% of `benchmarkMergeStrategies`" was incorrect arithmetic — Self-Consistency review 2026-04-28 corrected this. Codex FMA flagged that the original Task 7.4 wording could be misread as per-pair re-analysis; AC #9 / Task 7 are reworded per this DD.

19. **Baseline provenance for AC #4 corpus floors: capture on a CLEAN tree on a NAMED git SHA BEFORE any Story 3-5 code lands.** The unconditional-`#expect` corpus floors (Task 8.1 → Task 8.2/8.3) work as a regression gate ONLY if the baseline was captured BEFORE Story 3-5's wiring touched the merge layer. If a dev agent captures baselines after partial wiring landed (e.g., after Tasks 1-3 to "see what number to put in the test"), they will bless the wiring's bugs as the baseline — defeating the gate. Hardening: Task 8.1 must verify `git diff --quiet && git diff --cached --quiet` before running benchmarks, and the captured numbers must be annotated with the git SHA (`git rev-parse HEAD`) in the Debug Log References section. Baseline SHA must be a parent of (or equal to) the commit that lands Tasks 1-3. If the dev agent realizes mid-implementation that they skipped the pre-implementation baseline, they MUST stash, check out the pre-implementation parent, capture, then resume — they cannot recover the baseline by "running it again with the new code disabled." Same precaution Story 3-3 / Story 3-4 implicitly relied on but never spelled out; codified here because Codex FMA flagged it as the highest-likelihood AC #4 failure mode.

## Story

As a library author,
I want the window voting resolution policy to be configurable at runtime,
so that I can compile once and sweep through different voting strategies during benchmark runs without rebuilding.

## Acceptance Criteria

1. **Given** `Sources/BoomBoomBoomKit/`
   **When** the new file `VotingPolicy.swift` is added
   **Then** `public enum VotingPolicy: String, CaseIterable, Sendable, Hashable` exists with EXACTLY three cases: `case simpleMajority`, `case confidenceWeighted`, `case thresholdGated` (in that source order)
   **And** the type has no associated values on any case (so `CaseIterable` synthesis works)
   **And** the doc-comment explains: "Resolution policy used by `CandidateMergeStrategy.windowVoting` to choose the consensus window across multiple analysis windows. The threshold value applies only to `.thresholdGated`; the other two policies ignore it."
   **And** `VotingPolicy.allCases.count == 3` (regression guard, asserted in unit tests)
   **And** `VotingPolicy.allCases.map(\.rawValue) == ["simpleMajority", "confidenceWeighted", "thresholdGated"]` is asserted (locks both case order AND rawValue stability — benchmark labels and serialized configs depend on both).

2. **Given** `AudioAnalysisService.Options`
   **When** the two new fields are added
   **Then** `public var votingPolicy: VotingPolicy = .simpleMajority` exists with a doc-comment matching the existing `mergeStrategy` non-optional-with-default pattern
   **And** `public var votingThreshold: Double = 0.0` exists with a doc-comment explaining the `[0.0, 1.0]` valid range, the silent-clamp behavior for out-of-range values, and that the field is consulted ONLY when `mergeStrategy == .windowVoting && votingPolicy == .thresholdGated` — for any other combination the field is ignored
   **And** the Options struct doc-comment's "Field-style convention" block lists `votingPolicy` and `votingThreshold` alongside `intensity`, `mergeStrategy`, `maxSeconds`, `enableTrace`, `durationHint`, `durationHintMinFileSeconds` as non-optional always-present fields with sensible defaults
   **And** a unit test asserts that for EVERY `mergeStrategy != .windowVoting` (the other 7 cases), changing `votingPolicy` and `votingThreshold` (including pathological values like `.nan` / `2.0` / `-0.5`) produces a byte-identical `BPMResult` to the default `.simpleMajority`/`0.0` configuration — proves the fields are inert outside `.windowVoting`.

3. **Given** `CandidateMergeStrategy.merge(...)`
   **When** the signature is extended
   **Then** the call site adds two trailing defaulted parameters: `votingPolicy: VotingPolicy = .simpleMajority, votingThreshold: Double = 0.0`
   **And** the dispatcher's `.windowVoting` case threads both parameters through to a refactored `mergeByWindowVoting(_:policy:threshold:)`
   **And** the other 7 strategy cases (`.maxConfidence`, `.dedup`, `.quorum`, `.average`, `.median`, `.weightedAverage`, `.union`) ignore both new parameters (their behavior is byte-identical to pre-Story-3-5)
   **And** `AudioAnalysisService.analyzeBPM` (AudioAnalysisService.swift:234-238) is updated to pass `votingPolicy: options.votingPolicy, votingThreshold: options.votingThreshold`
   **And** an Options-level integration test (Task 6.5) constructs an `AudioAnalysisService.Options` whose policy/threshold combination produces a DIFFERENT merge outcome from the default (`.simpleMajority`/`0.0`) — proves the public-API plumbing is wired through `analyzeBPM` end-to-end, not just at the merge-helper layer. A click-track smoke test does NOT satisfy this AC because click tracks are unambiguous (every policy converges on the same answer).

4. **Given** an `AudioAnalysisService.Options()` configuration with `mergeStrategy = .windowVoting`
   **When** the corpus benchmarks run with that explicit configuration
   **Then** OA300 Acc1 and Acc2 EXACTLY match the post-Story-3-4 `windowVoting` baseline captured in Task 0 BEFORE any Story-3-5 code lands (per DD#19 baseline provenance — clean tree + recorded git SHA)
   **And** GiantSteps Acc1 and Acc2 EXACTLY match the post-Story-3-4 `windowVoting` baseline (same provenance rule)
   **And** the baseline source is explicit: NOT `make benchmark` (which uses default `mergeStrategy = .maxConfidence` per `Options()` defaults), but rather the existing `benchmarkMergeStrategies` `.windowVoting` ROW for OA300, plus a parallel one-off `windowVoting` invocation for GiantSteps. The dev agent runs `OA300_CORPUS_PATH=... swift test --filter benchmarkMergeStrategies` and records the `windowVoting` row's Correct/Total numbers; for GiantSteps, the dev agent adds a TEMPORARY pre-implementation harness (or runs `make benchmark-giantsteps` configured with `mergeStrategy = .windowVoting + votingPolicy = .simpleMajority`) — the temporary harness is NOT committed; only the captured numbers + SHA are.
   **And** if the dev agent reads ONLY this AC (not Task 0 / DD#19), they see: BEFORE any code lands, clean tree, recorded SHA, baseline source explicit. The AC is self-contained; Task 0 / DD#19 are the procedural detail.
   **And** the four corpus equality assertions are unconditional `#expect`s with the captured baseline numbers HARDCODED as `let oa300Acc1Baseline = N` constants in the test methods (matching Story 3-3 AC #6, Story 3-3a AC #6, Story 3-4 AC #4 / AC #5)
   **And** the captured baseline SHA is recorded in the Debug Log References section of this story alongside the four numbers, with a `git diff --quiet && git diff --cached --quiet` precondition documented (per DD#19)
   **And** the same four metrics are recorded in Completion Notes alongside the per-policy benchmark table.

5. **Given** the unit-test gauntlet exercising the policy axis via `@testable import BoomBoomBoomKit` calling `CandidateMergeStrategy.merge(...)` (NOT direct `mergeByWindowVoting` — keep helper `private static`; tests hit the dispatcher with explicit `votingPolicy:` arg)
   **When** the dispatcher is called with hand-crafted `[BPMResult]` inputs at every policy
   **Then** the synthetic cases hold with EXACT expected `(bpm, confidence, source-window-index)` per DD#15 (returned-result contract — `result.confidence` is the SELECTED window's confidence, NOT the global max). All test inputs use input-order `[window 0, window 1, window 2]`:
   - **5a (`.simpleMajority` matches today's behavior)**: existing `windowVotingConsensus`, `windowVotingUnanimous`, `windowVotingNoConsensus`, `windowVotingTwoWindowsDisagree`, `windowVotingTwoWindowsAgree` tests all pass against explicit `policy = .simpleMajority` (re-run with the new explicit policy parameter; outcomes unchanged byte-for-byte).
   - **5b (`.confidenceWeighted` picks higher summed confidence)**: two scenarios share the same input shape, only the confidences differ:
     - **5b-i (large cluster also wins by sum)**: 3 windows `[(bpm=170, conf=0.9), (bpm=170.5, conf=0.85), (bpm=85, conf=0.95)]`. Cluster A = {0, 1} (170, summed 1.75); Cluster B = {2} (85, summed 0.95). Both `.simpleMajority` and `.confidenceWeighted` pick Cluster A. Within A, max confidence is window 0 (0.9). Expected: `result.bpm == 170.0`, `result.confidence == 0.9`, returned `BPMResult` IS `windows[0]` (DD#15).
     - **5b-ii (small cluster wins by sum)**: 3 windows `[(bpm=170, conf=0.3), (bpm=170.5, conf=0.3), (bpm=85, conf=0.95)]`. Cluster A summed 0.6; Cluster B summed 0.95. `.simpleMajority` picks Cluster A by size (`indices.count = 2 ≥ 2`) → expected `result.bpm == 170.0`, `result.confidence == 0.3`, returned `BPMResult` IS `windows[0]` (input-order tiebreaker per DD#16). `.confidenceWeighted` picks Cluster B (singleton) → falls back to `mergeMaxConfidence(results)` per DD#3 singleton rule → expected `result.bpm == 85.0`, `result.confidence == 0.95`, returned `BPMResult` IS `windows[2]`.
   - **5c (`.thresholdGated` accepts when threshold met)**: 3 windows `[(bpm=170, conf=0.9), (bpm=170.2, conf=0.7), (bpm=85, conf=0.5)]`, `policy = .thresholdGated`, `threshold = 0.6`. Cluster A = {0, 1} (max conf 0.9 ≥ 0.6 → accepted). Within A, max confidence window is 0. Expected: `result.bpm == 170.0`, `result.confidence == 0.9`, returned `BPMResult` IS `windows[0]`.
   - **5d (`.thresholdGated` falls back when threshold not met)**: same 3 windows as 5c, `threshold = 0.95`. Cluster A's max conf 0.9 < 0.95 → fallback to `mergeMaxConfidence(results)`. Global max-confidence window is 0 (conf=0.9). Expected: `result.bpm == 170.0`, `result.confidence == 0.9`, returned `BPMResult` IS `windows[0]`. NOTE: same `result.bpm` as 5a-equivalent on these inputs, BUT reached via the fallback branch — distinguish via 5e (which produces a different answer between policies).
   - **5e (`.thresholdGated` divergence from `.simpleMajority`)**: 3 windows `[(bpm=170, conf=0.4), (bpm=170.2, conf=0.3), (bpm=85, conf=0.9)]`, `threshold = 0.5`. `.simpleMajority` picks Cluster A by size → `result.bpm == 170.0`, `result.confidence == 0.4`, returned `BPMResult` IS `windows[0]`. `.thresholdGated` rejects Cluster A (max conf 0.4 < 0.5) → fallback to maxConfidence → `result.bpm == 85.0`, `result.confidence == 0.9`, returned `BPMResult` IS `windows[2]`. Assert all six concrete equalities (3 fields × 2 policies). This is the divergence test — proves the threshold gate actually fires.

6. **Given** the threshold-validation tests in `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift` (`CandidateMergingTests` suite)
   **When** the dispatcher is called with `policy = .thresholdGated` and non-canonical threshold values
   **Then**:
   - **6a (`threshold = 0.0`)**: gate accepts ANY cluster whose max confidence is `>= 0.0`. Per DD#17 confidence is finite in `[0, 1]`, so this is trivially permissive — behavior matches `.simpleMajority` for inputs where consensus exists. Assert via the same 5a-equivalent input.
   - **6b (`threshold = 1.0`)**: gate accepts ONLY clusters whose max confidence is `>= 1.0`. Real-world `BPMResult.confidence` values are strictly less than 1.0 (the pipeline never produces exactly 1.0), so the gate falls back universally. If a test crafts a synthetic window with `confidence = 1.0`, the gate WOULD accept — that boundary case is unrealistic but well-defined. Assert via 5c inputs (max conf = 0.9, fallback expected).
   - **6c (`threshold = .nan`)**: NaN is non-finite → silent normalization to `0.0` per DD#9. Behavior matches 6a. Assert `result` equals the `.simpleMajority` result on 5a inputs.
   - **6d (`threshold = 2.0`)**: clamps to `1.0` per DD#9. Behavior matches 6b. Assert via 5c inputs producing fallback.
   - **6e (`threshold = -0.5`)**: clamps to `0.0` per DD#9. Behavior matches 6a.
   - **6f (`threshold = .infinity`)**: `.infinity.isFinite == false` → falls back to `0.0` per DD#9. Behavior matches 6a (NOT 6d) — Inf is treated identically to NaN, both bypass clamp logic. Lock this in to prevent a "clamp to 1.0" misimplementation.
   - **6g (`threshold = -0.0`)**: Swift's `min(max(-0.0, 0.0), 1.0)` returns `0.0`; behavior matches 6a. Spec lock-in to make `-0.0` semantics explicit.
   - **6h (`threshold = .signalingNaN`)**: `.signalingNaN.isFinite == false` (just like `.nan`); falls back to `0.0` per DD#9. Behavior matches 6c. Locks in that BOTH NaN flavors are handled identically.

7. **Given** a single-window input `[BPMResult]` of count 1
   **When** `CandidateMergeStrategy.merge(...)` is called with `strategy = .windowVoting` and any policy and any threshold
   **Then** the single window passes through unchanged (returned verbatim — the existing `merge` count==1 short-circuit at CandidateMergeStrategy.swift:71-73 handles this BEFORE policy dispatch)
   **And** the test exercises this via the dispatcher (NOT via direct `mergeByWindowVoting` call — the helper stays `private static`; do NOT promote visibility solely to test this AC)
   **And** at least one unit test asserts this for `.confidenceWeighted` and `.thresholdGated` to lock in the contract.

8. **Given** an empty input `[BPMResult]`
   **When** `CandidateMergeStrategy.merge(...)` is called with `strategy = .windowVoting` and any policy and any threshold
   **Then** `merge` returns `nil` (the existing `guard !windowResults.isEmpty else { return nil }` at CandidateMergeStrategy.swift:68 handles this BEFORE policy dispatch)
   **And** the test exercises this via the dispatcher (same visibility rule as AC #7)
   **And** at least one unit test asserts this for `.confidenceWeighted` and `.thresholdGated`.

9. **Given** the per-policy benchmark in `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift`
   **When** `@Test("voting policy comparison (3 policies × threshold sweep)") func benchmarkVotingPolicies()` runs
   **Then** all OA300 audio is pre-read into `[TrackAudio]` ONCE (mirrors `benchmarkMergeStrategies` lines 259-273)
   **And** for each track, the 3 windows are analyzed ONCE into a stored `[BPMResult]` BEFORE the policy/threshold loop begins (NOT re-analyzed per pair) — per DD#18 benchmark computation model
   **And** the inner loop iterates the 6 `(policy, threshold)` pairs calling ONLY `CandidateMergeStrategy.merge(windowResults: cachedWindows, candidateCount: ..., strategy: .windowVoting, votingPolicy: pair.policy, votingThreshold: pair.threshold)` on the cached results
   **And** the 6 pairs are: `(.simpleMajority, 0.0)`, `(.confidenceWeighted, 0.0)`, `(.thresholdGated, 0.0)`, `(.thresholdGated, 0.25)`, `(.thresholdGated, 0.5)`, `(.thresholdGated, 0.75)`
   **And** Acc1, Acc2, Correct count, Total count are printed per pair in a table identical in shape to `benchmarkMergeStrategies`'s output (label column 28 chars wide; e.g., `"thresholdGated@0.50"`)
   **And** total benchmark runtime is bounded by the DSP cost (N tracks × 3 window analyses), NOT by the policy-loop fan-out — wall-clock ≈ **1/8 of `benchmarkMergeStrategies`'s wall-clock** because `benchmarkMergeStrategies` re-analyzes 3 windows × 8 strategies × N tracks (no caching) while `benchmarkVotingPolicies` analyzes 3 windows × N tracks once + 6 cheap merge passes. The 6-vs-8 ratio is irrelevant to wall-clock; only the redundant DSP work matters.

10. **Given** the post-Story-3-5 codebase
    **When** the public API surface is inspected
    **Then** `CandidateMergeStrategy.allCases.count == 8` UNCHANGED (regression guard — DD#1; explicitly asserted by Task 5.8)
    **And** `VotingPolicy.allCases.count == 3` (DD#12; explicitly asserted by Task 5.6)
    **And** no new method overload exists on `AudioAnalysisService` — `analyzeBPM(url:)` and `analyzeBPM(url:options:)` are the only public entry points (no `analyzeBPM(url:options:votingPolicy:)` etc.; the policy lives on `Options` per ADR-11)
    **And** the API-surface check is stronger than a single reference assignment: Task 5.8 includes a deliberate enumeration of all `analyzeBPM` overloads (e.g., via Swift's reflection or by static-typed function references stored in a `let` array of typed function values). A single `_ = analyzeBPM(url:options:)` reference does NOT detect added overloads — the reference would still resolve correctly even if a third overload existed. The strengthened pattern: store both expected signatures into typed `let` constants and verify at compile time that no third typed signature exists by attempting to resolve `analyzeBPM(url:options:votingPolicy:)` and asserting it fails. **Pragmatic alternative**: a unit test that uses `String(describing:)` on `Mirror.children` of the type, or a public-symbol enumeration via `swift symbolgraph-extract` post-build — implement whichever is cheapest. The key is that ADDING a new overload during refactoring would surface as a test failure.

11. **Given** the `make oracle` test
    **When** the DAW oracle benchmark runs with `mergeStrategy = .windowVoting` AND `votingPolicy = .simpleMajority` (explicit — NOT relying on the default `.maxConfidence` mergeStrategy from `Options()`, which would NOT exercise the new code path)
    **Then** all DAW oracle tracks remain in tolerance (no regression vs the post-Story-3-4 oracle baseline — `Icicle - Condense` stays within 2% Acc1 per Story 3-4 Completion Notes oracle results; no other DAW oracle track flips from in-tolerance to out)
    **And** Completion Notes record the oracle outcome AND the explicit Options used to run it.

12. **Given** the per-policy benchmark output AND the existing `benchmarkMergeStrategies` `windowVoting` row
    **When** the user reads the post-implementation Completion Notes
    **Then** the notes record the `(policy, threshold)` row with the highest Acc1 alongside the post-Story-3-4 `windowVoting` baseline Acc1
    **And** the "best Acc1" tie-rule is documented: when 2+ rows share the same Acc1, pick by (a) highest Acc2, then (b) lowest threshold (for tie-rule purposes, `.simpleMajority` and `.confidenceWeighted` use effective threshold `0.0` even when the table displays `n/a`), then (c) source-order policy (`.simpleMajority` < `.confidenceWeighted` < `.thresholdGated`). The dev agent does NOT cherry-pick by formatting or aesthetic preference.
    **And** the comparison is reproducible from the printed tables (no hidden state)
    **And** if no policy beats the baseline, the notes say so honestly with the same "defer the call to the user" framing as Story 3-4 DD#12 / Story 3-3 DD#12 (the configurability has value as a benchmark substrate even if the default `.simpleMajority` remains the corpus champion). **This is informational, not a `#expect` floor (DD#14).**

## Tasks / Subtasks

- [x] **Task 0: Capture pre-implementation baselines (AC: #4, DD#19) — MUST run BEFORE Task 1**
  - [x] 0.1: Verify clean tree: `git diff --quiet && git diff --cached --quiet` must both succeed. If not, stash or commit; if uncommitted state can't be cleaned (e.g., debugging artifacts), check out the recorded post-Story-3-4 baseline SHA (find it via `git log --grep="Story 3-4 - close out"` or by walking history from current `develop`/`main` HEAD post-Story-3-4) before benchmarking.
  - [x] 0.2: Record `git rev-parse HEAD` at baseline-capture time. Save the SHA into the Debug Log References section of this story BEFORE proceeding to Task 1. This SHA must be a parent of (or equal to) the commit that lands Tasks 1-3.
  - [x] 0.3: Capture OA300 baseline. Run `OA300_CORPUS_PATH=... swift test --filter benchmarkMergeStrategies` and read the printed `windowVoting` row's Acc1 / Acc2 / Correct / Total numbers. Record the four numbers in Debug Log References. (NOTE: do NOT run plain `make benchmark` to capture this — `make benchmark` runs the corpus with default `mergeStrategy = .maxConfidence`, NOT `.windowVoting`. The `benchmarkMergeStrategies` test is the only existing path that exercises `.windowVoting` on the corpus.)
  - [x] 0.4: Capture GiantSteps baseline. The existing `GiantStepsBenchmarkTests` does NOT have a per-strategy comparison test, so the dev agent adds a TEMPORARY harness (do NOT commit) that runs the GiantSteps corpus with `mergeStrategy = .windowVoting + votingPolicy = .simpleMajority` (effectively current behavior) and captures Acc1 / Acc2 / Correct / Total. Record the four numbers in Debug Log References. Discard the temporary harness; only the captured numbers + SHA are committed.
  - [x] 0.5: If at any point the dev agent realizes they captured baselines on a tree that already has Story-3-5 code (DIRTY-TREE FAILURE), they MUST stash, check out the pre-Story-3-5 parent SHA from step 0.2, capture again, then resume. They CANNOT recover the baseline by "running it again with the new code disabled" (the merge layer's behavior may have shifted in subtle ways).
  - [x] 0.6: Once Task 0 is complete, the dev agent moves the captured numbers + SHA into Tasks 8.2 / 8.3's hardcoded `let oa300Acc1Baseline = N` constants when those tasks fire. Task 8 becomes the post-implementation `#expect` wiring; Task 0 IS the baseline capture.

- [x] Task 1: Add `VotingPolicy` enum (AC: #1; partial #10 — full #10 coverage requires Task 5.8)
  - [x] 1.1: Create `Sources/BoomBoomBoomKit/VotingPolicy.swift` with the file header six-line pattern (matches `CandidateMergeStrategy.swift`).
  - [x] 1.2: Define `public enum VotingPolicy: String, CaseIterable, Sendable, Hashable` with EXACTLY three cases in source order: `simpleMajority`, `confidenceWeighted`, `thresholdGated`. NO associated values. Do NOT introduce a `VotingPolicy?` Optional wrapper anywhere — every consumer uses the bare enum so `Sendable` synthesis stays clean (per DD#5 / Codex FMA Task 3).
  - [x] 1.3: Doc-comment per AC #1: top-level `///` block explaining purpose, threshold semantics, and the relationship to `CandidateMergeStrategy.windowVoting`. Include the line: "`VotingPolicy` is consulted ONLY when `mergeStrategy == .windowVoting` (where `mergeStrategy` is the `CandidateMergeStrategy` value held by `AudioAnalysisService.Options`). It is NOT a DSP technique, NOT a merge strategy case, and does NOT belong in `DSPTechnique` or `CandidateMergeStrategy.allCases`."
  - [x] 1.4: Add per-case doc-comments. Each case doc MUST cover, in one or two sentences: (a) the cluster-selection rule, (b) the within-cluster tiebreaker chain, (c) the fallback behavior, (d) for `.thresholdGated` only: that `votingThreshold` is consulted (and the silent-clamp rule from DD#9). For `.simpleMajority` and `.confidenceWeighted`: state explicitly that `votingThreshold` is ignored.

- [x] Task 2: Refactor `mergeByWindowVoting` to accept `(policy:threshold:)` (AC: #3, #5, #6)
  - [x] 2.1: Extend `CandidateMergeStrategy.merge(windowResults:candidateCount:strategy:)` signature with two new defaulted parameters: `votingPolicy: VotingPolicy = .simpleMajority, votingThreshold: Double = 0.0`. Default values mean every existing internal call site (only `AudioAnalysisService.swift:234-238` today) keeps compiling unchanged.
  - [x] 2.2: Inside the switch dispatch, change `case .windowVoting: return mergeByWindowVoting(windowResults)` to `case .windowVoting: return mergeByWindowVoting(windowResults, policy: votingPolicy, threshold: votingThreshold)`.
  - [x] 2.3: Refactor `private static func mergeByWindowVoting(_ results: [BPMResult]) -> BPMResult` (lines 123-148) into `private static func mergeByWindowVoting(_ results: [BPMResult], policy: VotingPolicy, threshold: Double) -> BPMResult`. Build the same `groups: [(bpm: Double, indices: [Int])]` cluster array as today (lines 124-132) — clustering is shared across all policies. Then dispatch on policy:
    ```swift
    switch policy {
    case .simpleMajority:
      return resolveSimpleMajority(results: results, groups: groups)
    case .confidenceWeighted:
      return resolveConfidenceWeighted(results: results, groups: groups)
    case .thresholdGated:
      // threshold normalization happens inside resolveThresholdGated per DD#9
      return resolveThresholdGated(results: results, groups: groups, threshold: threshold)
    }
    ```
  - [x] 2.4: Implement `resolveSimpleMajority(results:groups:) -> BPMResult` — pick the group with the most windows (`indices.count >= 2` required for "consensus"). When 2+ groups have equal `indices.count`, break ties by (a) the group's highest single-window confidence, then (b) the group's lowest original window index. Within the picked group, return `results[bestIndex]` where `bestIndex` is selected by the explicit `(higher confidence, lower index)` tiebreaker shape from DD#7 / DD#16. Falls back to `mergeMaxConfidence(results)` when no group has `indices.count >= 2`. This is current logic (lines 134-147) lifted into a named helper PLUS the explicit-tiebreaker hardening required by DD#16.
  - [x] 2.5: Implement `resolveConfidenceWeighted(results:groups:) -> BPMResult` — for EVERY group (singleton AND non-singleton), compute `summedConfidence = group.indices.reduce(0.0) { $0 + results[$1].confidence }`. Pick the group with highest summed confidence using DD#16's tiebreaker chain: (a) max single-window confidence within the group, then (b) lowest original window index in the group. **AFTER picking the winning group, check if it is a singleton (`indices.count == 1`); if yes, fall back to `mergeMaxConfidence(results)`.** This MUST happen post-pick, not pre-pick — AC #5b-ii requires that a singleton can WIN the summed-confidence ranking and then fall back, producing window 2's `BPMResult` rather than the larger cluster's. (The original FMA-round wording "Pick the non-singleton group" was self-contradictory with DD#3 / AC #5b-ii — Self-Consistency review 2026-04-28 corrected this.) Within the picked non-singleton group, return `results[bestIndex]` via the explicit `(higher confidence, lower index)` chain from DD#16.
  - [x] 2.6: Implement `resolveThresholdGated(results:groups:threshold:) -> BPMResult` — FIRST line normalizes threshold per DD#9: `let effectiveThreshold: Double = threshold.isFinite ? min(max(threshold, 0.0), 1.0) : 0.0`. Then same as `.simpleMajority` for the cluster-selection step (largest group with `indices.count >= 2`, with the same equal-size tiebreaker chain from Task 2.4). Then check `let maxConf = group.indices.map { results[$0].confidence }.max() ?? 0; guard maxConf >= effectiveThreshold else { return mergeMaxConfidence(results) }`. If gate passes, return the highest-confidence window in the cluster via the explicit-tiebreaker chain (DD#7). NOTE: use plain `.map { ... }.max()` not `.lazy.map { ... }.max()` — `max()` over a finite collection of ≤ 3 elements is faster eager than lazy, and lazy doesn't help here because `max` always traverses everything anyway.
  - [x] 2.7: Update `mergeByWindowVoting`'s doc-comment to enumerate the three policies and the threshold semantics. Cross-reference `VotingPolicy.swift`.

- [x] Task 3: Wire the public Options fields (AC: #2, #3 — Options→merge plumbing)
  - [x] 3.1: Add `public var votingPolicy: VotingPolicy = .simpleMajority` to `AudioAnalysisService.Options` (AudioAnalysisService.swift, immediately after `public var mergeStrategy: CandidateMergeStrategy = .maxConfidence` at line 84). Doc-comment per AC #2: "Resolution policy used when `mergeStrategy == .windowVoting`. Has no effect for any other strategy. Default `.simpleMajority` reproduces the post-Story-3-3a baseline byte-for-byte. See `VotingPolicy` for the per-case semantics."
  - [x] 3.2: Add `public var votingThreshold: Double = 0.0` immediately after `votingPolicy`. Doc-comment per AC #2: "Acceptance threshold for `VotingPolicy.thresholdGated` (range `[0.0, 1.0]`). Out-of-range values silently clamp; NaN/Inf falls back to `0.0`. Has no effect when `votingPolicy != .thresholdGated`. Default `0.0` makes the gate permissive (equivalent to `.simpleMajority`) so a benchmark sweep can dial up the threshold without recompiling."
  - [x] 3.3: Update the `Options` struct's "Field-style convention" doc-block (lines 36-41) to list `votingPolicy` and `votingThreshold` alongside the existing always-present fields.
  - [x] 3.4: Update `AudioAnalysisService.analyzeBPM`'s call to `CandidateMergeStrategy.merge` (lines 234-238) to pass `votingPolicy: options.votingPolicy, votingThreshold: options.votingThreshold`. Verify the call still compiles cleanly against the defaulted parameters from Task 2.1. **Critical:** the `Options.votingPolicy` and `Options.votingThreshold` values MUST flow through; if Task 3.4 is skipped or the call site forgets the `votingPolicy:` argument label, the public API silently ignores the field — Task 6.5's divergent integration test catches this.
  - [x] 3.5: Verify `AudioAnalysisService.Options` continues to conform to `Sendable` (the new `VotingPolicy` enum is `Sendable` per Task 1.2; `Double` is `Sendable`; no Optional or non-`Sendable` types are introduced). `swift build` failing on Sendable conformance after this task indicates a regression — fix root cause before proceeding.

- [x] Task 4: Update existing `windowVoting` tests for the explicit policy parameter (AC: #2 partial, #5a, #7, #8)
  - [x] 4.1: In `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift`, the existing `CandidateMergingTests` suite has 5 `windowVoting*` tests (`windowVotingConsensus`, `windowVotingUnanimous`, `windowVotingNoConsensus`, `windowVotingTwoWindowsDisagree`, `windowVotingTwoWindowsAgree`, lines 1122-1187). Confirm they all keep passing UNCHANGED — the new `votingPolicy:` parameter on `merge(...)` defaults to `.simpleMajority`, so call sites without an explicit policy keep current behavior. Watch for compile-time risk: if any caller passed `merge` as a function reference (`.merge(_:_:_:)`) or stored its function-type, the new defaulted parameters change the function's type signature and the reference breaks. Grep for `CandidateMergeStrategy.merge` references that don't immediately apply args; expected to find none, but verify.
  - [x] 4.2: Add `singleWindowPassthroughAllPolicies` test: pass a 1-element `windowResults` array, iterate all 3 policies, assert each returns the original `BPMResult` verbatim (covers AC #7 — short-circuit at `merge(...)` line 71-73 prevents policy dispatch). Test exercises the dispatcher (`CandidateMergeStrategy.merge(...)`); does NOT call `mergeByWindowVoting` directly (helper stays `private static`).
  - [x] 4.3: Add `emptyInputReturnsNilAllPolicies` test: pass an empty `windowResults` array, iterate all 3 policies (and a non-default threshold), assert `merge(...)` returns `nil` (covers AC #8 — short-circuit at line 68). Same dispatcher-only access pattern as Task 4.2.
  - [x] 4.4: Add `nonWindowVotingStrategiesIgnorePolicyAndThreshold` test (covers AC #2's new clause): for every `CandidateMergeStrategy` case OTHER than `.windowVoting` (7 strategies), call `merge(...)` twice on identical `[BPMResult]` inputs — once with default `votingPolicy:`/`votingThreshold:`, once with pathological values (`votingPolicy: .thresholdGated`, `votingThreshold: .nan`). Use the `assertSameBPMResult` helper from DD#15 to verify byte-for-byte identity (NOT bare `==` — `BPMResult` is not `Equatable` and the `candidates` tuple-array doesn't support `==`). The helper covers `.bpm`, `.confidence`, `.candidates` element-wise, and `.trace` nil-presence parity. Proves the policy fields are inert outside `.windowVoting`.

- [x] Task 5: Add new policy-specific unit tests (AC: #5b-e, #6, #10)
  - [x] 5.0: Add the `assertSameBPMResult(_:_:)` helper specified in DD#15 to `BPMAnalyzerTests.swift` near the existing `makeBPMResult` helper (BPMAnalyzerTests.swift:807-equivalent). Tests in 5.1-5.4 use it instead of bare `==` (which doesn't compile on `BPMResult` / tuple-array `candidates`). Tests in 5.1-5.4 also construct each synthetic `BPMResult` with a UNIQUE candidate sentinel (e.g., extra candidate `(bpm: 1.0 + Double(windowIndex), score: Float(windowIndex) * 0.001)`) so the candidates-array proxy is reliable identity evidence.
  - [x] 5.1: Add `confidenceWeightedPicksHigherSummedConfidence` (AC #5b): two scenarios per AC #5b-i / 5b-ii. For each: assert `result.bpm == <exact>`, `result.confidence == <exact>`, AND `assertSameBPMResult(result, windows[N])` for the expected source-window index. The unique-candidate-sentinel construction makes the `assertSameBPMResult` check unambiguous — two windows that "happen to" share a BPM still differ in their sentinel candidate.
  - [x] 5.2: Add `thresholdGatedAcceptsWhenThresholdMet` (AC #5c): inputs from AC #5c. Assert `result.bpm == 170.0`, `result.confidence == 0.9`, AND `assertSameBPMResult(result, windows[0])`.
  - [x] 5.3: Add `thresholdGatedFallsBackWhenThresholdNotMet` (AC #5d): inputs from AC #5d. Assert `result.bpm == 170.0`, `result.confidence == 0.9`, AND `assertSameBPMResult(result, windows[0])`. NOTE: the `result.bpm == 170.0` is intentionally identical to 5c's outcome — ALSO run `.simpleMajority` on the same inputs and assert that path returns the same `windows[0]` directly via cluster pick (not via fallback); the divergence proof comes from 5e, not from 5d.
  - [x] 5.4: Add `thresholdGatedDivergesFromSimpleMajority` (AC #5e): inputs from AC #5e. In one `@Test` body, run BOTH `.simpleMajority` and `.thresholdGated` (with `threshold = 0.5`). Assert via `assertSameBPMResult`: `simpleResult` IS `windows[0]`; `gatedResult` IS `windows[2]`. Plus explicit scalar assertions `simpleResult.bpm == 170.0 && simpleResult.confidence == 0.4`; `gatedResult.bpm == 85.0 && gatedResult.confidence == 0.9`. DO NOT use bare `result.candidates == windows[N].candidates` — the tuple-array `==` doesn't compile.
  - [x] 5.5: Add `thresholdValidation` (AC #6): SIX sub-assertions covering `0.0`, `1.0`, `.nan`, `2.0`, `-0.5`, `.infinity` (note the AC #6f addition for `.infinity`). Use the 5c input for `1.0`/`2.0` (which expects fallback); use the 5a-equivalent input for `0.0`/`.nan`/`-0.5`/`.infinity` (which expects consensus). Each assertion uses `assertSameBPMResult` against the expected source window.
  - [x] 5.6: Add `votingPolicyAllCasesCount` (AC #10 / AC #1): assert `VotingPolicy.allCases.count == 3` AND `VotingPolicy.allCases.map(\.rawValue) == ["simpleMajority", "confidenceWeighted", "thresholdGated"]`. Same shape as the implicit `CandidateMergeStrategy.allCases.count == 8` assertion at `BPMAnalyzerTests.swift:822`-equivalent.
  - [x] 5.7: Re-run the existing `confidencePropagation` test (BPMAnalyzerTests.swift:1191-1204) — it iterates `CandidateMergeStrategy.allCases` and asserts max-confidence propagation. With the new policy parameter defaulting to `.simpleMajority`, this test must continue to pass for all 8 strategies. **Compatibility note:** the test relies on the OLD `mergeByWindowVoting` returning the cluster's max-confidence window (which equals the global max when all 3 windows agree on the same BPM). Per DD#15, the new helper preserves this — the test should pass without modification.
  - [x] 5.8: Add `candidateMergeStrategyAllCasesCountUnchanged` test (covers AC #10's `CandidateMergeStrategy.allCases.count == 8` assertion that no existing task explicitly verifies): assert `CandidateMergeStrategy.allCases.count == 8` AND `CandidateMergeStrategy.allCases.map(\.rawValue).sorted() == ["average", "confidenceWeighted"...]` (or equivalent order-independent check that locks the eight known cases). Same shape as 5.6's `VotingPolicy` assertion. This test catches accidental promotion of `VotingPolicy` cases into `CandidateMergeStrategy` (DD#13 violation).
  - [x] 5.9: Add `equalSummedConfidenceClusterTieBreaker` test (covers Edge Case Hunter Q5 / DD#16): 4-window input `[(bpm=170, conf=0.5), (bpm=170.5, conf=0.5), (bpm=85, conf=0.4), (bpm=85.2, conf=0.6)]`. Cluster A = {0, 1} sums to 1.0; Cluster B = {2, 3} sums to 1.0. Equal summed confidence — DD#16 tiebreaker chain: (a) max single-window confidence: A=0.5, B=0.6 → B wins. Within B, max-confidence window is index 3. Expected: `result.bpm == 85.2`, `result.confidence == 0.6`, `assertSameBPMResult(result, windows[3])`. Run with `.confidenceWeighted` policy.
  - [x] 5.10: Add `equalSizeClusterTieBreaker` test (covers Edge Case Hunter Q6 / DD#16): 5-window input where two clusters each have `indices.count == 2`, e.g., `[(bpm=170, conf=0.5), (bpm=170.5, conf=0.4), (bpm=85, conf=0.7), (bpm=85.2, conf=0.3), (bpm=120, conf=0.5)]`. Cluster A = {0, 1}, Cluster B = {2, 3}, Singleton C = {4}. Both A and B have size 2 → DD#16 tiebreaker: (a) max single-window confidence: A=0.5, B=0.7 → B wins. Within B, max-confidence window is index 2. Expected: `result.bpm == 85`, `result.confidence == 0.7`, `assertSameBPMResult(result, windows[2])`. Run with `.simpleMajority` policy.
  - [x] 5.11: Add `unanimousClusterAllPolicies` test (covers Edge Case Hunter Q3): 3 windows that ALL cluster together at 170 BPM with distinct confidences. For each policy (`.simpleMajority`, `.confidenceWeighted`, `.thresholdGated` with threshold 0.0), assert the highest-confidence window is returned via `assertSameBPMResult`. This locks the all-agree case across all three policies in one test.

- [x] Task 6: Add Options-level integration test suite (AC: #2, #3 — divergent plumbing test)
  - [x] 6.1: In `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift`, add `AudioAnalysisServiceVotingPolicyTests` suite (mirrors `AudioAnalysisServiceDurationHintTests` from Story 3-4).
  - [x] 6.2: `defaultVotingPolicyIsSimpleMajority` — `Options()` produces `votingPolicy == .simpleMajority` and `votingThreshold == 0.0`. Sanity check that defaults match AC #2.
  - [x] 6.3: `votingPolicyFlowsThroughOptionsToMergeLayer` (smoke test): synthesize a 240s × 128 BPM click-track WAV (use `createClickTrackWAV(bpm:sampleRate:durationSeconds:url:)` already duplicated in `BPMAnalyzerDurationHintTests.swift`). Run `analyzeBPM` with `.windowVoting` strategy and a threshold so high it forces fallback (`votingPolicy = .thresholdGated, votingThreshold = 1.0`). Assert the BPM is still within 2% of 128 (click-track is unambiguous). This is a NON-CRASHING smoke; it does NOT prove plumbing — see Task 6.5.
  - [x] 6.4: `votingThresholdNonFiniteIsTolerated` — pass `.nan` and `.infinity` to `votingThreshold`. Assert `analyzeBPM` returns a valid result (silent normalization per DD#9).
  - [x] 6.5: **`votingPolicyOptionsFieldActuallyChangesResult` (the divergent integration test required by AC #3) — NO ACCEPTABLE-GAP FALLBACK.** The test MUST prove that changing `Options.votingPolicy` and/or `Options.votingThreshold` produces a DIFFERENT `analyzeBPM` result on the same audio input. Two acceptable strategies (pick whichever lands cleanly):

    **Strategy A — divergent real audio**: identify a track in the existing test fixtures (`Tests/BoomBoomBoomKitTests/Fixtures/`) or OA300 corpus where the 3 analysis windows produce ambiguous BPMs that DIVERGE under different policies. The dev agent finds this empirically by running each policy/threshold combination once and inspecting the per-window `BPMResult` confidences and BPMs to identify a track where windows split (e.g., 2 windows agree at one BPM, 1 disagrees with high confidence, OR no two windows agree). Document the chosen track in the test body. If no such track exists in the locally available fixtures, fall back to Strategy B.

    **Strategy B — deterministic synthetic seam**: construct a 30-90s composite WAV by concatenating click-tracks at different BPMs (e.g., 0-30s @ 128 BPM, 30-60s @ 64 BPM, 60-90s @ 128 BPM). The 3 analysis windows (30s/60s/90s) will see different BPMs depending on where the energy-onset detection lands. Run `analyzeBPM` with `(.simpleMajority, 0.0)` and `(.confidenceWeighted, 0.0)` on the same WAV; assert `result.bpm` differs between the two calls (`#expect(simpleResult.bpm != confidenceResult.bpm)`).

    Either strategy must produce a CONCRETE `#expect` that fails if `Options.votingPolicy` is silently ignored by `analyzeBPM`. The test does NOT pass if the assertion is "documented gap" — that escape was removed by the Self-Consistency review (2026-04-28) because it defeats AC #3's whole purpose. If the dev agent genuinely cannot construct EITHER strategy after honest effort, they MUST halt and surface the blocker to the user, NOT ship the story with a documented gap.

- [x] Task 7: Add benchmark sweep in `OA300BenchmarkTests` (AC: #9, #12)
  - [x] 7.1: Add `@Test("voting policy comparison (3 policies × threshold sweep)") func benchmarkVotingPolicies() throws` in `OA300BenchmarkTests.swift`, immediately after `benchmarkMergeStrategies` (line 315).
  - [x] 7.2: Pre-read all available OA300 tracks into `[TrackAudio]` (verbatim copy from `benchmarkMergeStrategies` lines 259-273; do NOT extract into a shared helper — duplication is consistent with the existing test's pattern).
  - [x] 7.3: Define the policy-threshold sweep: `let pairs: [(policy: VotingPolicy, threshold: Double)] = [(.simpleMajority, 0.0), (.confidenceWeighted, 0.0), (.thresholdGated, 0.0), (.thresholdGated, 0.25), (.thresholdGated, 0.5), (.thresholdGated, 0.75)]`.
  - [x] 7.4: **Compute window results ONCE per track, OUTSIDE the policy loop** (per DD#18). Outer loop: `for audio in audioData { let windowResults: [BPMResult] = AnalysisIntensity.default.windowSizes.compactMap { BPMAnalyzer.estimateBPM(samples: audio.samples, sampleRate: audio.sampleRate, options: .init(analysisWindowSeconds: $0, intensity: .default)) }; ... }`. Inner loop: `for pair in pairs { let merged = CandidateMergeStrategy.merge(windowResults: windowResults, candidateCount: AnalysisIntensity.default.techniqueSet.candidateCount, strategy: .windowVoting, votingPolicy: pair.policy, votingThreshold: pair.threshold); /* tally */ }`. **Naive shape (analyze 3 windows per pair) does 6× redundant DSP work and triples wall-clock; correct shape stores the cached `windowResults` once and varies only the merge call** (Codex FMA flagged this as a high-severity benchmark misimplementation).
  - [x] 7.5: Print a table identical in shape to `benchmarkMergeStrategies`'s output (header row + 6 data rows + total count). Label format: `"simpleMajority"`, `"confidenceWeighted"`, `"thresholdGated@0.00"`, `"thresholdGated@0.25"`, `"thresholdGated@0.50"`, `"thresholdGated@0.75"` (use `String(format: "thresholdGated@%.2f", threshold)` for the gated rows).
  - [x] 7.6: NO `#expect` floor on the printed numbers — the benchmark prints, the human reads, the comparison-to-baseline lives in Completion Notes per AC #12.
  - [x] 7.7: Verify the test runs under `make benchmark` without env var changes (it lives inside `OA300BenchmarkTests` which already requires `OA300_CORPUS_PATH`). Expected wall-clock: ≈ **1/8 of `benchmarkMergeStrategies`'s wall-clock** per DD#18 (because cached windows skip the per-pair DSP work that `benchmarkMergeStrategies` repeats). If the new benchmark wall-clock approaches `benchmarkMergeStrategies`'s wall-clock (or exceeds it), the dev agent has re-analyzed windows per pair — fix the loop nesting before merging.

- [x] Task 8: Add post-implementation corpus regression `#expect`s (AC: #4)
  - [x] 8.1: Baseline capture is now Task 0 (per Self-Consistency review 2026-04-28 — moved earlier in the task list because the original ordering had it after Tasks 1-7 even though it MUST run before Task 1).
  - [x] 8.2: After Tasks 1-3 land, add a new `@Test` test in `OA300BenchmarkTests.swift` named `windowVotingDefaultPolicyMatchesBaseline()` that runs the corpus with `mergeStrategy = .windowVoting + votingPolicy = .simpleMajority` (explicit) and `#expect`s Acc1 and Acc2 EXACTLY equal the Task 0 captured numbers (HARDCODED as `let oa300Acc1Baseline = N` constants in the test method body). Add a comment above the constants citing the Task 0 SHA.
  - [x] 8.3: Add a parallel test in `GiantStepsBenchmarkTests.swift` named `windowVotingDefaultPolicyMatchesBaseline()` with the same pattern + same SHA-citation comment.
  - [x] 8.4: Both tests use unconditional `#expect` (not `#expect(throws:)`) — the captured baseline numbers are hardcoded as `let oa300Acc1Baseline = N` constants in each test method. Drift means the wiring leaked state.

- [x] Task 9: Validation gate — accuracy + perf + DAW oracle (AC: #4, #11, #12)
  - [x] 9.1: `make benchmark` — OA300 Acc1/Acc2 with `mergeStrategy = .windowVoting + votingPolicy = .simpleMajority` match baseline EXACTLY (Task 8.2 `#expect`).
  - [x] 9.2: `make benchmark-giantsteps` — same EXACTLY-match assertion (Task 8.3).
  - [x] 9.3: `make oracle` — DAW oracle stays green (AC #11). The oracle test must use `mergeStrategy = .windowVoting + votingPolicy = .simpleMajority` explicitly (NOT the default `.maxConfidence` mergeStrategy) so it actually exercises the new code path. Record outcome AND the explicit Options used in Completion Notes.
  - [x] 9.4: **Library perf gate (`make perf-benchmark`)** — perf delta < 5% vs the prior baseline file in `_bmad-output/perf-baselines/`. This gate measures the perf of `analyzeBPM` running with default Options on a single audio file (NOT the multi-pair benchmark sweep). The merge layer's added work per call is one switch + one `.map.max` over ≤ 3 floats — sub-microsecond. New baseline file emitted with this story's commit SHA.
  - [x] 9.5: **Benchmark-sweep wall-clock check (separate from 9.4)** — run `benchmarkVotingPolicies` and confirm wall-clock is ≈ 75% of `benchmarkMergeStrategies` (per DD#18 / Task 7.7 expectation). If the sweep wall-clock is materially higher (say > 1.2× `benchmarkMergeStrategies`), the dev agent has likely re-analyzed windows per pair — fix Task 7.4 loop nesting before merging. This is NOT a hard `#expect` floor; it's a dev-agent self-check that the `O(N tracks × 3 windows)` analysis cost stays out of the policy loop.
  - [x] 9.6: Capture the printed 6-row table from Task 9.5. Identify the highest-Acc1 row using the AC #12 tie-rule (Acc1 → Acc2 → lowest threshold → source-order policy). Cite it in Completion Notes alongside the post-Story-3-4 `benchmarkMergeStrategies` `windowVoting` baseline Acc1 — the AC #12 informational comparison.
  - [x] 9.7: Final `make test` — all unit tests pass: existing 209 + 13 new unit tests from Tasks 4-6 (4.2, 4.3, 4.4 = 3 from Task 4; 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.8, 5.9, 5.10, 5.11 = 10 from Task 5; 6.2, 6.3, 6.4, 6.5 = 4 from Task 6 — note 6.1 is the suite container, not a test) + 2 corpus-regression tests (8.2, 8.3). Note: 5.7 re-runs an existing test, not a new test, so it's NOT counted in the 13.

- [x] Task 10: Update CLAUDE.md and gating checklist (Docs/supporting — supports AC #10 API-surface documentation)
  - [x] 10.1: `CLAUDE.md` — update the `CandidateMergeStrategy` description (line 29) to add: "`windowVoting` is parameterizable via `VotingPolicy` (`.simpleMajority` default; `.confidenceWeighted`, `.thresholdGated` for benchmark sweeps) — see `VotingPolicy.swift`."
  - [x] 10.2: Add a new bullet in the "Key Types" section listing `VotingPolicy` as a public type alongside `CandidateMergeStrategy`, `AnalysisIntensity`, `DSPTechnique`, etc. The bullet MUST include the line: "`VotingPolicy` is consulted ONLY when `mergeStrategy == .windowVoting` (the `CandidateMergeStrategy` value held by `AudioAnalysisService.Options`). It is NOT a `DSPTechnique` (no DSP changes; no ablation matrix expansion) and NOT a new `CandidateMergeStrategy` case (still 8 cases). Future stories must not promote it into either family without explicit story authorization."
  - [x] 10.3: `make fmt` — clean.
  - [x] 10.4: `make lint` — only the pre-existing `LUFSAnalyzer.swift:94` TODO survives. No new warnings.
  - [x] 10.5: Final metrics recorded in Completion Notes below.

## Dev Notes

### Architecture context

- **ADR-11 (Options-first public configuration)** governs the placement of `votingPolicy` and `votingThreshold`. Per `_bmad-output/planning-artifacts/architecture.md:247-258`: "All optional or defaulted configuration for public service methods MUST be passed via a single `Options` struct parameter." Both new fields take the "Non-optional `T = .default`" shape (alongside `intensity`, `mergeStrategy`, `maxSeconds`, `enableTrace`, `durationHint`, `durationHintMinFileSeconds`). NOT optional `T?` — those carry "feature inactive" semantics via nil; `votingPolicy: .simpleMajority` is "feature on, default behavior" not "feature off."
- **Why `VotingPolicy` is not gated by `mergeStrategy` at the type level**: making the field invariant ("only meaningful for `.windowVoting`") would push the constraint into runtime documentation rather than the type system — but Swift doesn't have a clean way to express "this field only applies when this OTHER field is X" without conditional types or an enum-with-associated-values that would break `CaseIterable` synthesis. The story accepts the runtime-documentation approach (matches Story 3-4's `durationHintMinFileSeconds` only-applies-when-`durationHint==true` pattern).
- **Why default policy is `.simpleMajority` not `.confidenceWeighted`**: empirical conservatism. `.simpleMajority` is what ships today; changing the default would shift the post-Story-3-4 corpus baseline and conflict with AC #4. If the benchmark sweep (Task 9.5) shows `.confidenceWeighted` beating `.simpleMajority` on both corpora by a meaningful margin, a follow-up story can change the default — that's a separate design decision with its own regression-floor considerations.
- **Why `votingThreshold: Double` not `Float`**: matches the existing project convention for confidence values in `BPMResult` and `Options` (e.g., `progressiveThreshold: Double?` in `AnalysisIntensity.swift:82`). Float would be a needless inconsistency.
- **Pipeline composition unchanged**: this story does NOT touch any DSP step. `BPMAnalyzer.estimateBPM(...)` is identical pre- and post-Story-3-5. Only the cross-window MERGE (post-pipeline) gains parameterization. The story's risk surface is concentrated in `CandidateMergeStrategy.swift` (one refactor + three policy helpers + one signature extension) and `AudioAnalysisService.Options` (two field additions).

### Code-review precedents to honor

From Stories 3-3, 3-3a, and 3-4 close-outs:

- **`@testable import` for internal helpers**: the three policy helper functions (`resolveSimpleMajority`, `resolveConfidenceWeighted`, `resolveThresholdGated`) MAY be `private static` if Task 5's tests can drive the policy axis through `merge(...)`'s public-default-arg signature. Prefer `private` over `internal` to keep the API surface minimal — only promote to `internal` if a test genuinely cannot exercise a branch through the public path.
- **Implicit-nil rule (CLAUDE.md / project-context.md)**: `votingThreshold: Double = 0.0` — the literal `0.0` is fine (it's a non-optional Double, not an optional). DO NOT write `votingThreshold: Double? = nil` — that would conflict with the "non-optional with default" pattern from DD#5.
- **CLAUDE.md "Options struct pattern"**: any new tunables go on `AudioAnalysisService.Options`. Do NOT add positional parameters to `analyzeBPM`. Internal helpers may accept positional parameters.
- **TDD discipline (Story 3-3 Task 2.4 / Story 3-4 Task 2.5)**: write the AC #5 + AC #6 unit tests BEFORE wiring the helpers into `merge(...)`. The tests must compile against the new `mergeByWindowVoting(_:policy:threshold:)` signature first.
- **Path/line-number citations in code comments must be precise (Story 3-3a precedent)**: any cross-file reference must use the explicit relative path. When citing ADR-11 in a doc-comment, use the explicit path `_bmad-output/planning-artifacts/architecture.md`.
- **Sort/iteration determinism (Story 3-3 DD#6, Story 3-4 DD#10)**: the policy helpers iterate `groups: [(bpm: Double, indices: [Int])]` which preserves insertion order from the cluster-build loop. Insertion order is deterministic because the build loop iterates `results.enumerated()` and `BPMResult` has no internal nondeterminism. Document this in `mergeByWindowVoting`'s doc-comment.

### Files to touch

- `Sources/BoomBoomBoomKit/VotingPolicy.swift` (NEW) — public enum (Task 1)
- `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` — extend `merge(...)` signature, refactor `mergeByWindowVoting`, add three policy helpers (Task 2)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — add `votingPolicy` and `votingThreshold` Options fields, thread through to `merge` call (Task 3)
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift` — extend `CandidateMergingTests` suite with new policy-specific tests (Tasks 4, 5)
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` — extend with `AudioAnalysisServiceVotingPolicyTests` suite (Task 6)
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` — add `benchmarkVotingPolicies` test + `windowVotingDefaultPolicyMatchesBaseline` (Tasks 7, 8.2)
- `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` — add `windowVotingDefaultPolicyMatchesBaseline` (Task 8.3)
- `CLAUDE.md` — update `CandidateMergeStrategy` description; add `VotingPolicy` to public types list (Task 10)

### Files NOT to touch

- `BPMAnalyzer.swift` — no DSP changes; the per-window result is identical pre/post (DD#13)
- `DSPTechnique.swift` — no new technique case; `TechniqueSet` allDSPCombinations() count remains 128 (DD#13)
- `AnalysisIntensity.swift` — no intensity-mapping changes (the policy applies at all intensities ≥ 6 where multi-window analysis runs) (DD#13)
- `BPMDiagnosticTrace.swift` — no new trace field per DD#10
- `PCMBufferReader.swift` — voting is post-PCM-read merge logic, no I/O changes
- `MelFilterbank.swift`, `LUFSAnalyzer.swift` — unrelated subsystems
- `Makefile` — no new targets needed; the new `benchmarkVotingPolicies` test runs via the existing `make benchmark` target (it has no env-gating beyond `OA300_CORPUS_PATH` which `make benchmark` already provides)
- `README.md` — defer mention to Story 5.5 (DX docs)

### Performance expectations

- **Per-call merge overhead**: building `groups: [(bpm, indices)]` is O(N²) in the number of windows N, but N ≤ 3 (max windowSizes at intensity 7). Total comparisons ≤ 3 — negligible.
- **Policy dispatch**: one switch on `VotingPolicy` (3-way) plus one of three helpers. Each helper does at most O(G × W) where G = number of groups (≤ N) and W = group size (≤ N). Bounded constant factor.
- **Threshold normalization**: 2 floating-point compares + 1 isFinite check per call. Sub-nanosecond.
- **Total per-`analyzeBPM` overhead vs pre-Story-3-5**: ≤ 1 microsecond per call. Expect `make perf-benchmark` delta < 0.5% on warm-cache repeat runs (well under the 5% threshold per Story 3-3 close-out's perf gate).

### Test fixture access

- `generateClickTrack(bpm:sampleRate:durationSeconds:)` from `BoomBoomBoomKitTestSupport` for synthetic candidate construction in `mergeByWindowVoting` unit tests (these tests don't need real audio; they hand-craft `BPMResult` instances).
- `createClickTrackWAV(bpm:sampleRate:durationSeconds:url:)` already duplicated in `BPMAnalyzerDurationHintTests.swift` (Story 3-4 DD precedent — Option A duplication). Task 6.3 needs it for an integration smoke test; either copy the existing duplicate into `AudioAnalysisServiceTests.swift` (Option A again) or leverage the existing duplicate in the duration-hint test file's namespace. **Recommended**: keep duplicating per Option A — promoting to TestSupport remains a deferred hygiene item per the Story 3-4 spec.
- Helper `makeBPMResult(bpm:confidence:candidates:)` already exists at `BPMAnalyzerTests.swift:807`-equivalent (used by all existing `windowVoting*` tests). Task 5's new tests reuse this helper unchanged.

### Previous-story intelligence

From `_bmad-output/implementation-artifacts/3-4-duration-derived-bpm-hint.md` (most recent done story):
- **TDD-first with helper-level tests**: Story 3-4 wrote `DurationHintHelperTests` with 4 boost-gauntlet cases BEFORE wiring into `estimateBPM`. Same pattern applies here: Task 5 (policy unit tests) precedes Task 7 (benchmark integration). The unit tests catch shape errors that benchmarks would only surface as hours-long ablation regressions.
- **Sort comparator NaN trap (Patch #2 fix)**: when comparing scores/confidences in policy helpers, NaN comparisons silently break determinism. The CONTRACT-LEVEL guarantee is DD#17 — `BPMResult.confidence` is finite in `[0.0, 1.0]`, so the policy helpers never see NaN-confidence inputs. Test 6c covers the explicit NaN path for the THRESHOLD (which IS validated per DD#9 because it's a public-API field). Confidence comparisons inside the policy helpers use plain `.map { ... }.max()` per Task 2.6 — DO NOT pre-emptively switch to `.lazy.map` for "NaN safety" because (a) the contract guarantees no NaN, (b) `.lazy` doesn't help here (max traverses everything anyway), and (c) any future NaN regression is a contract violation that should be fixed upstream, not papered over downstream.
- **`#expect` corpus-floor pattern (Story 3-4 AC #4 / AC #5)**: capture baselines BEFORE wiring, hardcode them in dedicated test methods, assert via unconditional `#expect`. Task 8 implements this pattern for AC #4. The pattern catches state leakage at the test layer regardless of whether benchmark numbers actually changed.
- **Honest acknowledgment when a feature is functionally inert**: Story 3-4's Completion Notes documented `changedFinalBPM == 0` on OA300 and recommended keeping the default-on for "cheap insurance + future-proofing." Story 3-5 may face similar empirical realities — `.confidenceWeighted` and `.thresholdGated` may produce zero-or-negative-net-benefit on OA300. AC #12 explicitly accepts this; the story ships with Configurability As Substrate (the policies are useful as benchmark sweepables even if no policy beats `.simpleMajority` at production time).
- **Spec-amendment-after-halt precedent**: Story 3-4 added Task 7 (`durationHintMinFileSeconds`) post-halt when GiantSteps regressed. If Story 3-5 surfaces a similar regression (e.g., `.confidenceWeighted` corrupts results on EDM clips), the dev agent should HALT before forcing through, document the failure, and propose either (a) keep the policy code, default `.simpleMajority`, ship, OR (b) drop the policy entirely. The story does NOT pre-authorize accepting a regression.

### Git intelligence

Recent commits (last 5) on `rterhaar/epic-3`:
- `f0c5b9e` Story 3-3a close-out: code-review patches, ADR-11 reconciliation, sentinel mock guard
- `0d1b731` upgrade to bmad 6.5.1a5
- `137de7c` Add ADR-11, re-author Story 3-3a, create 3-3b + benchmark-infra stories
- `8934f5f` Story 3-3 close-out: review patches, decisions, techniqueSet rename
- `df4cdaa` Story 3-3 click-track cross-correlation + public API override

Patterns to mirror:
- **Squash-style story commit subjects**: "Story 3-X close-out: <summary>" (post-review patches) or "Story 3-X <feature>" (initial implementation).
- **Code-review pass via Codex (gpt-5.5) parallel agents**: Story 3-4 used Blind Hunter / Edge Case Hunter / Acceptance Auditor. Story 3-5's code review should follow the same triage pattern when ready for review.
- **Sprint-status update at story-status transitions**: every story moves `last_updated` and the per-story status entry. Done by `bmad-create-story` (this workflow) for `backlog → ready-for-dev`, by the dev agent for subsequent transitions.

### Project Structure Notes

- `VotingPolicy.swift` lives at the top level of `Sources/BoomBoomBoomKit/` alongside `CandidateMergeStrategy.swift`, `AnalysisIntensity.swift`, `DSPTechnique.swift`. No new directory.
- File naming convention: `VotingPolicy.swift` (PascalCase matching the primary type, per project-context.md "File naming" rule).
- File header six-line pattern matches the project standard (per project-context.md "Header format" rule):
  ```swift
  //
  //  VotingPolicy.swift
  //  BoomBoomBoomKit
  //
  //  Resolution policy for windowVoting merge strategy.
  //
  ```
- Imports: `Foundation` only (no `Accelerate`, no `AVFoundation` — VotingPolicy is a pure value type).
- Public access modifier on the enum and all cases (per ADR-11 "public configuration surface" rule).

### References

- **Epic AC**: `_bmad-output/planning-artifacts/epics.md:614-638` (Story 3.5)
- **ADR-11 (Options-first public configuration)**: `_bmad-output/planning-artifacts/architecture.md:247-258`
- **Existing `windowVoting` implementation**: `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:121-148` (`mergeByWindowVoting`)
- **`merge(...)` dispatcher**: `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:63-94`
- **AudioAnalysisService merge call site**: `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:234-238`
- **Spec-post-disambiguation-voting (original `windowVoting` spec)**: `_bmad-output/implementation-artifacts/spec-post-disambiguation-voting.md`
- **Spec-multi-window-candidate-merging (original `CandidateMergeStrategy` spec)**: `_bmad-output/implementation-artifacts/spec-multi-window-candidate-merging.md`
- **`benchmarkMergeStrategies` (pattern for `benchmarkVotingPolicies`)**: `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift:243-315`
- **Existing `windowVoting*` unit tests (5 tests, regression baseline for AC #5a)**: `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:1120-1187`
- **Story 3-4 close-out (precedent for Options field, `#expect` corpus floors, `make perf-benchmark` gate)**: `_bmad-output/implementation-artifacts/3-4-duration-derived-bpm-hint.md`
- **Story 3-3a close-out (precedent for ADR-11 Options field placement)**: `_bmad-output/implementation-artifacts/3-3a-public-api-harmonization.md`
- **Project context (Options struct pattern, implicit-nil rule, file-naming convention)**: `_bmad-output/project-context.md`
- **CLAUDE.md** (top-level architecture summary, list of public types, accuracy baselines): `CLAUDE.md`

## Pre-Implementation Review (2026-04-28, Codex gpt-5.5 Failure Mode Analysis)

A single-pass Failure Mode Analysis was run via the `codex:consult` MCP server (Codex / gpt-5.5 model) before any code landed. Codex walked all 12 ACs and 10 Tasks, asked "what's the most plausible way this fails or gets misimplemented," and returned 8 high-severity, 12 medium, 5 low findings plus 5 new DDs. All findings were applied to the spec — none deferred.

### Findings applied (high-severity)

- **AC #3 unwired-plumbing risk** → AC #3 now requires Task 6.5's divergent integration test (proves Options field actually plumbs through `analyzeBPM`, not just the merge-helper layer); AC #11's oracle now explicitly sets `mergeStrategy = .windowVoting`.
- **AC #4 baseline-provenance gap** → DD#19 added (clean tree + recorded SHA + parent-of-implementation precondition); Task 8.1 now enumerates the precondition checks; "Task 5.0" reference removed.
- **AC #5 confidence semantics ambiguity** → DD#15 added (returned-result contract: helpers return the SELECTED window's BPMResult byte-for-byte, no global-max overlay); AC #5 now specifies exact `(bpm, confidence, source-window-index)` for every synthetic case.
- **AC #9 / Task 7 benchmark redundancy** → DD#18 added (precompute window results once, iterate policy/threshold pairs over cached results only); Task 7.4 now spells out the loop nesting; Task 7.7 + Task 9.5 added as wall-clock self-checks.
- **Task 2 cluster-tiebreaker ambiguity** → DD#16 added (explicit `(higher confidence, lower original index)` chain everywhere; do NOT rely on `max(by:)` first-equal stability — Apple's docs don't promise it); Task 2.4-2.6 now specify the chain at every tiebreaker site; DD#7 rewritten to require the explicit chain rather than implicit stability.
- **Task 5 expected-value vagueness** → Task 5 now requires deep-equality checks (returned BPMResult IS the source window) plus exact `(bpm, confidence)` literals at every assertion site.
- **Task 8 dirty-tree baseline risk** → see DD#19 / Task 8.1 above.

### Findings applied (medium)

- **AC #1 raw-value stability** → AC #1 now asserts `allCases.map(\.rawValue)` order, not just count.
- **AC #2 non-window ignore behavior** → AC #2 now requires Task 4.4's explicit byte-identical check across all 7 non-windowVoting strategies × pathological policy/threshold combos.
- **AC #6 threshold-edge cases** → AC #6f added for `.infinity` (clarifies it follows the NaN path, not the clamp-to-1 path); Task 5.5 sub-count bumped to six values.
- **AC #10 API-surface check** → AC #10 now requires a compile-time reference assignment to lock the public `analyzeBPM(url:options:)` signature.
- **AC #12 best-Acc1 tie rule** → AC #12 now specifies (Acc1 → Acc2 → lowest threshold → source-order policy) tie-rule for "best-performing" determination.
- **Task 3 Sendable preservation** → Task 3.5 added (verify `Sendable` conformance survives the new fields; no `VotingPolicy?` Optional anywhere).
- **Task 4 split** → Task 4.4 added separately for the non-window-strategy ignore test (split out of the existing-tests-keep-passing scope).
- **Task 6 divergent assertion** → Task 6.5 added (the integration test that actually proves plumbing — click-track-only smoke can't distinguish wired from unwired).
- **Task 9 perf gate scoping** → Task 9.4 (library perf gate, single-file `analyzeBPM`) and Task 9.5 (benchmark-sweep wall-clock self-check) split into separate sub-tasks with different criteria.

### Findings applied (low)

- **AC #7 / AC #8 helper-visibility** → ACs reworded to test via `merge(...)` dispatcher, not direct private helper; do NOT promote helper visibility solely for testing.
- **Task 1 per-case doc-comment requirements** → Task 1.4 now enumerates the four required doc-comment elements (cluster-selection rule, tiebreaker chain, fallback, threshold-applicability).
- **Task 10 doc-line clarity** → Task 10.2 now requires CLAUDE.md to explicitly state `VotingPolicy` is NOT a `DSPTechnique` and NOT a new merge strategy case — prevents future misclassification.

### New Design Decisions added

- **DD#15 (Returned-result contract)** — policy helpers return the EXACT selected `BPMResult` byte-for-byte; no recomputation; no global-max overlay. Resolves AC #5 confidence-semantics ambiguity.
- **DD#16 (Explicit deterministic tie-breakers)** — every tiebreaker site uses the `(higher confidence, lower original index)` chain; never rely on `max(by:)` first-equal stability. Resolves Task 2 cluster-tiebreaker ambiguity.
- **DD#17 (Confidence input precondition)** — `BPMResult.confidence` is assumed finite in `[0, 1]`; policy helpers do NOT defensively normalize. Documents the implicit pipeline contract.
- **DD#18 (Benchmark computation model)** — precompute per-track window results ONCE, iterate policy/threshold pairs over cached results. Resolves AC #9 benchmark redundancy.
- **DD#19 (Baseline provenance)** — clean tree + recorded SHA before any Story-3-5 code lands. Resolves AC #4 dirty-tree baseline risk.

### DDs revised

- **DD#3** — `.confidenceWeighted` singleton special case simplified: the original "AND its summed confidence equals the chosen window's individual confidence" clause was always true for singletons (Codex flagged the dead branch). Now collapsed to "if singleton, fall back to maxConfidence."
- **DD#7** — replaced the implicit `max(by:)` first-equal-stability claim with the explicit `(higher confidence, lower original index)` chain (per Codex's verification that Apple's docs don't promise stability).

### Codex thread reference

Codex thread ID: `019dd65b-5c60-7d40-bc49-84bd3148c993`. Findings cached in this story for reference; no follow-up Codex run required unless further design questions surface during implementation.

## Self-Consistency Review (2026-04-28, three Codex gpt-5.5 agents in parallel)

A second review round dispatched THREE parallel Codex agents on the post-FMA-patched spec, mirroring the Story 3-3 / 3-4 close-out triad pattern (Blind Hunter / Edge Case Hunter / Acceptance Auditor). Each agent reviewed the spec under a distinct lens. Findings were synthesized into a triage table and applied in-place. **The first FMA round had self-introduced two contradictions, which this round caught and corrected.**

### Critical findings (3) — applied

1. **DD#3 vs Task 2.5 self-contradiction (Blind Hunter)** — DD#3 said "fall back if singleton wins"; Task 2.5 (post-FMA) said "Pick the non-singleton group" — would have broken AC #5b-ii's expected output. **Patch:** rewrote Task 2.5 to score ALL groups (singleton + non-singleton), pick highest summed-confidence, THEN check if winner is singleton and fall back if so. Behavior now matches DD#3 / AC #5b-ii.
2. **AC #3 plumbing-test loophole (Acceptance Auditor)** — Task 6.5's "document the gap if neither approach is feasible" fallback defeated AC #3's hard requirement that policy/threshold actually plumb through `analyzeBPM`. **Patch:** rewrote Task 6.5 with TWO concrete strategies (divergent real audio OR deterministic synthetic seam), removed the "documented gap" escape, added explicit halt-and-surface instruction if neither strategy lands.
3. **`BPMResult` not `Equatable` + tuple-array `==` won't compile (Edge Case Hunter Q8/Q12 + Acceptance Auditor)** — Task 5.4's `result.candidates == windows[0].candidates` doesn't compile (`BPMResult.candidates` is `[(bpm: Double, score: Float)]`, a tuple-array which doesn't support `==`). **Patch:** added `assertSameBPMResult(_:_:)` helper specification to DD#15 (Task 5.0 implements it); rewrote all Task 5 tests to use the helper instead of bare `==`; added unique-candidate-sentinel construction requirement so the candidates-array proxy is reliable identity evidence.

### High findings (11) — applied

4. **Task 8.1 ordering bug (Blind Hunter)** — Task 8.1 said "BEFORE Task 1" but was positioned after Tasks 1-7. **Patch:** added new **Task 0** for baseline capture, sequenced before Task 1; reduced Task 8.1 to a pointer to Task 0.
5. **AC #4 baseline source mismatch (Blind Hunter)** — current `make benchmark` runs with default `mergeStrategy = .maxConfidence`, NOT `.windowVoting`; the AC's "run `make benchmark`" wording was unimplementable as written. **Patch:** rewrote AC #4 + Task 0.3-0.4 to specify the actual baseline source: existing `benchmarkMergeStrategies` `.windowVoting` row for OA300 + a temporary one-off harness for GiantSteps (uncommitted).
6. **Wall-clock math wrong (Blind Hunter)** — DD#18 / AC #9 / Task 7.7 claimed "75% of `benchmarkMergeStrategies`" but cached windows give ~1/8. **Patch:** corrected math in all three sites — expected wall-clock is ~1/8 of `benchmarkMergeStrategies` because cached windows skip the per-strategy DSP redo.
7. **Task 1.3 invalid Swift `CandidateMergeStrategy == .windowVoting` (Blind Hunter)** — type-name comparison, not valid Swift. **Patch:** rewrote to `mergeStrategy == .windowVoting` (the `CandidateMergeStrategy` value held by `Options`); same fix applied to Task 10.2.
8. **Stale `.lazy.map.max` reference contradicts Task 2.6 (Blind Hunter)** — Previous-Story-Intelligence section said use `.lazy.map.max` for NaN safety; Task 2.6 said use plain `.map.max`. **Patch:** rewrote Previous-Story-Intelligence note to align with Task 2.6 + DD#17 (contract guarantees no NaN; don't paper over).
9. **Task 4.4 underspec on `.trace` (Blind Hunter)** — Task 4.4 only checked `.bpm`/`.confidence`/`.candidates` but DD#15 byte-for-byte requires `.trace` too. **Patch:** Task 4.4 now explicitly uses `assertSameBPMResult` which covers `.trace` nil-presence parity.
10. **AC #5 source-window-index proxy weak (Blind Hunter + Acceptance Auditor)** — candidates-array equality could confuse two windows with similar candidates. **Patch:** Task 5.0 now requires unique candidate sentinels per synthetic window (e.g., extra `(bpm: 1.0 + Double(windowIndex), score: Float(windowIndex) * 0.001)`).
11. **DD#16 "everywhere" vs `mergeMaxConfidence` fallback (Blind Hunter)** — fallback uses bare `max(by:)` which DD#16 forbade. **Patch:** added explicit carve-out in DD#16 — the new policy helpers use the explicit chain; the existing `mergeMaxConfidence` keeps its current `max(by:)` tie behavior unchanged (modifying it would break AC #4 byte-equality for the other 7 strategies).
12. **AC #10 API-surface check is weak (Blind Hunter + Edge Case Hunter Q11)** — single reference assignment doesn't detect added overloads. **Patch:** strengthened AC #10 to require deliberate overload enumeration (typed `let` references, reflection, or `swift symbolgraph-extract`); added Task 5.8 to deliver the check.
13. **AC #10 has no Task explicitly asserting `CandidateMergeStrategy.allCases.count == 8` (Acceptance Auditor)** — invariant only implicit. **Patch:** added Task 5.8 (`candidateMergeStrategyAllCasesCountUnchanged`) explicitly asserting the count.
14. **Task 6 falsely claims AC #4 coverage (Acceptance Auditor)** — Task 6 doesn't deliver corpus baseline preservation. **Patch:** removed AC #4 from Task 6 annotation; Task 6 is now `(AC: #2, #3 — divergent plumbing test)`.

### Medium findings (9) — applied

15. **Missing test for two equal summed-confidence clusters (Edge Case Hunter Q5)** — added Task 5.9 (`equalSummedConfidenceClusterTieBreaker`) with the 4-window fixture covering DD#16's tiebreaker chain for `.confidenceWeighted`.
16. **Missing test for two equal-size clusters + singleton (Edge Case Hunter Q6)** — added Task 5.10 (`equalSizeClusterTieBreaker`) with the 5-window fixture covering DD#16's tiebreaker chain for `.simpleMajority`.
17. **DD#9 vs Task 2.3 disagree on clamp location (Edge Case Hunter Q9)** — DD#9 said "inside `mergeByWindowVoting`" but Task 2.3 put clamp in dispatcher. **Patch:** moved clamp INTO `resolveThresholdGated` as the FIRST line; rewrote DD#9 + Task 2.3 + Task 2.6 accordingly. Helper now self-contained.
18. **Missing unanimous-cluster-all-policies test (Edge Case Hunter Q3)** — added Task 5.11 (`unanimousClusterAllPolicies`).
19. **AC #11 "Icicle" reference incomplete (Acceptance Auditor)** — added "Icicle - Condense" track name + Story 3-4 Completion Notes citation.
20. **Test count claim wrong (Acceptance Auditor)** — corrected from "~12" to "13 unit + 2 corpus regression" in Task 9.7.
21. **Task annotations need updating (Acceptance Auditor)** — updated Task 1 (partial #10), Task 3 (add #3), Task 4 (add #2 partial), Task 6 (remove #4), Task 10 (Docs/supporting).
22. **Files to touch / Dev Agent Record file list incomplete (Acceptance Auditor)** — added `CLAUDE.md` to the Dev Agent Record modified files list with task annotations.
23. **AC #12 tie-rule for non-gated policies (Acceptance Auditor)** — clarified that `.simpleMajority` / `.confidenceWeighted` use effective threshold `0.0` for tie-rule purposes (display may show `n/a`).

### Low findings (4) — applied

24. **AC #6 micro-boundaries (Edge Case Hunter Q1)** — added AC #6g (`-0.0`) and AC #6h (`.signalingNaN`).
25. **Task 1.4 doc-comment requirements** — strengthened to require explicit threshold-applicability per case.
26. **Task 8.1 example SHA undefined (Blind Hunter)** — Task 8.1 now points to Task 0; Task 0.1 references "the recorded post-Story-3-4 baseline SHA (find it via `git log --grep`)" rather than naming a hardcoded SHA.
27. **DD#18 / DD#19 task-local procedure (Acceptance Auditor)** — accepted as DDs because they encode invariants the dev agent can violate accidentally; kept full detail in DDs rather than migrating to Tasks (the Tasks reference the DDs).

### Confirmed clean (no patch needed)

- **DD#15 / DD#17 / DD#16 carve-out** — durable behavioral contracts, correctly placed as DDs.
- **Confidence input precondition** (Edge Case Hunter Q7) — `BPMAnalyzer` never emits negative confidence; DD#17 stands.
- **Benchmark sweep always-on under `make benchmark`** (Edge Case Hunter Q10) — intentional, no env-gate needed.

### Codex thread references

- Blind Hunter: `019dd67a-3f47-7ac0-9649-ec7e7ff7bcdd`
- Edge Case Hunter: `019dd67b-2f51-76c0-98cb-4c53546276d6`
- Acceptance Auditor: `019dd67b-c81e-78f1-9447-34fc807af01a`

## Dev Agent Record

### Agent Model Used

claude-opus-4-7[1m] (Anthropic Claude Opus 4.7, 1M context)

### Debug Log References

#### Pre-implementation baseline capture (Task 8.1)

Run BEFORE Tasks 1-3 land:

```bash
make benchmark           # capture OA300 windowVoting Acc1/Acc2 baseline
make benchmark-giantsteps # capture GiantSteps windowVoting Acc1/Acc2 baseline
```

Record the four numbers in this section. Hardcode them as `let oa300Acc1Baseline = N` (etc.) constants in Tasks 8.2 and 8.3. They become the unconditional-`#expect` floors for AC #4.

**Captured at git SHA `ba6ba523990aecef872c0bdff96b758918609eee` (`ba6ba52`) — post-Story-3-4 close-out, pre-Story-3-5.**

Precondition verification (Task 0.1, DD#19):
- `git diff --quiet -- Sources Tests` → exit 0 (Sources/Tests clean)
- `git diff --cached --quiet -- Sources Tests` → exit 0 (Sources/Tests clean)
- The only staged paths at capture time were the story spec file (`_bmad-output/implementation-artifacts/3-5-configurable-window-voting-policy.md`) and `_bmad-output/implementation-artifacts/sprint-status.yaml`. Neither path is in `Sources/` or `Tests/`, so the library + test code at capture time was byte-identical to `ba6ba52`.

OA300 windowVoting baseline (captured via `swift test --filter benchmarkMergeStrategies`, reading the `windowVoting` row of the printed Merge Strategy Comparison table):
- Acc1: `57 / 82` (69.5%)
- Acc2: `72 / 82` (87.8%)

GiantSteps windowVoting baseline (captured via temporary `tempStory35Baseline` test calling `runBenchmark(intensity: .default, mergeStrategy: .windowVoting, tolerance: 0.02)`; harness removed after capture):
- Acc1: `537 / 661` (81.2%)
- Acc2: `546 / 661` (82.6%)

These four numbers are the unconditional `#expect` floors that Tasks 8.2 and 8.3 wire into `windowVotingDefaultPolicyMatchesBaseline`.

### Completion Notes List

#### Implementation summary

- New public type `VotingPolicy` (3 cases: `.simpleMajority`, `.confidenceWeighted`, `.thresholdGated`) added at `Sources/BoomBoomBoomKit/VotingPolicy.swift`. `String, CaseIterable, Sendable, Hashable`. No associated values.
- `CandidateMergeStrategy.merge(...)` extended with two trailing defaulted parameters `votingPolicy: VotingPolicy = .simpleMajority, votingThreshold: Double = 0.0`. Defaults preserve byte-for-byte behavior of all 8 strategies for callers that don't opt in. `CandidateMergeStrategy.allCases.count` is unchanged at 8.
- `mergeByWindowVoting(_:)` refactored to `mergeByWindowVoting(_:policy:threshold:)`; the original 25-line function split into shared clustering + 3 named resolvers (`resolveSimpleMajority`, `resolveConfidenceWeighted`, `resolveThresholdGated`) plus shared helpers `pickLargestCluster` and `bestWindow`. Threshold normalization (silent clamp + non-finite → 0.0) lives at the top of `resolveThresholdGated` per DD#9.
- All NEW resolver tiebreakers use the explicit `(higher confidence, lower original window index)` chain (DD#16) — never rely on `max(by:)` first-equal stability. The carve-out in DD#16 keeps `mergeMaxConfidence(_:)` unchanged so the other 7 strategies' fallback path is byte-identical to pre-Story-3-5.
- `AudioAnalysisService.Options` gained two non-optional fields with sensible defaults: `votingPolicy: VotingPolicy = .simpleMajority` and `votingThreshold: Double = 0.0`. Wired through to `merge(...)` at the existing call site. `Sendable` conformance preserved (verified by clean build).
- DAW oracle benchmark (`make oracle`) updated to invoke `analyzeBPM` with explicit `mergeStrategy = .windowVoting + votingPolicy = .simpleMajority` per AC #11.

#### Final corpus metrics

| Gate | Result | Spec |
|---|---|---|
| AC #4 OA300 (`.windowVoting`+`.simpleMajority`) Acc1, Acc2 | **57/82, 72/82** | EXACTLY matches Task 0 baseline (57/82, 72/82) at SHA `ba6ba52` |
| AC #4 GiantSteps (`.windowVoting`+`.simpleMajority`) Acc1, Acc2 | **537/661, 546/661** | EXACTLY matches Task 0 baseline (537/661, 546/661) at SHA `ba6ba52` |
| AC #11 DAW oracle — `Icicle - Condense` | **OK / OK** (rkbx 126.0, daw 126.0, detected 125.9) | within 2% Acc1 — no regression |
| AC #11 DAW oracle full corpus (`.windowVoting`+`.simpleMajority`) | Acc1=57/82 (69.5%), Acc2=72/82 (87.8%) | matches AC #4 baseline |
| Task 9.4 perf gate | mean +3.2% (0.175s → 0.180s) | < 5% threshold ✓ |
| Task 9.5 sweep wall-clock | 14.4s vs `benchmarkMergeStrategies` 83.7s ≈ **17%** | DD#18 expectation ≈ 1/8 ✓ |
| Task 9.7 unit tests | **227 passed** (existing 209 + 18 new) | all green |

DAW oracle Options used: `mergeStrategy = .windowVoting`, `votingPolicy = .simpleMajority`, `votingThreshold = 0.0` (per AC #11; default `.maxConfidence` would NOT exercise the new code path).

Test counts:
- Existing unit tests: 209 (pre-Story-3-5).
- New unit tests in `BPMAnalyzerTests.CandidateMergingTests`: **14** (Tasks 4.2/4.3/4.4 = 3, Tasks 5.1a/5.1b/5.2/5.3/5.4/5.5/5.6/5.8/5.9/5.10/5.11 = 11). Task 5.1's two scenarios (5b-i, 5b-ii) are split into separate `@Test`s for clarity, totaling 14 instead of the 13 the spec headlines.
- New unit tests in `AudioAnalysisServiceTests.AudioAnalysisServiceVotingPolicyTests`: **4** (Tasks 6.2/6.3/6.4/6.5).
- New corpus regression `#expect`s (env-gated, run via `make benchmark` / `make benchmark-giantsteps`): **2** (Tasks 8.2 OA300, 8.3 GiantSteps). Both pass with hardcoded baseline constants.

#### Best-policy comparison (AC #12 informational)

| Policy | Threshold | Acc1 | Acc2 | Notes |
|---|---|---|---|---|
| `.simpleMajority` | n/a | 57/82 (69.5%) | 72/82 (87.8%) | baseline match |
| `.confidenceWeighted` | n/a | 57/82 (69.5%) | 72/82 (87.8%) | matches baseline |
| `.thresholdGated` | 0.00 | 57/82 (69.5%) | 72/82 (87.8%) | equivalent to `.simpleMajority` per DD#3 |
| `.thresholdGated` | 0.25 | 57/82 (69.5%) | 72/82 (87.8%) | matches baseline |
| `.thresholdGated` | 0.50 | 57/82 (69.5%) | **73/82 (89.0%)** | **+1 Acc2 vs baseline** |
| `.thresholdGated` | 0.75 | 57/82 (69.5%) | **73/82 (89.0%)** | **+1 Acc2 vs baseline** (ties 0.50) |

Per AC #12 tie-rule (Acc1 → Acc2 → lowest threshold → source-order policy):
- All rows tie on Acc1 (57/82).
- `.thresholdGated@0.50` and `.thresholdGated@0.75` tie on Acc2 (73/82).
- Tiebreaker (lowest threshold): **`.thresholdGated@0.50`** wins.

Best row: **`.thresholdGated@0.50` — Acc1 57/82 vs baseline 57/82, Acc2 73/82 vs baseline 72/82** (+1 Acc2 hit).

The Acc1 floor (57/82) is met by every policy (no regression). The post-Story-3-4 `windowVoting` baseline is Acc1=57/82, Acc2=72/82; `.thresholdGated@0.50` matches Acc1 and beats Acc2 by 1 track on this corpus.

**Recommendation:** keep `.simpleMajority` as the default per the empirical-conservatism rationale in DD#7 — the +1 Acc2 win is small and well within sampling variance for an 82-track corpus. The configurability has direct value as a benchmark substrate (the 6-row policy sweep is now reproducible from `make benchmark`), and a follow-up story can revisit changing the default if larger corpora reinforce the result. Per AC #12 / Story 3-4 DD#12, this comparison is INFORMATIONAL — not a `#expect` floor and not a default-change authorization.

### Change Log

| Date | Change | Author |
|---|---|---|
| 2026-04-28 | Story created from epic AC, ADR-11, current `mergeByWindowVoting` reference, Story 3-3 / 3-3a / 3-4 precedents | bmad-create-story |
| 2026-04-28 | Pre-implementation Codex (gpt-5.5) Failure Mode Analysis applied: 5 new DDs (15-19), DD-3 / DD-7 revised, all 12 ACs and 10 Tasks tightened. 8 high-severity, 12 medium, 5 low findings landed in-place. | bmad-advanced-elicitation + codex:consult |
| 2026-04-28 | Self-Consistency review: 3 parallel Codex (gpt-5.5) agents (Blind Hunter / Edge Case Hunter / Acceptance Auditor). 3 critical, 11 high, 9 medium, 4 low findings landed. Caught two self-introduced contradictions from the FMA round (DD#3 vs Task 2.5; wall-clock math). Added Task 0 for baseline capture; specified `assertSameBPMResult` helper; hardened AC #3 plumbing test; added 4 new tests (5.8-5.11) for `allCases` invariants and tie-break edge cases. | bmad-advanced-elicitation + codex:consult |
| 2026-04-29 | Implementation: VotingPolicy enum + merge layer refactor + Options wiring + 18 new unit tests + 2 corpus regression tests + benchmarkVotingPolicies sweep + DAW oracle update. All AC #4 baselines match exactly; `.thresholdGated@0.50` discovered as best-Acc2 row (+1 over baseline); perf delta +3.2% under 5% gate; 227/227 tests pass. | bmad-dev-story (claude-opus-4-7) |
| 2026-04-29 | Code review (Blind Hunter / Edge Case Hunter / Acceptance Auditor): all 12 ACs PASS, all 19 DDs honored. 3 patches + 9 deferred findings; user scoped to "patches + actionable defers." Codex (gpt-5.5) plan-review disproved two originally-proposed deferred fixes (B2 denominator, B5 production -0.0 fix) — both stemmed from misreading Swift `max(_:_:)` semantics. | bmad-code-review + codex:consult |
| 2026-04-29 | Patches applied: A1 (thresholdValidation divergent fixture, locks in AC #6f clamp-to-1.0 prevention), A2 (`&&` → `||` in plumbing test), A3 (assertSameBPMResult short-circuit + reorder), B1 (nil-detection in OA300/GiantSteps baseline tests), B2 (assert in mergeByWindowVoting), B3 (threshold==1.0 boundary test), B4 (`-0.0` canonicalization pinned by test, no production change). 229/229 tests pass; lint clean. | bmad-dev-story (claude-opus-4-7) |

### File List

**New files:**
- `Sources/BoomBoomBoomKit/VotingPolicy.swift` — public enum, three cases, doc-comments per AC #1 / Task 1.4

**Modified files:**
- `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` — extended `merge(...)` signature with two trailing defaulted parameters; refactored `mergeByWindowVoting` into shared clustering + 3 named resolvers (`resolveSimpleMajority`, `resolveConfidenceWeighted`, `resolveThresholdGated`) + `pickLargestCluster` and `bestWindow` helpers (Task 2)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — added `votingPolicy: VotingPolicy = .simpleMajority` and `votingThreshold: Double = 0.0` to `Options`; updated Field-style convention doc-block; threaded fields through to `merge(...)` (Task 3)
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift` — `assertSameBPMResult` and `makeWindow` helpers + 14 new policy-specific tests in `CandidateMergingTests` (Tasks 4.2/4.3/4.4 and 5.0-5.11)
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` — `AudioAnalysisServiceVotingPolicyTests` suite (4 tests) + `createTwoSegmentClickTrackWAV` helper with `ClickSegment` parameter struct (Task 6)
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` — `benchmarkVotingPolicies` (Task 7) + `windowVotingDefaultPolicyMatchesBaseline` (Task 8.2)
- `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` — `windowVotingDefaultPolicyMatchesBaseline` (Task 8.3)
- `Tests/BoomBoomBoomKitBenchmarkTests/DAWOracleBenchmarkTests.swift` — explicit `mergeStrategy = .windowVoting + votingPolicy = .simpleMajority` in both oracle test methods (Task 9.3 / AC #11)
- `CLAUDE.md` — `CandidateMergeStrategy` description updated + `VotingPolicy` Key Types entry added + public types list updated (Task 10)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — story 3-5 status flipped `ready-for-dev` → `in-progress` → `review` (workflow)

### Review Findings

_Code review run 2026-04-29 against baseline `ba6ba52` via the `bmad-code-review` skill (Blind Hunter / Edge Case Hunter / Acceptance Auditor parallel layers). All 12 ACs verified PASS. Findings below are surface-level patches and deferred informational items — no `decision-needed` findings, no AC violations, no DD violations._

_Patches applied 2026-04-29 after a Codex (gpt-5.5) plan-review pass (thread `019ddc68-50c8-7c53-90c1-2f195791c3ff`) that disproved two originally-proposed deferred fixes (B2 denominator filter, B5 production -0.0 canonicalization) — both review findings stemmed from misreading Swift `max(_:_:)` Comparable semantics; production code already canonicalizes correctly. Codex-revised plan delivered 7 fixes (3 patches A1–A3 + 4 actionable defers B1–B4). 229 unit tests pass; lint clean (only pre-existing `LUFSAnalyzer.swift:94` TODO survives)._

- [x] [Review][Patch] AC #6 test fixture cannot lock in clamp-to-1.0 prevention [Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:1414-1442] — applied A1: swapped fixture to AC #5e-style divergent inputs `[(170, 0.4), (170.2, 0.3), (85, 0.9)]` and added per-case `expected: BPMResult` field to the cases tuple. Cases 6b (1.0) and 6d (2.0) now expect `windows[2]` via fallback; cases 6a/c/e/f/g/h expect `windows[0]` via consensus. A buggy `.infinity → 1.0` clamp would flip case 6f's expected `windows[0]` to `windows[2]` and the test FAILS.
- [x] [Review][Patch] Divergent integration test assertion is over-strict [Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:596-599] — applied A2: changed `&&` to `||`. Updated error message to "at least one of bpm/confidence must differ between policies." Concrete BPM sanity assertions (`~144`/`~100`) at lines 611-612 still independently catch plumbing breakage.
- [x] [Review][Patch] `assertSameBPMResult` zip iteration silently truncates on count mismatch [Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:951-969] — applied A3: moved trace nil-parity `#expect` BEFORE the zip iteration block (independent metadata, fires on count mismatch); added `guard got.candidates.count == expected.candidates.count else { return }` to short-circuit element-wise comparison.
- [x] [Review][Defer-applied] Nil-detection in baseline tests [OA300BenchmarkTests.swift, GiantStepsBenchmarkTests.swift] — applied B1: explicit `#expect` that no track returned nil from `analyzeBPM` before the unconditional `Acc1=N/M` assertion. A transient AVFoundation failure now surfaces with the offending track filenames instead of being swallowed into a misleading "Acc1 must equal N/M" message.
- [x] [Review][Defer-applied] `mergeByWindowVoting` precondition assert [Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:152-156] — applied B2: added `assert(results.count >= 2)` as first statement; chose `assert` over `precondition` per Codex review (private static helper with one provably-short-circuiting caller; release-build trap adds no value).
- [x] [Review][Defer-applied] Threshold-gate exact-equality boundary test [Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift] — applied B3: added `thresholdGatedAcceptsAtExactBoundary` test pinning `>=` semantics at `maxConf == effectiveThreshold == 1.0`. A future change to `>` would surface as a test failure.
- [x] [Review][Defer-applied] `-0.0` canonicalization pinned by test (no production change) [Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift] — demoted from production fix to test-only after Codex disproved the original review finding's premise (Swift `max(_:_:)` is `Comparable`-comparator-based, not IEEE-754 `maxNum`; current production code already canonicalizes `-0.0` to `+0.0`). Added `thresholdGatedNegativeZeroEqualsPositiveZero` test asserting `assertSameBPMResult(minusZero, plusZero)`.
- [x] [Review][Defer] 2% BPM tolerance clustering is non-transitive [Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:394-398] — deferred, pre-existing in original `windowVoting` (not introduced by this story); 100/102/104 BPM windows split into separate clusters depending on insertion order.
- [x] [Review][Defer] Hardcoded baseline numbers brittle across non-Apple-Silicon platforms [OA300BenchmarkTests.swift:422-424, GiantStepsBenchmarkTests.swift:121-123] — deferred, AC #4 design decision; per-platform IEEE 754 stable on current Apple targets.
- [x] [Review][Defer] FP equality on summed confidences short-circuits DD#16 tiebreaker chain at 1-ulp boundaries [Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:218-222] — deferred, per-platform deterministic; consistent with DD#17 "trust upstream contract" posture.
- [x] [Review][Defer] Threshold-gate `>=` boundary at exact maxConf == effectiveThreshold == 1.0 untested [Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:254] — deferred, low risk; current code uses `>=` (accept) but no test exercises the exact-equality boundary.
- [x] [Review][Defer] `benchmarkVotingPolicies` Acc1 denominator counts `audioData.count` even when a track produces 0 windows [OA300BenchmarkTests.swift:405] — deferred, pre-existing pattern (matches `benchmarkMergeStrategies`).
- [x] [Review][Defer] `windowVotingDefaultPolicyMatchesBaseline` silently treats `nil` analyzeBPM result as a 0 hit [OA300BenchmarkTests.swift:453] — deferred, low diagnostic weakness; a transient AVFoundation nil could fail "Acc1 must equal 57/82" without surfacing the actual cause.
- [x] [Review][Defer] AC #10 API-surface check uses typed `let` references that don't actively fail on third overload [BPMAnalyzerTests.swift:1469-1471] — deferred, author acknowledges in code comment; the spec wording demanded a stronger reflection-based or symbolgraph approach but the chosen pattern still requires updating this test on overload changes.
- [x] [Review][Defer] `-0.0` threshold not normalized to canonical `+0.0` inside `resolveThresholdGated` [Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:247] — deferred, behaviorally equivalent (`-0.0 == 0.0` numerically); only matters for code that prints/hashes the internal `effectiveThreshold`.
- [x] [Review][Defer] `mergeByWindowVoting` lacks `precondition(results.count >= 2)` [Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:152] — deferred, defensive missing; doc-comment claims the invariant but it's not asserted at runtime. Currently safe because the dispatcher short-circuits count==1 before reaching the helper.

_22 findings dismissed as noise / false positives / DD-covered (NaN propagation through `BPMResult.confidence` is covered by DD#17; `min(by:)` inverted-comparator pattern is correct Swift; `confidenceWeighted` 2-cluster-loses-to-singleton is intentional per DD#3; `runBenchmark(intensity:mergeStrategy:tolerance:)` overload exists despite Blind Hunter claim; etc.)._
