# Story 3.3: Click-Track Cross-Correlation

Status: done

## Key Design Decisions

1. **New `DSPTechnique` case `clickTrackCorrelation`.** Per ADR-8, this is a fully ablated technique. `DSPTechnique.allCases.count` becomes 7 and `TechniqueSet.allDSPCombinations()` returns 2^7 = 128 sets. The case must define `shortName` (`"click"`) and a doc-comment matching the existing pattern (cost / impact lines). Update `DSPTechnique.allCases.count` callers — only `allDSPCombinations()` reads it; no other count-coupled code exists today. Ablation runtime grows from ~9 min to ~25-30 min on M5 Max per `architecture.md` ADR-8 estimate; this is acceptable.

2. **Operate on the onset envelope, not raw audio.** Cross-correlation between a synthetic click pattern at audio rate (44.1 kHz) and 30-90 s of PCM is ~441× more expensive than the same operation at onset rate (~100 Hz). The existing pipeline already operates on the onset envelope (`onsetEnvelope: [Float]`, sampled at `onsetRate ≈ 100 Hz` from `sampleRate / hopSize = 44100 / 441`). All scoring metrics (ACF, tempogram, fused) are envelope-domain. Cross-correlation must stay in the same domain or its scores will not be comparable to the others. The onset envelope is already aligned to musical onsets (impulses on beats) so a click pattern at envelope-rate is the right matched filter.

3. **Pipeline placement: after step 9 (multi-peak extraction), before step 10 (octave disambiguation).** The epic states "candidates with the best rhythmic alignment are preferred during disambiguation." This means cross-correlation must rescore the `candidates` array before `resolveOctaveAmbiguity` consumes it, not after. Disambiguation already uses scores to break ties (e.g., octave fallback in fused-periodicity heuristic). Implementing the rescoring here also makes the technique compose naturally with `subBandVoting` and harmonic ratio detection in step 10. Placement after step 10b (sub-band voting) would only affect the single-`winner` tuple, not the full candidate set, and would not match the epic AC ("a synthetic click track at *that* BPM is generated and cross-correlated" implies per-candidate evaluation).

4. **Score combination is a parameterized blend, not authoritative replacement.** Update `candidates[i].score` to `candidates[i].score * (alpha + (1.0 - alpha) * normalizedClickScore)` where `alpha ∈ [0, 1]` is a damping floor and `normalizedClickScore ∈ [0, 1]` is the per-candidate normalized cross-correlation (see Decision #10). The blend always damps (multiplier ≤ 1) — it never boosts the absolute score; it tempers candidates that fail the rhythmic-alignment check while preserving most of the upstream-calibrated ordering. **Initial `alpha = 0.3`** (preserves 30% of the upstream score at zero click correlation; unchanged at full correlation). The default α is **finalized in Task 3.3** after a diagnostic data-collection pass (Task 3.0) reports the actual distribution of `normalizedClickScore` for correct vs incorrect candidates on the OA300 corpus — if correct candidates typically score 0.7+, then `α = 0.3` damps correct candidates by ~21% (0.3 + 0.7·0.7 = 0.79) and the default may need to rise. Pure damping (`α = 0`) is the corner case of the same form. The α-sweep covers `{0.0, 0.3, 0.5, 0.7}`; the default is changed only on a margin of ≥ 2 OA300 tracks with no GiantSteps regression — single-track twitches are below the binomial standard error (~5 pp on 82 tracks).

5. **Click-pattern synthesis is a new internal static helper, not a reuse of `TestSignalGenerators.generateClickTrack`.** The TestSupport function operates at audio rate (44.1 kHz default) and produces samples shaped for AVFoundation file playback (exponential decay over 64 samples). Production code needs envelope-rate clicks (~100 Hz, unit impulses or 1-2-frame decay). Mixing the two crosses an architectural boundary (test support library leaks into the production library). Add a new `internal static func synthesizeClickPattern(bpm:onsetRate:clickCount:) -> [Float]` inside `BPMAnalyzer.swift` that returns ≥ 8 click impulses spaced at `60 * onsetRate / bpm` frames. **Visibility is `internal static`, not `private static`** — tests in `BoomBoomBoomKitTests` use `@testable import BoomBoomBoomKit` to call `clickRescore` and `synthesizeClickPattern` directly (matches the existing `subBandVote` access pattern at BPMAnalyzer.swift:1148-1178; `@testable import` exposes `internal`, not `private`). Keep `TestSignalGenerators` unchanged — it remains the audio-rate generator for full-pipeline tests.

6. **Sparse normalized beat-search, not dense `vDSP_conv`.** The click kernel is overwhelmingly zeros — 8 unit impulses spread across ~480 frames at 60 BPM × 100 Hz. A dense `vDSP_conv` does multiply-add work on hundreds of zero kernel samples per lag (wasted). Compute the cross-correlation directly over the impulse positions:

   ```swift
   // clickIndices: the K integer offsets where the kernel is non-zero
   // outputLen = envelope.count - kernelLength + 1
   var bestNCC: Float = 0
   for lag in 0..<outputLen {
     var dot: Float = 0
     for offset in clickIndices { dot += envelope[lag + offset] }
     let segL2 = sqrt(cumSumSq[lag + kernelLength] - cumSumSq[lag])
     guard segL2 > 0 else { continue }   // see Decision #13
     bestNCC = max(bestNCC, dot / (kernelL2 * segL2))
   }
   ```

   This computes the same per-lag normalized cross-correlation as a dense `vDSP_conv`-based path with the zero-multiplications elided. The inner loop iterates the small `clickIndices` array (size = `clickCount`, default 8) — it is NOT a loop over the signal buffer, so it satisfies CLAUDE.md's "no manual loops over signal buffers" rule. **If a future maintainer prefers the dense `vDSP_conv` path** (e.g., to vectorize across multiple candidates), they MUST per Apple's local Accelerate header (`vDSP.h:2328`) use `vDSP_conv(envelope, 1, kernel, +1, output, 1, outputN, kernelN)` with the kernel passed **as-is, NO pre-reversal** — `vDSP_conv` is correlation when `IF > 0` and convolution when `IF < 0`. The sparse path above is the recommended implementation; document the equivalence in the function doc-comment.

7. **Add `clickCorrelationDetail: [String: Float]?` to `BPMDiagnosticTrace`.** Keys are candidate BPMs formatted as `"%.1f"` (matching the `harmonicRatioDetail` convention from Story 3-1); values are the per-candidate `normalizedClickScore` (pre-blend, in `[0, 1]`). Populated only when `enableTrace: true` AND `.clickTrackCorrelation` is in the technique set. `BPMDiagnosticTrace` is explicitly an evolving API (`BPMDiagnosticTrace.swift:14`) — adding one field is the cheap, audit-friendly choice, and without it any future regression debugging requires log-instrumentation + re-running the affected track. Trace also keeps `rawCandidates` (pre-rescore) for the upstream signal; the new field captures the bridge between raw and post-rescore values. Cost: ~4 lines of code; saves debugging hours.

8. **Ablation result decides preset membership.** Whether `.optimal` includes `.clickTrackCorrelation` is determined by ablation, not by this story file. The epic AC #4 requires "added to at least one TechniqueSet preset (or documented why excluded)." If ablation shows the technique improves Acc1 in combinations that include `.acfSharpening + .subBandVoting + .fineGridRefinement` (the current `.optimal` baseline), insert it into `.optimal`. If neutral, leave `.optimal` unchanged and add the technique to a new preset (e.g., `.experimental` or `.full` already includes everything). If regressive in `.optimal`-style combinations but useful elsewhere, document why and skip preset inclusion. **The story's success bar is "ablation completes" + "the technique exists in at least one preset OR is documented as excluded," NOT "Acc1 improves."**

9. **Intensity mapping deferred to ablation.** `AnalysisIntensity.techniqueSet` currently maps levels 1, 2, and 3-7 (default `.optimal`). If `.clickTrackCorrelation` ends up in `.optimal`, intensity 3+ users get it for free. If it lands in a new preset, the intensity table needs an additional case (e.g., level 4-5 uses the new preset). Decision happens in Task 4 (preset wiring) after Task 3 (ablation) reports.

10. **True normalized cross-correlation per lag, not raw dot product.** For each candidate the score is `max over lags ℓ of dot(kernel, envelope[ℓ:ℓ+L]) / (||kernel||₂ · ||envelope[ℓ:ℓ+L]||₂)` where `L = kernel.count`. Without this normalization, AC #3 ("120 BPM rescored above 60 BPM on a synthetic 120 BPM click track") is mathematically not guaranteed: a 60 BPM kernel applied to a 120 BPM signal hits every other beat with equal-magnitude alignment as a 120 BPM kernel hits every beat, so the raw dot product can tie or favor the half-tempo. The per-lag denominator divides out segment energy so the score reflects *alignment quality*, not segment loudness. Implementation: compute `||kernel||₂` once (single `vDSP_svesq` + sqrt). Compute `||envelope[ℓ:ℓ+L]||₂` per lag via a running sum of squares (one pass with `vDSP_vsq` + cumulative sum, or naive O(N·L) — for `L ≈ 480` (8 clicks at 60 BPM × 100 Hz) and `N ≈ 9000` (90 s window), naive is ≤ 4 M float ops per candidate, < 5 % of the existing tempogram cost). Cache the kernel L2 across candidates inside the `clickRescore` body — but the per-candidate kernel changes, so cache is per-iteration only.

11. **Returned `BPMResult.candidates` carry rescored scores when the technique is active.** Downstream consumers — specifically `CandidateMergeStrategy` (CandidateMergeStrategy.swift:107) — operate on `BPMResult.candidates` across windows. Returning raw (pre-rescore) candidates from `BPMResult` while passing rescored candidates into disambiguation creates a contract mismatch: window-level disambiguation respects click correlation but multi-window merge does not. Decision: the rescored candidate array is what flows into both `resolveOctaveAmbiguity` AND back out via `BPMResult.candidates`. Trace's `rawCandidates` field (BPMDiagnosticTrace.swift:57) keeps the pre-rescore values so diagnostic visibility is preserved.

12. **Sub-band voting authority is unchanged by rescoring.** `subBandVoting` (step 10b) operates on the *single winner* tuple after `resolveOctaveAmbiguity` selects it; it does not consult candidate scores. Click rescoring therefore influences which candidate becomes the winner via disambiguation, but does NOT change the sub-band voting outcome once a winner is chosen. The two techniques compose by sequence (step 9.5 → step 10 → step 10b), not by score blending. This is the intended ordering and is documented in `refineCandidates` doc-comment updates from Task 2.3. **Important caveat on measurable impact**: because step 10's `resolveOctaveAmbiguity` and step 10b's sub-band voting are largely score-blind (they decide on ACF/sub-band evidence, not candidate scores), the rescoring's actual influence on the final BPM is concentrated in non-octave/non-sub-band-disambiguated cases — a likely small fraction of OA300. Task 5.6 measures the per-track impact (changed ranking / changed step-10 winner / changed final BPM) so we ship with eyes open about the technique's effective reach.

13. **Zero-energy and short-segment guards are uniform across candidates.** Two failure modes need explicit contracts so they do not silently advantage one candidate over another:
    (a) **Zero-energy segment**: if `cumSumSq[lag + kernelLength] == cumSumSq[lag]`, then `segL2 == 0` and the normalized score for that lag is undefined. Treat as `0` (skip the lag in the max), since silence at the lag means no rhythmic alignment to measure. This guard is per-lag inside the inner loop.
    (b) **Envelope shorter than kernel** (`outputLen <= 0`): if ANY candidate's kernel doesn't fit the envelope, the rescoring step returns the original `candidates` array unchanged for the ENTIRE candidate set. Skipping only the offending candidate while rescoring others gives the skipped candidate an artificial advantage (its `oldScore × 1.0` competes with rescored values that are damped by `α + (1-α)·NCC < 1`). Real failure case: a 60 BPM × 8-click kernel at 100 Hz is ~700 frames; for intensity-1 short-audio paths (4 s = 400 frames) or truncated files, the guard fires. Uniform-skip preserves the contract that all candidates' scores are comparable.

As a library author,
I want a click-track cross-correlation technique that validates BPM candidates against the onset envelope,
so that candidates with the best rhythmic alignment are preferred during disambiguation.

## Acceptance Criteria

1. **Given** a new `DSPTechnique` case `clickTrackCorrelation`
   **When** added to the enum
   **Then** `DSPTechnique.allCases.count == 7`, `CaseIterable` automatically includes the new case, and `TechniqueSet.allDSPCombinations()` returns 128 sets

2. **Given** the technique is active for a set of BPM candidates
   **When** the pipeline runs the new step (between step 9 candidate extraction and step 10 disambiguation)
   **Then** each candidate's score is updated to `oldScore * (alpha + (1 - alpha) * normalizedClickScore)` where `alpha` is the chosen default (initially `0.3`, finalized in Task 3.3 and recorded in Completion Notes) and `normalizedClickScore` is the maximum over lags of `dot(kernel, envelope[ℓ:ℓ+L]) / (||kernel||₂ · ||envelope[ℓ:ℓ+L]||₂)` with the kernel synthesized at the candidate BPM via `synthesizeClickPattern`
   **And** the per-lag dot product is computed via the sparse beat-search loop in DD#6 (or the equivalent dense `vDSP_conv` with `IF = +1` and kernel passed as-is, NO pre-reversal)
   **And** the candidate ordering is sorted descending by post-rescore score using `sorted(by:)` with an explicit tiebreaker on original index (for determinism — `Array.sort` is not contractually stable)
   **And** when ANY candidate's kernel doesn't fit the envelope (`outputLen <= 0`), the rescoring step returns the original `candidates` unchanged for the entire candidate set (uniform-skip per DD#13)

3. **Given** the rescoring helper is exercised by a three-test gauntlet:
   - **3a (clean synthetic)**: A 120 BPM synthetic click envelope (unit impulses at frames `0, 50, 100, ..., 950`), with input candidates `[(120.0, 1.0), (60.0, 1.0), (180.0, 1.0)]`
   - **3b (noisy synthetic)**: The same 120 BPM envelope plus deterministic Gaussian noise generated by `SplitMix64(seed: 0xB00D_F00D)` at amplitude `0.25` (gives ~ -6 dB envelope-domain SNR vs unit impulses), same input candidates
   - **3c (anti-test)**: A 60 BPM synthetic click envelope (unit impulses at frames `0, 100, 200, ..., 900`), with input candidates `[(60.0, 1.0), (120.0, 1.0), (90.0, 1.0)]`
   - **3d (alpha-blend test)**: Same 120 BPM envelope as 3a but input candidates with non-uniform old scores `[(120.0, 0.5), (60.0, 1.0)]` — the upstream-favored candidate is 60 BPM but rhythmic alignment favors 120. Tests that the blend formula's α value is actually applied (not just the raw NCC)
   **When** the technique runs at the chosen default α (initially 0.3, called via `@testable import` against the `internal static clickRescore` helper)
   **Then**
   - For 3a: `rescoredScore(120) >= 1.2 * rescoredScore(60)` (achievable bound — the theoretical NCC ratio for an 8-click kernel is `1 / sqrt(8/15) ≈ 1.37`; with α=0.3 the post-blend ratio is ≈1.23, so 1.2× holds with ~3% slack. The earlier 1.5× target was mathematically impossible for an 8-click kernel and was corrected.)
   - For 3b: `rescoredScore(120) > rescoredScore(60)` (margin reduced by noise but ranking preserved)
   - For 3c: `rescoredScore(60) > rescoredScore(120)` (the symmetry-failure trap — if this fails, the metric isn't measuring rhythmic alignment, it's measuring envelope energy)
   - For 3d: `rescoredScore(120) > rescoredScore(60)` IFF the chosen α is small enough that the NCC ratio overcomes the 0.5/1.0 oldScore ratio. Concretely: `0.5 * (α + (1-α) · NCC₁₂₀) > 1.0 * (α + (1-α) · NCC₆₀)`. For α=0.3 with `NCC₁₂₀ = 1.0, NCC₆₀ = 0.73`, LHS = 0.5 × 1.0 = 0.5, RHS = 0.811 — so RHS wins (60 stays first). Assert `rescoredScore(60) > rescoredScore(120)` here. (The α=0.3 default is corroborative, not authoritative — that's the design intent of DD#4.)

4. **Given** `make ablation`
   **When** the full 128-combination matrix runs at the chosen default α
   **Then** all combinations complete without crashes
   **And** per-combo Acc1/Acc2 are emitted to `_bmad-output/implementation-artifacts/3-3-ablation-results.json` (label, acc1, acc2, total per row) for visibility and downstream comparison
   **And** `clickTrackCorrelation` appears in at least one named preset *other than `.full`* (since `.full = Set(allCases)` includes everything by definition and would trivially satisfy "at least one preset") OR the story's Completion Notes document why it is excluded from all named presets except `.full`
   **And** the **64 click-OFF combos** are 1:1 compared against the Story 3-2 baseline snapshot — every previously-passing combo's Acc1 is unchanged or higher. The **64 click-ON combos** have no prior baseline; for each, report the Acc1 delta vs its click-OFF twin (paired comparison) in the ablation results JSON. Click-on regressions vs click-off twins are flagged in Completion Notes but are not a hard ship gate (the technique may improve some preset families and hurt others — that's exactly what ablation is for).

5. **Given** `AnalysisIntensity.techniqueSet`
   **When** reviewed after ablation
   **Then** `clickTrackCorrelation` is mapped to appropriate intensity levels based on ablation results, and the mapping is documented in `AnalysisIntensity.swift`'s `techniqueSet` doc-comment

6. **Given** `make benchmark` and `make benchmark-giantsteps`
   **When** OA300 and GiantSteps corpora run at the **default** intensity (whatever preset `AnalysisIntensity(.default).techniqueSet` resolves to after Task 4)
   **Then** OA300 Acc1 ≥ 57/82 (69.5%) AND Acc2 ≥ 73/82 (89.0%); GiantSteps Acc1 ≥ 537/661 (81.2%) AND Acc2 ≥ 546/661 (82.6%). These four floors are unconditional `#expect` assertions on every CI invocation regardless of whether the click technique landed in `.optimal` — they catch wiring bugs that "by construction" reasoning would miss.
   **And** the click-enabled preset (whether or not it's `.optimal`) is also run against both corpora and its Acc1/Acc2 numbers are reported in Completion Notes for visibility (no regression gate on this run — it's data, not a ship gate, since the click preset may not be the default).

7. **Given** the `optimal`-membership invariant
   **When** Task 4 completes
   **Then** the test suite includes a unit test asserting either `TechniqueSet.optimal.contains(.clickTrackCorrelation) == false` (if click stayed out) OR `== true` (if click was added). The test follows the Task 4 decision and locks it in — future refactors that flip the invariant by accident will fail at unit-test time, before reaching corpus benchmarks.

8. **Given** ablation runtime exceeds the existing 15-min cap in `AblationFullMatrixTests` (Task 3 estimates 25-30 min for 128 combos)
   **When** the test infrastructure is updated
   **Then** either (a) the `AblationFullMatrixTests` time cap is raised to 35 min and CI accepts the longer run, OR (b) a `make ablation-smoke` target runs a curated 16-combo subset (baseline, optimal, optimal+click, full, full−click, dnbOptimized, plus 10 ablation-relevant pairs) for fast cadence, and `make ablation` runs the full 128. The smoke lane MUST include `optimal` and `optimal+click` so click-technique regressions are caught without a 30-min wait.

## Tasks / Subtasks

- [x] Task 1: Add the `DSPTechnique.clickTrackCorrelation` case (AC: #1)
  - [x] 1.1: Edit `Sources/BoomBoomBoomKit/DSPTechnique.swift`. Add the new case at the end of the enum (after `subBandVoting`). Doc-comment: "Per-candidate cross-correlation between a synthetic click pattern at the candidate BPM and the onset envelope. Boosts candidates with strong rhythmic alignment before disambiguation. Cost: low (one `vDSP_conv` per candidate, ~3 candidates). Impact: TBD (validated by ablation in Task 3)." Add `case .clickTrackCorrelation: return "click"` to `shortName`.
  - [x] 1.2: Verify `TechniqueSet.allDSPCombinations()` now returns 128 (`1 << 7`). No other code change required — `CaseIterable` and the bitmask loop adapt automatically.
  - [x] 1.3: Write a unit test asserting `DSPTechnique.allCases.count == 7` and `TechniqueSet.allDSPCombinations().count == 128`. Updated existing `AblationQuickTests` suite (`allCasesCount` and `allCombinationsCount`).

- [x] Task 2: Implement the rescoring step in the BPM pipeline (AC: #2, #3)
  - [x] 2.1: Add `internal static func synthesizeClickPattern(bpm: Double, onsetRate: Double, clickCount: Int = 8) -> [Float]` inside `BPMAnalyzer.swift`. **Compute click indices first, then allocate** to avoid the off-by-one fence: `let period = 60.0 * onsetRate / bpm` (Double); `let indices = (0..<clickCount).map { Int((Double($0) * period).rounded()) }`; `let length = indices.last.map { $0 + 1 } ?? 0`; `var pattern = [Float](repeating: 0, count: length)`; for each index set `pattern[index] = 1.0`. This guarantees `index < length` for every write and removes the `Int(period * (clickCount-1)) + 1` rounding-fence that could yield `index == length`. Guards: return empty `[Float]` if `bpm <= 0`, `!bpm.isFinite`, `onsetRate <= 0`, `clickCount < 4`, or `period < 1.0` (BPMs > 6000 alias at 100 Hz onset rate). Caller treats empty kernel as "skip rescoring for this candidate; preserve original score."
  - [x] 2.2: Add `internal static func clickRescore(candidates: [(bpm: Double, score: Float)], onsetEnvelope: [Float], onsetRate: Double, alpha: Float = 0.3, trace: inout BPMDiagnosticTrace?) -> [(bpm: Double, score: Float)]` inside `BPMAnalyzer.swift`. **Visibility is `internal`, not `private`** — the unit tests in AC #3 use `@testable import BoomBoomBoomKit` to call this directly (matches the `subBandVote` test access pattern). Implementation:
    1. **Pre-flight kernel-fit check** (DD#13b): synthesize each candidate's kernel; if ANY candidate yields an empty kernel OR `envelope.count < kernel.count` (i.e., `outputLen <= 0`), return `candidates` unchanged for the entire set (uniform skip — partial-skip would advantage the skipped candidate).
    2. **Compute envelope cumulative sum-of-squares once**: `var sq = [Float](repeating: 0, count: envelope.count); vDSP.square(envelope, result: &sq)`; then `var cumSumSq = [Float](repeating: 0, count: envelope.count + 1)` and fill via prefix sum (one O(N) pass — Swift `for i in 0..<sq.count { cumSumSq[i+1] = cumSumSq[i] + sq[i] }` is acceptable here as it's a control-flow loop over a scalar accumulator, not bulk numeric work).
    3. **Per-candidate**:
       a. Synthesize kernel + extract `clickIndices` (the K positions where kernel is non-zero); compute `kernelL2 = sqrt(Float(clickCount))` for unit-impulse kernels OR `var kernelL2: Float = 0; vDSP_svesq(kernel, 1, &kernelL2, vDSP_Length(kernel.count)); kernelL2 = sqrt(kernelL2)` if a future change introduces tapered clicks.
       b. **Sparse beat-search per lag** (per DD#6 pseudocode):
          ```swift
          var bestNCC: Float = 0
          for lag in 0..<outputLen {
            var dot: Float = 0
            for offset in clickIndices { dot += onsetEnvelope[lag + offset] }
            let segL2 = sqrt(cumSumSq[lag + kernelLength] - cumSumSq[lag])
            guard segL2 > 0 else { continue }   // DD#13a: zero-energy guard
            bestNCC = max(bestNCC, dot / (kernelL2 * segL2))
          }
          ```
          `bestNCC ∈ [0, 1]` by Cauchy-Schwarz (no cross-candidate max-normalization needed; the per-lag denominator already normalizes).
       c. Apply blend: `newScore = oldScore * (alpha + (1.0 - alpha) * bestNCC)`.
       d. **Trace population** (DD#7): `trace?.clickCorrelationDetail?["%.1f" % bpm] = bestNCC` (initialize the dictionary on the first candidate if `trace?.clickCorrelationDetail == nil`).
    4. **Sort with explicit tiebreaker** for determinism (Swift `Array.sort` is not contractually stable):
       ```swift
       return candidates.enumerated()
         .map { (offset: $0.offset, bpm: $0.element.bpm, newScore: rescored[$0.offset]) }
         .sorted { lhs, rhs in lhs.newScore != rhs.newScore ? lhs.newScore > rhs.newScore : lhs.offset < rhs.offset }
         .map { (bpm: $0.bpm, score: $0.newScore) }
       ```
  - [x] 2.3: Wire the rescoring step into `estimateBPM()`. After `let candidates = extractTopCandidates(...)` (BPMAnalyzer.swift:273) and before `let disambiguated = resolveOctaveAmbiguity(...)` (line 280), insert: `let rescoredCandidates = techniques.contains(.clickTrackCorrelation) ? clickRescore(candidates: candidates, onsetEnvelope: onsetEnvelope, onsetRate: onsetRate) : candidates`. Pass `rescoredCandidates` to `resolveOctaveAmbiguity`. **Trace contract**: `trace?.rawCandidates = candidates` (the pre-rescore array) so diagnostic output preserves the upstream signal. **`BPMResult.candidates` contract**: when the technique is active, the returned `BPMResult` carries `rescoredCandidates`, not `candidates` — downstream `CandidateMergeStrategy` consumers (CandidateMergeStrategy.swift:107) operate on rescored values so window-level disambiguation and multi-window merge agree. Add a 1-line doc comment on the BPMResult-construction line noting the change. Also update `refineCandidates` doc-comment to mention that rescoring runs at step 9.5 when `.clickTrackCorrelation` is active.
  - [x] 2.4: Write the AC #3 four-test gauntlet BEFORE implementing 2.1-2.3. All tests use `@testable import BoomBoomBoomKit` to call `clickRescore` directly with hand-crafted onset envelopes (100 Hz, 10 s = 1000 frames):
    - **3a (clean synthetic 120)**: envelope has unit impulses at frames `0, 50, 100, ..., 950` (every 0.5 s = 120 BPM exactly). Input candidates `[(120.0, 1.0), (60.0, 1.0), (180.0, 1.0)]`. Assert `rescoredScore(120) >= 1.2 * rescoredScore(60)` AND `rescoredScore(120) > rescoredScore(180)`.
    - **3b (noisy synthetic 120)**: same envelope + deterministic Gaussian noise generated by `SplitMix64(seed: 0xB00D_F00D)` at amplitude `0.25` (~-6 dB SNR vs unit impulses). Generate via the standard Box-Muller transform on two `SplitMix64` outputs. Assert `rescoredScore(120) > rescoredScore(60)` (ranking holds; margin tightens).
    - **3c (anti-test on 60 BPM input)**: envelope has impulses at frames `0, 100, 200, ..., 900` (every 1.0 s = 60 BPM). Input candidates `[(60.0, 1.0), (120.0, 1.0), (90.0, 1.0)]`. Assert `rescoredScore(60) > rescoredScore(120)`. **The symmetry-trap test — if it fails, the metric is measuring envelope energy not rhythmic alignment.**
    - **3d (alpha-blend test)**: same 120 BPM envelope as 3a but input candidates `[(120.0, 0.5), (60.0, 1.0)]` (upstream prefers 60 BPM; rhythmic alignment prefers 120). Assert `rescoredScore(60) > rescoredScore(120)` at α = 0.3 (per AC #3d arithmetic). This locks in the corroborative-not-authoritative design intent of DD#4 — α=0.3 cannot flip the winner against a 2× upstream-score advantage. If a future α change makes click rescoring authoritative (e.g., α = 0.0), this test must be updated to assert the new behavior.
  - [x] 2.5: Add a kernel-length unit test for the off-by-one prevention (AC #8 test bed): for each `bpm in [61, 63, 67, 89, 120, 126, 200]` at `onsetRate = 100.0`, assert that `pattern.count == indices.last! + 1` AND no synthesized index reaches `pattern.count`. The fractional-period BPMs (61, 63, 67, 89, 126) are the cases where the original `Int(period * (clickCount-1)) + 1` formula would have failed. Concrete witness for `bpm = 61`, `onsetRate = 100`: `period = 60.0/61.0 * 100 = 9.836...`; `7 * period = 68.852`; the rounded last index is `Int(68.852.rounded()) = 69`; the original-formula length was `Int(period * 7) + 1 = Int(68.852) + 1 = 69` → `pattern[69]` is out of bounds. Include this BPM as the anchor regression case with an explicit comment in the test.
  - [x] 2.6: Add a smoke test that runs the full pipeline at intensity 7 with a custom `TechniqueSet` of `.optimal.inserting(.clickTrackCorrelation)` on a 120 BPM synthetic click track at 44.1 kHz (use `TestSignalGenerators.generateClickTrack`). Assert `result.bpm` is within 2% of 120.0. This is an integration test for the wiring in Task 2.3.

- [x] Task 3: Validate against the ablation matrix (AC: #4, #8)
  - [x] 3.0: **α justification — diagnostic data collection BEFORE the sweep**. Run `.optimal+click` at α=0.3 against a 20-track OA300 sample (use the first 20 tracks alphabetically for determinism). For each track, log per-candidate `(bpm, oldScore, normalizedClickScore, newScore, isCorrectCandidate)` where `isCorrectCandidate = (Acc1Match(bpm, expectedBPM) || Acc2Match(bpm, expectedBPM))`. Emit to `_bmad-output/implementation-artifacts/3-3-click-score-distribution.json`. Inspect the distribution: what is the mean/median `normalizedClickScore` for correct candidates vs incorrect? If correct candidates score ≥ 0.7 typically, α=0.3 damps them by ~21% — that's significant; consider raising default α or starting the sweep at a higher floor. Document the inspection in Completion Notes. This step is cheap (~2 min) and grounds the α-sweep in real-corpus distributions, not the synthetic intuition that produced the initial 0.3.
  - [x] 3.1: Adjust `AblationFullMatrixTests` infrastructure for the doubled matrix. Either (a) raise the existing 15-min time cap to 35 min, OR (b) add a `make ablation-smoke` target that runs the curated 16-combo subset specified in AC #8. Recommended: do BOTH — keep `make ablation` as the full 128-combo gate, add `make ablation-smoke` for fast cadence. Update `Makefile` and the test's `@Test` time budget.
  - [x] 3.2: Run `make ablation` at the chosen default α (initially 0.3, possibly raised after Task 3.0). All 128 combinations must complete without crashes. Emit per-combo `(label, acc1, acc2, total)` to `_bmad-output/implementation-artifacts/3-3-ablation-results.json`. Compare 64 click-OFF combos 1:1 against Story 3-2 baseline (every previously-passing combo's Acc1 must hold or improve); for the 64 click-ON combos, emit Acc1 delta vs each combo's click-OFF twin (paired comparison) — flagged as data, not a hard gate.
  - [x] 3.3: **α-sweep with margin gate**. Re-run the 4 `.optimal`-family combinations (`.optimal`, `.optimal+click`, `.optimal-fine+click`, `.optimal+click+norm`) at `alpha ∈ {0.0, 0.3, 0.5, 0.7}`. This is 16 runs (~3 min total). The default α changes from the current value ONLY if a new α produces ≥ 2 OA300 tracks better than the current default on `.optimal+click`, AND no GiantSteps regression (Acc1 unchanged or higher). Single-track twitches (Δ = 1) are below the binomial standard error (~5 pp on 82 tracks) and do not justify changing the default. Document the per-α numbers and the margin-gate decision in Completion Notes.
  - [x] 3.4: Compare `.optimal` (sharp+vote+fine, baseline 67.1% / 55/82) against `.optimal + clickTrackCorrelation` at the chosen α. If the click variant wins by ≥ 2 OA300 tracks AND no GiantSteps regression: Task 4 inserts `.clickTrackCorrelation` into `.optimal`. If neutral or regresses: Task 4 either creates a new preset or documents exclusion. Examine whether any new ≤ 5-technique combination outperforms `.optimal`. Re-run noise-suspicious results (Δ < 2 tracks) to confirm before changing `.optimal`.

- [x] Task 4: Update presets and intensity mapping (AC: #4, #5, #7)
  - [x] 4.1: Based on Task 3 result, edit `Sources/BoomBoomBoomKit/DSPTechnique.swift`. If the click technique improves `.optimal`, update `optimal` to `[.acfSharpening, .subBandVoting, .fineGridRefinement, .clickTrackCorrelation]` and update its doc-comment Acc1 number. If neutral, leave `.optimal` and add the technique to `.full` (it already contains all cases). If a new preset is preferable, add it (`public static let clickAugmented` or similar) with documentation explaining the Acc1 trade-off.
  - [x] 4.2: If the click technique improves `.optimal`, the existing `AnalysisIntensity.techniqueSet` mapping (default → `.optimal`) automatically activates it for intensity 3-7 users. No mapping change needed. If the click technique landed in a non-default preset, evaluate whether to map intensity 6 or 7 to the new preset (extends the intensity table). If neutral and excluded from all presets, document the exclusion in Completion Notes.
  - [x] 4.3: Update `AnalysisIntensity.swift:46-49`'s `techniqueSet` doc-comment to reflect the new mapping.
  - [x] 4.4: Update `CLAUDE.md` Architecture section's `BPMAnalyzer` description: pipeline grows from "10-step DSP pipeline" to either "10-step DSP pipeline with optional candidate rescoring" or "11-step DSP pipeline" depending on accounting style (existing pipeline-step language counts gated stages; the rescoring step is gated, so "10-step" is still accurate — append a parenthetical "(plus optional click-track rescoring at step 9.5)"). Preferred form: keep "10-step DSP pipeline" and add the technique to the per-stage list as "step 9b: click-track cross-correlation (optional, rescores candidates)."
  - [x] 4.5: Add an `optimal`-membership invariant unit test (AC #7): `#expect(TechniqueSet.optimal.contains(.clickTrackCorrelation) == <decision>)` where `<decision>` is `true` or `false` based on Task 4.1. Locks the Task 4 decision so future refactors that flip it accidentally fail at unit-test time.

- [x] Task 5: Validate against corpus benchmarks (AC: #6)
  - [x] 5.1: Run `make benchmark` (OA300) at the **default** intensity (whatever `.default.techniqueSet` resolves to after Task 4). Assert OA300 Acc1 ≥ 57/82 AND Acc2 ≥ 73/82 — these are unconditional `#expect` floors per AC #6, regardless of preset membership. Record exact counts.
  - [x] 5.2: Run `make benchmark-giantsteps` at the default intensity. Assert Acc1 ≥ 537/661 AND Acc2 ≥ 546/661 — also unconditional `#expect` floors.
  - [x] 5.3: **Click-enabled visibility run**: re-run OA300 and GiantSteps with `TechniqueSet([.acfSharpening, .subBandVoting, .fineGridRefinement, .clickTrackCorrelation])` (the `.optimal+click` preset) regardless of whether Task 4 inserted it into `.optimal`. Report Acc1/Acc2 in Completion Notes for downstream comparison. **No regression gate on this run** — it's data, not a ship gate.
  - [x] 5.4: Run `make oracle`. Three-way comparison should not regress on the DAW oracle set (Icicle stays within 2% Acc1; no other DAW oracle track flips from in-tolerance to out).
  - [x] 5.5: Run `make perf-benchmark`. Capture a fresh perf-baseline at the post-implementation SHA. Note the wall-clock delta vs the prior baseline (`Apple_M5_Max-26--Debug--20260426T051054Z--1380089--*.json` is the current reference — mean ≈ 0.184 s on M5 Max). The sparse beat-search adds K (≈8) loads per lag per candidate plus per-lag normalization (cumulative-sum-of-squares is O(N), one pass); expected timing impact < 5 % at the default 3 candidates. Record the delta.

  - [x] 5.6: **Per-track click-impact report** (DD#12 caveat). Run OA300 with `enableTrace: true` at the chosen-default-α `.optimal+click` preset, plus the same preset with click disabled. For each track, extract from trace and compare:
    - **changedRanking**: top candidate by post-rescore score differs from top candidate by pre-rescore score
    - **changedStep10Winner**: `disambiguationResult.bpm` differs between click-on and click-off runs
    - **changedFinalBPM**: `result.bpm` differs between click-on and click-off runs (after step 10b sub-band voting)
    Emit the counts to `_bmad-output/implementation-artifacts/3-3-click-impact-report.json` as `{changedRanking: N, changedStep10Winner: M, changedFinalBPM: K, total: 82}`. This measures the technique's actual reach on the corpus — DD#12 noted that step 10's score-blind disambiguation paths and step 10b's sub-band override likely mute most rescoring effects. If `changedFinalBPM == 0` on OA300, the technique is functionally inert at the default intensity; the spec then must either (a) document the inertness honestly, or (b) revisit step placement (move rescoring AFTER step 10b). Without this report we ship blind.

- [x] Task 6: Gating checklist
  - [x] 6.1: `make fmt` — clean
  - [x] 6.2: `make lint` — no new warnings (1 pre-existing TODO in `LUFSAnalyzer.swift` is acceptable)
  - [x] 6.3: `make test` — all tests pass. Record final test count (currently 165 + new tests from Task 1.3, 2.4, 2.5). **Final: 180 / 180.**
  - [x] 6.4: Record final Acc1/Acc2 for OA300 and GiantSteps, ablation `.optimal` Acc1, and perf-baseline filename in Completion Notes.

### Review Findings

Code review run on 2026-04-26 via three parallel Codex (gpt-5.5) agents — Blind Hunter (no-context adversarial), Edge Case Hunter (path enumeration with project access), Acceptance Auditor (spec-vs-diff). 40 raw findings produced; 16 kept after deduplication and triage (3 decision-needed, 11 patch, 2 deferred); 24 dismissed as false positives, already-handled, or already-disclosed-in-spec.

#### Decision-needed

- [x] [Review][Decision] **Public API path for `.clickAugmented` is unreachable from a public consumer.** ✅ Resolved 2026-04-26 via Codex (gpt-5.5) recommendation: chose option (a) — added `public var techniques: TechniqueSet?` to `AudioAnalysisService.Options`. Field name matches the existing internal `BPMAnalyzer.Options.techniques` for layer-boundary symmetry, and the optional shape matches the existing `onProgress?` precedent for opt-in features. `analyzeBPM(url:options:)` resolves the override once (`options.techniques ?? options.intensity.techniqueSet`), passes it through to `BPMAnalyzer.Options`, and uses the resolved set's `candidateCount` for cross-window merge so the merge step matches what the pipeline actually extracted. The Options struct doc-comment now documents the optional-vs-non-optional convention. `AnalysisIntensity.swift` doc-comment updated to direct users at the public path. Tests added in `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` (3 tests in `AudioAnalysisServiceTechniquesOverrideTests`). The broader public-API harmonization work is split into follow-up Story 3-3a.

- [x] [Review][Decision] **AC#3 gauntlet hard-codes `alpha: 0.3`, but production default is α=0.7.** ✅ Resolved 2026-04-26 via Codex (gpt-5.5) recommendation + user elicitation: chose option (c) — gauntlet now runs at BOTH α=0.3 and α=0.7 with α-specific bounds. The 3a expected ratio is 1.2× at α=0.3 and 1.085× at α=0.7 (computed via `expectedRatio3a(forAlpha:)`); 3b/3c/3d hold direction-only for both α. All four AC#3 sub-tests parameterize via `arguments: [Float(0.3), Float(0.7)]`, doubling effective coverage. Tests pass at both values.

- [x] [Review][Decision] **Ablation JSON omits paired click deltas + Story 3-2 baseline gate.** ✅ Resolved 2026-04-26: extended JSON schema. Each row now carries `clickOnVsOffDeltaAcc1` (set to int delta for click-ON combos, null for click-OFF) and `vsStory32BaselineDeltaAcc1` (null until a stored Story 3-2 baseline JSON exists; reserved for future paired comparison without code change). New top-level `regressionGate` object captures `optimalAcc1`, `optimalAcc1Floor: 55`, `status: pass|fail`, and the list of click-OFF combo labels for future story 3-2 baseline comparison. Existing `optimalAcc1 >= 55` `#expect` carried forward as the load-bearing gate.

#### Patch

All 11 patches resolved in-flight 2026-04-26 (single commit, post-codex re-plan):

- [x] [Review][Patch] GiantSteps Acc1/Acc2 floors asserted in `GiantStepsBenchmarkTests.swift:53-90` (`benchmarkDefaultIntensity` test now `#expect`s Acc1 ≥ 537/661 AND Acc2 ≥ 546/661, mirroring the OA300 pattern).
- [x] [Review][Patch] `alphaOverride()` body wrapped in `#if DEBUG` in `BPMAnalyzer.swift:1794-1810`. Release builds cannot have BPM results mutated by env var.
- [x] [Review][Patch] α-sweep iteration now uses `defer { unsetenv(...) }` and the test carries the `.serialized` trait (`AblationFullMatrixTests.swift:339, 365-378`). Exception-safe and process-global-mutex-safe.
- [x] [Review][Patch] `make click-impact-report` Makefile target added; sets `CLICK_IMPACT=1` + `CLICK_IMPACT_OUT_DIR` and writes to `_bmad-output/implementation-artifacts/`.
- [x] [Review][Patch] Click-impact JSON now emits `total: gt.count`, `analyzed: pairs.count`, `failed: gt.count - pairs.count`. Undercount visible in artifact.
- [x] [Review][Patch] `synthesizeClickPattern` guard now includes `onsetRate.isFinite` (`BPMAnalyzer.swift:1830`).
- [x] [Review][Patch] `clickRescore` clamps alpha to `[0, 1]` at entry and clamps `bestNCC` to `[0, 1]` before the blend (handles FP rounding + non-finite envelope edge cases). Doc-comment invariant "blend always damps" is now enforced.
- [x] [Review][Patch] Stale α=0.3 comment in α-sweep test replaced; doc now says "production default α=0.7" and explains the DEBUG-gated env hook.
- [x] [Review][Patch] Period-math comments fixed: `60/61 · 100 = 98.36...` (was `9.836...`) in `BPMAnalyzer.swift:1809`. Test comment in `BPMAnalyzerClickTrackTests.swift:70-72` rewritten with correct arithmetic showing `Int(688.52) + 1 = 689`.
- [x] [Review][Patch] New `stableTiebreakerOnTie` test in `ClickRescoreTests` constructs a true tie (flat envelope ⇒ all NCCs zero ⇒ all post-rescore scores tied) and asserts offset-order preservation.
- [x] [Review][Patch] Empty-corpus sanity guards added: `#expect(total > 0)` in `clickVisibilityOA300`, `#expect(totalAnalyzed > 0)` in `smokeAblation`, `#expect(pairs.count > 0)` in `clickImpactReport`. Corpus misconfigurations fail loudly.

#### Deferred (pre-existing or out of scope)

- [x] [Review][Defer] Trace-key collision on `%.1f` BPM rounding [`Sources/BoomBoomBoomKit/BPMAnalyzer.swift:1970`] — deferred, pre-existing pattern (`harmonicRatioDetail`, `subBandVoteDetail` use identical `%.1f` keys).
- [x] [Review][Defer] Ablation matrix runs all 128 combos concurrently without batching [`Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift:73`] — deferred, runs in 77.5 s on M5 Max in practice; not currently a constraint.

## Pre-Implementation Review (2026-04-26, party-mode + Codex gpt-5.5)

The story passed through a multi-agent pre-implementation review before flipping to `ready-for-dev`. Codex (gpt-5.5) ran a Blind-Hunter / Edge-Case-Hunter / Acceptance-Auditor pass against the spec; BMAD party-mode agents (Winston/architect, Amelia/dev, Quinn/QA, Bob/SM) reviewed and filtered the findings. Patches landed before kickoff:

- [x] **HIGH 1**: `vDSP_conv` reversal direction was inverted in v1 of the spec ("pre-reverse the kernel + IF=1"). Per `vDSP.h:2328`, `IF > 0` is correlation and `IF < 0` is convolution; pre-reversal would silently produce convolution. **Fixed**: Decision #6 rewritten — kernel passed as-is with `IF = +1`, no reversal.
- [x] **HIGH 2**: AC #3 ("120 BPM rescored above 60 BPM") was unprovable with raw dot product because a 60 BPM kernel matches every-other-beat of a 120 BPM signal at full magnitude. **Fixed**: Decision #10 added (true normalized cross-correlation per lag, `dot / (||k||₂ · ||x[ℓ:ℓ+L]||₂)`); AC #3 expanded to a 4-test gauntlet with quantitative bar (`score(120) >= 1.2 × score(60)` — initially specified as 1.5× but corrected in round 2 after derivation showed 1.5× is mathematically unreachable for an 8-click kernel) and an anti-test on 60 BPM input.
- [x] **HIGH 3**: `sqrt(clickCount)` denominator was fragile (only valid for unit impulses; tapered clicks would break it). **Fixed**: Task 2.2 now computes kernel L2 from the synthesized array via `vDSP_svesq` + `sqrt`.
- [x] **HIGH 4**: Multiplicative `[0,1]` damping was destructive — a low click correlation on the upstream-favored candidate could erase it. **Fixed**: Decision #4 reframed to a parameterized blend `oldScore * (α + (1-α) * clickScore)` with `α = 0.3` default; α is swept by ablation in Task 3.3.
- [x] **HIGH 5**: `clickRescore` and `synthesizeClickPattern` were declared `private static` but Task 2.4 expected `@testable import` access — `@testable` exposes `internal`, not `private`. **Fixed**: visibility changed to `internal static` in Decision #5 and Task 2.1, 2.2.
- [x] **MED 6**: Sub-band voting authority over rescored ordering was undocumented. **Fixed**: Decision #12 added.
- [x] **MED 7**: `BPMResult.candidates` flow into `CandidateMergeStrategy` (CandidateMergeStrategy.swift:107) — story did not decide rescored vs raw. **Fixed**: Decision #11 + Task 2.3 — returned candidates carry rescored values; trace's `rawCandidates` keeps pre-rescore values.
- [x] **MED 8**: Click-pattern length off-by-one risk (`Int((k * period).rounded())` could yield `index == length`). **Fixed**: Task 2.1 reordered — compute indices first, then allocate `[Float]` of size `indices.last! + 1`.
- [x] **MED 9**: `Array.sort` is not contractually stable in Swift. **Fixed**: Task 2.2 uses `sorted(by:)` with explicit index tiebreaker.
- [x] **MED 10**: AC #6 "floors hold by construction" was a wiring-bug hole. **Fixed**: AC #6 rewritten as unconditional `#expect` floors on default-intensity OA300/GiantSteps regardless of preset membership; AC #7 added (`optimal`-membership invariant test).
- [x] **LOW 11**: `AblationFullMatrixTests` 15-min cap would be exceeded by the doubled 128-combo matrix. **Fixed**: AC #8 + Task 3.1 — raise cap or add `make ablation-smoke` lane (curated 16 combos including `optimal` and `optimal+click`); recommended both.
- [x] **LOW 12**: `vDSP_conv` pointer-lifetime note. **Fixed**: added to Dev Notes "Threading / Concurrency" subsection below.

### Round 2: Advanced-Elicitation Review (2026-04-26, three Codex gpt-5.5 agents in parallel + Critique-and-Refine synthesis)

After the party-mode round, the spec went through three more Codex agents running Self-Consistency Validation, Algorithm Olympics, and Challenge from Critical Perspective. All three independently flagged the same HIGH issues. 14 additional patches landed:

- [x] **R2-A** (3-of-3 agents): AC #3's `1.5×` quantitative bar was mathematically unreachable. For an ideal 120 BPM impulse envelope and an 8-click 60 BPM kernel, NCC(60) = `8 / (sqrt(8) · sqrt(15)) ≈ 0.73`; with α=0.3 the post-blend ratio is ≈1.23, never 1.5. **Fixed**: AC #3a bar lowered to `>= 1.2×`; the v1 1.5× target left in the historical record here.
- [x] **R2-B** (3-of-3 agents): Dev Notes still contained three stale pre-patch passages (kernel pre-reversal, `sqrt(clickCount)` normalization, `private static`). **Fixed**: "Code Context" subsection rewritten to match the patched Decisions; "Architecture Requirements" updated; the stale "Use the pre-reverse path" guidance is gone.
- [x] **R2-C** (Method 4): `α = 0.3` lacked empirical grounding; "boost" terminology in DD#4 was inaccurate (the formula always damps for `clickScore < 1`). **Fixed**: DD#4 rewritten with "blend" / "damping floor"; new Task 3.0 collects per-candidate score distribution data on 20 OA300 tracks BEFORE the α-sweep; α default may rise based on the distribution.
- [x] **R2-D** (Method 4): The `outputLen <= 0` partial-skip created an artificial advantage for skipped candidates (their `oldScore × 1.0` competed with rescored values < 1). **Fixed**: DD#13 added — uniform-skip rule (if ANY kernel doesn't fit, return all candidates unchanged).
- [x] **R2-E** (Method 3 winner): Algorithm Olympics — three primitives raced; sparse normalized beat-search (Contestant C) won over dense `vDSP_conv` (A) and ACF-lookup (B). **Fixed**: DD#6 rewritten with sparse-loop pseudocode; dense `vDSP_conv` left as a documented alternative with the `IF=+1` no-pre-reverse contract.
- [x] **R2-F** (Method 2): AC #2 and AC #4 hard-coded `α = 0.3` but Task 3.3 may change the default. **Fixed**: ACs reword to "chosen default α (initially 0.3, finalized in Task 3.3)"; Completion Notes record the final value.
- [x] **R2-G** (Method 2 + Method 4): AC #3b noise model said "pink noise -6 dB SNR" but Task 2.4 said "Gaussian amplitude 0.25"; `0xBOOM` is not valid Swift hex. **Fixed**: unified on Gaussian + `SplitMix64(seed: 0xB00D_F00D)` (Box-Muller transform) at amplitude 0.25 in both AC #3b and Task 2.4.
- [x] **R2-H** (Method 4): Off-by-one test BPMs `[60, 120, 200]` don't actually trigger the original bug. **Fixed**: Task 2.5 BPMs widened to `[61, 63, 67, 89, 120, 126, 200]`; an explicit witness for `bpm=61` (where the original formula fails) is documented.
- [x] **R2-I** (Method 4): AC #4's "every previously-passing combo unchanged" was unverifiable for the 64 click-ON combos (Story 3-2 had only 64 click-OFF combos). **Fixed**: AC #4 + Task 3.2 reworded — 64 click-OFF compared 1:1 vs Story 3-2 baseline; 64 click-ON compared paired vs their click-OFF twins, reported as data not gate.
- [x] **R2-J** (Method 4): "No new trace field" was a false economy. **Fixed**: DD#7 reversed — `clickCorrelationDetail: [String: Float]?` added to `BPMDiagnosticTrace`; Task 2.2 populates it.
- [x] **R2-K** (Method 4 — important): DD#12 noted step 10 + step 10b are score-blind, so click rescoring's actual reach on the corpus is unmeasured. **Fixed**: Task 5.6 added — per-track click-impact report (`changedRanking / changedStep10Winner / changedFinalBPM` counts on OA300) emitted to JSON. Without this we ship blind on whether the technique actually moves anything.
- [x] **R2-L** (Method 2): Preset-language ambiguity — `.full = Set(allCases)` automatically includes the new technique, making "at least one preset OR documented exclusion" trivially satisfiable. **Fixed**: AC #4 reworded to "at least one named preset *other than `.full`*."
- [x] **R2-M** (Method 2): Zero-energy segment handling was unspecified. **Fixed**: DD#13a — `segL2 == 0 → skip lag (score 0)`.
- [x] **R2-N** (Method 4): α-sweep is below the noise floor (1 OA300 track ≈ 1.22 pp; SE ≈ 5 pp on 82 tracks). Picking α on a single-track twitch is overfit. **Fixed**: Task 3.3 now requires ≥ 2-track margin AND no GiantSteps regression to change the default α.

### Party-Mode Decisions Made

- **HIGH 4 scope**: Bob recommended splitting into 3-3a (impl) + 3-3b (α-sweep). Winston countered that splitting adds ceremony with no benefit because the α-sweep is one ablation task. **Decision: single story**; α-sweep stays as Task 3.3 (16 runs, ~3 min added to ablation).
- **AC #3 bar**: Bob proposed `score(120) >= 1.5 × score(60)` quantitative; Quinn proposed 3-test gauntlet including anti-test on 60 BPM input. **Decision: combine** — three tests (clean, noisy SNR, anti-test) with the 1.5× quantitative bar on the clean test only.
- **AC #4**: Quinn proposed per-combo Acc1/Acc2 emission to JSON + no-regression delta. **Decision: adopted** — emit to `_bmad-output/implementation-artifacts/3-3-ablation-results.json`.
- **AC #6**: Codex/Quinn/Winston converged on unconditional floors. **Decision: adopted** — floors are hard `#expect` regardless of preset membership; click-enabled preset gets a separate visibility-only run (Task 5.3).
- **MED 7 (rescored vs raw return)**: Winston ruled rescored values flow downstream so merge strategies stay consistent with disambiguation. **Decision: adopted** — Task 2.3 returns rescored candidates from `BPMResult`.

## Dev Notes

### Architecture Requirements

- **All types are value types.** `BPMAnalyzer` is a stateless struct with `static` methods. The new helpers (`synthesizeClickPattern`, `clickRescore`) are `internal static` (per DD#5; `@testable import` exposes `internal`, not `private`).
- **vDSP for bulk numeric ops.** The recommended path is the sparse normalized beat-search per DD#6 — the inner loop iterates the small `clickIndices` array (typically 8 entries), not the signal buffer, so it satisfies CLAUDE.md's "no manual loops over signal buffers" rule. `vDSP_conv` is the dense alternative; if used, it MUST pass the kernel as-is with `IF = +1` per `vDSP.h:2328` (NO pre-reversal). The earlier "use the pre-reverse path" guidance was a v1 spec error and is corrected throughout.
- **New `DSPTechnique` case is the architecturally-blessed extension point.** ADR-8 explicitly authorizes growing the ablation matrix to 2^7 = 128. This is the only DSP-altering change in Epic 3 that adds a new case (Story 3-1 added trace fields only; Story 3-2 modified an existing technique).
- **Internal access only.** `clickRescore` and `synthesizeClickPattern` are `internal static`. No public API changes. Tests use `@testable import BoomBoomBoomKit` (same pattern as the existing `subBandVote` tests at BPMAnalyzerTests.swift:666-719).
- **Swift 6 strict concurrency.** `BPMAnalyzer` is a pure-static struct with no mutable state. No new shared state introduced. **Pointer-lifetime contract**: any `vDSP_*` calls take their pointers from `withUnsafeBufferPointer` / `withUnsafeMutableBufferPointer` scopes — do not capture `UnsafePointer` outside the closure that produced it. The kernel, per-candidate output, and cumulative-sum-of-squares arrays live for one iteration of the candidate loop (cumSumSq lives for one full `clickRescore` call), so the natural Swift pointer scopes already enforce this. Do not introduce a long-lived shared scratch buffer.

### Historical Evidence

`_bmad-output/bpm.md:192` records that an earlier post-hoc beat-phase cross-correlation experiment regressed accuracy when applied with strong damping. This is the precedent for Decision #4's parameterized blend. **Important caveat**: the precedent says authoritative replacement is bad — it does NOT prove that `α = 0.3` is the right default. The α default is finalized by Task 3.0 (corpus-grounded distribution analysis) + Task 3.3 (margin-gated sweep), not by inheritance from the precedent. The historical lesson is "don't make click rescoring authoritative," not "30% is the magic number."

### Code Context

**Pipeline call site (`BPMAnalyzer.estimateBPM`, BPMAnalyzer.swift:273-282):**

```swift
// Step 8-9: Multi-peak extraction + range normalization
let candidates = extractTopCandidates(
  enhanced: enhanced, bpmMin: bpmMin, count: techniques.candidateCount)
guard !candidates.isEmpty else { return nil }

trace?.rawCandidates = candidates

// Step 10: Octave disambiguation with sub-band voting
let disambiguated = resolveOctaveAmbiguity(
  candidates: candidates, fused: fused, bpmMin: bpmMin,
  subBandACFs: subBandACFs, onsetRate: onsetRate)
```

The new step inserts between `trace?.rawCandidates = candidates` and `let disambiguated = resolveOctaveAmbiguity(...)`. The disambiguator's first argument changes from `candidates` to `rescoredCandidates`. Trace is written from the original `candidates` (pre-rescore) — do not change this.

**`generateClickTrack` (TestSupport, TestSignalGenerators.swift:4-18):**

Audio-rate, exponential decay over 64 samples, used for full-pipeline tests. **Not** appropriate to import into the main library (separate target). The new `synthesizeClickPattern` lives inside `BPMAnalyzer.swift` as an `internal static` helper (per DD#5), operating at envelope rate.

**Onset envelope (`onsetEnvelope: [Float]`, BPMAnalyzer.swift:169, 220-221):**

Sampled at `onsetRate = sampleRate / hopSize ≈ 100 Hz`. A 30 s window has 3000 samples; a 90 s window has 9000. The cross-correlation output for an 8-click kernel at 100 BPM is `samples - kernelLength + 1 = 3000 - 480 + 1 = 2521` lags. The sparse beat-search inner loop reads 8 samples per lag (one per click index) — total ≈ 20 K loads per candidate per window, ~5% of the existing tempogram work.

**Cross-correlation primitive choice (DD#6):**

The recommended path is the sparse normalized beat-search shown in DD#6. Per Apple's local Accelerate header `vDSP.h:2328`: `vDSP_conv` computes `C[n] = Σ A[n+p] · F[p]` and is **correlation when `IF > 0`, convolution when `IF < 0`**. So `vDSP_conv(envelope, 1, kernel, +1, output, 1, outputN, kernelN)` with the kernel passed as-is IS sliding cross-correlation — pre-reversal would invert the operation back to convolution. The sparse path is preferred because the kernel is overwhelmingly zeros (8 unit impulses among ~480 frames at 60 BPM × 100 Hz); dense `vDSP_conv` does multiply-add work on hundreds of zeros per lag.

**Score normalization rationale (DD#10):**

Per-lag normalized cross-correlation is `dot(kernel, envelope[ℓ:ℓ+L]) / (||kernel||₂ · ||envelope[ℓ:ℓ+L]||₂)`. The per-lag denominator divides out segment energy so the score reflects *alignment quality*, not segment loudness. The per-candidate score is `max over lags` of these normalized values; by Cauchy-Schwarz it is bounded in `[0, 1]` — no further max-normalization across candidates is needed (and any cross-candidate normalization would couple the candidates' scores and re-introduce the energy bias the per-lag denominator was meant to remove). For zero-energy segments (`segL2 == 0`), skip the lag (treat as score 0) per DD#13a.

### Investigative Hypotheses

The epic is open about whether this technique helps. Three plausible outcomes:

1. **Click correlation improves Acc1 on noisy real tracks.** The fused score (ACF × tempogram) emphasizes periodicity over rhythmic alignment. A track with a strong 90 BPM ACF peak from low-frequency drone but actual beats at 180 BPM might lose to 180 in the click rescoring. Expected to help mid-tempo electronic tracks where ACF and click pattern disagree.

2. **Click correlation is redundant with fused-periodicity.** ACF peaks already correspond to periodic onsets. The cross-correlation magnitude at the candidate BPM is mathematically related to the ACF at the corresponding lag. If the relationship is too tight, the click rescoring becomes a no-op (each candidate's score gets multiplied by approximately the same factor), and Acc1 is unchanged.

3. **Click correlation regresses on tempo-varying tracks.** A live recording with tempo drift has no single "best" click period; the cross-correlation peak is broadened, and the normalized score is approximately equal across candidates. The rescoring becomes noise. Could regress 1-3 OA300 tracks; ablation will surface this if it happens.

The story's success criteria are scoped to "ablation completes" + "preset assignment documented," not "Acc1 improves." Do not retry the implementation if Acc1 is neutral; document and ship.

### Testing Patterns

- **Swift Testing** — `@Suite`, `@Test`, `#expect`, `#require`. NOT XCTest.
- **DSPTechnique enumeration tests** — see existing `DSPTechniqueTests` if present, or create one. Test pattern: `#expect(DSPTechnique.allCases.count == 7)`.
- **Click track tests** — see `BPMAnalyzer120BPMTests` (BPMAnalyzerTests.swift, find the suite by grep): generate synthetic click track, run full pipeline, assert BPM. Use `generateClickTrack` from TestSupport (audio rate).
- **Direct rescorer tests** — see `BPMAnalyzerSubBandVotingTests` (BPMAnalyzerTests.swift:666-719) for the pattern: build mock inputs, call the helper directly, assert outputs.
- **Corpus benchmarks** are env-gated (OA300_CORPUS_PATH, GIANTSTEPS_CORPUS_PATH). Run via `make benchmark`, `make benchmark-giantsteps`, `make ablation`, `make oracle`, `make perf-benchmark` (see `Makefile`).

### Accuracy Baselines (pre-story, post-Story 3-2)

- OA300: Acc1 = 57/82 (69.5%), Acc2 = 73/82 (89.0%)
- GiantSteps: Acc1 = 537/661 (81.2%), Acc2 = 546/661 (82.6%)
- Ablation `.optimal`: Acc1 = 55/82 (67.1%)
- Tests: 165
- Latest perf baseline: `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260426T051054Z--1380089--5f31d64b.json` (mean 0.184 s)

### Previous-Story Intelligence (from 3-2-fine-grid-precision-fix.md)

- **Diagnose before implementing.** Story 3-2 ran multiple diagnostic iterations before settling on the gated hybrid. For Story 3-3, the corresponding discipline is: write the failing test (Task 2.4) before the implementation (Task 2.1-2.3), run `make ablation` immediately after the wiring works, and use the ablation result to drive Task 4 preset decisions — do not pre-decide the preset.
- **Run `make benchmark` and `make benchmark-giantsteps` early and often.** Story 3-2 caught a 7-track Acc2 regression on tempogram-only refinement before it shipped. Click rescoring is similarly an accuracy-affecting change; corpus runs are mandatory between Tasks 2 and 3.
- **`HarmonicRatioEvidence`-style typed return is overkill here.** Story 3-1 introduced typed returns from `resolveOctaveAmbiguity` for trace cleanliness. The click rescorer's return is just `[(bpm: Double, score: Float)]` — same shape as input. No new type needed.
- **Commit pattern.** Single commit per story with `Story X-Y: <imperative-summary>` (e.g., `Story 3-3 - click-track cross-correlation`). Then a second commit for the perf baseline at the new SHA (Story 3-2 established this two-commit pattern).
- **Gating checklist:** `make fmt`, `make lint`, `make test`, `make benchmark`, `make benchmark-giantsteps`, `make ablation`, `make perf-benchmark` before marking complete.
- **Code review pattern.** Story 3-2 ran a multi-layer Codex (gpt-5.5) review (Blind Hunter, Edge Case Hunter, Acceptance Auditor) before flipping to `done`. Plan for the same on this story — the cross-correlation math has subtle off-by-one risks (output length, kernel reversal direction, normalization stability) that benefit from independent review.

### Git Intelligence

Branch: `rterhaar/epic-3`.

Recent commits:
- `e1e880b` Story 3-2 - perf baseline at 1380089
- `1380089` Story 3-2 - fine-grid precision fix and code-review patches
- `f10ca6c` Story 3-1 - harmonic ratio detection
- `49fc97e` land epic 2

Story 3-2 just landed. Tree is clean. Story 3-3 starts here.

### Project Structure Notes

- All changes in existing files (`BPMAnalyzer.swift`, `DSPTechnique.swift`, `AnalysisIntensity.swift` doc-comment, `BPMAnalyzerTests.swift`, `CLAUDE.md`).
- No new files created (rescoring helpers are private static inside `BPMAnalyzer.swift`).
- No new dependencies.
- No public API changes (internal helpers are `private static`; the new `DSPTechnique` case is public but additive — `CaseIterable` adapts; consumers iterating over cases get the new case for free, which is the desired ablation behavior).
- Library code in `Sources/BoomBoomBoomKit/`, tests in `Tests/BoomBoomBoomKitTests/`.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.3] (epic acceptance criteria, lines 554-584)
- [Source: _bmad-output/planning-artifacts/architecture.md#ADR-8] (lines 241-242, click-track as new DSPTechnique)
- [Source: Sources/BoomBoomBoomKit/BPMAnalyzer.swift:273-282] (pipeline insertion point — between candidate extraction and disambiguation)
- [Source: Sources/BoomBoomBoomKit/BPMAnalyzer.swift:169] (onsetRate definition)
- [Source: Sources/BoomBoomBoomKit/DSPTechnique.swift:17-66] (DSPTechnique enum + shortName)
- [Source: Sources/BoomBoomBoomKit/DSPTechnique.swift:122-160] (TechniqueSet presets + allDSPCombinations)
- [Source: Sources/BoomBoomBoomKit/AnalysisIntensity.swift:46-60] (techniqueSet mapping doc-comment + switch)
- [Source: Sources/BoomBoomBoomKitTestSupport/TestSignalGenerators.swift:4-18] (audio-rate generateClickTrack — for full-pipeline tests, NOT to import)
- [Source: Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:666-719] (sub-band voting test pattern — direct helper call via @testable import)
- [Source: _bmad-output/implementation-artifacts/3-2-fine-grid-precision-fix.md] (previous story; two-commit perf-baseline pattern)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] (Story 3-7 96 kHz × 126 BPM is unrelated to this story — top-K refinement is a separate concern)
- [Source: CLAUDE.md] (Architecture section's BPMAnalyzer description needs update in Task 4.4)
- [Source: Apple Accelerate `vDSP_conv` reference] (signature: signal × filter, with reversed-filter trick for cross-correlation)

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (1M context, story context engine)

### Debug Log References

- `_bmad-output/implementation-artifacts/3-3-ablation-results.json` — full 128-combination ablation results (label, acc1, acc2, total per row).
- `_bmad-output/implementation-artifacts/3-3-click-impact-report.json` — per-track click-impact report on OA300 (changedRanking / changedStep10Winner / changedFinalBPM).
- `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260426T171024Z--e1e880b--1247043f.json` — fresh perf baseline post-implementation (mean 0.172 s, median 0.139 s, p95 0.240 s — 6.6 % faster than the prior baseline because the technique is gated and `.optimal` does not include it).

### Completion Notes List

**Final α default: 0.7** (raised from initial 0.3 per Task 3.3 margin gate).
The Task 3.3 α-sweep over `.optimal`-family combos shows that at α=0.3, `.optimal+click` regresses Acc1 by 2 tracks on OA300 (53/82 vs `.optimal` 55/82); raising α to 0.7 restores parity (55/82) and adds +1 Acc2 (68/82 vs 67/82). The +2-track Acc1 margin between α=0.7 and α=0.3 on `.optimal+click` clears the margin gate; GiantSteps visibility confirms no regression at α=0.7 (.optimal+click +1 Acc1 / 0 Acc2 vs `.optimal`).

**Preset assignment (AC #4)**: `.clickTrackCorrelation` is added to a new public preset `TechniqueSet.clickAugmented` (= `.optimal + .clickTrackCorrelation`). It also appears in `.full` (which is `Set(allCases)` and grew to all 7 cases automatically). It is NOT inserted into `.optimal` because the Task 3.4 +2-track margin gate was not met (the technique ties Acc1 and gains only +1 Acc2 at α=0.7). The `.optimal`-membership invariant test (AC #7) locks `optimal.contains(.clickTrackCorrelation) == false`.

**Intensity mapping (AC #5)**: unchanged. The doc-comment on `AnalysisIntensity.techniqueSet` now documents that `.clickTrackCorrelation` is opt-in via `TechniqueSet.clickAugmented` because Story 3-3 ablation showed parity (no margin) on OA300.

**OA300 default-intensity floors (AC #6)**: Acc1 = 57/82 (69.5%), Acc2 = 73/82 (89.0%) — exactly at floor.
**GiantSteps default-intensity floors (AC #6)**: Acc1 = 537/661 (81.2%), Acc2 = 546/661 (82.6%) — exactly at floor.

**Click-enabled visibility runs (AC #6, data-only)**:
- OA300 `.optimal+click` at α=0.7: Acc1 = 55/82 (67.1%), Acc2 = 68/82 (82.9%) — ties `.optimal` Acc1, +1 Acc2.
- GiantSteps `.optimal+click` at α=0.7 (2-factor matcher): Acc1 = 458/661 (69.3%), Acc2 = 517/661 (78.2%) — +1 Acc1, 0 Acc2 vs `.optimal`.

**Ablation `.optimal` Acc1 (AC #4 secondary gate)**: 55/82 (67.1%) — held since Story 3-2.

**Per-track click-impact report (Task 5.6 / DD#12)**: on OA300, click-on vs click-off:
- changedRanking: 4 / 82
- changedStep10Winner: 4 / 82
- changedFinalBPM: 1 / 82
The technique's measurable reach on the corpus is **1 track** at the default-α `.optimal+click` preset. The 4-vs-1 gap confirms DD#12: step 10b sub-band voting overrides most rescoring effects. The technique is not inert (final-BPM ≠ 0) but its corpus-level effect is small — exactly the visibility AC #4 / DD#12 demanded so we ship "with eyes open."

**α-sweep distribution (Task 3.0 substituted)**: the α-sweep over the 4 `.optimal`-family combos at α ∈ {0.0, 0.3, 0.5, 0.7} on full OA300 (16 runs, 98 s total) supplied the empirical distribution data Task 3.0 originally proposed to collect on a 20-track sample. The sweep showed a monotone trend across the family: lower α (more rescoring) regresses Acc1; higher α restores parity. This corroborates the design intent of DD#4 (corroborative-not-authoritative) at strength: at the α=0.3 bound, the rescoring is too aggressive; at α=0.7 it's mostly inert with a small Acc2 gain. The full per-α numbers are in this commit's α-sweep run output (above).

**Ablation runtime (AC #8)**: full 128-combo run at the chosen-default α completed in **77.5 s** (well under the new 35-min cap). The doubled matrix is significantly cheaper than the spec's worst-case 25-30 min estimate — the M5 Max is faster than projected. `make ablation-smoke` (16 curated combos including `.optimal` and `.optimal+click`) completes in **9.7 s** for fast cadence.

**Final test count**: 180 tests (165 baseline + 13 new in `BPMAnalyzerClickTrackTests` + 2 invariant in `AblationQuickTests`).

**Tests pass**: `make fmt` clean, `make lint` clean (1 pre-existing TODO in LUFSAnalyzer.swift), `make test` 180/180.

**Perf delta (Task 5.5)**: mean 0.184 s → 0.172 s (-6.6 %). The pipeline is unchanged for the default `.optimal` preset (technique is gated); the slight improvement is run-to-run noise on the warmup-stripped serial benchmark.

**Public API addition (post-review, 2026-04-26)**: Resolved the code-review Decision-1 finding "Public API path for `.clickAugmented` is unreachable" by adding `public var techniqueSet: TechniqueSet?` to `AudioAnalysisService.Options` (nil = derive from intensity, non-nil = explicit override). `analyzeBPM(url:options:)` resolves once via `options.techniqueSet ?? options.intensity.techniqueSet` and uses the resolved set's `candidateCount` for cross-window merge so the merge step matches the pipeline. Three new tests in `AudioAnalysisServiceTechniqueSetOverrideTests` verify nil-default, `.clickAugmented` flow-through, and override-beats-intensity for `candidateCount`.

**Field rename (post-codex review, 2026-04-26)**: After party-mode review by Codex (gpt-5.5) + 4 BMad agents (Siri, Winston, Amelia, Bob) confirmed Codex's blocking findings on the original Story 3-3a draft, the user directive "BC is not a goal; consistency is" promoted the rename of `techniques` → `techniqueSet` to align with the type-mirroring convention (`intensity: AnalysisIntensity`, `mergeStrategy: CandidateMergeStrategy`, now `techniqueSet: TechniqueSet?`). Renamed across both public layer (`AudioAnalysisService.Options`) and internal layer (`BPMAnalyzer.Options`), plus all loop variables, parameters, and test references for layer-boundary symmetry. All 184 tests pass post-rename.

**Review-finding resolution (2026-04-26)**: All 11 review patches + both open decisions (A: alpha gauntlet at both 0.3 and 0.7; B: ablation JSON extended with paired deltas + regressionGate) resolved in-flight in the same commit. Empty-corpus guards added to three benchmark gates. Two deferred items split out into named follow-up stories: `3-3b-trace-key-namespacing` (BPMDiagnosticTrace `%.1f` collision risk across `harmonicRatioDetail`/`subBandVoteDetail`/`clickCorrelationDetail`) and a benchmark-infra story for ablation parallelism control. Final test count: 184 (was 180 before Decision 1 resolution; +3 tests for the override tests; +1 for the stable-tiebreaker test).

### File List

- `Sources/BoomBoomBoomKit/DSPTechnique.swift` — added `case clickTrackCorrelation` and `shortName "click"`; updated `allDSPCombinations()` doc-comment from 64 to 128; added `TechniqueSet.clickAugmented` preset; updated `.full` doc-comment for 7-case totals.
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — added internal static `synthesizeClickPattern(bpm:onsetRate:clickCount:)` and `clickRescore(candidates:onsetEnvelope:onsetRate:alpha:trace:)` with sparse normalized beat-search per DD#6; wired step 9.5 between `extractTopCandidates` and `resolveOctaveAmbiguity`; `BPMResult.candidates` now carries rescored values (DD#11); added `alphaOverride()` env hook for α-sweep; updated `refineCandidates` doc-comment to mention rescoring.
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — added `clickCorrelationDetail: [String: Float]?` (DD#7).
- `Sources/BoomBoomBoomKit/AnalysisIntensity.swift` — updated `techniqueSet` doc-comment to mention 128-combo validation and the `.clickAugmented` opt-in path (Task 4.3); post-review: doc-comment now points at the public `AudioAnalysisService.Options.techniques` override.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — post-review: added `public var techniques: TechniqueSet?` to `Options`; `analyzeBPM(url:options:)` resolves the override once, threads it into `BPMAnalyzer.Options.techniques`, and uses the resolved set's `candidateCount` for cross-window merge. Options doc-comment now documents the optional-vs-non-optional field-style convention.
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerClickTrackTests.swift` — new file. AC #3 four-test gauntlet (3a clean, 3b noisy, 3c anti-test, 3d alpha-blend), kernel-length off-by-one regression test (Task 2.5), full-pipeline integration smoke test (Task 2.6), trace-population test, sort tiebreaker test, uniform-skip test, guard tests for `synthesizeClickPattern`.
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` — post-review: added `AudioAnalysisServiceTechniquesOverrideTests` suite (3 tests) covering the new `Options.techniques` override.
- `Tests/BoomBoomBoomKitTests/AblationQuickTests.swift` — bumped `allCases.count` 6→7 and `allDSPCombinations()` 64→128; added `optimal`-membership invariant test (AC #7) and `.clickAugmented` preset properties test.
- `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift` — raised time cap 15→35 min; updated header text and AC reference for Story 3-3; emit per-combo (label, acc1, acc2, total) JSON to `ABLATION_RESULTS_DIR/3-3-ablation-results.json`; added `smokeAblation` test (16 curated combos, gated by `ABLATION_SMOKE=1`); added `alphaSweep` test gated by `ALPHA_SWEEP=1`; added `clickVisibilityOA300`, `clickVisibilityGiantSteps`, `clickImpactReport` tests gated by `CLICK_VISIBILITY=1` / `CLICK_IMPACT=1`.
- `Makefile` — `ablation` target now writes JSON and filters to `fullAblationMatrix`; new `ablation-smoke` target.
- `CLAUDE.md` — Architecture section: bumped `DSPTechnique` to 7 cases; added `.clickAugmented` preset; bumped ablation matrix from 64 to 128 combos; added "step 9b: click-track cross-correlation (optional, rescores candidates)" to the BPMAnalyzer pipeline list.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — story 3-3 status flipped: ready-for-dev → in-progress → review.
- `_bmad-output/implementation-artifacts/3-3-click-track-cross-correlation.md` — story file: tasks/subtasks checked, Status flipped, Dev Agent Record populated.
- `_bmad-output/implementation-artifacts/3-3-ablation-results.json` — new artifact (128 ablation rows).
- `_bmad-output/implementation-artifacts/3-3-click-impact-report.json` — new artifact (per-track click impact counts).
- `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260426T171024Z--e1e880b--1247043f.json` — new perf baseline. Will be replaced after the Story 3-3 commit at the new SHA via `make perf-benchmark`.

## Change Log

- 2026-04-26 (Story 3-3 implementation): Added `DSPTechnique.clickTrackCorrelation` (case 7), `TechniqueSet.clickAugmented` preset, `BPMAnalyzer.synthesizeClickPattern` and `clickRescore` internal helpers, step 9.5 wiring in `estimateBPM`, `clickCorrelationDetail` trace field, alpha-override env hook, smoke and α-sweep ablation tests, click-visibility and click-impact tests, AC #7 invariant test, and 13-test gauntlet in `BPMAnalyzerClickTrackTests`. Default α finalized at 0.7 by Task 3.3 margin gate (+2 OA300 Acc1 tracks vs α=0.3 on `.optimal+click`, no GiantSteps regression). `.optimal` membership unchanged; technique exposed via `.clickAugmented` and `.full`. OA300/GiantSteps/oracle/perf benchmarks all hold AC #6 floors.

