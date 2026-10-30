---
title: 'Story 15.5 follow-up: OA300 as the third corpus of the fixed-time report'
type: 'feature'
created: '2026-10-30'
status: 'done'
review_loop_iteration: 0
baseline_revision: 'c6101a8a4dbd783faa9952bb494c5bf302a5561b'
followup_review_recommended: true
context:
  - '{project-root}/_bmad-output/implementation-artifacts/spec-15-5-fixed-time-ml-input-ablation.md'
warnings: []
deferred:
  - summary: >-
      No test runs score.main to completion and checks the label-source hash it records in scoredInputs.
    evidence: |-
      The writer is untested for all three corpora; a missing hash fails closed at report time, so the gap is loud. One main-to-completion scoring test with a stub model would cover all three.
    location: >-
      _bmad-output/ml-training/fixed_time/score.py
    severity: low
  - summary: >-
      OA300 holds one recording twice (an .mp3 and a .wav of the same Darkgray title, label 170), so every OA300 count, including the shipped benchmark's 82, counts it twice.
    evidence: |-
      The OA300 corpus directory lists both files; both rows share (title, label) and both models predict the same BPM for each. Pre-existing in the committed ground truth, not caused by this change.
    location: >-
      Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json
    severity: low
  - summary: >-
      8 of the 82 OA300 files are byte-identical to files in the label-free unsupervisedPool pretraining manifest, although OA300 is meant to be excluded from that pool.
    evidence: |-
      The regenerated report's exposure section counts 8 for both arms; OA300 is the sentinel-exclusion source of the non-Rekordbox survey, so the manifest builder let these through. Pre-existing; affects the legacy model too.
    location: >-
      _bmad-output/ml-training/ablation/build_unsupervised_manifest.py
    severity: medium
---

<intent-contract>

## Intent

**Problem:** The Story 15.5 fixed-time report pairs the variant against the legacy model on GiantSteps and the 12.7 corpus only. OA300 (82 tracks, none of them in the pretraining pool) was scored ad hoc on 2026-10-30 (variant 62/82, legacy 43/82); the owner asked for it as a regular third corpus.

**Approach:** Add `oa300` to `fixed_time/score.py` and `fixed_time/report.py` with the same checks the other corpora have: exact pairing, equal labels, a recomputed expected legacy count, exposure counts, and every input hashed. Then score OA300 with the trained variant and regenerate the report in the existing run directory.

## Boundaries & Constraints

**Always:**
- OA300 rows come from `build_fr18_input.resolve_oa300(OA300_CORPUS_PATH)` over the committed `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json`; all 82 must resolve, or scoring refuses naming the missing files. Each row's `trackId` is its corpus-relative audio path (unique); the row also carries `title` (the ground-truth title) and the file's sha256, computed at scoring time. The ground-truth file's sha256 is recorded in `scoredInputs` and checked by the report like the other label sources.
- Legacy arm: the `corpus == "oa300"` rows of `fr18-predictions-191/seed_42/predictions.json` (field `fr18ModelBPM`). Those rows carry only `title` as `trackId`, and two titles cover two different files each. Pair each variant row with the legacy rows sharing its (title, groundTruthBPM) key. A key with several rows pairs only when the variant and legacy row counts for that key are equal and every legacy row of that key has the same `fr18ModelBPM`; otherwise the report refuses naming the key. Every legacy OA300 row must be used exactly once.
- Expected legacy strict Acc1 on OA300 is 43 of 82; the report refuses otherwise. Tempo-CNN has no OA300 rows: report `not-run`.
- OA300 appears in every per-corpus section of the report (bands, categories, paired deltas with McNemar, disagreements, exposure for both pools), and in the manifest inputs (ground-truth file, legacy dump).
- `make fixed-time-score` passes `OA300_CORPUS_PATH` (absolute) like `GIANTSTEPS_CORPUS_PATH`; `--corpus oa300` scores it alone.
- The real run directory (`/Users/rterhaar/tmp/bbbk-training/fixed-time-runs/seed_42`) gets `scores-oa300.json` and `crops-oa300.npz` from the existing `model.pt`, and the report is regenerated there. The existing GiantSteps and 12.7 scores are reused, not re-scored.

**Never:** retrain; change the crop, ranking or decode rules; change `Sources/`, `Tests/` or `tools/`; write under `eval-corpus/` or the OA300 corpus directory; publish OA300 track names outside the gitignored run directory (the corpus is private).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Unique key | one variant row and one legacy row share (title, label) | paired | No error expected |
| Shared key, same legacy prediction | two variant rows, two legacy rows with equal `fr18ModelBPM` | both paired | No error expected |
| Shared key, different legacy predictions | two legacy rows of one key with 169 and 140 | no report written | exit 3 naming the key |
| Key count mismatch | two variant rows, one legacy row for a key | no report written | exit 3 naming the key |
| Unused legacy row | a legacy OA300 row with no variant row | no report written | exit 3 naming it |
| Missing audio | a ground-truth row whose file is absent | scoring refuses | exit nonzero naming the file |
| Expected-count drift | legacy recomputes to 42 | no report written | exit 3 naming 43 |

</intent-contract>

## Code Map

- `_bmad-output/ml-training/fixed_time/score.py:106-170` -- `load_eval_12_7_rows`, `check_rows`, `resolve_corpus` (branch per corpus, label-source sha), `CORPORA` / `EXPECTED_COUNTS`; add the `oa300` branch here.
- `_bmad-output/ml-training/fixed_time/score.py:206-260` -- `score_track` copies `trackId`, `corpus`, `groundTruthBPM`, `audioSha256` into the row; add `title` passthrough when present.
- `_bmad-output/ml-training/fixed_time/report.py:41-60` -- `LEGACY_GIANTSTEPS_RELPATH`, `CORPORA`, `EXPECTED_COUNTS`, `EXPECTED_ACC1`.
- `_bmad-output/ml-training/fixed_time/report.py:123-180` -- `join_arms` (unique-id join, label equality) and `check_expected_acc1`; the OA300 legacy rows must be re-keyed to variant ids before `join_arms`.
- `_bmad-output/ml-training/fixed_time/report.py:338-370` -- `load_legacy_giantsteps` reads the same dump; model the OA300 loader on it.
- `_bmad-output/ml-training/fixed_time/report.py:660-680,738-800` -- `scoredInputs` checks and `build_report` wiring per corpus; manifest inputs list.
- `_bmad-output/ml-training/build_fr18_input.py:48-69` -- `resolve_oa300` returns `trackId` (title), `audioPath`, `groundTruthBPM`; `subdir` + `filename` give the relative path.
- `Makefile` `fixed-time-score` -- add `OA300_CORPUS_PATH`.
- `_bmad-output/ml-training/tests/test_fixed_time.py` -- existing corpus, join and refusal tests to extend.
- Ad-hoc evidence: `/private/tmp/claude-501/-Users-rterhaar-Dropbox-research-swift-BoomBoomBoomKit/48e711d1-ade9-4ea1-8c84-c8ff1a470c22/scratchpad/oa300_variant.py` (paired 82, legacy 43, variant 62, 0 pool hits; the two shared titles have equal legacy predictions 169/169 and labels 157.85/157.84).

## Tasks & Acceptance

**Execution:**
- `_bmad-output/ml-training/fixed_time/score.py` -- `oa300` corpus: resolve, require 82, relative-path ids, `title`, per-file sha256, label-source sha in `scoredInputs`; CLI `--corpus oa300`.
- `_bmad-output/ml-training/fixed_time/report.py` -- OA300 legacy loader with the (title, label) pairing rule and refusals; `oa300` in `CORPORA`, `EXPECTED_COUNTS` (82), `EXPECTED_ACC1` (legacy 43); tempo-CNN `not-run`; manifest inputs.
- `Makefile` -- `OA300_CORPUS_PATH` into `fixed-time-score`, plus a `FIXED_TIME_SCORE_ARGS` pass-through (empty default) for `--corpus`; help text names the three corpora.
- `_bmad-output/ml-training/tests/test_fixed_time.py` -- one test per I/O matrix row plus the OA300 report section rendering.
- Run directory -- `make fixed-time-score` for OA300 only, then `make fixed-time-report`.

**Acceptance Criteria:**
- Given the trained run directory, when the report is regenerated, then it contains an OA300 section with variant and legacy rows paired for all 82 tracks, legacy at exactly 43/82, tempo-CNN `not-run`, and the GiantSteps and 12.7 sections unchanged.
- Given the branch, when diffed against `c6101a8`, then nothing under `Sources/`, `Tests/`, `tools/` or `eval-corpus/` changed.

## Spec Change Log

## Review Triage Log

### 2026-10-30 — Review pass
- verdicts: 24 findings — high 0, medium 4, low 14, false 6, maybe-false 0
- findings:
  - `[medium]` `[patch]` Scores were written by uncommitted code, so their recorded git SHA names a commit without the OA300 branch — re-score OA300 and regenerate the report after the commit (done by the parent session).
  - `[false]` `[reject]` "GiantSteps and 12.7 sections unchanged" is unchecked — the implementer diffed the old and new report: tracks, summaries and exposure for both corpora identical.
  - `[false]` `[reject]` The variant's ad-hoc 62/82 is not cross-checked — the regenerated report gives 62/82.
  - `[low]` `[reject]` Old run directories and the default all-corpora score now need OA300 — one run directory exists and the Makefile always passes the path; adding a fallback adds branches.
  - `[low]` `[defer]` Two OA300 files share one key and may be one recording — they are an .mp3 and a .wav of one recording; pre-existing in the committed ground truth.
  - `[low]` `[patch]` OA300 label path absolute in scores, repo-relative in the manifest — record it repo-relative.
  - `[medium]` `[patch]` Label-source hashes recorded for every corpus in every scores doc, or omitted on single-corpus runs — record only each corpus's own source.
  - `[low]` `[patch]` Untested branches and two no-op test lines — no-op lines dropped; the build_report path gets tests (with the verification-gap finding).
  - `[low]` `[patch]` "legacy row unused" note missing or singular for some counts — reworded to the count.
  - `[low]` `[reject]` The same legacy file is recorded twice in the manifest — two names with one sha256; harmless.
  - `[false]` `[reject]` The new spec is not in the diff — by design: the spec is the claims file, kept out of the diff.
  - `[medium]` `[patch]` (edge) An all-corpora run binds the OA300 label hash into GiantSteps and 12.7 docs — same root cause as the label-source row above.
  - `[low]` `[reject]` (edge) A direct all-corpora run without OA300 now refuses — same as the default-corpus row above.
  - `[low]` `[reject]` (edge) A ground-truth row without a filename raises TypeError — the committed file has filenames; loud failure.
  - `[low]` `[reject]` (edge) Shared-key legacy rows that are all NaN refuse spuriously — the legacy dump is fixed and finite; loud failure.
  - `[false]` `[reject]` (edge) Exact float label equality splits keys — both sides read the same committed file; all 82 paired on real data.
  - `[medium]` `[patch]` (gap) build_report's OA300 wiring and manifest inputs never run under test — rp.main tests added for refusal and manifest keys.
  - `[low]` `[defer]` (gap) score.main's scoredInputs writer untested — fails closed at report time.
  - `[false]` `[reject]` (intent) Part B, the remaining Epic 15 stories, is absent — handled as separate stories (15.9) by design.
  - `[low]` `[patch]` (intent) The parent 15.5 spec still names two corpora — change-log line added to the parent spec.
  - `[false]` `[reject]` (intent) No test on the real 157.85/157.84 case — the real run pairs them and reproduces legacy 43/82.
  - `[low]` `[reject]` (intent) Tempo-CNN not run and legacy reused on OA300 — by spec: tempo-CNN has no OA300 rows, legacy comes from the recorded dump.
  - `[low]` `[reject]` (intent) Other harness stages untouched — OA300 is evaluation-only; the pool exposure is computed generically.
  - `[low]` `[reject]` (intent) make-level OA300 path untested — exercised by the real scoring run.

## Verification

**Commands:**
- `cd _bmad-output/ml-training && uv run pytest tests/ ablation/tests/ -q` -- all pass
- `make py-lint` -- clean
- `make fixed-time-score FIXED_TIME_RUN_DIR=/Users/rterhaar/tmp/bbbk-training/fixed-time-runs/seed_42 FIXED_TIME_LEGACY_ROOT=/Users/rterhaar/Dropbox/research/swift/BoomBoomBoomKit/_bmad-output/ml-training FIXED_TIME_SCORE_ARGS="--corpus oa300"` -- writes `scores-oa300.json`
- `make fixed-time-report` with the same run dir and legacy root -- writes the report; OA300 legacy 43/82

## Auto Run Result

Status: done

- **Change:** OA300 (82 tracks) is the third corpus of the fixed-time report: `--corpus oa300` scoring with corpus-relative track ids, titles and per-file hashes; the legacy rows pair by (title, label) and refuse on any ambiguity; expected legacy 43/82; tempo-CNN `not-run`; each scores file records only its own label-source hash.
- **Files:** `_bmad-output/ml-training/fixed_time/score.py` (OA300 resolution, per-corpus label-source hash, repo-relative label path); `_bmad-output/ml-training/fixed_time/report.py` (OA300 legacy loader and pairing, corpus constants, manifest inputs); `Makefile` (`OA300_CORPUS_PATH`, `FIXED_TIME_SCORE_ARGS`); `_bmad-output/ml-training/tests/test_fixed_time.py` (pairing, resolution, scoring and `report.main` tests); parent spec change-log line.
- **Review:** 24 findings; patches applied for 7 rows (4 medium, 3 low) across 5 entries; 3 items deferred (scoring writer test, the duplicated OA300 recording, 8 OA300 files in the pretraining pool); 14 rejected with reasons in the triage log.
- **Follow-up review recommended:** true. Patched mediums: 3 entries (label-source hashes, `report.main` tests, the dirty-SHA re-score). Unverified risk: the new `report.main` tests stub the exposure inputs and legacy manifests, so OA300 exposure through `main` is checked only by the real run (8 of 82 in the pool).
- **Verification:** `uv run pytest tests/ ablation/tests/ -q` 353 passed; `make py-lint` clean; no change under `Sources/`, `Tests/`, `tools/`; real run (`/Users/rterhaar/tmp/bbbk-training/fixed-time-runs/seed_42`): OA300 variant 62/82, legacy 43/82 (McNemar p = 0.000311), expected counts 348, 124, 545, 43 all reproduced.
- **Residual risk:** OA300 and the pretraining pool overlap by 8 files and OA300 counts one recording twice; both are pre-existing and recorded in `deferred`.
