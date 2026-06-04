# FR-15 audio-only audit (AC7) — KDD-B2 ablation harness

Story 7.3 / AC7 / DD #4. Develop-only.

FR-15 requires the trained tempo model to consume AUDIO ONLY. This audit records
how the harness enforces that, and the grep result.

## Locator vs feature transform (the boundary)

The literal epic grep `rg -i "playlist|path|rekordbox|artist|id3" ablation/*.py`
is unsatisfiable as written — the harness MUST reference a path to fetch audio
bytes (`relPath`/`local_path`/`pathlib`). So the boundary is drawn structurally
(the Story 7.2 AC9 distinction: a file LOCATOR is not a model FEATURE):

| module | role | references paths? | FR-15 grep scope |
|---|---|---|---|
| `ablation_features.py` | **feature transform** — pure `transform(pcm, sample_rate, bpm) -> Tensor` | NO | **IN scope (must be zero)** |
| `ablation_locator.py` | **file locator** — manifest/labels read + `relPath`/`local_path` -> decoded PCM | YES (by design) | out of scope (locator, not feature) |

## Structural enforcement (not grep-alone)

1. **Pure feature transform.** `ablation_features.transform(pcm, sample_rate, bpm, ...)`
   takes NO track-metadata object — only decoded PCM + the BPM label. It reuses
   the FR-15-clean `dataset.extract_log_mel`/`sample_window`/`zscore_per_band`
   (PCM-only) helpers.
2. **One-way import direction.** `ablation_features.py` does NOT import
   `ablation_locator` (verified: `rg "import ablation_locator" ablation_features.py`
   -> no hits). The locator imports the features, never the reverse — so the grep
   is a backstop, not the primary defense.
3. **Data-boundary contract.** The only values flowing from the locator into the
   feature pipeline are `{pcm, sample_rate, audioHash/track_id (bookkeeping), bpm}`.
   For the supervised set, `bpm` is ONLY the Tony consensus `bpm_truth` from
   `tony-truth-labels.json` (the locator's `LabeledRecord` exposes exactly
   `{track_id, audio_path, bpm}` — never an ID3/DSP/Rekordbox BPM, never
   `signals`/`artist`/`album`/`playlist`). For masked-mel pretraining there is NO
   label.
4. **No forbidden-signal-driven control flow.** No filtering, augmentation choice,
   weighting, or label derivation consults playlist/path/artist/ID3/Rekordbox/DSP
   fields.

## Grep result

`rg -in "playlist|rekordbox|artist|id3|path" ablation/ablation_features.py`
returns hits ONLY in the module docstring + a `# noqa` comment (lines naming the
forbidden tokens to document the rule, and the `# (sibling module on the inserted
sys.path)` import comment) — **zero hits in executable code** (comments and
docstrings excluded per AC7). The `transform`/`transform_unlabeled` function
bodies reference only `pcm`, `sample_rate`, `bpm`, `fixture`, `rng`, and
`weighting_profile`.

## Unsupervised-manifest cleanliness (AC9)

The masked-mel pretraining manifest (`non-rekordbox-unsupervised-pretrain-manifest.json`)
carries ONLY `{audioHash, relPath}` — `relPath` is a byte LOCATOR (used to fetch
audio), never a model feature; the survey's forbidden columns
(`dspBPM`/`dspConfidence`/`fileMetadataBPM`) are dropped at build time
(`build_unsupervised_manifest.py`). Asserted by
`tests/test_ablation_data.py::test_unsupervised_manifest_is_fr15_clean`.

## Story 7.4 addendum — Marginal diagnostic artifacts (AC10 / DD #12)

Story 7.4 produces two develop-only DIAGNOSTIC artifacts that intentionally
CONTAIN forbidden-as-FEATURE content (DSP BPM/confidence, Rekordbox/grid BPM,
playlist relation): `marginal-failure-categorization.json` and
`marginal-watchlist.json`. FR-15 governs MODEL INPUTS — a diagnostic file
containing these signals is fine; the risk is a feature-transform / training
path READING one of them. That risk is closed two ways:

1. **Filename grep (extended scope).** The FR-15 audit greps the
   feature-transform / training code paths (`dataset.py`, `train.py`,
   `ablation/ablation_features.py`, `ablation/train_*.py`,
   `ablation/build_unsupervised_manifest.py`) for the two artifact filenames and
   for the categorization module name (`marginal_failure_categorize` /
   `marginal-failure-categorize`) — **zero matches required**.
2. **Test enforcement.** Asserted by
   `ablation/tests/test_marginal_categorization.py::test_no_training_path_reads_marginal_artifacts`.

The boundary mirrors the Story 7.2 AC9 / 7.3 DD #4 locator-vs-feature
distinction and is also recorded in `marginal-failure-categorization.md`.

## Story 7.5 addendum — substrate v2 feature path (AC4 / DD #13 / DD #15)

Story 7.5 swaps the v2 model-input feature SOURCE off the librosa
`ablation_features.py` pipeline (v1 scaffolding, DD #1/#13) and onto the
substrate-locked `OnsetFeatures` envelope, so the trained model sees the same
bytes `BNNSTechnique.featurize` produces at runtime (FR-21). AC4 requires the
FR-15 boundary be re-affirmed for the three v2 files.

| module | role | references forbidden signals as a FEATURE? |
|---|---|---|
| `feature_substrate_v2.py` | **feature transform** — substrate log-mel -> `[128, 512]` model-input tensor | NO |
| `swift_feature_extractor/Sources/dump-model-input/main.swift` | **Swift parity dump** — single-sources `BNNSTechnique.modelInputTensor(from:)` | NO |
| `train.py` (v2 path) | **trainer** — substrate-v2 loop is fail-closed until wired (see below) | NO |

1. **`feature_substrate_v2.py` consumes ONLY the substrate log-mel.**
   `model_input_tensor_from_audio` calls `dataset.extract_log_mel(audio, fixture)`
   (decoded PCM in, mel-major log-mel out) then applies per-band z-score +
   resample-to-512. Those two are SHAPE transforms matching
   `BNNSTechnique.featurize` (transpose -> z-score -> resample) — FR-15 forbids
   new SIGNALS, not the mandatory shape transforms (the masked-mel encoder's
   mask-value-`0` assumption is calibrated to a z-scored distribution, so the
   z-score MUST be applied; DD #15 / AC4). No playlist/path/Rekordbox/artist/
   ID3-BPM/DSP-candidate-score signal enters. It does NOT import
   `ablation_locator`, `ablation_features` (librosa), or any metadata reader.
2. **The Swift `dump-model-input` CLI takes no track-metadata object.** It reads
   the `parity_signals/{sine,click}.f32` PCM fixtures, runs the REAL
   `OnsetFeaturesBuilder.build(.uniform)` -> `BNNSTechnique.modelInputTensor`,
   and dumps the post-featurize tensor. Single-sourcing `modelInputTensor`
   guarantees the transpose/z-score/resample have ONE implementation across
   runtime + dump — no separate signal path exists to leak a forbidden field.
3. **`train.py`'s v2 substrate loop is fail-closed today — this records the
   boundary the operator's wire-up MUST honor, NOT a claim it runs now.**
   `train.py` raises `NotImplementedError` unless `--allow-legacy-giantsteps`
   is explicitly passed (the S1 fail-closed guard); the substrate-v2 loader is
   the operator's gated step. When wired, the ONLY values flowing from the
   locator into the feature pipeline are `{pcm, sample_rate, track_id
   (bookkeeping), bpm_truth}` — `bpm_truth` is the Tony consensus label from
   `tony-truth-labels.json`, never an ID3/DSP/Rekordbox BPM. The legacy
   GiantSteps path remains explicitly historical, reachable only behind the
   opt-in flag.

### Grep result (extended scope)

`rg -in "playlist|rekordbox|artist|id3|dspBPM|dspConfidence|fileMetadataBPM" \
  feature_substrate_v2.py train.py swift_feature_extractor/Sources/dump-model-input/main.swift`
returns hits ONLY in docstrings/comments that name the forbidden tokens to
document this rule — **zero hits in executable code**. The
`feature_substrate_v2` transform bodies reference only `mel_major`, `audio`,
`fixture`, `frames`, `width`, `mean`/`std`, and the control-vector scalars; the
Swift dump references only the PCM payload + `OnsetFeaturesBuilder` /
`modelInputTensor`.
