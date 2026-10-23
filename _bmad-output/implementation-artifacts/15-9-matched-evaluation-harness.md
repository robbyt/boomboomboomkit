# Story 15.9: Matched evaluation harness vs rekordbox and DAW oracle

Status: backlog

Epic: 15 (Rekordbox-informed accuracy improvements)
Phase: 9 of the handoff in `../rekordboxReader/docs/rekordbox-analysis/AGENT_GUIDANCE.md`.

Summary: Build a reproducible, develop-only harness that scores BoomBoomBoomKit, each Epic 15 proposed change, a named rekordbox analysis mode, and independent DAW/hand-annotation references on identical audio across separated metric families, with paired per-track differences, stratification by DJ style and tempo band, and uncertainty estimates before any parity claim is made.

## Inherited from Story 15.7

- The twelve-fixture comparison of the Story 15.7 joint tempo and phase fit against the `BeatGridAnalyzer` comb path on actual grid timestamps (the synthetic click fixtures of `evidence/timing/TimingProbeTests.swift`, Phase 3 absolute-phase convention, per-fixture numbers under `_bmad-output/perf-baselines/`) moved here from Story 15.7 AC #5. Story 15.7 records only the fit's own anchor residual on clean clicks (about one hop early).
- From Story 15.10 (2026-10-23): the comb refit's best phase as an optional comparison variant: a grid anchored at that phase rather than at the selected raw beat. `BeatGridAnalyzer.combSupport` (the best-phase-bin loop at the end of the function) finds the best phase bin and returns only its mean support; the bin itself is discarded, and Story 15.10 left it so.
- From Story 15.10: per-track rows may split timing error by `BeatGrid.analysisSpan`, separating error inside `[startSeconds, endSeconds)` (measured) from error in the extrapolated regions before and after it.

## Key Design Decisions

1. **New harness, no edits to existing accuracy floors.** Add a new matched-evaluation harness alongside `make benchmark` / `make benchmark-giantsteps` / `make oracle` rather than retargeting them. The 2% Acc1 / 4% Acc2 regression floors in `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` and the GiantSteps equivalents stay unchanged, so a change that trades corpus accuracy for a new matched-eval win is still blocked by the committed floor.
2. **Four systems scored on one audio set.** The harness enumerates four systems per track on bit-identical input: current BoomBoomBoomKit at `TechniqueSet.optimal`, each proposed Epic 15 improvement as a named variant, one named-and-versioned rekordbox analysis mode (string recorded per track, e.g. `rekordbox-7.2.19.0342 constant-tempo`), and an independent reference (DAW oracle + Phase 8 hand-annotation when present). Rekordbox is a system under test, never the reference.
3. **Metric families stay separate, no collapsed scalar.** Report nine families in parallel, not a single composite: musical tempo level (half/double/triplet class), strict tempo correctness at a tightened absolute tolerance, fine BPM / rate error in BPM and in parts per thousand, absolute grid phase at the first annotated downbeat, beat precision / recall / F-measure, bar / downbeat phase correctness, long-span drift over the longest stable span, failures and abstentions, and runtime plus peak resident memory. The handoff explicitly calls the current 4% Acc1 / Acc2 tolerance too permissive for grid certification, so strict tempo uses a tightened tolerance surfaced per track (open question KQ-1 names the value).
4. **Paired per-track differences with uncertainty.** The report emits per-track rows (`track_id`, metric, system A value, system B value, signed diff, oracle value) plus a paired summary per pairing with bootstrap confidence intervals and the paired Wilcoxon p-value, so a claim that variant X beats baseline on fine BPM error is backed by a stated effect size and interval, not a mean-of-means. Any `A beats B` statement in the report must cite the pairing, interval, and n.
5. **Rekordbox-generated grids are not independent evidence.** When the harness notes agreement between BoomBoomBoomKit and rekordbox it labels the comparison `system-vs-system`, never `system-vs-truth`. An independent reference requires a DAW-verified entry or a Phase 8 hand-annotation. `SignalSource.beatGrid` and `SignalWeights.beatGrid` remain placeholders inside the pipeline; the harness never promotes a derived grid to an independent voter.
6. **Report by DJ style and tempo band.** Every metric family is reported overall and stratified into tempo bands (open question KQ-2 proposes 60-89, 90-109, 110-129, 130-149, 150-179, 180-210 BPM) and DJ style tags carried in the fixture JAMS files. A single corpus-wide number hides the drum-and-bass / downtempo asymmetry the handoff already called out.
7. **Deterministic, develop-only, versioned outputs.** The harness runs as `make matched-eval` and emits `_bmad-output/implementation-artifacts/15-9-matched-eval-<git-sha>.json` plus a sibling Markdown summary. Rekordbox binary version, named analysis mode, BoomBoomBoomKit git SHA (dirty flag included), corpus manifest SHA, and per-variant `TechniqueSet` identity are recorded in every row. Nothing under `../rekordboxReader/docs/rekordbox-analysis/`, `_bmad-output/`, or the new harness is added to `scripts/promote-to-main.py` or the `SHIPS_TO_MAIN` allowlist in `CLAUDE.md`.
8. **Retrain, do not re-preprocess, to compare under a new contract.** If a proposed variant changes frame-time convention (Phase 3), waveform-feature contract (Phase 4), or ML input shape (Phase 5), the variant row loads weights trained under the new contract or runs the matching retrain; it does not reuse the existing bundled weights with altered runtime preprocessing. Rows whose weights do not yet exist appear in the report as `abstained-pending-retrain`, not as a win.

## Story

As a BoomBoomBoomKit maintainer evaluating Epic 15 proposals,
I want a reproducible matched-evaluation harness that scores BoomBoomBoomKit, each proposed change, a named rekordbox mode, and independent DAW / hand-annotation references on identical audio across separated metric families, with paired differences and uncertainty,
so that a change can be accepted or rejected on evidence against an independent reference, and a `meets or exceeds rekordbox` claim is made only when the matched held-out numbers support it, with corpus, modes, metrics, denominator, uncertainty, and limitations stated.

## Acceptance Criteria

1. **Given** a committed matched-evaluation corpus manifest listing audio paths, independent reference entries (DAW oracle rows and Phase 8 hand-annotation rows), DJ-style tag, tempo-band tag, and corpus-SHA
   **When** an operator runs `make matched-eval` on a clean checkout of `develop` with `OA300_CORPUS_PATH`, `GIANTSTEPS_CORPUS_PATH`, and the matched-eval corpus path set
   **Then** the harness emits `_bmad-output/implementation-artifacts/15-9-matched-eval-<git-sha>.json` with one row per (track, system) pair where system is drawn from `{boomboomboomkit-optimal, variant-<name>, rekordbox-<version>-<mode>, oracle}`, and every row records the BoomBoomBoomKit git SHA (with dirty flag), rekordbox binary version string, rekordbox analysis mode string, variant `TechniqueSet` identity, corpus-SHA, and the audio-file SHA

2. **Given** the emitted JSON report
   **When** a reader filters any single track row
   **Then** nine metric families are present as separate fields and never collapsed into one scalar: musical tempo level class, strict tempo correctness at the tightened absolute tolerance (value recorded in the report header), fine BPM error (BPM) and fine rate error (parts per thousand), absolute grid phase error at the first annotated downbeat (seconds), beat precision / recall / F-measure, downbeat-phase correctness, long-span drift over the longest stable annotated span (seconds), a failure-or-abstention flag with reason string, and runtime (seconds) plus peak resident memory (bytes)

3. **Given** a matched-evaluation run that produces a per-pair summary
   **When** the report compares any two systems
   **Then** each pairing is labeled either `system-vs-system` or `system-vs-reference` based on whether the right-hand side is `oracle`, and no comparison of the form `boomboomboomkit-* vs rekordbox-*` is labeled `system-vs-reference` or treated as evidence of correctness on a disagreement

4. **Given** a per-pair summary row
   **When** the harness emits a superiority or inferiority claim for a metric family
   **Then** the row carries the pairing name, n, median paired signed diff, a bootstrap 95% confidence interval (open question KQ-3 names the resample count), the paired Wilcoxon p-value, and a boolean `interval_excludes_zero`, and no `A beats B` string appears in the Markdown summary without those fields populated

5. **Given** the committed tempo-band and style-tag taxonomy
   **When** the matched-eval run completes
   **Then** the Markdown summary contains overall numbers and stratified numbers per tempo band and per DJ style tag, with a per-stratum n so a reader can see where the harness has fewer than ten tracks and treat that stratum as underpowered

6. **Given** a variant that requires weights trained under a new frame-time or waveform-feature contract and whose retrain has not yet produced an artifact
   **When** the harness runs that variant on a track
   **Then** the row reports `abstained-pending-retrain` with the missing-artifact path, and no fine-BPM, F-measure, or long-span-drift number is recorded for that row

7. **Given** the matched-evaluation harness is landed
   **When** `make benchmark`, `make benchmark-giantsteps`, `make oracle`, and `make ablation` are run after this story
   **Then** the OA300 Acc1 >= 57/82 and Acc2 >= 73/82 floors, the GiantSteps Acc1 >= 536/661 and Acc2 >= 545/661 floors, and the beat-grid-accuracy floor from Story 8.7 are all held, confirming no existing regression gate was weakened to make the new harness pass

8. **Given** the matched-evaluation outputs under `_bmad-output/implementation-artifacts/` and `../rekordboxReader/docs/rekordbox-analysis/`
   **When** `scripts/promote-to-main.py --dry-run` is run
   **Then** none of the matched-eval scripts, corpus manifests, JSON reports, Markdown summaries, or `../rekordboxReader/docs/rekordbox-analysis/` files are listed in the main-bound diff, and `scripts/tests/test_promote_to_main.py` still passes

## Affected files

- `Makefile`
- `Tests/BoomBoomBoomKitBenchmarkTests/MatchedEvaluationTests.swift`
- `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/matched-eval-corpus-manifest.json`
- `_bmad-output/ml-training/eval-corpus/matched_eval_metrics.py`
- `_bmad-output/ml-training/eval-corpus/matched_eval_report.py`
- `_bmad-output/implementation-artifacts/15-9-matched-evaluation-harness.md`
- `_bmad-output/planning-artifacts/epics.md`
- `../rekordboxReader/docs/rekordbox-analysis/AGENT_GUIDANCE.md:68`
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift:103`
- `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift`
- `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridBenchmarkTests.swift`
- `scripts/promote-to-main.py`
- `scripts/tests/test_promote_to_main.py`
- `CLAUDE.md:12`

## Overlap with Epic 12

Epic 12 continues to own model-quality lever ranking and any retrain gate. This story adds the measurement surface Epic 12 can call into for a lever-ranking read, but does not import or move any Epic 12 model-quality lever logic. The harness is Epic 15 code and lives beside the existing `make benchmark` targets; Epic 12 stories that want to use it reference `make matched-eval` without taking ownership of the harness. The Phase 8 reference-downbeat and verified-BPM hand-annotation artifacts the harness reads are produced by Story 15.8 and must not alter Story 12-7 corpus membership or the signed corpus protocol as a side effect.

## Open questions for the PRD

- KQ-1: What strict-tempo absolute tolerance replaces the 4% Acc1 hit for grid certification? Candidate values: 0.10 BPM, 0.05 BPM, 0.02 BPM. Pick before implementation and record in the report header.
- KQ-2: Confirm the tempo-band taxonomy. Proposed: 60-89, 90-109, 110-129, 130-149, 150-179, 180-210 BPM. The 130-149 and 180-210 bands cover the house/techno and drum-and-bass clusters the DAW oracle already carries.
- KQ-3: Bootstrap resample count and seed for the paired confidence intervals. Suggest 10,000 resamples with a fixed seed committed to the harness. Confirm this is tractable for a corpus of the expected size.
- KQ-4: Which rekordbox version string and analysis-mode name are canonical for this evaluation? The current preserved investigation names `rekordbox-7.2.19.0342`; confirm whether `constant-tempo` or `dynamic-tempo` is the mode under test, and whether both are needed as separate systems.
- KQ-5: How is peak resident memory sampled? `getrusage(RUSAGE_SELF)` after each track versus `task_info` polling. Need a single documented sampling convention so the memory column is comparable across variants.
- KQ-6: What is the minimum per-stratum track count below which the report must mark a stratum as underpowered and refuse to publish a superiority claim scoped to that stratum? Suggest n < 10 as the floor.

## Explicit scope exclusions

- Do not weaken any existing regression floor in `OA300BenchmarkTests.swift`, `GiantStepsBenchmarkTests.swift`, `BeatGridBenchmarkTests.swift`, or the Story 8.7 beat-grid F-measure floor to let a variant pass.
- Do not declare rekordbox or BoomBoomBoomKit correct on a disagreement with the other when no independent reference row is present for that track.
- Do not emit a `meets or exceeds rekordbox` claim in the Markdown summary or any downstream artifact unless the paired held-out matched-eval result supports it with corpus, mode, metric, denominator, interval, and limitations stated.
- Do not alter runtime preprocessing of existing bundled weights to produce a new matched-eval row; retrain under the new contract or report `abstained-pending-retrain`.
- Do not count learned evidence twice: `SignalSource.beatGrid` and `SignalWeights.beatGrid` remain placeholders, and a derived beat-grid never acts as independent evidence for the BPM selection that fed it.
- Do not modify Story 12-7 corpus membership or the signed-corpus protocol as a side effect; the matched-eval corpus is a separate manifest.
- Do not add any file under `../rekordboxReader/docs/rekordbox-analysis/`, `_bmad-output/ml-training/eval-corpus/`, or the new matched-eval harness paths to `scripts/promote-to-main.py` or the `SHIPS_TO_MAIN` allowlist in `CLAUDE.md`.
- Do not collapse the nine metric families into a composite score in any emitted artifact.

