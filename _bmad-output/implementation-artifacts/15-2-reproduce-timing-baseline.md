# Story 15.2: Reproduce absolute grid-timing discrepancy in-tree with a recorded baseline

Status: backlog

Epic: 15 (Rekordbox-informed accuracy improvements)
Phase: 2 of the handoff in `../rekordboxReader/docs/rekordbox-analysis/AGENT_GUIDANCE.md`.

Summary: Port the SPM timing probe into an env-gated test under `BoomBoomBoomKitBenchmarkTests` and record a per-SHA baseline that Phase 3 can regress against.

## Key Design Decisions

1. **In-tree home is BoomBoomBoomKitBenchmarkTests, not BoomBoomBoomKitTests.** The probe produces 24 timed measurements per run and is a reproducibility artifact, not a correctness regression every developer should pay for on `make test`. `Tests/BoomBoomBoomKitBenchmarkTests/` already carries env-gated impact tests (`SuperFluxImpactTests`, `BNNSImpactTests`, `BeatGridBenchmarkTests`) with the same shape, so a new `BeatGridTimingBaselineTests.swift` there reuses the existing target wiring. No new SPM target is added.
2. **Single env gate, default-off, mirrors SuperFluxImpactTests.** The test uses `@Suite(.disabled(if: ProcessInfo.processInfo.environment["BBB_BEATGRID_TIMING_BASELINE"] != "1"))`, so `make test` runs the same test count as today. A `make beatgrid-timing-baseline` target invokes it with the env set. Only the env flip is required — no code or option default is changed to make the probe pass.
3. **Baseline JSON schema is per-fixture rows plus a run header.** Each run writes one file `_bmad-output/perf-baselines/beatgrid-timing/<sha>-<timestamp>.json`. Top-level: `schemaVersion` (int, starts at 1), `commitSHA`, `createdAt` ISO-8601, `platform`, `probeSource` (the git path to the in-tree test), `intensityLevel`, `fixtures: [...]`. Each fixture row carries `path` (`known-tempo` / `public-facade`), `sampleRate`, `offsetSamples`, `waveform`, `estimatedBPM`, `gridConfidence`, `beatCount`, `interiorCount`, `meanBeatConfidence`, `gridOriginSignedErrorMs`, `interiorMedianSignedErrorMs`, `interiorMinSignedErrorMs`, `interiorMaxSignedErrorMs`. Keys are `sortedKeys`-stable so Phase 3 can diff byte-for-byte.
4. **Phase 3 compares the extrapolated grid, not raw beats.** The schema records `gridOriginSignedErrorMs` separately from `interiorMedianSignedErrorMs` because the Epic 8 close-out rule is to compare the extrapolated grid, not raw framewise beats. Carrying both lets the Phase 3 fix show it moved the anchor without silently rewriting individual beat timestamps.
5. **This story asserts reproduction, not correctness.** The in-tree test asserts that every one of the 24 rows has `gridOriginSignedErrorMs` in `[-50.5, -39.5]` ms and the per-row `interiorMedianSignedErrorMs` is in the same band. It is a bug-still-present tripwire, not a Phase 3 tolerance. Flipping to a tight tolerance belongs to the Phase 3 story that fixes the frame-time convention, not here.
6. **The SPM probe at `../rekordboxReader/docs/rekordbox-analysis/evidence/timing/` stays preserved.** `evidence/timing/ProbePackage.swift`, `evidence/timing/TimingProbeTests.swift`, `evidence/timing/results.json`, and `evidence/timing/swift-test.log` are not deleted. A new `evidence/timing/README.md` points at `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridTimingBaselineTests.swift` and states that the two bodies must stay semantically identical (same fixture matrix, same residual math). A developer without BoomBoomBoomKit's test harness still reproduces the measurement from `evidence/timing/`.
7. **Baseline files are develop-only artifacts.** `_bmad-output/` is already excluded from `scripts/promote-to-main.py` (CLAUDE.md Release Process). The new subdirectory `_bmad-output/perf-baselines/beatgrid-timing/` inherits that exclusion. No row is added to the `SHIPS_TO_MAIN` list. Baseline JSONs are referenced by SHA in commit messages, not promoted outward.
8. **Probe is a facade-level measurement at `level3`, with level recorded explicitly.** The current probe runs `AudioAnalysisService.analyzeBeatGrid` at `.level3` and also measures a known-tempo path through `BeatGridAnalyzer.estimateBeatGrid`. The baseline JSON records `intensityLevel: 3` so Phase 3 can later add a second row at `.level7` (the public default) without silently rewriting what was measured here.

## Story

As a library maintainer working on Epic 15,
I want the absolute grid-timing discrepancy reproduced inside the project's own test harness with a per-SHA baseline file,
so that Phase 3's frame-time-convention fix has a reproducible, in-tree reference measurement to regress against instead of a one-off SPM probe outside the repo.

## Acceptance Criteria

1. **Given** `BBB_BEATGRID_TIMING_BASELINE` is unset in the environment
   **When** `make test` runs on current develop
   **Then** the new `BeatGridTimingBaselineTests` suite is skipped via `.disabled(if:)`, the pre-story test count is unchanged, and no file is written under `_bmad-output/perf-baselines/beatgrid-timing/`

2. **Given** `BBB_BEATGRID_TIMING_BASELINE=1` and the test runs on the current `develop` HEAD on an Apple Silicon macOS 15 host
   **When** `swift test --filter BeatGridTimingBaselineTests` completes
   **Then** exactly 24 fixture rows are produced (2 sample rates x 3 phase offsets x 2 waveforms x 2 paths), each row contains every field named in Design Decision 3, and the keys are emitted with `JSONSerialization` `sortedKeys` so repeat runs on the same SHA are byte-equal

3. **Given** the 24 rows produced in AC #2
   **When** the suite checks each row
   **Then** every row has `gridOriginSignedErrorMs` in `[-50.5, -39.5]` ms and `interiorMedianSignedErrorMs` in the same `[-50.5, -39.5]` ms band, matching the measurement already recorded in `../rekordboxReader/docs/rekordbox-analysis/evidence/timing/results.json`

4. **Given** a baseline file at `_bmad-output/perf-baselines/beatgrid-timing/<sha>-<timestamp>.json` written by AC #2
   **When** the committed file is inspected
   **Then** its filename begins with the current `git rev-parse HEAD` short SHA, its top-level `commitSHA` field holds the full SHA, its `probeSource` field is `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridTimingBaselineTests.swift`, and `scripts/promote-to-main.py` does not list that path

5. **Given** the preserved SPM probe at `../rekordboxReader/docs/rekordbox-analysis/evidence/timing/TimingProbeTests.swift` and the in-tree `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridTimingBaselineTests.swift`
   **When** a reader diffs the two bodies
   **Then** the fixture matrix (`sampleRate`, `offset`, `decay`), the public-facade and known-tempo paths, and the residual math (`phase = (t - offset/sr) / 0.5`, residual ms = `(phase - phase.rounded()) * 0.5 * 1000`) are identical, with any difference confined to SPM-vs-in-tree harness scaffolding and documented in `../rekordboxReader/docs/rekordbox-analysis/evidence/timing/README.md`

6. **Given** the AC #2 run completes
   **When** the suite exits
   **Then** neither `SignalSource.beatGrid` nor `SignalWeights.beatGrid` were given an independent vote during the run (they stay placeholders), and `Options.ensemblePolicy` keeps its `.dspOnly` default so the `MLTechnique.evaluate` byte-identity contract tested by `EnsemblePolicyTests` is not perturbed

7. **Given** the story is submitted for review
   **When** the diff is inspected
   **Then** no file under `Sources/BoomBoomBoomKit/` has been modified to make the probe assertions pass, no option default has been flipped, and no row has been added to the `SHIPS_TO_MAIN` list in `scripts/promote-to-main.py`

## Affected files

- `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridTimingBaselineTests.swift`
- `_bmad-output/perf-baselines/beatgrid-timing/README.md`
- `_bmad-output/perf-baselines/beatgrid-timing/.gitkeep`
- `_bmad-output/perf-baselines/beatgrid-timing/<sha>-<timestamp>.json`
- `../rekordboxReader/docs/rekordbox-analysis/evidence/timing/README.md`
- `../rekordboxReader/docs/rekordbox-analysis/evidence/timing/TimingProbeTests.swift`
- `../rekordboxReader/docs/rekordbox-analysis/evidence/timing/ProbePackage.swift`
- `../rekordboxReader/docs/rekordbox-analysis/evidence/timing/results.json`
- `Makefile`

## Overlap with Epic 12

Epic 12 (model-quality redesign) owns model-quality lever ranking and the retrain gate. This story takes no position on model training, feature contracts, or ML representation. The baseline it records is DSP + default-`.dspOnly`-ensemble output through `AudioAnalysisService.analyzeBeatGrid`, so Epic 12's lever work can proceed in parallel without colliding with the Phase 3 timing fix that follows. The only potential overlap sits in Phase 5 (fixed-time ML input), not here.

## Open questions for the PRD

- Baseline directory layout: `_bmad-output/perf-baselines/beatgrid-timing/<sha>-<timestamp>.json` subdirectory vs the existing flat `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--<ts>--<sha>--<run>.json` convention used by the BPM accuracy baselines. Pick one before Phase 3 lands.
- Which intensity levels to record. The probe currently measures only `.level3`. Phase 3 will likely want `.level3`, `.level7` (public default), and `.level2` to see if the discrepancy is level-sensitive. Does the baseline schema add a `levels` array now, or does Phase 3 extend it?
- Env var name: `BBB_BEATGRID_TIMING_BASELINE` matches the project's existing shout-case convention (`BNNS_IMPACT`, `SPECTRAL_FLUX_IMPACT`) but is wordier. Confirm or shorten.
- Platform tagging. Existing BPM baselines are tagged `Apple_M5_Max-26--Debug--...`. The probe is synthetic (no decode) so platform drift should be small, but Phase 3 may still want platform in the filename. Decide before the first baseline commit.
- Should the baseline file itself be committed per SHA, or only kept locally and reproduced on demand? The BPM baselines are committed; the timing baseline is small enough to follow that convention.

## Explicit scope exclusions

- Do not fix the 40 to 50 ms early-anchor bug in this story. The fix belongs to Phase 3 (frame-time convention) and will land as its own BMAD story with its own regression tests.
- Do not alter runtime preprocessing in `BPMAnalyzer.swift:1181`, `BPMAnalyzer.swift:916`, or `BeatGridAnalyzer.swift:330` to make the probe assertions pass.
- Do not change the default of `Options.ensemblePolicy`, `AnalysisIntensity`, or any `TechniqueSet` preset so the probe reports a smaller offset.
- Do not apply a universal +40 or +50 ms correction anywhere in the pipeline.
- Do not promote any file under `_bmad-output/perf-baselines/beatgrid-timing/` to `main`; do not add a row to `SHIPS_TO_MAIN` or to `scripts/promote-to-main.py`.
- Do not touch Story 12-7 corpus membership, the signed corpus protocol, the untracked `addendum-design.md`, or the untracked `_bmad-output/ml-training/eval-corpus/` tree as a side effect of this story.
- Do not count the derived `SignalSource.beatGrid` or `SignalWeights.beatGrid` as independent evidence; both remain placeholders through this story.
- Do not delete or rewrite the preserved SPM probe at `../rekordboxReader/docs/rekordbox-analysis/evidence/timing/`; keep the standalone artifact reproducible outside the project's test harness.

