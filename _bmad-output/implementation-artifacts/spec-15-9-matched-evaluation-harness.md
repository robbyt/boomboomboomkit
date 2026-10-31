---
title: 'Story 15.9: matched evaluation harness'
type: 'feature'
created: '2026-10-30'
status: 'done'
review_loop_iteration: 1
baseline_revision: 'a2d3b66d09fdb41ff6d48c20a342c3b79aafda9f'
followup_review_recommended: true
context:
  - '{project-root}/_bmad-output/implementation-artifacts/15-9-matched-evaluation-harness.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-15-context.md'
warnings: ['oversized']
deferred:
  - summary: >-
      Commit a small runner-output fixture and feed it through build_rows in pytest, so a change to the runner's grid record keys fails a routine test.
    evidence: |-
      Today the runner's output reaches the metrics only through `make matched-eval`; the synthetic-click corpus exercises it on every run, but `make ml-training-tests` does not.
    location: >-
      _bmad-output/ml-training/swift_feature_extractor/Sources/matched-eval-run/main.swift
    severity: low
---

<intent-contract>

## Intent

**Problem:** Epic 15 has no matched evaluation: nothing scores the shipped pipeline, the Epic 15 variants, the commercial DJ analyzer and an independent reference on identical audio with separated metric families, paired differences and uncertainty. Until it exists no change can be accepted on evidence and no comparison with the analyzer may be stated.

**Approach:** A develop-only `make matched-eval` that runs a Swift runner over three corpora, joins each system's output with the independent reference, computes nine metric families per track, and writes paired summaries with bootstrap intervals and Wilcoxon p-values, stratified by tempo band and style tag. Owner decisions of 2026-10-30 (memory `project_15_9_decisions.md`) fix the corpora, analyzer source, tolerances, variants, bands, statistics and memory sampling.

## Boundaries & Constraints

**Always:**
- **Placement.** A new executable target `matched-eval-run` in `_bmad-output/ml-training/swift_feature_extractor/`, and a new Python package `_bmad-output/ml-training/matched_eval/` (force-added; `_bmad-output/.gitignore` ignores `ml-training`). Nothing under `Tests/`, nothing under `eval-corpus/`, no change to `scripts/promote-to-main.py`. Fix the package's root dependency to `.package(name: "BoomBoomBoomKit", path: "../../..")` so it builds in any checkout directory.
- **Corpora and references (owner).** OA300: the 23 `daw-oracle.json` entries (DAW-verified BPM), joined on `identifiers.local_path`; the duplicated recording (one title as `.mp3` and `.wav`) counts once, keeping the `.wav`, so n = 22. 12.7: the 172 `locked-12.7-member` rows of the bundle-gate seed-42 input (verified tempo; read-only; audio sha256 checked, as Story 15.5 does). GiantSteps: 661 rows of `giantsteps-tempo-ground-truth.json`, a reference tagged `crowdsourced-reference` in every pairing. Hand annotations (`daw-oracle-annotations.json`, Story 15.8 schema `15.8.v2`) are read when present; today they have 0 entries.
- **Systems.** `boomboomboomkit-optimal`: `AudioAnalysisService.analyze(url:)` at default options. `variant-joint-fit` (15.7): on the same decode, `DSPStubObservationProducer` → `BarStateDecoder.decode` at the default BPM and level `.quarter` (the level the BPM stage chose; the epic rule says the fit never changes octave) → `JointTempoPhaseFit.fit(observations:candidate:)`; grid from `tempoBPM` and `phaseAnchorSeconds`; a nil decode or fit abstains. The selector's choice is recorded per row as a diagnostic only. `variant-comb-best-phase` (15.10): the default grid re-anchored at the comb refit's best phase, through a new internal hook (below), observed by `analyze(decoded:)` on the default pass's own decode (no second decode); refused per track when its BPM or grid differs from the default pass, or the observed tempo differs from the grid tempo. Its runtime and memory are `not-comparable` (it is the default analysis plus an observation). `variant-fixed-time` (15.5): BPM rows read from the 15.5 run's `scores-<corpus>.json` (path variable), tempo families only, runtime and memory `not-comparable`. `commercial-analyzer`: BPM from `oa300-ground-truth.json`, OA300 only, version and mode `unrecorded`, grid families `no-data`, other corpora `not-run`. `oracle`: the reference. In tracked files the analyzer is only ever named `commercial-analyzer`.
- **Comb hook.** The only `Sources/` change: `BeatGridAnalyzer` exposes the comb refit's best phase (bin, period, fold origin) through an internal type or function. Default outputs must stay byte-identical, proven by a test that compares `analyze` results with and without reading the hook on bundled fixtures.
- **Metric families, per (track, system), never collapsed:** (1) tempo level class vs reference (same, half, double, two-thirds, three-halves, other); (2) strict tempo correctness at 0.10, 0.05 and 0.02 BPM, all three; (3) fine error in BPM and parts per thousand; (4) grid phase at the first annotated downbeat (s); (5) beat precision, recall, F (mir_eval `match_events`, 70 ms); (6) downbeat-phase correctness; (7) drift over the longest annotated stable span (s); (8) failure or abstention with reason; (9) runtime (s) and peak resident memory above the pre-track baseline (bytes), sampled with `task_info` while the track runs. Accuracy rates and paired accuracy differences count an abstention or failure as incorrect, with coverage reported beside them. A non-finite or non-positive tempo is a failure. Downbeat phase and drift are scored only when the grid is at the reference's tempo level (`level-mismatch` otherwise); drift is the grid's phase error at the last annotated bar line minus its phase error at the first. Families 4 to 7 report `no-reference` when the track has no hand annotation, and `abstained-pending-retrain` never applies (no variant needs new weights).
- **Synthetic clicks (story, inherited from 15.7 and 15.10).** A fourth reference corpus: the bundled synthetic click fixtures with planted beat times (the Story 15.2 timing fixtures), where the planted beats and bar starts are the reference for families 1 to 7, so the grid families and the joint-fit and comb variants are measured before any hand annotation exists.
- **Pairings.** Every pair of systems per family. Right-hand side `oracle` → `system-vs-reference`; otherwise `system-vs-system`. A `boomboomboomkit-*` vs `commercial-analyzer` pairing is always `system-vs-system`.
- **Statistics (owner).** Paired signed differences per pairing: n, median, bootstrap 95 % interval from 10,000 resamples with a fixed committed seed, scipy paired Wilcoxon p-value, `interval_excludes_zero`. For yes/no metrics (level same, strict tempo, downbeat correct, failure) the interval is on the mean paired difference and the p-value is the exact McNemar test. Every p-value also carries a Benjamini-Hochberg q-value over all tests in its corpus, and the summary states how many tests were run; a direction sentence needs the interval to exclude zero, q < 0.05 and n >= 10. Underpowered uses the paired n everywhere. Strata: six tempo bands by reference BPM (60-89, 90-109, 110-129, 130-149, 150-179, 180-210) and style tags (OA300 and GiantSteps `genre`; 12.7 `untagged`); every stratum shows n, and n < 10 is marked underpowered with no better-or-worse sentence.
- **Wording.** The Markdown summary states a direction only with pairing, n, interval and p beside it, and never says the library meets, matches, approaches or exceeds the commercial analyzer; a test scans the generated Markdown and the tracked JSON for those words and for plain comparatives (better, worse, ahead, level with, equivalent, comparable, on a par, beats).
- **Provenance.** The runner output records its own git SHA and build configuration, and the report refuses when they differ from the report's. Every row records git SHA (dirty flag), build configuration, system id, variant identity, corpus manifest sha256, audio sha256, reference source and its sha256.
- **Outputs.** Full per-track rows, the corpus manifest and the runner output go to a gitignored `_bmad-output/ml-training/matched-eval-runs/<git-sha>/`. The tracked artifacts are `_bmad-output/implementation-artifacts/15-9-matched-eval-<git-sha>.json` and `.md`, holding only aggregates, intervals and digests, no track identifiers.
- **Floors.** `make test` count unchanged except the comb-hook invariance test; OA300 (57/82, 73/82) and GiantSteps (537/661, 546/661) floors still pass.

**Never:** change any default output or public API; touch `SignalSource.beatGrid` / `SignalWeights.beatGrid`; write under `eval-corpus/`; weaken a floor; treat the analyzer as a reference; commit 12.7 track identifiers.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Exact tempo | system 128.00, reference 128.00 | level `same`; strict true at all tolerances; error 0 | No error expected |
| Tolerance edge | system 128.04, reference 128.00 | strict true at 0.10 and 0.05, false at 0.02 | No error expected |
| Octave | system 64.2, reference 128.0 | level `half`; strict false | No error expected |
| No hand annotation | track without a 15.8 entry | families 4 to 7 `no-reference`, excluded from their pairings | No error expected |
| Joint fit abstains | fit returns nil | `variant-joint-fit` row abstained with reason; counted as incorrect in accuracy, in family 8, and in coverage | No error expected |
| Planted click | synthetic 120 BPM click, beats every 0.5 s | grid families scored against the planted beats; joint-fit and comb rows carry phase error | No error expected |
| Analyzer outside OA300 | 12.7 or GiantSteps track | `commercial-analyzer` row `not-run` | No error expected |
| Underpowered stratum | band with 6 tracks | n shown, `underpowered`, no direction sentence | No error expected |
| Duplicate recording | oracle `.mp3` and `.wav` of one title | one row (the `.wav`) | No error expected |
| Changed 12.7 audio | sha256 differs from the bundle-gate input | run refuses | exit nonzero naming the track |
| Parity wording | summary text would contain "matches" next to the analyzer | generation fails | test failure |

</intent-contract>

## Code Map

- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:2058,2102` -- `analyze(url:options:)` and `analyze(decoded:options:)`; `CombinedAnalysisResult.bpm` / `.beatGrid` (:94, :99). Default options resolve to `TechniqueSet.optimal`.
- `Sources/BoomBoomBoomKit/BeatGrid.swift:113-263,317` -- `BeatGrid` fields (`beats`, `downbeats`, `gridOrigin`, `analysisSpan`) and public init for re-anchored grids.
- `Sources/BoomBoomBoomKit/JointTempoPhaseFit.swift:56,106` -- internal fit; chain as in `Tests/BoomBoomBoomKitTests/JointTempoPhaseFitTests.swift:91-96`.
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:789,907-937,632` -- private `refineTempo`, `combSupport` (best phase bin discarded at :932-936), `selectGridOrigin`; the hook goes here.
- `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:129-280` -- OA300, GiantSteps and DAW-oracle loaders to mirror in Python or reuse in Swift.
- `_bmad-output/ml-training/swift_feature_extractor/Package.swift:35-37` -- root dependency identity (worktree build failure); `Sources/tony-dsp-prepass/main.swift:200-209` public-API corpus loop; `Sources/dump-fixed-time-input/main.swift:17,45` `@testable` precedent (debug, or release with `-Xswiftc -enable-testing`).
- `Tests/BoomBoomBoomKitBenchmarkTests/BandWaveformPerfTests.swift:245-280,421-427` -- existing memory probe (`getrusage` in a child); `task_info` sampling is new.
- `_bmad-output/ml-training/fixed_time/score.py:106-170`, `report.py:128,195,206` -- 12.7 loader with audio-hash check, `join_arms`, `paired`, `mcnemar_exact_p` to reuse; 15.5 scores at `/Users/rterhaar/tmp/bbbk-training/fixed-time-runs/seed_42/scores-*.json` (ids: GiantSteps filename, 12.7 row id, OA300 relative path).
- `_bmad-output/ml-training/eval-beatgrid.py:35,87-104` -- 70 ms window and mir_eval use; call `mir_eval.util.match_events` for precision and recall.
- `scripts/dawproject-annotations.py:85-87,535-593` -- 15.8 schema (`reference_downbeat_time_sec`, `verified_span_start_sec`/`end`, `declared_metrical_level`, `beat_position` items).
- `_bmad-output/ml-training/pyproject.toml` -- scipy 1.17.1, numpy, mir_eval 0.8.2 present; `extra-paths`. `Makefile:539-546` ty list, `:808` ml-training-tests.
- Data: OA300 labels `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json`; oracle `$OA300_CORPUS_PATH/daw-oracle.json`; 12.7 `$(LEGACY_ROOT)/eval-corpus/bundle-gate/predictions/bundle-gate-input-seed-42.json`; GiantSteps `$GIANTSTEPS_CORPUS_PATH/giantsteps-tempo-ground-truth.json`.

## Tasks & Acceptance

**Execution:**
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` -- internal best-phase hook; `Tests/BoomBoomBoomKitTests/` invariance test on bundled fixtures.
- `_bmad-output/ml-training/swift_feature_extractor/Package.swift`, `Sources/matched-eval-run/main.swift` -- dependency identity fix; runner reading an input JSON (track id, corpus, audio path, sha256) and writing per-track outputs for the three Swift systems with runtime and `task_info` peak memory; build in release with `-Xswiftc -enable-testing` (record the configuration in every row).
- `_bmad-output/ml-training/matched_eval/` -- `corpora.py` (manifests, references, dedup, hash checks), `metrics.py` (nine families), `stats.py` (bootstrap, Wilcoxon, strata), `report.py` (pairings, labels, wording guard, tracked aggregate plus gitignored rows), `run.py` (CLI).
- `_bmad-output/ml-training/tests/test_matched_eval.py` -- every I/O matrix row, bootstrap determinism, label rules, wording guard, no track ids in the tracked aggregate.
- `Makefile` -- `matched-eval` target (corpus paths, `FIXED_TIME_RUN_DIR`, legacy root), ty list; `.gitignore` -- `matched-eval-runs/`.
- Run `make matched-eval` on the three corpora; commit the tracked aggregate JSON and Markdown.

**Acceptance Criteria:**
- Given the corpora present, when `make matched-eval` runs, then the gitignored run directory holds one row per (track, system) with the nine families and provenance, and the tracked `15-9-matched-eval-<sha>.{json,md}` hold only aggregates and digests.
- Given the branch, when `uv run scripts/promote-to-main.py --from-ref HEAD` runs, then no `matched_eval`, `matched-eval-run`, run-directory or 15-9 artifact path is listed as shipping, and `scripts/tests/test_promote_to_main.py` passes.
- Given the comb hook, when `make test` runs, then the invariance test passes and every existing test passes.
- Given the summary, when read, then every pairing carries its label, n, interval and p, crowdsourced GiantSteps pairings are tagged, underpowered strata carry no direction, and the analyzer is never described as matched or exceeded.

## Spec Change Log

- 2026-10-30, review pass 1 (loop 1). Triggering findings: the joint fit ran on the metrical-level selector's choice (doubling 394 of 566 real fits) although the epic rule fixes the fit at the BPM stage's level; yes/no metrics compared by paired medians that are nearly always 0; abstentions dropped from accuracy denominators; no multiple-comparison control; the comb pass decoded the file a second time; drift equal to tempo error times span length; no measurement surface for the grid families before annotations exist, although the story inherits a synthetic-click comparison. Amended (agent-authored text in the contract only; every owner decision of 2026-10-30 is unchanged): the joint-fit chain, the comb pass, accuracy accounting, downbeat and drift scoring, statistics for yes/no metrics and BH q-values, the wording scan, runner provenance, and a fourth synthetic-click reference corpus. Known-bad state avoided: a committed aggregate whose joint-fit rows measure the selector's octave choice and whose accuracy comparisons can never state a direction. Deviation, recorded deliberately: the bad_spec rule says revert and re-derive; the code was kept and patched instead, because the amendments touch a bounded set of functions in an otherwise reviewed implementation. KEEP: placement (runner target, `matched_eval/` package), the Package.swift identity fix, the comb hook and its invariance test, corpus loading and hash checks, the gitignored rows and identifier-free tracked aggregate, the 12.7 reuse of `fixed_time.score`, provenance fields, all existing tests. The first aggregate (`15-9-matched-eval-4c88e71...`) is superseded and removed.
- 2026-10-30, patch round of loop 1: the comb pass's BPM is checked against the same `analyze(decoded:)` call run unobserved, not against the default `analyze(url:)` pass, because the URL path adds file-tag corroboration and a duration hint that the decoded path lacks (the literal check refused 28 of 40 12.7 tracks on a smoke run for that reason alone). The comb row still reports the default pass's BPM and is checked against the default pass's grid, so its only difference from the shipped pipeline is the anchor.
- 2026-10-31, rerun after Epic 13 made rhythmic regions plus window voting the default `Options()` path (develop a79792d). The committed summary is now `15-9-matched-eval-c59d47c2822a7bda3558075827f609d07e88b38a.{json,md}`, replacing the c1108d9 run measured on the old default; same inputs (12.7 input sha256 bb3accfe..., fixed-time scores unchanged, so the fixed-time and commercial-analyzer rows are identical). `boomboomboomkit-optimal` level same: 12.7 0.855 to 0.895, GiantSteps 0.723 to 0.773, OA300 0.545 to 0.864. `variant-joint-fit` coverage: 12.7 0.733 to 0.756, GiantSteps 0.632 to 0.700, OA300 0.636 to 0.864. New stated directions include the default pipeline above the fixed-time model at strict 0.05 on 12.7; the OA300 finding that the default pipeline is below the reference on level same is gone. Library benchmarks at the stack top: OA300 60/82 and 76/82, GiantSteps 573/661 and 579/661 (2 %); the historical-path floors quoted under Floors still pass.

## Review Triage Log

### 2026-10-30 — Review pass
- verdicts: 36 findings — high 2, medium 20, low 14, false 0, maybe-false 0
- findings:
  - `[high]` `[bad_spec]` Joint fit ran on the selector's octave choice, against the epic rule — main.swift runs MetricalLevelSelector then fit(selection:); 394 of 566 real fits chose double; contract amended to the quarter candidate
  - `[high]` `[bad_spec]` Yes/no metrics compared by paired median, so no direction can ever be stated (blind) — differences are -1/0/+1, median 0; contract amended: mean difference interval plus exact McNemar
  - `[medium]` `[bad_spec]` Abstentions leave accuracy denominators, so abstaining raises accuracy (blind) — rates are over tracks with a value; contract amended: abstain counts as incorrect, coverage shown
  - `[medium]` `[bad_spec]` No multiple-comparison control across thousands of tests (blind) — contract amended: BH q-values per corpus, direction needs q < 0.05
  - `[medium]` `[bad_spec]` Pass order and a second decode skew comb runtime, memory and output (blind; edge comb-differs) — contract amended: comb observed on pass A's decode via analyze(decoded:), refused when it differs, runtime not-comparable
  - `[medium]` `[patch]` Memory reads resident_size, which page reuse makes history-dependent (blind) — switch to TASK_VM_INFO phys_footprint, still task_info sampling
  - `[medium]` `[patch]` outputIdenticalToDefaultPass recorded but never checked (blind) — covered by the comb refusal in the amended contract
  - `[medium]` `[patch]` 15.5 join: hash mismatch blamed on the model; missing scores file silently not-run (blind; edge) — refuse on both
  - `[medium]` `[bad_spec]` Downbeat scored at any tempo level; comb downbeat identical to default (blind) — contract amended: downbeat and drift only at the reference level
  - `[low]` `[patch]` Wording guard misses plain comparatives and skips the JSON (blind; edge claim) — extend word list, scan the JSON too
  - `[medium]` `[patch]` Runner output carries no git SHA; report stamps its own (blind) — record SHA and build config in runner output; refuse on mismatch
  - `[medium]` `[patch]` Comb phase-to-seconds conversion never checked against clicks (blind; gap) — add a Swift test on the 120 and 170 BPM click fixtures
  - `[low]` `[patch]` No quick subset run; non-numeric or negative --limit ignored or traps (blind; edge) — MATCHED_EVAL_LIMIT make variable; strict --limit parsing; report accepts a declared subset
  - `[medium]` `[patch]` Non-finite tempo recorded ok and dropped uncounted (blind; edge) — non-finite or non-positive tempo is a failure
  - `[medium]` `[bad_spec]` Drift is tempo error times span length (blind) — contract amended: phase error at last annotated bar minus first
  - `[medium]` `[patch]` Pass A failure gives joint fit runtime 0 and memory 0 as comparable data (edge x2) — mark non-comparable
  - `[low]` `[patch]` Comb observation tempo may differ from grid tempo (edge) — covered by the comb refusal
  - `[low]` `[patch]` Grid tempo 0 or negative divides by zero (edge) — guard as failure
  - `[low]` `[patch]` Direction sentence says below zero for a zero median (edge) — superseded by the amended direction rule
  - `[low]` `[patch]` Annotation on the dropped duplicate is silently discarded (edge) — refuse
  - `[low]` `[reject]` GiantSteps genre key fallback may mis-tag a row (edge) — every label row has a filename; adds a branch for an unseen case
  - `[low]` `[patch]` run.py: missing --runner, missing run files, uncaught WordingViolation give tracebacks (edge x3) — refusal paths with EXIT_REFUSED
  - `[medium]` `[patch]` Aggregate named after the run directory, not the SHA (edge) — name from the recorded SHA
  - `[medium]` `[patch]` 15.5 fixed-time join never exercised (gap) — test with a synthetic scores directory
  - `[medium]` `[patch]` Runner grid record format never checked against what the metrics read (gap) — the synthetic-click corpus exercises real runner grid output; a runner-output fixture test added
  - `[medium]` `[bad_spec]` Story's inherited twelve-fixture click comparison absent; grid families unmeasurable today (intent) — contract amended: synthetic-click reference corpus
  - `[low]` `[reject]` OA300 count 22, not the owner's 23 (intent) — the owner named the oracle (23 entries); counting the one recording stored twice once is a recorded spec decision
  - `[low]` `[reject]` Rows gitignored instead of tracked per AC1 (intent) — 12.7 rows may not be committed; spec decision with the identifier guard
  - `[low]` `[reject]` Analyzer version and mode unrecorded (intent) — the label file records neither; owner chose this source
  - `[low]` `[patch]` Sources hook comments call it develop-only harness code (intent) — reword neutrally; the hook ships
  - `[low]` `[reject]` make test count rises by the hook tests (intent) — the epic's count rule covers env-gated measurement; the hook needs its invariance test
  - `[low]` `[reject]` Seventh band outside-60-210 (intent) — keeps out-of-range tracks visible instead of dropping them
  - `[low]` `[patch]` Underpowered uses stratum count in Markdown, paired n in JSON (intent) — paired n everywhere
  - `[low]` `[reject]` Default Options include metadata corroboration (intent) — that is the shipped default the story names
  - `[low]` `[defer]` Parity stage-style manual coverage of runner output beyond the synthetic corpus (gap) — the synthetic run exercises it; a committed runner-output fixture is a follow-up
  - `[low]` `[reject]` Comb variant indistinguishable from default on real corpora (gap other) — true until annotations exist; the synthetic corpus now measures it

## Design Notes

The story's affected-files list conflicts with its own AC8 and the epic rules: `Tests/` ships to main wholesale, and `eval-corpus/` is both forbidden and gitignored. The develop-only Swift package and a sibling Python package follow the Story 15.5 precedent. The story's GiantSteps floors (536/545) are stale; the enforced ones are 537/546. The OA300 label file records no analyzer version or mode (and its `data_source` mislabels the values as hand-labelled), so those fields read `unrecorded`. No hand annotations exist yet, so families 4 to 7 are implemented and unit-tested on synthetic 15.8-shaped entries but report `no-reference` on today's data; they fill in when the operator annotates. Only the OA300 oracle offers the analyzer comparison, at n = 22, so most of its strata are underpowered by design.

## Verification

**Commands:**
- `cd _bmad-output/ml-training && uv run pytest tests/ ablation/tests/ -q` -- all pass
- `make py-lint` and `make lint` -- clean
- `make test` -- passes, count up only by the invariance test
- `cd _bmad-output/ml-training/swift_feature_extractor && swift build -c release -Xswiftc -enable-testing --product matched-eval-run` -- builds in this worktree
- `make benchmark` and `make benchmark-giantsteps` -- floors pass
- `uv run scripts/promote-to-main.py --from-ref HEAD` -- no matched-eval path ships
- `make matched-eval` -- writes the run directory and the tracked aggregate

## Auto Run Result

Status: done

- **Change:** `make matched-eval` scores the shipped pipeline, the 15.7 joint fit, the 15.10 comb best phase, the 15.5 fixed-time model and the commercial analyzer (OA300 label BPM) against independent references on four corpora (OA300 DAW oracle 22 recordings, 12.7 172, GiantSteps 661 crowdsourced, 12 synthetic clicks), with nine separate metric families, paired bootstrap intervals, Wilcoxon or McNemar p-values with BH q-values, six tempo bands and style tags. One internal `Sources/` hook exposes the comb best phase without changing any output.
- **Files:** `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` (internal hook); `Tests/BoomBoomBoomKitTests/CombPhaseHookInvarianceTests.swift` (invariance and anchor-time tests); `_bmad-output/ml-training/swift_feature_extractor/` (`Package.swift` identity fix, `matched-eval-run` runner); `_bmad-output/ml-training/matched_eval/` (corpora, metrics, stats, report, CLI); `_bmad-output/ml-training/tests/test_matched_eval.py`; `Makefile`; `.gitignore`; tracked aggregate `15-9-matched-eval-c1108d9b558908dc151ade33cce25f30be168433.{json,md}`.
- **Review:** 36 findings; 8 bad_spec entries amended the agent-authored contract text (owner decisions unchanged) and were patched in place rather than re-derived (recorded in the Spec Change Log); 20 patches; 1 deferred; 9 rejected with reasons. The comb BPM check follows the implementer's corrected comparison (Spec Change Log).
- **Follow-up review recommended:** true. Patched high entries: 2 (joint-fit level, yes/no statistics). Unverified risk: grid families (phase, beat F, downbeat, drift) are exercised on real runner output only by the 12 synthetic clicks; on real music they wait for Story 15.8 hand annotations.
- **Verification:** `uv run pytest tests/ ablation/tests/` 420 passed; `make py-lint` clean; `make lint` only the existing nesting warning; `make test` 1252 (1250 + 2 hook tests); runner builds release with `-enable-testing`; OA300 and GiantSteps benchmark floors passed at 4c88e71 (the hook code is unchanged since, comments only); promotion check ships no matched-eval path (300 files, the hook test file added); `make matched-eval` at clean c1108d9: 867 tracks, 5202 rows, 400 s.
- **Residual risk:** the joint fit abstains on 14 to 30 % of real tracks on the rhythmic-region default (12.7 24 %, GiantSteps 30 %, OA300 14 %; 27 to 37 % on the old default); the commercial-analyzer comparison exists only on OA300 (n 22, mostly underpowered strata); memory figures are high-water marks above a pre-pass baseline.
