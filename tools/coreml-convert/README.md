# BoomBoomBoomKit · CoreML conversion tool

Standalone PyTorch → CoreML conversion CLI for BoomBoomBoomKit's `MLTechnique` plug-in surface. Self-contained `uv`-managed Python project; ships with the Swift package on `main` so consumers can convert their own tempo models without cloning the dev-only training pipeline.

> **Important context before you use this tool:** BoomBoomBoomKit's default analysis path is DSP-first. The bundled reference model at `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc` is a **smoke-test fixture** — it validates the `MLTechnique` plug-in end-to-end but is measurably less accurate than the DSP pipeline on the project's held-out test corpus. Before bundling an ML model in your app, validate against your own corpus and confirm it improves over DSP on your distribution. See [MODEL_CARD.md](../../MODEL_CARD.md) for measured numbers + known failure modes.

## Licensing (read first)

| Path                          | Licensor          | Consumer obligation                                          |
|-------------------------------|-------------------|--------------------------------------------------------------|
| A. Bundled default            | BoomBoomBoomKit   | None — BBBKit license applies (MIT-compatible)               |
| B. Your custom weights        | You               | Your app's license terms apply to your weights               |
| C. Third-party (e.g., AGPL)   | Upstream author   | May impose AGPL §13 obligations on your app, including the   |
|                               |                   | network-use trigger; consult counsel before distributing     |

> **Disclaimer.** BoomBoomBoomKit makes no representation about third-party model licenses. We ship neither weights nor any rights to use them. The license obligations of your chosen weights belong to your app's distribution.

## When to use this

| Scenario | Path | Tool |
|---|---|---|
| Use the bundled reference model for adapter smoke tests | A — bundled fixture | None (opt-in via `BNNSTechnique`; not a recommended accuracy default — see [MODEL_CARD.md](../../MODEL_CARD.md)) |
| Use your own weights, same architecture | A | This tool, `--arch reference` |
| Use your own architecture (transformer / Deep-Rhythm / etc) | B | This tool, `--arch custom` |
| Use a third-party model with non-permissive license (e.g., AGPL) | C | This tool — but bundle the artifact in YOUR app, not the library |

The "bundled fixture" exists so consumers can verify `BNNSTechnique` loads + predicts end-to-end without needing Python or your own checkpoint. Most production consumers will use Path A (with their own weights) or Path B (with their own architecture).

Detailed worked examples follow.

## Setup

```bash
cd tools/coreml-convert
uv sync --locked
```

Required:
- macOS (Apple Silicon)
- Python 3.11–3.13 (`uv` will install if missing)
- A PyTorch state_dict (`.pt`) for the architecture you want to ship

## Quick reference

```bash
uv run python convert.py \
  --checkpoint path/to/your_model.pt \
  --arch reference \
  --output path/to/your_model.mlpackage \
  --validate

# Custom architecture (you point at your nn.Module class):
uv run python convert.py \
  --checkpoint your_model.pt \
  --arch custom \
  --module path/to/your_model.py:YourModel \
  --input-shape "1,1,128,512" \
  --output your_model.mlpackage
```

## How it works — consumer pipeline

```text
[your PyTorch .pt]
        |
        v
tools/coreml-convert/convert.py
        |
        v
[your_model.mlmodelc]
        |
        v
[bundle in your app's Resources]
        |
        v
Options.mlTechnique = try? BNNSTechnique(modelURL: yourURL)
        |
        v
BPMAnalyzer ---> MLFeatureFrames ---> BNNSTechnique.evaluate(trace:)
                                              |
                                              v
                                       MLEvaluation
                                              |
                                              v
EnsembleCombiner --> AudioAnalysisResult
```

The library's bundled `giantsteps_v1.mlmodelc` is reachable via
`Options.mlTechnique = try? BNNSTechnique()` (no `modelURL`). The
diagram above shows the consumer-override (BYOW) variant; the bundled
path is identical except `convert.py` is skipped.

## Worked examples

### Path A — same architecture, different weights

You trained a tempo classifier with the same `TempoCNN` architecture as the reference (3 conv blocks, 256-bin BPM softmax, NCHW input `(1,1,128,512)`) on your own corpus. Convert and bundle into your app:

```bash
# 1. Convert
cd tools/coreml-convert
uv run python convert.py \
  --checkpoint /path/to/your_model.pt \
  --arch reference \
  --output /path/to/your_model.mlpackage

# 2. Bundle your_model.mlpackage in YOUR app (not BoomBoomBoomKit's bundle)

# 3. At runtime, override the bundled reference:
```

```swift
import BoomBoomBoomKit
import BoomBoomBoomKitML

let yourModelURL = Bundle.main.url(
  forResource: "your_model",
  withExtension: "mlmodelc"  // BNNSTechnique accepts compiled .mlmodelc only
)!

var options = AudioAnalysisService.Options()
options.mlTechnique = try? BNNSTechnique(modelURL: yourModelURL)
// Use plain `try` if you want explicit error handling — BNNSTechnique
// throws MLTechniqueError on .modelResourceMissing(URL),
// .modelLoadFailed(underlying: any Error),
// .invalidTensorContract(missing: String), and
// .binCountMismatch(expected: Int, actual: Int).
```

When `options.mlTechnique = nil` (the default), no ML model is loaded and the pipeline runs DSP-only. To opt in to the bundled reference, construct `BNNSTechnique()` (no arguments) and assign it to `options.mlTechnique`. Your custom-URL override replaces the bundled-reference fallback for the same-arch path.

### Path B — different architecture

You want to use a transformer-based or HCQM-input tempo model (e.g., based on Deep-Rhythm). The architecture is incompatible with the reference, so you implement your own `MLTechnique` conformance:

```bash
# 1. Convert with your own architecture class:
uv run python convert.py \
  --checkpoint your_deeprhythm.pt \
  --arch custom \
  --module path/to/deeprhythm/model.py:DeepRhythmModel \
  --input-shape "1,8,12,512" \
  --output your_deeprhythm.mlpackage

# 1b. If your class takes constructor kwargs, pass them via --module-args:
uv run python convert.py \
  --checkpoint your_deeprhythm.pt \
  --arch custom \
  --module path/to/deeprhythm/model.py:DeepRhythmModel \
  --module-args '{"n_mels": 128, "dropout": 0.1, "use_attention": true}' \
  --input-shape "1,8,12,512" \
  --output your_deeprhythm.mlpackage
```

```swift
// 2. Implement your own MLTechnique conformance:
import BoomBoomBoomKit
import CoreML

// `MLModel` does not conform to `Sendable` in the current SDK
// (Core ML headers note this — the class hierarchy predates Swift
// concurrency). The `MLTechnique` protocol requires `Sendable`, so
// conformers wrapping `MLModel` must use `@unchecked Sendable` with
// a documented rationale (the model's inference path is internally
// thread-safe). This matches BoomBoomBoomKit's own `BNNSTechnique`
// pattern (`public struct BNNSTechnique: MLTechnique, @unchecked Sendable`).
struct MyDeepRhythmTechnique: MLTechnique, @unchecked Sendable {
    let model: MLModel  // or BNNSGraph / MLX runtime / etc.

    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
        // Read what you need from `trace` (mlFeatures, subBandEnergies,
        // BarCandidate ranks, ...) and run your own featurize → infer → score
        // pipeline. The MLTechnique protocol is backend-agnostic
        // (Core ML, BNNSGraph, MLX, MPS Graph — all valid).
        guard let features = featurize(from: trace) else { return nil }
        // Distinguish "no model output" (recoverable abstain → nil) from
        // "Core ML threw" (model-shape or runtime bug → log and abstain).
        // The earlier `try? model.prediction(from:)` swallowed every error
        // class silently, including bugs in your featurize step. Logging
        // the underlying error makes those bugs visible in diagnostics.
        let prediction: MLFeatureProvider
        do {
            prediction = try model.prediction(from: features)
        } catch {
            os_log(.error, "MyDeepRhythmTechnique prediction failed: %{public}@",
                   String(describing: error))
            return nil  // abstain — DSP candidates remain authoritative
        }
        return MLEvaluation(bpm: yourBPM(prediction), confidence: yourConfidence(prediction))
    }
}

var options = AudioAnalysisService.Options()
options.mlTechnique = MyDeepRhythmTechnique(model: try MLModel(contentsOf: yourModelURL))
```

License compliance for your weights is your responsibility — BoomBoomBoomKit ships only the protocol + bundled reference; your weights live in your app's bundle under your app's license terms.

### Path C — third-party model with non-permissive license (e.g., AGPL)

You want to use `bleugreen/deeprhythm` (AGPL-3.0). The convert tool can produce a `.mlpackage` from their checkpoint; runtime wiring goes through Path B (custom `MLTechnique` conformance) due to architecture incompatibility.

**Your app, your license obligations.** AGPL §13 may impose obligations including a network-use trigger and source-disclosure requirements depending on linkage and distribution model. **Consult your own legal counsel before bundling AGPL weights into your app.** BoomBoomBoomKit makes no representation about AGPL or any other upstream-weight license; we ship neither the weights nor any rights to use them. The license obligations of your chosen weights belong to your app's distribution.

```bash
# Clone upstream, train or fetch their weights, then convert:
uv run python convert.py \
  --checkpoint deeprhythm.pt \
  --arch custom \
  --module deeprhythm/model.py:DeepRhythm \
  --input-shape "1,8,12,512" \
  --output deeprhythm.mlpackage
```

Wire via Path B's custom `MLTechnique` conformance.

### Path D — runtime wiring summary

The override surface is `Options.mlTechnique`:

- `Options.mlTechnique = nil` (default) → DSP-only; no ML model is loaded.
- `Options.mlTechnique = try? BNNSTechnique()` → opt in to the bundled reference.
- `Options.mlTechnique = try? BNNSTechnique(modelURL: ...)` → same-arch override.
- `Options.mlTechnique = MyCustomTechnique()` → custom-arch override.

There are no convenience APIs (`useMLModel(at:)` / `setMLTechnique(_:)`) — `Options.mlTechnique` is the sole surface.

## CLI reference

```text
uv run python convert.py \
  --checkpoint <path.pt>              REQUIRED. PyTorch state_dict.
  --arch <reference|custom>           Default: reference. Use custom for non-reference architectures.
  --module <path/to/model.py:ClassName>  Required when --arch=custom.
  --input-shape "N,C,H,W"             Default: "1,1,128,512" (matches reference).
  --output <path.mlpackage|.mlmodel|.mlmodelc>  REQUIRED. Output destination.
  --target macOS14|macOS15|iOS17|iOS18 Default: macOS15 (matches BoomBoomBoomKit's .macOS(.v15) package target and the bundled reference's metadata.json availability).
  --validate / --no-validate          Default: --validate. --no-validate emits a stderr warning.
  --module-args '{"key": value}'      JSON object of constructor kwargs for --arch custom (ignored when --arch=reference).
  --atol <float>                      Default: 1e-3. Tolerance for eager-vs-traced + roundtrip.
```

Output extensions:
- `.mlpackage` — coremltools native MLProgram bundle (recommended for new code).
- `.mlmodel` — Core ML model bundle (a directory tree under this name; `xcrun coremlc compile` accepts it as input).
- `.mlmodelc` — pre-compiled. The tool runs `xcrun coremlc compile` and emits the compiled tree. Requires Xcode 15+.

Compute units always `CPU_ONLY` because BNNSGraph reads MIL + weights directly and ignores the runtime hint.

## Validation

`--validate` (default) runs four checks across the conversion pipeline:

1. **Eager-vs-traced equivalence** (corenet pattern, before `ct.convert`) — `torch.jit.trace` output must match eager mode within `--atol` (1e-3 default). Catches silent trace divergence.
2. **Tensor names** (on the source `.mlpackage`) — input must be named `"input"`, output named `"output"` for the runtime tensor-name contract.
3. **Roundtrip equivalence** (on the source `.mlpackage`) — PyTorch eager output vs CoreML predict output on a deterministic test input, within `--atol`. Catches silent conversion drift. Run on the `.mlpackage` because coremltools loads `.mlpackage` natively but cannot directly load `.mlmodelc`.
4. **Structural sanity** (on the compiled `.mlmodelc`, only when `--output` ends in `.mlmodelc`) — the compiled bundle must contain `metadata.json`, `model.mil`, `coremldata.bin`, and `weights/weight.bin`, all non-empty. Catches `xcrun coremlc compile` corruption that the .mlpackage-based checks above cannot see.

A failure on any check exits with code 1. The failed artifact + `convert_report.json` are written to a stable `<output_stem>.failed<ext>` sibling so you can inspect what went wrong (the report records exactly which check failed and the measured deviation), and **the consumer's prior good artifact at `--output` is preserved untouched**. So if `--output your_model.mlmodelc` fails validation, the failed copy lands at `your_model.failed.mlmodelc` and your existing `your_model.mlmodelc` (if any) is intact. **Do not ship a failed artifact**; either fix the underlying issue (broken trace, tensor-name renaming, FP16 precision drift, etc.) and re-run, or run with `--no-validate` once you understand the failure and have decided to accept it. The stderr warning printed by `--no-validate` explicitly recommends against shipping unvalidated outputs to consumers.

### `convert_report.json` shape

Two valid shapes depending on `--validate`:

**With `--validate` (default):** the `validation` block carries every per-check result:
```json
"validation": {
  "skipped": false,
  "atol": 0.001,
  "eager_vs_traced_max_abs": 1.2e-7,
  "eager_vs_traced_passed": true,
  "tensor_names_passed": true,
  "tensor_names_input": ["input"],
  "tensor_names_output": ["output"],
  "roundtrip_max_abs": 9.5e-7,
  "roundtrip_passed": true,
  "structural_passed": true,
  "structural_missing": []
}
```

**With `--no-validate`:** per-check result keys are **omitted entirely** (not nulled):
```json
"validation": {
  "skipped": true,
  "atol": 0.001
}
```

This shape lets schema-style consumers treat the result keys as required-when-not-skipped without `null`-aware boolean checks.

### Output writes are crash-recoverable, not atomic

Conversion stages all intermediate artifacts in a sibling staging directory (`.coreml-convert.<stem>.<pid>.staging/`) next to your `--output` path. The final promotion uses `os.rename` and never copies across filesystems. If the existing `--output` already has a good artifact and conversion / validation / compile fails, the staging dir is cleaned up and your existing artifact is preserved.

**Crash-recoverable, not atomic.** Python cannot atomically replace a non-empty directory bundle on macOS. The promotion sequence is `rename(existing, .old.<pid>) → rename(staging, final) → rmtree(.old)`; if the second rename fails, the helper restores `.old` back to `final`. There is a brief crash window between the two renames during which only the `.old.<pid>` sibling exists — restart can detect this manually and recover. For idempotent shipping pipelines, accept this window as the cost of preserving the consumer's prior good artifact.

## Non-goals

This tool does NOT:

- Train models. Use your own training pipeline; this tool only converts an already-trained PyTorch checkpoint into Core ML.
- Fine-tune existing checkpoints.
- Compress / palettize / quantize. If you need that, run `coremltools.optimize.*` upstream of this step.

## Tests

```bash
cd tools/coreml-convert
uv run pytest tests/
```

The pytest suite synthesizes a state_dict for the reference architecture, round-trips through convert.py, validates the output. NOT integrated with Swift `make test` — the convert tool is isolated from the Swift package.
