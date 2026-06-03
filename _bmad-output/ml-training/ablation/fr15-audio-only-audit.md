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
