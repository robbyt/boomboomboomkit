# BoomBoomBoomKit — Tempo Classifier Training Pipeline (Story 4-4b)

Dev-only training pipeline for the reference tempo classifier `tempo_classifier.mlmodelc` consumed by Story 4-5's `BNNSTechnique`. Local PyTorch + MPS training on M5 Max against GiantSteps (train/val) + OA300 (held-out test).

**This directory lives ONLY on `develop` — it does NOT ship to `main`.** The release process (project-context.md §"Development Workflow Rules" — "What goes to main") excludes `_bmad-output/` from squash-merges. Only the produced `Sources/BoomBoomBoomKitML/Resources/tempo_classifier.mlmodelc/` artifact ships to `main`. The consumer-facing convert tool that DOES ship to `main` lives at `tools/coreml-convert/` (Story 4-4b DD #13).

## Setup

```bash
cd _bmad-output/ml-training
uv sync --locked    # installs torch, torchaudio, librosa, coremltools, etc.
```

Required environment variables (the Makefile-default paths work on Robby's setup):

| Var | Default | Used by |
|---|---|---|
| `OA300_CORPUS_PATH` | `/Users/rterhaar/Dropbox/OA300_OnsetAudio300` | `dataset.py`, `eval.py` (held-out test) |
| `GIANTSTEPS_CORPUS_PATH` | `/Users/rterhaar/Dropbox/research/giantsteps-tempo-dataset` | `dataset.py` (train/val) |

Required system tools (verify with `brew list`):
- `ffmpeg` — librosa's m4a/aac decode backend (DD #5)

## Workflow

```bash
# 1. Build shared filterbank fixture from Swift (Task 3 — AC #3 Part A)
cd swift_feature_extractor && swift run dump-fixture && cd ..

# 2. Verify feature parity Python ↔ Swift (AC #3 Part B four-stage tolerance)
uv run python test_feature_parity.py

# 3. Smoke train (1 epoch, 32 tracks, must complete < 2 min — AC #8 / Task 5.5)
uv run python train.py --seed 42 --epochs 1 --subset 32

# 4. Full train (60 epochs; ≤ 6h wall-clock HALT ceiling — AC #8 / Task 5.6)
tmux new-session -d -s train 'uv run python train.py --seed 42 --epochs 60'

# 5. Eval against OA300 held-out test set (AC #11)
uv run python eval.py --checkpoint model.pt --test-corpus oa300

# 6. Export to CoreML (AC #9 — separate CPU-only script per Apple convention)
uv run python export.py --checkpoint model.pt --output ../ml-models/tempo_classifier.mlmodel

# 7. Compile .mlmodelc via Story 4.1 Makefile target
cd ../.. && make compile-model
```

## Files in this directory

Source:
- `pyproject.toml`, `uv.lock` — dep manifest, locked.
- `model.py` — `TempoCNN` definition. **Imports the canonical reference architecture from `tools/coreml-convert/reference_arch.py`** (DD #13, codex Med #6 — single source of truth).
- `dataset.py` — corpus split logic + Python feature extractor reading the shared fixture.
- `train.py` — training loop. MPS device, Adam + cosine, CE loss with label smoothing 0.1, on-PCM data augmentation.
- `export.py` — CPU-only export. eager-vs-traced `torch.allclose` HALT (b) + `coremltools.convert(macOS14, CPU_ONLY, mlprogram)` + tensor-name verification.
- `eval.py` — runs trained `.mlmodel` via `coremltools.MLModel.predict` against OA300; emits three named accuracy metrics.
- `test_feature_parity.py` — 4-stage parity harness (filterbank fixture round-trip, raw mel power, log-mel, z-scored final).
- `swift_feature_extractor/` — Swift CLI tool that imports BoomBoomBoomKit SPM package and dumps the shared `feature_pipeline_v1.npz` fixture.

Generated:
- `fixtures/feature_pipeline_v1.npz` — shared filterbank matrix + STFT window + DSP constants. Exported once from Swift; loaded by Python.
- `corpus_splits.json` — `{train: [...], val: [...], test: [...]}` track ID lists.
- `model_summary.txt` — `torchinfo.summary` output.
- `model_metadata.json` — BPM bin centers `[30.0, 31.0, ..., 285.0]` for Story 4-5 lookup.
- `model.pt` — final trained state_dict.
- `checkpoints/epoch_*.pt` — every-5-epoch checkpoints for `--resume`.
- `training_log.json` — per-epoch wall-clock, train/val acc_4pct, train/val loss, MPS-fallback-observed flag.
- `eval_report.json` — OA300 test set metrics + named-DnB results + sanity-HALT outcomes.
- `feature_parity_report.txt` — per-stage max abs/rel deviation.
- `mlmodelc_layout.txt` — `find` listing of compiled `.mlmodelc/` directory tree + structural-equivalence hashes.
- `parity_signals.f32` — deterministic test signals (1s 440Hz sine + 5s 120BPM click).
- `benchmark-oa300-pre.log`, `benchmark-giantsteps-pre.log` — pre-source baseline benchmark output.

## Spec deviations

- **Python 3.13** instead of spec-literal `>=3.11,<3.13` — coremltools 9.0 supports up to Python 3.13; 3.14 is NOT yet supported (no 3.14 classifier on PyPI). Approved by user 2026-05-09. See `_bmad-output/implementation-artifacts/4-4b-regression-snapshot.json` `spec_deviations` block for full rationale.

## Determinism notes

`torch.use_deterministic_algorithms(True, warn_only=True)` is set, but PyTorch MPS does NOT guarantee bit-reproducibility across macOS minor versions or repeated runs of the same seed (PyTorch issue #97236). The seed pin makes runs deterministic-at-the-Python-level; trained weights may differ slightly across hardware/driver versions. The held-out OA300 sanity HALT (`acc_4pct ≥ 5%` per DD #11) is the regression-protection contract.

`PYTORCH_ENABLE_MPS_FALLBACK=1` is set so unsupported MPS ops fall back to CPU rather than crashing. `mps_fallback_observed: true` in `training_log.json` metadata fires if any single epoch wall-clock is ≥ 5× the median epoch wall-clock (likely silent CPU fallback).

## Per-story conventions

- All scripts run via `uv run python <script>.py` — never `python3 ...` (project-context.md §"Development Workflow Rules").
- ZERO modifications to `Package.swift`, `Sources/BoomBoomBoomKit/`, `Sources/BoomBoomBoomKitML/*.swift`, `Tests/`, `Makefile`, `CLAUDE.md`, or `_bmad/`. Only added files are this directory + `_bmad-output/ml-models/tempo_classifier.mlmodel` + `Sources/BoomBoomBoomKitML/Resources/tempo_classifier.mlmodelc/` + `tools/coreml-convert/` + the regression / diff-scope artifacts.

## References

See `_bmad-output/implementation-artifacts/4-4b-tempo-classifier-training.md` (the story spec) for the full DD/AC list, HALT triggers, and review history.
