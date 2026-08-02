# Bundled Reference Models — Model Card

This document is the authoritative source for accuracy, training-corpus, and limitations data for any Core ML model bundled with `BoomBoomBoomKit`. Update one entry per model whenever a new bundled artifact ships under `Sources/BoomBoomBoomKitML/Resources/`.

## Status (as of Story 4-6, 2026-05-16)

**No bundled model ships in `BoomBoomBoomKit`.** Story 4-6 (BNNS ML Accuracy Investigation and Bundle Decision) removed the previously-bundled `giantsteps_v1.mlmodelc` from `Sources/BoomBoomBoomKitML/Resources/` after the diagnostic instrumentation pass confirmed:

- `ml_acc1 = 0/82` at production thresholds (`confidence ≥ 0.50`, `margin ≥ 0.10`)
- `ml_acc1 = 2/82` even with the two-gate abstain disabled (`0.00/0.00`); `wrong_non_abstain_count = 54/82`
- `softmax_max_p95 = 0.294` — 95th percentile of model confidence falls below the production gate
- bimodal predictions clustered at 125 and 175 BPM regardless of input
- `make ml-parity` PASSES — Swift/Python featurize agree, so the failure is the model itself, not the featurize step
- lowering thresholds destroys safe behavior: `dsp_correct_controls_preserved` collapses 4/4 → 0/4

**The framing here matters.** This is not "ML doesn't work for BPM detection" — it is **this reference model (`giantsteps_v1.mlmodelc` trained on lossy 96 kbps GiantSteps MP3) doesn't generalize past its training distribution.** The BNNSTechnique infrastructure (load, featurize, inference, two-gate, diagnostic capability) is unchanged and ready to consume a higher-quality model when one is trained. The training pipeline remains operational on the development branch, where the previous checkpoint is also preserved for historical reproduction.

**What this means for consumers today:**

- `Options.mlTechnique = nil` (default) → DSP-only. Recommended for production until a higher-quality bundled model returns.
- `try? BNNSTechnique()` → returns `nil` because the no-arg form throws `.modelResourceMissing` (the static `bundledReferenceURL` is now `nil`).
- `try? BNNSTechnique(modelURL: yourURL)` → BYOW (bring-your-own-weights). Train against the same NCHW `(1, 1, 128, 512)` tensor contract or implement a custom `MLTechnique` conformance from scratch. See `tools/coreml-convert/README.md`.

**Re-open trigger.** (Attempted and not met. See the 2026-07-26 status update below.) A future Branch-A retrain story re-bundles a higher-quality model (≥ 2/4 named DnB triplets resolved AND 4/4 DSP-correct controls preserved at production thresholds, per Story 4-6 Task 15). At that point `BNNSTechnique.bundledReferenceURL` flips back to a non-nil `Bundle.module.url(...)` lookup and this Status section gets a new entry below the historical one.

## Status update (2026-07-26): retrain completed, evaluated, still no bundled model

**No bundled model ships.** A full retrain against a 1,534-track labeled corpus was completed and evaluated in June 2026. It did not reach bundling quality, so the position above is unchanged. This section records the outcome so the "ready to consume a higher-quality model when one is trained" framing above is not read as untested optimism.

Measured on the retrained model (`maskedMelPretrain`, seed 42, `featureSetVersion` v2, tempo-band rebalanced), run through the production Swift inference path with `EnsemblePolicy.mlOnly`:

- Internal evaluation corpus (82 tracks) Acc1 **43/82 (52.4%)** against a bundling bar of more than 55/82
- GiantSteps Acc1 **348/661 (52.6%)** against a bundling bar of at least 537/661

Both model figures were scored at 4% tolerance, while the two bars are DSP results at 2% tolerance. The looser standard was applied to the model and it still finished 13 tracks below the internal-corpus bar and 189 below the GiantSteps bar.

Three successive retrains, each adding labels, produced 50/82, 48/82, 43/82 on the internal corpus and GiantSteps 296/661, 330/661, 348/661. Tracks below 120 BPM stayed at 2 of 95 correct across all three runs. The third batch, weighted toward 120-140 BPM, gained 32 tracks in that band and lost 16 in 140-160 and 2 above 175 BPM.

The reading the project takes from this is that the limit is structural rather than a shortage of labels. Below 100 BPM the model predicts exactly twice the true tempo on 38 of 60 tracks, so the band is octave-shifted rather than random. Between 100 and 120 BPM it is mis-pulsed instead, and octave tolerance recovers nothing (1 of 35 either way). An octave-aware training loss was already in place throughout, so the defect is not in the loss function. Where it does sit has not been isolated: the input representation and the argmax decode are both candidates, and an octave-folded decode was later measured on this model and made accuracy worse rather than better.

Confidence calibration was not measured on this model. The decision was reached on accuracy alone, so the calibration question is open rather than answered.

**What this means for consumers.** Nothing changes in the API surface. `Options.mlTechnique = nil` remains the default and remains the recommendation for production. `BNNSTechnique(modelURL:)` remains the bring-your-own-weights path and the NCHW `(1, 1, 128, 512)` tensor contract below is unchanged. The retrained model is kept on the development branch as a BYOW reference, for reproduction and as a baseline to beat. It is not recommended for production use: on the numbers above, DSP alone is more accurate on both corpora.

The pre-Story-4-6 model-card content is preserved below for historical accuracy and as the architectural reference for BYOW consumers targeting the same `TempoCNN` shape.

---

## Naming convention

Bundled models are named `<corpus>_v<version>.mlmodelc` where:
- **`<corpus>`** identifies the training source (e.g., `giantsteps`, `mixed`).
- **`v<version>`** is an integer suffix bumped on every re-train. `v1` is the first ship; `v2` would be a follow-up trained against the same or expanded corpus.

Examples of future names: `giantsteps_v2.mlmodelc`, `mixed_v1.mlmodelc`. Never overwrite a `v1` artifact in place once it has shipped to `main` — bump the version.

**The existing `giantsteps_v2_*` artifacts violate this convention and are misnamed
(recorded 2026-08-01, GH-152).** They are trained on the private Tony corpus;
GiantSteps is *external evaluation only* and contributes no training data to them.
Read `giantsteps` in a `v2` filename as an inherited prefix, not a claim about the
training source. `v1` is correctly named — it was GiantSteps-trained.

Renaming the artifacts is deferred rather than done: the names are load-bearing in
`export.py`'s default, the `make ml-export-v2` target, and the Story 7.6 FR-18
prediction dumps, so a rename is a coordinated change rather than a text edit. Until
then this note is the correction of record.

---

## `giantsteps_v1.mlmodelc`

`Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/`

**Status:** reference fixture, NOT default accuracy model. Ships for adapter-validation and as a smoke-test reference for `BNNSTechnique`. Consumers wanting tempo-classification quality should provide their own `MLTechnique` conformance or convert their own checkpoint with `tools/coreml-convert/`.

### Architecture

| Property | Value |
|---|---|
| Architecture | Schreiber & Müller 2018 — shallow multi-filter CNN, 3 conv blocks (scaled down) |
| Parameters | 315,096 |
| Input shape | `(1, 1, 128, 512)` NCHW float32 (1 channel × 128 mel bands × 512 time frames) |
| Output shape | `(1, 256)` logits over 256 BPM bins |
| BPM bin schema | bin index `i` → BPM `i + 30` (range 30 to 285 BPM inclusive) |
| Tensor names | `input`, `output` |
| Compute units | `CPU_ONLY` (consumed via BNNSGraph in `BoomBoomBoomKitML`; ANE not used) |
| Compute precision | `FLOAT32` (1.25 MB `.mlpackage`, 1.2 MB compiled `.mlmodelc`) |
| Min deployment target | macOS 15 |

### Training corpus

| Split | Source | Tracks | Used for |
|---|---|---|---|
| Train | GiantSteps Tempo Dataset folds 02-10 | 595 | Gradient updates |
| Validation | GiantSteps Tempo Dataset fold 01 | 66 | Per-epoch monitoring + early-stop signal |
| Held-out test | Project-internal evaluation corpus v1 | 82 | Cross-corpus generalization measurement (held out from training under the project's evaluation protocol) |

Training: 60 epochs, Adam optimizer (lr=1e-3, cosine decay), CE loss with label smoothing 0.1, on-PCM augmentation (time-shift, ±4% tempo stretch via `scipy.signal.resample`, ±6 dB gain, pink noise SNR 30-50 dB). Total wall-clock 12,460s (3.46h) on Apple M5 Max with PyTorch MPS, seed 42. Reproducible at the Python level; PyTorch MPS does not guarantee bit-reproducibility across macOS minor versions.

### Measured accuracy

| Metric | Bundled model | DSP pipeline (`intensity = 7`) | Δ |
|---|---|---|---|
| Internal-eval Acc1 (within ±2% BPM) | **39.0%** (32/82) | **70.7%** (58/82) | **−31.7 pp (worse)** |
| Internal-eval Acc2 (within ±4% BPM, MIREX-style) | 48.8% (40/82) | 90.2% (74/82) | −41.4 pp (worse) |
| Internal-eval strict (within ±0.5 BPM) | 8.5% (7/82) | n/a (DSP doesn't quantize to bins) | — |
| GiantSteps fold01 val (within ±4%) | 81.8% | n/a | — |

**The bundled reference model is meaningfully WEAKER than the existing DSP pipeline on the same held-out corpus at the same tolerance.** Do not enable ML expecting an accuracy improvement over DSP-only without first validating against your own corpus.

### Known limitations

1. **Bin collapse on common BPMs.** Per-track prediction analysis shows the model concentrates outputs on a small number of bins. Across the 82-track internal evaluation corpus:
   - 13 tracks predicted at exactly 172 BPM
   - 12 tracks at 152 BPM
   - 10 tracks at 117 BPM
   - 3 tracks at 176 BPM
   This is the model learning the prior distribution of the GiantSteps training corpus rather than discriminating individual track tempos. Symptom: low confidence on tracks whose true tempo is far from the dominant training bins.

2. **Half-tempo doubling on slow material.** Tracks with ground truth in the 80-90 BPM range are routinely predicted at the doubled rate (≈170 BPM). Examples from the internal evaluation corpus:
   - 85 BPM → 176, 172, 169
   - 86 BPM → 172
   - 84.92 BPM → 169 / 172
   - 82.86 BPM → 168
   The model has effectively learned "DnB-shaped audio ≈ 170 BPM" and applies it bluntly. This is the same failure mode the DSP pipeline exhibits on a smaller subset, so the bundled model does not help on the cases where help is most needed.

3. **DnB triplet failures.** Four tracks the project tracks as a regression baseline (identified by the first 12 hex of the SHA-256 of their audio: `b4ede997273b` @ 160, `4637a3e45499` @ 170, `0a725edfccc2` @ 170, `a81b58e80e71` @ 170) all fail the strict ±0.5 BPM gate: predicted 152, 176, 176, 180. Range is approximately right; precision is not.

4. **Architecture limit.** 315k-param shallow CNN trained on ≈600 tracks is a small model on a small corpus. Tempo-CNN literature (Schreiber & Müller 2018, Foroughmand & Peeters 2019) trains on ≈10× more data; expecting parity with their published numbers from this bundled artifact is unrealistic.

### Reproducibility

The training pipeline that produced this artifact lives on the `develop` branch. It is **not shipped to `main`**: it hardcodes project-internal corpus paths, env-var conventions, and reproducibility scaffolding that a consumer cannot act on. To re-train:

```bash
git checkout develop
make ml-train-deps
make ml-train          # 60 epochs ≈ 3.5h on Apple M5 Max + PyTorch MPS
make ml-export
make compile-model
```

(Run from the project root. The `ml-*` targets fail loudly on a `main`-only checkout — the training pipeline lives only on `develop`.)

If you want to ship a different bundled model (or replace this one), see "Adding a new bundled model" below.

---

## When NOT to use the bundled model

- You expect the library to "just work" on accuracy. Use DSP-only (`Options.intensity = .default`, `Options.mlTechnique = nil`).
- You want a tempo classifier you can rely on at production scale. Train your own; convert with `tools/coreml-convert/`.
- You target half-tempo or non-Western-electronic content. The bundled model is corpus-biased toward the GiantSteps EDM distribution.

## When to use the bundled model

- You're integrating `BoomBoomBoomKitML` for the first time and want to verify the end-to-end pipeline (load → featurize → predict → score) with a known artifact.
- You're writing tests against the `MLTechnique` plug-in surface and need a deterministic loaded-model fixture.
- You're prototyping ensemble logic (DSP + ML) and need a known-quality ML output to test policy code.

## How to override

```swift
import BoomBoomBoomKit
import BoomBoomBoomKitML

var options = AudioAnalysisService.Options()
let yourModelURL = Bundle.main.url(forResource: "your_model", withExtension: "mlmodelc")!
options.mlTechnique = try? BNNSTechnique(modelURL: yourModelURL)
let result = try await AudioAnalysisService.analyzeBPM(url: trackURL, options: options)
```

See `tools/coreml-convert/README.md` for the four consumer paths (same-arch override, custom-arch via `MLTechnique` conformance, third-party model with non-permissive license, runtime wiring).

---

## Adding a new bundled model

1. Train your model. The architecture must honor the contract documented above (input/output shapes + tensor names) OR you ship a custom `MLTechnique` conformance that featurizes appropriately.
2. Convert: `cd tools/coreml-convert && uv run python convert.py --checkpoint your.pt --arch reference --output ../../build/models/<corpus>_v1.mlmodel`
3. Compile: `make compile-model ML_MODEL_INPUT=build/models/<corpus>_v1.mlmodel ML_MODEL_OUT_DIR=build/models`
4. **Append a model-card entry to this file** with: corpus split, training config, measured accuracy on the internal evaluation corpus, known limitations, reproducibility instructions.
5. Update `BoomBoomBoomKitML/Sources/...` to load the new artifact (Story 4-5 ships `BNNSTechnique` with `bundledReferenceURL` — point it at the new artifact).
6. The previous bundled `<corpus>_v(N-1).mlmodelc` may be removed in the same commit OR retained as a co-bundled fixture for migration testing — your call. Pre-1.0, removal is fine; post-1.0, retain at least one prior version for one minor release.

---

## Beat-grid acceptance (DSP, not an ML model)

The beat grid is a pure-DSP feature (no model involved), but its accuracy is disclosed here alongside the model accuracy for a single place to judge what the library promises.

- **Metric:** standard MIR beat **F-measure** at a **±70 ms** tolerance, with tempo-octave equivalence allowed (a correct half- or double-time grid is not penalized).
- **Reference:** a beat grid exported from DJ software, over a real-world, constant-tempo drum & bass corpus.
- **Measured mean F-measure:** **≈ 0.37**, with a committed regression floor of **0.33** enforced by the test suite.
- **Opt-in downbeat detector:** deliberately conservative. It abstained on about 96% of the corpus, firing on 54 of 1,264 tracks. Across the 42 constant-tempo tracks where it did fire, mean octave-tolerant downbeat F-measure was **0.14**. Treat a detected downbeat as a hint, not a guarantee.
- **Long-file grid divergence:** across constant-tempo tracks of 5 minutes or longer, the last entry in `beats` and the anchor-plus-tempo extrapolation of that same beat index differ by a median of about **0.18 s** and a 95th percentile of about **1.65 s**. The test suite holds that 95th percentile under a 2.0 s ceiling. This is a divergence between two views of the same grid, not a measured error against a reference, and it does not establish which view is closer to the audio: `beats` carries per-beat onset quantization and the occasional dropped or doubled beat, while the extrapolation applies a single tempo across the whole track. **For sync, use the anchor plus tempo extrapolation, not the raw `beats` array.**

That F-measure is roughly half the 0.75 the project targeted. The disagreement with the reference is dominated by fine tempo and phase error that accumulates across a track rather than by gross mistakes, on heavily-produced material scored against an auto-analyzed reference. For sync-critical work, prefer the anchor + tempo extrapolation over the raw `beats` array. The divergence figure above shows the two views are not interchangeable late in a long track; the reason to pick the extrapolation is that it is the library's canonical playable grid, not that the measurement proves it sits closer to the audio. Gate on `confidence`, and validate against your own material.

The tracker assumes a constant tempo throughout. It does not detect or adapt to accelerando, rubato, or tempo-change sections, and on variable-tempo material the beats drift out of phase.

## License

The bundled `giantsteps_v1.mlmodelc` is distributed under the same license as `BoomBoomBoomKit` (see [LICENSE](./LICENSE)). The GiantSteps Tempo Dataset used for training is publicly available from its original source and is not redistributed here; the project-internal evaluation corpus is private and is not published.

Consumer-supplied bundled models inherit the consumer's license obligations — see `tools/coreml-convert/README.md` Path C for AGPL and other non-permissive-license guidance.

---

_This card is the source of truth for bundled-model accuracy. If a story or marketing copy contradicts it, this card wins. Update on every new bundled model._
