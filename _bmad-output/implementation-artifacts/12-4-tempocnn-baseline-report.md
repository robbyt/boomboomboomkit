# Story 12.4: Reference tempo-CNN baseline reproduced on our evaluation path (Gate 0)

Date: 2026-08-07. Runner: dev agent (full 661-track run completed in-session; re-run
after review patches, which changed the normalization -- see Method decisions).
Baseline revision: 4184c72. Harness: `_bmad-output/ml-training/tempocnn_baseline.py`.
Raw output: `_bmad-output/ml-training/tempocnn-baseline/predictions.json`.

## Verdict

**Gate 0 does NOT fire.** The published Schreiber and Mueller ISMIR 2018 single-step
tempo CNN, run end to end on the same 661 GiantSteps rows, the same annotation source,
and the same FR-18-strict protocol that produced our v2 model's 348/661, scores
**545/661 (82.4%)** -- track-for-track equal to the published 82.5% Acc1 converted to
tracks (545). The pre-registered threshold was midpoint(348, 545) = 446.5 tracks; 545
is far above it. The evaluation path and the ruler are sound; the thirty-point gap is
attributable to our model and training, and Story 12.5's pipeline differential proceeds
on this scored baseline.

## Annotation alignment record (established BEFORE scoring)

Skipping this record would make Gate 0 measure the ruler and report it as the model.

- **What the papers scored against.** The 2018 paper (Schreiber and Mueller, "A
  Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural
  Network", ISMIR 2018) evaluated GiantSteps Tempo as published by Knees et al. 2015
  (its reference [18]); its Section 4.1 "corrected annotations from [25]" refers to
  Percival and Tzanetakis 2014, whose corrections cover other datasets, not GiantSteps.
  The 2019 follow-up (Schreiber and Mueller, "Musical Tempo and Key Estimation using
  Convolutional Neural Networks with Directional Filters", arXiv:1903.10839, SMC 2019)
  states in Section 2.4: "GiantSteps Tempo (661 samples): 2 min excerpts of EDM [25].
  Revised tempo annotations from [26]" where [26] is Schreiber and Mueller, "A
  Crowdsourced Experiment for Tempo Estimation of Electronic Dance Music", ISMIR 2018 --
  the crowd-sourced re-annotation.
- **What our ground truth is.** `giantsteps-tempo-ground-truth.json`, SHA-256
  `3dc6f3759f9a67398130b3ee8c86996f9d8bd312262b300bed05f329bc8ccf13`, generated (Story
  2.1, 2026-04) from the corpus `annotations_v2/jams` directory -- the same crowd-sourced
  re-annotation, including `tempo2`. 664 entries, 661 scoreable (bpm > 0), matching the
  2019 paper's 661. All 661 resolved rows joined to a ground-truth entry
  (`matchedTempo2Rows: 661`, asserted by the harness).
- **Match statement.** Our annotation source MATCHES the one behind the 2019 paper's
  GiantSteps figures. The aligned published figure for the 2018 CNN at this annotation
  is therefore the 2019 paper's Table 4a "Literature" row: **82.5% Acc1**. The 2018
  paper's own Table 1b figure (73.0%) is measured on a different ruler (the original
  Knees et al. 2015 annotations) and is reported here only as context.

## Citation ledger (every figure to primary text; PRD section 11)

| Claim | Source |
|---|---|
| Acc1 = identical within 4% tolerance; Acc2 additionally permits factor 2 and 3 errors | 2018 paper, Section 4, Evaluation ("allowing a 4% tolerance"); 2019 paper Section 2.5 (same definitions) |
| 2018 CNN GiantSteps: Acc0 59.8 / Acc1 73.0 / Acc2 89.3 (original annotations) | 2018 paper, Table 1 (a)/(b)/(c), `new` column, GiantSteps row |
| 2018 CNN GiantSteps: Acc1 82.5 (revised annotations, 661 tracks) | 2019 paper, Table 4a, "Literature" row, GS column, citing its ref [3] = the 2018 paper |
| GiantSteps Tempo = 661 samples with revised annotations | 2019 paper, Section 2.4, dataset list |
| Model: 256 tempo classes covering integer BPM 30-285; 2,921,042 parameters | 2018 paper, Section 3.2 |
| Input: 11025 Hz, 1024-sample half-overlapping windows, 40 mel bands 20-5000 Hz, 256 frames (11.9 s); values rescaled to [0,1] per sub-spectrogram | 2018 paper, Sections 3.1 and 3.3 |
| Global decode: sliding window, hop 128 frames, class-wise averaged activations, argmax | 2018 paper, Section 3.4 |
| PRD line "82.1/97.1" (prd.md:95) | NOT confirmed in either primary text. The traced Acc1 at the aligned annotation is 82.5 (2019 Table 4a); no 97.1 Acc2 at this annotation appears in either paper (2018 Table 1c has 89.3 on the ORIGINAL annotations; the 2019 paper reports no Acc2). The PRD row is now annotated in place (amend-not-erase note dated 2026-08-07). |

## Weights provenance

`_bmad-output/ml-training/tempocnn-baseline-provenance.json`. Variant `ismir2018.h5`
(the 2018 paper's network, named by the provenance's `model_file` key), SHA-256
`622751f2c5395028dee0554be8c9292081191b167135eac35de7ff160fdd8973`, git blob SHA-1
`ad6a6d7a81afe80f485002b270ab812e0cab4228`, 11,868,088 bytes, retrieved 2026-08-07 from
the author's AGPL-3.0 reference-implementation repository via the pinned-commit raw URL
(commit `482c64ad2e01b61d39bc161b796e3c2a1afaf67e`, latest release tag v0.0.8); both
digests verified against the commit's tree entry. Weights live outside git in
`TEMPOCNN_WEIGHTS_DIR` (`/Users/rterhaar/Dropbox/research/tempocnn-weights/`); the
harness verifies BOTH digests on every run and refuses on mismatch. No third-party
model code was copied into this repository; the harness implements the published
pipeline from the papers' text (parameters cited above).

## Method decisions (implementation choices the pipeline description must own)

- **Per-window normalization.** Each 256-frame sub-spectrogram is max-normalized to
  [0, 1] independently, per the 2018 paper's Section 3.3 training-time semantics
  ("the values of the resulting sub-spectrogram are rescaled to [0, 1]"). An earlier
  run of this harness normalized the whole sliding-window batch by one global max and
  scored 539/661; the per-window form scores 545/661 and is the recorded method.
- **Tail frames dropped.** The sliding window (hop 128) drops trailing frames short of
  a full 256-frame window -- up to 127 frames, about 5.9 s -- matching the reference
  implementation's sliding-window behavior. Recorded as a deliberate decision, not an
  accident.
- **Failure guard.** A per-track decode failure (unreadable audio, degenerate/silent
  spectrogram, non-finite model output) counts as wrong per the FR-18 abstain
  convention, BUT if failures exceed 5% of rows the harness refuses to score at all:
  a systematic environment fault must not be read as near-zero accuracy and fire the
  gate. This run: 0 per-track failures.

## Pre-registered gate rule (written before the run)

P = round(0.825 x 661) = **545 tracks** (the aligned published Acc1 converted to
tracks). Gate 0 fires iff the reference scores at or below midpoint(348, 545) =
**446.5 tracks** on the FR-18-strict protocol; it passes iff above. Binary by
construction. The rule is hard-guarded to the 661-row denominator (348 is
pre-registered FOR that population). Unit-locked in
`tests/test_tempocnn_baseline.py::TestGateRule`.

## Results (661/661 scored, zero decode failures)

Each row labelled with its protocol; the gate comparison uses ONLY the FR-18-strict row.
All reference rows regenerate from `make tempocnn-baseline` (the summary emits the
octave-tolerant and Acc2 rows directly).

| System | Protocol | Tracks / 661 | % |
|---|---|---|---|
| **Reference 2018 CNN (this run)** | FR-18 strict Acc1 @4%, no tempo2 | **545** | 82.4 |
| Reference 2018 CNN (this run) | strict Acc1 @2%, no tempo2 | 544 | 82.3 |
| Reference 2018 CNN (this run) | Acc1 @2% with tempo2 floor (Python re-implementation of the Swift mirexHit metric; equivalence tested on synthetic rows only) | 642 | 97.1 |
| Reference 2018 CNN (this run) | octave-tolerant Acc1 @4% (pred, 2x, /2) | 645 | 97.6 |
| Reference 2018 CNN (this run) | Acc2 @4% (paper definition, factors 2 and 3) | 645 | 97.6 |
| Our v2 model (maskedMelPretrain seed_42) | FR-18 strict Acc1 @4%, no tempo2 | 348 | 52.6 |
| Our DSP path (benchmark floor) | Acc1 @2% with tempo2 floor | 537 | 81.2 |
| Published (2019 Table 4a, same annotation) | Acc1 @4% | 545 (82.5%) | 82.5 |

Gate: reference 545 > midpoint 446.5 -> **Gate 0 passes**; verdict
`gap-attributable-to-our-model`.

The in-house reproduction lands ON the published figure (545 vs 545 tracks; 82.4% vs
82.5% is rounding on the same count), which doubles as a strong cross-check that the
harness, rows, and annotation are aligned.

## Per-axis observations handed to Story 12.5

All figures below regenerate from the harness summary (`strictMissesOctaveRecoverable`,
`octaveTolerantAcc1At4pct`, `acc2At4pct` rows).

- **The reference's remaining error is almost entirely octave.** Of its 116 strict
  misses, 100 are octave-recoverable (pred, 2x, or /2 within 4%): octave-tolerant
  accuracy 645/661 (97.6%). Acc2 minus Acc1 = 100 tracks for the reference versus our
  model's roughly 53 (348 -> ~401): our model's failures are NOT merely
  octave-placement; a large share are genuinely mis-pulsed.
- **The reference at @2% barely differs from @4%** (544 vs 545): its integer-class
  decode sits close to true tempi; tolerance choice is not what separates systems here.
- **The tempo2 floor is worth 97 tracks to the reference** (545 -> 642 at 2%),
  quantifying again how much octave ambiguity the DSP benchmark's tempo2 fallback
  pre-absorbs on this corpus (Story 12.3 evidence: 71 tracks for the DSP path).
- **Protocol confusion bounded:** on the DSP path's own instrument (@2% + tempo2) the
  reference scores 642 vs the DSP 537, so the reference is genuinely stronger on this
  corpus, not just differently measured.

## Dependency note and side effects

`tensorflow>=2.20,<2.21` added as the `tempocnn-baseline` dependency group (not a core
dep; 2.19 has no cp313 wheels for the project's Python). Universal resolution side
effect recorded honestly: adding TF to the project universe lowered the locked `numpy`
(2.4.4 -> TF-compatible 2.x) and `protobuf` for the shared env; two
`ty: ignore[invalid-argument-type]` comments in `scripts/audit-corpus-splits.py` and
`corpus_diagnostics.py` became unused under the older numpy stubs and were removed to
keep `make py-lint` green. **The existing ml-training pytest suites were re-run under
the new lock: `make ablation-tests` = 138 passed, zero failures** (plus the new
`make ml-training-tests` = 34 passed, now in the `pre-commit` chain).
`tempocnn_baseline.py` is ruff-covered via the `.` glob; it is NOT added to the ty
enumeration (its lazy TensorFlow import resolves only with the group installed -- the
torch-debt precedent recorded in the Makefile `py-lint` help text).

## Reproduction

```
TEMPOCNN_WEIGHTS_DIR=/path/to/weights make tempocnn-baseline
```

Verifies both checksums, resolves the identical 661 rows via
`build_fr18_input.resolve_giantsteps`, refuses any other denominator, hard-asserts the
tempo2 join (661/661), runs the published featurization and decode, refuses to score
past the 5% failure guard, and re-evaluates the pre-registered gate. Predictions JSON
records the ground-truth SHA-256 and stores audio paths as basenames only.
