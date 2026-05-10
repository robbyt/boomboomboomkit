# Story 4.4b: Reference Tempo Classifier + Bring-Your-Own-Weights Adapter — Story 4-5 Prerequisite

Story ID: 4.4b
Story Key: 4-4b-tempo-classifier-training
Epic: 4 — ML-Augmented Detection
Status: review
**Depends on:** Story 4.1 (`done` — `BoomBoomBoomKitML` target + `compile-model` Makefile target), Story 4.4 (`done` — `EnsemblePolicy` surface + `MLEvaluation` shape)
**Blocks:** Story 4.5 (`ready-for-dev` blocked at HALT (a') — Task 1.5 model availability gate)

## Story

As a library author preparing to land Story 4-5's BNNS conformance,
I want (a) a small reference `giantsteps_v1.mlmodelc` artifact produced from a Schreiber & Müller-style shallow tempo CNN trained locally on this M5 Max 128GB MacBook against GiantSteps + OA300 corpora that ships as the library's out-of-the-box default, (b) a public consumer-facing conversion tool at `tools/coreml-convert/` (NEW location at repo root, ships to main — distinct from the dev-only training pipeline at `_bmad-output/ml-training/`) that lets library consumers convert ANY external PyTorch tempo model checkpoint to a `.mlmodelc` honoring our adapter contract, and (c) clear consumer-onboarding documentation showing how to bundle external model weights (under whatever license, including AGPL/proprietary — consumer's responsibility) into THEIR app and wire them up via the `MLTechnique` protocol or override API,
So that Story 4-5's HALT (a') gate clears with a real (non-random-weight) reference model, BoomBoomBoomKit becomes a pluggable ML host where consumers can ablate across architectures (S&M, Deep-Rhythm, custom) without library changes, and license compliance for upstream model weights is fully delegated to the consumer's app rather than entangled with the library's distribution.

**Architectural pivot 2026-05-09:** Story 4-4b's purpose changed from "train a model" to "ship a reference model + the adapter pattern + consumer tooling." The reference model is a quality demonstrator and out-of-the-box default, NOT the only supported model. Consumers swap weights freely; license compliance for upstream weights belongs to the consumer's app distribution, not to BoomBoomBoomKit.

## Key Design Decisions

The 13 design decisions below were authored at story-creation time (2026-05-09) against HEAD `757d57c` plus the staged Story 4-5 spec, then revised same-day after Project Lead pivoted to the bring-your-own-weights adapter pattern. The Project Lead reviews this block BEFORE the dev agent begins Task 1. **DDs #0, #5, #7, #11, #13 are the most consequential decisions** — they lock the adapter pattern (DD #0), feature-pipeline parity contract (DD #5), BPM bin schema (DD #7), reference-model sanity targets (DD #11, reframed from HALT-only to soft), and consumer-facing convert-tool contract (DD #13).

0. **Reference + bring-your-own-weights adapter pattern (foundational, added 2026-05-09 pivot).** BoomBoomBoomKit's ML augmentation is a pluggable surface: consumers can ship the bundled reference model (default, works out of the box) OR override with their own `.mlmodelc` produced from any PyTorch model. Three contracts make this concrete:
    - **Public protocol = `MLTechnique`** (already declared per CLAUDE.md as "Definition only, no conformances yet"). Story 4-5 ships the first conformance (`BNNSTempoTechnique` or similar) and the override API; this story produces the reference weights that the default conformance loads. Power users implement their own `MLTechnique` conformance (CoreML, BNNSGraph, MPSGraph, MLX, even pure-Swift inference) — feature pipeline, inference, and scoring are all consumer-controlled at that level.
    - **Default conformance = bundled reference model.** A small (~150-300k param) S&M-style classifier is trained by this story (Tasks 2-9), bundled into `BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/`, and loaded by Story 4-5's default `MLTechnique` conformance via `Bundle.module.url(forResource: "giantsteps_v1", withExtension: "mlmodelc")`. This is a reference + sanity demonstrator, NOT the canonical model.
    - **Convert-tooling for consumer override** = `tools/coreml-convert/` at repo root (NEW directory, ships to main alongside the Swift package — represents an explicit relaxation of project-context.md "What stays on develop" for THIS specific tool because it must be discoverable by consumers). Self-contained Python project with its own `pyproject.toml`+`uv.lock`. Consumers run `uv run python convert.py --checkpoint their_model.pth --arch <reference|custom> --output their_model.mlmodelc`. The script validates the tensor-name + shape contract, runs eager-vs-traced numerical equivalence, and produces a `.mlmodelc` consumers bundle into THEIR app's main bundle.
    - **License posture (clarified 2026-05-09):** the library never ships third-party weights. AGPL deeprhythm, MIT custom-trained, proprietary commercial — all are the consumer's responsibility once they choose to bundle them in their app. BoomBoomBoomKit's only license obligation is for the small reference model trained by this story (which we license under the project's own license, MIT-compatible, since corpora are GiantSteps + OA300 — both research-use; the reference model is for sanity demonstration not redistribution-as-product).
    - **Why this pattern:** sidesteps the upstream-weights license entanglement entirely (verified 2026-05-09 — bleugreen/deeprhythm is AGPL-3.0, blocking direct bundling but unblocked when consumer ships it themselves); enables architecture ablation across S&M / Deep-Rhythm / future without library code changes; matches the existing project pattern (`DSPTechnique` is a closed enum because DSP variants live in the library; `MLTechnique` is an open protocol because ML is consumer-pluggable).


1. **Framework: PyTorch + MPS backend, NOT Keras/TensorFlow.** Three reasons: (a) coremltools 8.x has a mature PyTorch ExecuTorch / `torch.export` conversion path that produces `.mlmodel` from a traced `nn.Module` directly — fewer hops than Keras→ONNX→CoreML; (b) PyTorch native MPS support on Apple Silicon (M-series) is the canonical 2025+ training stack on this hardware; (c) the reference `tempo-cnn` repo (Hendrik Schreiber, Keras 1.x / TF1) is unmaintained — porting the architecture cleanly to PyTorch is more maintainable than chasing TF1 compat. **Hardware target: M5 Max 128 GB unified memory** — generous for a small CNN; full corpus fits in RAM, MPS handles training.

2. **Training pipeline lives in `_bmad-output/ml-training/`, NEVER in `Sources/` or `Tests/`.** Per Story 4-5 line 662 ("Do NOT add training infrastructure to the repo"). The directory is a non-shipped tooling location (consistent with `_bmad-output/perf-baselines/`, `_bmad-output/ml-models/`, `_bmad-output/implementation-artifacts/`). Branch `develop` carries it; `main` excludes it via the existing release-process exclusion rules (project-context.md §"Development Workflow Rules" — "What goes to main"). The Python project layout is self-contained: `pyproject.toml` (uv-managed), `train.py`, `model.py`, `dataset.py`, `convert.py`, `eval.py`, `requirements.lock`. ZERO modifications to `Sources/` or `Tests/`.

3. **Corpus split discipline. OA300 is held out as a sanity test set; GiantSteps is the train+val source.** Two reasons: (a) OA300 is small (82 labeled tracks) — splitting it further yields meaningless validation; better used as a downstream verification matching Story 4-5's impact-report set; (b) GiantSteps ships official 10-fold CV splits (`splits/fold01.txt` … `fold10.txt`) — the dev uses fold01 as validation and folds 02-10 as training (≈90/10 train/val), preserving the dataset's documented split convention. **Leak prevention rule:** the 4 named DnB triplet tracks (Charly, Faraday_Bunker, Yin Yang, HEFT_Anagram 6) are in OA300 only — they CANNOT appear in the training set by construction (corpus disjointness). The dev MUST verify zero filename overlap between OA300 ground-truth (`Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json`, 82 entries) and GiantSteps ground-truth (`giantsteps-tempo-ground-truth.json`, 661 entries) at Task 2.

4. **Reproducibility: pinned seeds + locked deps + recorded env.** `train.py` accepts `--seed N` (default 42); seeds Python `random`, NumPy, PyTorch (CPU + MPS — `torch.manual_seed` covers MPS in PyTorch 2.x; there is NO separate `torch.mps.manual_seed` API in stable releases as of 2026-05-09), and Python hash randomization (`PYTHONHASHSEED`). The global determinism switch is `torch.use_deterministic_algorithms(True, warn_only=True)` — **NOT** `torch.backends.mps.deterministic = True`, which does not exist as a public API (verified by Apple-docs review 2026-05-09: `torch.backends.mps` exposes only `is_available()`, `is_built()`, `is_macos_or_newer()`; PyTorch issue #97236 documents incomplete MPS determinism). `warn_only=True` is required because some PyTorch ops have no deterministic MPS implementation and would otherwise raise. `uv lock` produces `uv.lock` committed alongside `pyproject.toml` so re-runs are deterministic at the dep level. Training artifacts (`model.pt`, `training_log.json`, `eval_report.json`) carry a metadata header recording macOS / Xcode / Python / PyTorch / coremltools versions plus git SHA at training time. **Training is not bit-reproducible across MPS driver versions** — Apple's MPS does not guarantee floating-point determinism per WWDC framing; the seed pin makes runs *deterministic-at-the-Python-level* but the resulting weights may differ slightly across macOS minor versions. The dev also exports `PYTORCH_ENABLE_MPS_FALLBACK=1` so unsupported ops fall back to CPU rather than crashing — the per-epoch wall-clock log will reveal if any op is silently falling back (epoch time spikes 5×+ vs the reference). The held-out floor (DD #11) protects against catastrophic regressions, not against weight-level drift.

5. **Feature pipeline matches `MLFeatureFrames` semantically via shared-fixture parity contract (NCHW, 128 mel, W=512, log compression scale=100, z-score across time axis per mel band).** This is the load-bearing contract with Story 4-5: the trained model's expected input distribution MUST equal what `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` + `BNNSTechnique.featurize(_:)` produce at runtime, otherwise inference is garbage regardless of training quality. **The naive 1e-5 element-wise tolerance is too tight** across the full pipeline (vvlogf vs np.log1p ULP differences, vDSP operation ordering, mel-filterbank Slaney/HTK conventions, librosa power=2.0 vs Accelerate magnitude defaults). **Two-part contract:**

    **Part A — Shared fixture (Winston's recommendation, 2026-05-09 review).** The mel filterbank matrix and STFT window are exported ONCE from Swift as a `.npz` fixture committed to `_bmad-output/ml-training/fixtures/feature_pipeline_v1.npz` containing: `mel_filterbank: (128, 1025) float32`, `stft_window: (2048,) float32`, `hop_size: int`, `sample_rate: int`, `f_min: 30.0`, `f_max: float`, plus a `sha256` self-hash for tamper-detection. Python loads this fixture at training time — Python and Swift now share the EXACT filterbank/window/hop, so parity drift can come only from STFT framing, magnitude vs power, and per-frame numerics, not from filterbank construction.

    **Part B — Staged element-wise tolerance (Codex's recommendation, 2026-05-09 review).**
    - **Stage 1 (filterbank matrix from fixture):** `abs ≤ 1e-6` — the matrix is exported once; this is a sanity check that the .npz round-trip is lossless.
    - **Stage 2 (raw mel power, post-STFT, pre-log):** `abs ≤ 1e-5 OR rel ≤ 1e-4` — STFT framing + window + magnitude/power conventions resolved.
    - **Stage 3 (log-mel, post-`log1p(100·x)`):** `abs ≤ 1e-4 OR rel ≤ 1e-3` — accommodates `vvlogf` vs `np.log1p` ULP differences.
    - **Stage 4 (z-scored final tensor, output to model):** `abs ≤ 1e-4 OR rel ≤ 1e-3`.
    - Each stage is verified independently by the parity harness (AC #3); failure at any stage surfaces with the stage name so the dev knows where to look.

    **Specifics (unchanged):**
    - **Sample rate:** training audio is resampled to 44 100 Hz mono float32 (matches `BPMAnalyzer` source rate; `librosa.load(path, sr=44100, mono=True, res_type="soxr_hq")` — `soxr_hq` is required because default `kaiser_best` differs from Accelerate's resampler enough to break Stage 4 tolerance). Files at native 48 000 / 96 000 Hz are resampled. Note `librosa.load` requires `ffmpeg` for m4a/aac decode — install via `brew install ffmpeg` before running training pipeline.
    - **Mel parameters:** 128 mel bands, `f_min=30 Hz`, `f_max=min(sr/2, 16000)`, FFT size 2048, hop size = pipeline-derived (~441 samples for 100 Hz onset rate at 44.1 kHz = matches `BPMAnalyzer.hopSize`). The dev verifies the exact `hopSize` constant from `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` at Task 3 and pins the Python pipeline to it AND records it in the shared fixture.
    - **Log compression:** `log(1 + 100·mel_energy)` — matches `BPMAnalyzer` lines 578-583 (`vDSP_vsmul ×100` then `vDSP_vsadd +1.0` then `vvlogf`). Python: `np.log1p(100.0 * mel_spec)`.
    - **Temporal resampling:** training samples are clipped/looped to W=512 frames per example (matches Story 4-5 DD #9 fixed-W resampling). For training, the dev randomly samples 512 contiguous frames from each track (data augmentation via temporal shift); for eval, takes the centered 512-frame window. Runtime uses `vDSP.linearInterpolate` to resample variable-length input to W=512 — semantically equivalent to "fixed window" at training time.
    - **Z-score normalization:** per mel band, across time axis, mean 0 / stddev 1. Matches `BNNSTechnique.featurize` step. Computed AFTER the log step.
    - **`featureSetVersion = "v1"`** — Story 4-5 DD #2 sets this; if any of the above changes (e.g., Story 4.7 lands and changes onset-envelope source), the trained model is invalidated and `featureSetVersion` bumps to `"v2"`. The dev embeds `feature_set_version: "v1"` in `eval_report.json` and the shared `.npz` fixture so the Story 4-5 dev can verify match at HALT (g) trace inspection.

6. **Model architecture: shallow multi-filter CNN per Schreiber & Müller (2018) §3, scaled DOWN to fit the smaller corpus.** S&M trained on ~10k tracks with 5 multi-filter conv blocks; we have ≈661 GiantSteps train tracks, so 3 conv blocks is the maximum-defensible depth before overfit risk dominates. Layers (PyTorch `nn.Module`):
    1. **Input:** `(N, 1, 128, 512)` — NCHW row-major, float32.
    2. **Conv block 1:** parallel branches with kernel sizes `(1, 32)`, `(1, 64)`, `(1, 96)` along the time axis (per S&M §3 multi-filter design — captures multiple tempo periodicities); 16 channels per branch; ReLU; concatenate along channel dim → 48 channels.
    3. **MaxPool (1, 5)** along time.
    4. **Conv block 2:** parallel `(1, 16)`, `(1, 32)`, `(1, 48)` kernels; 32 channels per branch; ReLU; concatenate → 96 channels.
    5. **MaxPool (1, 4)** along time.
    6. **Conv block 3:** `(1, 8)`, `(1, 16)`, `(1, 24)` kernels; 32 channels per branch; ReLU; concatenate → 96 channels.
    7. **Global average pool** (mel + time axes collapsed).
    8. **Dense layer:** 256 units, ReLU, dropout 0.3.
    9. **Output dense:** `BPM_BINS` units (DD #7), softmax → probability distribution over BPM bins.
    Total parameters: ~150-300 k (small for an Apple Silicon training run; M5 Max has tons of headroom). The dev finalizes exact channel counts at Task 4 based on initial val-set Acc1 — if val Acc1 < 30% after 30 epochs, the dev escalates to 4 conv blocks; if val Acc1 plateaus high too quickly with overfit signs (train Acc1 - val Acc1 > 20 percentage points), drops to 2 blocks.

7. **BPM bin schema: integer-BPM bins from 30 to 285 inclusive (256 classes).** Matches Schreiber & Müller's original output range — wide enough to cover anything in the corpora (GiantSteps spans ~50-180 BPM, OA300 spans ~70-180 BPM); narrow integer resolution (1 BPM/bin) keeps the output dense without over-discretizing. **Bin index ↔ BPM mapping:** `bin_i = i + 30` for `i ∈ [0, 255]`, so argmax bin `k` → `bpm = float(k + 30)`. The dev embeds the bin centers as a Python list in `model_metadata.json` AND as a comment in `BNNSTechnique.swift`'s `bpmBinCenter(forIndex:)` helper at Story 4-5 Task 5.2. **Output range conflict resolution:** Story 4-5 clamps the predicted BPM to `60.0…200.0` defensively in `evaluate(trace:)` (DD #2 / AC #2). Bins 0-29 (30-59 BPM) and 171-255 (201-285 BPM) are unreachable in practice but kept in the schema for future flexibility. Loss function: cross-entropy with label-smoothing 0.1 (rounds nearest-integer BPM to the bin index; tracks with non-integer ground-truth BPM use the floor — GiantSteps has float ground-truth so this matters; OA300 has integer ground-truth).

8. **Training framework: torch 2.x + torchaudio + librosa for off-line feature pre-compute; coremltools 8.x for conversion.** Python deps via `uv` (project-context.md §"Development Workflow Rules" — "Python scripts use `uv run` not `python3`"):
    ```toml
    # _bmad-output/ml-training/pyproject.toml
    [project]
    name = "boomboomboomkit-tempo-training"
    requires-python = ">=3.11,<3.13"
    dependencies = [
      "torch>=2.4",
      "torchaudio>=2.4",
      "librosa>=0.10",
      "numpy>=1.26",
      "coremltools>=8.0",
      "tqdm>=4.66",
    ]
    ```
    The dev runs `uv sync` once; `uv run python train.py` invokes the script. **`coremltools` requires Python 3.11/3.12** (not 3.13 as of this story's authoring 2026-05-09 — the dev verifies the current Python compat range at Task 1 and adjusts `requires-python` accordingly). MPS device selection: `torch.device("mps" if torch.backends.mps.is_available() else "cpu")`. M5 Max → MPS available → training runs on GPU.

9. **Conversion path: SEPARATE export script that loads the checkpoint on CPU, traces on CPU, converts.** Per Apple's universal pattern (verified 2026-05-09 across `apple/ml-fastvit`, `apple/ml-vision-transformers-ane`, `apple/corenet`, coremltools 8.x tutorials — every reference repo separates training device from export device, ALWAYS tracing on CPU after `model.eval()`). **Train and export are different scripts in different processes:**
    - `train.py` — runs on MPS, saves `model.pt` (state_dict only, not full pickle) and `train_metrics.json`, then exits.
    - `export.py` (renamed from `convert.py`) — `torch.load(checkpoint, map_location="cpu")`, `model.eval()`, traces on CPU with a CPU example input.
    - **Numerical-equivalence guard (corenet pattern, AC #9):** before `ct.convert`, assert `torch.allclose(model_eager(x), traced_model(x), atol=1e-3)` — this catches silent trace divergence (e.g., a layer with training-time-only branches that didn't fold cleanly). If the assertion fails, the trace is broken and the export script HALTs before producing a poisoned `.mlmodel`. corenet/`pytorch_to_coreml.py` uses `decimal=3` for the same purpose.
    - **Conversion call:** `coremltools.convert(traced_model, inputs=[ct.TensorType(name="input", shape=(1, 1, 128, 512), dtype=np.float32)], outputs=[ct.TensorType(name="output", dtype=np.float32)], minimum_deployment_target=ct.target.macOS15, compute_units=ct.ComputeUnit.CPU_ONLY, convert_to="mlprogram", compute_precision=ct.precision.FLOAT32)`.
    - **`ct.target.macOS15` (final, post-chunk-2 amendment):** The Schreiber-Müller-style 2-D CNN uses no macOS 15-only MIL features, so a `macOS14` floor would technically widen runtime compatibility by one full release. The original 2026-05-09 review chose `macOS14` for that reason. **Chunk-2 review DN1 (also 2026-05-09) reversed that** — the consumer convert tool was already producing `macOS15` artifacts via the bundled-model pipeline, AND BoomBoomBoomKit's own `Package.swift` declares `.macOS(.v15)`, so widening the .mlmodelc floor below the library's own minimum was internally inconsistent. Both `tools/coreml-convert/convert.py` and the dev-side `_bmad-output/ml-training/export.py` now default to `ct.target.macOS15`. If a future story needs to ship the bundled artifact at a wider deployment-target floor, bump back then.
    - **Why `CPU_ONLY` and NOT `CPU_AND_NE` (revised 2026-05-09):** Story 4-5 consumes the `.mlmodelc` via BNNSGraph, NOT via Core ML runtime. BNNSGraph reads the MIL program + weight tensors directly and dispatches on CPU (per WWDC 2024-10211, "Support real-time ML inference on the CPU"). The `compute_units` flag is a Core ML runtime hint that BNNSGraph ignores. Setting `CPU_ONLY` is honest about the consumer; setting `CPU_AND_NE` would mislead anyone reading the spec into thinking ANE is in scope. If Story 4-6 (CoreML conformance) lands later and wants ANE, it can re-export the same checkpoint with `CPU_AND_NE`.
    - **Tensor naming contract (Story 4-5 DD #16):** input tensor named `"input"`, output tensor named `"output"`. Verified post-convert by:
        - `python -c "import coremltools as ct; m = ct.models.MLModel('...'); spec = m.get_spec(); print([i.name for i in spec.description.input], [o.name for o in spec.description.output])"` — must print `['input']` and `['output']` literal.
        - **Inputs always honored on TorchScript trace path** (verified Apple-docs review 2026-05-09). **Outputs only honored when explicitly named** — else coremltools auto-generates `var_NNN`. Both must be explicit; HALT (b) trips if either is renamed.
        - Defensive fallback: if names didn't propagate, apply `ct.utils.rename_feature(spec, old_name, "input"/"output")` and re-save.

10. **Data augmentation: time-shift (random 512-frame window per example), tempo-stretch (±4% via `librosa.effects.time_stretch`), gain (±6 dB), pink-noise (SNR 30-50 dB).** Augmentation is applied on-the-fly in the PyTorch `Dataset.__getitem__` on the **PCM signal BEFORE feature extraction** (NOT on cached log-mel tensors — applying time-stretch to a log-mel tensor and then re-extracting is mathematically incoherent). Tempo-stretch is the most consequential: it expands the training set's effective tempo coverage, and the corresponding ground-truth label MUST be re-bound. **Label direction (corrected 2026-05-09 review):** `librosa.effects.time_stretch(y, rate=r)` with `r > 1` makes the audio faster (returns fewer samples — see librosa docs https://librosa.org/doc/0.10.2/generated/librosa.effects.time_stretch.html). A 120 BPM track stretched at `rate=1.04` plays back faster and now sounds like 120 × 1.04 = 124.8 BPM. The new label is therefore `new_bpm = original_bpm * rate`, then re-binned to the nearest integer BPM bin. **(The previous draft of this DD said "BPM divided by stretch factor" — that was incorrect; the corrected derivation is `bpm * rate`.)** The dev implements this as: stretch factor sampled uniformly in `[0.96, 1.04]`, `new_bpm = bpm * rate`, then `label = round(new_bpm) - 30` clamped to `[0, 255]`. **Augmentation toggle:** `--augment` flag default-on for training; eval / test use `--augment=false` (no stretch, centered window, no gain/noise).

11. **Reference-model quality posture — sanity HALTs only, accuracy targets soft (revised 2026-05-09 pivot to bring-your-own-weights).** With DD #0's adapter pattern in place, the reference model demonstrates that the adapter works end-to-end and provides a sensible default. Consumers needing higher quality bring their own weights via `tools/coreml-convert/` + override API. The empirical bar therefore drops from "real-not-placeholder HALT" to "non-broken sanity HALT," with literature-comparable accuracy numbers becoming reported soft targets.

    **Three named accuracy metrics (define once, applied separately per AC):**
    - `acc_4pct` := `|pred - truth| / truth ≤ 0.04` — the literature-comparable Acc1 metric (Schreiber & Müller 2018 used this).
    - `acc_2pct` := `|pred - truth| / truth ≤ 0.02` — tighter, used for ablation-comparable reporting (matches `make benchmark` Acc1 in this repo).
    - `strict_0_5` := `|pred - truth| ≤ 0.5 BPM` (absolute) — the strictest gate; equivalent to "predicts the exact integer BPM bin" for integer ground-truth.

    **Sanity HALTs (must hold — these gate the story):**
    - **Non-broken-output HALT:** the trained model produces non-NaN, non-Inf, finite-sum-to-1 softmax outputs on 100% of OA300 test tracks. (Catches: NaN gradients during training, MPS numerical overflow, broken tracing.) **Below 100% → HALT (c).**
    - **Beats-random HALT:** held-out OA300 (82 tracks) `acc_4pct ≥ 5%` (≥ 5 of 82 tracks). Random softmax over 256 bins → ~0.4% baseline; 5% is 12.5× random and demonstrates the model has learned SOMETHING. (Catches: model that didn't actually train, label corruption, feature pipeline disconnect.) **Below 5% → HALT (c).**
    - **Convert-roundtrip HALT:** the produced `.mlmodel` loads via `coremltools.MLModel(path)` AND produces output within `1e-3` of the PyTorch eager output on a deterministic test input. (Catches: silent conversion drift, wrong tensor names.) **Roundtrip mismatch → HALT (b).**

    **Advisory HALT (named-DnB) — does NOT block 4-4b production, but blocks Story 4-5 handoff signoff:**
    - Named-DnB `strict_0_5 ≥ 2/4`: the same threshold Story 4-5's HALT (b) tests at runtime. If the reference model fails this here at training time, Story 4-5 will trip its own HALT (b) on the same model (codex 2026-05-09 review caught this — removing the gate entirely silently defers the failure). Below 2/4 → ADVISORY HALT (d): Project Lead must explicitly acknowledge before Task 10.3 marks Story 4-5 unblocked. Acknowledgement options: (i) accept reference model with expected 4-5 HALT (b), (ii) re-train with DnB-augmented data, (iii) require consumer-override path from start (defer 4-5 default model wiring).

    **Promotion-warning threshold (REPORTED — Project Lead signoff required if missed; story not gated):**
    - OA300 test `acc_4pct ≥ 25%` — "decent reference default" warning per codex 2026-05-09 review (5% is too weak to claim "sensible default"). If miss: Completion Notes must include explicit Project Lead acknowledgement text before story moves to `review`.

    **Soft quality targets (REPORTED, purely informational — no signoff):**
    - GiantSteps val `acc_4pct ≥ 55%` — literature ballpark for a 3-block reduced S&M variant.
    - OA300 test `acc_4pct ≥ 40%` — cross-corpus generalization target.
    - Named-DnB `strict_0_5 ≥ 3/4` — beyond the advisory minimum.
    - All recorded in `eval_report.json` with a `target_met: bool` flag per metric. None blocks the story.

    **Why this reframing:** under DD #0's bring-your-own-weights pattern, "the bundled reference model is mediocre" is solved by the override API, not by re-training. The reference model exists to (a) prove the adapter pipeline is functional, (b) give consumers a working default, (c) provide a known-quality baseline for Story 4-5's impact-report ablation. Consumers wanting better convert their own model. Aggressive HALT floors on the reference model would force re-training cycles for a quality bar that the override path makes optional. **Recorded in Epic 4 retrospective as a deliberate quality-vs-shipping-velocity tradeoff.**

    **Architectural caveat (Mary, 2026-05-09 review, retained):** the S&M architecture was originally fitted to GiantSteps-class material. GiantSteps train/val therefore has an architectural advantage OA300 does not share. This is not data leakage in the formal sense (no track overlap) but is a known confounder of "cross-corpus generalization" framing. Recorded for retrospective consumption. Less load-bearing now that the reference model is just a default consumers can replace.

12. **HALT triggers (named, revised 2026-05-09 pivot).**
    - **HALT (a) — Corpora not present at expected paths OR smoke run > 2 min.** `OA300_CORPUS_PATH` and `GIANTSTEPS_CORPUS_PATH` env vars must resolve to readable directories with the expected structure. Additionally, the AC #8 / Task 5.5 smoke run (`--epochs 1 --subset 32`) must complete < 2 minutes; if it doesn't, MPS is likely silently falling back to CPU on a critical op and the full run will burn hours. Surface to Project Lead in either case.
    - **HALT (b) — Numerical-equivalence guard fails OR `coremltools` conversion fails OR tensor names don't propagate OR convert-roundtrip mismatch.** Failure modes: (1) `torch.allclose(eager_out, traced_out, atol=1e-3)` fails (broken trace), (2) PyTorch op not yet supported by the converter, (3) input or output tensor name didn't propagate (apply `ct.utils.rename_feature` fallback), (4) per DD #11 sanity HALT: `coremltools.MLModel(path).predict(...)` output diverges from PyTorch eager by > 1e-3 on a deterministic test input (silent conversion drift). Dev surfaces with the specific failure mode + a workaround proposal.
    - **HALT (c) — Reference-model sanity HALT failure (revised — ≥5% acc_4pct + non-NaN outputs, NOT 30%).** Per DD #11 reframed thresholds: held-out OA300 `acc_4pct < 5%` (model didn't learn anything; 12.5× random baseline) OR any test-set track produces NaN/Inf softmax (training numerical instability). Possible causes: NaN gradients, MPS numerical issues, label corruption, feature pipeline disconnect. Dev surfaces with `eval_report.json` evidence; Project Lead decides whether to re-train or accept the broken reference (consumers can override via DD #0).
    - **HALT (d) — REINSTATED AS ADVISORY (codex 2026-05-09 review): Named-DnB `strict_0_5 < 2/4`.** Per DD #11 advisory framing: this does NOT block 4-4b artifact production, but Project Lead MUST explicitly acknowledge before Task 10.3 marks Story 4-5 unblocked. Without acknowledgement, the dev does not move the story to `review`. Story 4-5's HALT (b) tests the same gate at runtime; ignoring this advisory silently hands 4-5 a known-failing model. Acknowledgement options: (i) accept with expected 4-5 HALT (b), (ii) re-train with DnB augmentation, (iii) defer 4-5 default-model wiring entirely (consumer-override-only path).
    - **HALT (e) — `make compile-model` fails on the produced `.mlmodel` OR structural-equivalence check fails on re-run.** `xcrun coremlc` (Story 4.1 Makefile target) must produce a valid `.mlmodelc` directory tree, and re-running must produce structurally equivalent output (op-graph plutil diff empty + per-weight sha256 identical, NOT necessarily byte-identical container per AC #10). If either fails, HALT and surface.
    - **HALT (f) — Source / test directories modified beyond expected scope.** Anti-scope guard: if `git diff --stat Sources/ Tests/` shows non-zero output other than `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` (the produced reference artifact), HALT. Story 4-5 will land the public `MLTechnique` conformance + override API in `Sources/BoomBoomBoomKitML/*.swift` — those edits are NOT this story's scope. (Note: pre-pivot wording said "ANY non-zero output" — relaxed to allow the bundled reference `.mlmodelc` per DD #0.)
    - **HALT (g) — `tools/coreml-convert/` convert script fails on its own reference checkpoint (NEW per DD #13).** The convert script must successfully round-trip the reference `model.pt` checkpoint to a valid `.mlmodelc` AND to an arbitrary other PyTorch checkpoint matching the documented reference architecture (smoke test). If the script fails on its own reference output, no consumer can use it. Dev surfaces with the failure mode + workaround.

13. **Convert-tooling location and contract (NEW per DD #0 pivot, 2026-05-09).** The consumer-facing convert script lives at `tools/coreml-convert/` at the repo root — NEW directory, ships to `main` alongside the Swift package.

    **Release-process exception (codex 2026-05-09 review — explicit clause).** Project-context.md's "What stays on develop" rule is updated for this story to read:
    > **"What ships to main (post-Story-4-4b):**
    > - `Package.swift`, `Sources/`, `Tests/`, `.swiftlint.yml`, `LICENSE`, `README.md`, `CLAUDE.md`, `Makefile` — unchanged from prior policy.
    > - **NEW:** `tools/coreml-convert/` — consumer-facing CoreML conversion tool, Python (uv-managed), self-contained.
    >
    > **What stays on develop (NOT shipped to main):**
    > - `_bmad-output/` (all subdirectories including `ml-training/`, `ml-models/`, `implementation-artifacts/`, `perf-baselines/`).
    > - `_bmad/` (BMAD tooling).
    > - All other Python tooling not under `tools/coreml-convert/`."
    The squash-merge to main MUST include `tools/coreml-convert/` and MUST exclude `_bmad-output/ml-training/` (the dev-only training pipeline). Recorded in Change Log for Epic 4 retrospective consumption + propagated to project-context.md at story close-out. Layout:
    ```
    tools/coreml-convert/
      pyproject.toml         # uv-managed, isolated from _bmad-output/ml-training/
      uv.lock
      convert.py             # main entrypoint
      reference_arch.py      # the S&M-style reference architecture definition
      validate.py            # post-convert tensor-name + roundtrip-equivalence checks
      README.md              # consumer onboarding (4 worked examples: reference S&M, custom arch, AGPL deeprhythm port, MLX-trained)
      tests/                 # unit tests on reference checkpoint
    ```
    Public CLI surface (consumers run via `uv run python convert.py ...`):
    - `--checkpoint <path.pt>` (required) — PyTorch state_dict.
    - `--arch <reference|custom>` (default reference) — reference uses `reference_arch.py`'s S&M-style class; custom requires `--module path/to/model.py:ClassName`.
    - `--input-shape "1,1,128,512"` (default — matches reference). Custom-arch consumers override.
    - `--output <path.mlmodelc>` (required) — destination for the compiled `.mlmodelc` directory tree.
    - `--validate` (default true) — runs the AC #9 numerical-equivalence guard + tensor-name verification. `--no-validate` is allowed for debugging but: (a) prints a stderr warning "WARNING: --no-validate skips numerical-equivalence and tensor-name guards; the produced .mlmodelc may be silently broken. Do NOT ship a model produced with --no-validate to consumers without re-running with validation.", (b) sets `convert_report.json.validation.skipped = true`, (c) the consumer-onboarding README explicitly recommends against shipping `--no-validate` outputs.
    - `--target macOS14|macOS15|iOS17|iOS18` (default `macOS15` — matches BoomBoomBoomKit's `.macOS(.v15)` package target and the bundled artifact's `metadata.json` availability; superseded the original DD #9 macOS14 default in chunk-2 review DN1, see Change Log). Compute units always `CPU_ONLY` per DD #9 / Story 4-5 BNNSGraph contract.
    Output: `<path.mlmodelc>` directory tree + `<path>.convert_report.json` with metadata (PyTorch param count, conversion wall-clock, validation results, coremltools version).
    **Explicit non-goals:** the tool does NOT train models, does NOT fine-tune, does NOT compress (palettization/quantization). Consumers wanting those handle them upstream of the convert step.

## Background

Story 4-5 (BNNS MLTechnique conformance) is `ready-for-dev` but blocked at its Task 1.5 model-availability gate. Story 4-5's spec lines 114, 662, and 1090 (epics.md) explicitly carve training as out-of-scope for Story 4-5 — the spec assumes the dev can acquire a `.mlmodelc` externally (e.g., via tempo-cnn) but does not actually produce one. Story 4-5 DD #12 / HALT (a') (post-2026-05-08 roundtable hardening) closed the "ship plumbing only with random weights" escape hatch — Story 4-5 promotion now REQUIRES a real, non-random-weight model.

Story 4-4b fills that gap. It produces a real trained model end-to-end on the M5 Max 128 GB MacBook, locally, against the corpora the project already uses for benchmark gating (OA300 + GiantSteps). The training pipeline lives outside `Sources/` and `Tests/` per Story 4-5's "do NOT add training infrastructure to the repo" rule, so the released library on `main` carries only the compiled `.mlmodelc` artifact, never the training scripts.

The story is **explicitly out-of-scope** of Epic 4's planning posture — Epic 4 line 1090 says "ML model training is out of scope for Phase 3." The Project Lead (user) has authorized this deviation as of 2026-05-09 because the alternative (acquiring an external model) does not materialize without first cloning + converting tempo-cnn (which is Keras 1.x and unmaintained), and a from-scratch local training pipeline has the additional benefit of producing a model whose feature pipeline EXACTLY matches `MLFeatureFrames` (whereas a tempo-cnn-converted model would require feature-pipeline adapters that introduce semantic drift). The deviation is recorded in this story's Change Log + Epic 4's retrospective at close-out.

## Acceptance Criteria

1. **Training pipeline lives entirely in `_bmad-output/ml-training/`; ZERO modifications to `Sources/` or `Tests/`.**

   **Given** the Story 4-4b dev run is complete
   **When** the dev runs `git diff --stat <Task-1-pre-source-SHA>..HEAD -- Sources/ Tests/`
   **Then** stdout is empty (zero bytes, zero lines)
   **And** `git diff --stat <Task-1-pre-source-SHA>..HEAD -- _bmad-output/ml-training/` shows the new pipeline files (Python scripts, `pyproject.toml`, `uv.lock`, `eval_report.json`, `training_log.json`)
   **And** `git diff --stat <Task-1-pre-source-SHA>..HEAD -- _bmad-output/ml-models/` shows the produced `giantsteps_v1.mlmodel` (committed for reproducibility — `.mlmodel` is the compilation source per Story 4.1 DD #5)
   **And** `git diff --stat <Task-1-pre-source-SHA>..HEAD -- Sources/BoomBoomBoomKitML/Resources/` shows the produced `giantsteps_v1.mlmodelc/` directory tree
   **And** `Package.swift`, `Makefile`, and all existing source/test files are UNCHANGED

2. **Python project structure uses `uv` per project conventions.**

   **Given** `_bmad-output/ml-training/`
   **When** the dev sets up the Python environment
   **Then** the directory contains: `pyproject.toml`, `uv.lock`, `train.py`, `model.py`, `dataset.py`, `convert.py`, `eval.py`, `README.md` (one-page training-pipeline documentation)
   **And** `pyproject.toml` declares deps per DD #8: `torch>=2.4`, `torchaudio>=2.4`, `librosa>=0.10`, `numpy>=1.26`, `coremltools>=8.0`, `tqdm>=4.66` (versions verified at Task 1 against current PyPI; adjust if stale)
   **And** `uv.lock` is committed (deterministic dep resolution)
   **And** all scripts run via `uv run python <script>.py` (project-context.md "use uv run not python3")
   **And** the `README.md` documents: setup commands, env vars (`OA300_CORPUS_PATH`, `GIANTSTEPS_CORPUS_PATH`), training command, eval command, conversion command, expected wall-clock per stage, and the "do not commit training pipeline to main" rule (the directory stays on develop)

3. **Feature pipeline matches `MLFeatureFrames` semantically via shared-fixture + staged parity (DD #5).**

   **Given** the Python feature extractor in `dataset.py` AND the shared filterbank fixture at `_bmad-output/ml-training/fixtures/feature_pipeline_v1.npz`
   **When** it processes a track
   **Then** the output tensor has shape `(1, 128, 512)` (channel-first per training-time conv expectations; collapses to NCHW `(1, 1, 128, 512)` at inference)
   **And** the Python extractor LOADS the mel filterbank matrix and STFT window from `feature_pipeline_v1.npz` (NOT reconstructed from librosa) — the fixture is the contract, not the reconstruction
   **And** mel parameters recorded in the fixture match `BPMAnalyzer`: 128 mel bands, `f_min=30 Hz`, `f_max=min(sr/2, 16000)`, FFT size 2048, hop size matching `BPMAnalyzer.hopSize` (verified at Task 3 by reading the constant from `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`)
   **And** log compression matches `BPMAnalyzer` lines 578-583: `np.log1p(100.0 * mel_spec)`
   **And** z-score normalization is per-mel-band, across the time axis (mean 0, stddev 1)
   **And** a parity harness (`test_feature_parity.py` in `_bmad-output/ml-training/`) loads a deterministic fixture audio (1 second of 440 Hz sine wave + 5-second 120 BPM click track from `TestSignalGenerators.generateClickTrack`, dumped as `parity_signals.f32`), runs both Python and Swift extraction, and asserts the four-stage tolerance contract:
     - **Stage 1 — filterbank matrix from .npz round-trip:** `abs ≤ 1e-6` element-wise.
     - **Stage 2 — raw mel power (post-STFT, pre-log):** `abs ≤ 1e-5` OR `rel ≤ 1e-4` element-wise.
     - **Stage 3 — log-mel (post-`np.log1p(100·x)` / `vvlogf`):** `abs ≤ 1e-4` OR `rel ≤ 1e-3` element-wise.
     - **Stage 4 — z-scored final tensor:** `abs ≤ 1e-4` OR `rel ≤ 1e-3` element-wise.
   **And** the Swift reference extraction is a small CLI tool at `_bmad-output/ml-training/swift_feature_extractor/` (NOT committed under `Sources/`) compiled via `swiftc` directly; emits each stage's output as JSON for the Python harness to compare
   **And** the parity harness output (per-stage pass/fail + max abs/rel deviation) is captured in `_bmad-output/ml-training/feature_parity_report.txt`
   **And** if any stage fails, the harness names the stage in the failure message so the dev knows where to debug

4. **Corpus split discipline per DD #3.**

   **Given** the corpora at `OA300_CORPUS_PATH` and `GIANTSTEPS_CORPUS_PATH`
   **When** `dataset.py` builds the train / val / test splits
   **Then** OA300 (82 tracks) is held out entirely as the test set
   **And** GiantSteps (≈661 tracks) is split: validation = `splits/fold01.txt` track IDs; training = `splits/fold02.txt` … `fold10.txt` track IDs (≈90/10 train/val)
   **And** the dev verifies zero filename overlap between OA300 and GiantSteps ground-truth (run `python -c "import json; oa = {t['filename'] for t in json.load(open('<oa300>')) }; gs = {t['filename'] for t in json.load(open('<gs>'))}; print(oa & gs)"` — must print `set()`)
   **And** the 4 named DnB triplet tracks (`Charly`, `Faraday_Bunker`, `Yin Yang`, `HEFT_Anagram 6`) are confirmed in the OA300 (test) set, NOT in GiantSteps train/val
   **And** the split assignments are recorded in `_bmad-output/ml-training/corpus_splits.json` with schema `{"train": [...], "val": [...], "test": [...]}` for reproducibility

5. **Model architecture matches DD #6 (S&M shallow CNN, 3 conv blocks, ≈150-300k params).**

   **Given** `model.py` defines `class TempoCNN(nn.Module)`
   **When** the dev instantiates and inspects it
   **Then** the module follows the DD #6 layer specification (3 multi-filter conv blocks + global avg pool + dense + dense softmax over 256 BPM bins)
   **And** `print(sum(p.numel() for p in model.parameters()))` reports total parameters in `[150_000, 350_000]` (allows ±15% from the 150-300k target for branch-channel tuning)
   **And** the dev records the exact layer summary in `_bmad-output/ml-training/model_summary.txt` via `torchinfo.summary` or equivalent
   **And** if final val Acc1 < 30% after 30 epochs, the dev escalates to 4 conv blocks per DD #6 (documented in `training_log.json`)

6. **BPM bin schema per DD #7: 256 integer bins from 30 to 285.**

   **Given** the model's softmax output
   **When** the argmax is computed
   **Then** `argmax → BPM` is `bpm = float(argmax + 30)` for `argmax ∈ [0, 255]`
   **And** ground-truth labels are computed: `label = int(round(track.bpm)) - 30`, clamped to `[0, 255]` (label-out-of-range tracks fail loudly at training time; GiantSteps label range is ~50-180 → bins 20-150 reachable, well within range)
   **And** the bin centers are recorded in `_bmad-output/ml-training/model_metadata.json` as a list `[30.0, 31.0, ..., 285.0]` (256 entries) so Story 4-5's `bpmBinCenter(forIndex:)` helper can reference it
   **And** the cross-entropy loss uses label-smoothing 0.1 (dampens overconfidence on integer-rounded labels)

7. **Reproducibility per DD #4.**

   **Given** `train.py` is invoked with `--seed 42` (default)
   **When** training runs
   **Then** the following seed/determinism block runs BEFORE any data shuffling or model init:
   ```python
   import os, random, numpy as np, torch
   SEED = 42
   os.environ["PYTHONHASHSEED"] = str(SEED)
   os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"   # silent fallback for unsupported MPS ops
   random.seed(SEED)
   np.random.seed(SEED)
   torch.manual_seed(SEED)        # covers MPS in PyTorch 2.x; no separate torch.mps.manual_seed in stable
   torch.use_deterministic_algorithms(True, warn_only=True)
   ```
   **And** the spec does NOT reference `torch.backends.mps.deterministic` (the previous draft did — that attribute does not exist in stable PyTorch as of 2026-05-09; verified by Apple-docs review)
   **And** training-time MPS non-determinism is documented in `training_log.json` as a known limitation: "PyTorch MPS does not guarantee bit-reproducibility across macOS minor versions or between repeated runs of the same seed (PyTorch issue #97236 documents incomplete MPS determinism). The seed pin makes runs deterministic-at-the-Python-level but resulting weights may differ slightly across hardware/driver versions. The held-out test floor (DD #11 generalization HALT floor) is the regression-protection contract."
   **And** `eval_report.json` and `training_log.json` carry a metadata header recording: macOS version, Xcode version, Python version, PyTorch version, coremltools version, training git SHA, training start/end UTC timestamps, plus a `mps_fallback_observed: bool` flag set if any per-epoch wall-clock spike suggests CPU fallback (defined as: any single epoch ≥ 5× the median epoch wall-clock)

8. **Training time budget: ≤ 6 hours wall-clock on M5 Max (HALT ceiling, not target).**

   **Given** `uv run python train.py --seed 42 --epochs 60`
   **When** training runs end-to-end on M5 Max 128 GB
   **Then** **smoke run FIRST: `uv run python train.py --seed 42 --epochs 1 --subset 32`** must complete in < 2 minutes (32-track subset, 1 epoch). If smoke run > 2 minutes, MPS is likely falling back to CPU on a critical op — surface to Project Lead BEFORE the full run.
   **And** total wall-clock for the full 60-epoch run from script start to `model.pt` write is ≤ 6 hours (stretch goal: ≤ 2 hours — Codex's 2026-05-09 review notes 60 epochs over ~595 examples on M5 Max with pre-extracted features should be tens of minutes, not hours; 6 hours is the HALT ceiling for "something is wrong," not the expected runtime)
   **And** `training_log.json` records per-epoch wall-clock + per-epoch train/val `acc_4pct` + per-epoch train/val loss
   **And** if any single epoch wall-clock is ≥ 5× the median epoch wall-clock, the dev sets `mps_fallback_observed: true` in `training_log.json` metadata header (per AC #7) and surfaces to the Project Lead BEFORE the next full run
   **And** if training exceeds 6 hours, the dev surfaces to the Project Lead with the bottleneck identified (data loading, MPS op fallback to CPU, batch size too small, etc.) BEFORE killing the run — partial training is recoverable via `--resume <checkpoint>` (the dev implements basic checkpointing: save `model.pt` every 5 epochs)
   **And** the dev runs the training in `tmux` or similar so a dropped SSH/terminal does not kill it

9. **Export path: separate CPU-only export script with numerical-equivalence guard, produces `giantsteps_v1.mlmodel` with correct tensor names.**

   **Given** a trained `model.pt` checkpoint (state_dict serialized by `train.py`)
   **When** `uv run python export.py --checkpoint model.pt --output _bmad-output/ml-models/giantsteps_v1.mlmodel` runs
   **Then** the script (in this exact order):
      1. **Loads the checkpoint on CPU:** `state = torch.load(checkpoint, map_location="cpu")`. The model is constructed on CPU; no MPS device is ever touched in `export.py` (matches Apple's universal pattern across `apple/ml-fastvit`, `apple/corenet`, `apple/ml-vision-transformers-ane`).
      2. Sets the model to eval mode: `model.eval()`.
      3. Constructs a deterministic CPU example input: `example = torch.randn(1, 1, 128, 512, generator=torch.Generator().manual_seed(0))`.
      4. **Numerical-equivalence assertion (corenet pattern):** captures eager-mode output `eager_out = model(example)`, traces via `traced = torch.jit.trace(model, example)`, captures traced output `traced_out = traced(example)`, and `assert torch.allclose(eager_out, traced_out, atol=1e-3), "trace divergence"`. **HALT (b)** if assertion fails — a poisoned trace must not produce a `.mlmodel`.
      5. Calls `coremltools.convert(traced, inputs=[ct.TensorType(name="input", shape=(1, 1, 128, 512), dtype=np.float32)], outputs=[ct.TensorType(name="output", dtype=np.float32)], minimum_deployment_target=ct.target.macOS15, compute_units=ct.ComputeUnit.CPU_ONLY, convert_to="mlprogram", compute_precision=ct.precision.FLOAT32)`. **`macOS15`** matches BoomBoomBoomKit's `Package.swift` `.macOS(.v15)` minimum (chunk-2 review DN1 reversed the original macOS14 default); **`CPU_ONLY`** (vs `CPU_AND_NE`) because Story 4-5's BNNSGraph consumer ignores the compute-units flag and reads MIL directly — `CPU_ONLY` is honest about the consumer; **`FLOAT32`** explicitly because coremltools' ML Program default has been FP16 since 5.0b3 (Apple docs), and FP16 drift exceeds the AC #9 1e-3 roundtrip tolerance.
      6. Writes `_bmad-output/ml-models/giantsteps_v1.mlmodel`. **Note (axiom-ai review 2026-05-09):** `convert_to="mlprogram"` in coremltools 8.x canonically saves to a `.mlpackage` directory bundle. `mlmodel.save("path.mlmodel")` may either (a) write a single-file `.mlmodel` for backward compat, or (b) auto-correct the extension and write a `.mlpackage` directory at `path.mlpackage` (the coremltools behavior is version-dependent). The dev verifies at Task 7 which actually happens; if it writes `.mlpackage`, the dev either renames the output back to `giantsteps_v1.mlmodel` (the Story 4.1-locked filename consumed by `make compile-model`) or updates `ML_MODEL_INPUT` in `make compile-model` invocation. `xcrun coremlc compile` accepts either source format → produces the same `.mlmodelc`. The downstream contract (`.mlmodelc` for BNNSGraph) is unaffected.
      7. **Verifies tensor names post-convert:** `m = ct.models.MLModel(path); spec = m.get_spec(); assert [i.name for i in spec.description.input] == ["input"]; assert [o.name for o in spec.description.output] == ["output"]`. **HALT (b)** if names don't propagate. Defensive fallback: apply `ct.utils.rename_feature(spec, old_name, "input"/"output")` and re-save.
   **And** the script prints: PyTorch param count, eager-vs-traced max-abs-difference (must be < 1e-3 per the assertion), CoreML model spec input/output descriptions, model file size in MB
   **And** the produced `.mlmodel` is committed (it is the build-input the Makefile `compile-model` target consumes)

10. **`make compile-model` produces `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/`.**

    **Given** `_bmad-output/ml-models/giantsteps_v1.mlmodel` exists
    **When** the dev runs `make compile-model`
    **Then** the Story 4.1 Makefile target succeeds (`xcrun coremlc compile` produces the `.mlmodelc` directory)
    **And** `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` exists as a directory tree (NOT a flattened file — `.copy("Resources")` per Story 4.1 DD #2 preserves the tree)
    **And** the directory contains the standard `.mlmodelc` layout: `model.mil` (or platform-specific), `weights/` (or `*.espresso.weights`), `metadata.json`, `coremldata.bin`, `analytics/` (the exact layout depends on coremltools/coremlc version; the dev records the actual tree in `_bmad-output/ml-training/mlmodelc_layout.txt`)
    **And** running `xcrun coremlc compile` again is **structurally equivalent** (NOT byte-identical — Apple does NOT publicly document byte-identity guarantees for `coremlc compile`; verified Apple-docs review 2026-05-09). Structural equivalence verified by:
       - Compile twice into separate output directories `out1/` and `out2/`.
       - `diff <(plutil -p out1/*.mlmodelc/model.espresso.net) <(plutil -p out2/*.mlmodelc/model.espresso.net)` is empty (op graph + tensor metadata identical).
       - `sha256sum out{1,2}/*.mlmodelc/*.espresso.weights` produces identical hashes per weight blob (deterministic weight serialization is reasonable to expect even if container metadata varies).
       - The dev records the actual idempotence behavior observed (true byte-identity vs structural-only) in `mlmodelc_layout.txt` — this is empirical evidence for future stories, not a contractual claim.

11. **Reference-model sanity HALTs + advisory + soft targets per DD #11 (revised 2026-05-09 third pivot).**

    **Given** the trained `model.pt` and `giantsteps_v1.mlmodelc`
    **When** `uv run python eval.py --checkpoint model.pt --test-corpus oa300` runs
    **Then** **Sanity HALT thresholds (must hold — these gate the story):**
       - Held-out OA300 `acc_4pct ≥ 5%` (≥ 5 of 82 tracks within `|pred - truth| / truth ≤ 0.04`). 12.5× the 0.4% random baseline. **Below 5% → HALT (c).**
       - Non-NaN, non-Inf, finite-sum-to-1 softmax outputs on 100% of OA300 test tracks. **Any non-finite output → HALT (c).**
       - Convert-roundtrip equivalence (post-export.py, AC #9): `coremltools.MLModel(path).predict(x)` agrees with PyTorch eager `model(x)` within `1e-3` on a deterministic test input. **Mismatch → HALT (b).**
    **And** **Advisory HALT (named-DnB) — does NOT block this story, but blocks the 4-5 handoff signoff:**
       - Named DnB triplet `strict_0_5` resolution ≥ 2 of 4 (Charly @ 160, Faraday_Bunker @ 170, Yin Yang @ 170, HEFT_Anagram 6 @ 170; `|pred - truth| ≤ 0.5 BPM` absolute). **Below 2/4 → ADVISORY HALT (d):** the dev produces all artifacts and surfaces to Project Lead before marking Story 4-5 unblocked. Project Lead either (i) accepts the reference model with anticipated Story 4-5 HALT (b) failure (and either re-trains here or accepts that 4-5 will need a different model via the override path), or (ii) blocks story signoff. The point of the advisory: avoid silently handing Story 4-5 a model that will trip its own HALT (b) named-DnB gate.
    **And** **Promotion-warning thresholds (REPORTED — Project Lead signoff required if any miss, but story is not gated):**
       - OA300 test `acc_4pct ≥ 25%` — "decent reference default" promotion warning per Codex 2026-05-09 review.
       - If miss: dev must explicitly note in Completion Notes "Reference model BELOW 25% OA300 floor; Project Lead acknowledged consumer-override is the recommended path." Without that note, story does not move to `review`.
    **And** **Soft quality targets (REPORTED, no signoff needed — purely informational):**
       - GiantSteps val `acc_4pct ≥ 55%` — literature ballpark for 3-block S&M variant.
       - OA300 test `acc_4pct ≥ 40%` — cross-corpus generalization target.
       - Named-DnB `strict_0_5 ≥ 3/4` — beyond the advisory minimum.
    **And** `_bmad-output/ml-training/eval_report.json` is produced with schema:
    ```json
    {
      "metadata": { "git_sha": "...", "training_seed": 42, "feature_set_version": "v1", ... },
      "test_corpus": "oa300",
      "test_size": 82,
      "metrics": {
        "acc_4pct_count": <Int>, "acc_4pct_percent": <Float>,
        "acc_2pct_count": <Int>, "acc_2pct_percent": <Float>,
        "strict_0_5_count": <Int>, "strict_0_5_percent": <Float>
      },
      "sanity_halts": {
        "oa300_acc_4pct_>=_5pct": <bool>,
        "non_nan_outputs_100pct": <bool>,
        // Renamed in chunk-1 review (Codex C9): now compares logits, not argmax.
        // OMITTED entirely from the report when --source != "both" (chunk-2 P12
        // omit-keys-when-skipped pattern) — absence is unambiguous.
        "convert_roundtrip_logit_within_1e3": <bool>  // present only when --source=="both"
      },
      "advisory_halts": {
        "named_dnb_strict_0_5_>=_2_of_4": <bool>,
        "_advisory_only": "below threshold blocks Story 4-5 signoff, not Story 4-4b production"
      },
      "promotion_warnings": {
        "oa300_acc_4pct_>=_25pct": <bool>,
        "_signoff_required_if_false": "Project Lead must acknowledge in Completion Notes"
      },
      "soft_targets": {
        "giantsteps_val_acc_4pct_>=_55pct": <bool>,
        "oa300_acc_4pct_>=_40pct": <bool>,
        "named_dnb_strict_0_5_>=_3_of_4": <bool>
      },
      "named_dnb_results": [
        { "track_id": "Charly", "ground_truth_bpm": 160.0, "predicted_bpm": <Float>, "abs_error_bpm": <Float>, "rel_error_pct": <Float>, "acc_4pct": <bool>, "acc_2pct": <bool>, "strict_0_5": <bool> },
        { "track_id": "Faraday_Bunker", ... },
        { "track_id": "Yin Yang", ... },
        { "track_id": "HEFT_Anagram 6", ... }
      ],
      "per_track_predictions": [...]
    }
    ```
    **And** `eval.py` runs inference **directly through the produced `.mlmodel`** (via `coremltools.models.MLModel.predict`) — not through a Python re-implementation of `BNNSTechnique`. Story 4-5 owns the BNNSGraph featurize/infer parity validation at its own AC; Story 4-4b validates only that the .mlmodel produces sensible BPM predictions on the held-out corpus.
    **And** if any sanity HALT trips: surface to Project Lead with `eval_report.json` + `training_log.json` evidence per DD #12 — story does not advance.
    **And** if advisory HALT (d) trips: surface to Project Lead BEFORE marking Story 4-5 unblocked (Task 10.3) — Project Lead decides whether to re-train, accept and warn 4-5, or require consumer-override path from the start.
    **And** if promotion warning trips: dev must include the explicit acknowledgement text in Completion Notes before moving the story to `review`.

12. **Reproducibility & gating checklist for the training pipeline.**

    **Given** the Story 4-4b dev work is complete
    **When** the standard gating checklist runs
    **Then** ALL of the following pass:
    - `cd _bmad-output/ml-training && uv sync --locked` — clean dep resolve from `uv.lock` (idempotent)
    - `cd _bmad-output/ml-training && uv run python -c "import torch; print(torch.backends.mps.is_available())"` — prints `True` (M5 Max MPS available)
    - `cd _bmad-output/ml-training && uv run python test_feature_parity.py` — passes all 4 staged tolerance checks (Stage 1-4 per AC #3)
    - `cd _bmad-output/ml-training && uv run python eval.py --checkpoint model.pt --test-corpus oa300` — `acc_4pct ≥ 5%` AND non-NaN softmax outputs on 100% of OA300 tracks (sanity HALT (c) per DD #11; the previous `acc_4pct ≥ 30%` HALT was reframed as a soft target 2026-05-09 pivot)
    - `cd _bmad-output/ml-training && uv run python export.py --checkpoint model.pt --output _bmad-output/ml-models/giantsteps_v1.mlmodel` — runs the eager-vs-traced `torch.allclose` assertion AND tensor-name verification (HALT (b) gate per AC #9)
    - `make compile-model ML_MODEL_INPUT=_bmad-output/ml-models/giantsteps_v1.mlmodel` — produces `.mlmodelc/` (HALT (e) gate)
    - **Re-run idempotence check:** running `make compile-model` twice produces structurally equivalent output (op-graph plutil diff empty + per-weight sha256 identical, NOT byte-identical container) per AC #10
    - `swift build` from project root — succeeds with the new `.mlmodelc` resource (no Swift code changes; resource is bundled)
    - `make test` — passes; test count UNCHANGED from pre-Story-4-4b baseline (this story does NOT add tests; tests are Python under `_bmad-output/ml-training/`, not `Tests/`)
    - `make benchmark` AND `make benchmark-giantsteps` — asserted floors hold (AC: corpus floors per Epic 4 Definitions); per-track BPM JSON output is byte-identical to the pre-Story-4-4b regression snapshot (the trained model is NOT exercised by `make benchmark` because Story 4-5 hasn't wired it to `BNNSTechnique` yet — this is the inertness contract for Story 4-4b's Swift-side impact)
    - **`git diff --stat` — ZERO bytes/lines under `Sources/` and `Tests/` except for `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` (the produced artifact)** (HALT (f) gate)
    - **NEW per DD #13:** `cd tools/coreml-convert && uv run python convert.py --checkpoint <reference-checkpoint> --arch reference --output /tmp/test.mlmodelc --validate` — succeeds (HALT (g) gate); negative test with corrupt checkpoint HALTs cleanly.
    - **NEW per DD #13:** `cd tools/coreml-convert && uv run pytest tests/` — passes (synthetic round-trip).

13. **Consumer-facing convert tool at `tools/coreml-convert/` is publicly documented and demonstrably works (DD #0, DD #13).**

    **Given** the Story 4-4b dev work is complete
    **When** a hypothetical consumer (the Story 4-4b dev acting as a consumer for the gating check) follows the `tools/coreml-convert/README.md` instructions
    **Then** `tools/coreml-convert/` exists at repo root with: `pyproject.toml`, `uv.lock`, `convert.py`, `reference_arch.py`, `validate.py`, `README.md`, `tests/` directory
    **And** `cd tools/coreml-convert && uv sync --locked` resolves cleanly
    **And** the README documents 4 worked examples per Task 11.7: (a) reference checkpoint, (b) custom architecture, (c) external PyTorch model (deeprhythm cited as example with explicit AGPL note "consumer's responsibility when bundling"), (d) cross-link to Story 4-5's MLTechnique conformance for runtime wiring
    **And** `uv run python convert.py --help` prints the full CLI surface from DD #13
    **And** running the convert script on the reference `model.pt` produces a `.mlmodelc/` that loads via `coremltools.MLModel` AND produces output within `1e-3` of PyTorch eager on a deterministic test input (DD #11 sanity HALT)
    **And** running on a deliberately-corrupted checkpoint HALTs with a clear error before producing any output (HALT (g) wired)
    **And** `tools/coreml-convert/` is included in the squash-merge to `main` (relaxation of project-context.md "What stays on develop" rule per DD #13, recorded in Change Log)
    **And** **standalone-consumer smoke test (codex 2026-05-09 review, refined per Project Lead 2026-05-09):** the dev validates the convert tool has no repo-relative path dependencies via a git worktree (cleaner than file-copy gymnastics; tests the actual "consumer clones the repo" path):
    ```bash
    git worktree add --detach /tmp/bbbk-consumer-wt HEAD
    cd /tmp/bbbk-consumer-wt/tools/coreml-convert
    uv sync --locked
    uv run python convert.py \
      --checkpoint "$(realpath ~/path/to/reference/model.pt)" \
      --arch reference \
      --output /tmp/test.mlmodelc \
      --validate
    cd "$OLDPWD"
    git worktree remove /tmp/bbbk-consumer-wt
    ```
    The worktree gives a clean repo state with NO dev-only untracked artifacts (`_bmad-output/ml-training/checkpoints/*`, stray `model.pt`, etc.), so the test can't accidentally leak develop-only paths. The checkpoint is passed as an absolute path (realistic — consumers point to their own checkpoints anywhere on disk). If the convert script references any path relative to repo root (`../../_bmad-output/...`) instead of relative to its own `__file__` location or absolute, the worktree test will fail because the checkpoint file isn't where the script assumed. Output captured to `_bmad-output/implementation-artifacts/4-4b-standalone-consumer-test.txt`.

## Tasks / Subtasks

- [x] **Task 1: Pre-source baseline + Python env setup (AC: #1, #2, #12)**
  - [x] 1.1: Confirm working tree is clean and on the Story-4-4b branch. Verify `OA300_CORPUS_PATH` and `GIANTSTEPS_CORPUS_PATH` env vars resolve (HALT (a) if not).
  - [x] 1.2: Capture pre-source regression snapshot: run `make benchmark` AND `make benchmark-giantsteps`; save per-track BPM JSON to `_bmad-output/implementation-artifacts/4-4b-regression-snapshot.json` (the byte-identity comparison baseline for AC #12). Schema mirrors `4-4-regression-snapshot.json`.
  - [x] 1.3: Create `_bmad-output/ml-training/` directory. Initialize Python project: `cd _bmad-output/ml-training && uv init --bare && uv add torch torchaudio librosa numpy coremltools tqdm`. Verify `uv.lock` is generated.
  - [x] 1.4: Verify `coremltools` Python compat at the current PyPI release. If `requires-python` excludes 3.13 (or whatever's current), pin `requires-python = ">=3.11,<3.13"` in `pyproject.toml`. Re-run `uv sync` to verify. **Pinned `>=3.11,<3.14` because coremltools 9.0 supports up to 3.13 (no 3.14 classifier yet); user-approved spec deviation 2026-05-09.**
  - [x] 1.5: Verify MPS availability: `uv run python -c "import torch; print(torch.backends.mps.is_available())"` prints `True`.
  - [x] 1.6: Commit Task 1 artifacts: `Story 4-4b Task 1: pre-source baseline + Python env scaffolding` (mirrors Story 4-4 Task 1 / Story 4-5 Task 1 pattern). **Committed at 73f8188.**

- [x] **Task 2: Corpus split + ground-truth verification (AC: #4)**
  - [x] 2.1: Write `_bmad-output/ml-training/dataset.py` skeleton. Function `build_splits()` reads `OA300_CORPUS_PATH/Tests/.../oa300-ground-truth.json` (path TBD — actual file is at `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` in the repo) and `GIANTSTEPS_CORPUS_PATH/giantsteps-tempo-ground-truth.json`. Builds three lists: `train`, `val`, `test`.
  - [x] 2.2: Verify zero filename overlap: `python -c "..."` per AC #4 — must print empty set. **Confirmed: 0 overlap.**
  - [x] 2.3: Verify the 4 named DnB triplets are in OA300 ground-truth (test set), NOT in GiantSteps train/val. Filenames: `06 Charly (Neekeetone Jungle Rework)`, `1. The Faraday_Bunker (D-Struct Remix)`, `4. Yin Yang Audio_Within Cells Interlinked (Acid Lab Remix)`, `9. HEFT_Anagram 6 (Owl Remix)` — substring match (track_id strings vary slightly between `4-dnb-triplet-targets.json` and `oa300-ground-truth.json`). **All 4 confirmed in OA300 only.**
  - [x] 2.4: Use GiantSteps `splits/fold01.txt` as validation; folds 02-10 as training. Record split assignments to `_bmad-output/ml-training/corpus_splits.json`. **train=595, val=66, test=82 (3 fold entries skipped — not in GT).**

- [x] **Task 3: Feature pipeline + shared fixture + staged parity harness (AC: #3)**
  - [x] 3.1: **Export shared filterbank fixture FROM SWIFT FIRST.** Build a small Swift CLI tool at `_bmad-output/ml-training/swift_feature_extractor/` (NOT in `Sources/`, NOT in `Tests/`) that imports the `BoomBoomBoomKit` package via SPM and dumps `MelFilterbank` matrix, STFT window, hop_size, sample_rate, f_min, f_max, plus a self-sha256 to `_bmad-output/ml-training/fixtures/feature_pipeline_v1.npz`. Compile via `swiftc` against the package. The fixture is THE contract; subsequent steps load it. **Implementation note: Swift CLI re-implements MelFilterbank.buildFilterbank verbatim from Sources/ (rather than @testable importing — would require modifying Sources/ which AC #1 forbids). Drift is caught by the 4-stage parity harness. Build pipeline: Swift CLI → raw .f32 binaries + manifest.json → `build_fixture.py` packs into .npz.**
  - [x] 3.2: Read `BPMAnalyzer.hopSize` exact value from `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` (do NOT modify the Swift file; just read). **hopSize = Int(sampleRate / 100) = 441 at 44.1kHz; halfN = 1024 (NOT 1025) per BPMAnalyzer's split-complex FFT convention.**
  - [x] 3.3: Implement Python feature extractor in `dataset.py`: `extract_features(audio_path, fixture_path) -> np.ndarray` returning `(128, T)` log-mel array. **Vectorized via numpy stride_tricks (was per-frame loop, ~5× faster). Mirrors Swift's POWER spectrum (vDSP_zvmags = |z|^2, NOT magnitude) including the DC^2+Nyquist^2 bin-0 packing convention and the 4× scale factor from vDSP's "first N/2 elements multiplied by 2" rule.**
  - [x] 3.4: Implement temporal window: `def sample_window(features, target_frames=512, training=True)` — random 512-frame contiguous slice for training, centered slice for eval, looped if `T < 512` (loop the array; do NOT zero-pad — zero-padding distorts z-score statistics).
  - [x] 3.5: Implement z-score per-mel-band across time axis: `(features - features.mean(axis=1, keepdims=True)) / (features.std(axis=1, keepdims=True) + 1e-8)`.
  - [x] 3.6: Write parity harness `test_feature_parity.py` per AC #3 with FOUR STAGES (NOT a single end-to-end 1e-5 check). **Final results — Stage 1 (filterbank): abs=0 (byte-identical). Stage 2 (raw mel power): max_abs 1.5e-4 / max_rel 5e-6 (passes via rel). Stage 3 (log-mel): max_abs 9.5e-7 / max_rel 1.0 on near-zero values (passes via abs). Stage 4 (z-scored): click_120bpm max_abs 9.5e-7 (well under 1e-4). Sine Stage 4 informational-only: degenerate stress signal — only 32/128 active mel bands, near-zero std amplifies float32 accumulation noise; verified that Python z-score is bit-identical when fed Swift's Stage 3 output.**

- [x] **Task 4: Model architecture (AC: #5, #6)**
  - [x] 4.1: Implement `model.py` with `TempoCNN(nn.Module)` per DD #6: 3 multi-filter conv blocks + global avg pool + dense + softmax. Output dim 256 (BPM bins per DD #7). **Source of truth lives at `tools/coreml-convert/reference_arch.py` per DD #13 / codex Med #6; `model.py` re-exports.**
  - [x] 4.2: Verify param count is in `[150_000, 350_000]` via `sum(p.numel() for p in model.parameters())`. **315,096 params — block 2 out_per_branch tuned 32→24 to fit budget; model output is logits (CE applies log_softmax internally).**
  - [x] 4.3: Generate `model_summary.txt` via `torchinfo.summary(model, input_size=(1, 1, 128, 512))` or equivalent.
  - [x] 4.4: Embed BPM bin centers `[30.0, 31.0, ..., 285.0]` in `model_metadata.json` for Story 4-5 reference.

- [x] **Task 5: Training loop + augmentation + smoke (AC: #7, #8, #10)**
  - [x] 5.1: Implement `train.py` main loop: data loaders, optimizer (Adam with lr=1e-3, cosine decay over epochs), CE loss with label-smoothing 0.1, train/val `acc_4pct` logging per epoch (per AC #11 named-metric scheme).
  - [x] 5.2: Implement on-the-fly augmentation in `Dataset.__getitem__` ON PCM SIGNAL BEFORE FEATURE EXTRACTION (NOT on cached log-mel tensors). **Switched tempo-stretch from `librosa.effects.time_stretch` (phase vocoder, 277ms/30s) to `scipy.signal.resample` (44ms/30s, 6× faster) — pitch follows tempo (analogous to a tape machine going faster). Preserves DD #10 label-binding contract (`new_bpm = bpm * rate`); preserves rhythmic period for tempo classification.** Pink noise white-noise generation moved from per-sample `random.gauss` loop (180ms) to numpy vectorized (10ms, 18× faster). All other augmentations (gain ±6dB, pink noise SNR 30-50dB, window crop) per spec.
  - [x] 5.3: Set seeds + `torch.use_deterministic_algorithms(True, warn_only=True)` + `os.environ["PYTORCH_ENABLE_MPS_FALLBACK"]="1"` per AC #7. Record metadata header in `training_log.json`.
  - [x] 5.4: Implement checkpointing: save `model.pt` (state_dict only) every 5 epochs to `_bmad-output/ml-training/checkpoints/epoch_{N:03d}.pt`. `--resume <checkpoint>` flag for recovery.
  - [x] 5.5 **Smoke run FIRST:** `uv run python train.py --seed 42 --epochs 1 --subset 32`. **Completed in 68s — well under 2-min HALT (a) ceiling.** Loss 5.54 (~random over 256 bins is log(256)=5.55, model is learning).
  - [x] 5.6: Run full training: `uv run python train.py --seed 42 --epochs 60`. Wall-clock ≤ 6 hours HALT ceiling. **DONE: 60 epochs in 12460s = 3.46h (well within 6h ceiling). Per-epoch wall-clock 215-230s (8 worker run was steady at 215s; switched to 12 workers mid-run at user's suggestion to better utilize M5 Max's 12P+6super cores — 12 workers ended slightly slower at 228s due to I/O contention from 12 concurrent Dropbox-corpus reads, not a CPU cap; 8 was actually optimal). Final val_acc_4pct converged to 0.818 by epoch 50, train_acc_4pct 0.78 (gap is augmentation noise, expected). Smoke run met HALT (a) at 68s.**
  - [x] 5.7: If val `acc_4pct` < 30% at epoch 30, surface HALT (c) candidate to Project Lead with DD #6 escalation paths. **DONE: val_acc_4pct at epoch 30 was well above 30% (~0.75); model converged comfortably. DD #11 third pivot reframed actual HALT (c) gate as `acc_4pct ≥ 5%` on OA300 test (not GiantSteps val). OA300 result 48.8% — passes that gate by 10× margin.**

- [x] **Task 6: Eval + named-track verification (AC: #11)**
  - [x] 6.1: Implement `eval.py`: load checkpoint OR load the produced `.mlmodel` via `coremltools.models.MLModel.predict` (run BOTH and compare outputs match within `1e-3` — surfaces any conversion drift), run inference on OA300 test set, compute the three named metrics per AC #11: `acc_4pct`, `acc_2pct`, `strict_0_5`. Per-track predictions emitted alongside the metrics. **eval.py supports `--source pytorch | coreml | both`. 1-epoch sanity test: 45.8s wall-clock for 82 OA300 tracks.**
  - [x] 6.2: Compute named-DnB-triplet results: for each of the 4 tracks, compute `predicted_bpm`, `abs_error_bpm`, `rel_error_pct`, and the three boolean accuracy flags against `4-dnb-triplet-targets.json`'s `ground_truth_bpm`.
  - [x] 6.3: Emit `eval_report.json` per AC #11 schema with `JSONEncoder` byte-stable output (`sort_keys=True, indent=2`). Include `sanity_halts`, `advisory_halts`, `promotion_warnings`, `soft_targets` blocks per DD #11 third pivot.
  - [x] 6.4: Verify HALT thresholds. **FINAL RESULTS — Sanity HALTs ALL PASS: oa300 acc_4pct=48.8% (≥5% gate, 10× margin); 100% finite softmax outputs; convert-roundtrip 9.54e-7 (within 1e-3 gate after FP32 fix — see HALT (b) note below). Promotion warning PASS: acc_4pct=48.8% ≥ 25% Codex floor. Advisory HALT (d) FAIL: 0/4 named DnB strict_0_5 (Charly 160→152, Faraday_Bunker 170→176, Yin Yang 170→176, HEFT_Anagram 170→180 — model gets BPM range right but misses ±0.5 BPM). User authorized acceptance per DD #11 acknowledgement option (i): proceed with reference model, expect Story 4-5 HALT (b) to trip on these 4 tracks at runtime — Story 4-5 dev addresses via re-train OR override path at that time.**

  **HALT (b) resolution NOTE:** initial export with coremltools 9.0 default `compute_precision=FLOAT16` produced convert-roundtrip max abs 1.15e-3, marginally over the 1e-3 spec gate. Empirically, argmax matches PyTorch eager for 10/10 deterministic random inputs (FP16 drift in logit space < inter-bin margin), so behavior is preserved. User-authorized fix: explicitly set `compute_precision=ct.precision.FLOAT32` in `coremltools.convert(...)` — convert-roundtrip max abs drops to 9.54e-7 (~1200× tighter, well within gate). Cost: model file size 657 KB → 1254 KB (acceptable; spec DD #9 dev-note line "compression: not required" anticipated this). Recorded in Change Log.
  - [x] 6.5: **DO NOT re-implement `BNNSTechnique.featurize` in Python.** eval.py uses `coremltools.MLModel.predict` directly per spec.

- [x] **Task 7: Export to CoreML in separate CPU-only script (AC: #9)**
  - [x] 7.1: Implement `export.py` per Apple's universal pattern: load on CPU, eval mode, deterministic CPU example input, trace on CPU.
  - [x] 7.2: **Numerical-equivalence guard (corenet pattern, AC #9 step 4):** eager-vs-traced `torch.allclose(atol=1e-3)`. **Verified on 1-epoch model: max abs diff = 0.0e+00 (perfect equivalence).**
  - [x] 7.3: Call `coremltools.convert(traced, ..., minimum_deployment_target=ct.target.macOS14, compute_units=ct.ComputeUnit.CPU_ONLY, convert_to="mlprogram")`. Verified.
  - [x] 7.4: Verify tensor names post-convert: input='input', output='output' (Story 4-5 DD #16 contract). **Verified — both names propagate correctly without fallback.**
  - [x] 7.5: Write produced model to `_bmad-output/ml-models/giantsteps_v1.mlmodel`. **Verified empirically: coremltools 9.0 with `convert_to=mlprogram` REQUIRES `.mlpackage` extension and does NOT auto-rename — throws `Exception: For an ML Program, extension must be .mlpackage`. Fix: save as `.mlpackage` then rename directory to `.mlmodel` (Story 4.1 convention; xcrun coremlc compile accepts either). Roundtrip equiv on 1-epoch model: max abs diff 8.3e-4 < 1e-3 HALT (b) tolerance.**

- [x] **Task 8: Compile to `.mlmodelc` + structural-equivalence check + verify Swift-side load (AC: #10)**
  - [x] 8.1: Run `make compile-model`. **HALT (e) gate passes; produces `.mlmodelc` directory tree under `Sources/BoomBoomBoomKitML/Resources/`. NOTE: Story 4.1's Makefile target had `[ ! -f ]` check (file-only) which fails on the .mlmodel directory bundle from coremltools 9.x mlprogram saves. Fixed to `[ ! -e ]` (file OR directory). Recorded as Makefile spec amendment in Change Log.**
  - [x] 8.2: Verify `.mlmodelc` directory tree contents: `analytics/coremldata.bin`, `coremldata.bin`, `metadata.json`, `model.mil`, `weights/weight.bin`.
  - [x] 8.3: **Structural-equivalence check** — compile twice; verify `plutil -p` of `model.mil` is identical via diff + per-weight `sha256sum` is identical. **DONE on FP32 final model: ALL files byte-identical across re-compiles (analytics/coremldata.bin, top-level coremldata.bin, metadata.json, model.mil, weights/weight.bin) — stronger than the spec required. Recorded in `mlmodelc_layout.txt`.**
  - [x] 8.4: Run `swift build` from project root. **Verified: `Build complete!` with new resource bundled.**

- [x] **Task 9: Diff-scope proof + gating checklist (AC: #1, #12)**
  - [x] 9.1: Run `git diff --stat <Task-1-pre-source-SHA>..HEAD -- Sources/ Tests/`. **PASS — all Sources/Tests changes are confined to `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` per HALT (f) gate; verified by `_bmad-output/ml-training/diff_scope_check.sh`.**
  - [x] 9.2: Run `make test`. Verify test count is UNCHANGED from Task 1 baseline. **PASS — 355 tests in 79 suites pass; Story 4-4b adds zero Swift tests.**
  - [x] 9.3: Run `make benchmark` + `make benchmark-giantsteps`. Verify byte-identity vs `4-4b-regression-snapshot.json`. **PASS — OA300 Acc1=58/82 (70.7%) Acc2=74/82 (90.2%) IDENTICAL to baseline; GiantSteps 2pct Acc1=537/661 (81.2%) Acc2=546/661 (82.6%) IDENTICAL to baseline; GiantSteps 4pct (MIREX) Acc1=556/661 (84.1%) Acc2=562/661 (85.0%) IDENTICAL. Story 4-5 hasn't wired `BNNSTechnique` yet so the trained .mlmodelc is bundled but never invoked by `analyzeBPM` — inertness contract holds.**
  - [x] 9.4: Capture `_bmad-output/implementation-artifacts/4-4b-diff-scope-proof.txt`. **DONE.**
  - [x] 9.5: Update Completion Notes with training metrics + DnB triplet table + artifact sizes. **See Dev Agent Record → Completion Notes List below.**

- [x] **Task 10: Commit + handoff to Story 4-5 (AC: #12)**
  - [x] 10.1: Commit the source artifacts (single commit per spec).
  - [x] 10.2: Move story to `review` status.
  - [x] 10.3: Story 4-5 HALT (a') unblocked status: **PARTIALLY UNBLOCKED.** Story 4-5's HALT (a') (real-not-placeholder model) clears: this story produces a real trained `.mlmodelc` with non-NaN finite softmax outputs, OA300 acc_4pct = 48.8%, FP32 conversion roundtrip 9.54e-7. **However, Story 4-5's HALT (b) (named DnB strict_0_5 ≥ 2/4) WILL TRIP on this model (verified at training time: 0/4 strict). User-authorized acceptance per DD #11 advisory HALT (d) acknowledgement option (i): Story 4-5 dev should expect HALT (b) on these 4 tracks and address via re-train OR consumer-override path at that time. Story 4-5 can proceed with `/bmad-dev-story _bmad-output/implementation-artifacts/4-5-bnns-mltechnique-conformance.md`.**

- [x] **Task 11: Consumer-facing convert tool at `tools/coreml-convert/` (AC: #13, DD #0, DD #13)**
  - [x] 11.1: Create `tools/coreml-convert/` directory at repo root. Initialize uv project. **Self-contained `pyproject.toml` + `uv.lock`; deps: torch, coremltools, numpy + dev: pytest.**
  - [x] 11.2: Implement `reference_arch.py` exporting the S&M-style reference architecture. **Single source of truth at `tools/coreml-convert/reference_arch.py` per DD #13 codex Med #6; `_bmad-output/ml-training/model.py` re-exports via `sys.path.insert`. Public: `build_reference_model()`, `verify_param_budget()`, `bin_to_bpm`, `bpm_to_bin`, `BPM_BIN_*`.**
  - [x] 11.3: Implement `convert.py` per DD #13 CLI surface. **Full CLI: `--checkpoint`, `--arch reference|custom`, `--module path:Class`, `--input-shape`, `--output`, `--target macOS14|macOS15|iOS17|iOS18`, `--validate / --no-validate`. Output extensions `.mlpackage`, `.mlmodel` (renames from .mlpackage), `.mlmodelc` (compiles via `xcrun coremlc`).**
  - [x] 11.4: Implement `validate.py` with the three validators (eager-vs-traced, tensor-names, roundtrip).
  - [x] 11.5: Smoke test on the reference checkpoint. **Verified: convert script produces .mlpackage from `_bmad-output/ml-training/model.pt`; tensor names ['input']/['output']; roundtrip max abs 8.3e-4. Standalone-consumer worktree test: pending Task 10.1 commit (worktree clones HEAD).**
  - [x] 11.6: Negative test with deliberately-corrupted checkpoint. **Verified: empty `state_dict={}` checkpoint HALTs cleanly with clear "state_dict shape mismatch (HALT (g))" error and exits non-zero before producing any output.**
  - [x] 11.7: Author `tools/coreml-convert/README.md` with 4 worked examples (Path A same-arch, Path B different-arch, Path C AGPL third-party, Path D runtime wiring). Includes finalized API surface (`Options.mlTechnique` sole override; `BNNSTechnique(modelURL:) throws` ergonomic constructor) + `<!-- FINALIZED-BY-4-5 -->` placeholders for symbols Story 4-5 will lock.
  - [x] 11.8: Author `tools/coreml-convert/tests/` minimal pytest suite. **Originally 3 tests at story dev-time; expanded to 15 tests in chunk-2 review (2026-05-09):** `test_reference_round_trip` (subprocess via `sys.executable` for argparse + cross-process state, plus AC #9 numerical equivalence assertion at the test layer), `test_alternate_checkpoint_round_trip` (HALT (g) "second checkpoint" coverage), `test_module_path_round_trip` (custom-arch + security warning), `test_promotion_failure_restores_existing_artifact` (monkeypatches `os.rename` to prove the crash-recoverable promotion's restore-on-failure branch), `test_existing_mlpackage_survives_validation_failure`, `test_no_orphan_staging_dir_after_failure`, four `test_input_shape_*` boundary tests, two `test_module_args_*` JSON validation tests, plus the original three. **All 15 pass.** New `tools/coreml-convert/conftest.py` provides collection-time `sys.path` bootstrap.

## Dev Notes

### Architecture compliance

- **Swift / SPM target additions are minimal: only the produced reference `.mlmodelc` lands in `Sources/BoomBoomBoomKitML/Resources/` per Story 4.1's `.copy("Resources")` declaration.** ZERO modifications to `Package.swift`, other `Sources/`, or `Tests/`. (The Story 4-5 dev — NOT this story — adds the `MLTechnique` conformance and override API in `Sources/BoomBoomBoomKitML/*.swift`.)
- **`tools/coreml-convert/` is a NEW directory shipping to main per DD #13.** Self-contained Python project, isolated `pyproject.toml`. Not a Swift target; not built or tested by `swift build` / `make test`. Discoverable at `git clone` time by consumers. This is an explicit relaxation of project-context.md "What stays on develop" rule for this single tool.
- **Story 4-5 contract.** The reference model's input/output names are `"input"` / `"output"` per Story 4-5 DD #16 — non-negotiable; mismatches break Story 4-5's `BNNSGraphGetArgumentPosition` lookup. The model's input shape is `(1, 1, 128, 512)` NCHW float32 per Story 4-5 DD #8. The model's output is a 256-class softmax over BPM bins per DD #7. Consumer-supplied models honoring the same contract are interchangeable via the override API.
- **Feature pipeline parity.** The Python training feature extractor MUST match `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` step-by-step (n_fft=2048, n_mels=128, fmin=30, fmax=min(sr/2,16000), `np.log1p(100.0 * mel)`). Hop size matches `BPMAnalyzer.hopSize` exactly. Z-score normalization per-mel-band across time axis is applied AFTER log compression (matches Story 4-5 DD #2 / DD #5). The `MLFeatureFrames.featureSetVersion = "v1"` contract is locked by this story; consumers using the bundled feature extractor inherit "v1"; any future change bumps to `"v2"`. **Custom-architecture consumers** (those implementing their own `MLTechnique` conformance) bypass this contract entirely — they own feature extraction.
- **Pre-1.0 / no-BC framing.** This story produces an artifact + a tool, not a public API surface for the bundled model itself (the `.mlmodelc` is replaceable). The `MLTechnique` protocol IS a public API surface, but Story 4-5 owns its definition lifecycle. The convert tool's CLI surface is documented (DD #13) and stable for consumer use.

### Consumer onboarding (NEW per DD #0 / DD #13 pivot 2026-05-09; API names FINALIZED 2026-05-09 cohesion review)

Consumers wanting to use a different ML model than the bundled reference follow one of three paths. **API names below match Story 4-5 DD #18 / DD #19 finalized signatures: `Options.mlTechnique` is the sole override surface; `BNNSTechnique(modelURL:) throws` is the ergonomic constructor; custom `MLTechnique` conformances are how power users plug in any architecture.**

**Path A — same architecture, different weights** (e.g., consumer trained their own S&M variant on private corpus):
1. Train your model in PyTorch matching the reference architecture (`reference_arch.TempoCNN`).
2. Save state_dict to `model.pt`.
3. `cd tools/coreml-convert && uv run python convert.py --checkpoint /path/to/model.pt --arch reference --output /path/to/your_model.mlmodelc`.
4. Bundle `your_model.mlmodelc` in YOUR app's main bundle.
5. At runtime, swap in your weights:
   ```swift
   let yourModelURL = Bundle.main.url(forResource: "your_model", withExtension: "mlmodelc")!
   options.mlTechnique = try? BNNSTechnique(modelURL: yourModelURL)
   ```
   `try?` returns nil on load failure (graceful degradation); use `try BNNSTechnique(modelURL: ...)` if you want to handle `MLTechniqueError` explicitly per Story 4-5 DD #22.

**Path B — different architecture** (e.g., consumer wants Deep-Rhythm or a transformer):
1. Train your model in PyTorch with whatever input/output shapes you choose.
2. Implement your own `MLTechnique` conformance in your app:
   ```swift
   struct MyDeepRhythmTechnique: MLTechnique {
       func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
           // your featurize → inference → score logic; any backend (Core ML, MLX, custom)
       }
   }
   options.mlTechnique = MyDeepRhythmTechnique()
   ```
3. The `MLTechnique` protocol takes only `BPMDiagnosticTrace` — you read whatever fields you need (`mlFeatures`, `subBandEnergies`, etc.) and do your own feature extraction. The protocol is backend-agnostic per Story 4-5 DD #18 (Core ML, BNNSGraph, MLX, MPS Graph, all valid).
4. License compliance for your model's weights is your problem (BoomBoomBoomKit ships only protocol + bundled reference; your weights live in your app's bundle under your app's license terms).

**Path C — third-party model with non-permissive license** (e.g., consumer wants `bleugreen/deeprhythm` which is AGPL-3.0):
1. Clone the upstream repo, fetch their weights (or train from their architecture).
2. Use Path B (deeprhythm is HCQM-input, ~1.4M params, different input shape) — write a custom `MLTechnique` conformance.
3. **Your app, your license obligations.** AGPL §13 may impose obligations including network-use trigger and source-disclosure requirements depending on linkage and distribution model; consult your own legal counsel before bundling AGPL weights into your app. **BoomBoomBoomKit makes no representation about AGPL or any other upstream-weight license; we ship neither the weights nor any rights to use them. The license obligations of your chosen weights belong to your app's distribution.**
4. The convert tool (`tools/coreml-convert/`) can still help you produce the `.mlmodelc`, but the runtime wiring goes through Path B (custom `MLTechnique` conformance), not Path A (`BNNSTechnique(modelURL:)`), because of the architectural mismatch.

**README at `tools/coreml-convert/README.md` documents all three paths with worked code examples + the unified workflow diagram + license matrix per Story 4-5 AC #15 / AC #16 / AC #17.**

### Why M5 Max + PyTorch MPS

PyTorch's MPS (Metal Performance Shaders) backend in 2.4+ has mature coverage for the ops this CNN uses: `nn.Conv1d`/`Conv2d`, `nn.Linear`, `nn.ReLU`, `nn.MaxPool2d`, `nn.AvgPool2d`, `nn.Dropout`, `F.cross_entropy`. None of these fall back to CPU. The 128 GB unified memory means the entire training corpus's pre-computed features (≈661 GiantSteps tracks × 128 mels × ~3000 frames × 4 bytes ≈ 1 GB) fits in RAM with room to spare; no streaming needed. MPS does NOT guarantee bit-reproducibility across macOS minor versions (this is documented Apple framing) — the held-out test floor (≥ 30% Acc1) is the regression-protection contract per AC #7.

### Why GiantSteps for train/val and OA300 for test

- GiantSteps has 661 tracks, 10 official folds. Standard ML-tempo-estimation corpus. Genre-stratified ground truth.
- OA300 is 82 tracks; too small for meaningful intra-corpus train/test split. Better used as an out-of-distribution test set (different content distribution: heavily-mastered DnB, bedroom-producer mixes, etc.).
- Training on GiantSteps and testing on OA300 also tests **generalization** — the model has never seen OA300 content type at training time. If it generalizes (≥ 30% test Acc1), it's a real model. If it overfits (high val Acc1, low test Acc1), the held-out gate catches it.
- The 4 named DnB triplets are in OA300 → guaranteed not in training set. This is the SAME gate Story 4-5 HALT (b) tests, sanity-checked at training time.

### Why integer BPM bins (256 classes)

- Schreiber & Müller (2018) used 256 classes from 30 to 285 BPM. This story matches the published architecture for transferability of insights (their hyperparameter choices apply).
- 1 BPM/bin resolution is standard for this task. Sub-integer resolution (e.g., 0.1 BPM) explodes the class count to 2560 with little gain — sub-integer ground-truth is rare in tempo-annotated corpora.
- BPM bin centers `[30.0, 31.0, ..., 285.0]` are recorded in `model_metadata.json` so Story 4-5's `bpmBinCenter(forIndex:)` helper can reference the exact mapping (DD #7).

### Why `coremltools` PyTorch path (not ONNX intermediate)

- coremltools 8.x supports PyTorch directly via `torch.jit.trace` → `ct.convert`. No ONNX hop.
- ONNX→CoreML often loses semantic info (e.g., BatchNorm fusion patterns) that coremltools' direct PyTorch path preserves.
- coremltools 8.x is the WWDC 2024-10159-recommended path for production ML model conversion on Apple Silicon ("Bring your ML models to Apple silicon").
- Reference: WWDC 2024-10159 + `https://apple.github.io/coremltools/docs-guides/source/convert-pytorch-models.html`.

### Risk / out-of-scope guards

- **Do NOT** modify `Package.swift`, `Sources/`, `Tests/`, `Makefile`, `CLAUDE.md`. The pipeline lives entirely in `_bmad-output/ml-training/` and produces artifacts under `_bmad-output/ml-models/` and `Sources/BoomBoomBoomKitML/Resources/` (the latter via `make compile-model` only).
- **Do NOT** add training infrastructure as Swift code. The pipeline is Python; the runtime library never imports or references it.
- **Do NOT** ship the training pipeline to `main`. The release process (project-context.md "What stays on develop") excludes `_bmad-output/`. The `.mlmodelc` produced under `Sources/BoomBoomBoomKitML/Resources/` IS shipped to main (it's the runtime artifact).
- **Do NOT** rely on `tempo-cnn`'s pre-trained weights — this story trains from scratch. The reference repo is a *design reference* for the architecture (DD #6), not a weight source. (A future story can revisit if from-scratch training fails repeatedly; for now, training from scratch on the project's own corpora is the chosen path per Project Lead authorization 2026-05-09.)
- **Do NOT** introduce `tempo-cnn` as a Python dep. The architecture is re-implemented cleanly in PyTorch from the paper's specification.
- **Do NOT** train on test set (OA300). Leak prevention is verified by the AC #4 zero-overlap check.

### Apple-platform notes (revised 2026-05-09 review)

- **PyTorch MPS in 2.4+:** `torch.backends.mps.is_available()` returns True on M-series. **`torch.backends.mps.deterministic` does NOT exist as a public API** (verified 2026-05-09 across PyTorch docs, `apple/*` GitHub repos, and PyTorch issue #97236; the previous draft of this story incorrectly claimed it). Use `torch.use_deterministic_algorithms(True, warn_only=True)` for the global determinism switch; this disables MPS optimizations on some ops but is the only documented mechanism. Document residual nondeterminism in `training_log.json`.
- **`torch.jit.trace` vs `torch.export`:** `torch.jit.trace` is the stable Apple-recommended path for coremltools 8.x as of 2026-05-09. `torch.export` (PyTorch 2.x post-export-IR) is supported but **`outputs=[ct.TensorType(name=...)]` is NOT honored on the ExportedProgram path** — output names auto-generate. Default to `torch.jit.trace` to keep tensor-name control; switch only if a critical op fails to trace.
- **Coremltools `minimum_deployment_target=ct.target.macOS15` (final after chunk-2 review DN1):** Original 2026-05-09 review chose `macOS14` for "widest runtime compat" since Apple's own reference repos (`ml-stable-diffusion`, `ml-fastvit`, `corenet`) cap there. Chunk-2 review reversed: BoomBoomBoomKit's own `Package.swift` declares `.macOS(.v15)`, so the .mlmodelc deployment-target floor sitting below the library's own minimum was internally inconsistent. Both `tools/coreml-convert/convert.py` and dev-side `_bmad-output/ml-training/export.py` now default to `macOS15`. The Schreiber-Müller CNN still uses no macOS 15-only MIL features, so a future story can re-widen if needed.
- **`compute_units=ct.ComputeUnit.CPU_ONLY` (changed from `CPU_AND_NE`):** Story 4-5 consumes the `.mlmodelc` via BNNSGraph (WWDC 2024-10211, "Support real-time ML inference on the CPU"; WWDC 2025-276, "What's new in BNNS Graph"). BNNSGraph reads MIL + weight tensors directly and dispatches on CPU; **the `compute_units` flag is a Core ML *runtime* hint that BNNSGraph ignores entirely**. Setting `CPU_ONLY` is honest about the consumer; setting `CPU_AND_NE` would mislead anyone reading the spec into thinking ANE is in scope. Story 4.6 (CoreML conformance) can re-export the same checkpoint with `CPU_AND_NE` if it wants ANE.
- **Train/export separation:** every reference repo in `apple/*` (verified 2026-05-09) separates training (any device) from export (CPU after `model.eval()`, fresh process). This story matches that pattern: `train.py` runs on MPS and exits; `export.py` loads on CPU, traces on CPU, converts. This is non-negotiable; the previous draft implied same-process export.
- **`xcrun coremlc compile` idempotence:** Apple does NOT publicly document byte-identity guarantees. AC #10 reframed 2026-05-09 as structural equivalence (op-graph plutil diff + per-weight sha256), NOT byte-identity.
- **`.mlmodel` vs `.mlpackage` (axiom-ai review 2026-05-09):** coremltools 8.x's `convert_to="mlprogram"` canonically produces a `.mlpackage` directory bundle, not a single `.mlmodel` file. Story 4.1 locked `giantsteps_v1.mlmodel` as the resource convention (Makefile target reads that filename) — pre-dates this story's choice of `mlprogram`. The dev verifies at Task 7 what `mlmodel.save("....mlmodel")` actually writes; the source format is invisible to BNNSGraph (which loads `.mlmodelc`), so resolution is a project-naming concern, not a contract concern.
- **Compression: not required.** A 150-300k param float32 model is ~0.6-1.2 MB. The `coremltools.optimize.coreml` toolkit (palettization / linear quantization / pruning per WWDC 2024-10159) and `coremltools.optimize.torch` (DKM training-time palettization) are available if the artifact ever grows past a few MB, but adding compression now would only spend accuracy without buying anything. Float16 weight conversion remains an option (free 2× size win, negligible accuracy delta on classification) — defer to a later story if size becomes a concern.
- **Resampling at runtime vs training:** Story 4-5's `BNNSTechnique.featurize` uses `vDSP.linearInterpolate(elementsOf:using:result:)` to resample variable-length input to W=512. Training uses fixed 512-frame windows (random for train, centered for eval). This is semantically equivalent — runtime resamples a longer window to 512 frames; training samples a 512-frame slice. The model's training distribution covers any 512-frame slice from a track, so runtime-resampled input is in-distribution. (Aliasing introduced by vDSP linear interpolation IS a marginal concern — float32 linear-interp from N frames to 512 is essentially a low-pass filter; this is documented in Story 4-5 DD #9.)

### Previous Story Intelligence

From Story 4-5 (`ready-for-dev`, blocks on this story):
- **HALT (a') gate.** Story 4-5 DD #12 / HALT (a') REQUIRES a real (non-random-weight) `.mlmodelc` artifact. Story 4-4b is the response to that gate.
- **Tensor name contract.** Story 4-5 DD #16 + AC #1 specify `BNNSGraphGetArgumentPosition(graph, nil, "input")` and `BNNSGraphGetArgumentPosition(graph, nil, "output")`. The trained model MUST honor these names (AC #9).
- **Feature pipeline parity.** Story 4-5 DD #2 + DD #5 lock the `MLFeatureFrames` shape; Story 4-4b's training must produce the same feature pipeline (AC #3).
- **DnB triplet baseline.** Story 4-5 DD #1 freezes the named-track baseline at SHA `9185698`. Story 4-4b's eval reads the same `4-dnb-triplet-targets.json` (AC #11).
- **HALT (b) downstream.** Story 4-5's HALT (b) tests resolution of ≥ 2/4 named DnB triplets at runtime. Story 4-4b's AC #11 named-track gate ensures the trained model has a real chance of clearing it.

From Story 4.1 (`done`, commit `29ced70`):
- **`compile-model` Makefile target.** Story 4.1 ships `make compile-model` reading `ML_MODEL_INPUT ?= _bmad-output/ml-models/giantsteps_v1.mlmodel`. Story 4-4b consumes this target at Task 8 (no modification needed).
- **`.copy("Resources")` discipline.** Story 4.1 DD #2 — `.mlmodelc` is a directory tree. The `compile-model` target produces this tree under `Sources/BoomBoomBoomKitML/Resources/`; it bundles correctly via `.copy`.
- **Tempo classifier resource convention.** Story 4.1 + Story 4-5 settled `giantsteps_v1.mlmodelc` as the model file name. Story 4-4b honors this convention; do NOT rename.

### Project Structure Notes

After Story 4-4b source changes:
- `_bmad-output/ml-training/` is NEW: contains `pyproject.toml`, `uv.lock`, `train.py`, `model.py`, `dataset.py`, `export.py` (renamed from `convert.py` per 2026-05-09 review — separate-script-from-train pattern matches `apple/*` repos), `eval.py`, `test_feature_parity.py`, `README.md`, `corpus_splits.json`, `feature_parity_report.txt`, `model_summary.txt`, `model_metadata.json`, `mlmodelc_layout.txt`, `training_log.json`, `eval_report.json`, `model.pt`, `checkpoints/epoch_*.pt`, `parity_signals.f32` (deterministic parity-harness audio), `fixtures/feature_pipeline_v1.npz` (shared filterbank/STFT-window contract per AC #3 Part A), `swift_feature_extractor/` (subdirectory: small Swift CLI tool that imports the BoomBoomBoomKit SPM package, dumps the fixture .npz and per-stage feature outputs as JSON; compiled via `swiftc`).
- `_bmad-output/ml-models/` is NEW (Story 4.1 deferred its creation here): contains `giantsteps_v1.mlmodel`.
- `Sources/BoomBoomBoomKitML/Resources/` is MODIFIED: `giantsteps_v1.mlmodelc/` directory tree added (alongside the existing `.gitkeep`).
- `_bmad-output/implementation-artifacts/`: NEW `4-4b-regression-snapshot.json`, `4-4b-diff-scope-proof.txt`, `4-4b-tempo-classifier-training.md` (this story file).
- ZERO modifications to: `Package.swift`, `Makefile`, `Sources/BoomBoomBoomKit/`, `Sources/BoomBoomBoomKitML/*.swift`, `Sources/BoomBoomBoomKitTestSupport/`, `Tests/`, `CLAUDE.md`, `_bmad/`.
- Branch `develop` carries everything; squash-merge to `main` excludes `_bmad-output/` (per project release process — only `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` lands on `main`).

### References

- [Source: epics.md:756-771] — Epic 4 preamble (Definitions, framework references).
- [Source: epics.md:1090] — "ML model training is out of scope for Phase 3" — explicit deviation authorized by Project Lead 2026-05-09.
- [Source: _bmad-output/implementation-artifacts/4-5-bnns-mltechnique-conformance.md] — Story 4-5 spec; HALT (a') gate (DD #12); tensor-name contract (DD #16); feature pipeline contract (DD #2, #5); named DnB triplet gate (HALT (b) / DD #11).
- [Source: _bmad-output/implementation-artifacts/4-1-boomboomboomkitml-package-structure.md] — Story 4.1 spec; `.copy("Resources")` (DD #2); `compile-model` Makefile target (AC #5); `giantsteps_v1.mlmodel` resource convention.
- [Source: _bmad-output/implementation-artifacts/4-dnb-triplet-targets.json] — DnB triplet ground truth + frozen baseline (DD #1; named-track AC #11 reads this).
- [Source: Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json] — OA300 ground truth (82 tracks; AC #4 test set).
- [Source: $GIANTSTEPS_CORPUS_PATH/giantsteps-tempo-ground-truth.json] — GiantSteps ground truth (661 tracks; AC #4 train/val source).
- [Source: $GIANTSTEPS_CORPUS_PATH/splits/fold01.txt … fold10.txt] — GiantSteps official 10-fold splits (AC #4 train/val partition).
- [Source: _bmad-output/project-context.md] — Python `uv run` convention (§"Development Workflow Rules"); branch model + release process (§"Development Workflow Rules"); pre-1.0 / no-BC framing (§"Public API Discipline (pre-1.0)").
- [Reference: Schreiber & Müller (2018) "A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural Network"] — `https://archives.ismir.net/ismir2018/paper/000068.pdf` — shallow CNN architecture (DD #6), 256-class BPM bin schema (DD #7).
- [Reference: tempo-cnn reference implementation] — `https://github.com/hendriks73/tempo-cnn` — DESIGN REFERENCE ONLY for the architecture; this story re-implements in PyTorch from the paper, NOT from this Keras codebase.
- [Reference: PyTorch MPS backend documentation] — `https://pytorch.org/docs/stable/notes/mps.html` — MPS availability check, op support.
- [Reference: PyTorch issue #97236] — `https://github.com/pytorch/pytorch/issues/97236` — documents incomplete MPS determinism (cited 2026-05-09 review for DD #4 / AC #7 correction).
- [Reference: PyTorch backends documentation] — `https://docs.pytorch.org/docs/stable/backends.html` — `torch.backends.mps` exposes ONLY `is_available()`, `is_built()`, `is_macos_or_newer()` (no `deterministic` attribute; cited for DD #4 correction).
- [Reference: coremltools PyTorch conversion guide] — `https://apple.github.io/coremltools/docs-guides/source/convert-pytorch-models.html` — `torch.jit.trace` + `ct.convert` flow (AC #9).
- [Reference: coremltools convert API] — `https://apple.github.io/coremltools/source/coremltools.converters.convert.html` — `inputs`/`outputs` TensorType naming behavior on TorchScript vs `torch.export` paths (cited for AC #9 / DD #9 corrections).
- [Reference: librosa.effects.time_stretch] — `https://librosa.org/doc/0.10.2/generated/librosa.effects.time_stretch.html` — confirms `rate > 1` speeds audio up (cited for DD #10 / Task 5.2 label-direction correction).
- [Reference: apple/ml-fastvit `export_model.py`] — `https://github.com/apple/ml-fastvit/blob/main/export_model.py` — Apple's reference pattern: separate export script, CPU trace after `model.eval()` (cited for DD #9 split).
- [Reference: apple/corenet `pytorch_to_coreml.py`] — Apple's reference pattern: numerical-equivalence assertion (PyTorch eager vs traced JIT) before `ct.convert` (cited for AC #9 step 4 — `torch.allclose` guard).
- [Reference: apple/ml-vision-transformers-ane / apple/ml-stable-diffusion / apple/ml-isqoe] — survey 2026-05-09: every Apple training/export reference repo separates the two, traces on CPU, and caps `ct.target` at `macOS14`.
- [Reference: WWDC 2023-10047 "Improve Core ML integration with async prediction"] — async prediction patterns (informs eval.py + future Story 4.6 CoreML conformance).
- [Reference: WWDC 2023-10049 "Use Core ML Tools for machine learning model compression"] — compression techniques (palettization / quantization / pruning); deferred for Story 4-4b but available if model size grows in a future story.
- [Reference: WWDC 2024-10159 "Bring your ML models to Apple silicon"] — coremltools 8 conversion (Task 7).
- [Reference: WWDC 2024-10160 "Train your ML and AI models on Apple GPUs"] — PyTorch MPS unified memory + ExecuTorch path (DD #1 framework choice).
- [Reference: WWDC 2024-10161 "Deploy ML and AI models on-device with Core ML"] — runtime integration, MLModel lifecycle, async prediction, MLState; the runtime-side companion to 10159.
- [Reference: WWDC 2024-10211 "Support real-time ML inference on the CPU"] — directly applicable to Story 4-5's BNNSGraph CPU dispatch; explains why `compute_units=CPU_ONLY` is the honest setting for Story 4-4b's downstream consumer (DD #9 / AC #9).
- [Reference: WWDC 2025-276 "What's new in BNNS Graph"] — latest BNNSGraph framing (Story 4-5's consumer of this artifact).
- [Reference: WWDC 2025-315 "Get started with MLX for Apple silicon"] — alternative training framework if PyTorch-MPS proves limiting for a future re-train (NOT in scope for Story 4-4b; recorded for option-tree continuity).
- [Reference: WWDC 2022-10027 "Optimize your Core ML usage"] — predates `MLShapedArray` but still accurate framing for the model's runtime shape contract.
- [Reference: Axiom CoreML skill — `axiom-ai` → `skills/ios-ml.md` → `coreml`] — canonical project pattern reference for CoreML model conversion, compression, stateful models, MLTensor, async prediction (consulted 2026-05-09 review pass; Patterns 2-7 not applicable to this story but anchor the option tree for future ML stories).

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context) via `/bmad-dev-story` workflow, 2026-05-09.

### Debug Log References

- Training output (transient, not committed): `/tmp/train-full.log`
- Per-epoch wall-clock + train/val acc_4pct: `_bmad-output/ml-training/training_log.json`
- Eval per-track predictions + sanity HALTs: `_bmad-output/ml-training/eval_report.json`
- 4-stage parity harness output: `_bmad-output/ml-training/feature_parity_report.txt`
- .mlmodelc structural-equivalence record: `_bmad-output/ml-training/mlmodelc_layout.txt`

### Completion Notes List

**Training (Task 5):**
- Wall-clock: 12460s = 3.46h (within 6h HALT ceiling; meets stretch <2h goal? — close: 3.46h is well under 6h but not stretch). Smoke run 68s (HALT (a) ≤2 min PASS).
- Final epoch: 59 (60 epochs total; resume-from-checkpoint mid-run when user authorized worker count change 4→8→12).
- Per-epoch wall-clock: 215-230s steady-state (8 workers); 12 workers ended slightly slower at 228s due to I/O contention from 12 concurrent Dropbox-corpus reads (CPU saturated at 8, more workers don't help).
- Final val_acc_4pct: 0.818 (steady from epoch 50+; converged). Train_acc_4pct: 0.795 (gap is augmentation noise).
- Perf optimizations applied vs spec literal: scipy.signal.resample for tempo stretch (was librosa.effects.time_stretch, 6× faster, pitch-coupled but benign for tempo classification), numpy-vectorized white noise (was python rng.gauss loop, 18× faster), vectorized STFT via stride_tricks. Combined: ~3 min/epoch saved.

**Eval (Task 6 / AC #11) — 60-epoch model on OA300 held-out test (82 tracks):**
- acc_4pct: **40/82 = 48.8%** (PASS sanity HALT ≥5%; PASS promotion warning ≥25%; PASS soft target ≥40%)
- acc_2pct: 32/82 = 39.0%
- strict_0_5: 7/82 = 8.5%
- finite_softmax: 82/82 = 100% (PASS sanity HALT)
- convert-roundtrip: 9.54e-7 max abs (PASS sanity HALT ≤1e-3 after FP32 fix; was 1.15e-3 with FP16 default)
- Eval wall-clock: 33.5s

**Named DnB triplet (advisory HALT (d) — does NOT block 4-4b production):**

| Track | Truth | Predicted | Abs error | Rel error | strict_0_5 |
|---|---|---|---|---|---|
| Charly (Neekeetone Jungle Rework) | 160.0 | 152.0 | 8.0 | 5.0% | False |
| 1. The Faraday_Bunker (D-Struct Remix) | 170.0 | 176.0 | 6.0 | 3.5% | False |
| 4. Yin Yang Audio_Within Cells Interlinked (Acid Lab Remix) | 170.0 | 176.0 | 6.0 | 3.5% | False |
| 9. HEFT_Anagram 6 (Owl Remix) | 170.0 | 180.0 | 10.0 | 5.9% | False |

**Result: 0/4 strict_0_5 (advisory HALT (d) trips).** Model gets BPM range right but doesn't pin to ±0.5 BPM. User authorized acceptance per DD #11 advisory HALT (d) option (i): "accept reference model with anticipated Story 4-5 HALT (b) — Story 4-5 dev addresses via re-train OR consumer override path at that time."

**Export + Compile (Task 7-8):**
- `giantsteps_v1.mlmodel` (Story 4.1 directory-bundle convention): 1254 KB (FP32 weights; was 657 KB with default FP16 — see HALT (b) note in Task 6.4)
- `giantsteps_v1.mlmodelc/`: 5 files — analytics/coremldata.bin, coremldata.bin, metadata.json (1.8 KB), model.mil (22.7 KB op graph), weights/weight.bin
- `swift build`: PASS (artifact bundles cleanly via `.copy("Resources")` per Story 4.1 DD #2)
- Tensor names verified: input='input', output='output' per Story 4-5 DD #16 contract
- Eager-vs-traced: 0.0 (perfect)
- Convert-roundtrip: 9.54e-7 (PyTorch eager vs CoreML predict, deterministic input)
- Structural-equivalence: ALL files byte-identical across re-compiles (stronger than spec required)
- Deployment target: macOS15 (matches BoomBoomBoomKit's `Package.swift` `.macOS(.v15)` minimum; user-authorized spec amendment from DD #9's macOS14)

**AC #12 gating checklist outcomes:**
- `make test`: 355 tests in 79 suites — PASS (count unchanged from baseline)
- `make benchmark`: OA300 Acc1=58/82 (70.7%), Acc2=74/82 (90.2%) — BYTE-IDENTICAL to pre-Story-4-4b baseline
- `make benchmark-giantsteps`: 2pct Acc1=537/661 (81.2%), Acc2=546/661 (82.6%); 4pct MIREX Acc1=556/661 (84.1%), Acc2=562/661 (85.0%) — BYTE-IDENTICAL to baseline
- `make compile-model`: PASS (idempotent, structurally equivalent on re-run)
- `swift build`: PASS
- `git diff --stat <baseline>..HEAD -- Sources/ Tests/`: limited to `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` (HALT (f) PASS)
- `tools/coreml-convert/` pytest: 3/3 tests pass (round-trip + corrupted-checkpoint HALT + --no-validate warning)

**Spec amendments applied (user-authorized at execution time):**
1. Python 3.13 (was `>=3.11,<3.13`) — coremltools 9.0 supports 3.7-3.13.
2. Makefile additions for `ml-*` shortcut targets + `compile-model` `[ ! -f ]` → `[ ! -e ]` directory-bundle support fix.
3. Augmentation perf: scipy.signal.resample (was librosa phase vocoder), numpy-vectorized white noise.
4. `compute_precision=ct.precision.FLOAT32` (was coremltools 9.x default FLOAT16) — keeps convert-roundtrip well within 1e-3 spec gate.
5. `minimum_deployment_target=ct.target.macOS15` (was `macOS14` per DD #9) — matches BoomBoomBoomKit's library minimum.
6. Persistent_workers tried then reverted (deadlock on macOS spawn). Worker count: 4→8→12; 8 was empirically optimal (12 workers add I/O contention).

All Change Log entries written under "2026-05-09 (dev-time spec amendments authorized by Project Lead)" + a final entry at close.

**Story 4-5 unblock status:**
- HALT (a') (real-not-placeholder model): UNBLOCKED. Trained `.mlmodelc` ships at `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/`.
- HALT (b) (named DnB strict_0_5 ≥ 2/4 at runtime): WILL TRIP at runtime (0/4 at training time). Per DD #11 acknowledgement option (i), Story 4-5 dev expects this and addresses via re-train or consumer override path.

### File List

**New files (this story):**
- `_bmad-output/ml-training/pyproject.toml`, `uv.lock`, `README.md`
- `_bmad-output/ml-training/dataset.py`, `model.py`, `train.py`, `export.py`, `eval.py`, `test_feature_parity.py`, `build_fixture.py`, `diff_scope_check.sh`, `finalize.sh`
- `_bmad-output/ml-training/swift_feature_extractor/Package.swift`, `Sources/dump-fixture/main.swift`
- `_bmad-output/ml-training/fixtures/feature_pipeline_v1.npz`
- `_bmad-output/ml-training/parity_signals/sine_440Hz_1s.f32`, `click_120bpm_5s.f32`
- `_bmad-output/ml-training/feature_parity_report.txt`, `mlmodelc_layout.txt`, `corpus_splits.json`, `model_metadata.json`, `model_summary.txt`, `training_log.json`, `eval_report.json`, `model.pt`
- `_bmad-output/ml-models/giantsteps_v1.mlmodel/` (directory bundle: Manifest.json + Data/com.apple.CoreML/{model.mlmodel,weights/weight.bin})
- `_bmad-output/ml-models/giantsteps_v1.mlmodel.convert_report.json`
- `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` (directory: analytics/coremldata.bin + coremldata.bin + metadata.json + model.mil + weights/weight.bin)
- `_bmad-output/implementation-artifacts/4-4b-regression-snapshot.json`, `4-4b-diff-scope-proof.txt`
- `_bmad-output/implementation-artifacts/4-4b-tempo-classifier-training.md` (this story file — committed Task 1)
- `_bmad-output/implementation-artifacts/4-5-bnns-mltechnique-conformance.md` (Story 4-5 spec — committed Task 1)
- `tools/coreml-convert/pyproject.toml`, `uv.lock`, `convert.py`, `reference_arch.py`, `validate.py`, `README.md`, `tests/test_round_trip.py`

**Modified files (this story):**
- `.gitignore` (added `__pycache__/`, `.venv/`, `.pytest_cache/`, `_bmad-output/ml-training/checkpoints/`, etc.)
- `Makefile` (added `ml-*` shortcut targets + `compile-model` `-f`→`-e` directory-bundle support)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (4-4b status field updates)

### Review Findings — Chunk 3 of 4 (main-bound non-tool surface — `MODEL_CARD.md`, `Makefile`, `README.md`, `.gitignore`, bundled `.mlmodelc`)

Code review run 2026-05-09 against staged tree at branch `rterhaar/epic-4` vs Task-1-pre-source-SHA `73f8188`. Three parallel reviewers: Blind Hunter (diff-only), Edge Case Hunter (diff + project), Acceptance Auditor (diff + spec). Findings dedup'd and triaged. **Chunks 1, 2, 4 not yet reviewed in this pass.**

- [x] [Review][Decision] README references `BNNSTechnique` / `BNNSTechnique(modelURL:)` before Story 4-5 has shipped — **RESOLVED 2026-05-09 (option a, accept the gap)**. Story 4-5 (`4-5-bnns-mltechnique-conformance`) is `ready-for-dev`; consumers cloning between 4-4b ship and 4-5 ship will hit "Cannot find type 'BNNSTechnique' in scope" on the `README.md:152` / `MODEL_CARD.md:117` BYOM example. Project Lead chose to accept the gap, on the bet that 4-5 lands close behind 4-4b and pre-1.0 consumers tolerate the short window. **Re-open trigger:** if 4-5 slips materially, revisit and switch to option (b) (preview framing) before the next squash to main.

- [x] [Review][Patch] `MODEL_CARD.md` compiled `.mlmodelc` size is 1.2 MB, not 640 KB [`MODEL_CARD.md:36`] — fixed: now reads `1.2 MB compiled .mlmodelc`.
- [x] [Review][Patch] `Makefile` Story-4-4b banner leaks LLM-aided-development workflow to `main` [`Makefile:184-187`] — fixed: banner rewritten as plain technical English; ALSO swept all per-target help strings to strip "(Task N / AC #M)" / "(Task N)" / "(Task N.M)" annotations from the same Makefile section (12 targets) — same defect class, same CLAUDE.md rule.
- [x] [Review][Patch] `Makefile compile-model` target does not clear stale `<name>.mlmodelc` directory before recompile [`Makefile:165-178`] — fixed: added `rm -rf "$(ML_MODEL_OUT_DIR)/$$MODEL_BASE.mlmodelc"` before the compile invocation; uses shell parameter expansion `$${MODEL_NAME%.*}` to handle both `.mlmodel` and `.mlpackage` inputs.
- [x] [Review][Patch] `Makefile ml-export` does not ensure `_bmad-output/ml-models/` parent dir exists [`Makefile:269-272`] — fixed: prepended `@mkdir -p "$(CURDIR)/_bmad-output/ml-models"` to the recipe.
- [x] [Review][Patch] `Makefile ml-convert` writes to a hard-coded `/tmp/coreml-convert-test.mlmodelc` [`Makefile:281`] — fixed: now uses `$$(mktemp -d)/coreml-convert-test.mlmodelc` per invocation.
- [x] [Review][Patch] `Makefile ml-pipeline` advertises "End-to-end gate run" but skips `ml-train` [`Makefile:290-291`] — fixed: help string rewritten as `Post-training gate run — ... (assumes ml-train has already produced model.pt)` so the precondition is explicit.
- [x] [Review][Patch] `MODEL_CARD.md` reproducibility recipe runs `make ml-train` from the wrong cwd [`MODEL_CARD.md:84-91`] — fixed: recipe now runs all `make` targets from project root (`make ml-train-deps && make ml-train && ...`), with an inline note that the targets fail loudly on `main`-only checkouts.
- [x] [Review][Patch] `Makefile ml-train-resume` fails when `CHECKPOINT` is given as a project-root-relative path [`Makefile:255-260`] — fixed: recipe now resolves `CHECKPOINT` via `python3 -c "os.path.realpath"` from `$(CURDIR)` before `cd` so absolute and relative inputs both work.

- [x] [Review][Defer] `MODEL_CARD.md` GiantSteps split sums to 661 (595+66) but CLAUDE.md cites the dataset as 664 tracks [`MODEL_CARD.md:43-44`] — deferred, doc polish; CLAUDE.md doesn't ship to main, so consumer-only readers won't see the discrepancy. Optional: add a footnote "(661 = 664 minus 3 tracks with malformed labels)".
- [x] [Review][Defer] `MODEL_CARD.md` OA300 entry shows 82 tracks under a corpus named "OA300" without explaining the 218 missing tracks [`MODEL_CARD.md:45`] — deferred, doc polish; OA300 is documented project-internally as 300 onset audio with 82 ground-truth-labeled. Optional: parenthetical "(82 labeled subset of the 300-track project-internal corpus)".
- [x] [Review][Defer] License posture for trained-weights derivative work on GiantSteps + OA300 corpora needs counsel review [`MODEL_CARD.md:134-138`] — deferred, out of code-review scope. The bundled model is a derivative work and the "distributed under the same license as BoomBoomBoomKit" claim assumes corpus licenses permit weight redistribution. Track separately for Epic 4 retrospective / pre-1.0 legal review.

**Dismissed as noise (not surfaced as findings):** Blind Hunter context-error claims (M5 Max as "unannounced", torch 2.11 / coremltools 9.0 as "forward-dated", `2026-05-09` as "future" — current date is 2026-05-09 and these are real shipped versions); accuracy-table contradiction with CLAUDE.md (Blind Hunter hallucinated 87.8%, MODEL_CARD's 70.7%/90.2% match CLAUDE.md ground truth); compute-units field "unenforceable from artifact" (correct as written — describes consumer behavior, not artifact metadata); metadata.json platform list over-advertising (coremltools-generated, informational); `cd $(VAR) && cmd` shell semantics (each Make line is its own shell, correct); trailing-newline cosmetics on JSON/MIL files; `__pycache__/` and `.venv/` unscoped gitignore (correct as written); `make ml-export` "overwriting bundled artifact" (writes to dev-only `_bmad-output/ml-models/`, not the shipped `Sources/BoomBoomBoomKitML/Resources/`); README "self-undermining marketing copy" (the disclosure is the right call).

### Review Findings — Chunk 2 of 4 (`tools/coreml-convert/` consumer-facing CLI)

Code review run 2026-05-09 on `tools/coreml-convert/{convert.py, reference_arch.py, validate.py, tests/test_round_trip.py, README.md, pyproject.toml}` (uv.lock excluded as auto-generated). **Four parallel adversarial reviewers**: Claude Blind Hunter, Claude Edge Case Hunter, Claude Acceptance Auditor, Codex Blind Hunter (run via Codex MCP). Codex caught 3 high-impact findings the Claude panel missed (C4, C6, C12 below), validating the cross-LLM second-opinion approach for high-stakes consumer-facing code.

- [x] [Review][Decision] `--target` default macOS14 vs macOS15 — **RESOLVED 2026-05-09 (option a, align consumer default to macOS15)**. `convert.py:327` and `README.md:168` default `macOS14` per DD #13 literal text, but the bundled artifact's `metadata.json` availability says `macOS 15.0` (per Completion Notes line 693 spec amendment). Project Lead chose to align: consumer default matches the de facto policy, so consumer-converted models have the same availability as the bundled reference. **Side effect:** DD #13 line 167's literal "default macOS14" needs a one-line amendment in the Change Log to record the consumer-side bump. Patch list: convert.py default + README.md docs + Change Log entry.

**HIGH-IMPACT PATCHES (8) — load-bearing for AC #9 / AC #13 / DD #9 / HALT (g):**

- [x] [Review][Patch] **[Codex C6] Validation failure leaves bad `.mlmodelc` on disk despite README promising "refused to ship"** [`convert.py:370-372`, `README.md:182`] — README line 182 reads "A failure on any check exits with code 1 and refuses to ship the `.mlmodelc`." Code returns 1 with `final_path` (the bad `.mlmodelc`) still on disk and a `convert_report.json` next to it advertising the failure. Either: (a) `shutil.rmtree(final_path)` + `report_path.unlink(missing_ok=True)` on validation failure to honor the README contract (preferred — README's contract is the right semantics), or (b) update README to disclose that the artifact remains for inspection.
- [x] [Review][Patch] **[Codex C12] `.mlmodelc` output validation rebuilds a fresh `.mlpackage` and validates THAT, never opens the compiled `.mlmodelc` on disk** [`convert.py:306-316`] — when output is `.mlmodelc`, the validation path saves `ml_model` (the in-memory MLProgram) to `recovery_pkg = final_path.parent / (final_path.stem + ".mlpackage.tmp")`, validates that copy, then deletes it. The actually-compiled `.mlmodelc` produced by `xcrun coremlc compile` is never re-loaded. Compile-time corruption (truncated `weight.bin`, broken op-graph, missing analytics dir) would silently pass validation. Restructure: (i) move tensor-name + roundtrip validation to run on `tmp_pkg` BEFORE compile (since `.mlpackage` is the natively-loadable form), then (ii) add a post-compile structural check that asserts the `.mlmodelc` directory has the expected layout (`metadata.json`, `model.mil`, `coremldata.bin`, `weights/weight.bin` non-empty, file sha256 of weights matches the .mlpackage).
- [x] [Review][Patch] **[Codex C4] Output extension validated AFTER `.mlpackage` already created on disk** [`convert.py:209-292`] — `tmp_pkg = out_path.with_suffix(".mlpackage")` and `ml_model.save(str(tmp_pkg))` execute BEFORE the `if/elif` extension dispatch. Calling `convert.py --output foo.bad` saves `foo.mlpackage` to disk before reaching `else: return 2`, leaving an orphan artifact. Patch: hoist `if out_path.suffix not in {".mlpackage", ".mlmodel", ".mlmodelc"}: return 2` to immediately after argparse, before the conversion step.
- [x] [Review][Patch] **[Edge+Auditor / AC #9 spec amendment] Missing `compute_precision=ct.precision.FLOAT32` in `ct.convert(...)`** [`convert.py:442-449`] — Spec line 867 / Change Log records the AC #9 step 5 amendment: "add `compute_precision=ct.precision.FLOAT32` to the canonical `coremltools.convert(...)` invocation" because coremltools 9.x's FP16 default produced 1.154e-3 max abs roundtrip (just over the 1e-3 HALT (b) gate). The training-side `_bmad-output/ml-training/export.py` was patched; the consumer-facing `convert.py` was not. Consumers running this tool with coremltools 9.x silently inherit FP16 and fail validation on otherwise-good checkpoints. Patch: add `compute_precision=ct.precision.FLOAT32` to the `ct.convert` keyword args.
- [x] [Review][Patch] **[Edge+Auditor / DD #9] Missing `ct.utils.rename_feature` fallback** [`convert.py:528-541`, `validate.py:18-23`] — DD #9 lines 95-98: "Defensive fallback: if names didn't propagate, apply `ct.utils.rename_feature(spec, old_name, "input"/"output")` and re-save." `validate_tensor_names` returns `(False, …)` on mismatch and the caller HALTs with no recovery attempt. Patch: when input/output names don't match, call `ct.utils.rename_feature(ml_model.get_spec(), actual_name, "input"|"output")`, rebuild `MLModel(spec, weights_dir=...)`, save again, then re-run validation. Mirror the `export.py` fallback pattern.
- [x] [Review][Patch] **[Blind+Edge] `--module path:Class` is unsandboxed arbitrary code execution with no warning** [`convert.py:269-289`, `README.md:96-104` Path B] — `spec.loader.exec_module(module)` runs whatever Python is in the file. `cls()` then runs constructor code. README treats this as a normal consumer workflow with no security caveat. Patch: at the top of `load_custom`, print to stderr "WARNING: --module executes arbitrary Python from <abs_path>; only run with model.py files you trust." Add a matching "trust boundary" subsection to README Path B.
- [x] [Review][Patch] **[Edge] `xcrun` missing surfaces as uncaught `FileNotFoundError`** [`convert.py:260-268`] — `subprocess.run(["xcrun", "coremlc", ...])` only catches `subprocess.CalledProcessError`. Consumers without Xcode CLT see a raw traceback. Patch: also catch `FileNotFoundError` with a friendly "Xcode command-line tools required (run `xcode-select --install`)" message and exit 2.
- [x] [Review][Patch] **[Edge] Wrapped-checkpoint dicts (Lightning, Hydra, custom training) fail to load** [`convert.py:374-383`] — `convert.py` calls `model.load_state_dict(state)` directly. The reference's own `model.pt` was saved as a flat state_dict, but the dominant convention in research checkpoints is `torch.save({"state_dict": ..., "optimizer": ..., "epoch": ...})` or `{"model": state_dict}`. Consumers hit a "Missing key(s)" error with no path forward. Patch: before `load_state_dict`, unwrap with `for key in ("state_dict", "model", "model_state"): if isinstance(state, dict) and key in state: state = state[key]; break`.

**MEDIUM PATCHES (8):**

- [x] [Review][Patch] **`cls()` blind no-arg instantiation breaks any custom architecture with required ctor args** — fixed: added `--module-args` JSON-typed flag (`convert.py:103-110`); `load_custom` now accepts kwargs and surfaces a clear `TypeError` with the failing kwargs + hint to use `--module-args`. README Path B gained a worked `--module-args` example. Tests `test_module_args_invalid_json` and `test_module_args_array_rejected` cover the JSON parsing edge cases.
- [x] [Review][Patch] **Non-atomic output writes destroy prior good artifact on failure** — fixed: full restructure in `convert.py:421-580`. All intermediate work staged in a sibling `.coreml-convert.<stem>.<pid>.staging/` dir; new `promote_directory()` helper (`convert.py:142-184`) handles existing-output preservation via `os.rename`-based `.<name>.old.<pid>` rename-and-restore pattern. Validation failure writes to `<output_stem>.failed<ext>` so the consumer's prior good artifact at `--output` survives. Tests `test_promotion_failure_restores_existing_artifact` (monkeypatches `os.rename` for the second-rename failure) and `test_existing_mlpackage_survives_validation_failure` and `test_no_orphan_staging_dir_after_failure` all pass.
- [x] [Review][Patch] **`--input-shape` parser accepts negative, zero, or non-4D dims** — fixed: validation block at `convert.py:222-262` enforces 4D + positive + per-dim 4096 cap + element-product 16M cap. Tests `test_input_shape_too_few_dims` / `test_input_shape_zero_dim` / `test_input_shape_per_dim_cap` / `test_input_shape_element_cap` all pass.
- [x] [Review][Patch] **`--no-validate` warning fires AFTER artifact written; report sets `*_passed: true` even when skipped** — fixed: warning now prints at the start of `main()` (`convert.py:218-224`) AND post-write; report (`convert.py:556-573`) emits only `{skipped, atol}` when skipped — per-check result keys are absent entirely (not nulled). Test `test_no_validate_emits_warning` asserts the absent-keys shape.
- [x] [Review][Patch] **Tests assert finiteness, not numerical equivalence** — fixed: `test_reference_round_trip` now asserts `np.allclose(eager_out, out, atol=1e-3)` (`tests/test_round_trip.py:96-101`).
- [x] [Review][Patch] **Tests subprocess `uv run …` — break on any CI host without `uv` on PATH** — fixed: hybrid pattern. `test_reference_round_trip` uses `subprocess.run([sys.executable, ...])` — no `uv run` dependency. The other 14 tests use `convert_main(argv)` in-process via the new `_run_convert` helper. New `tools/coreml-convert/conftest.py` prepends the parent dir onto `sys.path` at collection time (no per-test sys.path manipulation in test code).
- [x] [Review][Patch] **HALT (g) "round-trip another checkpoint matching the architecture" is not tested** — fixed: `test_alternate_checkpoint_round_trip` builds a second `TempoCNN` with a distinct seed (12345) and asserts round-trip success.
- [x] [Review][Patch] **`--module path:Class` (custom-arch consumer path) has zero test coverage** — fixed: new `tools/coreml-convert/tests/fixtures/custom_arch.py` defines `CustomTempoCNN`; `test_module_path_round_trip` exercises the full custom-arch flow + verifies the security warning is emitted. Uses `monkeypatch.syspath_prepend` and `importlib.util.spec_from_file_location` (no sys.modules registration → no collision risk).

**LOW PATCHES (8) — doc / pin / cleanup:**

- [x] [Review][Patch] `pyproject.toml` pins are too loose — fixed (with corrected rationale): `coremltools>=8.0,<10` upper-bounded; Python pin stays at `<3.14` (Codex first-pass review confirmed coremltools 9 supports 3.13). The rationale for the upper pin is "validated against 8/9 with explicit FLOAT32; defense against unreviewed 10.x changes" — NOT "9.x changed FP16 default" (Apple docs confirm FP16 has been the ML Program default since coremltools 5.0b3).
- [x] [Review][Patch] Intermediate `.mlpackage` colocated with consumer's `--output` — fixed (folded into the P10 atomic-writes restructure): all intermediate work now in a sibling `.coreml-convert.<stem>.<pid>.staging/` dir per `convert.py:421-580`. The consumer's `--output` is touched only by the final `promote_directory()` rename. Sibling staging (rather than `tempfile.mkdtemp` in `/tmp`) was chosen to avoid `EXDEV` cross-filesystem rename failures — Codex flagged this in the v1 review.
- [x] [Review][Patch] `reference_arch.py` docstring channel counts are stale — fixed: layer summary updated to 48ch / 72ch / 96ch, with an inline note explaining the deviation from spec DD #6's stated (32, 32, 32) channel counts (`reference_arch.py:13-26`).
- [x] [Review][Patch] Runtime `assert` for invariant check is silenced under `python -O` — fixed: `reference_arch.py:153-164` now raises `ValueError` instead of `assert`.
- [x] [Review][Patch] `e.stderr.decode()` may itself raise `UnicodeDecodeError` on non-UTF-8 tool output [`convert.py:267`] — fixed: folded into P7's xcrun handler (`e.stderr.decode(errors="replace")`).
- [x] [Review][Patch] README quick-reference example uses the wrong input shape — fixed: `README.md:46` now shows `--input-shape "1,1,128,512"`.
- [x] [Review][Patch] README references `_bmad-output/ml-training/` without noting it's develop-only — fixed: `README.md` "Non-goals" line now says "develop-only, not present on the `main` branch consumers clone".
- [x] [Review][Patch] `--module` silently ignored when `--arch reference` — fixed: warning at `convert.py:200-204` fires when both `--arch=reference` and `--module` are set. Test `test_module_with_arch_reference_warns` asserts the warning text.

**Defers (4):**

- [x] [Review][Defer] README "non-recommended accuracy default" framing too negative compared to spec's "sensible default" posture [`README.md:11,17`] — deferred, framing call; addressed indirectly in MODEL_CARD chunk 3. Re-open if a consumer files an issue suggesting the wording is hostile.
- [x] [Review][Defer] `ReLU(inplace=True)` on sliced (non-contiguous) view in `MultiKernelConvBlock.forward` may produce subtle eager-vs-traced numerical drift [`reference_arch.py:694-705`] — deferred; needs targeted A/B test (eager vs traced output on representative inputs) to confirm whether real drift exists. Speculative until measured.
- [x] [Review][Defer] `weights_only=True` rejects pickles containing custom classes (PyTorch 2.4-2.5 era checkpoints with schedulers / custom transforms / dataclasses) [`convert.py:369`] — deferred; no fallback is the conservative security posture. Re-open if multiple consumers report `UnpicklingError` on common training-framework outputs.
- [x] [Review][Defer] README Path D is a Story 4-5 cross-link rather than the "MLX-trained" worked example originally listed in DD #13 line 158 [`README.md:149-157`] — deferred; spec line 390 (later revision) explicitly accepts the cross-link form, so this matches spec-as-written. Listed for tracking only.

**Dismissed as noise (~13):** Claude Blind Hunter context errors (target_map case-mismatch — argparse `choices` is case-sensitive; `--atol` negative — minor; trailing f-string with no interpolation — cosmetic; "Required macOS Apple Silicon" no platform marker — `xcrun` failure already gives a clear signal); shutil.move string-vs-Path comparison edge cases (only fires under exotic cwd); `report_path` trailing-slash edge cases; cross-device `shutil.move` on directory bundles (very edge); `--output` existing-directory case (already covered by extension-validation hoist P3 + the rmtree path); `convert_seconds` undefined-on-exception (refactor with try/except can address as part of P10 atomic-writes patch); `convert_report.json` "leaks" consumer path strings (paths are the consumer's own; not a real leak); no checksum on `--checkpoint` (`torch.load` gives a usable error); `spec_from_file_location` stem collisions (very edge — only on repeated in-process invocation).

### Review Findings — Chunk 1 of 4 (`_bmad-output/ml-training/` — dev-only training pipeline)

Code review run 2026-05-09 on the Python training pipeline + Swift fixture extractor (2,979 lines of diff). **Four parallel adversarial reviewers** (Claude Blind Hunter, Claude Edge Case Hunter, Claude Acceptance Auditor, Codex Blind Hunter) surfaced ~30 findings, with 8 cross-confirmed by 3-4 reviewers. Chunk 1 is dev-only — the pipeline already produced `model.pt` + `eval_report.json` + the bundled `.mlmodelc`. Review value is reproducibility, correctness, and silent inaccuracy in the audit trail, NOT consumer impact. Project Lead authorized "apply everything" 2026-05-09.

**HIGH-IMPACT PATCHES (8) — load-bearing for AC #1 / AC #4 / AC #7 / AC #8 / AC #9 / AC #11:**

- [x] [Review][Patch] **`export.py` writes `"minimum_deployment_target": "macOS14"` while actually converting at macOS15** — fixed: `export.py:1506` literal updated to `"macOS15"` matching the actual `ct.target.macOS15` call.
- [x] [Review][Patch] **`diff_scope_check.sh` hard-codes `giantsteps_v1.mlmodelc`** — fixed: `ALLOWED_PATH` updated to `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc`. Header docstring also updated.
- [x] [Review][Patch] **Checkpoint format asymmetry** — fixed in both `eval.py` and `export.py`: added the chunk-2 P8 wrapped-dict unwrap pattern (`for wrapper_key in ("model", "state_dict", "model_state_dict", "model_state"): ...`). `make ml-train-resume CHECKPOINT=...` → `make ml-export` now works against either flat or wrapped checkpoints.
- [x] [Review][Patch] **Determinism is theatrical** — all 4 sub-patches landed: (a) `set_seeds` now warns to stderr if `PYTHONHASHSEED` wasn't pre-set in env (Python docs explicit: in-process set is no-op); (b) `CachedTempoDataset._make_rng` no longer mixes `os.getpid()` — now `(base_seed * 1_000_003 + idx) * 1_000_003 + epoch`; (c) added `set_epoch(epoch)` method, called from train loop between epochs so successive epochs see different deterministic augmentations; (d) `--resume` now saves + restores Python/NumPy/PyTorch RNG state via `rng_state` field in the wrapped checkpoint dict.
- [x] [Review][Patch] **HALT (a) wall-clock not enforced in code** — fixed: `train.py` main loop now enforces 2 min smoke ceiling (when `--subset` set) and 6 h full-run ceiling. Each epoch checks elapsed wall-clock; if exceeded, saves partial state to `model.pt.partial` and raises `RuntimeError`. `finalize.sh` retains `set -euo pipefail` (was already present); now also surfaces inner-block exit code via `PIPESTATUS[0]` so step failures aren't masked by `tee`.
- [x] [Review][Patch] **Stage 4 `sine_440Hz_1s` parity result silently set to `passed=True`** — fixed: `StageResult` gained an `informational_only: bool` field. Sine Stage 4 now reports its actual measured pass/fail in the row's `passed` field; the row is marked `informational_only=True` so OVERALL gate excludes it. Output flag is `INFO` / `info` instead of `OK` / `FAIL`. Header now reads `OVERALL (gating rows only)`.
- [x] [Review][Patch] **`eval.py` default `--source` is `"pytorch"` + `convert_roundtrip_within_1e3` defaults `True`** — fixed: default `--source` changed to `"both"` so the canonical gating run exercises CoreML AND captures the convert-roundtrip sanity HALT. When `--source != "both"`, `convert_roundtrip_logit_within_1e3` is OMITTED entirely from `sanity_halts` (mirrors chunk-2 P12 omit-keys pattern). `metadata.max_roundtrip_diff_*` keys also omitted when not measured.
- [x] [Review][Patch] **Leak detection (`_verify_no_leak`) is filename-only** — fixed: added `_normalize_track_key` helper (strips dirs, leading numeric prefix, bracketed suffixes, extension, lowercases) and check both exact filename overlap AND normalized-title overlap. `_verify_dnb_triplets_in_oa300` now takes `gs_gt` and verifies the 4 DnB needles are NOT present in GiantSteps train+val under any normalized form (was only checking OA300 presence).

**MEDIUM PATCHES (10):**

- [x] [Review][Patch] **CoreML/PyTorch roundtrip parity check compares only argmax** — fixed: `predict_pytorch` and `predict_coreml` now return raw logits as the third tuple element. `evaluate_corpus` tracks BOTH `max_roundtrip_diff_bpm` (informational, BPM-class diff) and `max_roundtrip_diff_logit` (binding gate, elementwise logit max abs diff). The sanity HALT is now `convert_roundtrip_logit_within_1e3` against `max_roundtrip_diff_logit`.
- [x] [Review][Patch] **`diff_scope_check.sh` ignores unstaged working-tree violations** — fixed: gate now checks `BASELINE..HEAD` AND `git diff --cached` AND `git diff` (unstaged), aggregating all three and deduping.
- [x] [Review][Patch] **`diff_scope_check.sh` allowed-path grep is prefix-based** — fixed: replaced grep with `git diff` pathspec exclude (`:(exclude)${ALLOWED_PATH}/**`) which anchors at directory boundary and rejects `giantsteps_v1.mlmodelc_backup`-style suffix-collision attacks.
- [x] [Review][Patch] **`export.py` non-atomic output write** — fixed: mirrored chunk-2 P10 sibling-staging pattern. Stage in `out_path.parent / f".export.{stem}.{pid}.staging/"`, validate tensor names + apply rename_feature fallback in staging, then `os.rename`-based promotion (rename existing → `.old.<pid>`, rename staging → final, rmtree old). `try/finally` cleans up staging dir.
- [x] [Review][Patch] **`finalize.sh` AC #12 byte-equality NOT enforced** — fixed: added step `[8b/9]` that `diff -q`s `REGRESSION_SNAPSHOT` against the current snapshot. Soft-skip if snapshot files aren't present (caller can capture them out-of-band); hard-fail with first 40 lines of diff if they drift.
- [x] [Review][Patch] **`finalize.sh` hardcoded `/tmp/coreml-out1` and `/tmp/coreml-out2`** — fixed: `mktemp -d -t coreml-out{1,2}.XXXXXX` per invocation; `trap 'rm -rf ...' EXIT` for cleanup.
- [x] [Review][Patch] **`finalize.sh` lacks `set -euo pipefail` + PIPESTATUS handling** — `set -euo pipefail` was already present; added `exit "${PIPESTATUS[0]}"` after the `tee` so inner-block failures aren't masked. Step `[1/9]` switched from `--source pytorch` to `--source both` (binds AC #11 sanity HALT into the canonical gating run).
- [x] [Review][Patch] **`finalize.sh` hardcoded OA300 path** — fixed: respects `OA300_CORPUS_PATH` and `GIANTSTEPS_CORPUS_PATH` env overrides; fallback to `~/Dropbox/...` defaults via `${HOME}` rather than hardcoded `/Users/rterhaar/`.
- [x] [Review][Patch] **Swift fixture manifest stage shapes reversed** — fixed: `main.swift:381-383` now declares `[frameCount, nMels]` matching the actual row-major `writeFloats2D` layout. Also added `byte_order: "little"` and `float_dtype: "f32"` declarations to the manifest header (Codex C14 / endianness contract).
- [x] [Review][Patch] **`export.py` trace uses `torch.randn` example only** — fixed: traces with two examples (random + featurized-style clamped to `[-3.0, 3.0]` matching the runtime z-scored log-mel distribution); both must `torch.allclose` to atol=1e-3 or the trace is rejected.

**LOW / DOCUMENTATION PATCHES (~10):**

- [x] [Review][Patch] **STFT framing docstring says "centered" but implementation is uncentered** — fixed: `dataset.py:stft_frame_count` docstring rewritten to say "Uncentered Accelerate-style STFT framing matching BPMAnalyzer" and explicitly call out that this is NOT librosa-style centered framing.
- [x] [Review][Patch] **`train.py` librosa.load failure substitutes 5s of zeros** — fixed: failed loads add the index to a `_failed: set[int]` set and are excluded from `len(dataset)` via a skip-and-shift `_idx_to_record` helper. Lazy-path failures recurse to the next valid item; preload-path failures shrink the effective corpus.
- [x] [Review][Patch] **`dataset.py` GiantSteps audio-missing silently skipped without counter** — fixed: added `skipped_audio_missing_giantsteps` counter alongside `skipped_no_gt` in the `_meta` block.
- [x] [Review][Patch] **`dataset.py` pink noise `weights[0] = 1`** — fixed: `_pink_shape` sets `weights[0] = 0.0` to remove DC weighting; pink noise should not contain a DC component.
- [x] [Review][Patch] **`dataset.py` `bin_idx` clamp at high BPM** — fixed: `augment_pcm` gained `allow_stretch: bool = True` parameter; both `TempoDataset` and `CachedTempoDataset` pass `allow_stretch=(bpm <= BPM_BIN_MAX / 1.04)` so high-BPM tracks (>~274) skip stretch and don't silently clamp into bin 255.
- [x] [Review][Patch] **`dataset.py` hard-coded fallback `/Users/rterhaar/...` paths** — fixed: `get_corpus_paths` now requires both env vars to be set; raises `EnvironmentError` with an example export command otherwise. Supports `~` expansion via `Path.expanduser()`.
- [x] [Review][Patch] **`build_fixture.py` doesn't delete stale fixture before writing** — fixed: `FIXTURE_PATH.unlink()` before `np.savez` so a stale `.npz` with different shape is observably replaced (mtime/size).
- [x] [Review][Patch] **`build_fixture.py` fixture loader doesn't validate sample-rate / shapes** — fixed: `load_fixture` now validates `sample_rate == SAMPLE_RATE`, `n_mels == N_MELS`, `n_fft == N_FFT`, `feature_set_version == FEATURE_SET_VERSION`, plus `mel_filterbank` and `stft_window` shapes. Raises `ValueError` with actionable message on mismatch. Added a `FEATURE_SET_VERSION` module constant.
- [x] [Review][Patch] **`eval.py` `non_nan_outputs_100pct` sanity HALT uses `≥99.99`** — fixed: now uses `finite_softmax_count == n` (exact 100%, no rounding tolerance).
- [x] [Review][Patch] **`eval.py` `predict_coreml` fallback `next(iter(out.values()))`** — fixed: now hard-fails with `RuntimeError` if `'output'` key not present in the CoreML predict result. Tensor-name contract is binding.
- [x] [Review][Patch] **`train.py` MPS-availability not enforced** — fixed: `main()` raises `RuntimeError` if MPS unavailable AND `--subset` is not set (full training requires MPS to fit the 6 h budget; smoke runs may use CPU).

**Defers (5):**

- [x] [Review][Defer] **Corpus quality: GiantSteps train+val data is 96 kbps MP3 (lossy)** — major strategic concern raised by Project Lead 2026-05-09; the trained `giantsteps_v1.mlmodelc` reference model inherits this quality ceiling regardless of architecture / hyperparameters. The 4 named DnB-triplet failures (Charly, Faraday_Bunker, Yin Yang, HEFT_Anagram) almost certainly trace partially to lossy onset-envelope smearing. **Action item for next training run** — recorded in `deferred-work.md` with re-open trigger: any future re-train story MUST consult this entry first.
- [x] [Review][Defer] **Augmentation tempo-stretch via `scipy.signal.resample` (FFT-based) wraps boundaries** [`dataset.py:589`] — should use `scipy.signal.resample_poly` (polyphase, no wrap). Current implementation introduces seam discontinuity at frame edges. Defer to next-train story.
- [x] [Review][Defer] **`xcrun coremlc compile` structural-equivalence may be non-deterministic** [`finalize.sh:1582-1589`] — coremlc may embed timestamps in metadata; double-compile + sha-compare may pass/fail spuriously. Defer; investigate with a controlled test before tightening.
- [x] [Review][Defer] **CUDA/cuDNN determinism flags missing** [`set_seeds`] — informational only; project is MPS-only, no CUDA path. Defer.
- [x] [Review][Defer] **No endianness declaration in raw Swift `Float` fixture dumps** — fine on macOS little-endian; brittle for future cross-platform. Defer.

**Dismissed as noise:** Claude Blind Hunter speculative concerns about `vDSP_zvmags` DC/Nyquist packing (the harness explicitly tests this); `compare_within_tol` inflated `max_rel` reporting (cosmetic); `bin_idx` round-half-to-even (banker's rounding is fine, no real-world impact); BatchNorm batch=1 MPS edge (no BatchNorm in model); various "could be cleaner" stylistic flags from the broader review.

### Review Findings — Chunk 4 of 4 (spec/sprint-status doc edits)

Single Acceptance Auditor pass on the spec self-amendments + sprint-status updates + Story 4-5 cross-spec edits. Doc bookkeeping; substantive code review chunks 1-3 already complete. 5 findings; all addressed.

- [x] [Review][Patch] **[BLOCKING] Story 4-5 spec `forResource: "tempo_classifier"` literals (6 occurrences)** — fixed: replace_all in `_bmad-output/implementation-artifacts/4-5-bnns-mltechnique-conformance.md` for `forResource: "tempo_classifier"` → `forResource: "giantsteps_v1"`. The chunk-2 rename had updated `tempo_classifier.mlmodelc` → `giantsteps_v1.mlmodelc` (with extension) but missed the bare-string `forResource:` literals. Without this fix, Story 4-5 dev would have crashed at `init() throws BNNSTechniqueError.modelResourceMissing` because `Bundle.module.url(forResource: "tempo_classifier", ...)` returns nil — the actual bundled resource is named `giantsteps_v1.mlmodelc`.
- [x] [Review][Patch] **Story 4-4b narrative body `tempo_classifier` references (16 occurrences in pre-Change-Log content)** — fixed: targeted sed-replace on lines 1..(Change-Log-start - 1) only; Change Log entries dated 2026-05-09 retain original wording as audit trail. Story / DDs / ACs / Tasks / Dev Notes now consistently reference `giantsteps_v1.mlmodelc` / `giantsteps_v1.mlmodel`.
- [x] [Review][Patch] **DD #13 line 167 default `macOS14` superseded by chunk-2 review DN1 but spec body still said macOS14** — fixed: line 167 updated to "default `macOS15` — matches BoomBoomBoomKit's `.macOS(.v15)` package target and the bundled artifact's `metadata.json` availability". DD #9 narrative justification + DD #4 / AC #9 example coremltools.convert calls + Dev Notes "Coremltools `minimum_deployment_target`" section all updated to reflect the macOS15 final state, with brief audit trail of the DN1 reversal.
- [x] [Review][Patch] **AC #11 schema key `convert_roundtrip_within_1e3` was renamed to `convert_roundtrip_logit_within_1e3` (chunk-1 Codex C9) but spec schema still showed old name** — fixed: line 336 now shows `convert_roundtrip_logit_within_1e3` with inline comment explaining the rename + chunk-2 P12 omit-keys-when-skipped behavior.
- [x] [Review][Patch] **Sprint-status `last_updated` + Task 11.8 stale "3 pytests" count** — fixed: sprint-status updated to "15/15 pytests passing (was 3 at story dev-time)" with summary of the 4-chunk review completion + ~70 patches applied; Task 11.8 spec body updated to enumerate the 12 chunk-2 additions on top of the original 3.

**Verified clean (auditor-confirmed):**
- `compute_precision=ct.precision.FLOAT32` present in both `tools/coreml-convert/convert.py:397` and `_bmad-output/ml-training/export.py:137`
- `os.rename`-based crash-recoverable promotion present in both files
- `convert.py:138 default="macOS15"` confirmed
- Stage 4 sine `informational_only=True` honesty fix confirmed
- `eval.py:302 default="both"` confirmed
- Wrapped-checkpoint unwrap pattern present in both `eval.py:325-331` and `export.py:51-57`
- Story 4-4b Tasks 1-11 all flipped `[ ]` → `[x]` and Completion Notes / Debug Log / Agent Model Used populated
- sprint-status `4-4b: review` and `4-5: ready-for-dev` correctly reflect the dev-time state

## Change Log

- **2026-05-09 (Chunk-4 code review revisions).** Single Acceptance Auditor pass on the spec/sprint-status doc bookkeeping. 5 findings, all fixed:
  - Story 4-5 spec: 6 occurrences of `forResource: "tempo_classifier"` → `forResource: "giantsteps_v1"`. **Load-bearing** — without this, Story 4-5 dev would have shipped a model loader that returned nil at runtime.
  - Story 4-4b narrative body: 16 occurrences of `tempo_classifier.mlmodelc` / `tempo_classifier.mlmodel` updated to `giantsteps_v1.*`. Sed-replace on pre-Change-Log lines only; Change Log entries documenting the rename history retain their original wording as audit trail.
  - DD #13 line 167 + DD #9 narrative justification + AC #9 / DD #4 example coremltools.convert calls + Dev Notes section: macOS14 references updated to macOS15 with brief audit-trail of the chunk-2 review DN1 reversal.
  - AC #11 schema key `convert_roundtrip_within_1e3` → `convert_roundtrip_logit_within_1e3` with inline comment about the chunk-1 Codex C9 rename + chunk-2 P12 omit-keys-when-skipped behavior.
  - Sprint-status `last_updated` rewritten: "15/15 pytests passing (was 3 at story dev-time)", summary of 4-chunk review completion + ~70 patches across chunks 1-3, GiantSteps 96kbps MP3 retrain note flagged.

  **All 4 review chunks now resolved.** Story 4-4b is ready to move from `review` to `done`.

- **2026-05-09 (Chunk-1 code review revisions — apply-everything).** All ~30 chunk-1 findings applied to the dev-only training pipeline at `_bmad-output/ml-training/`. 4-pass adversarial review (3 Claude reviewers + Codex Blind Hunter) surfaced 8 cross-confirmed high-impact issues plus 22 medium/low. Project Lead authorized apply-everything 2026-05-09. Notable changes:
  - **Determinism rework** (AC #7 reproducibility envelope): `set_seeds()` now warns at startup if `PYTHONHASHSEED` wasn't pre-set in env (in-process set is a no-op per Python docs); `CachedTempoDataset._make_rng` no longer mixes `os.getpid()` (was breaking same-seed reproducibility across shell sessions); RNG state saved in periodic checkpoints + restored on `--resume` so resumed augmentation matches non-interrupted runs; `set_epoch(epoch)` method called between epochs so successive epochs see different deterministic augmentations (was identical every epoch — defeated DD #10's intent).
  - **HALT (a) wall-clock enforcement** (AC #8): train loop now checks elapsed wall-clock per epoch; raises `RuntimeError` if smoke run exceeds 2 min OR full run exceeds 6 h. Was documented in spec but never tripped in code.
  - **Crash-recoverable export.py** (mirrors chunk-2 P10): all intermediate `.mlpackage` work in sibling `.export.<stem>.<pid>.staging/`; `os.rename`-based promotion preserves the consumer's prior good `.mlmodel`. Trace also runs against TWO example tensors (random + featurized-style) for branch coverage.
  - **AC #11 sanity HALT honesty**: `eval.py` default `--source` flipped from `"pytorch"` to `"both"` so canonical gating run exercises CoreML AND captures the convert-roundtrip HALT. When `--source != "both"`, the `convert_roundtrip_logit_within_1e3` key is OMITTED from `sanity_halts` (mirrors chunk-2 P12 omit-keys-when-skipped). Roundtrip parity now compares logits (`max_roundtrip_diff_logit`), not just argmax-class BPM (was masking massive logit drift inside the same BPM bin).
  - **Cross-corpus leak detection deepening** (AC #4): `_verify_no_leak` now checks both exact filename overlap AND normalized-title overlap (strips numeric prefix, bracketed suffixes, extension; case-insensitive). `_verify_dnb_triplets_in_oa300` now also asserts the 4 named DnB needles are NOT present in GiantSteps train+val under any normalized form.
  - **Filename rename ripple** (AC #1): `diff_scope_check.sh` updated for the `tempo_classifier` → `giantsteps_v1` rename; gate now also covers staged + unstaged changes (was committed-only) and uses `git diff` pathspec exclude `:(exclude)...` (was prefix-grep). `export.py` `convert_report.json` `minimum_deployment_target` literal corrected to `macOS15` (was lying as `macOS14` while actually converting at macOS15).
  - **Honest Stage 4 sine framing** (AC #3): `StageResult` gained `informational_only: bool`. Sine Stage 4 reports actual measured pass/fail; OVERALL gate excludes informational rows. Output flag `INFO`/`info` instead of `OK`/`FAIL`. Click 120bpm Stage 4 remains the binding gate.
  - **Wrapped-checkpoint dict unwrap** (chunk-2 P8 mirror): `eval.py` and `export.py` now handle both flat state_dicts (from final `model.pt`) and wrapped `{"epoch", "model", "optimizer", ...}` dicts (from periodic checkpoints), so `make ml-train-resume → ml-eval / ml-export` works against either form.
  - **Swift fixture manifest** (Codex C10/C14): `[frameCount, nMels]` stage-shape declarations now match actual row-major byte layout (was reversed); manifest gained `byte_order: "little"` and `float_dtype: "f32"` for cross-platform consumer detection.
  - **Plus** ~12 smaller cleanups: `dataset.py` pink-noise DC removal, BPM-stretch-ceiling guard at high BPM, audio-missing counter, hard-coded path removal (require env vars), STFT docstring corrected; `eval.py` exact 100% non-NaN HALT (was ≥99.99 threshold); `eval.py` hard-fail on missing `output` tensor (was silent fallback); `train.py` MPS-required check for full runs; `build_fixture.py` stale-fixture rmtree + load-time validation against module constants; `finalize.sh` `mktemp -d` + AC #12 byte-equality enforcement + env-var corpus paths + `PIPESTATUS` exit propagation.
  - **All 7 chunk-1 Python files import cleanly + bash scripts parse + chunk-2 pytest suite (15/15) still passes + project `make build` + `make test` (355/355) still pass.** AC #1 anti-scope guard preserved.

  **Strategic deferral (recorded in deferred-work.md):** GiantSteps train+val data is 96 kbps MP3 (lossy compression). The trained `giantsteps_v1.mlmodelc` reference model inherits this corpus quality ceiling regardless of architecture/hyperparameters. Next training run should consider HiFi sources (320 kbps / PCM), supplemental higher-quality corpus, or simulated-MP3 augmentation on lossless source material. Project Lead flagged 2026-05-09; required pre-read for any future re-train story.

- **2026-05-09 (Chunk-2 code review revisions).** 16 patches applied to `tools/coreml-convert/` after a 4-pass adversarial review (3 Claude reviewers + Codex) that produced a Codex-approved implementation plan (`/Users/rterhaar/.claude/plans/tender-strolling-nygaard.md`). Notable changes:
  - **DD #13 amendment to `--target` default**: bumped from `macOS14` to `macOS15` (`convert.py:328`, `README.md:166`) so the consumer convert tool default matches the bundled `giantsteps_v1.mlmodelc` artifact's `metadata.json` availability and BoomBoomBoomKit's `.macOS(.v15)` package target. DD #13 line 167's literal "default macOS14" is hereby superseded.
  - **Crash-recoverable output writes** (Codex C5/C6/C7 + P10/P18): all intermediate work staged in a sibling `.coreml-convert.<stem>.<pid>.staging/` dir; `os.rename` (not `shutil.move`) for promotion via a new `promote_directory()` helper that handles existing-output preservation via `.<name>.old.<pid>` rename-and-restore. Validation failure now writes to `<output_stem>.failed<ext>` so the consumer's prior good artifact at `--output` survives forced failures.
  - **`compute_precision=ct.precision.FLOAT32`** added to `ct.convert(...)` per AC #9 amendment — load-bearing for coremltools 9.x default-FP16 environments.
  - **`ct.utils.rename_feature` defensive fallback** added per DD #9.
  - **`--module-args` JSON kwargs flag** for custom architectures with required ctor args; **`--input-shape` validation** (4D + positive + per-dim 4096 cap + element-product 16M cap); **`--no-validate` report shape**: per-check result keys omitted (not nulled) when skipped; **`--module` security warning** when --arch=custom; **xcrun FileNotFoundError caught**; **wrapped-checkpoint dicts auto-unwrapped** (Lightning / Hydra convention support).
  - **15-test pytest suite** (was 3 tests): hybrid subprocess + in-process pattern (using `sys.executable`, not `uv run`); new `test_promotion_failure_restores_existing_artifact` (monkeypatches `os.rename` to fail the second rename, asserts restoration), `test_existing_mlpackage_survives_validation_failure`, `test_no_orphan_staging_dir_after_failure`, `test_input_shape_*` boundary tests, `test_module_args_*` tests. New `tools/coreml-convert/conftest.py` for collection-time `sys.path` setup.
  - **`pyproject.toml`** pin: `coremltools>=8.0,<10` (rationale: validated against 8/9 with explicit FLOAT32; defense against unreviewed 10.x changes — NOT because 9.x changed FP16 default, which Apple docs confirm has been the ML Program default since coremltools 5.0b3).
  - **`reference_arch.py`** docstring channel counts corrected (block 2 is 72ch concat, not 96), `assert` for param budget converted to `raise ValueError` (silenced under `python -O` otherwise).

- **2026-05-09 (Story 4-4b authoring).** Story authored as a prerequisite for Story 4-5 after Project Lead authorized the "training out of scope" deviation per Epic 4 line 1090. Decision tree:
  - **Option (a) — convert tempo-cnn pre-trained Keras weights via coremltools** (in-scope per Story 4-5 spec): rejected because tempo-cnn is unmaintained Keras 1.x with TF1 dep chain; conversion path is fragile; produced model would have a different feature pipeline than `MLFeatureFrames`, requiring runtime adapters that introduce semantic drift.
  - **Option (b) — placeholder/random-weight model** (in-scope per Story 4-5 line 114 path b): rejected because Story 4-5 DD #12 / HALT (a') (post-2026-05-08 hardening) closed this escape hatch.
  - **Option (c) — train from scratch locally on M5 Max against OA300 + GiantSteps** (this story): selected. Local M-series training is feasible for this corpus + model size; the produced model uses a feature pipeline that exactly matches `MLFeatureFrames` (no runtime adapter); the held-out gate (≥ 30% Acc1, ≥ 2/4 DnB) provides empirical "real not placeholder" validation.
  - **Option (d) — stay halted; you provide a model** (status quo): the user explicitly chose option (c) at /ask 2026-05-09.

  This is an explicit out-of-scope deviation from Epic 4 line 1090. Recorded in this Change Log for Epic 4 retrospective consumption.

  **Architecture choices:**
  - Framework: PyTorch + MPS (DD #1) — coremltools 8.x has mature PyTorch path; M-series MPS is canonical 2025+ Apple Silicon training stack.
  - Corpus split: GiantSteps train/val (90/10 via official 10-fold split), OA300 held-out test (DD #3) — leak-free; tests generalization to out-of-distribution material.
  - Architecture: S&M shallow CNN scaled to 3 conv blocks for the smaller corpus (DD #6) — ~150-300k params, fits M5 Max trivially.
  - BPM bins: 256 integer bins from 30 to 285 BPM (DD #7) — matches S&M paper.
  - Floor: held-out OA300 Acc1 ≥ 30% AND DnB triplet ≥ 2/4 within ±0.5 BPM (DD #11) — first floor catches "useless model"; second catches "useless for Story 4-5".

  **Output deliverables for Story 4-5:**
  - `Sources/BoomBoomBoomKitML/Resources/tempo_classifier.mlmodelc/` — the runtime artifact Story 4-5 loads via `BNNSGraphCompileFromFile`.
  - `_bmad-output/ml-models/tempo_classifier.mlmodel` — the conversion source for `make compile-model` re-runs.
  - `_bmad-output/ml-training/eval_report.json` — held-out test set results + named-track outcomes; cited in Story 4-5's pre-implementation review.
  - `_bmad-output/ml-training/model_metadata.json` — BPM bin centers; consumed by Story 4-5 Task 5.2 `bpmBinCenter(forIndex:)` helper.
  - `_bmad-output/implementation-artifacts/4-4b-{regression-snapshot,diff-scope-proof}.{json,txt}` — gating evidence.

- **2026-05-09 (review pass via `/bmad-party-mode`).** Story revised after roundtable review with Codex (plan critique), gh-CLI survey of `apple/*` Python repos for MPS+CoreML training patterns, Apple-docs validation of platform claims, and four BMAD agents (Winston / Amelia / Mary / Siri). Edits applied:
  - **DD #4 / AC #7 / Apple-platform notes:** Removed `torch.backends.mps.deterministic = True` (does not exist as public API; verified PyTorch issue #97236, PyTorch backends docs, zero hits across `apple/*`). Replaced with `torch.use_deterministic_algorithms(True, warn_only=True)` + documented residual MPS nondeterminism. Added `PYTORCH_ENABLE_MPS_FALLBACK=1` env var + per-epoch wall-clock fallback detection.
  - **DD #5 / AC #3:** Replaced flat `1e-5` element-wise feature-parity tolerance with (a) shared `feature_pipeline_v1.npz` fixture (Winston's recommendation: filterbank matrix + STFT window exported once from Swift, loaded by Python — moves the seam from duplicated math to data), and (b) four-stage tolerance contract (Codex's recommendation): Stage 1 fixture round-trip `≤1e-6`, Stage 2 raw mel power `≤1e-5 OR rel ≤1e-4`, Stage 3 log-mel `≤1e-4 OR rel ≤1e-3`, Stage 4 z-scored `≤1e-4 OR rel ≤1e-3`. Each failure surfaces the failing stage by name. Added `ffmpeg` brew dep + `res_type="soxr_hq"` librosa.load pin.
  - **DD #9 / AC #9 / Task 7:** Renamed `convert.py` → `export.py` and split it from `train.py` per Apple's universal pattern (verified across `apple/ml-fastvit`, `apple/corenet`, `apple/ml-vision-transformers-ane`, `apple/ml-isqoe`, coremltools 8.x tutorials — every reference repo separates training from export, ALWAYS tracing on CPU after `model.eval()`). Added eager-vs-traced `torch.allclose(atol=1e-3)` numerical-equivalence assertion before `ct.convert` (corenet's `pytorch_to_coreml.py` pattern) — catches silent trace divergence before producing a poisoned `.mlmodel`. Downgraded `minimum_deployment_target=ct.target.macOS15` → `macOS14` (Apple's own repos cap there; the CNN uses no macOS 15-only MIL features). Changed `compute_units=ct.ComputeUnit.CPU_AND_NE` → `CPU_ONLY` (Story 4-5's BNNSGraph consumer ignores the flag entirely; honest setting per WWDC 2024-10211 + 2025-276).
  - **DD #10 / Task 5.2:** **Inverted tempo-stretch label direction** — corrected `bpm / rate` to `bpm * rate`. librosa.effects.time_stretch `rate>1` makes audio FASTER (returns fewer samples per librosa docs); a 120 BPM track stretched at 1.04× sounds like 124.8 BPM, so the label is `bpm * rate`. Previous draft was backwards; this would have invalidated all augmented training data silently. Also clarified augmentation is on PCM, not on cached log-mel.
  - **DD #11 / AC #11:** Reframed "real not placeholder" floor as **HALT-only gate, paired with soft quality target** (resolves Mary's Project Lead question). HALT triggers: OA300 `acc_4pct ≥ 30%` AND named-DnB `strict_0_5 ≥ 2/4`. Soft targets (reported, not gated): GiantSteps val `acc_4pct ≥ 55%`, OA300 `acc_4pct ≥ 40%`. The model's value to Story 4-5 is ENSEMBLE behavior on DSP failure cases, not standalone accuracy vs DSP optimal (69.5%); recorded for Epic 4 retrospective. Defined three named accuracy metrics — `acc_4pct`, `acc_2pct`, `strict_0_5` — and applied them throughout AC #11 schema. Added architectural-confounder note (Mary): S&M architecture was originally fitted to GiantSteps-class material; cross-corpus generalization framing has a known asymmetry.
  - **AC #10 / Task 8.3 / DD #12 HALT (e):** Replaced byte-identity idempotence claim with **structural equivalence** (op-graph plutil diff + per-weight sha256). Apple does not publicly document byte-identity for `xcrun coremlc compile` (Apple-docs review 2026-05-09); treating it as the handoff invariant was brittle.
  - **DD #12 HALT (a):** Added smoke-run gate (1-epoch / 32-track subset must complete < 2 min per AC #8 / Task 5.5) — catches MPS CPU-fallback silent failures before the dev burns hours.
  - **AC #11 / Task 6.5:** **Removed Python re-implementation of `BNNSTechnique.featurize`** — previous draft asked the dev to re-implement Story 4-5's inference pipeline in Python, which has no source of truth. Story 4-5 owns BNNSGraph parity validation at its own AC. eval.py uses `coremltools.MLModel.predict` directly.
  - **References:** Added 2026-05-09 review citations — PyTorch issue #97236, PyTorch backends docs, librosa time_stretch docs, `apple/ml-fastvit` `export_model.py`, `apple/corenet` `pytorch_to_coreml.py`, WWDC 2024-10160, 2024-10211, 2025-276.

  **Codex's recommendation:** "Approve with revisions." All Hi-severity items applied; Med items applied (paired soft targets, output-name post-convert assertion, structural-equivalence idempotence); Low items applied (smoke-run gate, named accuracy metrics).

  **Architectural change of note (Winston):** the parity contract moved from "feature vector equivalence at 1e-5" to "shared filterbank fixture + staged unit equivalence + numerical-equivalence guard at export." This is the seam reposition that makes Story 4-5 not a guessing game.

  **Story remains `ready-for-dev`.** No tasks have been started; the dev opens a clean story tomorrow.

- **2026-05-09 (axiom-ai / `coreml` skill review pass).** Cross-checked the post-edit story against the canonical Axiom CoreML pattern reference (`/skill axiom-ai` → `skills/ios-ml.md` → `coreml`). Confirmed: macOS14 deployment, separate train/export, `torch.use_deterministic_algorithms`, `coremltools.MLModel.predict` for eval are all aligned with Apple-canonical patterns. Confirmed not-applicable: model compression (Patterns 2-4 — model is ~1 MB float32, under all thresholds), stateful models / KV-cache (Pattern 5 — not a transformer), multi-function (Pattern 6 — single classifier), MLTensor stitching (Pattern 7 — single model). Three additions:
  - **DD #9 / AC #9 step 6 / Task 7.5:** flagged that `convert_to="mlprogram"` in coremltools 8.x canonically produces a `.mlpackage` directory bundle, not a single `.mlmodel` file. Story 4.1's locked `tempo_classifier.mlmodel` resource convention pre-dates this story's `mlprogram` choice. Dev verifies at Task 7 what `mlmodel.save("....mlmodel")` actually writes and resolves the naming. BNNSGraph contract (`.mlmodelc` consumer) is unaffected either way.
  - **Apple-platform notes:** added compression-deferral note (`coremltools.optimize.*` toolkit available; not applied at this model size; float16 conversion remains a free 2× size option for a future re-train).
  - **References:** added WWDC 2023-10047 (async prediction), 2023-10049 (compression), 2024-10161 (Core ML deployment), 2025-315 (MLX alt), and Axiom CoreML skill anchor for future ML stories.

- **2026-05-09 (third revision — bring-your-own-weights adapter pivot).** Project Lead pivoted the story's purpose after research surfaced two facts:
  - **Hugging Face is empty for tempo/BPM** (verified 2026-05-09 via `hf` CLI search across `tempo`, `bpm`, `tempocnn`, `madmom`, `beat tracking`, `tempo estimation`). Only direct hit was a re-upload of `bleugreen/deeprhythm` weights, which are AGPL-3.0 (verified via `gh api repos/bleugreen/deeprhythm/license`).
  - **Foroughmand & Peeters 2019 (Deep-Rhythm) beats S&M on GiantSteps by ~24 absolute Acc1 points** using HCQM features (8-band OSF × 6 harmonics) instead of log-mel — and `bleugreen/deeprhythm` is a working PyTorch port. The architecture is documented well enough to re-implement; the WEIGHTS are AGPL-blocked for closed-source library bundling.

  **Pivot decision:** rather than train one model from scratch and bundle it as the canonical artifact (with all the architecture-choice, license-compatibility, and quality-vs-shipping-velocity questions that entails), redesign Story 4-4b's purpose around a **bring-your-own-weights adapter pattern** (DD #0 added). The library:
  - **Ships a small reference model** (this story produces it via the existing training pipeline — Tasks 2-9 unchanged in mechanics) as the out-of-the-box default.
  - **Exposes `MLTechnique` as a public protocol** (already declared per CLAUDE.md; Story 4-5 ships first conformance + override API + reference model loader).
  - **Provides a public consumer-facing convert tool** at `tools/coreml-convert/` (NEW directory at repo root, ships to main — explicit relaxation of "What stays on develop" rule per DD #13). Consumers convert their own PyTorch checkpoints to `.mlmodelc` honoring the documented contract; bundle into THEIR app; wire via `MLTechnique` or override API. License compliance for upstream weights belongs to the consumer.

  **Concrete edits applied this pass:**
  - **Story title + statement:** reframed from "tempo classifier training" to "Reference Tempo Classifier + Bring-Your-Own-Weights Adapter."
  - **DD #0 (NEW, foundational):** documents the adapter pattern, the three contracts (protocol / default reference / convert tool), and the license posture (consumer owns upstream-weight compliance).
  - **DD #11 (revised):** softened from HALT-only floors (`acc_4pct ≥ 30%` + DnB ≥ 2/4) to sanity HALTs (non-NaN outputs + `acc_4pct ≥ 5%` beats-random + convert-roundtrip equivalence). The 30% / 55% / 40% / 2-of-4 numbers became reported soft targets, not gates.
  - **DD #12 HALT triggers (revised):** HALT (c) reframed to ≥5% sanity floor. **HALT (d) REMOVED** (named-DnB strict_0_5 is now a soft target). NEW **HALT (g)** for convert-script failure on its own reference checkpoint. HALT (f) relaxed to allow the bundled reference `.mlmodelc` under `Sources/BoomBoomBoomKitML/Resources/`.
  - **DD #13 (NEW):** convert-tool contract — directory layout, CLI surface, validation responsibilities, explicit non-goals (no training, no compression).
  - **AC #12 gating checklist:** updated to reflect new sanity-HALT thresholds + added two convert-tool gates.
  - **AC #13 (NEW):** convert tool exists at `tools/coreml-convert/`, README documents 4 worked examples (reference / custom / external AGPL / runtime wiring), CLI works on reference checkpoint, HALTs cleanly on corrupted input, ships to main.
  - **Task 11 (NEW):** 8 sub-tasks for building the convert tool — directory init, reference architecture duplication (intentional, NOT a refactor target), CLI implementation, validation harness, smoke + negative tests, README, pytest suite.
  - **Task 10.1:** commit message expanded to cover `tools/coreml-convert/*`.
  - **Dev Notes "Architecture compliance":** updated to acknowledge the new directory + Story 4-5's responsibility for `MLTechnique` conformance + override API.
  - **Dev Notes "Consumer onboarding" (NEW section):** documents the three consumer paths (same-arch, custom-arch, third-party AGPL).

  **What did NOT change:** training pipeline mechanics (Tasks 2-9), feature pipeline parity contract (DD #5 / AC #3), MPS determinism handling (DD #4 / AC #7), tempo-stretch label direction (DD #10), Apple-canonical separated-train/export pattern (DD #9 / Task 7), tensor name contract (`"input"` / `"output"`), `ct.target.macOS14` + `CPU_ONLY` decisions, structural-equivalence framing (AC #10).

  **Story scope expanded** from ~10 deliverables to ~12 (new: convert tool directory + README + tests). Story 4-5 dependency on this story TIGHTENED: 4-5 now also depends on this story's `MLTechnique` public protocol + override API definition, but those are implemented IN Story 4-5 (consuming the reference `.mlmodelc` Story 4-4b ships). No circular dependency.

  **Open question RESOLVED 2026-05-09 cohesion review (codex Item 2-MOD):** `Options.mlTechnique` is the sole override surface; `BNNSTechnique(modelURL: URL = bundledReferenceURL) throws` is the ergonomic constructor for same-arch consumers; custom `MLTechnique` conformances are the path for different-arch consumers. No `useMLModel(at:)` / `setMLTechnique(_:)` convenience APIs (codex rejected as redundant with `Options.mlTechnique`). Story 4-5 DD #19 finalized the four-row selection table.

  **Story remains `ready-for-dev`.** No tasks have been started.

- **2026-05-09 (codex review pass on third-revision pivot).** Codex flagged 3 Hi-severity inconsistencies + 7 Med/Low gaps after the bring-your-own-weights pivot. All applied:
  - **Hi #1 (AC #11 ↔ DD #11 contradiction):** AC #11 still hard-gated `acc_4pct ≥ 30%` and DnB `≥2/4` after DD #11 was relaxed to ≥5% sanity HALT. Reconciled — AC #11 fully rewritten to match DD #11's three-tier framing (sanity HALTs / advisory HALT / promotion warning / soft targets) with corresponding `eval_report.json` schema additions.
  - **Hi #2 (DnB removal silently defers Story 4-5 HALT (b)):** removing the named-DnB gate as "soft target" silently hands Story 4-5 a known-failing model — Story 4-5's HALT (b) tests the same threshold at runtime. Codex recommended advisory HALT instead. Reinstated as **ADVISORY HALT (d)**: does NOT block 4-4b artifact production but blocks Task 10.3 Story-4-5-unblocked signoff without explicit Project Lead acknowledgement. Three acknowledgement options surfaced (accept with expected 4-5 HALT (b) / re-train / consumer-override-only).
  - **Hi #3 (5% acc_4pct too weak for "decent default"):** the relaxation went too far — random over 256 BPM bins with strong tempo priors makes the realistic floor higher than 0.4%. Added **promotion-warning threshold at OA300 `acc_4pct ≥ 25%`** — non-blocking but requires explicit Project Lead acknowledgement text in Completion Notes if missed.
  - **Med #4 (release-process language):** added explicit project-context.md update text inside DD #13: "tools/coreml-convert/" allowed on main; "_bmad-output/ml-training/" stays on develop. To be propagated to project-context.md at story close-out.
  - **Med #5 (`--no-validate` friction):** updated DD #13 — `--no-validate` now prints stderr warning, sets `convert_report.json.validation.skipped = true`, README explicitly recommends against shipping un-validated outputs.
  - **Med #6 (architecture-duplication drift):** flipped the source of truth — `tools/coreml-convert/reference_arch.py` is canonical; `_bmad-output/ml-training/model.py` imports from it. Single architecture definition, single drift point, smoke-run dev workflow catches incompatible changes.
  - **Med #7 (AC #13 standalone consumer usability):** added standalone-consumer smoke test using `git worktree add --detach` (NOT file-copy-to-tmp gymnastics — Project Lead 2026-05-09 redirect). Worktree gives a clean repo state with no dev-only untracked artifacts, then `cd worktree/tools/coreml-convert && uv sync --locked && uv run python convert.py --checkpoint <abs-path>`. Proves the tool works without ANY repo-relative path dependencies (script must use absolute paths or `__file__`-relative). Output captured to `_bmad-output/implementation-artifacts/4-4b-standalone-consumer-test.txt`.
  - **Med #8 (Consumer Onboarding API names) — SUPERSEDED 2026-05-09 cohesion review:** the pseudocode references to `useMLModel(at:)` / `setMLTechnique(_:)` were resolved by the cohesion review (codex Item 2-MOD): `Options.mlTechnique` is the sole override surface. All references in this story now use the finalized API. The convert-tool README (Task 11.7) ships placeholders marked `<!-- FINALIZED-BY-4-5 -->` for any name whose exact spelling lives in Story 4-5 source; Story 4-5 Task 13 closes the placeholder loop.
  - **Low #9 (AGPL legal language):** Path C disclaimer strengthened from "consumer's responsibility" to "consult your own legal counsel; BoomBoomBoomKit makes no representation about AGPL or any other upstream-weight license; we ship neither the weights nor any rights to use them."

  **Codex final recommendation:** "Approve with revisions." All revisions applied this pass. Story remains `ready-for-dev`.

- **2026-05-09 (Story 4-5 cohesion review — cross-story propagation pass).** Story 4-5 underwent its own revision pass after the BYOW pivot here in 4-4b created cohesion gaps with 4-5's pre-pivot framing. Four BMad agents (Winston / Amelia / Paige / Siri) reviewed cross-story cohesion; codex returned per-item AGREE/MODIFY verdicts; 4-5 was substantially revised. **Cross-cutting changes propagated back to this story:**
  - **Naming finalized (codex M1):** the public Swift type is `BNNSTechnique` (existing Story 4.1 + 4-5 convention) — NOT `BundledTempoClassifier`. Replaced all `BundledTempoClassifier` references in this story.
  - **Override API finalized (codex Item 2-MOD):** `Options.mlTechnique` is the sole override surface. NO `useMLModel(at:)` / `setMLTechnique(_:)` convenience methods. Ergonomics via `BNNSTechnique(modelURL: URL = bundledReferenceURL) throws` constructor. Replaced all pseudocode references in Consumer Onboarding section + Med #8 entry + deferred-question entry. Story 4-5 DD #19 owns the four-row consumer-selection table.
  - **Convert tool README (Task 11.7):** updated to ship with `<!-- FINALIZED-BY-4-5 -->` placeholders for symbol names that depend on Story 4-5 source. Story 4-5 Task 13 closes the placeholder loop. The "two acceptable resolutions" framing (author-after-4-5 vs author-with-WIP-caveat) was superseded by the finalized API decision.
  - **Path A / B / C in Consumer Onboarding:** rewritten with finalized API. Path A uses `Options.mlTechnique = try? BNNSTechnique(modelURL:)`. Path B uses custom `MLTechnique` conformance assigned to `Options.mlTechnique`. Path C language softened per codex Item 15-MOD: "may impose AGPL §13 obligations including network-use trigger; consult counsel" instead of categorical "AGPL your whole app."
  - **Story 4-5 deliverables NEW (consumer-onboarding cohesion):** AC #14 (DocC on `MLTechnique` / `MLTechniqueError` / `BNNSTechnique` / `MLFeatureFrames` / `TensorLayout` / `Options.mlTechnique`); AC #15 (back-propagate placeholders to convert-tool README); AC #16 (unified workflow diagram); AC #17 (license matrix in convert-tool README opening). Story 4-5 Task 12 + Task 13 implement these.

  **Net effect on 4-4b:** scope unchanged. Reference model still produced via the same training pipeline; convert tool still ships at `tools/coreml-convert/`. The placeholder + sequencing convention is now explicit. Story remains `ready-for-dev`.

- **2026-05-09 (dev-time spec amendments authorized by Project Lead).** Two amendments applied during execution, both user-approved at the prompt:

  1. **Python 3.13 instead of spec-literal `>=3.11,<3.13`** (Task 1.4). DD #8 wrote the cap based on coremltools 8.x 2026-05-09 PyPI compat. coremltools 9.0 (now latest) supports Python 3.7-3.13 per PyPI Programming Language classifiers; Python 3.14 is NOT yet supported (no 3.14 classifier). User selected 3.13 over 3.12 to use the most modern supported version. Spec footnote in DD #8 already authorized this: "the dev verifies the current Python compat range at Task 1 and adjusts `requires-python` accordingly." `pyproject.toml` pins `>=3.11,<3.14`.

  2. **Makefile UNCHANGED clause (AC #1) relaxed to allow training/eval/export shortcut targets** AND a `compile-model` `-f → -e` fix. User explicitly requested Makefile targets ("can you add some @../../Makefile targets for the important training and conversion commands?"). Added under a marked "Story 4-4b training pipeline + tools/coreml-convert/ targets" block at the end of the Makefile: `ml-train-deps`, `ml-dump-fixture`, `ml-parity`, `ml-splits`, `ml-summary`, `ml-train-smoke`, `ml-train`, `ml-train-resume`, `ml-eval`, `ml-export`, `ml-convert`, `ml-convert-tests`, `ml-pipeline`. Plus a 1-character `compile-model` guard fix from `[ ! -f ... ]` to `[ ! -e ... ]` because coremltools 9.x's `convert_to=mlprogram` produces `.mlpackage` directory bundles (rather than single files), and Story 4.1's filesystem check pre-dated this convention. The `-e` (exists) check matches both files and directory bundles. Recorded in this Change Log per spec discipline; AC #1's "Makefile UNCHANGED" assertion is amended to "Makefile additions limited to training-pipeline shortcut targets + the `compile-model` directory-bundle support fix; no functional changes to existing Story 4.1 behavior."

  3. **Augmentation perf tuning (Task 5.2 spec amendment).** DD #10 specified `librosa.effects.time_stretch` with the `bpm * rate` label correction. Profiled at 277ms/30s of audio (phase-vocoder). Switched to `scipy.signal.resample` (44ms/30s, 6× faster) which co-shifts pitch with tempo (analogous to a tape machine going faster). For tempo classification, the pitch coupling is benign (model trains on rhythmic period in the onset envelope and is approximately invariant to small pitch shifts of underlying spectral content). Preserves DD #10's label-binding contract `new_bpm = bpm * rate`. Net per-epoch wall-clock: 4.7 min vs unoptimized ~7 min — moves projected 60-epoch run from 7h (over HALT (a) ceiling) to 4.7h (within ceiling). Pink noise generation also moved from per-sample `random.gauss` loop (180ms/call) to numpy vectorized (`np.random.default_rng(seed).standard_normal(n)`, 10ms/call). Determinism preserved via per-call seed derivation from the python RNG.

  4. **`compute_precision=ct.precision.FLOAT32` (Task 7 / AC #9 spec amendment).** Initial export with coremltools 9.0 default (`compute_precision=FLOAT16` for mlprogram) produced convert-roundtrip max abs 1.154e-3 — marginally over the spec's 1e-3 HALT (b) gate. **Empirical verification: argmax matches PyTorch eager 10/10 across deterministic random inputs** (FP16 drift in 256-class logit space < typical inter-bin margin O(0.1+)). User-authorized fix: explicitly set `compute_precision=ct.precision.FLOAT32`. Result: convert-roundtrip drops to 9.54e-7 (~1200× tighter, comfortably within gate). Cost: weights 657 KB → 1254 KB (negligible per spec DD #9 dev-note "compression: not required"). Spec amendment to AC #9 step 5 / DD #9: add `compute_precision=ct.precision.FLOAT32` to the canonical `coremltools.convert(...)` invocation. Story 4-5's BNNSGraph consumer is unaffected (BNNSGraph reads MIL + weights regardless of precision marker).

  5. **`minimum_deployment_target=ct.target.macOS15` (Task 7 / AC #9 / DD #9 spec amendment).** DD #9 specified `macOS14` for "widest runtime compatibility, one full macOS release wider than the library minimum." User clarified at runtime: "MacOS15 and current MacOS26 are the only targets for this." Reasoning: BoomBoomBoomKit's `Package.swift` requires `.macOS(.v15)` minimum; widening the .mlmodelc deployment target to macOS14 is wasted (no library consumer can be on macOS 14 — they'd fail to build the library before reaching the model). Switched to `ct.target.macOS15`. The Schreiber-Müller-style 2-D CNN uses no macOS-15-only MIL features so functional behavior is identical; the deployment-marker change just removes a confusing inconsistency.

  6. **Worker count tuning (Task 5.2 / AC #8 dev-time exploration).** Spec did not pin `--num-workers`. Empirically:
     - `num_workers=4`, no persistent_workers: 273s/epoch (initial setting)
     - `num_workers=8`, `persistent_workers=True`: deadlocked on macOS spawn — workers each accumulated 50+ min CPU but main process consumed zero batches in 52 min real time (known PyTorch issue with persistent + spawn on macOS). Reverted persistent_workers.
     - `num_workers=8`, no persistent: 215s/epoch — 17% faster than 4 workers (winner)
     - `num_workers=12`, no persistent: 228s/epoch — slightly slower than 8 due to I/O contention from 12 concurrent Dropbox-corpus reads (CPU saturated at 8; more workers compete for disk bandwidth, not CPU)

     Final config: `num_workers=8`, no persistent. The Makefile default `TRAIN_WORKERS ?= 4` was kept as the conservative default (works on systems with fewer cores); user docs note that 8 is empirically optimal on M5 Max.

- **2026-05-09 (post-implementation party-mode review — bin-collapse finding + reframing).** Five-voice review (Mary / Winston / Amelia / John + independent Codex consult) on the trained reference model and the open-source release boundary. **Strong consensus across all five voices.** Key findings:

  **Bin-collapse on the reference model (Codex finding, NOT in `eval_report.json` summary).** Per-track prediction analysis surfaced a failure mode worse than "mediocre generalization": the model collapses onto a small set of favored bins. Bin 172 BPM appears 13 times across the 82-track OA300 test, 152 BPM 12 times, 117 BPM 10 times, 176 BPM 3 times. The 85-ish BPM tracks are especially damning: 85 → 176, 86 → 172, 85 → 172, 86.48 → 176/172, 84.92 → 169/172, 82.86 → 168. That is not useful tempo discrimination — it is a double-tempo prior firing. The model has learned "DnB-shaped audio ≈ ~170 BPM" and applies it bluntly. Mary's framing: this isn't a "slightly-weaker-than-DSP default," it is "a known-poor reference artifact that proves the adapter wiring works." This evidence was not in the high-level metrics — only surfaced when Codex inspected `eval_report.json.per_track_predictions` directly.

  **Comparison reframed (NOT a tolerance gap, a model-quality gap).** Initial framing in Story 4-4b's eval section compared `acc_4pct=48.8%` to the existing DSP pipeline's `Acc1=70.7%` and noted "different tolerance — 4% vs 2%." Truer comparison: ML acc_2pct (same 2% tolerance as DSP Acc1) = **39.0% vs 70.7%**. The bundled ML reference model is not just "a smaller fraction passing the tighter gate" — it is **measurably worse than the existing DSP** on the same tolerance. This must be the framing that ships in any consumer-facing documentation.

  **Open-source release boundary (Winston / Amelia / Codex agree).** Net to main from this story: 14 files (5 `.mlmodelc/` artifact + 7 `tools/coreml-convert/` + `Makefile` + `.gitignore`). Net to develop-only: 29 files (training pipeline + reports + uncompiled `.mlmodel` + story bookkeeping). The DD #13 boundary is correct as drawn. Specifically: `_bmad-output/ml-training/` should NOT promote to main — shipping it would imply the library owns "the blessed training pipeline" and inherits a soft commitment to that pipeline working in future versions; the public contract should remain "provide an `MLTechnique`, or convert your PyTorch model with `tools/coreml-convert/`."

  **Reframing the bundled model as fixture, NOT default (John / Codex agree).** The bundled `.mlmodelc` ships to main, but its FRAMING shifts:
  - It is NOT the library's "out-of-the-box ML default." It is a **reference fixture / smoke-test artifact** that proves `BNNSTechnique` can load + predict end-to-end without consumers needing Python.
  - The library's actual product is the DSP pipeline + the `MLTechnique` protocol surface. The bundled model is "documentation in artifact form."
  - **Story 4-5 must NOT auto-enable the bundled model in `Options.intensity = 8+`** until an ensemble policy proves non-negative accuracy delta vs DSP. Until then, `Options.mlTechnique` defaults nil and the bundled model is opt-in only via `try BNNSTechnique()` or `try BNNSTechnique(modelURL: ...)`.

  **Three follow-up artifacts identified — drafted in this same session (NOT deferred):**
  1. **`MODEL_CARD.md` at repo root** — drafted. Discloses 39.0% / 48.8% / 8.5% strict + 0/4 named-DnB + bin-collapse evidence + corpus split + reference architecture summary + naming-convention guidance for future bundled models. Ships to main alongside the `.mlmodelc`.
  2. **`tools/coreml-convert/README.md` reframe** — applied. Header callout added before the path table; row 1 of the table changed from "Use the bundled reference model" → "Use the bundled reference model for adapter smoke tests"; "auto-loaded by `BNNSTechnique`" → "opt-in via `BNNSTechnique`."
  3. **`README.md` "Optional ML Models" section** — drafted. Discloses bundled-vs-DSP numbers explicitly (39.0% vs 70.7% same tolerance), recommends DSP as baseline, frames ML as BYOM-first with a bundled fixture for adapter validation, links to MODEL_CARD.md.

  **DD #11 sanity-HALT thresholds were too lenient.** Mary's strategic framing: a sanity HALT at `acc_4pct ≥ 5%` (12.5× random) was set conservatively but in retrospect the model passes the gate while exhibiting bin-collapse — a failure mode the gate doesn't detect. Future stories with reference-model bundling should add **per-bin distribution sanity** as a HALT (e.g., "no single bin captures > 20% of test predictions"). Recorded for Epic 4 retrospective.

  **Net effect on Story 4-4b status:** No status change — story remains `review`. The party-mode findings sharpen the framing but do not change which artifacts ship. Three follow-up items above are now drafted in the same session, not deferred.

- **2026-05-09 (post-party-mode rename — bundled-model naming convention).** User-authorized spec amendment after the party-mode review surfaced the framing reset. The bundled artifact is renamed to reflect its training corpus, anticipating future bundled models from different corpora.

  **Old name:** `tempo_classifier.mlmodelc` (Story 4.1 / Story 4-5 convention).
  **New name:** `giantsteps_v1.mlmodelc`.

  **Naming convention going forward:** `<corpus>_v<version>.mlmodelc` where `<corpus>` identifies the training source (e.g. `giantsteps`, `oa300`, `mixed`) and `v<version>` is an integer suffix bumped on every re-train. Examples for future bundled models: `giantsteps_v2.mlmodelc`, `oa300_v1.mlmodelc`, `mixed_v1.mlmodelc`. Documented authoritatively in `MODEL_CARD.md`.

  **Files renamed (this story's working tree):**
  - `Sources/BoomBoomBoomKitML/Resources/tempo_classifier.mlmodelc/` → `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` (compiled artifact)
  - `_bmad-output/ml-models/tempo_classifier.mlmodel/` → `_bmad-output/ml-models/giantsteps_v1.mlmodel/` (uncompiled source)
  - `_bmad-output/ml-models/tempo_classifier.mlmodel.convert_report.json` → `_bmad-output/ml-models/giantsteps_v1.mlmodel.convert_report.json`

  **Forward-looking spec updates:** Story 4-5 spec (still `ready-for-dev`) had all `tempo_classifier.mlmodelc` references updated to `giantsteps_v1.mlmodelc` (replace_all, 17 occurrences). Story 4.1 spec (status: `done`) and the historical Change Log entries in this story are NOT modified — they remain accurate to what was discussed at authoring time, with the rename documented here as the canonical forward-pointer.

  **Other files updated:**
  - `Makefile` — `ML_MODEL_INPUT ?= _bmad-output/ml-models/giantsteps_v1.mlmodel` (was `tempo_classifier.mlmodel`); `ml-export` target output path updated.
  - `_bmad-output/ml-training/export.py` — default `--output` argument updated.
  - `_bmad-output/ml-training/eval.py` — `DEFAULT_MLMODEL_PATH` constant updated.
  - `_bmad-output/ml-training/finalize.sh` — paths updated.
  - `_bmad-output/ml-training/mlmodelc_layout.txt` — regenerated against new name.
  - `_bmad-output/ml-training/README.md` — paths updated.
  - `tools/coreml-convert/README.md` — Path A example uses `your_model.mlpackage` (consumer-named, unaffected); reference paths to `giantsteps_v1.mlmodelc`.

  **Re-export + re-compile verification:** export ran cleanly with new name (eager-vs-traced 0.0, convert-roundtrip 9.54e-7, tensor names input/output preserved); `make compile-model` produced `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` (5 files: analytics/coremldata.bin, coremldata.bin, metadata.json, model.mil, weights/weight.bin).

- **2026-05-09 (Story 4-4b dev close-out — moves to `review`).** Final state at completion:
  - **Sanity HALTs (gate the story): ALL PASS.** OA300 acc_4pct=48.8% (≥5% gate, 10× margin); 100% finite softmax outputs (82/82); convert-roundtrip 9.54e-7 (within 1e-3 gate after FP32 fix).
  - **Promotion warning: PASS.** OA300 acc_4pct=48.8% ≥ 25% Codex floor.
  - **Soft targets: 1/3 met empirically.** GiantSteps val acc_4pct ≥ 55%? — final val_acc_4pct converged to 0.818 = 81.8% — PASS by wide margin. OA300 acc_4pct ≥ 40%? — 48.8% PASS. Named-DnB strict_0_5 ≥ 3/4? — 0/4 FAIL.
  - **Advisory HALT (d): FAIL.** Named-DnB strict_0_5 = 0/4 (Charly 152 vs 160; Faraday_Bunker 176 vs 170; Yin Yang 176 vs 170; HEFT_Anagram 180 vs 170). Model gets BPM range right but doesn't pin to ±0.5 BPM. **User-authorized acceptance per DD #11 advisory HALT (d) acknowledgement option (i): "accept reference model with anticipated Story 4-5 HALT (b) failure on these tracks; Story 4-5 dev re-trains or uses consumer-override path at that time."**
  - **AC #12 gating-checklist outcomes:** `make test` (355 tests pass, count unchanged); `make benchmark` (OA300 byte-identical to baseline at Acc1=58/82, Acc2=74/82); `make benchmark-giantsteps` (byte-identical to baseline 2pct=537/661+546/661 + MIREX 4pct=556/661+562/661); `make compile-model` (idempotent — structural equivalence on re-compile is BYTE-identical for FP32 model, stronger than spec required); `swift build` (PASS); `git diff Sources/Tests` (HALT (f) PASS — only Resources/tempo_classifier.mlmodelc/ changed); `tools/coreml-convert/` pytest (3/3 pass).
  - **Total wall-clock breakdown:** Task 1-4 + 7-8 + 11 setup ≈ 90 min (parallel with benchmark-baseline runs); Task 5 training 3.46h (60 epochs in 12460s on M5 Max + MPS); Task 6 eval 33.5s; Task 8.3 structural equivalence 5s; Task 9 gating ≈ 4 min (re-running both corpus benchmarks).
  - **Story 4-5 unblock status:** HALT (a') (real-not-placeholder model) UNBLOCKED. HALT (b) at runtime (named DnB strict_0_5 ≥ 2/4) WILL TRIP (verified 0/4 at training time); Story 4-5 dev addresses via re-train or override path per the option (i) acknowledgement.
  - **Worktree consumer test (AC #13 standalone smoke):** ran post-commit on the produced HEAD; output captured to `_bmad-output/implementation-artifacts/4-4b-standalone-consumer-test.txt`.
  - **Story moves to `review` status.**
