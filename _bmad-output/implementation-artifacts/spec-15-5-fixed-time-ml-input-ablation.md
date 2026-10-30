---
title: 'Story 15.5: fixed-time ML input ablation harness'
type: 'feature'
created: '2026-10-29'
status: 'done'
route: 'dispatch'
review_loop_iteration: 2
baseline_commit: '0f15054da3db14a025dc73744928c6d0e8bdbcb9'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/15-5-fixed-time-ml-input-ablation.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-15-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The tempo model reads each analysis window (30, 60 or 90 s) resized to 512 columns, so its seconds per column changes from track to track. Story 12.5 ranked input representation as a cause of its misses, but nothing in the repo measures a fixed time scale against the current input.

**Approach:** A develop-only harness under `_bmad-output/ml-training/fixed_time/` that featurizes fixed 1200-frame (12 s) crops at the native 0.01 s per frame, ranks each song's crops with the library's DSP rhythm score so that training and scoring use only the most rhythmic few, trains one variant model on them with the legacy recipe, scores it with mean-of-softmax over the ranked crops, and writes paired per-track rows against the legacy model and the tempo-CNN reference. The first full run is tagged `infrastructure-smoke`; Story 12.5 owns any ranking read.

## Boundaries & Constraints

**Always:**
- **Input contract.** All audio is resampled to 44.1 kHz (the existing training loader's policy), then the v2 substrate runs up to the log-mel (FFT 2048, hop 441, 128 mels, 30 Hz to 16 kHz, no STFT padding, log1p(100x)). A crop is exactly 1200 frames (530,807 samples, owner decision 2026-10-29) with the per-band population z-score applied per crop. No resize.
- **Candidate crops.** Regular crops start every 600 frames; when they do not reach the last frame, one tail crop ends on it. A 120 s clip (11,996 frames) gives 18 regular crops plus one tail crop.
- **Rhythm ranking (owner decision 2026-10-29).** Each candidate crop is scored on its own PCM samples with the rhythm score of `RhythmicRegionSelector` (`Sources/BoomBoomBoomKit/RhythmicRegionSelector.swift`, private `score`): onset autocorrelation over lags for 60 to 200 BPM times the activity factor, ported to Python and parity-checked against Swift by passing each exact 530,807-sample crop slice to `probeRegions` with a duration that covers the whole slice and asserting the returned start and count. A song keeps at most 4 crops, walking the ranking by score (ties to the earlier start) and skipping any candidate whose frames overlap an already kept crop at all (owner decision 2026-10-29), each kept crop with a score above 0 and at least half the song's best. A song whose best score is 0 has no kept crop. The same rule selects crops for pretraining, fine-tuning and scoring.
- **Crop plan (owner decision 2026-10-29).** Training is deterministic in its data: a separate planning step (`make fixed-time-plan`) ranks every training song once and writes `crop-plan.json` to the run directory. The plan records the ranking rule, the song lists with their hashes, and for every song the kept crops (start frame, start seconds, rhythm score) or the reason it was skipped; it also fixes the full schedule: the kept crop each song uses in each of the 30 pretraining and 60 fine-tuning epochs (drawn once from `seed`), and the validation crop. Training reads only the plan, never runs the rhythm score, and refuses when the plan is missing or its rule, recipe values or song-list hashes differ from the run's. The plan's sha256 is recorded in the training metadata and the report manifest. Floating-point training on MPS is not claimed to be bit-reproducible.
- **Scoring.** Reads the whole file, bypassing the 120 s PCM cache cap, scores every candidate crop, keeps them per the ranking, and aggregates the kept crops with one named function `mean_of_softmax_ranked`; a song with no kept crop abstains `no-rhythmic-crop`. Per-crop rhythm scores, the kept crops' start frames and seconds, and the softmax of every kept crop are saved per track; decode `bpm = 30 + argmax` reported raw, including values outside 60 to 200, exactly as the legacy `decodedBPM` / `fr18ModelBPM` rows do (`BNNSTechnique.swift:842-898`; a legacy GiantSteps row reads 55); each row also carries `inRuntimeRange` for 60 to 200. No confidence gates.
- **Training recipe = legacy except the input.** maskedMelPretrain, seed 42, 30 pretraining plus 60 fine-tuning epochs, tempo-band rebalance, uniform weighting, and every other value exactly as `train.py` passes it to `run_v2` (`octave_mass=0.15`, `label_smoothing=0.1`, its `lr` and batch size, `masked_mel.DEFAULT_MASK_RATIO` and `DEFAULT_SPAN`), with the same augmentations in the same order. Before training, the script reads the archived legacy `model_metadata.json` and refuses unless its own split hash (`b89f8d7c…`) matches. The corpus hash is not required to match (owner decision 2026-10-29): the legacy run's pretraining manifests (`25e59a18…`) still held continuous DJ mixes that commit 1a697a5 removed; the variant trains on the current manifests, and the metadata, manifest and report record both corpus hashes and the row counts that differ. Both pretraining and fine-tuning see 1200-frame crops; `MelReconstructionDecoder` gets `target_frames=1200`. Training ranks candidate crops over the first 120 s of each file (the PCM cache cap, applied whether or not the cache is set). Each pretraining and fine-tuning epoch uses the kept crop the plan assigns that song for that epoch, so every appearance of a song within an epoch uses that crop; the epoch reaches the datasets through an optional per-epoch callback added to the reused `finetune` and `pretrain_encoder` loops (legacy default unchanged) and is set before each epoch's DataLoader iterator starts. Cached tensors are keyed by crop identity, never by song alone. Augmentation parameters keep the legacy per-song seeding (`seed * 1_000_003 + index`). Songs with no kept crop are removed from the record lists before the datasets and the rebalancing sampler are built, and counted in the metadata. Validation uses the plan's top-ranked crop. Fine-tuning augments a PCM segment starting at the drawn crop, long enough that a 4 % stretch still yields 1200 frames; when it would overrun the audio it shifts left by d samples, and after a stretch at rate r the crop is taken from sample round(d / r), so it covers the ranked audio. A song too short for the full segment trains that example with stretch disabled. Feature caches use a new cache version so no 512-column cache is read.
- **Corpora** (owner decision 2026-10-29): GiantSteps (661) and the 12.7 signed corpus, read-only (the 172 `locked-12.7-member` rows of the 12.9 bundle-gate seed-42 input, each file checked against its `audioSha256`). GiantSteps audio resolves through `build_fr18_input.resolve_giantsteps`.
- **Legacy and reference arms.** Both legacy dumps came from the same `giantsteps_v2_seed_42.mlmodelc` (verified). GiantSteps: `fr18-predictions-191/seed_42/predictions.json`, field `fr18ModelBPM`. 12.7: `eval-corpus/bundle-gate/predictions/seed_42/predictions.json`, field `modelBPM`. Tempo-CNN: committed `tempocnn-baseline/predictions.json`, carried forward verbatim, GiantSteps only (12.7 rows report `not-run`). Each input's sha256 is recorded.
- **Pairing and anchors.** The report requires an exact, unique track-id join across all arms (661 and 172) with equal ground-truth labels, and recomputed strict Acc1 (4 %) of 348/661 and 124/172 for legacy and 545/661 for tempo-CNN. Otherwise it writes nothing.
- **Disclosure.** The report lists every way the arms differ besides crop length, including that the variant's crops are chosen by the DSP rhythm ranking while legacy used its energy-transition window, so a delta measures crop length and crop choice together, and that legacy fine-tuning saw one fixed view per song in every epoch while the variant's crop changes by epoch.
- **Exposure disclosure.** The report counts the GiantSteps and 12.7 tracks whose audio hash is in the masked-mel pretraining pool (about 135 of 172 for 12.7), split by pool source, since the pool also holds the labelled `tony.train` audio and never calls either result unseen-audio generalization.
- Variant inference runs in Python on `model.pt`; Swift mirrors only the crop preprocessing and the rhythm score, for parity, within the existing 1e-4 absolute or 1e-3 relative tolerance (DD #15 records byte equality as unreachable).
- Before the full run, a pre-flight checks the model at `[N,1,128,1200]` and times a one-epoch subset; the agent then starts the full training (owner decision) in the background under `caffeinate`, after code review.

**Never:** change `Sources/` or `Tests/` (including `supportedFeatureSetVersion` and `currentFeatureSetVersion = "v2"`); name or load variant weights under `v2` or `giantsteps_v2_seed_*`; edit `tools/coreml-convert/`; add anything to `scripts/promote-to-main.py`; write under `eval-corpus/` or change 12-7 membership; route variant output into `SignalSource.beatGrid` / `SignalWeights.beatGrid`; compare to rekordbox.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Missing or stale plan | no `crop-plan.json`, or its rule or song-list hash differs | training refuses | exit nonzero naming the mismatch |
| Out-of-range argmax | aggregated argmax at 55 BPM | row `variantBPM: 55`, `inRuntimeRange: false`, scored as a miss | N/A |
| Normal track | 120 s GiantSteps clip | 19 candidate crops scored, up to 4 kept, kept-crop softmax saved, one aggregated BPM | N/A |
| Exact fit | 1200 + 600k frames | regular crops only, no tail crop | N/A |
| Short track | under 530,807 samples | row `abstained: shorter-than-crop`, counted as a miss | no crash |
| No rhythm | every candidate crop scores 0 (silence, drone) | scoring: row `abstained: no-rhythmic-crop`; training: song left out and counted | no crash |
| Weak crops | non-overlapping crops scoring 0.8, 0.5, 0.39, 0.1 | kept: the 0.8 and 0.5 crops only | N/A |
| Overlapping neighbours | crops at frames 0, 600, 1200 scoring 0.9, 0.85, 0.8 | kept: 0 and 1200 (600 overlaps 0) | N/A |
| 48 kHz file | 48 kHz audio | resampled to 44.1 kHz first | N/A |
| Anchor or label drift | legacy recomputes to 347, or a label differs | no report written | exit nonzero naming it |
| Missing or duplicate id | track absent in, or repeated in, an arm | no report written | exit nonzero listing ids |
| Changed 12.7 audio | sha256 differs from the bundle-gate input | run refuses | exit nonzero naming the track |
| Recipe drift | split hash or a recorded recipe value differs from legacy | training refuses | exit nonzero naming it |
| Corpus drift | current corpus hash differs from legacy | training runs; both hashes and the differing row counts recorded | N/A |

</frozen-after-approval>

## Code Map

- `_bmad-output/ml-training/feature_substrate_v2.py` -- v2 log-mel and z-score to reuse; the `TARGET_WIDTH=512` resize (:74-119) is what the variant drops.
- `_bmad-output/ml-training/ablation/ablation_features_v2.py:167,189` -- `select_window`, `transform_v2`: model the crop transform on them without changing them.
- `_bmad-output/ml-training/ablation/train_v2.py:56,90-130` -- `run_v2`; hard-wired to `feature_path="v2"`. Reuse its loops through a new entry point rather than editing its legacy path.
- `_bmad-output/ml-training/ablation/masked_mel.py:43` -- `MelReconstructionDecoder(target_frames=512)` default.
- `_bmad-output/ml-training/ablation/ablation_locator.py:223,277-302` -- `build_pretrain_audio_paths`; the PCM cache caps decode at 120 s.
- Parent checkout `_bmad-output/ml-training/v2-runs/_archive/maskedMelPretrain-seed42-191tracks-rebalance/model_metadata.json` -- legacy recipe values and hashes.
- `tools/coreml-convert/reference_arch.py:99-131` -- architecture; widest receptive field about 810 frames; `AdaptiveAvgPool2d`. Read-only.
- `_bmad-output/ml-training/build_fr18_input.py:72` -- `resolve_giantsteps`.
- `_bmad-output/ml-training/evaluate_fr18.py:89-117` -- `acc1_correct`, `octave_match`.
- `_bmad-output/ml-training/tempocnn_baseline.py:217` -- `score_rows`; 545 is strict Acc1 at 4 %, no tempo2.
- `_bmad-output/ml-training/evaluate_bundle_gate.py:24-26,95-106` -- precedent for reading signed 12.7 state read-only. Variant outputs go to `_bmad-output/ml-training/fixed-time-runs/`.
- `_bmad-output/ml-training/test_feature_parity.py`, `swift_feature_extractor/Sources/dump-model-input/` -- parity harness and Swift dump template (`@_spi(FeatureParity)`, `OnsetFeaturesBuilder`); existing parity signals are 1 s and 5 s, too short for a crop.
- `Sources/BoomBoomBoomKit/RhythmicRegionSelector.swift:64-111` -- the rhythm score to port (bins of sr/100 samples, every max(1, bin/64)th sample, mean absolute value; positive differences; centred autocorrelation over lags 30 to 100; activity = min(1, 8 x onset / energy)). Internal, read-only; `probeRegions` (internal) returns scores for evenly spaced spans and is the parity seam (SwiftPM debug builds allow `@testable import`).
- `Makefile` -- add develop-only targets next to `fr18-produce`.

## Tasks & Acceptance

**Execution:**
- [x] `_bmad-output/ml-training/fixed_time/features.py` -- 1200-frame crops, hop 600, rhythm score port, `rank_crops` (top 4, floor at half, above 0), manifest constants -- one source for training, inference and parity.
- [x] `_bmad-output/ml-training/fixed_time/plan.py` -- ranks every pretraining, train and validation song once (first 120 s), writes `crop-plan.json` with kept crops, skipped songs and the per-epoch schedule; `make fixed-time-plan`.
- [x] `_bmad-output/ml-training/fixed_time/train_fixed_time.py` -- reads the crop plan (refuses on mismatch), recipe-hash guard, pretraining plus fine-tuning on ranked 1200-frame crops drawn fresh each epoch, decoder at 1200, skipped-song counts, new cache version, `--preflight` (shape check plus timed one-epoch subset); writes `fixed-time-runs/seed_42/{model.pt,metadata.json}`.
- [x] `_bmad-output/ml-training/fixed_time/score.py` -- whole-file decode, per-crop rhythm scores and kept-crop softmax saved (`.npz`), `mean_of_softmax_ranked`, `no-rhythmic-crop` abstain, decode, per-track JSON rows; refuses on audio-hash mismatch.
- [x] `_bmad-output/ml-training/fixed_time/report.py` -- exact join, label and anchor checks, bands (<100, 100 to 140, >140 by ground truth), categories (`within-4pct`, `octave-halving`, `octave-doubling`, `non-octave-over-4pct`, `abstained`), exposure counts, the crop-choice disclosure; writes `fixed-time-report.{json,md}` and `manifest.json`.
- [x] `swift_feature_extractor/Sources/dump-fixed-time-input/`, a click parity signal long enough for two 1200-frame crops, and parity stages in `test_feature_parity.py` comparing crop tensors and rhythm scores (Swift `probeRegions` scores against the Python port on the same spans).
- [x] `_bmad-output/ml-training/tests/test_fixed_time.py` -- crop plan (19 crops at 11,996 frames, exact fit, short track), rhythm score against hand-built pulse and silence signals, ranking rule (the matrix rows), per-epoch fresh draw, aggregator, decode range, bands, categories, join, anchor, label and hash refusals, recipe-hash refusal.
- [x] `Makefile` -- `fixed-time-preflight`, `fixed-time-train`, `fixed-time-score`, `fixed-time-report`; add new files to the `py-lint` ty list.

**Acceptance Criteria:**
- Given a finished run, when `manifest.json` is read, then it records sample rate, STFT window and padding, mel schema and order, normalization formula, crop frames and seconds, hop, tail-crop rule, tensor shape `[1,1,128,1200]`, rhythm ranking rule and score source,, class schema (256 bins, 30 to 285), model identity, weights sha256, training and inference seconds per frame (equal), aggregator name, every input's sha256, and `run_kind: infrastructure-smoke`.
- Given the parity fixtures, when `make ml-parity` runs, then the new stages pass within tolerance and the legacy stage 5 still passes.
- Given the branch, when diffed against develop, then nothing under `Sources/`, `Tests/`, `tools/` or `scripts/promote-to-main.py` changed.
- Given the report, when read, then every miss carries band and category, deltas are stated against legacy and tempo-CNN, exposure counts appear, and no sentence compares to rekordbox.

## Implementation Notes

- 2026-10-29/30 run (`/Users/rterhaar/tmp/bbbk-training/fixed-time-runs/seed_42`, outside git and Dropbox; caches copied from the ssd-raid volume): crop plan sha256 `20c34a57...` (two independent builds byte-identical); 5,231 pretraining, 959 train, 108 validation songs; 3 pretraining songs shorter than one crop. Weights sha256 `f6c73002...`, final validation Acc1 0.870 (best 0.889, one top-ranked crop per song, not comparable with the legacy figure).
- MPS faults: the first full run crashed in pretraining epoch 23 (`index 887502912 is out of bounds: 0, range 0 to 32`), the restart once after epoch 0 (`value tensor of shape [744448] cannot be broadcast to indexing result of shape [930635]`), both in `loss.backward()` through the boolean-mask indexing in `masked_mel.masked_reconstruction_loss`. A 6,000-step stress test of the same step did not reproduce it. Added after review: per-epoch checkpoints with exact resume (`fixed_time/checkpoints.py`, optional hooks on the shared loops, CPU equivalence tests) and `PYTHONHASHSEED=42` in `fixed-time-train`. The final run resumed once from `pretrain-latest.pt` and finished.
- Result (infrastructure-smoke, no ranking claim): GiantSteps strict Acc1 variant 547/661, legacy 348/661, tempo-CNN 545/661; 12.7 corpus variant 158/172, legacy 124/172. Expected legacy and tempo-CNN counts recomputed exactly.

## Spec Change Log

- 2026-10-29, Codex spec review (before approval): pinned the legacy recipe and a hash guard; specified 800-frame pretraining and decoder width; added the explicit GiantSteps audio join and exact id and label pairing; fixed the sample-rate policy at 44.1 kHz; defined crops in frames with a tail crop and whole-file decode; added a 10 s parity signal, an architecture pre-flight, and the pretraining-exposure disclosure (135 of 172 12.7 tracks found in the label-free pool). Second round: the loss settings are pinned to the values `train.py` passes (`octave_mass=0.15`, `label_smoothing=0.1`), which the legacy metadata hashes do not cover.
- 2026-10-29, owner decision (review loop 1, finding B20): kept crops may not overlap; the ranking walk skips any candidate overlapping a kept crop.
- 2026-10-29, owner decision (loop 1): crop selection moves to a separate planning step that writes every kept crop's timestamps and the per-epoch schedule; training only reads that plan.
- 2026-10-29, Codex review of loop 1: the decode rule now reports the raw argmax like the legacy rows (correcting an error in the approved text); records without a kept crop are filtered before the sampler; the per-epoch draw has an explicit epoch callback, crop-keyed caches and (seed, epoch, song) seeding; the augmentation segment's shift and short-song rule are defined; parity probes exact crop slices.
- 2026-10-29, owner decision during review (loop 1): crops are 12 s (1200 frames); each song's crops are ranked by the DSP rhythm score and only the top 4 at or above half the best (and above 0) are used, in pretraining, fine-tuning and scoring, with a fresh draw each epoch. This replaces the fixed 8 s pretraining crop (finding B5) and random crops inside `select_window`. KEEP: the reviewed harness code (recipe guard and corpus-drift record, atomic artifact writes, exact join, label and anchor refusals, refusal-writes-nothing, per-source exposure, arm-difference disclosures, manifest provenance, parity path handling, tests); change crop constants, crop selection and the aggregator, and update tests to match.
- 2026-10-29, owner decision during review: the corpus hash no longer has to match. The legacy pretraining manifests predate commit 1a697a5, which removed continuous DJ mixes; the variant trains on the current manifests and records the difference. The exposure bullet now says the pool includes labelled `tony.train` audio.

- 2026-10-30, owner request after done: OA300 added as a third corpus by the follow-up spec `spec-15-5-oa300-third-corpus.md` (expected legacy 43/82). 8 of its 82 files turned out to be in the label-free pretraining pool, not 0 as first reported.

## Review Triage Log

Pass 1 (2026-10-29). Layers: blind (B), edge case (E), verification gap (V).

| # | Finding | Verdict | Evidence | Route |
|---|---------|---------|----------|-------|
| B1 | Coverage difference stated but not measured | medium | true; the npz keeps crop starts, so a first-120 s aggregate is computable, but it is a new report figure the spec does not ask for | defer |
| B2 | Decoder and engine differences between arms undisclosed | medium | `COVERAGE_NOTE` names only coverage; legacy is AVFoundation plus BNNS, variant is librosa plus PyTorch | patch (disclose); legacy-through-Python control deferred |
| B3 | Exposure called label-free, but the pool includes `tony.train` | medium | `ablation_locator.py:236-238` adds the labelled train audio | patch |
| B4 | Exposure counts byte-identical files only | low | `audioHash` is a file sha256; wording overstates completeness | patch (wording) |
| B5 | Pretraining uses one fixed 8 s crop per track, legacy a 30 to 90 s window | medium | `_pretrain_crop_rng` seeded by path, crop cached; legacy also uses one fixed view per track (`transform_unlabeled_v2`, `augment=False`) but more audio | patch (disclose in metadata and report) |
| B6 | `fixed-time-train` cannot be rerun; crash between `model.pt` and `metadata.json` strands weights | medium | `full_run` refuses on existing `model.pt`; the make target cannot pass `--overwrite` | patch |
| B7, E4 | Refused report still writes `pretraining-pool-hash-cache.json` | low | cache written before `_require` and `build_manifest` checks; contradicts "writes nothing" | patch |
| B8, E10 | Manifest is not every input's sha256 | medium | fixture self-hash, bare manifest filenames, no code git SHA, inference seconds per frame copied from training | patch |
| B9, V-o1 | `feature_parity_report.txt` records the worktree path | low | the path line changes with the checkout | patch (print a repo-relative path) |
| B10 | Makefile still calls `ml-parity` a 4-stage harness | low | stage 6 added | patch |
| B11 | Sprint row `in-progress` vs spec `in-review` | false | the workflow syncs the sprint row at step 3 and step 5 only; this is the expected intermediate state | reject |
| B12 | Missing tests (training crop, datasets, manifest, out-of-range abstain, markdown) | medium | same gaps as V1 to V4 | patch (with V1 to V4) |
| B13 | Short windows looped in training, abstained in inference | low | needs a Tony window under 8 s; select_window windows are 30 s or more except near-silent tails; adding skip logic adds branches | reject |
| B14 | Validation Acc1 measured on one centre crop, not comparable with legacy | low | direct one-line note in metadata | patch |
| V1 | `training_crop` relabelling after stretch untested | medium | pre-verified gap | patch |
| V2 | Fixed-time dataset strict and skip modes untested | medium | pre-verified gap | patch |
| V3 | `score_track` and `crop_probabilities` untested, variant arm has no anchor | medium | pre-verified gap | patch |
| V4 | `build_manifest` refusal paths untested | medium | pre-verified gap | patch |
| V-o2 | Stage 6 runs only through `make ml-parity` | false | same as stages 1 to 5 by design; crop equality is covered in pytest by `test_crop_from_pcm_equals_crop_of_whole_log_mel` | reject |
| E1 | An undecodable file aborts scoring | false | loud failure on an input not shown reachable; the end-to-end run decoded all 833 tracks | reject |
| E2 | Missing pretraining file gives a traceback, not exit 3 | low | loud failure either way; unlikely; adds handling | reject |
| E3 | Malformed prediction row gives KeyError | low | inputs are fixed dumps whose fields the anchors check; adds handling | reject |
| E5 | Ground truth 0 divides by zero in `error_category` | low | unreachable: the resolver skips bpm 0 and the label join rejects drift; crash is loud | reject |
| E6 | `--preflight-subset` 0 or negative | low | developer misuse; adds a guard | reject |
| E7 | Preflight subset above record count skews projection | low | default 32 is below every count; adds a branch | reject |
| E8 | Training reads the float16 120 s PCM cache, scoring decodes float32 whole files | medium | true; legacy training used the same cache, so only disclosure is missing | patch (record PCM source in metadata and manifest) |
| E9 | Stage 6 reshape crashes on a size mismatch | low | loud failure in a check harness; adds a branch | reject |

Pass 2 (2026-10-29, after the 12 s rhythm-ranked rework). Layers: blind (B), edge case (E), verification gap (V). Carried rows repeat a pass-1 verdict on the same claim.

| # | Finding | Verdict | Evidence | Route |
|---|---------|---------|----------|-------|
| V5, B25 | Per-epoch callback never exercised through `finetune` / `pretrain_encoder` or with workers | medium | pre-verified; dataset tests call `set_epoch` directly | patch |
| V6 | Parity stages 6 and 7 run only through `make ml-parity` | medium | pre-verified; same manual convention as stages 1 to 5; a normally run gate needs a committed Swift score fixture | defer |
| V7 | `pretraining_pool_hashes` per-source attribution untested | medium | pre-verified | patch |
| B15 | New code names expected counts "anchors", a word CLAUDE.md bans | low | CLAUDE.md naming rules list `anchor`; direct rename | patch |
| B16 | Bands merge 100 to 120 with 120 to 140 and do not match the 12.7 bands | medium | true; the three bands are the story's, a finer cut is an extra figure | defer |
| B17 | Triplet misses have no category of their own | low | the five categories are fixed by the spec | reject |
| B18 | Paired deltas carry no significance test | low | true; an exact McNemar p-value on the discordant counts is one field | patch |
| B19 | Exposure counts only the variant's pool, says "same pool", and folds `tony.train` (labelled) and unattributed paths together | medium | the corpus-drift decision made the pools differ; `tony.train` is fine-tuned with labels | patch |
| B20 | Kept crops can overlap and repeat one section | high | hop 600 vs 1200-frame crops; owner chose no overlap | intent_gap, resolved by owner |
| B21 | Augmentation draw fixed per song across epochs; seed index shifts after skipped songs | low | by spec (legacy seeding) but undisclosed; no train song is skipped in the current plan | patch (disclose) |
| B22, E18 | Plan records no audio identity; `validate_plan` checks neither validation crops nor schedule membership; corrupt JSON gives a traceback | medium | a replaced file trains on crops ranked on other audio or crashes mid-run | patch |
| B23, E13 | One undecodable file aborts scoring | false | carried: E1 pass 1 | reject |
| B24 | Stage 7 uses one click whose crops score nearly equal; activity factor below 1 never compared | medium | true; a ranking-relevant port error would pass | patch |
| B26 | Validation crop decoded every epoch despite cached crop | low | direct reorder: check the cache before decoding | patch |
| B27 | No top-crop-only or per-crop figure to separate averaging | medium | extra figure from saved softmax | defer |
| B28 | Report outputs not renamed as a set | low | needs a crash between renames; adds handling | reject |
| B29 | `masked_mel.py` error text and comment still say TARGET_FRAMES | low | direct wording correction | patch |
| E11 | Plan worker raises on a missing file with the cache set | low | loud failure before training; adds handling | reject |
| E12 | Dataset skip loop does not catch OSError or ValueError | low | covered by B22's audio-identity check before training starts | reject |
| E14 | Missing pool file at report time gives a traceback | low | carried: E2 pass 1 | reject |
| E15 | Corrupt hash cache crashes until deleted | low | loud; cache is regenerable; adds handling | reject |
| E16 | Label sources may change between score and report | medium | manifest would hash files other than those scored; a direct sha comparison | patch |
| E17 | `--preflight-subset` 0 or negative | low | carried: E6 pass 1 | reject |
| E19 | Feature-cache key omits the PCM source | low | toggling the cache would mix sources; one key field | patch |
| E20 | Relative Makefile paths resolve after `cd` | low | direct `abspath` | patch |
| E21 | Stale parity dump crashes the harness | low | carried: E9 pass 1 | reject |
| E22 | Ground truth 0 divides by zero | low | carried: E5 pass 1 | reject |
| E23 | Manifest omits `corpus_splits.json`, label and pool-durations hashes that exposure reads | low | direct addition to the hashed inputs | patch |

## Design Notes

The story's category "non-octave within four percent" cannot hold a miss, because the strict hit test is itself 4 %. Rows within 4 % are labelled `within-4pct` (a hit), and every miss is halving, doubling, or non-octave over 4 %; triplet errors land in the last.

Coverage and crop choice differ by design: the legacy rows come from the runtime's energy-transition analysis window, while the variant reads the whole file and keeps only its most rhythmic crops. The report states this next to the deltas.

The rhythm score is ported rather than called because training needs it on 12 s spans inside Python data loaders; the Swift `select` ranks only up to eight 30 s probes.

## Verification

**Commands:**
- `cd _bmad-output/ml-training && uv run pytest tests/test_fixed_time.py` -- passes
- `make ml-dump-fixture && make ml-parity` -- all stages pass
- `make py-lint` and `make lint` -- clean
- `make fixed-time-preflight` -- shape check passes and prints a projected full-run time
- `make fixed-time-report` -- refuses on a tampered anchor; writes the report on the real inputs
