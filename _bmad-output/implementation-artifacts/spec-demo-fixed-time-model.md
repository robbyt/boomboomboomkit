---
title: 'Try the fixed-time model in the demo app, voting in the ensemble'
type: 'feature'
created: '2026-10-30'
status: 'in-review'
baseline_commit: 'f8b45dcbd02520ab758d1e3ffaaa5059a74433c2'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/spec-15-5-fixed-time-ml-input-ablation.md'
  - '{project-root}/.claude/skills/bpm-diagnostic-trace/SKILL.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Story 15.5 fixed-time model (GiantSteps 547/661 against the shipped 348) runs only in Python. The owner cannot load it in the demo app. The library cannot run it either: `BNNSTechnique` hard-checks a 512-frame input, the model needs 1200-frame crops ranked by the rhythm score over the whole track, and `MLTechnique.evaluate(trace:)` sees only the 30 s analysis window's log-mel and no audio.

**Approach:** Add public library API for the 15.5 input contract, and a fixed-time ML technique that gets the whole decoded track and votes in the ensemble like any ML technique. Then let the demo load the exported model through its existing picker and shade the kept crops on the timeline.

**Owner decisions (2026-10-30):**
- Crop scoring and ranking become public library API.
- The model's BPM votes in the ensemble through the existing `EnsemblePolicy`, which needs a library change to pass the whole decoded track to the technique.
- The demo shows the kept crops on the existing timeline. There is no per-crop table and no click-to-play.

## Boundaries & Constraints

**Always:**
- The crop contract is the one in `fixed_time/features.py`:
  - 44.1 kHz mono and the v2 log-mel;
  - 1200-frame crops, hop 600, plus a tail crop;
  - per-crop, per-band z-score;
  - rhythm score from `RhythmicRegionSelector`'s score on the crop's own samples;
  - keep at most 4 crops, each scoring above 0 and at least half the best, ties to the earlier start;
  - mean of the kept crops' softmax, decoded as `30 + argmax`.
- Audio at any other sample rate is converted to 44.1 kHz inside the library before cropping.
- Default `Options` (`.dspOnly`) output stays byte-identical, and `BNNSTechnique` behaviour and its tests are unchanged.
- New trace fields follow the typed-evidence rules in the `bpm-diagnostic-trace` skill.
- Names follow CLAUDE.md "Naming and vocabulary".
- Weights stay outside git.
- The model is never named or exported as `giantsteps_v2_*`, and no weights are bundled.

**Never:**
- Change the `MLTechnique.evaluate(trace:)` signature.
- Give `RhythmicRegionSelector` a second implementation; the public API calls the existing one.
- Change shipped DSP output or presets.
- Write under `eval-corpus/`.
- Name third-party apps in `Sources/`, `Tests/`, commits or PR text.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Happy path | 44.1 kHz track ≥ 12.04 s, fixed-time model loaded, ML-augmented preset | Ensemble includes ML vote, `trace.mlInputCrops` lists 1-4 kept crops | N/A |
| Other rate | 48 kHz file | Converted to 44.1 kHz, then same as the happy path | Conversion failure: abstain |
| Too short | Fewer than 1200 frames | Technique abstains; ensemble uses DSP | Reason "shorter-than-crop" |
| No rhythm | All candidate crops score 0 | Technique abstains | Reason "no-rhythmic-crop" |
| Wrong model | 512-wide model passed to the fixed-time technique, or 1200-wide to `BNNSTechnique` | Construction throws `invalidTensorContract` | Demo tries the other technique before failing |
| DSP only | `.dspOnly` with the fixed-time model attached | No ML call, byte-identical to no model | N/A |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKit/RhythmicRegionSelector.swift:64` -- private `score(samples:start:count:sampleRate:)` to expose to the new public API. `probeRegions` is at :39.
- `Sources/BoomBoomBoomKit/FeatureSubstrate/` -- `OnsetFeaturesBuilder.build(decoded:weighting:)` (public, whole buffer, frame-major log-mel) and `DecodedAudio`. The new crop builder belongs here.
- `_bmad-output/ml-training/swift_feature_extractor/Sources/dump-fixed-time-input/main.swift` -- working Swift crop plan, z-score (`vDSP_normalize`, zeroing on a zero or non-finite stddev) and rhythm-score slicing to lift into `Sources/`. Once the public API exists, switch it to call that API, so parity stages 6 and 7 cover the library code.
- `Sources/BoomBoomBoomKit/PCMBufferReader.swift` -- internal downsample path, for conversion to 44.1 kHz.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift`:
  - `evaluateMLIfActive` (:846) is the ML seam. Add a capability check, the `MLDiagnosticTechnique` pattern at :858, for a new protocol that refines `MLTechnique` and also receives the decoded track.
  - Thread the decoded audio in from the shared decode (`decodeOnce` :1468, `applyCap` :1485). Pass the uncapped decode when one exists.
- `Sources/BoomBoomBoomKit/MLTechnique.swift`, `BPMDiagnosticTrace.swift` -- protocol home, and the new typed-evidence field for the kept crops.
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift`:
  - `targetWidth = 512` (:187), contract check (:1021).
  - Reuse its graph load, contract check and inference by making the width a parameter internally; its public behaviour stays the same.
- `tools/coreml-convert/reference_arch.py:154` -- `build_reference_model`, width-agnostic. `tools/coreml-convert/convert.py` takes `--input-shape`. Do not edit it.
- `_bmad-output/ml-training/fixed_time/score.py`, `features.py` -- Python reference. `scores-giantsteps.json` in the run dir holds the expected kept starts and BPM per track.
- Demo files:
  - `AnalysisViewModel.swift`: `loadModel(at:)` :887, `attachMLTechnique` :929, options :433-459.
  - `ModelPickerView.swift`: the panel accepts `.mlmodelc`.
  - `BeatGridView.swift` / `Waveform.swift`: the timeline.
  - `TraceView.swift` :263-300: the ML diagnostic rows.
- Model run: `/Users/rterhaar/tmp/bbbk-training/fixed-time-runs/seed_42/model.pt` (plain state_dict, `promotable: False`).

## Tasks & Acceptance

**Execution:**
- [x] `_bmad-output/ml-training/fixed_time/export.py` and Makefile target `fixed-time-export` -- Export the checkpoint to an ML program with input `[1,1,128,1200]` named `input` and output `output`, FP32, macOS 15, then compile it with `xcrun coremlc` into `fixed_time_seed_42.mlmodelc` next to `model.pt`.
  - Refuse if eager and Core ML outputs differ by more than 1e-3 on a real crop tensor.
  - Rationale: the demo needs a compiled model, and `export.py` is pinned to 512.
- [x] `Sources/BoomBoomBoomKit/FeatureSubstrate/` (new file) -- Public fixed-time crop builder.
  - Input: decoded audio. Output: every candidate crop's start (frames and seconds) and rhythm score, the kept crops in rank order, and each kept crop's z-scored mel-major `[128×1200]` tensor.
  - It calls the existing rhythm score, which needs widening to internal.
  - Rationale: owner decision 1.
- [x] `Sources/BoomBoomBoomKit/MLTechnique.swift`, `AudioAnalysisService.swift`, `BPMDiagnosticTrace.swift`:
  - Add a public protocol refining `MLTechnique` that receives the trace plus the decoded track, and returns the evaluation plus kept-crop evidence.
  - The service calls it when that technique is attached and the policy invokes ML.
  - Write the kept crops to a new public trace field when `enableMLDiagnostics` is set.
  - Rationale: owner decision 2.
- [x] `Sources/BoomBoomBoomKitML/` (new file plus a shared internal graph helper) -- Public fixed-time technique.
  - `init(modelURL:) throws` validates a `[1,1,128,1200]` input and a 256-element output.
  - Evaluation: crops, inference per kept crop, mean softmax, `30 + argmax`. Confidence is the mean softmax's top probability, documented as uncalibrated.
  - It abstains with the reasons in the matrix and supports `MLDiagnosticTechnique`.
- [x] `Tests/BoomBoomBoomKitTests/` -- Tests for:
  - the crop plan (short clip, exact multiple, tail crop);
  - ranking (cap of 4, half-best floor, ties to earlier, all zero);
  - z-score zeroing;
  - 48 kHz conversion;
  - `.dspOnly` byte-identity with the technique attached;
  - service wiring with a stub conformer;
  - technique contract rejection, using a tiny 1200-wide fixture model built by a committed script.
- [x] `Tests/BoomBoomBoomKitBenchmarkTests/` (env-gated) plus a Makefile target -- Run the Swift technique on the first 20 GiantSteps rows of `scores-giantsteps.json` and record kept starts and BPM against Python.
- [x] Demo:
  - Model loading: `loadModel` tries `BNNSTechnique`, and on `invalidTensorContract` the fixed-time technique. The row and chip name the model kind ("Fixed-time, 12 s crops"). Picker help text covers both kinds.
  - Timeline: shade the kept crops on the timeline, each labelled with its rank.
  - `TraceView`: show the fixed-time abstain reason.
  - Tests: demo tests for the load fallback.
- [x] Docs: CLAUDE.md key types, README public API, DocC symbol docs. `docc-validate` must pass.

**Acceptance Criteria:**
- Given the exported model, when `make fixed-time-export` runs, then it prints the eager-vs-Core ML difference (≤ 1e-3) and writes the `.mlmodelc` outside git.
- Given the 20-track parity run, then at least 18 of 20 BPMs match Python, and every mismatch is listed in Implementation Notes with its kept starts.
- Given the demo with the fixed-time model loaded under the ML-augmented preset, when the owner analyzes a track, then:
  - the trace's ML rows show the fixed-time BPM;
  - the final BPM follows the ensemble;
  - the timeline shades 1-4 crops.
  This is the operator GUI smoke, which gates `done` per CLAUDE.md.
- Given any change, then all of these pass, and `make test` still runs every pre-existing test:
  - `make test`, `make lint`, `make docc-validate`;
  - `make demo-build`, `make demo-test`, `make demo-lint`;
  - `make release-rehearse RELEASE_REHEARSE_REF=HEAD`.

## Implementation Notes

**Export (2026-10-30).** `make fixed-time-export FIXED_TIME_RUN_DIR=/Users/rterhaar/tmp/bbbk-training/fixed-time-runs/seed_42` wrote `fixed_time_seed_42.mlmodelc` and `fixed_time_seed_42.export.json` next to `model.pt`. Check crop: the top-ranked crop (frame 0) of the bundled `robbyt_x-ray-120s.mp3`. Eager vs traced 0; eager vs Core ML max abs 4.77e-06 (limit 1e-3).

**20-track parity (`make fixed-time-parity`, same run dir).** BPM matches Python on 20 of 20 rows; the kept starts match on 17 of 20. The three start differences change no BPM:

| Track | Python kept starts | Swift kept starts | BPM (both) | Cause |
|---|---|---|---|---|
| 1030011.LOFI.mp3 | 2400, 1200, 10796, 0 | 2400, 10796, 1200, 0 | 126 | ranks 2 and 3 swap: Python scores 0.4136 and 0.4121, within float32 and decoder noise |
| 1114156.LOFI.mp3 | 0, 10797, 9000, 2400 | 0, 10795, 9000, 2400 | 172 | tail crop 2 frames earlier: the AVFoundation decode of this MP3 is 2 log-mel frames shorter than the librosa decode |
| 1240672.LOFI.mp3 | 10797 | 10795 | 86 | same tail-crop decode-length difference |

Per-track rows: `swift-parity-giantsteps.json` in the run dir.

**Choices the spec left open.**
- Kept crops also skip any crop sharing a frame with one already kept, because `fixed_time/features.py` (the named contract) does so; the Always list's short form omits it.
- Each kept crop's log-mel is computed from its own 530,807-sample slice, not sliced from a whole-track log-mel. The values are identical (each frame depends only on its own samples, confirmed by parity stage 6), and it avoids `MLFeatureFrames`' 8,388,608-float cap, which a whole-track log-mel exceeds past about 10.9 minutes.
- An out-of-range decode (`30 + argmax` outside 60...200) is returned as the evaluation's raw BPM, matching the Python rows; the ensemble octave-folds it. `BNNSTechnique` abstains there instead.
- The service passes the full decode to the technique on `analyzeBPM(decoded:)` and `analyze(decoded:)` (via an internal overload), the `maxSeconds`-capped read on the URL paths, and the union-cap decode on `analyzeFull`.
- `BPMDiagnosticTrace` has no public initializer, so the env-gated parity test uses `@testable import BoomBoomBoomKit`.
- Two pre-existing tests were edited: `RhythmicRegionIntegrationTests.legacyTraceBytes` reflects over every trace field, so the new `mlInputCrops` field (nil there) is skipped like `rhythmicRegionEvidence`; and three `HelpButtonLogicTests` cases gained `@MainActor` because `make demo-test` did not compile under Xcode 27.2 without it (the `docs` accessor is MainActor-isolated; unrelated to this change).
- `_bmad-output/.gitignore` ignores `ml-training`, so `fixed_time/export.py` and `scripts/build-fixed-time-fixture.py` need `git add -f`, like the files already tracked there.
- `fixed_time/features.py`'s `RHYTHM_SCORE_SOURCE` still names `probeRegions`; it is recorded in `crop-plan.json` and checked by training, so changing it would invalidate the existing plan. The parity harness text now names `FixedTimeCrops`.

- **Status (2026-10-30):** review is complete and every command gate passes. The spec stays `in-review` until the owner's GUI smoke in the demo, which CLAUDE.md requires before a demo-UI change is `done`.

## Spec Change Log

- **Review pass 1 (2026-10-30).**
  - **Trigger:** findings that the URL paths give the whole-track technique only the `maxSeconds` decode (the demo default is 120 s) while the Python scores read whole files, and that `analyzeBPM(url:)` and `analyzeFull` disagree.
  - **Root cause:** the Code Map said "pass the uncapped decode when one exists" without requiring that one exist. That is a bad_spec.
  - **What changed:** when the policy invokes ML and the technique is a `WholeTrackMLTechnique`, the service decodes the whole file once and caps the DSP, grid and loudness passes with `applyCap`. In every other case the reads are unchanged.
  - **Patched in place, not reverted:** the rest of the implementation passed review, and the fix touches only the decode sites.
  - **Known effect:** in this mode the capped passes read `applyCap` of the full decode. That is about 1,020 samples longer than AVFoundation's own capped read on the test WAV, so loudness gains one 100 ms block. `analyzeFull` already behaved this way whenever the loudness cap exceeded the BPM cap. `.dspOnly`, and any setup without a whole-track technique, stay byte-identical.
  - **KEEP:**
    - the crop builder and its ranking, identical to `features.py`;
    - the `BNNSTempoGraph` extraction with `BNNSTechnique` unchanged;
    - the demo's fallback load;
    - 20/20 BPM parity.

## Review Triage Log

Pass 1: blind, edge-case and verification-gap layers.

| # | Finding | Verdict | Evidence | Route |
|---|---|---|---|---|
| 1 | URL paths give the technique a capped decode; demo sees 120 s; entry points disagree; docs claim the whole track | medium | `analyzeFull` passed its union-cap decode, and the demo sets the loudness cap to the BPM cap (120 s by default) | bad_spec, patched in place (Spec Change Log) |
| 2 | `MLEvaluation` docs say conformers clamp to 60...200; `FixedTimeTechnique` returns raw and cites that doc | low | MLTechnique.swift:38,69 versus FixedTimeTechnique.swift:24; the ensemble folds ML BPMs | patch: docs reconciled |
| 3 | No cancellation and no length bound inside whole-track evaluation | medium | `FixedTimeCrops.build` has no cancellation hook; a fix changes the public protocol | defer |
| 4 | Copy-as-code snippet always emits `BNNSTechnique` | low | AnalysisViewModel.swift:842 | patch |
| 5 | Trace export drops `mlInputCrops` | medium | TraceExport.swift:300-315 gate and `MLInfo` | patch |
| 6 | Parity test does not assert kept-start agreement | low | FixedTimeParityTests.swift:111,135; spec AC gates on BPM only | defer |
| 7 | Parity uses the first 20 rows, not a band sample | low | matches the spec AC; not a defect | reject |
| 8 | Makefile hard-codes seed 42 | low | `fixed-time-export` and `fixed-time-parity` | patch |
| 9 | No tests for conversion/inference-failure abstains | medium (developer-facing) | the paths need an inference seam | defer |
| 10 | Fingerprint skips `mlInputCrops` without asserting nil | low | RhythmicRegionIntegrationTests | patch |
| 11 | CLAUDE.md key-type entries stale | low | agent-context file | defer |
| 12 | `BNNSTempoGraph` comments copied from `BNNSTechnique` (wrong links, 512, C3 messages) | low | BNNSTempoGraph.swift | patch |
| 13 | Duplicate softmax in `BNNSTechnique` and `BNNSTempoGraph` | low | merging risks `BNNSTechnique` numerics for no user benefit | reject |
| 14 | Demo compiles a fixed-time model twice on load | low | one extra compile per load; the fix adds a metadata reader | reject |
| 15 | README calls FP32 a requirement the loader does not check | low | `validateContract` checks only shapes and data types | patch: README wording |
| 16 | `FixedTimeCropSet` public init allows mismatched counts | false | the technique only consumes sets from `build(decoded:)`, which keeps them aligned | reject |
| 17 | Overflow in `rhythmScore`/`cropTensor` before the bounds guard | low | `startFrame * hopSamples` was computed first | patch |
| 18 | `evaluateWithDiagnostic` returns (nil, nil) | low | documented; the service always takes the whole-track branch first | reject |
| 19 | Abstains from `cropTensor` failures are mislabelled `conversion-failed` | low | the shape check is an internal invariant that real audio does not reach; a fix adds a public case | reject |
| 20 | `analyzeFull` whole-track input untested (gap) | medium | pre-verified | patch: tests added with #1 |
| 21 | `loadModel` kind untested; `attachMLTechnique` defaults to `.window` (gap) | low | pre-verified | patch: default removed |

## Design Notes

**Ensemble behaviour:** the ML-augmented preset weighs ML 1.5 against DSP 1.0, applied to self-reported confidence. Because the fixed-time model's top probability is uncalibrated, it may win often or rarely. The demo shows both votes (`SignalPoolDiagnosticTable` :337-341), so the owner can judge.

**Timeline sketch** (existing view, new shading only):
```
|~~~~waveform~~~~[##1##]~~~~~~[##2##]~~[#3#]~~~~~~~|
 0:00            1:12          2:30   2:51        5:40
```

## Verification

**Commands:**
- `make test`, `make lint`, `make docc-validate` -- expected: green, with the test count up only by the new tests.
- `make fixed-time-export` -- expected: max difference ≤ 1e-3, `.mlmodelc` written.
- `make demo-build`, `make demo-test`, `make demo-lint` -- expected: green.
- `make release-rehearse RELEASE_REHEARSE_REF=HEAD` -- expected: passes.

**Manual checks:**
- Owner GUI smoke on 2-3 tracks in the demo.
