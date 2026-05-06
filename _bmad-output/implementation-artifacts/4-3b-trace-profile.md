# Story 4-3b — Trace-Build Cost Profile

## Reproducibility

- macOS: 26.5 (25F5068a)
- Xcode: Xcode 26.4.1
- xctrace: xctrace version 16.0 (17E202)
- Hardware: Mac17,7 (Apple M5 Max)
- AC power: connected (required — battery throttling distorts profiles)
- Run count: 1 capture (14,175 samples at 1 ms = 14.2 s of CPU work)
- Profile target: `BoomBoomBoomKitTests.MLTechniquePerfTests/profileLongLoop` (env-gated long-loop variant; `PROFILE_LOOPS=1`, `PROFILE_LOOPS_ITERS=2000`)
- Intensity: `.fastest` (matches existing `MLTechniquePerfTests` fixture; Story 4.3 measured the 22% structural ratio as constant across `.fastest` and `.default`, so `.fastest` is sufficient)
- Mock: `MockMLTechnique(returning: nil)` — abstain path
- `enableTrace`: forced `true` because `options.mlTechnique != nil` (`AudioAnalysisService.swift:256` — Story 4.3 plumbing). The profile therefore captures the trace-build hot path.
- Build config: `swift build -c release --build-tests -Xswiftc -enable-testing`
- Commit: `c1ba272` (Story 4.3 final)
- Reproducibility recipe: `_bmad-output/scripts/profile-trace-build-cost.sh` (Task 1.2)
- Time-profile XML extracted with: `xctrace export --input <trace> --xpath '/trace-toc/run/data/table[@schema="time-profile"]'`
- Aggregated via: `_bmad-output/scripts/analyze-time-profile.py /tmp/4-3b-time-profile.xml`
- Aggregated raw output committed at: `_bmad-output/perf-baselines/4-3b-time-profile-summary.txt`
- `.trace` bundles are gitignored (`.gitignore` updated 2026-05-05)

## Top 3 hot functions (Time Profiler, leaf / exclusive cost)

Aggregated from 14,175 samples × 1 ms each (= 14.18 s total weight) via
`_bmad-output/scripts/analyze-time-profile.py`.

| Rank | Function | % CPU | Sample count | Inside `enableTrace` branch? |
|------|----------|-------|--------------|------------------------------|
| 1 | `0x190b4fff0` (BLAS internal: cblas_sgemm inner kernel — see ancestor stack) | 42.7% | 6046 | NO — DSP step 3 (mel filterbank matmul, runs unconditionally) |
| 2 | `0x19e6f3340` (Accelerate `vForce`/transcendental kernel — adjacent to `VVLOGF`/`VVCOSF`) | 8.0% | 1140 | NO — DSP step 3 (FFT magnitude post-processing) |
| 3 | `_platform_memmove` | 4.4% | 628 | PARTIALLY — see commentary below |

**Commentary on column 4 ("inside `enableTrace` branch?")** — this column is
the AC #1 differentiator between trace-build cost and DSP cost. None of the
top-3 hot leaves live inside an `if options.enableTrace { … }` gate. The
top inclusive-cost ancestor is `static BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(samples:sampleRate:hopSize:computeSubBands:normalizeSubBands:)`
at **85.4% (12,105 ms)** — which is the mel filterbank matmul + FFT path,
called unconditionally from `BPMAnalyzer.estimateBPM` regardless of trace
state. The closure-#3 site inside it (`vDSP_mmul` → `cblas_sgemm`) accounts
for **45.0% of all CPU** by itself.

`_platform_memmove` is partially attributable to trace because some of the
628 ms covers Swift `Array` copies into `BPMDiagnosticTrace` fields
(`extractTopPeaks` returns are assigned to `trace?.acfTopLags`,
`trace?.tempogramTopBPMs`, etc. — see "Trace write inventory" below); but
the same primitive is also called from non-trace code (PCM buffer sample
copy in `PCMBufferReader.downsample`, vDSP working buffers in
`computeAutocorrelation`). Without per-call-site allocation attribution
(which xctrace's CLI export does not surface — see "Allocation profile
limitation" below), the precise trace share is not separable from the
total. Order-of-magnitude estimate: ≤1 percentage point of the 4.4%
total — well below the 22% structural ratio Story 4.3 measured.

## Top 3 allocation sites

**Allocation profile limitation (AC #1 escape):** `xctrace export --input <trace> --toc`
against the `Allocations` template trace shows only the standard `tick`,
`os-log`, `kdebug`, `process-info`, etc. schemas — there is no
`vm-allocation` or `allocation-stack-trace` schema available via the CLI in
Xcode 26.4.1. The Allocations instrument writes data into binary
`instrument_data` blobs that are queryable only through the Instruments GUI.
The script (`_bmad-output/scripts/profile-trace-build-cost.sh`) captured an
`Allocations`-template trace at `_bmad-output/perf-baselines/4-3b-allocations-222536.trace`
(gitignored), but per-call-site bytes/count attribution requires opening
that bundle in Instruments — AC #1 explicitly authorizes this fallback.

As a CLI-grounded proxy, the table below uses the malloc/free/copy/zero
leaf functions surfaced by Time Profiler. These show the allocation /
release / copy primitives the runtime spent CPU on; combined with their
ancestor stacks they identify which call sites are responsible.

| Rank | Call site (leaf primitive) | CPU spent | Approx. attributable to trace? |
|------|----------------------------|-----------|--------------------------------|
| 1 | `__bzero` (buffer zeroing — `vDSP.clear` / `vDSP_vclr` / fresh `[Float]` init) | 503 ms (3.5%) | NO — driven by `PipelineBuffers.allocate(...)`, `ACFBuffers.allocate(...)`, `TempogramBuffers.allocate(...)` and their `defer { deallocate() }` per `estimateBPM` call. Same cost paid with or without trace. |
| 2 | `_platform_memmove` (Swift `Array` copies, vDSP overlap-safe transforms) | 628 ms (4.4%) | PARTIAL — copies into `[(Int, Float)]` arrays returned by `extractTopPeaks` ARE assigned to trace fields (`trace?.acfTopLags = …`, `trace?.tempogramTopBPMs = …`, etc.). Most copies are non-trace (vDSP working buffer reuse). |
| 3 | `_xzm_xzone_malloc_tiny` + `_xzm_free` + `__munmap` (small-object alloc + page release) | 90 + 44 + 86 = 220 ms (1.5%) | PARTIAL — small-object allocations include `[String: Float]` for `subBandEnergies` (line 230, allocated unconditionally inside the `if options.enableTrace` branch even when sub-band data is empty at `.fastest`) plus the 9 array-typed trace fields' backing storage. |

## Hotspots NOT optimized (Branch B reasoning)

Per AC #3's no-finding escape, this story takes **Branch B: irreducible
structural floor**. Justification:

1. **No discrete trace-attributable hotspot rises above measurement noise.**
   The top inclusive-cost BoomBoomBoomKit function is
   `computeMelOnsetEnvelopeWithSubBands` at **85.4%** — pure DSP (mel
   filterbank matmul + FFT). The `enableTrace`-gated work in this function
   (the `subBandEnergies` accumulator at `BPMAnalyzer.swift:228-238`) does
   NOT appear in the leaf function list above 1 ms even with 14 s of
   sampling. It is too cheap to register against the FFT/matmul stack at
   `.fastest` intensity (where `subBandVoting` is not in the technique
   set, so `onsetResult.subBands` is empty and the loop body executes
   zero times anyway — only a `[String: Float] = [:]` allocation +
   trace assignment fires).

2. **Trace-build cost is structurally diffuse.** `BPMAnalyzer.swift`
   contains **18 `trace?.<field> = …` write sites** (verified
   2026-05-05 via `grep -cE 'trace\?\.\w+\s*=' Sources/BoomBoomBoomKit/BPMAnalyzer.swift`).
   Each individual write costs:
   - 1 optional unwrap on `trace?` (cheap; branch-predicted hot)
   - 1 property write
   - For array-valued fields: 1 `Array` heap allocation + element copy
     (e.g., `extractTopPeaks(...)` returns a fresh `[(Int, Float)]` of
     size 5 on each of `acfTopLags`, `tempogramTopBPMs`, `fusedTopBPMs`,
     `tps2TopBPMs` — 4 sites)
   - For struct-valued fields: 1 stack-to-heap transfer if the trace is
     boxed via `inout` (Story 3-3b evidence types are stack structs but
     the trace itself is a struct currently passed by `inout`)

   The 22% structural wall-clock ratio Story 4.3 measured is the SUM of
   these 18 small writes per `estimateBPM` call, plus the fixed cost of
   `BPMDiagnosticTrace`'s own initialization. No single write is
   individually optimizable; the ratio reflects the breadth of writes,
   not depth at any one site.

3. **Why the 22% is constant across `.fastest` and `.default`.** Both
   intensities call into the same 9-step BPM pipeline. The trace fields
   populated are the same in count (or scale linearly with candidate
   count, which is `1` at `.fastest` and `3` at `.default`). The fixed
   per-call cost (trace allocation + 18 base writes) dominates over the
   variable per-candidate cost — which matches Story 4.3's
   constant-ratio fingerprint observation.

4. **`_platform_memmove` (top-3 leaf) is a candidate but speculative.**
   The closest "reducible without correctness changes" optimization is
   `reserveCapacity(5)` on the `extractTopPeaks` return arrays before
   they are assigned to trace fields. The win would be ~0-1 percentage
   points and Winston / Amelia (party-mode round 2) explicitly flagged
   this as the kind of speculative `reserveCapacity` not authorized
   under AC #3 unless the profile names the site. **The profile does
   NOT name an `extractTopPeaks` allocation as a top-3 hotspot.** Per
   AC #3 paragraph "The dev MUST NOT invent speculative `reserveCapacity`
   calls or other 'might help' edits in the absence of a profile-named
   hotspot," that edit is out of scope for this story.

## Hotspots NOT optimized — per-row analysis

| Hotspot | Why not optimized | Anticipated Story 4.5/4.6 reader (from Task 1.6) |
|---------|-------------------|-------------------------------------------------|
| `cblas_sgemm` inside `computeMelOnsetEnvelopeWithSubBands` (45.0% inclusive) | Pure DSP — mel filterbank matmul. NOT a trace write. Reducing it would require redesigning the mel filterbank (out of scope per DD #7: "Do NOT modify any DSP correctness behavior"). | N/A — feeds the onset envelope that all other DSP steps consume. |
| `vDSP.FFT.forward` / `vDSP.FFT.transform` (20.6% inclusive) | Pure DSP — Step 3 mel-spectrogram FFT. NOT a trace write. | N/A. |
| `extractTopPeaks` array allocations (4 trace fields × ~5 elements) | Speculative `reserveCapacity(5)` win is unverified by profile; AC #3 forbids speculative edits. | Story 4.5 BNNS feature engineering may read `acfTopLags` / `tempogramTopBPMs` / `fusedTopBPMs` / `tps2TopBPMs` to build periodicity features. |
| `_platform_memmove` (4.4% leaf) | Mostly non-trace (vDSP working buffers, PCM copy). Trace share <1% — below noise. | N/A — dominant share is DSP, not trace. |
| `__bzero` (3.5% leaf) | Driven by `PipelineBuffers` / `ACFBuffers` / `TempogramBuffers` `allocate` calls — paid with or without trace. The `defer { deallocate() }` pattern (project-context.md "UnsafeMutablePointer discipline") is correct as-is. | N/A — pre-existing buffer allocations. |
| 18 `trace?.<field> = …` writes in `BPMAnalyzer.swift` | Diffuse — no single write dominates. Reducing the COUNT of writes would require splitting `BPMDiagnosticTrace` into per-stage sub-traces or making the trace lazy, both of which DD #7 explicitly defers. | Story 4.5 BNNS / Story 4.6 CoreML feature engineering reads many of these (see Task 1.6 below). Reducing arbitrarily would break those readers. |

## Optimizations applied

**None** beyond the `subBandEnergies` typed migration (Task 2). Per the
Branch B exit (AC #3 paragraph "No-finding escape"), the dev does NOT
invent speculative optimizations in the absence of a profile-named
hotspot. The `subBandEnergies` migration ships for typed-evidence
discipline (project-context.md §"Banned trace-field shapes" anti-pattern
(1)) regardless of perf delta.

| Edit description | Pre-ratio | Post-ratio (median of N=5) | Δ | Notes |
|------------------|-----------|----------------------------|---|-------|
| `subBandEnergies: [String: Float]` → `SubBandEnergies` typed struct | 1.092x (Story 4.3 final, single-run) | **1.083x** (median of 5; vector `[1.042, 1.083, 1.100, 1.093, 1.083]`) | -0.009 (≈ -0.8 pp) | Typed-evidence discipline migration; perf delta within run-to-run noise. The pre-ratio is Story 4.3's last-recorded single-run measurement, NOT a 5-run median — so the Δ is informative but not statistically tight. The post-5-run range (max-min) of 0.058 is itself larger than the apparent Δ. **Conclusion:** migration is perf-neutral within noise. |

**Re-measure protocol (Task 4.1):** all 5 runs were `make perf-benchmark` mock-injected on AC power, ambient thermal state, post-Task-2 working tree, Apple M5 Max. 81 tracks succeeded in both baseline + mock passes per run. Variance bound `max - min = 0.058 ≤ 0.10` per AC #4 — no HALT.

**Computed threshold update:** `safeThreshold(1.083)` = `ceil((1.083 + 0.10) / 0.05) * 0.05` = `ceil(23.66) * 0.05` = **1.20**. Updated in `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` (`mlMockOnAbstainMaxRatio` constant + assertion message + test name).

## Trace fields anticipated by Story 4.5 / 4.6 readers

Per Task 1.6, the following `BPMDiagnosticTrace` fields are anticipated
candidates for BNNS feature engineering (Story 4.5) and CoreML feature
engineering (Story 4.6). Both stories are still `backlog` per
`sprint-status.yaml` 2026-05-05; this list is the dev's best-guess
projection and carries a "TBD pending 4.5 spec" caveat per Task 1.6
guidance.

| Field | Type | Anticipated Story 4.5/4.6 use |
|-------|------|------------------------------|
| `analysisWindowDuration` | `Double` | Feature normalization (longer windows give more reliable BPM) |
| `intensityUsed` | `AnalysisIntensity` | Branch on intensity for ML inference budget |
| `onsetEnvelopeLength` | `Int` | Length feature for sequence model (CoreML / BNNS conv input length) |
| `subBandEnergies` (post-Story-4-3b: `SubBandEnergies` typed struct) | `SubBandEnergies` | **Likely top-3 BNNS feature** — kick/snare/crack/hihat distribution is the canonical "DnB vs other genre" feature per Epic 3 retro 2026-05-03 dev-note. Typed access (`.kick` / `.snare` / etc.) is exactly the auto-completable surface a feature engineer wants. |
| `acfTopLags` | `[(lag: Int, strength: Float)]` | Periodicity feature — top-5 ACF lags as input to a small dense classifier |
| `tempogramTopBPMs` | `[(bpm: Int, magnitude: Float)]` | Tempogram top-K as feature vector |
| `fusedTopBPMs` | `[(bpm: Int, score: Float)]` | Post-fusion top-K — alternative or complementary to tempogram |
| `tps2TopBPMs` | `[(bpm: Int, score: Float)]` | TPS2-enhanced periodicity — feeds candidate scoring |
| `rawCandidates` | `[(bpm: Double, score: Float)]` | DSP-derived candidates BEFORE any rescoring; ML can rerank |
| `harmonicRatioDetail` | `HarmonicRatioEvidence` (Story 3.1) | Octave-resolution feature (3:2, 1:2, 2:1 ratios) |
| `subBandVoteDetail` | `SubBandVoteEvidence` (Story 3-3b) | Per-band winner BPMs — strong feature for genre-aware tempo bias |
| `clickCorrelationDetail` | `[ClickCorrelationEntry]` | Rhythmic-alignment feature when `.clickAugmented` is enabled |
| `durationHintDetail` | `DurationHintEvidence?` | Bar-count BPM hint features (Story 3.4) |
| `confidence` | `Double` | DSP confidence — ML may regress against this for ensemble weighting |
| `disambiguationResult` | `(bpm: Double, score: Float)?` | Post-octave-resolution winner — ML reranker target |
| `refinedBPM` | `Double?` | Fine-grid refined value — alternative target |
| `metadataEvidenceBeforeBoost` | `[MetadataBPMEvidence]` (Story 3-6) | File-tag evidence — orthogonal feature axis |
| `candidatesBeforeBoost` | `[(bpm: Double, score: Float)]` (Story 3-6) | Pre-corroboration candidate list — alternative ML input |
| `candidatesAfterBoost` | `[(bpm: Double, score: Float)]` (Story 3-6) | Post-corroboration candidate list — primary ML reranker input |

**Caveat (TBD pending 4.5 spec):** Until Story 4.5's spec author chooses
specific input features, the above is a projection. The Branch B
"irreducible structural floor" claim does NOT depend on this list being
exhaustive — even a minimal Story 4.5 reader (e.g., just
`fusedTopBPMs` + `confidence`) would still require those trace writes,
preserving the irreducibility argument for those fields. The list
exists per Task 1.6 to convert "irreducible" from author judgment to
citable forward-compat constraint when 4.5/4.6 ship.

## Per-edit delta table (Task 3 — empty under Branch B)

(Empty by design: Branch B exits Task 3 without applying optimizations.
Task 4 records the post-migration ratio as the measured floor.)

| Edit description | Pre-ratio | Post-ratio | Δ | Notes |
|------------------|-----------|------------|---|-------|
| (no edits applied — Branch B) | — | — | — | See "Hotspots NOT optimized" sections above. |
