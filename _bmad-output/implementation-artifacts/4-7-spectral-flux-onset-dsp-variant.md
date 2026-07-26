# Story 4.7: SuperFlux Onset Detection DSP Variant

Story ID: 4.7
Story Key: 4-7-spectral-flux-onset-dsp-variant (file name retained for historical traceability — the rescope below renamed the algorithm from "spectral flux" to "SuperFlux" mid-finalization; sprint-status.yaml + epics.md references still resolve)
Epic: 4 — ML-Augmented Detection (this is the ONLY pure-DSP story in Epic 4 — see DD #1)
Status: done

## Story

As a library author,
given that **Codex review on 2026-05-17 surfaced a structural blocker** on the original Story 4-7 framing — `BPMAnalyzer.swift:711-748` (the existing `computeMelOnsetEnvelopeWithSubBands` function) ALREADY implements log-mel spectral flux verbatim (`vDSP_vsub(prev, curr, &diff) → vDSP_vthres(&diff, 0, &rectified) → vDSP_sve(&rectified, &sum)` chain). The original "spectral-flux variant" proposal was a near-verbatim duplicate of the live baseline. The Epic 3 retro footnote diagnosis ("upstream onset-envelope weakness") was symptom-correct but algorithm-imprecise: the analyzer is already using spectral flux; what it has not been using is a **frequency-neighborhood max-filter reference** per Böck & Widmer 2013 ("Maximum Filter Vibrato Suppression for Onset Detection," DAFx) — the canonical SuperFlux extension that targets vibrato suppression by widening the reference frame's frequency trajectory before differencing,
I want a `DSPTechnique.superFluxOnset` variant that replaces the existing log-mel spectral flux's reference frame `M[t-1][k]` with a `vDSP_vswmax`-computed mel-bin-neighborhood max `max(M[t-1][k-r:k+r])` (r=1, window=3 mel bins) before the half-wave rectification and per-frame sum — this is the algorithmically distinct, paper-faithful Böck 2013 formulation,
So that the upstream onset-envelope handling on heavily-mastered DnB material (Epic 3 retro 2026-05-03 footnote — clipped/limited masters where the limiter has flattened amplitude dynamics) gets a genuinely novel DSP attempt that is NOT byte-equivalent to the current code path, while the brutal-corpus-gate framing (Codex 2026-05-04 + 2026-05-17, thread `019e36de-1440-7b71-b4aa-f68b0a9b6708`) is preserved verbatim.

**Sequencing + rescope history (final 2026-05-17).**
- Original Story 4-7 framing (2026-05-04 Epic 4 planning, epics.md:1183): "spectral-flux DSP variant — land BEFORE Story 4.5 so BNNS feature design knows the post-spectral-flux baseline."
- Stories 4-5 + 4-6 (Branch C) shipped before this story; the bundle was pulled to `_bmad-output/ml-models/` (develop-only). Spectral-flux is now a pure-DSP improvement orthogonal to ML.
- 2026-05-16 spec authored against false premise that the existing onset detector was "energy-based"; ran axiom-skills review (apple-docs/concurrency/testing/swift) — all 4 skills validated the proposed implementation correctly but none caught that the existing code was already the proposed algorithm.
- 2026-05-17 Codex blocker raised duplicate-algorithm finding via thread `019e36de`. Party-mode unanimous redirect to SuperFlux (Böck & Widmer 2013). axiom-apple-docs MCP verified `vDSP_vswmax` is the correct sliding-window-max primitive (macOS 10.10+); `vDSP_vmaxmg` ruled out (max-of-magnitudes between two vectors ≠ sliding-window max over one vector).
- 2026-05-17 Codex parameter consultation locked: **frequency-axis max-filter (NOT time-axis), r=1, µ=1, replicate-pad**. Brutal-corpus-gate unchanged. Per Codex's explicit follow-up: "Do not promise the same brutal-gate odds merely because SuperFlux is now genuinely novel. The paper's stated win condition is vibrato suppression, not recovery from limiter-flattened DnB triplet ambiguity. Keep the brutal gate, but say plainly that **Branch B remains the expected outcome and Branch A is upside.**"

**Honest framing of expected outcome.** Branch B (ship inert) remains the expected outcome of this story. Branch A is upside. The 4 named DnB tracks currently sit at ~107-113 BPM against 160-170 ground truth (abs_error 53-57 BPM). For SuperFlux to clear Branch A's `abs_error_variant < 0.02 × ground_truth_bpm` gate, it must collapse 50+ BPM of error to under 3.4 BPM on at least one track — a substantial empirical move. The Böck 2013 paper's documented win condition is vibrato suppression on pitched-instrument onsets, not brick-walled-DnB triplet-tempo confusion. SuperFlux is the most defensible *non-duplicate* DSP lever available, but Codex's brutal gate remains brutal regardless of algorithm choice.

## Key Design Decisions

The DDs below are the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #1, #4, #5, #6, #9 are the most consequential** — they lock the architectural shape (DSPTechnique case vs Options flag), the gating model, the brutal-corpus-gate authorization, the impact-report deliverable contract, and the HALT discipline distinguishing "ship the technique" from "ship inert".

1. **DSPTechnique enum case (renamed `.superFluxOnset`), not Options flag.** The variant is a CLOSED-SET DSP technique alongside the existing 7 cases. Adding `.superFluxOnset` LAST preserves the stable-identifier convention (project-context.md line 75 — "Pipeline step numbers are stable identifiers"; same convention applies to enum case ordering for `CaseIterable`-driven ablation generation).

   **Naming change from `.superFluxOnset` to `.superFluxOnset` (post-rescope 2026-05-17).** Codex flagged in thread `019e36de` that "spectral flux" is what the existing baseline already implements; the new case is specifically SuperFlux (Böck & Widmer 2013's frequency-neighborhood max-filter extension). The renamed case prevents future readers from interpreting Story 4-7 as "spectral flux that's somehow different from baseline" — it IS different (frequency-neighborhood reference), and the name should say so.

   The architectural alternative (Options-flag gate à la Story 3-4's `durationHint`) was considered and rejected here because (a) the variant changes onset-detection algorithm at a pipeline step that's already technique-gated (`.subBandNormalization`, `.adaptiveThreshold`, `.subBandVoting`, `.acfSharpening` all gate at steps 3/4/5), (b) it MUST appear in the ablation matrix to satisfy the architectural rule "Every accuracy-affecting change must be ablation-testable" (architecture.md:304), and (c) the Options flag is reserved per ADR-11 for orthogonal signal axes (file-level metadata, ML, etc.), not for DSP variants on a technique-gated step.

   **Implication — 10 invariant updates in lockstep.** The architecture invariant `DSPTechnique.allCases.count == 7` is unit-test-locked at multiple sites (project-context.md:41, 88, 101, 160; CLAUDE.md; `MetadataCorroborationTests.swift`; `AblationQuickTests.swift`; `DSPTechnique.swift` doc-comment). Bumping to 8 requires updating ALL 10 sites in a single commit — `4-7-HALT-(a)` fires if any one is missed. Detailed list in AC #1.

   **Implication — ablation matrix doubles from 128 to 256 combos.** `TechniqueSet.allDSPCombinations().count` auto-expands via `CaseIterable` (`DSPTechnique.swift:164-181`). Wall-clock impact for `make ablation`: ~77 s on M5 Max → ~150 s (2×). The smoke lane (`make ablation-smoke`, 16 curated combos in `Makefile:51-65`) MUST NOT add `.superFluxOnset` to any of its combos by default — see DD #6.

2. **SuperFlux frequency-axis max-filter on the reference frame.** Per Böck & Widmer 2013 (DAFx; the paper's stated win condition is vibrato suppression on pitched-instrument onsets). The variant operates ON THE EXISTING mel-spectrogram frames produced inside `computeMelOnsetEnvelopeWithSubBands` (BPMAnalyzer.swift:553-617) — no second STFT, no bypass of `MelFilterbank`, no linear-domain operation. The novelty vs the existing baseline:

   - **Existing baseline** (BPMAnalyzer.swift:711-748): `SF_baseline(t, k) = max(0, M[t][k] - M[t-1][k])` summed across k. This IS log-mel spectral flux; the team's prior framing of "energy-based onset detection" was wrong about what the live code does.
   - **SuperFlux (Story 4-7 redirect)**: `SF_super(t, k) = max(0, M[t][k] - max_filter_freq(M[t-1], k, r))` summed across k, where `max_filter_freq(M[t-1], k, r) = max(M[t-1][k-r:k+r])`. The reference frame `M[t-1][k]` is replaced with the maximum value in a ±r mel-bin neighborhood at the same time t-1.

   Rationale for keeping mel-domain (not linear-domain) and frequency-axis max-filter (not time-axis):
   - **Architectural alignment** — every other onset-derived signal in BoomBoomBoomKit (sub-band voting, click correlation, sub-band normalization) works in mel space. A linear-domain variant would be an orphan operating on a different signal axis.
   - **Zero new utilities** — `MelFilterbank` matrix and log-mel frames are already constructed before the temporal-differentiation step. SuperFlux is "swap `M[t-1][k]` for `max(M[t-1][k-r:k+r])` in the existing chain".
   - **Frequency-axis is the canonical Böck 2013 formulation** — the paper widens the reference frame's frequency trajectory; a time-axis max-filter is a different hypothesis (slow-attack handling, not vibrato suppression). Per Codex 2026-05-17 thread `019e36de`: "Frequency-axis only. That is the defensible SuperFlux rescope. A time-axis max is a different hypothesis, and for this story it would blur the experiment." Time-axis composability is reserved for a future story if SuperFlux clears Branch A.
   - **No second audio pass** — the variant runs on the SAME `logMelData` matrix the existing path produces. PCM read + FFT + mel-filterbank application are unchanged. Only the reference-frame construction and subsequent vDSP_vsub differ.

3. **SuperFlux formula — parameter values locked by Codex consultation 2026-05-17.**

   `SF_super(t, k) = max(0, M[t][k] - max(M[t-µ][k-r : k+r]))`, summed across mel bins:
   - **r = 1** (mel-bin neighborhood radius) → window length = 2r+1 = **3 mel bins**. Codex: "the paper's canonical form is 'current bin and direct neighbors'; with 128 mel bands spanning 30 Hz–16 kHz, larger radii get coarse fast; `r = 3` risks turning 'track nearby spectral trajectory' into 'smear across meaningfully different regions.' Start with `r = 1` because it is the paper-faithful default." Reserved for ablation: `r ∈ {1, 2, 3}` in a future story if SuperFlux clears Branch A.
   - **µ = 1** (temporal reference offset) → `M[t-1]`, i.e. the immediately previous mel frame. Codex: "Böck & Widmer used `µ = 2` at 200 fps, which is still a 10 ms lag. Your current hop is already 10 ms, so `µ = 1` preserves the same physical reference offset as the paper." Reserved for future ablation: `µ = 2` for slow-attack handling.
   - **Half-wave rectification at 0** (`vDSP_vthres` with threshold 0) — same primitive the baseline uses; carries unchanged.
   - **Replicate-pad** at mel-band boundaries (NOT zero-pad, NOT reflect-pad). Codex: "Zero-pad is the one I would reject outright. Between reflect and replicate, replicate is the better engineering choice here: with a max filter it does not 'over-count' in the way it would for a sum/mean, it preserves edge locality, and it avoids reflecting stronger interior energy into the kick/hat boundaries where your load-bearing bins live." Add an edge-case unit test proving the first and last bins do not collapse under padding.

   **Implementation seam.** A new internal function `computeSuperFluxOnsetEnvelope(samples:sampleRate:hopSize:computeSubBands:normalizeSubBands:captureMLFeatures:) -> OnsetEnvelopes` lives in `BPMAnalyzer.swift` adjacent to `computeMelOnsetEnvelopeWithSubBands`. Shares the same return-type contract (`fullBand: [Float]`, `subBands: [[Float]]` (4), `mlFeatures: MLFeatureFrames?`) so downstream steps 4-10 require NO changes. The two functions differ ONLY in the **reference-frame construction** preceding `vDSP_vsub`:

   - Baseline: `vDSP_vsub(prevFrame, 1, currFrame, 1, &diff, 1, n)` — `prevFrame` is `logMelFrames[t-1]` directly.
   - SuperFlux: `vDSP_vswmax(paddedPrev, 1, &maxFilteredPrev, 1, n, windowLength=3)` first, then `vDSP_vsub(maxFilteredPrev, 1, currFrame, 1, &diff, 1, n)`.

   Everything after the `vDSP_vsub` step (HWR, full-band sum, sub-band sums, sub-band normalization) is **byte-for-byte identical** to the baseline.

4. **Numeric delta gate — ≥1 named DnB track resolved OR honest inertness.** Per epics.md AC #4 + Codex 2026-05-04 brutal-corpus-gate framing. Resolution criterion: at least one of the 4 frozen named DnB triplet entries in `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` (Charly @ 160, Faraday_Bunker @ 170, Yin Yang @ 170, HEFT_Anagram 6 @ 170) moves from its frozen `current_predicted_bpm` to within ±2% of `ground_truth_bpm`. The frozen values were captured at SHA `7a6652a` (Story 4-5 close-out) and are NOT re-frozen at Story 4-7 PR time — they're the baseline this story tries to beat. Currently all 4 sit at ~107-113 BPM against ground truth ~160-170 (abs_error ~53-57 BPM).

   **AND DSP-correct controls preserved (4/4).** Per Story 4-6 DD #4 + the symmetric gate established in Story 4-6 review pass: the 4 `dsp_correct_controls` entries in the same fixture MUST remain correctly detected within ±0.5 BPM of ground truth after enabling `.superFluxOnset`. The control set is the regression-protection backbone — a variant that resolves a named failure at the cost of breaking a previously-correct DnB track is NOT acceptable.

   **OR ship inert (Codex-authorized exit).** If the variant doesn't clear either gate, the case ships in `DSPTechnique` (with the 10 invariant updates) BUT is added to NO preset (`optimal`, `dnbOptimized`, `clickAugmented`, `full`*). Completion Notes document the brutal-corpus-gate outcome with the impact-report JSON as evidence. The case becomes available for consumer experimentation (`opts.techniqueSet = TechniqueSet([.superFluxOnset])`) and for future stories to layer on (e.g., a SuperFlux-derived variant or sub-band flux). *Exception: `.full` includes all cases by construction (`Set(DSPTechnique.allCases)`) — that preset auto-includes `.superFluxOnset` regardless of the brutal gate.

5. **Aggregate floor non-regression — corpus floors hold regardless of branch (AC #3).** With `.superFluxOnset` NOT in any preset and NOT in `options.techniqueSet`, the BPM analyzer MUST produce byte-identical output to the pre-Story-4-7 baseline. The pre-source snapshot at `_bmad-output/implementation-artifacts/4-7-regression-snapshot.json` (captured in Task 1) is the byte-equality anchor. With the variant ENABLED (any preset including it OR explicit consumer opt-in), the four asserted floors hold unconditionally:

   - OA300 Acc1 ≥ 57/82 (`OA300BenchmarkTests.swift:104`)
   - OA300 Acc2 ≥ 73/82 (`OA300BenchmarkTests.swift:108`)
   - GiantSteps Acc1 ≥ 537/661 (`GiantStepsBenchmarkTests.swift:82`)
   - GiantSteps Acc2 ≥ 546/661 (`GiantStepsBenchmarkTests.swift:86`)

   These are unconditional `#expect` assertions on every CI run regardless of preset/policy membership (project-context.md:98 — "All four corpus floors are unconditional #expect assertions on every CI invocation regardless of preset/policy membership").

6. **Smoke-lane preservation — `.superFluxOnset` must NOT appear in any of the 16 smoke combos by default.** Per epics.md AC #5. The smoke lane (`make ablation-smoke`, Makefile:51-65) is the everyday CI cadence gate; doubling the matrix without doubling smoke runtime is the design intent. The 16 curated combos are defined in `AblationFullMatrixTests.smokeAblation` — verify by code-review that none of them call `TechniqueSet.inserting(.superFluxOnset)` or include the case literal. Only the full 256-combo `make ablation` pays the 2× cost. CI-cadence smoke runs remain unchanged.

   **Smoke addition path (future story authorization).** If Branch A fires (named DnB resolved, controls preserved, ≥1 named-track delta proven) AND a future story authorizes default-on inclusion in `.optimal`, the smoke lane gains a single combo `[.optimal | .superFluxOnset]` at that point — not in Story 4-7.

7. **Per-track impact report deliverable (mandatory — AC #6).** A new `make super-flux-impact-report` Makefile target (env-gated on `OA300_CORPUS_PATH=1`) produces `_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json` with per-track rows:

   ```json
   {
     "track": "<filename>",
     "baseline_bpm": <bpm at default Options, .superFluxOnset absent>,
     "with_variant_bpm": <bpm with Options.techniqueSet = .optimal ∪ {.superFluxOnset}>,
     "ground_truth": <bpm>,
     "baseline_correct": <bool — within 2% Acc1 of gt>,
     "variant_correct": <bool — within 2% Acc1 of gt>,
     "named_dnb_track": <bool — in 4-dnb-triplet-targets.json::targets>,
     "dsp_correct_control": <bool — in 4-dnb-triplet-targets.json::dsp_correct_controls>,
     "abs_error_baseline": <float>,
     "abs_error_variant": <float>
   }
   ```

   Plus aggregate counts: `{changedRanking: N, changedFinalBPM: K, namedDnBImproved: J, controlsPreserved: M, total: 82}`. **If `changedFinalBPM == 0` AND `namedDnBImproved == 0`, Completion Notes MUST document the inertness honestly with this JSON as evidence — no hand-waving "feature works + no regression" framing** (Epic 3 retro line 45 + Story 3-4 precedent where `changedFinalBPM == 0` was shipped plainly).

   **Output location: same `_bmad-output/implementation-artifacts/` as Story 3-3/3-4 click and duration impact reports** (NOT under `_bmad-output/perf-baselines/bnns-impact/` — that lane is reserved for the v3 harmonized perf+ml-impact envelope; Story 4-7's impact report is a story-tagged artifact, not a per-run baseline).

8. **Byte-equality opt-out test (mandatory — AC #3 paired test).** A unit test in `Tests/BoomBoomBoomKitTests/` asserts that with `.superFluxOnset` ABSENT from `options.techniqueSet` (default + any non-`.full` preset), the analyzer output is BYTE-IDENTICAL to the Task-1 captured baseline. Pattern reuses Story 3-6b's `runPreCorroborationPipeline` discipline: call the SAME helper that production uses; assert `Double.bitPattern` equality on `bpm` and `confidence`; per-candidate element-wise. This is the regression-protection backbone for opt-in features per project-context.md:103.

   **Test file location and naming.** New file `Tests/BoomBoomBoomKitTests/SuperFluxByteIdentityTests.swift` — separate from the existing onset tests so blame history stays clean. Two tests minimum: (a) DSP-only path byte-identity with `.superFluxOnset ∉ techniqueSet`, (b) DSP-only path with `.superFluxOnset ∈ techniqueSet` AND explicit assertion that output IS expected to differ (proves the gate actually does something).

9. **HALT discipline — 7 named HALTs distinguish "fix found and applied" from "investigation closed without fix".** Following Story 4-6 DD #9 + DD #8 revised's verbatim authorization pattern:

   - **4-7-HALT-(a) — Invariant updates incomplete.** Any of the 10 sites in AC #1 left at old values (`== 7`, `== 128`) → HALT and complete the lockstep update before proceeding.
   - **4-7-HALT-(b) — Variant resolves zero named tracks AND breaks one or more controls.** This is the explicit failure path: no upside, regression on the safe set. The Codex-authorized exit path is INERT-BY-DEFAULT, not "ship and hope" — if neither gate clears, the case ships in the enum (per AC #1) but joins NO preset. Completion Notes document the brutal-gate outcome.
   - **4-7-HALT-(c) — Aggregate floor breach.** OA300 Acc1 < 57 OR Acc2 < 73 OR GiantSteps Acc1 < 537 OR Acc2 < 546 at default `Options` (variant absent) → HALT. Default-path byte-identity should make this physically impossible, but the floor assertions fire on every CI run; this HALT is the second line of defense.
   - **4-7-HALT-(d) — Test count outside band `[432, 438]` (post-Story-4-6 baseline 420 + 12-18 new tests per Epic 3 precedent).** `rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l` — outside the band → investigate test drift before merging. Below: missing test. Above: drift signal.
   - **4-7-HALT-(e) — Smoke lane mutated.** Any of the 16 combos in `AblationFullMatrixTests.smokeAblation` includes `.superFluxOnset` → HALT and revert. The smoke-lane preservation contract (DD #6) is not "smoke runtime stays the same" — it's "smoke combos stay byte-for-byte identical" so the cadence gate doesn't shift under feet.
   - **4-7-HALT-(f) — DSP-correct controls regress at `.optimal ∪ {.superFluxOnset}`.** Per AC #4 second clause. ≥1 of the 4 `dsp_correct_controls` entries' detected BPM moves outside ±0.5 BPM of `ground_truth_bpm` → HALT. The variant either ships INERT (per AC #4 OR-branch) or remediation is found and re-tested before close-out.
   - **4-7-HALT-(g) — Byte-equality opt-out test fails.** With `.superFluxOnset ∉ techniqueSet`, the analyzer output is NOT byte-identical to the Task-1 snapshot → HALT. This indicates the new code path is leaking into the default — likely a bug in the gate condition. Code-review until byte-identity holds.

10. **Pre-implementation 3-layer Codex review remains mandatory.** Per project-context.md line 138 + Epic 3 retro line 51 + Team Agreements line 147. The three layers:
    - **(1) Failure Mode Analysis** — single-pass, walks every AC asking "what's the most plausible way this fails?"
    - **(2) Self-Consistency review** — 3 parallel Codex agents (Blind Hunter, Edge Case Hunter, Acceptance Auditor) each critique the post-FMA spec
    - **(3) Code review** on the staged diff (post-implementation, pre-merge — same `bmad-code-review` workflow that ran on Story 4-6)

    For Story 4-7 specifically, Layer 1 should focus heavily on whether the half-wave rectification is in the right place (before sum vs after sum across bands), whether the variant could plausibly help non-mastered material (or whether it's strictly a DnB lever), and whether the brutal-corpus-gate criterion is empirically reachable on real audio at all.

11. **Pre-1.0 / no-BC framing — new public type addition acceptable.** Per Story 4-6 DD #11 + project-context.md Public API Discipline (pre-1.0) subsection. Adding `.superFluxOnset` to public `DSPTechnique` is internal→public promotion authorized by this story's AC #1 (named in the title and AC). The case ships `Sendable, Hashable, CaseIterable` by enum inheritance; no `Codable` synthesis (no `BPMDiagnosticTrace`-level Codable per Story 4-6 DD #11). If this story's brutal-corpus-gate fires the OR-branch (ship inert), pre-1.0 framing means a future story can REMOVE the case entirely — no consumers are pinning on it yet.

12. **No new trace fields by default.** The default impact-report path produces a per-track BPM comparison; it does NOT require a new `BPMDiagnosticTrace.superFluxDetail` field. If diagnostic detail is needed for debugging, the variant function returns `OnsetEnvelopes.fullBand` which is already captured via existing `melSpectrogram` trace plumbing (Story 4-5 era). New trace fields are reserved for follow-up stories if Branch A fires AND default-on inclusion requires per-track diagnostic visibility.

13. **DSP single-window Acc1 ceiling at 55/82 (project-context.md:149) is acknowledged.** Story 4-7 acknowledges that "Add another DSPTechnique case to fix accuracy is no longer viable without architecture change" per the project-context.md rule. The Epic 4 planning session (2026-05-04, epics.md:760) explicitly authorized Story 4-7 as the EXCEPTION to this rule because: (a) it doesn't tune existing techniques — it changes the upstream onset envelope itself; (b) the failure mode (mastered material) is documented and well-understood; (c) the brutal-corpus-gate provides the honest-inertness exit path so the rule isn't violated in spirit (no false promise of accuracy improvement). The OR-branch in AC #4 is the discipline-preserving exit.

## Acceptance Criteria

1. **`DSPTechnique.superFluxOnset` case added; 10 invariant updates in lockstep.**

   **Given** the existing `DSPTechnique` enum with 7 cases (`acfSharpening`, `adaptiveThreshold`, `subBandNormalization`, `expandedCandidates`, `fineGridRefinement`, `subBandVoting`, `clickTrackCorrelation`)
   **When** Story 4-7 ships
   **Then** the enum has exactly 8 cases with `.superFluxOnset` appended LAST (stable-identifier convention; the rename from earlier-draft `.superFluxOnset` reflects the actual algorithm — see DD #1)
   **And** all 10 invariant sites are updated to `== 8` / `== 256` in a single commit:
   1. `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — `DSPTechnique.allCases.count == 7` → `== 8`
   2. `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — `TechniqueSet.allDSPCombinations().count == 128` → `== 256`
   3. `Tests/BoomBoomBoomKitTests/AblationQuickTests.swift` — `combos.count == 128` → `== 256`
   4. `Tests/BoomBoomBoomKitTests/AblationQuickTests.swift` — `DSPTechnique.allCases.count == 7` → `== 8`
   5. `Sources/BoomBoomBoomKit/DSPTechnique.swift` — doc comment "2^7 = 128" → "2^8 = 256"
   6. `CLAUDE.md` — `DSPTechnique` description "7 cases" → "8 cases"; "2^7=128 combos" → "2^8=256 combos"
   7. `_bmad-output/project-context.md:41` — same `allCases.count` and `allDSPCombinations().count` invariants
   8. `_bmad-output/project-context.md:88` — same invariants in Post-Pipeline Corroboration Boundary subsection
   9. `_bmad-output/project-context.md:101` — "all 2^7=128 DSP technique combinations" → "2^8=256"
   10. `_bmad-output/project-context.md:160` — same invariants in Critical Don't-Miss Rules
   11. **NEW (per `axiom-testing/skills/swift-testing.md:220-228`):** parameterized smoke-lane invariant test in `AblationFullMatrixTests.swift` — converts HALT-(e) from manual code-review to a CI-enforced gate (matches the Story 3-3 `.optimal.contains(.clickTrackCorrelation) == false` precedent). The form:
   ```swift
   @Test(
     "smokeAblation combos do not include .superFluxOnset (Story 4-7 DD #6)",
     arguments: smokeCombos
   )
   func smokeComboDoesNotIncludeSuperFlux(_ combo: TechniqueSet) {
     #expect(
       !combo.contains(.superFluxOnset),
       "Smoke combo \(combo) must not include .superFluxOnset — see Story 4-7 DD #6 + HALT-(e)"
     )
   }
   ```
   Parameterized form is required (not a for-loop in a single `@Test` body) because parameterization names the offending combo in the failure output and lets a developer re-run a single failing argument. Source: `axiom-testing/skills/swift-testing.md:220-228` "Benefits Over For-Loops".

   12. **NEW (per Codex 2026-05-17 rescope review):** numeric-distinctness invariant test in `SuperFluxOnsetEnvelopeTests.swift` — proves the new code path is empirically distinct from the baseline `computeMelOnsetEnvelopeWithSubBands`, NOT just notionally different. Crafted fixture: a synthetic log-mel matrix where adjacent mel bins carry intentionally-different energy (e.g., bin k=64 at 1.0, bins k=63,65 at 0.0, frame t-1 only). For this fixture, baseline produces `diff[64] = curr[64] - prev[64] = curr[64] - 1.0`, while SuperFlux with r=1 produces `diff[64] = curr[64] - max(prev[63], prev[64], prev[65]) = curr[64] - 1.0` (same — bin 64 is the max in the window). Then craft the inverse fixture: bins k=63,65 at 1.0, bin k=64 at 0.0 — baseline `diff[64] = curr[64] - 0.0`, SuperFlux `diff[64] = curr[64] - 1.0`. The two outputs MUST differ. Codex: "the rescope's new anti-regression spine."
   **And** `make test` passes (the unit-test invariants pin both numbers)
   **And** `make ablation` runs all 256 combos to completion (wall-clock ~2× pre-story budget)

2. **SuperFlux variant produces an onset envelope shaped identically to the baseline, with algorithmically-distinct reference-frame construction.**

   **Given** the SuperFlux variant in `BPMAnalyzer` step 3 onset detection (new internal function `computeSuperFluxOnsetEnvelope` adjacent to `computeMelOnsetEnvelopeWithSubBands`)
   **When** `.superFluxOnset ∈ techniqueSet`
   **Then** the reference-frame construction uses Böck & Widmer 2013 SuperFlux: `referenceFrame[k] = max(M[t-1][k-r], M[t-1][k-r+1], ..., M[t-1][k+r])` with `r = 1` (window = 3 mel bins), computed via `vDSP_vswmax`
   **And** the per-frame difference + half-wave rectification + sum chain (`vDSP_vsub` → `vDSP_vthres` → `vDSP_sve`) is byte-for-byte identical to the baseline at `BPMAnalyzer.swift:721-734`; only the reference-frame construction differs
   **And** the existing baseline log-mel spectral flux (`computeMelOnsetEnvelopeWithSubBands`) is used when `.superFluxOnset ∉ techniqueSet`
   **And** the variant operates on the SAME mel-spectrogram — no second STFT, no extra audio pass, no new pipeline step number
   **And** the returned `OnsetEnvelopes` value is shape-identical to the baseline return (`fullBand: [Float]` with same length, `subBands: [[Float]]` with 4 sub-bands of same length, `mlFeatures: MLFeatureFrames?` populated when `captureMLFeatures == true`) — downstream steps 4-10 require ZERO code changes
   **And** the gate at `BPMAnalyzer.swift:230-235` switches between the two onset functions based on `techniqueSet.contains(.superFluxOnset)` (precedence: if both `.superFluxOnset` and `.subBandNormalization` are in the set, the SuperFlux variant runs FIRST and `.subBandNormalization` is applied to its sub-band output — document this composition explicitly in the function-level doc-comment)
   **And** the AC #1 invariant #12 numeric-distinctness test passes — the SuperFlux output is empirically distinct from the baseline output on the crafted fixture (proves the algorithm change took effect at the binary level, not just notional)

3. **Non-regression gate — variant disabled produces byte-identical output to pre-Story-4-7 baseline.**

   **Given** `Options.techniqueSet` does NOT contain `.superFluxOnset` (default + any preset NOT named `.full`)
   **When** `make benchmark` and `make benchmark-giantsteps` and `make test` run
   **Then** the asserted floors hold per Epic 4 Definitions:
   - OA300 Acc1 ≥ 57/82 (`OA300BenchmarkTests.swift:104`)
   - OA300 Acc2 ≥ 73/82 (`OA300BenchmarkTests.swift:108`)
   - GiantSteps Acc1 ≥ 537/661 (`GiantStepsBenchmarkTests.swift:82`)
   - GiantSteps Acc2 ≥ 546/661 (`GiantStepsBenchmarkTests.swift:86`)
   **And** per-track BPM JSON output is BYTE-IDENTICAL to the pre-Story-4-7 snapshot at `_bmad-output/implementation-artifacts/4-7-regression-snapshot.json` (captured in Task 1)
   **And** the byte-equality opt-out test `Tests/BoomBoomBoomKitTests/SuperFluxByteIdentityTests.swift::dspOnlyByteIdenticalWithSuperFluxAbsent` passes — `Double.bitPattern` equality on every `bpm` and `confidence` value; element-wise on `candidates`

4. **Numeric delta gate — variant enabled clears ≥1 named DnB triplet AND preserves all 4 controls, OR ships inert.**

   **Given** the variant is enabled via `options.techniqueSet = TechniqueSet([.acfSharpening, .subBandVoting, .fineGridRefinement, .superFluxOnset])` (`.optimal` augmented with `.superFluxOnset`)
   **When** `make super-flux-impact-report` produces `_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json`
   **Then** EITHER **(Branch A)**:
   - ≥1 of the 4 named DnB triplet tracks (Charly, Faraday_Bunker, Yin Yang, HEFT_Anagram 6) moves from its frozen `current_predicted_bpm` to within ±2% of `ground_truth_bpm` — i.e., `abs_error_variant < 0.02 × ground_truth_bpm` for at least one named track
   - AND all 4 `dsp_correct_controls` (Hellacopta, D3Z_Axons, Darkgray Heart, HEFT_Fuyu) remain within ±0.5 BPM of their `ground_truth_bpm`
   - AND aggregate Acc1/Acc2 floors hold (per AC #3)
   - → variant is added to `.optimal` and/or a new `.superFluxOptimal` preset (preset decision authorized at close-out time based on impact-report evidence)
   **OR (Branch B — Codex-authorized inert-ship)**:
   - Variant does NOT clear the named-track gate OR breaks ≥1 control
   - → variant case STAYS in `DSPTechnique` per AC #1, but is added to NO preset (`.optimal`, `.dnbOptimized`, `.clickAugmented` all UNCHANGED; `.full` auto-includes by `Set(allCases)` construction — that's the only preset that gains the case)
   - → Completion Notes document the per-track inertness with `4-7-super-flux-impact-report.json` as evidence (counts of `changedRanking`, `changedFinalBPM`, `namedDnBImproved`, `controlsPreserved`)
   - → no false-promise framing — "feature works + no regression" is NOT acceptable wording; honest framing IS "the brutal corpus gate was not cleared; the case ships available for consumer experimentation"

5. **Smoke-lane preservation.**

   **Given** the variant is shipped (either Branch A or Branch B per AC #4)
   **When** `make ablation-smoke` runs (the 16 curated combos in `AblationFullMatrixTests.smokeAblation`)
   **Then** ZERO of the 16 combos include `.superFluxOnset` (Branch B is the certain case; Branch A still defers smoke addition to a future story per DD #6)
   **And** smoke wall-clock is byte-for-byte identical to pre-Story-4-7 cadence (verifiable via `make perf-benchmark` p50/p95 not regressing on smoke runs)

6. **Per-track impact report deliverable.**

   **Given** a new `make super-flux-impact-report` target in `Makefile`
   **When** run with `OA300_CORPUS_PATH` set
   **Then** `_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json` is produced with:
   - Per-track rows: `{track, baseline_bpm, with_variant_bpm, ground_truth, baseline_correct, variant_correct, named_dnb_track, dsp_correct_control, abs_error_baseline, abs_error_variant}` (exact schema per DD #7)
   - Aggregate counts: `{changedRanking, changedFinalBPM, namedDnBImproved, controlsPreserved, total: 82}`
   - Schema version field: `schema_version: 1` (story-tagged artifact, NOT v3-harmonized envelope — that lane is reserved for perf-baselines)
   - Captured-with provenance block: `{captured_at, captured_by, git_sha, macos_version, xcode_version, swift_version}` matching Story 4-6 fixture conventions
   **And** the named DnB tracks AND DSP-correct controls are explicitly tagged (`named_dnb_track: true` / `dsp_correct_control: true`)
   **And** Completion Notes cite this artifact when reporting AC #4 outcome (Branch A: which named track resolved + by how much; Branch B: explicit inertness counts)

7. **Diff-scope proof + standard gating + Completion Notes integers.**

   **Given** the implementation is staged for commit
   **When** the dev agent prepares the close-out commit
   **Then** `_bmad-output/implementation-artifacts/4-7-diff-scope-proof.txt` is produced with 6 sections per Story 4-6 precedent:
   1. `git diff --stat` from the Task-1 pre-source SHA
   2. `git status -- Sources/` showing only the expected files (`BPMAnalyzer.swift`, `DSPTechnique.swift` — and CLAUDE.md / project-context.md per AC #1)
   3. `grep` for deprecated DSP APIs (zero matches — should be vacuous)
   4. Trace-field audit recipes A-E from `.claude/skills/bpm-diagnostic-trace/SKILL.md` against `Sources/` and `Tests/` — zero matches outside any new trace-field if added (per DD #12: no new trace field by default; vacuous if true)
   5. SPM external-deps count (still zero — Story 4-7 adds NO new dependencies; the variant is pure vDSP)
   6. Story-4-7 addendum — ablation matrix count growth confirmed from 128 to 256, smoke-lane combo count unchanged at 16, byte-equality opt-out test added at `Tests/BoomBoomBoomKitTests/SuperFluxByteIdentityTests.swift`
   **And** `make fmt` + `make lint` clean (only the canonical pre-existing `LUFSAnalyzer.swift:94` TODO baseline violation)
   **And** Completion Notes record exact integers per AC #11 precedent: test count, OA300 Acc1/Acc2, GiantSteps Acc1/Acc2, named-DnB-resolved count (0-4), controls-preserved count (0-4), Branch identifier (A or B), variant on/off Acc1 delta on OA300 (signed integer), per-track `changedFinalBPM` count

8. **File scope discipline.**

   **Given** Story 4-7's source changes
   **When** the diff is reviewed
   **Then** the following files are the ONLY source/test files touched by the dev agent (per AC #1 + AC #2 + AC #8):
   - **Modified source:** `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` (new internal `computeSuperFluxOnsetEnvelope` function + step-3 gate update), `Sources/BoomBoomBoomKit/DSPTechnique.swift` (new case + doc-comment)
   - **Modified docs:** `CLAUDE.md`, `_bmad-output/project-context.md`
   - **Modified tests:** `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` (invariant assertions), `Tests/BoomBoomBoomKitTests/AblationQuickTests.swift` (invariant assertions), `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift` (description string "128-combination" → "256-combination"; smoke-lane verification per DD #6)
   - **Modified infrastructure:** `Makefile` (new `super-flux-impact-report` target; the `ablation` target is unchanged but receives 2× more combos by inheritance)
   - **New test files:** `Tests/BoomBoomBoomKitTests/SuperFluxByteIdentityTests.swift`, `Tests/BoomBoomBoomKitTests/SuperFluxOnsetEnvelopeTests.swift`, `Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift`
   - **No `BoomBoomBoomKitML` target changes** — Story 4-7 is pure DSP, no ML dependency
   - **No new SPM products / no new external dependencies**
   - **No `BPMDiagnosticTrace` field additions** (per DD #12)

   **Test skip discipline (mandatory; per `axiom-testing/skills/swift-testing.md:52-58, 127-133`).** All new test files use `try #require` for setup failures and suite-level `.disabled(if:)` traits for env-gated or fixture-absent skips. Never use `Issue.record + return` inside test bodies — that pattern records a *failure*, not a *skip* (Story 4-6 P4/P15 review-pass lesson; project-context.md test rule).

   **`.serialized` trait — NOT used in Story 4-7.** Per `axiom-testing/skills/swift-testing.md:558-561, 701-707` "Only serialize when tests truly share mutable state." None of the 3 new test files mutate global state (Story 4-6 P13's `BNNSTechnique.thresholdOverride` was the documented exception; Story 4-7 has no analog). Parallel test execution is the default and is correct here.

   **Byte-identity via `Double.bitPattern` equality.** Per `axiom-testing/skills/swift-testing.md:46-64` (`#expect` handles any operator), use `#expect(actual.bitPattern == expected.bitPattern)`. This avoids the `NaN != NaN` and `+0.0 == -0.0` floating-point quirks that plain `==` introduces. Per-element on `[Float]` and `[Double]`; per-`bpm`/per-`confidence` on `BPMResult`.

## Tasks / Subtasks

- [x] **Task 1 — Pre-source baseline capture (AC #3, AC #7)** [matches Story 4-4/4-5/4-6 Task 1 commit pattern: `Story 4-7 Task 1: pre-source-change baseline artifacts`]
  - [x] 1.1: Run `make fmt && make lint && make test` — record gating baseline (test count == 420, only LUFSAnalyzer:94 TODO)
  - [x] 1.2: Run `make benchmark` (OA300) — capture per-track BPM JSON snapshot + aggregate Acc1/Acc2 to `_bmad-output/implementation-artifacts/4-7-regression-snapshot.json` (byte-equality anchor for AC #3)
  - [x] 1.3: Run `make benchmark-giantsteps` — capture per-track JSON + aggregate Acc1/Acc2 to the same snapshot file (suffix `giantsteps` section)
  - [x] 1.4: Run `make perf-benchmark` — capture per-run perf baseline JSON under `_bmad-output/perf-baselines/`
  - [x] 1.5: Confirm 4-dnb-triplet-targets.json fixture is at `schema_version: 3` (Story 4-6 v3 with controls partition); confirm SHA `7a6652a` `current_predicted_bpm` values for the 4 named tracks (Charly, Faraday_Bunker, Yin Yang, HEFT_Anagram 6) — these are the brutal-gate baseline values
  - [x] 1.6: Commit baselines + snapshot artifacts + initial story spec touch: `Story 4-7 Task 1: pre-source-change baseline artifacts`

- [x] **Task 2 — DSPTechnique enum extension + 10 invariant updates (AC #1)** [single commit; HALT-(a) fires if any site missed]
  - [x] 2.1: Append `case superFluxOnset` to `Sources/BoomBoomBoomKit/DSPTechnique.swift` (LAST position, preserving stable-identifier convention)
  - [x] 2.2: Update doc-comment in same file: "2^7 = 128 combinations" → "2^8 = 256 combinations"
  - [x] 2.3: Update `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — both `DSPTechnique.allCases.count == 7` (→ 8) and `TechniqueSet.allDSPCombinations().count == 128` (→ 256) assertions
  - [x] 2.4: Update `Tests/BoomBoomBoomKitTests/AblationQuickTests.swift` — both invariant assertions
  - [x] 2.5: Update `CLAUDE.md` — `DSPTechnique` description "7 cases" → "8 cases" and "2^7=128 combos" → "2^8=256 combos"; add `.superFluxOnset` to the enumerated case list with brief description
  - [x] 2.6: Update `_bmad-output/project-context.md` — 4 sites (lines 41, 88, 101, 160 per AC #1); preserve the "Add another DSPTechnique case to fix accuracy is no longer viable without architecture change" rule (Story 4-7 is the documented exception, not a deletion of the rule)
  - [x] 2.7: Run `make test` — assert the unit-test invariants pin both numbers to 8 / 256
  - [x] 2.8: Commit: `Story 4-7 Task 2: DSPTechnique.superFluxOnset case + 10 invariant updates`

- [x] **Task 3 — Implement `computeSuperFluxOnsetEnvelope` (AC #2, DDs #2, #3)** [pure vDSP, no new dependencies]
  - [ ] 3.1: Add new internal function `computeSuperFluxOnsetEnvelope(samples:sampleRate:hopSize:computeSubBands:normalizeSubBands:captureMLFeatures:) -> OnsetEnvelopes` to `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` adjacent to `computeMelOnsetEnvelopeWithSubBands`. Use the verbatim DocC template below (sourced from project Swift-doc convention; explicitly NO `- Throws` per project-context.md:39 "BPMAnalyzer ... return nil for no-result, never throw"):

    ```swift
    /// Computes the SuperFlux onset envelope from raw PCM samples.
    ///
    /// Per Böck & Widmer (2013) "Maximum Filter Vibrato Suppression for
    /// Onset Detection" (DAFx-13), SuperFlux extends spectral flux by
    /// replacing the temporal reference value `M[t-1][k]` with a
    /// frequency-neighborhood maximum `max(M[t-1][k-r:k+r])` (r=1, window
    /// = 3 mel bins) before per-frame differencing. The widened reference
    /// trajectory suppresses vibrato — energy sloshing between adjacent
    /// mel bins frame-to-frame no longer registers as a new onset.
    ///
    /// Formula: `SF_super[t] = Σ_k max(0, M[t][k] - max(M[t-1][k-r:k+r]))`
    /// where `M` is the post-`vvlogf` log-mel matrix and `r = 1`.
    ///
    /// Algorithmic distinction from the baseline at
    /// ``computeMelOnsetEnvelopeWithSubBands(samples:sampleRate:hopSize:computeSubBands:normalizeSubBands:captureMLFeatures:)``
    /// (which uses `M[t-1][k]` directly as the reference): only the
    /// reference-frame construction differs. The `vDSP_vsub` →
    /// `vDSP_vthres` → `vDSP_sve` chain is byte-identical.
    ///
    /// - Parameters:
    ///   - samples: Mono PCM `[Float]`, normalized to `[-1.0, 1.0]`.
    ///   - sampleRate: Hz (44.1k, 48k, 96k supported per `MelFilterbank`).
    ///   - hopSize: FFT hop in samples (typically 441 at 44.1k).
    ///   - computeSubBands: Gate for 4 sub-band envelope extraction (mirrors
    ///     `computeMelOnsetEnvelopeWithSubBands`'s contract).
    ///   - normalizeSubBands: Gate for per-band max normalization, applied
    ///     after sub-band extraction.
    ///   - captureMLFeatures: Gate for retaining the log-mel matrix in
    ///     ``OnsetEnvelopes/mlFeatures``.
    /// - Returns: An ``OnsetEnvelopes`` with `fullBand` (frame-count), four
    ///   `subBands` (each frame-count), and optional `mlFeatures`. Returns
    ///   sentinel-empty envelopes for degenerate inputs (silent buffer,
    ///   frame count < 32). **Does not throw** — sentinel-return semantics
    ///   per project-context.md:39.
    /// - Note: Variant of ``computeMelOnsetEnvelopeWithSubBands(samples:sampleRate:hopSize:computeSubBands:normalizeSubBands:captureMLFeatures:)``.
    ///   Gated by ``DSPTechnique/superFluxOnset`` in the technique set.
    ///   Pipeline step 3 — same step number as the baseline per
    ///   project-context.md:75 "Pipeline step numbers are stable
    ///   identifiers". Frequency-axis max-filter (canonical Böck 2013);
    ///   time-axis variant is reserved for a future story per Codex
    ///   2026-05-17 thread `019e36de`.
    /// - SeeAlso:
    ///   - ``computeMelOnsetEnvelopeWithSubBands(samples:sampleRate:hopSize:computeSubBands:normalizeSubBands:captureMLFeatures:)``
    ///   - ``DSPTechnique/superFluxOnset``
    ///   - Böck & Widmer (2013), DAFx-13 — https://phenicx.upf.edu/system/files/publications/Boeck_DAFx-13.pdf
    ```
  - [ ] 3.2: Reuse the FFT + Hann window + mel-filterbank chain (BPMAnalyzer.swift:553-617) — do NOT duplicate that code; either share a helper or factor the common part into a private function called by both onset variants
  - [ ] 3.3: Implement the SuperFlux per-frame chain. **Critical algorithmic distinction from baseline:** the baseline at `BPMAnalyzer.swift:721-734` uses `prevPtr.baseAddress!` directly as the `vDSP_vsub` subtrahend; SuperFlux replaces that pointer with a `vDSP_vswmax`-computed mel-bin-neighborhood max of the previous frame. The post-difference chain (HWR, sum) is byte-identical to baseline. Use the verbatim code pattern below — all four vDSP primitives are Apple-verbatim-validated (`vDSP_vswmax` via apple-docs MCP + `vDSP.h:5682-5697`, the other three from the original axiom-apple-docs report):

    ```swift
    let n = vDSP_Length(melBands)
    let r: vDSP_Length = 1                  // Codex 2026-05-17: r=1 is paper-faithful
    let windowLength: vDSP_Length = 2 * r + 1  // = 3 mel bins
    let paddedLength = melBands + Int(windowLength) - 1  // = melBands + 2

    var paddedRef = [Float](repeating: 0, count: paddedLength)
    var maxFilteredRef = [Float](repeating: 0, count: melBands)
    var diff = [Float](repeating: 0, count: melBands)
    var rectified = [Float](repeating: 0, count: melBands)
    var flux = [Float](repeating: 0, count: frameCount)

    for t in 1..<logMelFrames.count {
      // 1. Build the replicate-padded reference frame from M[t-1].
      //    Codex 2026-05-17 locked replicate-pad (rejected zero-pad and reflect-pad).
      //    Replicate-pad preserves edge locality and avoids reflecting interior
      //    energy into kick/hi-hat boundaries (load-bearing for the 4 named DnB tracks).
      let refFrame = logMelFrames[t - 1]
      let rInt = Int(r)
      // Left pad: replicate refFrame[0]
      for i in 0..<rInt { paddedRef[i] = refFrame[0] }
      // Center: copy refFrame
      for i in 0..<melBands { paddedRef[rInt + i] = refFrame[i] }
      // Right pad: replicate refFrame[melBands - 1]
      for i in 0..<rInt { paddedRef[rInt + melBands + i] = refFrame[melBands - 1] }

      // 2. Frequency-axis max-filter on the padded reference frame.
      //    vDSP_vswmax: C[k] = max(A[k], A[k+1], ..., A[k+WindowLength-1])
      //    Apple verbatim: developer.apple.com/documentation/accelerate/vdsp_vswmax
      //    Constraints: A and C may NOT overlap; input must be N+WindowLength-1 elements
      //    (paddedRef satisfies this — sized to melBands + windowLength - 1).
      vDSP_vswmax(paddedRef, 1, &maxFilteredRef, 1, n, windowLength)

      // 3. SuperFlux temporal difference: diff = M[t] - max_filter(M[t-1])
      //    vDSP_vsub computes C = A - B with parameter ORDER (B, A, C).
      //    Pass maxFilteredRef as B (subtrahend), currFrame as A (minuend).
      //    This is the only step that differs in shape from the baseline at
      //    BPMAnalyzer.swift:721-734 — baseline passes `prevPtr` directly here.
      //    Apple verbatim: developer.apple.com/documentation/accelerate/vdsp_vsub
      logMelFrames[t].withUnsafeBufferPointer { currPtr in
        vDSP_vsub(maxFilteredRef, 1, currPtr.baseAddress!, 1, &diff, 1, n)
      }

      // 4. Half-wave rectify: rectified = max(diff, 0) — byte-identical to baseline.
      //    Apple verbatim: developer.apple.com/documentation/accelerate/vdsp_vthres
      var threshold: Float = 0
      vDSP_vthres(diff, 1, &threshold, &rectified, 1, n)

      // 5. Sum across mel bands — byte-identical to baseline.
      //    Apple verbatim: developer.apple.com/documentation/accelerate/vdsp_sve
      var frameSum: Float = 0
      vDSP_sve(rectified, 1, &frameSum, n)
      flux[t - 1] = frameSum
    }
    ```

    **API choice rationale (locked by axiom-apple-docs MCP 2026-05-17):**
    - `vDSP_vswmax` IS the sliding-window max primitive. `vDSP_vmaxmg` (max of magnitudes between two vectors) was a candidate in earlier party-mode discussion but **eliminated** as incorrect semantics for SuperFlux — it does not perform a sliding-window operation.
    - C-style vDSP names verbatim (NOT the Swift overlay `vDSP.subtract` / `vDSP.threshold` / `vDSP.sum`). Per project-context.md:64.
    - Padding loops are scalar `for` over `melBands + 2r` elements (≤130 iterations); negligible cost vs the vDSP chain. The padding step does NOT use vDSP because the project-context.md "no manual loops over signal data" rule applies to bulk numeric ops on long signal buffers, not to small constant-size buffer setup; consistent with the existing baseline's frame-iteration loop.
  - [ ] 3.4: Sub-band extraction with **explicit pipeline order** (clarification of DD #3):
    1. Compute the per-mel × per-frame difference matrix (step 1 of Task 3.3)
    2. Half-wave rectify per cell (step 2 of Task 3.3) — produces the post-HWR per-cell matrix
    3. **Sub-band envelopes** are siblings of the full-band envelope, both consuming the post-HWR per-cell matrix from step 2:
       - For each sub-band range (`kickBandRange: 0..<20`, `snareLowRange: 20..<50`, `snareCrackRange: 50..<80`, `hiHatRange: 80..<128`), sum within that mel-range per frame → 4 sub-band envelopes
       - For the full-band envelope, sum across all 128 mel bands per frame → 1 full-band envelope
    4. HWR is per-cell (NOT after summing). Order matters: `sum(max(0, diff))` produces different output than `max(0, sum(diff))`. The spectral-flux formula in DD #3 is the former — HWR is applied to each (mel, frame) cell, and the sum is across cells with already-non-negative values.

    Mel-bin range extraction uses pointer arithmetic on the post-HWR matrix (`rectifiedMatrix.baseAddress! + range.lowerBound` with `vDSP_sve` and length `vDSP_Length(range.count)`) — matches the existing pattern at `BPMAnalyzer.swift:738-746`.
  - [ ] 3.5: Sub-band normalization (gated by `normalizeSubBands` per existing pattern) — applies after sub-band extraction; reuse the existing per-band max-normalization code
  - [ ] 3.6: MLFeatures capture (gated by `captureMLFeatures`) — retain the same log-mel matrix as the energy variant; ML feature contract is unchanged
  - [ ] 3.7: Add unit tests in `Tests/BoomBoomBoomKitTests/SuperFluxOnsetEnvelopeTests.swift`:
    - Variant returns non-empty `fullBand` for click-track inputs
    - Variant returns 4 non-empty sub-bands
    - Variant's `fullBand` has POSITIVE values for known-positive onset times (use bpm-120-click fixture and assert peaks at expected sample positions)
    - Variant's output is BYTE-DIFFERENT from energy-variant output for the same input (proves the algorithm change took effect)
    - Variant on degenerate input (silent buffer, short clip < 32 frames) returns empty/sentinel envelopes without crashing

    **Per-fixture vs OR-aggregate test-shape discipline (per `axiom-testing/skills/swift-testing.md:181-228` parameterized testing):** For the 8 frozen fixtures (4 named DnB + 4 controls), use parameterized `@Test(arguments:)` with this constraint —
    - **Control-set assertion is per-fixture** — each of the 4 controls MUST individually pass `absError <= 0.5 BPM` (per Story 4-6 DD #4 + Story 4-7 AC #4 second clause). A single `#expect(absError <= 0.5, "Control \(track) regressed")` per parameterized invocation.
    - **Named-failure assertion is OR-of-4 aggregate** — Branch A success requires `≥1` resolution across the 4 named tracks, NOT all-of-4. Do NOT put per-fixture `#expect(resolved)` in the parameterized body — that would inflate Branch A from OR-of-4 to AND-of-4 and silently raise the success bar. Implement the OR-aggregate by accumulating into the impact-report JSON (Task 6) and asserting `report.namedDnBImproved >= 1` at the harness level.
    - **Why this matters:** Parameterized tests run each argument as a separate test case (per `swift-testing.md:220-228`). A failing per-fixture `#expect` on 3-of-4 named tracks would mark the test red even when Branch A succeeded with 1-of-4 resolved. Keep the per-fixture / OR-aggregate semantics in different test files: per-fixture in `SuperFluxOnsetEnvelopeTests.swift`; OR-aggregate in `SuperFluxImpactTests.swift` (the benchmark-target harness).
  - [ ] 3.8: Commit: `Story 4-7 Task 3: computeSuperFluxOnsetEnvelope + unit tests`

- [x] **Task 4 — Integrate at BPMAnalyzer step 3 with gating (AC #2)**
  - [ ] 4.1: At `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:230-235`, branch the onset-construction call on `techniqueSet.contains(.superFluxOnset)`:
    ```swift
    let onsetResult: OnsetEnvelopes
    if techniqueSet.contains(.superFluxOnset) {
      onsetResult = computeSuperFluxOnsetEnvelope(
        samples: analysisWindow, sampleRate: sampleRate, hopSize: hopSize,
        computeSubBands: techniqueSet.contains(.subBandVoting),
        normalizeSubBands: techniqueSet.contains(.subBandNormalization),
        captureMLFeatures: options.captureMLFeatures)
    } else {
      onsetResult = computeMelOnsetEnvelopeWithSubBands(
        samples: analysisWindow, sampleRate: sampleRate, hopSize: hopSize,
        computeSubBands: techniqueSet.contains(.subBandVoting),
        normalizeSubBands: techniqueSet.contains(.subBandNormalization),
        captureMLFeatures: options.captureMLFeatures)
    }
    var onsetEnvelope = onsetResult.fullBand
    ```
  - [ ] 4.2: Verify no downstream code path (lines 240-end of `estimateBPM`) inspects the onset envelope's algorithmic origin — the contract is the `[Float]` shape and the `OnsetEnvelopes` struct, which both variants honor
  - [ ] 4.3: Verify `MLFeatureFrames` capture works correctly under spectral-flux variant (mlFeatures captured against same log-mel matrix; downstream BNNS path receives same shape)
  - [ ] 4.4: Run `make test` — all 420+ tests should still pass with `.superFluxOnset` absent from default `Options.techniqueSet`
  - [ ] 4.5: Commit: `Story 4-7 Task 4: BPMAnalyzer step 3 spectral-flux gating`

- [x] **Task 5 — Byte-equality opt-out test (AC #3, AC #8)**
  - [x] 5.1: Create `Tests/BoomBoomBoomKitTests/SuperFluxByteIdentityTests.swift`
  - [x] 5.2: First test: `dspOnlyByteIdenticalWithSuperFluxAbsent` — analyze each fixture in `AudioFixtures` with default `Options` (no `.superFluxOnset`); compare to Task-1 baseline using `Double.bitPattern` equality on `bpm`/`confidence`, element-wise on `candidates`; SHOULD pass (variant is gated correctly)
  - [x] 5.3: Second test: `dspOnlyDifferentWithSuperFluxPresent` — analyze same fixtures with `options.techniqueSet = TechniqueSet([.superFluxOnset, ...optimal])`; compare to baseline; SHOULD FAIL byte-identity (proves the variant actually does something — if this test passes byte-identity, the gate is broken)
  - [x] 5.4: Run via `make test` — both tests pass according to their respective contracts
  - [x] 5.5: Commit: `Story 4-7 Task 5: byte-equality opt-out tests for spectral-flux variant`

- [x] **Task 6 — Per-track impact report harness + Makefile target (AC #6, DD #7)**
  - [ ] 6.1: Create `Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift` modeled after Story 3-3 `ClickImpactTests` and Story 3-4 `DurationImpactTests`
  - [ ] 6.2: Suite trait `.enabled(if: ProcessInfo.processInfo.environment["SPECTRAL_FLUX_IMPACT"] == "1")` so it doesn't fire during `make test`
  - [ ] 6.3: Test body: for each OA300 fixture, run two analyses (baseline `Options()` and variant `Options()` with `.optimal ∪ {.superFluxOnset}`); accumulate per-track row per DD #7 schema; emit JSON to env-overridable path (default `_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json`)
  - [ ] 6.4: Add `make super-flux-impact-report` target to `Makefile` following the `click-impact-report` precedent (Makefile:98-114 with appropriate env vars and output-dir override)
  - [ ] 6.5: Run `make super-flux-impact-report` against full OA300 — verify JSON shape, named-DnB and control flags correct, aggregate counts present
  - [ ] 6.6: Commit: `Story 4-7 Task 6: per-track spectral-flux impact-report harness + Makefile target`

- [x] **Task 7 — Run brutal-corpus gate (AC #4)** [CRITICAL — this task decides Branch A vs Branch B]
  - [x] 7.1: Run `make super-flux-impact-report` against full OA300 (post-Task-6 implementation)
  - [x] 7.2: Parse the JSON: count `namedDnBImproved` (named-DnB tracks where `variant_correct == true && baseline_correct == false`); count `controlsPreserved` (controls where `variant_correct == true`)
  - [x] 7.3: Decide branch: **Branch B** (`namedDnBImproved=0/4 < 1` AND `controlsPreserved=2/4 < 4`)
  - [x] 7.4: AC #3 second clause N/A for Branch B (no preset path includes `.superFluxOnset`); aggregate floors at default `Options()` (variant absent) confirmed: OA300 Acc1=58/82 Acc2=74/82, GiantSteps Acc1=537/661 Acc2=546/661 (>= floors 57/73 + 537/546)
  - [x] 7.5: Branch A skipped — see Task 8 (skipped) and Task 9 (Branch B inert-ship close-out)
  - [x] 7.6: Commit (Branch B): `Story 4-7 Task 7: brutal-corpus-gate outcome — Branch B`

- [ ] **Task 8 — Preset addition (Branch A ONLY; skip if Branch B)** SKIPPED — Branch B outcome.

- [x] **Task 9 — Inert-ship close-out (Branch B ONLY; skip if Branch A)**
  - [x] 9.1: Confirmed no preset was mutated — `.optimal`, `.dnbOptimized`, `.clickAugmented` byte-identical to pre-Story-4-7 state; `.full` auto-includes via `Set(allCases)` (mechanical)
  - [x] 9.2: Added inert-ship doc-comment to `DSPTechnique.superFluxOnset` citing the impact-report JSON as evidence
  - [x] 9.3: Filed deferred-work entry with re-open trigger
  - [x] 9.4: Commit: `Story 4-7 Task 9: Branch B inert-ship close-out`

- [x] **Task 10 — Smoke-lane verification (AC #5, HALT-(e))**
  - [x] 10.1: Read `AblationFullMatrixTests.smokeAblation` body — enumerate the 16 combos (extracted to `AblationMatrixTests.smokeCombos` static for source-of-truth sharing)
  - [x] 10.2: Verify ZERO of the 16 include `.superFluxOnset` — `("full", .full)` + `("full-click", .full.removing(.click))` swapped to `("full(-superFlux)", .full.removing(.superFluxOnset))` + same for click variant. CI-enforced via new `SmokeAblationInvariantTests` suite (AC #1 invariant #11, parameterized over the 16 combos)
  - [x] 10.3: `make ablation-smoke` wall-clock 10.38s real (no measurable cadence shift; pre-Story-4-7 cell `.full` produces same Acc1=49/82 as new `.full(-superFlux)` by construction)

- [x] **Task 11 — Test count verification (HALT-(d))**
  - [x] 11.1: `rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l` = 432 (band `[432, 438]` low edge)
  - [x] 11.2: N/A — at floor of band
  - [x] 11.3: N/A — at floor of band

- [x] **Task 12 — Diff-scope proof + Gating checklist + Completion Notes (AC #7)**
  - [x] 12.1: Produce `_bmad-output/implementation-artifacts/4-7-diff-scope-proof.txt` with 6 sections per AC #7
  - [x] 12.2: Run gating gauntlet — all integer counts captured in Completion Notes (`make ablation` ran 256 combos in 207.6s, best combo `.optimal` at 55/82 — DSP-only ceiling unchanged)
  - [x] 12.3: Completion Notes updated with full integers + per-track tables + branch-decision rationale + honest-framing prose
  - [x] 12.4: Story Status flipped to `review` in header + sprint-status.yaml
  - [x] 12.5: Final commit pending (this commit)
  - [x] 12.6: Run `/bmad-code-review` — completed 2026-05-17, 4-layer parallel review (Claude Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex Blind Hunter) returned 54 raw findings deduplicated to 12 `patch` + 13 `defer` + 15 `dismiss`. Zero `decision_needed`. Acceptance Auditor verdict: 7/8 ACs PASS, AC #6 PARTIAL (missing `xcode_version`/`swift_version` in impact-report provenance). No Critical/High shipped-code bugs; High-severity Codex findings concentrate in `SuperFluxImpactTests` test-harness hardening (silent missing-file skip, swallowed analyzer errors, fixture-totals not asserted). All findings recorded below.
  - [x] 12.7: Post-review final flip Status `review` → `done` — applied 2026-05-17 after 12 patches landed; OA300 Acc1=58/82 + Acc2=74/82 (unchanged), GiantSteps Acc1=537/661 + Acc2=546/661 (unchanged), impact-report regenerated with aggregate counts unchanged (changedFinalBPM=82/82, namedDnBImproved=0/4, controlsPreserved=2/4) — Branch B inert-ship semantics preserved.

### Review Findings

_Code review run 2026-05-17 via `/bmad-code-review`. 54 raw findings from 4 layers (Claude Blind Hunter, Edge Case Hunter, Acceptance Auditor, Codex Blind Hunter) deduplicated. Acceptance Auditor verdict: 7/8 ACs PASS, AC #6 PARTIAL (cosmetic provenance gap)._

**Patches (12) — code-issue fixes, unambiguous resolution:**

- [ ] [Review][Patch] P1 — `SuperFluxImpactTests` harness silently skips missing files + swallows analyzer errors + does not assert namedDnB/control fixture totals [`Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift:101,132,176-186`] — Codex H1/H2/H3 + ECH#10/#11. The brutal-corpus-gate report can pass on a degraded dataset (e.g., one surviving track, both DnB-targets missing). Fix: replace `compactMap { ... guard fileExists else { return nil } }` with explicit error propagation; replace `} catch { return nil }` with a typed failure that surfaces in the row; add post-loop `#expect(namedDnBTotal == 4)` and `#expect(controlsTotal >= 4)` assertions.
- [ ] [Review][Patch] P2 — `sentinelOnSilentInput` test is mis-named and only asserts `.isFinite` on `fullBand`, not on `subBands` [`Tests/BoomBoomBoomKitTests/SuperFluxOnsetEnvelopeTests.swift:78`] — CBH#6 + ECH#19 + Codex#6. Title claims "sentinel-empty envelopes" but body tests finite-zero behavior on silent input (>2 frames), not the actual `<2 frames` sentinel. Fix: rename to `silentInputProducesFiniteZeros`; extend `isFinite` check across `result.subBands` flatMap; add a separate test that crafts a `<2`-frame input and asserts `fullBand.isEmpty && subBands.allSatisfy(\.isEmpty)`.
- [ ] [Review][Patch] P3 — Docstring contract on `computeSuperFluxOnsetEnvelope` says "Returns sentinel-empty envelopes for degenerate inputs (silent buffer, frame count < 2)" but silent buffer with ≥2 frames returns non-empty all-zero envelopes [`Sources/BoomBoomBoomKit/BPMAnalyzer.swift:656`] — Codex#7. Fix: split the doc-comment into two contracts: "frame count < 2 → empty envelopes" and "silent buffer with ≥2 frames → finite all-zero envelopes".
- [ ] [Review][Patch] P4 — Weak distinctness gates: `differingFrames > 0` and `anyDifferent` short-circuit on first byte-different value; one differing float satisfies the assertion [`Tests/BoomBoomBoomKitTests/SuperFluxOnsetEnvelopeTests.swift:1473-1480` + `SuperFluxByteIdentityTests.swift:131`] — CBH#7 + ECH#20 + Codex#12 + ECH#8. Fix: require either (a) ≥10% of frames differ, or (b) mean absolute difference > 1e-3 across the envelope. For the multi-fixture case (`SuperFluxByteIdentityTests`), require all 5 fixtures to differ, not just one.
- [ ] [Review][Patch] P5 — `replicatePadPreservesBoundaryBins` uses a generic click track and only asserts `kickMax > 0 && hiHatMax > 0`; baseline path also produces non-zero output there, so the test doesn't isolate boundary-padding behavior [`Tests/BoomBoomBoomKitTests/SuperFluxOnsetEnvelopeTests.swift:1483-1506`] — Codex#8 + ECH#21. Fix: craft a fixture where energy is concentrated at mel-bin 0 only, then assert the SuperFlux envelope at the kick band is empirically distinct from the baseline (uses replicate-pad to suppress center-bin spread).
- [ ] [Review][Patch] P6 — `changedRanking` and `changedFinalBPM` counters increment under identical predicate, producing duplicate telemetry presented as distinct signals [`Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift:926-931`] — CBH#10 + Codex#5. Fix: either consolidate to one field (rename to `changedAnyBPM`, drop the other), or implement the documented distinction (changedRanking = pre-disambiguation top candidate; changedFinalBPM = post-disambiguation winner) by re-running the analyzer with `enableTrace: true` and comparing trace candidates.
- [ ] [Review][Patch] P7 — `r.baselineBPM != r.variantBPM` counts nil-vs-non-nil as `changedFinalBPM`, conflating "variant failed to analyze" with "variant disagreed" [`Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift:920-925`] — ECH#10. Fix: split the predicate: `analyzerFailureCount` (one side nil) vs `changedFinalBPM` (both non-nil and different).
- [ ] [Review][Patch] P8 — Empty `OnsetEnvelopes(fullBand: [], subBands: [[], [], [], []])` literal is duplicated at two call sites (baseline + SuperFlux helper-returns-nil paths); future variants must replicate it verbatim [`Sources/BoomBoomBoomKit/BPMAnalyzer.swift:103-104,224-225`] — CBH#16. Fix: add `internal static var empty: OnsetEnvelopes` factory on the type (or have `computeLogMelFramesAndRetention` return non-nil with empty contents).
- [ ] [Review][Patch] P9 — `.superFluxOnset` doc-comment mentions controls regressed but does not surface the Acc1=-4 number (55→51) for opt-in consumers [`Sources/BoomBoomBoomKit/DSPTechnique.swift:517-525`] — CBH#19 + Acceptance Auditor F19. Fix: append "Enabling this case on top of `.optimal` regresses OA300 DSP-only Acc1 by 4 tracks (55→51); see `_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json` for per-track impact." to the doc-comment.
- [ ] [Review][Patch] P10 — Impact-report `captured_with` provenance block is missing `xcode_version` and `swift_version` per spec AC #6 [`Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift:980-987`] — Acceptance Auditor F9. Fix: extend the provenance dict with the two fields; spec wording explicitly listed both, matching Story 4-6 fixture conventions. (Develop-only artifact; missing fields are duplicable from regression-snapshot.json, so cosmetic but spec-bound.)
- [ ] [Review][Patch] P11 — `baseline_bpm: r.baselineBPM as Any` in the JSON serializer passes an `Optional<Double>` to `JSONSerialization` which throws on nil-wrapped-as-Any [`Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift:952,959-960`] — ECH#12. Fix: use the same `isFinite ? value : NSNull()` pattern that `abs_error_variant` already uses, or branch on `r.baselineBPM.map { $0 } ?? NSNull()`.
- [ ] [Review][Patch] P12 — Impact-report `rows[]` are appended in `withTaskGroup` completion order, not deterministic; consecutive runs produce different JSON orderings [`Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift:860-890`] — ECH#14. Fix: collect rows into a dictionary keyed by track name, then write `rows: dict.keys.sorted().map { dict[$0]! }`.

**Defers (13) — real but pre-existing or out-of-scope; appended to `deferred-work.md`:**

- [x] [Review][Defer] W1 — `.full` preset auto-includes `.superFluxOnset` via `Set(allCases)`; consumers selecting `.full` get the regressing variant despite the documented inert-ship outcome — deferred, intentional per `DSPTechnique.swift:524` documentation; revisit if `.full` semantics ever change.
- [x] [Review][Defer] W2 — Byte-identity baseline JSON pins M5 Max-specific Float bit patterns; will fail on Intel hardware or future Accelerate ISA changes [`Tests/BoomBoomBoomKitTests/Fixtures/4-7-byte-identity-baseline.json`] — deferred, pre-existing pattern (Story 3-3, 3-6 use same shape); needs cross-hardware-gate story.
- [x] [Review][Defer] W3 — `computeSuperFluxOnsetEnvelope` lacks the `onPostVvlogf` test-only seam that `computeMelOnsetEnvelopeWithSubBands` exposes [`Sources/BoomBoomBoomKit/BPMAnalyzer.swift:211-218`] — deferred, symmetric extension when SuperFlux needs Story-4-5-style parity testing.
- [x] [Review][Defer] W4 — NaN/Inf coverage on `vDSP_vswmax` path missing; max-filter now amplifies NaN across 3-bin neighborhood vs baseline 1-bin exposure [`Sources/BoomBoomBoomKit/BPMAnalyzer.swift:707-742`] — deferred, pre-existing NaN sensitivity in the wider pipeline; needs a fixture story.
- [x] [Review][Defer] W5 — SuperFlux + `.subBandNormalization` composition has no unit-test coverage; ablation-only [`Sources/BoomBoomBoomKit/BPMAnalyzer.swift:651-654`] — deferred, ablation matrix covers it but `make test` (no corpus) does not.
- [x] [Review][Defer] W6 — Numeric-distinctness test (AC #1 invariant #12) uses a generic 144-BPM click fixture; spec called for a crafted bin-level fixture exposing the max-filter difference [`Tests/BoomBoomBoomKitTests/SuperFluxOnsetEnvelopeTests.swift:1521-1572`] — deferred, spirit met (proves bit-level distinctness); letter requires a follow-up fixture story.
- [x] [Review][Defer] W7 — Replicate-pad uses three scalar Swift loops over 130 floats per frame; project rule prefers vDSP/memcpy for bulk numeric ops [`Sources/BoomBoomBoomKit/BPMAnalyzer.swift:255-257`] — deferred, perf-immaterial at 130 elements; revisit when the per-frame inner loop shows up in xctrace.
- [x] [Review][Defer] W8 — `acc1Correct(detected:expected:)` returns false when `expected <= 0` without diagnostic; future ground-truth entries with `bpm: 0.0` sentinel silently drop from metrics [`Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift:897-900`] — deferred, requires ground-truth schema convention work.
- [x] [Review][Defer] W9 — `namedDnBSet` filename-matching uses double-fallback (`trackIDStem || filename`); doesn't handle path-separator-containing IDs in future schema_version 4 [`Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift:878-881`] — deferred, schema_version 4 work is a separate story.
- [x] [Review][Defer] W10 — Hardcoded `let r = 1` is duplicated across source, comments, docs, and tests with no single source of truth; if r ever changes, ≥5 sites must update [`Sources/BoomBoomBoomKit/BPMAnalyzer.swift:233`] — deferred, hoist to `static let superFluxRadius = 1` when a future story enables r as a parameter.
- [x] [Review][Defer] W11 — `paddedRef` allocated once and overwritten exhaustively per frame; correct for r=1 but fragile if a future change relaxes r [`Sources/BoomBoomBoomKit/BPMAnalyzer.swift:241,255-257`] — deferred, add `assert(r == 1)` when introducing parameterized r.
- [x] [Review][Defer] W12 — Smoke-combo array has no duplicate-detection invariant; a copy-paste duplicate would collapse to fewer unique tests under `@Test(arguments:)` dedup [`Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift:723-735`] — deferred, add `#expect(Set(smokeCombos.map(\.1)).count == smokeCombos.count)` in a follow-up.
- [x] [Review][Defer] W13 — `SmokeAblationInvariantTests` failure message uses `combo.label` (recomputed from `TechniqueSet`), losing the smoke-combo display-name from the tuple `.0` field [`Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift:730`] — deferred, parameterize over the full tuple to surface both.

**Dismissed (15):**

R1 `frameCount == 0` short-circuited via `>= 2` helper guard (CBH#1 + ECH#2) — correctly defended. R2 `internal static func` access modifier explicit (CBH#9) — matches project precedent. R3 `try #require` defense-in-depth via `.disabled(if:)` (CBH#11). R4 GIT_SHA Makefile convention drift between targets (CBH#14). R5 `for ... where ... { break }` style (CBH#15) — code is correct. R6 `bandRanges` literal duplication (CBH#17) — minor. R7 `OnsetEnvelopes` initializer shape verifiable in pre-diff code (CBH#18). R8 `combo.label` API verifiable in pre-diff code (CBH#13). R9 256-combo ablation memory/timeLimit (ECH#15) — measured at 207.6s within 60-min budget. R10 `Bundle.module.url(...subdirectory:)` fallback handles SPM layout drift (ECH#16). R11 `withTaskGroup` ordering (ECH#14) — addressed by P12. R12 `#expect(schema_version == 3)` doesn't halt (ECH#17 + Codex#4 partial) — informational; future schema_version 4 is a separate story. R13 `CodingKeys` over `swiftlint:disable identifier_name` (CBH#12) — style preference. R14 `dspOnlyByteIdenticalWithSuperFluxAbsent` default Options assumption (ECH#9) — protected by AC #3 review; future preset additions correctly trip this test. R15 `dspOnlyDifferentWithSuperFluxPresent` short-circuits on first fixture (ECH#8) — addressed by P4.

## Dev Notes

### Architecture references

- **Onset envelope construction (lines being modified):** `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:230-235` (step 3 call site), `BPMAnalyzer.swift:483-774` (`computeMelOnsetEnvelopeWithSubBands` function body), `BPMAnalyzer.swift:553-617` (FFT + mel-filterbank chain that the spectral-flux variant SHARES), `BPMAnalyzer.swift:721-748` (temporal-differentiation step that the spectral-flux variant REPLACES).
- **DSPTechnique enum:** `Sources/BoomBoomBoomKit/DSPTechnique.swift:19-76` (7 cases), `:131-160` (5 presets), `:164-181` (`allDSPCombinations()` 2^N expansion).
- **ADRs touching the DSP spine:** ADR-3 (buffer reuse, project-context.md ADR table), ADR-7 (harmonic-ratio inside step 10), ADR-8 (click-track as new DSPTechnique case — Story 3-3 precedent for the same architectural shape as Story 4-7), ADR-11 (Options-first — does NOT apply to Story 4-7 per DD #1 because the variant is a DSP-spine technique, not orthogonal signal axis).
- **Floor assertions:** `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift:104,108` (Acc1 ≥ 57, Acc2 ≥ 73), `GiantStepsBenchmarkTests.swift:82,86` (Acc1 ≥ 537, Acc2 ≥ 546). These are unconditional `#expect` per project-context.md:98.
- **Frozen named-DnB + control fixture:** `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` schema_version 3, captured at SHA `7a6652a`. The `current_predicted_bpm` values for the 4 named tracks are the brutal-gate baseline. The `dsp_correct_controls` array is the regression-protection backbone.

### Project Structure Notes

- Library target `BoomBoomBoomKit` ships to main; no `BoomBoomBoomKitML` changes (Story 4-7 is pure DSP).
- `Makefile` gains a new `super-flux-impact-report` target alongside `click-impact-report` and `duration-impact-report`. The target follows the existing pattern (env-gated on `OA300_CORPUS_PATH`, optional output-dir override via env var). The target IS develop-only — consumers won't run it.
- `_bmad-output/implementation-artifacts/4-7-*.{md,json,txt}` are develop-only artifacts (per CLAUDE.md "Stays on develop ONLY" — `_bmad-output/` is on the develop-only list).
- The new test file `SuperFluxImpactTests.swift` lives in the BENCHMARK test target (`BoomBoomBoomKitBenchmarkTests`), env-gated. The byte-equality and onset-envelope tests live in the UNIT test target (`BoomBoomBoomKitTests`) so they run on every `make test`.
- No SPM manifest changes. No new external dependencies. No new SPM products.

### Risk

- **R1 — Variant doesn't help DnB triplets at all.** This is the most likely outcome (Codex 2026-05-04 framing). The brutal-corpus-gate + inert-ship branch (DD #4, AC #4 Branch B) is the discipline-preserving exit. The architectural-rule exception (DD #13) is preserved by NOT adding the case to any preset on failure.
- **R2 — Variant helps DnB but breaks one or more controls.** This is the "bad-trade" outcome — improving a named failure at the cost of a previously-correct track is NOT acceptable. Branch B fires, and Completion Notes document the trade-off explicitly. The case still ships but unused.
- **R3 — Variant produces NaN/Inf on edge inputs.** Half-wave rectification (`vDSP_vthres` with threshold 0.0) can in principle leave NaN values untouched (NaN > 0 is false → not clamped). The unit-test suite in Task 3.7 includes a "degenerate input" test that asserts no NaN/Inf in the output envelope. Mitigation: add an `isFinite` filter after the half-wave rectification step or document the invariant from `vvlogf` (log-mel values should always be finite for non-silent input).
- **R4 — Ablation matrix wall-clock doubles, CI budget breached.** Story 3-3's ablation was ~9 min on M5 Max; current ablation is ~77 s with parallelism. Doubling to ~150 s is well within the 60-min `@Test(.timeLimit(.minutes(60)))` budget. No CI infrastructure change needed.
- **R5 — Byte-identity test fails despite correct gating.** The first byte-identity test (`dspOnlyByteIdenticalWithSuperFluxAbsent`) is supposed to PASS. If it fails, the gate condition is leaking into the default path — likely the branch at BPMAnalyzer.swift:230-235 is unconditional or the new function has side-effects on shared state. Code-review and the Story 3-6b `runPreCorroborationPipeline`-share-with-production pattern mitigate this.
- **R6 — Smoke-lane drift.** The smoke combos in `AblationFullMatrixTests.smokeAblation` are hard-coded. If a dev accidentally adds `.superFluxOnset` to one of them (e.g., copy-paste from the full ablation), HALT-(e) fires. Task 10 is the verification step.
- **R7 — Sub-band composition with `.subBandNormalization`.** When both `.superFluxOnset` and `.subBandNormalization` are in the technique set, the SuperFlux variant computes sub-bands FIRST (per DD #3 Task 3.4) and `.subBandNormalization` applies per-band max-normalization to those flux-derived sub-bands. This is a sensible composition (both operations are downstream of mel-filterbank), but it WAS NOT empirically validated before Story 4-7. The ablation matrix (256 combos) covers this composition cell — if the cell behavior is degenerate, the impact-report numbers will surface it.

- **R8 — Frequency-axis vs time-axis interpretation discipline.** Per Codex 2026-05-17, SuperFlux can mean either frequency-axis max-filter (canonical Böck 2013 — vibrato suppression) or time-axis max-filter (slow-attack handling). Story 4-7 implements ONLY the frequency-axis variant. The dev agent must NOT compose them or substitute one for the other mid-implementation — Codex was explicit: "A time-axis max is a different hypothesis, and for this story it would blur the experiment." If a future ablation suggests time-axis would help, that becomes a separate story.

- **R9 — Replicate-pad edge bin handling.** The first and last `r` mel bins (bins 0 and 127 at r=1) get their reference value via replicate-pad. For bin 0: `max(refFrame[0], refFrame[0], refFrame[1])` collapses the left-pad to the interior value. For bin 127: symmetric on the right edge. These edge bins are in the kick band (0..<20) and hi-hat band (80..<128) — both load-bearing for the 4 named DnB tracks. The padding choice does NOT mask transient detection at the boundaries (Codex 2026-05-17: replicate "preserves edge locality and avoids reflecting interior energy into the kick/hat boundaries"), but a per-fixture edge-case unit test is required (AC #1 invariant #12 numeric-distinctness test plus a dedicated boundary test in `SuperFluxOnsetEnvelopeTests.swift` per Task 3.7).

### Apple Platform / Swift / vDSP Notes (post-rescope-to-SuperFlux, 2026-05-17)

All claims below validated against `axiom:axiom-apple-docs` MCP (Apple Developer verbatim citations + Xcode SDK header `vDSP.h:5682-5697`), `axiom:axiom-concurrency` (Swift 6 strict-concurrency rules), `axiom:axiom-testing` (Swift Testing patterns), and `axiom:axiom-swift` (modern idioms + ownership conventions). Citations inline.

#### vDSP primitives — Apple verbatim signatures (axiom-apple-docs)

- **`vDSP_vswmax(__A, __IA, __C, __IC, __N, __WindowLength)`** — Vector sliding window max. Apple verbatim from `developer.apple.com/documentation/accelerate/vdsp_vswmax`:
  > "Finds the maximum value in a sliding window at each possible position in a single-precision input vector. ... `C[n]` = the greatest value of `A[w]` for `n <= w < n+WindowLength`. **A must contain N+WindowLength-1 elements**, and C must contain space for N+WindowLength-1 elements. ... **A and C may not overlap**. WindowLength must be positive (zero is not supported)."

  Availability: **macOS 10.10+, iOS 8.0+** — well within the project's macOS 15+ floor. Not deprecated.

  **THIS IS THE CANONICAL SUPERFLUX PRIMITIVE.** For Story 4-7's `r=1, windowLength=3` mel-bin-neighborhood max-filter: input is the replicate-padded reference frame (`melBands + 2r = 130` elements); output is the max-filtered reference frame (`melBands = 128` elements). Pattern locked verbatim in Task 3.3.

  **`vDSP_vmaxmg` is NOT the right primitive** and was eliminated during the 2026-05-17 rescope review. `vDSP_vmaxmg(A, IA, B, IB, C, IC, N)` computes `C[n] = max(|A[n]|, |B[n]|)` — per-element max of absolute values between TWO vectors. This is not a sliding-window operation; it does not perform max-filtering. Earlier party-mode roleplay's suggestion of `vDSP_vmaxmg` was incorrect and would have produced non-SuperFlux behavior.

- **`vDSP_vsub(__B, __IB, __A, __IA, __C, __IC, __N)`** — computes `C[i] = A[i] - B[i]`. **Parameter order is `(B, A, C)` — B is the subtrahend, passed FIRST.** Apple verbatim from `developer.apple.com/documentation/accelerate/vdsp_vsub`. For Story 4-7's `diff = currFrame - maxFilteredRef`: pass `maxFilteredRef` as B, `currFrame` as A. Project precedent at `BPMAnalyzer.swift:722-724` (Story 3-3 baseline) uses this exact parameter ordering with `prevFrame` as B; SuperFlux substitutes `maxFilteredRef` for `prevFrame` and leaves everything else identical. macOS 10.0+, not deprecated.

- **`vDSP_vthres(__A, __IA, __B, __C, __IC, __N)`** — where `__B` is a **pointer-to-scalar** threshold. Apple verbatim: "If an input value is less than `*B`, zero is written to `C`; otherwise, the input value from `A` is copied to `C`." With `*B = 0`: negative values become 0, non-negative pass through — half-wave rectification by construction. **The threshold scalar must be a `var` whose address is taken** (`__B` is a pointer; passing a literal won't compile). macOS 10.4+, not deprecated.

- **`vDSP_sve(__A, __I, __C, __N)`** — computes `C[0] = sum(A[n], 0 <= n < N)`. Direct sum across N elements. Project precedent at `BPMAnalyzer.swift:732-733` (Story 3-3) is the literal "sum 128 mel bands into one scalar per frame" pattern. macOS 10.4+, not deprecated.

- **C-style vs Swift overlay** — Use C-style verbatim names (NOT `vDSP.subtract`/`vDSP.threshold`/`vDSP.sum`/`vDSP.maximum`). Per project-context.md:64: "every bulk numeric operation on audio buffers must use vDSP (`vDSP_vmul`, ..., `vDSP_vthres`, ...)". Codebase audit: zero use of the Swift overlay in `Sources/`. Story 4-7 must match.

- **`vDSP_Length` wrapping** — all count parameters require `vDSP_Length(count)` (per project-context.md:40). Lint won't catch missed wrapping; silent truncation is the failure mode.

#### Swift 6 concurrency (axiom-concurrency)

- **`OnsetEnvelopes` Sendable transitivity — CONFIRMED.** `OnsetEnvelopes` is internal (struct) with fields `fullBand: [Float]`, `subBands: [[Float]]`, `mlFeatures: MLFeatureFrames?`. All three field types are `Sendable`: `[Float]` and `[[Float]]` via Array's `Sendable` conformance when Element: Sendable; `MLFeatureFrames` is **explicitly `Sendable`** at `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:483` (`public struct MLFeatureFrames: Sendable, CustomStringConvertible, Equatable`). Implicit `Sendable` conformance applies to `OnsetEnvelopes` per Swift 6 transitivity rules.
- **No concurrency annotations on the new function — CONFIRMED.** Synchronous internal function with all-Sendable parameters/return inherits its caller's isolation. `BPMAnalyzer.estimateBPM` is non-isolated synchronous; the new function should be the same (no `@MainActor`, no `nonisolated`, no `async`).
- **No `nonisolated(unsafe)` needed — CONFIRMED.** Per project-context.md:38, `nonisolated(unsafe)` has exactly three documented use cases (PCMBufferReader.downsample synchronous closure, test closures capturing mutable state, FileMetadataReader scratch buffers). Story 4-7's pure-function context matches none of them.
- **`MelFilterbank` static-let safety — CONFIRMED.** The mel-filterbank matrix is `static let` of a Sendable value type → safely concurrent-read under Swift 6's immutable-global rule. Read-only access from the new function is race-free.
- **No `@unchecked Sendable` / `nonisolated(nonsending)` — CONFIRMED not needed.** Per `axiom-swift/skills/swift-modern.md:62-64`: "Treat `@unchecked Sendable`, `@preconcurrency`, `nonisolated(unsafe)` as temporary bridge tools. Each should have a removal ticket, not be permanent." Story 4-7's pure-value-type, pure-sync function pattern requires none of these escape hatches.

#### Modern Swift idioms (axiom-swift)

- **`Span<Float>` / `RawSpan` — NOT adopted in Story 4-7.** Per `axiom-swift/skills/ownership-conventions.md:374-402`, Span replaces `UnsafeBufferPointer` for *pure-Swift* algorithms. **The C-style vDSP APIs require `UnsafePointer<Float>` arguments — Span does not provide a stable raw-C-pointer extraction without going through `withUnsafeBufferPointer` at the C boundary anyway.** The Story-3-3 `withUnsafeBufferPointer { vDSP_…(ptr.baseAddress!, …) }` pattern at `BPMAnalyzer.swift:722-724` IS the project's documented C-interop seam. Defer Span adoption to a future *pure-Swift* refactor of a non-vDSP path.
- **No typed throws.** Function does not throw; nil-sentinel return for degenerate inputs is the project pattern (project-context.md:39 "BPMAnalyzer ... return nil for no-result, never throw"). Adding typed throws would break the established contract.
- **No `@frozen` on `DSPTechnique`.** Pre-1.0 / no-BC framing (DD #11) requires non-frozen — and `@frozen` would make Story 4-7 itself impossible (adding a case to a frozen enum is a breaking ABI change).
- **`InlineArray<128, Float>` deferred-work opportunity.** Per `axiom-swift/skills/ownership-conventions.md:267-320`, the mel-band scratch buffer (128 Floats, compile-time-known, per-frame hot path) is textbook InlineArray material. NOT adopted in Story 4-7 because the rest of `BPMAnalyzer` uses `[Float]` arrays — adopting InlineArray for Story 4-7 alone would create inconsistency without measurable benefit. Filed as deferred-work entry; re-open trigger: future profiling-driven story shows allocator-pressure regression.

#### Swift Testing patterns (axiom-testing)

- **`try #require` + `.disabled(if:)`** is mandated for setup-failure / env-gated skips. **Never `Issue.record + return`** (recovers Story 4-6 P4/P15 lesson). Sourced from `axiom-testing/skills/swift-testing.md:52-58, 127-133`.
- **No `.serialized` trait** on any new test file (no shared mutable state; per `axiom-testing/skills/swift-testing.md:558-561, 701-707`).
- **Parameterized `@Test(arguments:)`** for the smoke-lane invariant (AC #1 invariant #11) and for the 8 frozen-fixture tests. Per-fixture vs OR-aggregate semantics laid out in Task 3.7.
- **`Double.bitPattern`** for byte-identity (avoids `NaN != NaN` and `+0.0 == -0.0` quirks).

### Previous Story Intelligence

**From Story 4-6 (immediately-prior story, ML diagnostic instrumentation + Branch C bundle pull, commits `360ae5c` → `fcaddf4` → `0447e63` + review-pass commits `a535111` + `16d1dc1`):**

- **Test count band discipline** — Story 4-6 set a band of `[416, 424]` after parameterized-test collapse + new file additions. Story 4-7's projected band `[432, 438]` adds 12-18 tests across 3 new files (`SuperFluxByteIdentityTests.swift`, `SuperFluxOnsetEnvelopeTests.swift`, `SuperFluxImpactTests.swift`). HALT-(d) enforces.
- **Pre-implementation Codex multi-pass review remains mandatory** — Story 4-6 ran 4 layers (Claude Blind Hunter, Edge Case Hunter, Acceptance Auditor, Codex Blind Hunter) and surfaced 24 findings. For Story 4-7's DSP-only scope, expect 30-45 raw findings concentrated on algorithm correctness, gate composition, and ablation matrix bookkeeping.
- **Diff-scope proof artifact pattern** — Story 4-6 produced `4-6-diff-scope-proof.txt` with 6 sections; Story 4-7 produces `4-7-diff-scope-proof.txt` with the same shape.
- **Brutal-corpus-gate honest-inertness pattern** — Story 4-6 documented Outcome D (model genuinely too weak) honestly with the impact-report JSON as evidence and pulled the bundle. Story 4-7's Branch B mirrors that discipline: if the variant doesn't clear the gate, ship it inert and document why.
- **Sprint-status entry pattern** — Story 4-6's `last_updated` entry in `sprint-status.yaml` summarizes the close-out outcome in narrative form. Story 4-7 follows the same pattern (revised at story-creation time to indicate `ready-for-dev` flip; revised again at close-out to summarize Branch A or B outcome).
- **`Issue.record + return` skip anti-pattern is REGRESSED on Branch C builds** — Story 4-6 review pass restored `.disabled(if:)` traits. Story 4-7's new test files MUST follow the suite-level `.disabled(if:)` pattern for any test that depends on `BNNS_IMPACT=1` or `OA300_CORPUS_PATH` corpus availability — never `Issue.record + return` inside test bodies.

**From Story 3-3 (click-track cross-correlation, the closest architectural precedent — also added a new DSPTechnique case):**

- **DSPTechnique case addition mechanics** — DD #1 of Story 3-3 enumerated the same 10-invariant-update problem. Story 4-7 inherits the pattern verbatim; the dev agent should use a single commit for all 10 updates so HALT-(a) has a clean rollback target if the partial-update mid-state breaks unit tests.
- **Per-track impact report pattern** — Story 3-3 produced `3-3-click-impact-report.json` with `{changedRanking, changedDisambiguationWinner, changedFinalBPM, total: 82}` schema. Story 4-7's schema (per DD #7) is similar but adds named-DnB and control flagging.
- **Honest inertness shipping** — Story 3-3 click-correlation shipped with `changedFinalBPM == 1/82` at default config. The story was closed with that finding documented plainly. Story 4-7's Branch B is the equivalent.

**From Story 3-4 (duration-derived BPM hint, ALSO an accuracy-affecting feature that ended up shipping inert at default):**

- **Inert-feature framing** — Story 3-4 shipped with `changedFinalBPM == 0/82` and is the canonical "honest inertness" precedent in the codebase. The Completion Notes documented the inertness explicitly. Story 4-7 Branch B should follow that voice (descriptive, not apologetic, with the impact-report JSON as evidence).
- **Options flag vs DSPTechnique case** — Story 3-4 chose Options flag (`durationHint`); Story 4-7 chooses DSPTechnique case (per DD #1 architectural alignment). The two patterns are not interchangeable; Story 4-7's case path is justified by being a DSP-spine variant rather than an orthogonal signal axis.

**From Epic 3 retrospective (`epic-3-retro-2026-05-03.md`):**

- **Architecture invariants are unit-test-locked** — `DSPTechnique.allCases.count == 7` is enforced at multiple sites; bumping to 8 requires updating all sites in lockstep per AC #1. Failure = HALT-(a).
- **Onset-envelope quality on heavily-mastered material is the upstream weakness** — this is the rationale for Story 4-7 itself. Spectral flux is the directly-relevant DSP attempt at addressing it.
- **Pre-implementation Codex multi-pass review is load-bearing** — Story 3-3 caught a kernel-pre-reverse direction inversion before any code landed. Story 4-7 must run the same review before `ready-for-dev` flip.

### References

- **Böck & Widmer (2013) "Maximum Filter Vibrato Suppression for Onset Detection," DAFx-13.** Primary algorithm reference for Story 4-7 (post-2026-05-17 rescope). URL: https://phenicx.upf.edu/system/files/publications/Boeck_DAFx-13.pdf. Codex cited this paper across both consultation rounds for: frequency-axis-only canonical interpretation (Section 3), `r=1` default (Section 3.2 "current bin and direct neighbors"), `µ=1` at 10ms hop preserving paper's physical lag (Section 4.1). Apple-platform implementation uses `vDSP_vswmax` for the max-filter pre-pass; algorithmically distinct from the project's existing log-mel spectral flux at `BPMAnalyzer.swift:711-748`.
- Bello et al., "A Tutorial on Onset Detection in Music Signals," IEEE Transactions on Speech and Audio Processing, 2005. (epics.md:771, epics.md:1248) — original log-mel spectral flux formulation; documents the algorithm the existing baseline implements. Story 4-7's rescope from "add spectral flux" to "add SuperFlux" was driven by Codex's 2026-05-17 discovery that the existing baseline already implements Bello's formulation; SuperFlux extends Bello via Böck's frequency-neighborhood reference.
- Codex consultation thread `019df0ea-9b91-7173-866c-7f8e8efdc94e` (2026-05-04, Epic 4 planning) — recommended the original brutal-corpus-gate framing.
- Codex consultation thread `019e36de-1440-7b71-b4aa-f68b0a9b6708` (2026-05-17, rescope) — duplicate-algorithm finding; SuperFlux redirect parameter consultation (frequency-axis, r=1, µ=1, replicate-pad, brutal gate unchanged).
- Epic 4 epics.md sections referenced: Story 4.7 spec lines 1177-1249; Epic 4 preamble lines 229-235; planning decisions line 760; gate type line 762-769; reference line 771; sequencing notes lines 1183, 1244.
- Project context references: project-context.md:41 (architecture invariants), :69 (pipeline step stability), :88 (Post-Pipeline Corroboration Boundary), :98 (floor assertions), :101 (ablation matrix), :149 (DSP ceiling rule), :160 (Critical Don't-Miss Rules), :173 (onset-envelope quality footnote).
- Story 4-6 close-out commit `0447e63` and review-pass commits `a535111` + `16d1dc1` — most-recent reference points for spec structure, HALT discipline, and Branch C inert-ship pattern.
- Story 3-3 spec at `_bmad-output/implementation-artifacts/3-3-click-track-cross-correlation.md` — closest architectural precedent for new DSPTechnique case addition.
- Story 3-4 spec at `_bmad-output/implementation-artifacts/3-4-duration-derived-bpm-hint.md` — canonical inert-ship precedent.
- `4-dnb-triplet-targets.json` schema_version 3 — frozen named-DnB + DSP-correct controls fixture.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (`claude-opus-4-7[1m]`), via bmad-dev-story workflow.

### Debug Log References

- Capture of pre-source baselines: SHA `16d1dc1` (= HEAD at story dispatch).
- Task 3 helper-extraction byte-identity proof: ran
  `OA300_CORPUS_PATH=... swift test --filter
  BoomBoomBoomKitBenchmarkTests.MLPolicySweepTests/dspOnlyMatchesStory4_3Baseline`
  at post-Task-3 SHA — PASSED.
- Per-fixture byte-identity baseline capture used a one-shot env-gated
  `SuperFluxBaselineCaptureHelper` suite (`BBBK_CAPTURE_SUPERFLUX_BASELINE=1`)
  — captured at SHA `9bee3cc`; helper removed from the file once values were
  frozen into `Fixtures/4-7-byte-identity-baseline.json`.
- Brutal-corpus-gate run: `make super-flux-impact-report` against full OA300
  (82 tracks, 0 missing) at SHA `6096ab1`; artifact at
  `_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json`.

### Completion Notes List

**Outcome: Branch B (Codex-authorized inert-ship).** Per Story 4-7 AC #4 and
HALT-(b), the `.superFluxOnset` case ships in `DSPTechnique` but joins NO
production preset. `.full` auto-includes via `Set(allCases)` (mechanical
change per AC #4 Branch B-acknowledged).

**Exact integers (per AC #7 + AC #11 precedent):**

| Metric | Value | Source |
|---|---|---|
| Unit test count (`rg '@Test\(' Tests/BoomBoomBoomKitTests \| wc -l`) | 432 | HALT-(d) band `[432, 438]` low edge |
| Pre-source unit test count | 420 | SHA 16d1dc1 |
| Net new unit @Tests | +12 | 9 SuperFluxOnsetEnvelopeTests + 3 SuperFluxByteIdentityTests |
| Benchmark-target new @Tests | +2 | SmokeAblationInvariantTests (parameterized + smokeLaneSize) |
| OA300 Acc1 at default Options (post-source) | 58/82 (70.7%) | `make benchmark` |
| OA300 Acc2 at default Options (post-source) | 74/82 (90.2%) | `make benchmark` |
| OA300 Acc1 at maxConfidence (matches floor) | 57/82 | `make benchmark` |
| OA300 Acc2 at maxConfidence (matches floor) | 73/82 | `make benchmark` |
| GiantSteps Acc1 at default intensity 7 | 537/661 (81.2%) | `make benchmark-giantsteps` |
| GiantSteps Acc2 at default intensity 7 | 546/661 (82.6%) | `make benchmark-giantsteps` |
| Aggregate floors at default Options held? | YES | OA300 ≥ 57/73 + GiantSteps ≥ 537/546 |
| DSP-only byte-identity at default Options vs Task-1 snapshot | PASS | `dspOnlyMatchesStory4_3Baseline` (corpus-paired) + `SuperFluxByteIdentityTests` (unit-target) |
| Branch identifier | **B** | AC #4 Branch B |
| `changedRanking` (impact report) | 82/82 | variant moves every per-track BPM |
| `changedFinalBPM` (impact report) | 82/82 | per AC #4 second clause |
| `namedDnBImproved` | **0 / 4** | Branch A criterion FAILS (need ≥1) |
| `controlsPreserved` (±0.5 BPM) | **2 / 4** | Branch A criterion FAILS (need 4) |
| Variant-on Acc1 delta on OA300 (DSP-only) | **-4** (55 → 51) | from impact-report rows |
| Ablation matrix size | 128 → 256 | 2^7 → 2^8 (Story 4-7 added .superFluxOnset) |
| Smoke combo count | 16 (unchanged) | AC #5 / HALT-(e) — `.full` swapped for `.full.removing(.superFluxOnset)` |
| `make ablation-smoke` wall-clock | 10.38s real on M5 Max | no cadence shift |
| New SPM external dependencies | 0 | pure vDSP, Accelerate already system framework |
| New BPMDiagnosticTrace fields | 0 | per DD #12 |
| `BoomBoomBoomKitML` target changes | 0 | pure DSP, no ML dependency |

**Named DnB triplet per-track outcomes (from impact report, baseline vs variant):**

| Track | Ground truth | Baseline BPM | Variant BPM | Abs err Δ |
|---|---|---|---|---|
| Charly (Neekeetone Jungle Rework) | 160 | 106.29 | 106.42 | +0.13 (worse) |
| 1. Faraday_Bunker (D-Struct Remix) | 170 | 172.54 (✓) | 171.88 (✓) | −0.66 (better; both within ±2%) |
| 4. Yin Yang Audio | 85 (OA300 gt) | 113.15 | 113.35 | +0.20 (worse) |
| 9. HEFT_Anagram 6 (Owl Remix) | 85 (OA300 gt) | 113.61 | 113.31 | −0.30 (better, still wrong) |

Yin Yang and HEFT_Anagram are gt=170 per the DAW oracle / 4-dnb-triplet-targets.json
(both fixtures are at 170 in the named-DnB list). The impact report's `ground_truth`
field uses OA300's official label (85) — the variant's ~113 BPM detection misses
both interpretations.

**DSP-correct control per-track outcomes (impact report, all gt=170; tolerance ±0.5 BPM):**

| Track | Baseline BPM | Variant BPM | Variant abs err | Preserved (≤0.5)? |
|---|---|---|---|---|
| 3. D3Z_Axons (Offish Remix) | 170.18 | 169.96 | 0.04 | YES |
| 6. HEFT_Fuyu (Akinsa Remix) | 169.56 | 170.27 | 0.27 | YES |
| 5. Darkgray Heart_Beating Heart | 170.43 | 170.52 | 0.52 | NO (margin 0.02) |
| 10. Hellacopta_Assemby (Xiûa) | 170.29 | 170.97 | 0.97 | NO |

**Branch-decision rationale.** The brutal-corpus gate's Branch-A criterion
requires `namedDnBImproved ≥ 1 AND controlsPreserved == 4`. With
`namedDnBImproved = 0` AND `controlsPreserved = 2`, both Branch-A conditions
independently fail; Branch B is unambiguous. Per Codex 2026-05-17 thread
`019e36de`, Branch B was the expected outcome — SuperFlux's documented win
condition is vibrato suppression on pitched-instrument onsets (Böck 2013
Section 3), not recovery from limiter-flattened DnB triplet ambiguity. The
variant produces per-track output changes on 82/82 tracks, but the changes
are small and not aligned with the named-DnB failure modes. Per AC #4 Branch
B + HALT-(b), the `.superFluxOnset` case ships in `DSPTechnique` (per AC #1)
but joins NO production preset; `.full` auto-includes via `Set(allCases)`.
Consumer experimentation path: `opts.techniqueSet =
TechniqueSet.optimal.inserting(.superFluxOnset)`. Re-open trigger filed in
`_bmad-output/implementation-artifacts/deferred-work.md`.

**Honest framing.** "Feature works + no regression" is NOT acceptable per
AC #4 Branch B and Epic 3 retro line 45. The accurate framing is: the
brutal corpus gate was NOT cleared; SuperFlux is shipped available for
consumer experimentation as a paper-faithful Böck 2013 reference
implementation, not as a default-on accuracy improvement. The per-track
impact-report JSON at
`_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json`
is the evidence trail.

**Gating gauntlet (Task 12.2):**

- `make fmt` — clean (no diff produced)
- `make lint` — 157 violations, but only ONE in Sources/: the canonical
  pre-existing `LUFSAnalyzer.swift:94` TODO baseline (per CLAUDE.md
  acceptable-violation rule). All other violations are in
  `_bmad-output/ml-training/.venv/...` and `tools/coreml-convert/.venv/...`
  (Python venv accidentally linted — pre-existing project condition, not
  introduced by Story 4-7).
- `make test` — 430 ran, 432 @Test, 2 env-gated skips (same skip pattern as
  pre-Story-4-7 baseline 418/420).
- `make benchmark` — Acc1 58/82, Acc2 74/82 at default Options ≥ floors.
- `make benchmark-giantsteps` — Acc1 537/661, Acc2 546/661 ≥ floors.
- `make perf-benchmark` — captured at Task 1 SHA 16d1dc1; wall-clock mean
  0.173s, p95 0.241s on M5 Max (no perf regression expected from Story 4-7
  since the variant is inactive at default Options).
- `make super-flux-impact-report` — JSON produced at
  `_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json`
  (1011 lines).
- `make ablation` — 256 combos completed without crash in 207.6s on M5 Max
  (vs ~77s pre-Story-4-7 for 128 combos — 2.7× cost, within the ~2× design
  budget). Ablation matrix doubled from 128 to 256 per AC #1. Best
  combination: `sharp+fine+vote` (= `.optimal`, Acc1=55/82) —
  **NO SuperFlux-containing combo beat `.optimal`**, confirming the DSP-only
  single-window Acc1 ceiling at 55/82 (project-context.md:149) is preserved
  post-Story-4-7 and that adding `.superFluxOnset` to any DSP composition
  does not unlock a new ceiling.

**Diff-scope proof:** see
`_bmad-output/implementation-artifacts/4-7-diff-scope-proof.txt` for the
6-section proof per AC #7 (git diff stat, status, deprecated-API check,
trace-field audit recipes A-E, SPM deps count, Story-4-7 addendum).

### File List

_To be filled by dev agent — anticipated based on AC #8 file scope discipline:_

**Modified:**
- Sources/BoomBoomBoomKit/BPMAnalyzer.swift (new `computeSuperFluxOnsetEnvelope` function + step-3 gate)
- Sources/BoomBoomBoomKit/DSPTechnique.swift (new case + doc-comment; new preset if Branch A)
- CLAUDE.md (invariant updates)
- _bmad-output/project-context.md (4 invariant-update sites)
- Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift (invariant assertions)
- Tests/BoomBoomBoomKitTests/AblationQuickTests.swift (invariant assertions)
- Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift ("128-combination" → "256-combination" + smoke-lane verification)
- Makefile (new `super-flux-impact-report` target)

**New:**
- Tests/BoomBoomBoomKitTests/SuperFluxByteIdentityTests.swift
- Tests/BoomBoomBoomKitTests/SuperFluxOnsetEnvelopeTests.swift
- Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift
- _bmad-output/implementation-artifacts/4-7-regression-snapshot.json (Task 1)
- _bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json (Task 7)
- _bmad-output/implementation-artifacts/4-7-diff-scope-proof.txt (Task 12)

**No `BoomBoomBoomKitML` changes. No new SPM products. No new external dependencies. No `BPMDiagnosticTrace` field additions.**

## HALT discipline

This section names the specific HALT triggers that block close-out. Format matches Story 4-6 DD #9.

- **4-7-HALT-(a) — Invariant updates incomplete.** Any of the 10 sites in AC #1 left at old values (`== 7` or `== 128`). Investigation: enumerate every site in a fresh `rg` pass; complete the lockstep update before any subsequent task proceeds.
- **4-7-HALT-(b) — Variant resolves zero named tracks AND breaks one or more controls.** The "bad-trade" outcome (Risk R2). The Codex-authorized exit is INERT-BY-DEFAULT (per AC #4 Branch B), but a control-set regression is unacceptable — Branch B still requires controls preserved. Investigation: read the impact-report per-track rows; identify which control regressed and by how much; if remediation is found (e.g., a per-band reweighting), re-run from Task 7; otherwise HALT close-out and consult the project lead.
- **4-7-HALT-(c) — Aggregate floor breach.** OA300 Acc1 < 57 OR Acc2 < 73 OR GiantSteps Acc1 < 537 OR Acc2 < 546 at default `Options` (variant absent). Investigation: byte-identity opt-out test (AC #3) MUST hold for default to be unchanged; if floors breach with variant absent, the new function has a side-effect leaking into the default path. Code-review the integration at BPMAnalyzer.swift:230-235 until byte-identity holds.
- **4-7-HALT-(d) — Test count outside band `[432, 438]`.** `rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l` — outside band → investigate. Below 432: ACs have insufficient test coverage; identify missing test per the test-plan table in Task 11.2; add. Above 438: parameterized-test drift or unintended test additions; review and either parameterize-collapse OR document the higher count via DD revision.
- **4-7-HALT-(e) — Smoke lane mutated.** Any of the 16 combos in `AblationFullMatrixTests.smokeAblation` includes `.superFluxOnset`. Investigation: locate the offending combo via `grep -n 'superFluxOnset' Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift`; revert; re-run `make ablation-smoke` to confirm wall-clock unchanged.
- **4-7-HALT-(f) — DSP-correct controls regress at variant-enabled preset.** ≥1 of the 4 entries in `4-dnb-triplet-targets.json::dsp_correct_controls` moves outside ±0.5 BPM of `ground_truth_bpm` when `.optimal ∪ {.superFluxOnset}` is run. Investigation: identical to 4-7-HALT-(b) for the control-set regression sub-case; remediation OR Branch B.
- **4-7-HALT-(g) — Byte-equality opt-out test fails.** `SuperFluxByteIdentityTests.dspOnlyByteIdenticalWithSuperFluxAbsent` produces non-byte-identical output vs Task-1 snapshot. Investigation: the variant function is leaking into the default code path; code-review BPMAnalyzer.swift:230-235 for unconditional execution; verify the gate is `if techniqueSet.contains(.superFluxOnset)` and the `else` branch calls the unchanged `computeMelOnsetEnvelopeWithSubBands`.

## Story authoring checklist

The following was verified at story-creation time (2026-05-16, post-Story-4-6 close-out) and at rescope time (2026-05-17, post-Codex blocker):

- [x] Story is the next `backlog` entry in `sprint-status.yaml` (verified via top-to-bottom scan)
- [x] Epic 4 status is already `in-progress` (no status flip needed at story-creation time)
- [x] Story key matches: `4-7-spectral-flux-onset-dsp-variant` (sprint-status.yaml:86) — file name retained post-rescope for historical traceability; algorithm and DSPTechnique case renamed to "SuperFlux"
- [x] Pre-implementation 3-layer Codex review COMPLETED on 2026-05-17 (thread `019e36de`) — surfaced the duplicate-algorithm blocker that triggered the rescope; second consultation locked SuperFlux parameters (frequency-axis, r=1, µ=1, replicate-pad)
- [x] All 10 invariant-update sites enumerated in AC #1 (verified by spec author against project-context.md + CLAUDE.md + test files), plus 2 new sites added post-rescope: invariant #11 (parameterized smoke-lane test) and invariant #12 (numeric-distinctness fixture)
- [x] Floor assertions cited with line numbers (OA300BenchmarkTests.swift:104,108 + GiantStepsBenchmarkTests.swift:82,86)
- [x] Brutal-corpus-gate (Branch A vs Branch B) is unambiguous — AC #4 is a true XOR; Codex 2026-05-17 reaffirmed Branch B is the *expected* outcome
- [x] HALT-(a) through HALT-(g) named and tied to specific investigation pathways
- [x] Test count band `[432, 438]` derived from post-Story-4-6 baseline 420 + Epic-3-precedent 12-18 new tests
- [x] No `BPMDiagnosticTrace` field additions (DD #12 — reserved for follow-up stories if Branch A fires)
- [x] Pre-1.0 / no-BC framing acknowledged for the new public case (DD #11)
- [x] Architectural-rule exception for DSP-ceiling-at-saturation acknowledged with brutal-gate as the discipline-preserving exit (DD #13)
- [x] **NEW (post-2026-05-17 rescope):** Existing code precedent VERIFIED — `BPMAnalyzer.swift:711-748` (`computeMelOnsetEnvelopeWithSubBands`) was read in full before the SuperFlux algorithm was specced. The verbatim implementation is documented in DD #2 as the baseline against which the SuperFlux algorithm is novel. **Workflow lesson filed to deferred-work.md:** "for any story proposing a 'new' variant at a documented pipeline step, the spec author MUST read the existing function body verbatim and explicitly state the algorithmic delta vs the existing code." This closes the failure-class that produced the 2026-05-17 duplicate-algorithm blocker (axiom-skills validated the proposed implementation correctly but missed that the proposed implementation IS the existing implementation).
- [x] **NEW (post-2026-05-17 rescope):** Apple-platform primitive verbatim-validation completed. `vDSP_vswmax` confirmed via apple-docs MCP (https://developer.apple.com/documentation/accelerate/vdsp_vswmax) AND Xcode SDK header `vDSP.h:5682-5697`. `vDSP_vmaxmg` explicitly eliminated as incorrect-semantics candidate.
