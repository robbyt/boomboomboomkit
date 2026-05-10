# Bundled Reference Models — Model Card

This document is the authoritative source for accuracy, training-corpus, and limitations data on every Core ML model bundled with `BoomBoomBoomKit`. Update one entry per model whenever a new bundled artifact ships under `Sources/BoomBoomBoomKitML/Resources/`.

> **Reading this card before enabling ML?** Short version: **the bundled reference models are not the recommended accuracy default.** They exist to validate the `MLTechnique` plug-in surface and provide a known tensor/metadata contract for bring-your-own-model (BYOM) workflows. Production tempo accuracy should come from the DSP pipeline (default `Options.intensity = .default`) or from a model you trained or selected yourself.

---

## Naming convention

Bundled models are named `<corpus>_v<version>.mlmodelc` where:
- **`<corpus>`** identifies the training source (e.g., `giantsteps`, `oa300`, `mixed`).
- **`v<version>`** is an integer suffix bumped on every re-train. `v1` is the first ship; `v2` would be a follow-up trained against the same or expanded corpus.

Examples of future names: `giantsteps_v2.mlmodelc`, `oa300_v1.mlmodelc`, `mixed_v1.mlmodelc`. Never overwrite a `v1` artifact in place once it has shipped to `main` — bump the version.

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
| Held-out test | OA300 (project-internal corpus) | 82 | Cross-corpus generalization measurement (NEVER seen during training) |

Training: 60 epochs, Adam optimizer (lr=1e-3, cosine decay), CE loss with label smoothing 0.1, on-PCM augmentation (time-shift, ±4% tempo stretch via `scipy.signal.resample`, ±6 dB gain, pink noise SNR 30-50 dB). Total wall-clock 12,460s (3.46h) on Apple M5 Max with PyTorch MPS, seed 42. Reproducible at the Python level; PyTorch MPS does not guarantee bit-reproducibility across macOS minor versions.

### Measured accuracy

| Metric | Bundled model | DSP pipeline (`intensity = 7`) | Δ |
|---|---|---|---|
| OA300 Acc1 (within ±2% BPM) | **39.0%** (32/82) | **70.7%** (58/82) | **−31.7 pp (worse)** |
| OA300 Acc2 (within ±4% BPM, MIREX-style) | 48.8% (40/82) | 90.2% (74/82) | −41.4 pp (worse) |
| OA300 strict (within ±0.5 BPM) | 8.5% (7/82) | n/a (DSP doesn't quantize to bins) | — |
| GiantSteps fold01 val (within ±4%) | 81.8% | n/a | — |

**The bundled reference model is meaningfully WEAKER than the existing DSP pipeline on the same held-out corpus at the same tolerance.** Do not enable ML expecting an accuracy improvement over DSP-only without first validating against your own corpus.

### Known limitations

1. **Bin collapse on common BPMs.** Per-track prediction analysis shows the model concentrates outputs on a small number of bins. Across the 82-track OA300 test:
   - 13 tracks predicted at exactly 172 BPM
   - 12 tracks at 152 BPM
   - 10 tracks at 117 BPM
   - 3 tracks at 176 BPM
   This is the model learning the prior distribution of the GiantSteps training corpus rather than discriminating individual track tempos. Symptom: low confidence on tracks whose true tempo is far from the dominant training bins.

2. **Half-tempo doubling on slow material.** Tracks with ground truth in the 80-90 BPM range are routinely predicted at the doubled rate (≈170 BPM). Examples from OA300:
   - 85 BPM → 176, 172, 169
   - 86 BPM → 172
   - 84.92 BPM → 169 / 172
   - 82.86 BPM → 168
   The model has effectively learned "DnB-shaped audio ≈ 170 BPM" and applies it bluntly. This is the same failure mode the DSP pipeline exhibits on a smaller subset, so the bundled model does not help on the cases where help is most needed.

3. **Named DnB triplet failures.** Four tracks the project tracks as a regression baseline (Charly @ 160, Faraday_Bunker @ 170, Yin Yang @ 170, HEFT_Anagram @ 170) all fail the strict ±0.5 BPM gate: predicted 152, 176, 176, 180. Range is approximately right; precision is not.

4. **Architecture limit.** 315k-param shallow CNN trained on ≈600 tracks is a small model on a small corpus. Tempo-CNN literature (Schreiber & Müller 2018, Foroughmand & Peeters 2019) trains on ≈10× more data; expecting parity with their published numbers from this bundled artifact is unrealistic.

### Reproducibility

The training pipeline that produced this artifact lives on the `develop` branch at `_bmad-output/ml-training/`. It is **not shipped to `main`** — that directory contains project-internal corpus paths, env-var conventions, and reproducibility scaffolding. To re-train:

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
2. Convert: `cd tools/coreml-convert && uv run python convert.py --checkpoint your.pt --arch reference --output ../../_bmad-output/ml-models/<corpus>_v1.mlmodel`
3. Compile: `make compile-model ML_MODEL_INPUT=_bmad-output/ml-models/<corpus>_v1.mlmodel`
4. **Append a model-card entry to this file** with: corpus split, training config, measured accuracy on OA300 (project regression set), known limitations, reproducibility instructions.
5. Update `BoomBoomBoomKitML/Sources/...` to load the new artifact (Story 4-5 ships `BNNSTechnique` with `bundledReferenceURL` — point it at the new artifact).
6. The previous bundled `<corpus>_v(N-1).mlmodelc` may be removed in the same commit OR retained as a co-bundled fixture for migration testing — your call. Pre-1.0, removal is fine; post-1.0, retain at least one prior version for one minor release.

## License

The bundled `giantsteps_v1.mlmodelc` is distributed under the same license as `BoomBoomBoomKit` (see [LICENSE](./LICENSE)). The training corpora (GiantSteps Tempo Dataset, OA300) are not redistributed by this repository; consumers wanting to re-train can obtain them from their original sources.

Consumer-supplied bundled models inherit the consumer's license obligations — see `tools/coreml-convert/README.md` Path C for AGPL and other non-permissive-license guidance.

---

_This card is the source of truth for bundled-model accuracy. If a story or marketing copy contradicts it, this card wins. Update on every new bundled model._
