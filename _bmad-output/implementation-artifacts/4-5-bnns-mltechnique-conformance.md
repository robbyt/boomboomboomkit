# Story 4.5: BNNS MLTechnique Conformance (Proof of Concept)

Story ID: 4.5
Story Key: 4-5-bnns-mltechnique-conformance
Epic: 4 — ML-Augmented Detection
Status: ready-for-dev

## Story

As a library author,
I want a BNNSGraph-based `MLTechnique` conformance reading the same `.mlmodelc` artifact that Story 4.6 will consume, with the model input derived from a typed log-mel feature trace field that survives clipped/limited DnB material,
So that the ML integration architecture is validated end-to-end on the four named DnB triplet failures with zero new framework dependencies (BNNS lives inside `Accelerate`), and Story 4.6 inherits a symmetric load path, an explicit NCHW tensor layout, and the same per-track impact-report shape.

## Key Design Decisions

The 17 design decisions below were authored at story-creation time (2026-05-08) against HEAD `757d57c` and revised on 2026-05-08 after a 4-layer pre-implementation review (Codex initial pass, axiom-ai, axiom-concurrency, axiom-apple-docs) plus Codex meta-synthesis and a `/bmad-party-mode` roundtable (Winston, Amelia, Mary, Siri). The Project Lead reviews this block BEFORE the dev agent begins Task 1. **DDs #2, #7, #15, #16, #17 are the most consequential decisions** — they lock the trace-shape, BNNSGraph C-API surface, struct-with-RAII-storage lifecycle, argument-by-name lookup, and multi-window feature ownership that Story 4.6 (CoreML) inherits.

1. **Pre-promotion gate is satisfied; the named-track baseline is FROZEN.** `_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json` (`schema_version: 2`) is committed at SHA `9185698` (verified by `git log --diff-filter=A -- _bmad-output/implementation-artifacts/4-dnb-triplet-targets.json`). All 4 named tracks resolve to existing files in `OA300_CORPUS_PATH`; all 4 entries have non-null `source` (2× `dawproject`, 2× `daw_oracle`); `current_predicted_bpm` is populated for each (Charly: 106.246; Faraday_Bunker: 113.471; Yin Yang: 113.240; HEFT_Anagram 6: 113.366) with absolute errors of 53–57 BPM (the canonical half-tempo failure mode). **Per the epic AC (`epics.md:1039`), these `current_predicted_bpm` values are NOT re-frozen at Story 4.5 PR time** — they are the named-track baseline against which the T2 non-regression assertion compares. Re-running would risk per-track drift via NTP-style benchmark wall-clock noise even though per-track BPM is deterministic. Story 4.5 reads the artifact, asserts each `track_id` resolves to a corpus file, and asserts the 4 absolute errors against this frozen baseline (NOT against a fresh Task-1 measurement).

2. **The `BPMDiagnosticTrace` does NOT carry per-frame log-mel features today; Story 4.5 adds a typed-evidence trace field WITH SEMANTIC METADATA to surface them to `MLTechnique.evaluate(trace:)`.** Per Story 4.3 protocol shape (`MLTechnique.evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?`), the conformance receives ONLY the trace — no raw audio, no per-window samples. The current trace exposes `onsetEnvelopeLength: Int`, `subBandEnergies: SubBandEnergies` (4 max-pooled values), and downstream BPM candidates — none of which are sufficient input for a tempo CNN. Schreiber & Muller (2018) requires a log-mel-spectrogram time-series as input. **Story 4.5 introduces a new typed-evidence struct** (`MLFeatureFrames: Sendable, CustomStringConvertible, Equatable`) following the project-context.md "Banned trace-field shapes" pattern: row-major `[Float]` payload + shape metadata + **semantic metadata** (Codex MAJOR #4 — without it, the trace cannot prove what the tensor means and Story 4.6 inherits ambiguity):

    ```swift
    public struct MLFeatureFrames: Sendable, CustomStringConvertible, Equatable {
      public let melBands: Int           // == 128 for the Story 4.5 model
      public let frames: Int             // pre-resample source frame count
      public let tensorLayout: TensorLayout  // .nchw only initially
      public let logMelData: [Float]     // row-major; precondition: count == melBands * frames
      public let sampleRate: Double      // 44100 / 48000 / 96000 (DSP source rate)
      public let fftSize: Int            // 2048 (BPMAnalyzer constant)
      public let hopSize: Int            // pipeline hop in samples
      public let melFmin: Double         // 30 Hz (BPMAnalyzer.melFmin)
      public let melFmax: Double         // min(sampleRate/2, 16000)
      public let logCompressionScale: Float  // 100.0 (BPMAnalyzer.logCompressionScale)
      public let featureSetVersion: String   // "v1" — bumps when pre-vvlogf pipeline changes
    }
    ```

    The field is `BPMDiagnosticTrace.mlFeatures: MLFeatureFrames?` and is populated by `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` ONLY when `Options.captureMLFeatures == true` (new internal Options flag, NOT public — see DD #4). Initializer preconditions enforce `logMelData.count == melBands * frames` and positive dimensions. Z-score normalization across the time axis happens INSIDE `BNNSTechnique.evaluate(trace:)` from the raw log-mel matrix, NOT in `BPMAnalyzer` (keeps the DSP pipeline ML-agnostic; if a future ML technique wants different normalization, it owns the choice). **`featureSetVersion` is the load-bearing field for Story 4.7 inheritance**: any change to the pre-`vvlogf` mel pipeline MUST bump the version (Mary's "name the seam, name the trigger" discipline).

3. **Log compression is ALREADY applied in `computeMelOnsetEnvelopeWithSubBands` (verified at story-authoring time per `epics.md:1009` instruction).** Lines 578-583 of `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` apply `vDSP_vsmul` (×100 scale) + `vDSP_vsadd` (+1.0 floor for `log(0)`) + `vvlogf` to per-frame mel energies before they enter the temporal-difference + HWR + aggregation downstream. The intermediate `logMelFrames: [[Float]]` is currently discarded after temporal differencing. **Story 4.5 retains those frames into the new `mlFeatures` trace field when the capture flag is on, BEFORE `vDSP_vsub` consumes them**. This means: (a) NO new log step is added (the AC paired byte-equality opt-out test in `epics.md:1009` is satisfied vacuously — the existing log step already shipped pre-Story-4.5); (b) the spectrogram fed to BNNS is bit-for-bit identical to the spectrogram fed to the onset envelope downstream.

4. **`Options.captureMLFeatures` is INTERNAL — not on the public `AudioAnalysisService.Options`.** ADR-11 governs public configuration; this flag does not extend the public surface because it is not a consumer-facing knob. The flag lives on `BPMAnalyzer.Options` (internal) and is set by `AudioAnalysisService.runPreCorroborationPipeline` based on `shouldBuildTrace` AND `options.mlTechnique != nil` AND `options.ensemblePolicy != .dspOnly` (mirrors the existing `shouldBuildTrace` predicate at `AudioAnalysisService.swift:289-291`). When the flag is false, the spectrogram intermediate stays purely transient — zero-cost on the DSP-only path. Verifying this is the regression-protection contract for AC #5: per-track BPM byte-identity vs the post-Story-4.4 snapshot when `mlTechnique == nil`.

5. **`init()` becomes `init() throws`; missing-resource path returns nil via `try?`.** Per ADR-4 ("Eager model loading at conformance init"), and per Story 4.1's pre-1.0 / no-BC notice in `BNNSTechnique.swift` ("Story 4.5 will change `init()` to `init() throws` when adding model load"). The init throws when EITHER (a) `Bundle.module.url(forResource: <name>, withExtension: "mlmodelc")` returns nil, OR (b) `BNNSGraphCompileFromFile` fails. `try? BNNSTechnique()` returns nil on either path; consumers who want diagnostics use `try BNNSTechnique()` and inspect the thrown error. **Pre-1.0 / no-BC framing**: this is a documented breaking signature change to a struct that shipped in Story 4.1 — explicitly authorized by the Story 4.1 doc-comment.

6. **Model file name = `giantsteps_v1.mlmodelc`** (NOT the `epics.md:996` placeholder `"model"`). Story 4.1 settled this convention via the Makefile defaults `ML_MODEL_INPUT ?= _bmad-output/ml-models/giantsteps_v1.mlmodel` and `ML_MODEL_OUT_DIR ?= Sources/BoomBoomBoomKitML/Resources` (`Story 4.1 spec lines 24-31, 107`). Story 4.5 reads `Bundle.module.url(forResource: "giantsteps_v1", withExtension: "mlmodelc")` to honor the Story 4.1 convention. The `epics.md:996` `"model"` literal was illustrative; this DD reconciles it with Story 4.1's settled name. Story 4.6 inherits the same name (one model artifact per Epic 4, symmetric load).

7. **BNNSGraph API surface is the RAW C API only on macOS 15** — `BNNSGraphCompileFromFile` + `BNNSGraphContextMake` + `BNNSGraphContextExecute` + `BNNSGraphContextDestroy`. **The Swift overlay (`BNNSGraph.Context`, `BNNSGraph.Builder`, `BNNSGraph.makeContext`) is locked out by project floor.** SDK evidence (`Accelerate.swiftmodule/arm64e-apple-macos.swiftinterface:3336-3372, 14705-14716`, verified 2026-05-08): `BNNSGraph.Context` exists on macOS 15+ but its synchronous initializer (`Context(contentsOf:)`), `BNNSGraph.Builder`, and `BNNSGraph.makeContext` are all `@available(macOS 26.0, ...)`. The macOS 15 SDK only exposes `BNNSGraph.Context.init(compileFromPath:options:) async throws` — async-only. Story 4.5's `init() throws` is sync per ADR-4, so the Swift overlay is unreachable until macOS 26. Apple's classic `BNNS.*Layer` / `BNNSFilterCreateLayer*` API is in the deprecated `classic-bnns-api` collection (verified via apple-docs MCP, cited in `epics.md:1001-1003`); a `grep -rn "BNNSFilterCreate" Sources/BoomBoomBoomKitML/` guard at PR time asserts zero matches. Inference flows through the C path: compile-once `bnns_graph_t` cached in private storage; per-call `bnns_graph_context_t` created via `BNNSGraphContextMake` and destroyed in `defer` (DD #15 — Shape A-prime). Argument lookup by NAME via `BNNSGraphGetArgumentPosition(graph, nil, "<name>")` (DD #16); arguments are `[bnns_graph_argument_t]` with `argument.tensor = pointer` (NOT `BNNSNDArrayDescriptor` — that's the classic descriptor, wrong path for graph execution per axiom-apple-docs MAJOR #4). **BNNSGraph executes on CPU only** (WWDC 2024 #10211 framing — see Apple-platform notes). ANE inference is reserved for Story 4.6 via CoreML.

8. **Tensor layout is NCHW row-major; declared explicitly in code AND Completion Notes.** Per `epics.md:1010` ("the model input tensor shape and stride layout are declared explicitly in code AND documented in Completion Notes"). The exact shape: `N=1` (batch), `C=1` (channel — log-mel is single-channel), `H=mel_bands` (default 128, defined as `BPMAnalyzer.melBands` private constant — Story 4.5 surfaces this as `BNNSTechnique.expectedMelBands: Int = 128`), `W=512` after temporal resampling (DD #9). Stride is contiguous row-major: `stride = [H*W, H*W, W, 1]` for `N`, `C`, `H`, `W` respectively. **Story 4.6 inherits this exact SHAPE ordering** (NCHW) for `MLShapedArray<Float>` construction. **Stride caveat (axiom-apple-docs MINOR #7)**: `MLShapedArray` does NOT allow setting non-contiguous strides at init — it manages contiguous strides internally. Story 4.6 constructs `MLShapedArray<Float>(shape: [1, 1, 128, 512])` and lets the type collapse strides; do NOT thread Story 4.5's explicit stride array through to CoreML.

9. **Variable-frame-count input handling — temporal RESAMPLING (not pooling) to fixed W=512 via `vDSP.linearInterpolate(elementsOf:using:result:)` per mel band.** "Pooling" was wrong terminology (Codex MAJOR #7) — `vDSP_vlint` and its Swift overlay perform fractional-index linear interpolation, which is resampling. Story 4.5 chooses **per-mel-band resampling** to a fixed W=512 frames (~5.12s window at 100 Hz onset rate) BEFORE feeding to the graph. Rationale: (a) BNNSGraph compile-time shape is fixed (dynamic-shape compilation deferred — see notes below); (b) Schreiber & Muller's tempo CNN was trained on fixed-length inputs; (c) `vDSP.linearInterpolate(elementsOf:using:result:)` is the canonical Swift overlay (NOT `values:atIndices:result:` — that's the sparse-known-values path; NOT `vImageScale_PlanarF` — image abstraction wrong-fits "resize 128×N to 128×512 along time only"). Available macOS 10.15+ per Siri; wraps `vDSP_vlint`. Implementation: 128 row-loops, precomputed 512-element control vector reused across all bands. Reject `sourceFrames < 32` BEFORE resize (degenerate input — return nil from `evaluate(trace:)`). The resample happens in `BNNSTechnique.featurize(_:)` (private helper), AFTER z-score normalization (DD #2). **Confidence-rule gap (cross-review insight d, Mary's re-open trigger):** upsampling a short clip (sourceFrames < 512, pool factor < 1.0) is materially different from downsampling a long one. Story 4.5 ships with a single 0.50 abstain threshold (DD #10); Mary's deferred-work entry: re-open as MUST-FIX if any post-4.5 corpus run shows >2% Acc1 regression on clips < 8 seconds. **Dynamic-shape compilation is documented as a Story 4.6+ deferred-work item** (`BNNSGraphContextSetDynamicShapes` per WWDC 2024 #10211): if the trained model author re-exports with `ct.RangeDim` on the time axis, the resample step can be eliminated; not blocking 4.5 because the `tempo-cnn` reference repo ships fixed 512-frame inputs.

10. **Confidence threshold for ML-abstain — `0.50` default constant; sidecar JSON override is OPTIONAL deferred-work, NOT a Story 4.5 must-ship.** axiom-ai recommended a `tempo_classifier.metadata.json` sidecar; Siri verified this is NOT Apple-canonical for BNNSGraph (Apple's pattern is `MLModel.modelDescription.metadata[.creatorDefinedKey]` — embedded in the compiled `.mlmodelc`, but `BNNSGraphCompileFromFile` strips metadata). Decision: **Story 4.5 ships with a hard-coded `private static let confidenceThreshold: Double = 0.50` constant** (matches the `epics.md:1085` Schreiber & Muller architecture default); a sidecar load path is DEFERRED to a follow-up story if calibration evidence demands. Per the protocol DocC at `Sources/BoomBoomBoomKit/DSPTechnique.swift:248-252` ("Conformers SHOULD return `nil` (rather than a low-confidence value) whenever the input falls outside the model's training distribution"). The 0.50 floor is empirical: tempo CNNs typically produce softmax peaks ≥ 0.80 on confident predictions; values below 0.50 indicate the model is hedging. **`MLEvaluation` is constructed only when softmax max ≥ 0.50**; otherwise `nil` is returned. The bpm is the `argmax` of the softmax distribution mapped through the BPM-bin centers; confidence is the softmax max value (clamped to `[0.0, 1.0]` defensively even though softmax outputs are inherently in-range — defense-in-depth per Story 4-4 DD #4 sanitization precedent). **Story 4.6 inheritance**: CoreML reads `MLModel.modelDescription.metadata[.creatorDefinedKey]["confidence_threshold"]` first; falls back to the same `0.50` default if absent (canonical Apple pattern; this is the "Free to redesign" item from Mary's stakeholder analysis).

11. **Cancellation cooperation across `MLTechnique.evaluate` boundary — fix the deferred-work entry via a private throws helper, NOT an IIFE.** Per the deferred-work entry "Story 4.5/4.6 — Cancellation cooperation across `MLTechnique.evaluate` boundary" (filed at Story 4.3 close-out, `_bmad-output/implementation-artifacts/deferred-work.md:244`). Codex MAJOR #8 / Amelia rejected the IIFE-with-cancellation pattern (control-flow smell: IIFE returns `MLEvaluation?` and can't throw cleanly). **Resolution**: extract a small `private static func evaluateMLIfActive(options:trace:) throws -> MLEvaluation?` helper in `extension AudioAnalysisService` (private static, same file, placed below `degradationMessage` near `AudioAnalysisService.swift:358`). The helper does the policy/mlTechnique/trace guards, then `if options.isCancelled() { throw CancellationError() }`, then `ml.evaluate(trace:)`. The call site at `AudioAnalysisService.swift:311-317` becomes a single `let mlEvaluation = try evaluateMLIfActive(options: options, trace: corroborated.trace)` line. `analyzeBPM` already `throws`, so no signature churn. AC #14 invariant (`RecordingMockMLTechnique.callCount == 0` on `.dspOnly`) preserved. Inside `evaluate(trace:)`, BNNSGraph inference is atomic from the consumer's perspective (no internal cancellation hooks); the conformance does NOT thread a cancellation closure into the graph context. Pre-evaluate check is sufficient for ADR-1 per-window cancellation granularity. Optional defense-in-depth (NOT required): an in-`evaluate` `Task.isCancelled` check returning nil between `featurize` and `inferTempoCNN` (returns nil because the protocol is non-throwing).

12. **HALT triggers (named, story-prefixed per codex Item 11; reframed for BYOW pivot per codex Item 10-MOD).** Story 4-5's HALTs are renamed `4-5-HALT-<letter>` to disambiguate from Story 4-4b's HALTs (4-4b uses `4-4b-HALT-<letter>`; cross-story references use the prefixed form). **Pivot reconciliation:** with Story 4-4b's bring-your-own-weights pattern, the bundled reference `.mlmodelc` may legitimately ship with Project-Lead-acknowledged DnB advisory miss (per 4-4b DD #11 advisory framing). 4-5's HALT (b) was originally a hard gate on DnB ≥ 2/4 — that's now incoherent with 4-4b's advisory model. Reframed below.

    - **4-5-HALT-(a) — Pre-promotion gate fails.** Already verified at story-authoring time (DD #1). If at Task 1 the artifact has been mutated (e.g., file moved, schema changed), HALT and re-run `make oracle-generate` per `epics.md:1038` BEFORE the first source edit.
    - **4-5-HALT-(a') — Bundled reference model artifact unavailable at Task 1.5 (revised for BYOW pivot).** Story 4-5 SHIPS with a bundled reference `.mlmodelc` produced by Story 4-4b. If 4-4b has shipped per its sanity HALTs (DD #11: non-NaN outputs, ≥5% acc_4pct, convert-roundtrip equivalence), the artifact is acquired and Task 2 proceeds. If 4-4b has NOT shipped (story still in-progress), the dev HALTs at Task 1.5 and surfaces to PM. **Story 4.5 still requires a real bundled model** — random weights and placeholder-only paths remain rejected. Consumer-override-only mode (Branch C below) is NOT a substitute for shipping the bundled reference; it's a quality fallback when the bundled reference is mediocre.
    - **4-5-HALT-(b) — BNNS resolves <2 of 4 named DnB triplets at runtime.** Per `epics.md:1053-1056` (Epic 4 retro action item T2). Reframing post-pivot: this gate WAS the only honest path to Branch C. With 4-4b's advisory framing, 4-4b may legitimately ship a bundled reference that fails this gate (Project Lead acknowledged the mediocre quality). 4-5 then has two paths:
        - **Branch A (bundled reference passes):** ship default-on; 4.6 inherits cleanly. No further action.
        - **Branch C (bundled reference fails) — reframed for BYOW.** 4.5 STILL ships the BNNSTechnique conformance + override API, BUT the default `Options.mlTechnique` stays `nil` (DSP-only). Story 4.6 enters Branch C: moved BACK TO `backlog` in `sprint-status.yaml` with `gated_on: research-spike-4.5b`. The library's runtime is correct; only the bundled-default activation is deferred. **Consumers wanting ML augmentation explicitly opt in via `Options.mlTechnique = try? BNNSTechnique()` AND should be aware of the documented quality caveat in DocC.** This is the BYOW honest fallback — the conformance and override API ship; quality demonstration defers.
    - **4-5-HALT-(c) — Asserted floors regress.** Per `epics.md:1048` — OA300 Acc1 ≥ 57/82, Acc2 ≥ 73/82; GiantSteps Acc1 ≥ 537/661, Acc2 ≥ 546/661. ANY corpus floor breach at default config (`Options.mlTechnique == nil` per BYOW default) HALTs.
    - **4-5-HALT-(d) — BNNS-on path regresses Acc1 below 58/82 at default intensity, when consumers explicitly opt in.** Per `epics.md:1049` ("the BNNS-on path may not be worse than DSP-only at the default config it ships under"). Note: post-pivot, BNNS-on is NO LONGER the default config — `Options.mlTechnique = nil` is. This HALT applies to the impact-report run (`make bnns-impact-report`) which DOES set `Options.mlTechnique = try? BNNSTechnique()`. The intent is preserved (when ML is on, it shouldn't be worse than DSP-only) but the gating context is the impact-report config, not the default ship config.
    - **4-5-HALT-(e) — Per-track BPM byte-identity fails on DSP-only path.** When `Options.mlTechnique == nil` (default — unchanged by pivot), per-track BPM JSON output MUST be byte-identical to `_bmad-output/implementation-artifacts/4-5-regression-snapshot.json` (the post-Story-4.4 / pre-Story-4.5 snapshot). The `captureMLFeatures` flag (DD #4) ensures this. If any track diverges with `mlTechnique == nil`, the flag is leaking through; HALT and trace the divergence.
    - **4-5-HALT-(f) — Model resource missing in CI.** When the real `.mlmodelc` is absent (CI default — the artifact is large and not committed), `make test` MUST pass with `try? BNNSTechnique()` returning nil per DD #22 graceful degradation. If `make test` fails because a unit test required the real model, the test is mis-structured; HALT and move that assertion to `BoomBoomBoomKitBenchmarkTests` under `BNNS_IMPACT=1`.
    - **4-5-HALT-(g) — `evaluate(trace:)` is called when `trace.mlFeatures == nil`.** Indicates the `captureMLFeatures` flag is not propagating correctly; the conformance MUST defensively return nil with a one-time logged diagnostic AND the issue must be traced + fixed before merge (NOT silently absorbed).
    - **4-5-HALT-(h) — Element-wise byte-identity test fails (Codex MAJOR #5 / patch P7).** A new test (Task 8.x) captures `logOutput` immediately post-`vvlogf` and asserts `MLFeatureFrames.logMelData` is element-identical to the flattened retained log-mel frames when `captureMLFeatures == true`. If the retention path mutates intermediate state, this fires — HALT and trace the mutation.
    - **4-5-HALT-(i) NEW per DD #20 (codex Item 5):** `BNNSTechnique.init` does NOT raise `MLTechniqueError.invalidTensorContract` when handed an artifact whose tensor names mismatch. The runtime invariant from DD #20 must fire on contract violation; if the test for it passes silently on a mismatched-name fixture, the validateContract step is broken — HALT and fix.

13. **Test count band. Pre-story baseline = 357** (`rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l` at HEAD `757d57c` — verified by Amelia 2026-05-08; the earlier "355" figure was stale from Story 4-4 close-out). Net additions per Amelia's line-by-line recalc:
    - +4 `MLFeatureFramesTests` init preconditions (count == melBands*frames, melBands>0, frames>0, layout==.nchw)
    - +1 element-wise byte-identity test (Codex P7 / HALT (h))
    - +1 multi-window ownership invariant (single ML eval per `analyzeBPM` call — DD #17)
    - +2 impact-report config gates (`.thorough/.mlOnly` pinned vs default-config inertness — Codex P9)
    - +1 `BNNSGraphGetArgumentPosition` lookup-by-name test (DD #16)
    - +1 compile-time `assertMLTechnique<T:MLTechnique>(_: T.Type) {}` witness (Codex P13 — pure type-check, no runtime init)
    - +1 concurrency exposure `withTaskGroup` test running 16 concurrent calls (axiom-concurrency #5; gated on real-model presence with `Issue.record` skip)
    - +2 RAII storage tests (deinit fires + calls `free`; struct-copy doesn't double-free — Winston's project-context.md C-interop discipline applied per-story)
    - +1 per-call lifecycle test (`BNNSGraphContextDestroy` invoked even on throw path)
    - +1 raw-API guard grep test (asserts zero `BNNSFilterCreate*` / `BNNSFilterApply*` matches in `Sources/BoomBoomBoomKitML/`)
    - +1 `@available(macOS 15.0, *)` compile gate (Siri's defense-in-depth recommendation)

    Sum: +15. New target = 357 + 15 = **372**. Band: **[370, 378]** (±3 drift; review patches per Story 4.4 precedent). Outside the band → investigate test drift before merging.

14. **Pre-1.0 / no-BC posture, restated.** Story 4.5 lands two new public types (`MLFeatureFrames` with semantic metadata per DD #2, `TensorLayout` enum) and one new public mutable trace field (`BPMDiagnosticTrace.mlFeatures`). Pre-1.0 framing per project-context.md "Public API Discipline (pre-1.0)": breaking changes to these types are explicitly allowed and expected as Story 4.6 surfaces concrete needs. **Specifically allowed downstream work that breaks 4.5's surface:** (a) renaming `MLFeatureFrames` if Story 4.6 finds a better aggregate; (b) renaming `BNNSTechnique` from `struct` → `struct + private final class Storage` shape (Story 4.1 placeholder was `struct`, Story 4.5 keeps `struct` public surface but adds private `BNNSGraphHandle` class for RAII per DD #15 — the public type stays `struct`); (c) adding fields to `MLFeatureFrames` beyond the semantic metadata DD #2 enumerates; (d) extending `TensorLayout` with new cases. The story does NOT promise the case list, default, or struct field names are 1.0-stable. **Sequencing note (deviation from Epic 4 spec):** Epic 4 recommended Story 4.7 (spectral-flux DSP variant) BEFORE Story 4.5 so BNNS feature design knows the post-spectral-flux baseline (`epics.md:1092`). User is promoting 4.5 first per project-lead discretion. Consequence: BNNS feature design uses the current energy-based onset envelope; if 4.7 lands later and changes the spectrogram pre-image, `MLFeatureFrames.featureSetVersion` MUST bump (Mary's "name the seam, name the trigger" — DD #2 makes this explicit).

15. **`BNNSTechnique` lifecycle is Shape A-prime: public `struct` + private `final class BNNSGraphHandle` for RAII.** Codex meta-synthesis surfaced the cross-review insight nobody single-review caught: **the real lifecycle bug is graph leakage** (`graph.data` from `BNNSGraphCompileFromFile` is allocated and `BNNSGraphContextDestroy` does NOT free it), not context leakage. The original Shape A (struct + per-call context) leaked the cached graph because Swift `struct` lacks `deinit`. The original Shape B (`final class` + lock) killed concurrent fan-out parallelism through one BNNS context (single-thread-at-a-time per Apple docs). **Resolution — Shape A-prime:**
    - **Public `struct BNNSTechnique: MLTechnique`** — preserves project-wide value-type posture (CLAUDE.md "stateless structs/enums"), parallels other public types
    - **Private `final class BNNSGraphHandle: @unchecked Sendable`** owning the immutable `bnns_graph_t`; `BNNSGraphHandle.deinit { free(graph.data) }` releases the malloc'd graph payload (the `giantsteps_v1.mlmodelc` is loaded from filesystem, not mmap-backed, so `free` is the right release primitive). The struct holds a `private let handle: BNNSGraphHandle` reference; struct-copy preserves graph (same handle), no double-free
    - **Per-call `bnns_graph_context_t`** constructed via `BNNSGraphContextMake(handle.graph)` at top of `evaluate(trace:)` and destroyed via `defer { BNNSGraphContextDestroy(&context) }`. Cost: tens of µs vs multi-ms inference (~0.1% overhead — verified via perf gate at Task 10.7); eliminates concurrent-context data race without locks; preserves intensity 8-10 fan-out parallelism
    - **`@unchecked Sendable` on the struct** with documented rationale ("graph immutable post-compile; per-call contexts isolated; no shared mutable state"). Per axiom-concurrency #3: `nonisolated(unsafe)` is wrong here — that attribute is reserved for sync-only callbacks (`PCMBufferReader.downsample`), test closures, and `FileMetadataReader` scratch buffers; caching a graph handle in a `Sendable` struct is none of those.

    **Naming**: Winston preferred `BNNSGraphHandle` over `Storage` ("Storage suggests state; we have a handle to a C resource"). Adopted.

    **Project-wide implication (Winston's elevation)**: this story establishes the C-interop discipline pattern that future C-resource-owning types should follow — `final class` with `deinit` exercised by ≥1 test that drops the last reference. Captured as a project-context.md rule update at story close-out.

16. **BNNSGraph argument lookup by name, not by hard-coded position.** axiom-apple-docs P12 + Apple's documented `BNNSGraphContextExecute` example use `BNNSGraphGetArgumentPosition(graph, nil, "<name>")` to resolve argument indices at init time. Hard-coded ordering (e.g. assuming input is index 0, output is index 1) creates silent breakage if the model is re-converted with different argument names. **Story 4.5 queries argument positions and tensor metadata from the compiled graph by name AT INIT TIME** (input name: `"input"` for spec-default, fall back to whatever the trained model declares; output name: `"output"`). Cached `srcIndex: Int` and `dstIndex: Int` private properties. The Story 4.5 dev MUST verify the actual argument names embedded in the `giantsteps_v1.mlmodelc` artifact at Task 1.5 (model availability check) and document them in the AC #2 init shape. If the model's argument names differ, update the constants — do NOT hard-code positions.

17. **Multi-window feature ownership: SINGLE ML evaluation on the merged-winner trace** (Winston roundtable verdict + Codex MAJOR #6 / P8). `computeMelOnsetEnvelopeWithSubBands` runs per analysis window; `CandidateMergeStrategy.merge` aggregates `[BPMResult]` to a single `BPMResult`; the merged result's `trace` is from one of the windows (the convention per `BPMDiagnosticTrace` ownership). Story 4.5 ML evaluation runs ONCE on the merged-winner trace's `mlFeatures`. **NOT option (b)** (`[MLWindowFeatureFrames]` per-window with ML aggregation) — that's a richer signal that deserves its own story; introducing it in 4.5 is scope creep. The single-eval choice matches the existing `BPMDiagnosticTrace` attachment convention (every other window's trace is dropped at merge time anyway). Future story may revisit if Story 4.5/4.6 ablation shows per-window ML evaluation would resolve more named-track failures than single-window.

---

**DDs #18-#23 added 2026-05-09 fourth-pass cohesion review** after Story 4-4b pivoted to bring-your-own-weights adapter pattern. Four BMad agents (Winston / Amelia / Paige / Siri) reviewed cross-story cohesion; codex returned per-item AGREE/MODIFY verdicts. The DDs below codify the public API surface and consumer-onboarding contracts that 4-4b's pivot pushed into 4-5's scope. **Naming reconciliation (codex M1):** the public type is `BNNSTechnique` (existing Story 4.1 + 4-5 convention); 4-4b's pseudocode references to `BundledTempoClassifier` are propagated back to `BNNSTechnique`.

18. **`MLTechnique` protocol surface — finalized public API per codex Item 1.** The protocol was declared in Story 4.3 ("Definition only, no conformances yet" per CLAUDE.md). Story 4.5 ships the first conformance AND freezes the public surface so consumers can implement their own. **Final shape (verbatim — copied into DocC):**
    ```swift
    public protocol MLTechnique: Sendable {
        /// Evaluates a candidate set against an ML model using features captured in the trace.
        /// - Parameter trace: The diagnostic trace from the just-completed merge step. May contain
        ///   `mlFeatures` populated when `Options.captureMLFeatures` was true upstream.
        /// - Returns: An `MLEvaluation` when the model produced a confident prediction; `nil` when
        ///   the model abstained (low confidence, missing features, or out-of-distribution input).
        ///   Conformers SHOULD return `nil` rather than a low-confidence `MLEvaluation` when the
        ///   prediction would not improve on DSP-only candidate scoring.
        /// - Note: Implementations MUST be thread-safe. The library may invoke this method
        ///   concurrently from `withTaskGroup` fan-out at intensity ≥ `.thorough`.
        /// - Note: This protocol is backend-agnostic. Conformers may use BNNSGraph (CPU-only,
        ///   low-latency), Core ML (CPU+ANE eligible), MLX (Apple Silicon), MPS Graph, or pure
        ///   Swift inference. The library does not constrain the choice.
        func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?
    }
    ```
    **Frozen invariants for 1.0:** (a) takes ONLY `BPMDiagnosticTrace`, no raw audio or per-window samples; (b) returns `MLEvaluation?` (consumers cannot return throwing values; failure modes are encoded as `nil` + diagnostic logging in the conformance); (c) `Sendable` requirement enables concurrent fan-out; (d) backend-agnostic — does NOT mention BNNSGraph in the protocol surface (codex Item 1 + Siri Item 5: protocol abstracts at the task level, not the tensor level).
    **BPM bin decode contract (codex Item 1):** `BNNSTechnique` decodes its 256-class softmax via `bpm = 30.0 + Double(argmax)`; bin count 256 asserted at load time via DD #20's `validateContract` step. Custom `MLTechnique` conformances may use any decode they want — the protocol does not constrain it.

19. **Override API: `Options.mlTechnique` only, with `BNNSTechnique(modelURL:)` injection for ergonomics (codex Item 2-MOD + Item 3 + Item 4-MOD).** The override seam is the existing `AudioAnalysisService.Options.mlTechnique: (any MLTechnique)?` field (established Story 4-3, default `nil` per Story 4-4). **No new convenience APIs** — codex rejected `useMLModel(at:)` / `setMLTechnique(_:)` as redundant with `Options.mlTechnique`. **Selection is explicit, not precedential:**
    | Consumer intent | Code |
    |---|---|
    | Disable ML entirely (default — DSP-only) | `Options.mlTechnique = nil` |
    | Use library's bundled reference model | `Options.mlTechnique = try? BNNSTechnique()` |
    | Use consumer's converted weights, same architecture | `Options.mlTechnique = try? BNNSTechnique(modelURL: myMLModelcURL)` |
    | Use consumer's custom architecture / different framework | `Options.mlTechnique = MyCustomMLTechnique()` |
    `BNNSTechnique.init(modelURL: URL = bundledReferenceURL) throws` accepts an injected URL with a default resolving to `Bundle.module.url(forResource: "giantsteps_v1", withExtension: "mlmodelc")` (the Story 4.1-locked bundled reference). Consumer-supplied `.mlmodelc` files MUST honor the tensor-name + shape contract from DD #16 / DD #20 — if not, init throws `MLTechniqueError.invalidTensorContract` per DD #20. **No precedence; no implicit fallback.** The consumer assigns ONE `MLTechnique` (or `nil`); the library uses what's assigned.

20. **`validateContract(graph:) throws` runtime invariant (codex Item 5 + Item 6 elevated + Siri Item 3).** DD #16's "argument lookup by name" was a documented promise; DD #20 makes it a runtime invariant enforced inside `BNNSTechnique.init`. Implementation:
    ```swift
    private static func validateContract(graph: bnns_graph_t) throws {
        let inputIdx = BNNSGraphGetArgumentPosition(graph, nil, "input")
        guard inputIdx != .max else {  // BNNSGraphGetArgumentPosition returns SIZE_MAX on miss
            throw MLTechniqueError.invalidTensorContract(missing: "input")
        }
        let outputIdx = BNNSGraphGetArgumentPosition(graph, nil, "output")
        guard outputIdx != .max else {
            throw MLTechniqueError.invalidTensorContract(missing: "output")
        }
        // Bin count assertion: output tensor's last dim must be 256 per DD #18 BPM bin decode.
        // (Implementation reads tensor metadata via BNNSGraph API; exact call shape TBD at Task 1.5
        // when the dev confirms BNNSGraph 26 SDK symbols against the local Xcode.)
    }
    ```
    `MLTechniqueError` is a new public enum (Sendable) co-located with the protocol:
    ```swift
    public enum MLTechniqueError: Error, Sendable {
        case modelResourceMissing(URL)        // Bundle.module.url returned nil OR custom URL doesn't exist
        case modelLoadFailed(underlying: any Error) // BNNSGraphCompileFromFile failed
        case invalidTensorContract(missing: String) // tensor name not found per DD #20
        case binCountMismatch(expected: Int, actual: Int) // output last-dim != 256 per DD #18
    }
    ```
    Consumer-supplied `.mlmodelc` files violating the contract throw at construction time — they NEVER reach `evaluate(trace:)`. The runtime invariant turns DD #16 from documentation into enforcement at the only place enforcement is meaningful.

21. **macOS 14 artifact / macOS 15 runtime forward-compat invariant (codex Item 7 + Siri Item 1).** Story 4-4b's DD #9 sets `coremltools.convert(...minimum_deployment_target=ct.target.macOS14)` to widen consumer compatibility. Story 4-5's runtime path (`BNNSGraphCompileFromFile`) is gated on macOS 15 (Swift package floor). The contract is **artifact opset ≤ runtime opset**: a `.mlmodelc` compiled for macOS 14 runs on macOS 15+ runtimes per Apple's MLProgram forward-compat spec. The package floor of macOS 15 is what matters for the Swift-side code path (BNNSGraph C API availability, Swift 6 concurrency); the `.mlmodelc` floor of macOS 14 is what matters for the Python-side conversion. They are independent. The dev does NOT need a runtime version check — `BNNSGraphCompileFromFile` will accept any macOS 14+ artifact; only consumers running on macOS 14 hosts (which the package doesn't support) would be affected.

22. **Failure semantics: `init` throws; `analyzeBPM` does not silently mask (codex Item 9-MOD).** `BNNSTechnique.init(modelURL:) throws` propagates failures to the caller. The library does NOT silently degrade to DSP-only when the model fails to load — graceful degradation is opt-in via `try?`:
    ```swift
    // Caller chooses graceful: nil on any load failure → ML disabled
    options.mlTechnique = try? BNNSTechnique()

    // Caller chooses strict: load failure throws → caller decides what to do
    do {
        options.mlTechnique = try BNNSTechnique()
    } catch MLTechniqueError.modelResourceMissing(let url) {
        // log, alert, fall back to DSP-only with explicit knowledge
    }
    ```
    `analyzeBPM(...)` never absorbs an `MLTechnique` error silently — once `Options.mlTechnique` is set to a non-nil value, the library trusts the conformance. Per-call failures inside `evaluate(trace:)` (e.g., BNNSGraph runtime error) are returned as `nil` per the protocol contract; the library logs once-per-session via `os_log` and continues with DSP-only candidate scoring for that call. **No retry, no fallback model, no silent degradation.**

23. **`BNNSGraphCompileOptions.preferredDeviceClass = .cpu` if SDK exposes it (codex Item 8-MOD + Siri Item 2).** WWDC 2025 session 276 introduced `BNNSGraphCompileOptions` with a device-class preference. The dev verifies the exact symbol against the local SDK at Task 2 (the Xcode 26 / macOS 26 SDK header is the authoritative source — codex flagged: "do not hard-code a WWDC 2025 API spelling unless confirmed against the local SDK"). If the symbol exists, pass `.cpu` explicitly to match Story 4-4b's `CPU_ONLY` honest signal. If the symbol is gated behind `@available(macOS 26.0, *)` and the package floor is macOS 15, use the existing default-device path and document the deferred upgrade as a Story 4.6+ enhancement. Either way, BNNSGraph executes on CPU per WWDC 2024-10211 framing — the device-class hint is a forward-compat nicety, not a correctness requirement.

## Background

Story 4.4 closed the public `EnsemblePolicy` surface (3 cases: `.dspOnly` default, `.mlOnly`, `.highestConfidence`) and promoted the ensemble combiner to its own file (`Sources/BoomBoomBoomKit/EnsembleCombiner.swift`). The pipeline ordering is now `merge → MetadataCorroborator.apply → MLTechnique.evaluate → EnsembleCombiner.combine → AudioAnalysisResult` (Story 4-3 DD #5 + Story 4-4 A1 short-circuit). The ML path is wired end-to-end against `MockMLTechnique` returning fixed `MLEvaluation` values; **what's missing is a real `MLTechnique` conformance that uses an on-device model**. Story 4.5 ships that conformance using BNNSGraph (zero new framework dependencies — BNNS is inside `Accelerate`).

Story 4.5 closes three correctness gaps in addition to landing the conformance:

- **Trace-as-feature-source — the missing input contract.** `MLTechnique.evaluate(trace:)` receives only the trace; today the trace carries DSP candidates and post-pipeline diagnostics but NOT the log-mel-spectrogram a tempo CNN needs as input. Story 4.5 adds the typed `MLFeatureFrames` evidence struct + `BPMDiagnosticTrace.mlFeatures` field to bridge the gap. This is the most consequential design choice in the story (DD #2).

- **Cancellation cooperation across the ML boundary.** Mock `MLTechnique.evaluate` is sub-millisecond; real BNNS inference is multi-second on Apple Silicon (typical tempo CNN forward pass: 50–500 ms on M-series Neural Engine via CoreML, 100–1000 ms via BNNSGraph CPU path). The deferred-work entry from Story 4.3 review flagged this as a Story 4.5/4.6 fix (DD #11).

- **Named-track validation against the DnB triplet failure mode.** The 4 named DnB tracks (Charly @ 160, Faraday_Bunker @ 170, Yin Yang @ 170, HEFT_Anagram 6 @ 170) are the canonical failure mode for Phase 1-3 DSP — onset-envelope quality on heavily-mastered material collapses, the limiter equalizes the dynamic range that energy-based onset detection keys off (Epic 3 retro 2026-05-03 footnote). Story 4.5 ML features (log-mel-spectrogram + per-sub-band z-score normalization across the time axis) are robust to this failure mode by design (DD #2, citing Schreiber & Muller 2018 and Bello et al. tutorial on onset detection). The T2 numeric delta gate (≥ 2 of 4 resolved within ±0.5 BPM) tests whether this design holds empirically.

**Sequencing note (deviation from Epic 4 spec).** Epic 4 recommended landing Story 4.7 (spectral-flux DSP variant) BEFORE Story 4.5 so BNNS feature design knows the post-spectral-flux baseline (`epics.md:1092` and `epics.md:1181`). The user is promoting Story 4.5 first per project-lead discretion. **Consequence:** BNNS feature design uses the current energy-based onset envelope as its log-mel source. If Story 4.7 lands later and changes the spectrogram pre-image, Story 4.5 features will need re-training against the post-4.7 features (the typed `MLFeatureFrames` shape is unchanged; only the model weights change). This is documented in DD #14 and the deferred-work disposition.

**Model availability.** ML model training is out of scope for Phase 3 (`epics.md:1090`). Story 4.5 ships the conformance, the feature pipeline, the trace plumbing, and the impact-report harness; the dev acquires a `.mlmodelc` artifact via `make compile-model` against either (a) a Schreiber & Muller-style shallow CNN trained externally (e.g., via `tempo-cnn` reference repo `https://github.com/hendriks73/tempo-cnn`), OR (b) a placeholder/mock model with the correct input/output shape but random weights (will fail HALT (b) by design — surfaces Branch C). **The story spec covers both paths**; the dev surfaces the model-availability question to the Project Lead at Task 2 BEFORE attempting Task 4 (BNNSGraph inference). Pure-plumbing validation with random weights is insufficient for HALT (b) clearance — a real model is required for Story 4.6 Branch A/A'/B promotion.

## Acceptance Criteria

1. **`BNNSTechnique` conforms to `MLTechnique` via Shape A-prime (public struct + private RAII storage class); `init() throws`; missing-resource path returns nil via `try?`.**

   **Given** the current `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` (Story 4.1 stub: `public struct BNNSTechnique: Sendable { public init() {} }`)
   **When** Story 4.5 ships
   **Then** the type is `public struct BNNSTechnique: MLTechnique` with `@unchecked Sendable` conformance (rationale: graph immutable post-compile; per-call contexts isolated; no shared mutable state — DD #15)
   **And** a private `final class BNNSGraphHandle: @unchecked Sendable` owns the immutable `bnns_graph_t`; `BNNSGraphHandle.deinit { free(graph.data) }` releases the malloc'd graph payload (DD #15 — fixes graph leakage that no single review caught)
   **And** the struct holds `private let handle: BNNSGraphHandle`, `private let srcIndex: Int`, `private let dstIndex: Int` (argument positions resolved by name at init via `BNNSGraphGetArgumentPosition` per DD #16)
   **And** the initializer signature is `public init() throws` (per ADR-4 and Story 4.1 doc-comment's pre-1.0 / no-BC notice)
   **And** the initializer also has `@available(macOS 15.0, *)` annotation as defense-in-depth (Siri's recommendation — guards if package floor ever drops to macOS 14)
   **And** the init throws `BNNSTechniqueError.modelResourceMissing` when `Bundle.module.url(forResource: "giantsteps_v1", withExtension: "mlmodelc")` returns nil (use `url.path()` — modern percent-decoded form per axiom-apple-docs MAJOR #6; `url.path` property is deprecated macOS 13+)
   **And** the init throws `BNNSTechniqueError.graphCompilationFailed(underlyingMessage: String)` when `BNNSGraphCompileFromFile(path, nil, options)` returns a graph with `graph.size == 0` OR `graph.data == nil` (per Apple's documented failure-detection pattern; not a status-out API)
   **And** `try? BNNSTechnique()` returns nil on either error path (the documented graceful-degradation pattern at `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:113-138`)
   **And** the type uses ONLY raw C: `BNNSGraphCompileFromFile` + `BNNSGraphContextMake` + `BNNSGraphContextExecute` + `BNNSGraphContextDestroy` — NEVER `BNNSGraph.Builder`, `BNNSGraph.Context(contentsOf:)`, or `BNNSGraph.makeContext` (those are macOS 26+ per DD #7), and NEVER `BNNSFilterCreate*` / `BNNSFilterApply*` (deprecated classic-bnns-api per DD #7)
   **And** PR-time guards: `grep -rn "BNNSFilterCreate\|BNNSFilterApply" Sources/BoomBoomBoomKitML/` AND `grep -rn "BNNSGraph\.Builder\|BNNSGraph\.Context\|BNNSGraph\.makeContext" Sources/BoomBoomBoomKitML/` both return ZERO matches

2. **`BNNSTechnique.evaluate(trace:)` reads `trace.mlFeatures`, z-score normalizes, resamples per-row, and runs BNNSGraph inference via per-call context.**

   **Given** a `BPMDiagnosticTrace` with non-nil `mlFeatures: MLFeatureFrames?` populated by `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` per AC #4
   **When** `BNNSTechnique.evaluate(trace:)` is called (per Story 4.3 protocol shape `func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?`)
   **Then** it rejects degenerate input: if `trace.mlFeatures.frames < 32`, return nil immediately (DD #9 short-clip guard fires BEFORE resize)
   **And** it z-score-normalizes each mel sub-band across the time axis (`vDSP_meanv` + `vDSP_normalizev` per row) — output preserves NCHW layout
   **And** it temporally **resamples** (NOT pools — DD #9) to a fixed W=512 frames via `vDSP.linearInterpolate(elementsOf:using:result:)` per mel band (the `(elementsOf:using:result:)` overload, NOT `(values:atIndices:result:)`); precomputed 512-element control vector reused across all 128 bands
   **And** it constructs `BNNSTensor` instances for input/output (NOT `BNNSNDArrayDescriptor` — that's the classic-API descriptor, wrong path for graph execution per axiom-apple-docs MAJOR #4); input shape `[1, 1, 128, 512]` row-major NCHW, `BNNSDataType.float`; output shape derived from compiled graph metadata via `BNNSGraphContextGetTensor` (NOT hard-coded)
   **And** it wraps tensors in `bnns_graph_argument_t.tensor = pointer` and places them in a SINGLE `[bnns_graph_argument_t]` array indexed by `srcIndex`/`dstIndex` (resolved at init per DD #16); calls `BNNSGraphContextSetArgumentType(context, BNNSGraphArgumentTypeTensor)` once before execute
   **And** it creates a per-call context: `var context = BNNSGraphContextMake(handle.graph)` + `defer { BNNSGraphContextDestroy(&context) }` — the context is destroyed on every code path including throws (DD #15 lifecycle correctness)
   **And** it invokes `BNNSGraphContextExecute(context, nil, arguments.count, &arguments, workspaceSize, workspace)` (6 args, takes context not graph; per Apple's documented signature; workspace allocation sized via `BNNSGraphContextGetWorkspaceSize` if non-zero — typically zero for inference graphs)
   **And** the output tensor is decoded as a softmax over BPM bins; `vDSP.indexOfMaximum` for argmax, `vDSP.maximum` for confidence; argmax-bin → BPM via the bin-center mapping declared at init from model metadata
   **And** the function returns `MLEvaluation(bpm: clampedBPM, confidence: clampedConfidence, modelIdentifier: "bnns_tempo_v1")` when `softmax-max >= confidenceThreshold` (`Self.confidenceThreshold = 0.50` per DD #10); `bpm` clamped to `60.0...200.0`; `confidence` clamped to `0.0...1.0` (defense-in-depth per Story 4-4 DD #4)
   **And** the function returns `nil` (the documented abstain path) when `softmax-max < confidenceThreshold` OR `trace.mlFeatures == nil` OR `mlFeatures.frames < 32`

   **Given** `trace.mlFeatures == nil` (the capture flag was off, OR an unexpected code path)
   **When** `evaluate(trace:)` is called
   **Then** the function returns `nil` immediately with a one-time `os_log` diagnostic at `.fault` level: `"BNNSTechnique.evaluate(trace:) called with nil mlFeatures — capture flag may not be propagating"` (HALT (g) — defensive log; the issue is structural, not runtime)
   **And** a unit test (`BNNSTechniqueTests::evaluateReturnsNilWhenFeaturesAbsent`) covers this branch

3. **`MLFeatureFrames` typed-evidence struct with semantic metadata lives in `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` per the typed-evidence pattern.**

   **Given** the project-context.md "Banned trace-field shapes" rule (named `Sendable` value types only; no `[String: Any]`, no stringified-numeric values)
   **When** Story 4.5 ships
   **Then** a new struct in `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` is added (mirrors the placement convention of `ClickCorrelationEntry`, `HarmonicRatioEvidence`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`, `SubBandEnergies`):
   ```swift
   public struct MLFeatureFrames: Sendable, CustomStringConvertible, Equatable {
     public let melBands: Int           // == 128 for the Story 4.5 model
     public let frames: Int             // pre-resample source frame count
     public let tensorLayout: TensorLayout  // .nchw only initially
     public let logMelData: [Float]     // row-major; precondition: count == melBands * frames
     public let sampleRate: Double      // 44100 / 48000 / 96000 (DSP source rate)
     public let fftSize: Int            // 2048 (BPMAnalyzer constant)
     public let hopSize: Int            // pipeline hop in samples
     public let melFmin: Double         // 30 Hz (BPMAnalyzer.melFmin)
     public let melFmax: Double         // min(sampleRate/2, 16000)
     public let logCompressionScale: Float  // 100.0 (BPMAnalyzer.logCompressionScale)
     public let featureSetVersion: String   // "v1" — bumps when pre-vvlogf pipeline changes
     public init(...) {
       precondition(melBands > 0, "melBands must be positive")
       precondition(frames > 0, "frames must be positive")
       precondition(logMelData.count == melBands * frames,
         "logMelData.count must equal melBands * frames")
       precondition(tensorLayout == .nchw,
         "Story 4.5 only supports .nchw tensor layout")
       // ... assignments
     }
     public var description: String { ... }
   }
   public enum TensorLayout: String, Sendable, Hashable, CaseIterable {
     case nchw  // row-major, [N=1, C=1, H=melBands, W=frames]
   }
   ```
   **And** `MLFeatureFrames` conforms to `Sendable, CustomStringConvertible, Equatable` per the Story 3-3b typed-evidence precedent (5 evidence structs already conform to this pair)
   **And** `Equatable` semantics are element-wise on `logMelData` (Float `==` — NaN ≠ NaN by design; this is a diagnostic equality, not a hash key)
   **And** the initializer enforces 4 invariants via `precondition`: `melBands > 0`, `frames > 0`, `logMelData.count == melBands * frames`, `tensorLayout == .nchw` (Codex MAJOR #4 — without these, the trace cannot prove what the tensor means)
   **And** `TensorLayout` initial case set is exactly `.nchw` (1 case) — `CaseIterable` for future enumeration; pre-1.0 framing allows new cases (`.nhwc` for CoreML if Story 4.6 surfaces a need)
   **And** the new field on `BPMDiagnosticTrace` is `public var mlFeatures: MLFeatureFrames? = nil` (matches the existing `BPMDiagnosticTrace` field convention — every field is `public var`, mutable defaulted)
   **And** the four banned trace-field anti-patterns audit (`.claude/skills/bpm-diagnostic-trace/SKILL.md` recipes A-E) returns ZERO matches against `Sources/` and `Tests/` at PR time
   **And** `MLFeatureFrames.featureSetVersion` is initialized to `"v1"` for Story 4.5; Story 4.7 (or any other change to the pre-`vvlogf` mel pipeline) MUST bump to `"v2"` (Mary's "name the seam, name the trigger" — DD #14)

4. **`BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` populates `MLFeatureFrames` only when `Options.captureMLFeatures == true`.**

   **Given** the existing `computeMelOnsetEnvelopeWithSubBands` in `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:488-700+` (which already builds `logMelFrames` at lines 535-585 then discards it after temporal differencing)
   **When** Story 4.5 ships
   **Then** an internal `BPMAnalyzer.Options.captureMLFeatures: Bool = false` flag is added (default false; internal-only per DD #4)
   **And** `AudioAnalysisService.runPreCorroborationPipeline` sets the flag when `shouldBuildTrace == true && options.mlTechnique != nil && options.ensemblePolicy != .dspOnly` (mirrors the existing `shouldBuildTrace` predicate at `AudioAnalysisService.swift:289-291`)
   **And** the existing `OnsetEnvelopes` return tuple is extended with `mlFeatures: MLFeatureFrames?` (only when capture is on); OR the function is refactored to thread features into the trace builder downstream (dev-judgment which approach minimizes churn — both are spec-compatible)
   **And** when `captureMLFeatures == false`, `logMelFrames` is discarded as before; the `[Float]` row-major payload is NEVER allocated; `BPMDiagnosticTrace.mlFeatures` is nil (regression-protection contract)
   **And** the spectrogram fed to BNNS is bit-for-bit identical to the spectrogram fed to the onset envelope downstream — verified by AC #5 byte-identity test (proves the retention path doesn't mutate the intermediate)

5. **Default-disabled byte-identity gate (Non-regression gate per Epic 4 Definitions, DSP-only path) PLUS element-wise spectrogram-retention proof.**

   **Given** Story 4.5 ships with `Options.mlTechnique` defaulting to `nil` (unchanged from Story 4-4 default; DD #4 keeps `captureMLFeatures` off when `mlTechnique == nil`)
   **When** `make benchmark` and `make benchmark-giantsteps` run pre-merge with default options
   **Then** asserted floors hold per Epic 4 Definitions: OA300 Acc1 ≥ 57/82, Acc2 ≥ 73/82; GiantSteps Acc1 ≥ 537/661, Acc2 ≥ 546/661 (HALT (c))
   **And** per-track BPM JSON output is byte-identical to the pre-Story-4.5 snapshot at `_bmad-output/implementation-artifacts/4-5-regression-snapshot.json` captured at Task 1
   **And** the snapshot captures both `mlTechnique == nil` (the default) AND `mlTechnique != nil + ensemblePolicy = .dspOnly` paths (the latter exercises the A1 short-circuit; both must be byte-identical to baseline because neither invokes `evaluate(trace:)` per Story 4-4 AC #14)
   **And** the byte-equality opt-out test in `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift::dspOnlyByteIdenticalWithBNNSAvailable` runs `try? BNNSTechnique()` (CI: returns nil; local: returns instance) on a synthetic click-track fixture — both paths produce byte-identical `bpm`/`confidence`/`candidates` to the no-ML baseline (HALT (e))
   **And** the `equalByBitPattern` helper from `EnsembleCombinerTests.swift` (Story 4-3 Task 6.1) is reused for this byte-identity comparison

   **Given** the spectrogram-retention path in `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` (Codex MAJOR #5 / patch P7)
   **When** `Tests/BoomBoomBoomKitTests/MLFeatureFramesTests.swift::retainedSpectrogramIsBitExactPostVvlogf` runs
   **Then** the test invokes `computeMelOnsetEnvelopeWithSubBands` with `captureMLFeatures: true` on a synthetic deterministic input, captures the `logOutput` array immediately AFTER `vvlogf` (line 583) and BEFORE the `vDSP_vsub` temporal-difference loop (line 603), then asserts `MLFeatureFrames.logMelData` equals the flattened retained log-mel frames element-by-element (`Float` `==` per row, every row)
   **And** if any element diverges, HALT (h) fires — the retention path is mutating intermediate state
   **And** this test uses `@testable import BoomBoomBoomKit` to reach the internal `computeMelOnsetEnvelopeWithSubBands` function

6. **Pre-promotion ground-truth verification gate (per Epic 4 retro, also gates Story 4.5 promotion to `ready-for-dev`).**

   **Given** the artifact `_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json` (`schema_version: 2`, committed at SHA `9185698`)
   **When** the dev verifies at Task 1 (BEFORE first source edit)
   **Then** the artifact exists with all 4 expected `track_id` values populated (Charly, Faraday_Bunker, Yin Yang Audio, HEFT_Anagram 6)
   **And** all 4 `current_predicted_bpm` and `current_abs_error` values are populated (the named-track baseline; DD #1 — frozen at Story 4.1 / 4.2 / 4.3 / 4.4 baseline, NOT re-run at Story 4.5 PR time)
   **And** all 4 entries have non-null `source` (2× `dawproject`, 2× `daw_oracle`)
   **And** the `regression_threshold` block is `{min_resolved: 2, tolerance_bpm: 0.5, min_oa300_acc1: 58, min_giantsteps_acc1: 537}` — these values are READ-ONLY for Story 4.5 (changes require explicit Project Lead authorization per the epic AC)
   **And** if any entry is missing or malformed, HALT (a) fires; re-run `make oracle-generate` per `epics.md:1038`

7. **T2 — Numeric delta gate (A1, applies to Story 4.5). Impact-report config is PINNED, separate from default-config inertness gate.**

   **PINNED IMPACT-REPORT CONFIG (Codex MAJOR #9 / P9 — resolves spec-internal contradiction):**
   - `intensity = .thorough` (forces ML path activation)
   - `ensemblePolicy = .mlOnly` (isolates ML signal; DD #10 confidence threshold + AC #2 abstain ensures DSP fallback on low-confidence tracks)
   - The "default config" mentioned in HALT (d) is a SEPARATE gate (see below) measured via `make benchmark` with `Options.mlTechnique = try? BNNSTechnique()` and `ensemblePolicy = .dspOnly` — the inertness path. These are not the same configuration.

   **Given** Story 4.5 BNNS is enabled at the pinned impact-report config: `var opts = AudioAnalysisService.Options(); opts.mlTechnique = try BNNSTechnique(); opts.intensity = .thorough; opts.ensemblePolicy = .mlOnly`
   **When** `make bnns-impact-report` runs with `OA300_CORPUS_PATH` set against the 4 DnB triplet targets AND the broader OA300 corpus
   **Then** ≥ 2 of the 4 named tracks must be detected within ±0.5 BPM strict Acc1 of their named ground-truth value (per `regression_threshold.min_resolved: 2`, `regression_threshold.tolerance_bpm: 0.5`)
   **And** NO track in the named set may regress in absolute BPM error vs the Story 4.4 named-track baseline frozen in `4-dnb-triplet-targets.json` (cannot trade Charly+HEFT wins for breaking Faraday_Bunker — corpus floors are a per-track invariant on the named set; per `epics.md:1047`)
   **And** asserted floors hold per Epic 4 Definitions (HALT (c))
   **And** the BNNS-on path does NOT regress vs the post-Story-4.4 snapshot (OA300 Acc1=58, Acc2=74, GiantSteps Acc1=537, Acc2=546) — i.e. BNNS may improve named-track resolution but cannot trade Charly+HEFT wins for breaking Faraday_Bunker AND cannot regress overall corpus from snapshot (HALT (d))
   **And** Acc1 must NOT regress below 58/82 with the BNNS-on path at the pinned impact-report config (HALT (d))

   **Separately — Default-config inertness gate (per Codex P9):**
   **Given** `Options.mlTechnique = try? BNNSTechnique()` AND `Options.ensemblePolicy = .dspOnly` (the A1-short-circuit configuration)
   **When** `make benchmark` runs
   **Then** per-track BPM JSON output is byte-identical to the pre-Story-4.5 snapshot per AC #5 (HALT (e))
   **And** `RecordingMockMLTechnique.callCount == 0` invariant (Story 4-4 AC #14) is preserved — the short-circuit fires regardless of whether `BNNSTechnique` is loaded

   **HALT trigger (per Epic 4 retro action item T2):** if BNNS resolves < 2 of 4 named DnB triplets WITH a real model, HALT (b) fires; Completion Notes document per-track failure modes; Story 4.6 enters Branch C. (Plumbing-only / placeholder-model path is REJECTED per DD #12 — see HALT (a').)

   **DnB baseline coherence (Mary's "two baselines, two purposes"):** the frozen `4-dnb-triplet-targets.json` (SHA `9185698`) is the ACCURACY oracle (compare absolute BPM errors). The element-wise byte-identity test (AC #5 / HALT (h)) is the COMPUTATIONAL oracle (compare retained spectrogram element-by-element). These baselines are NEVER cross-validated — re-running the impact report at HEAD will produce numerically different absolute errors than the JSON records (because retention is new code), and that's expected drift, NOT regression. Completion Notes must document this distinction.

8. **`make bnns-impact-report` Makefile target produces deterministic per-track JSON; env override `BNNS_IMPACT_OUT_DIR` works correctly (Amelia's correction to Codex P10/P11).**

   **Given** the `make bnns-impact-report` target does not yet exist
   **When** Story 4.5 ships
   **Then** `Makefile` gains an env-default at file-top alongside `ML_MODEL_INPUT ?= ...` (variable defaults belong at file-top, NOT in recipe body — `?=` in recipe-line context is shell, not make):
   ```makefile
   # File-top variable defaults (alongside Makefile:5-9 existing env vars):
   BNNS_IMPACT_OUT_DIR ?= $(CURDIR)/_bmad-output/implementation-artifacts
   ```
   **And** the new target follows the `click-impact-report` / `duration-impact-report` / `ml-policy-sweep` pattern (`Makefile:101-114`):
   ```makefile
   ## bnns-impact-report: Generate per-track BNNS impact JSON to _bmad-output/implementation-artifacts/4-5-bnns-impact-report.json
   .PHONY: bnns-impact-report
   bnns-impact-report:
   	@mkdir -p "$(BNNS_IMPACT_OUT_DIR)"
   	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
   	BNNS_IMPACT=1 \
   	BNNS_IMPACT_OUT_DIR="$(BNNS_IMPACT_OUT_DIR)" \
   	GIT_SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown) \
   	swift test --filter BoomBoomBoomKitBenchmarkTests.BNNSImpactTests/bnnsImpactReport
   ```
   **And** `make bnns-impact-report BNNS_IMPACT_OUT_DIR=/tmp/run1` correctly redirects output to `/tmp/run1/4-5-bnns-impact-report.json` (Codex P10 — verified by Task 7.5 two-run determinism check)
   **And** the underlying `@Test` is env-gated on `BNNS_IMPACT=1` AND `OA300_CORPUS_PATH != nil`
   **And** the test pre-reads each OA300 file once into `[TrackAudio]` to filter unreadable files, then iterates surviving tracks running `analyzeBPM(url:)` with `Options.mlTechnique = try? BNNSTechnique()` and the pinned impact-report config from AC #7 (`intensity = .thorough`, `ensemblePolicy = .mlOnly`); skip the test entirely with `Issue.record("BNNSTechnique unavailable — model artifact missing")` if `BNNSTechnique()` returns nil (corresponds to HALT (a') if encountered post-Task-1.5; in CI without the model, the env-gated test simply doesn't run)
   **And** the output is `_bmad-output/implementation-artifacts/4-5-bnns-impact-report.json` with schema (per `epics.md:1066-1081`):
   ```json
   {
     "schema_version": 1,
     "snapshot_sha": "<commit-SHA-at-test-run>",
     "model_identifier": "bnns_tempo_v1",
     "named_dnb_track_results": [...],
     "all_tracks": [
       {
         "track": "<id>",
         "dsp_winner": <bpm>,
         "ml_winner": <bpm>,
         "ensemble_winner": <bpm>,
         "ml_confidence": <0..1>,
         "ground_truth": <bpm>,
         "dsp_correct": <bool>,
         "ml_correct": <bool>,
         "ensemble_correct": <bool>,
         "named_dnb_track": <bool>,
         "latency_ms": <number>
       }
     ]
   }
   ```
   **And** the report explicitly calls out the 4 named DnB triplet outcomes in `named_dnb_track_results`
   **And** if BNNS resolves <2 of 4, completion notes document per-track failure modes with this JSON as evidence (HALT (b) trigger)
   **And** JSON is emitted via `JSONEncoder` with `outputFormatting = [.prettyPrinted, .sortedKeys]` for byte-stable output (per Story 4.4 HALT (c) precedent)
   **And** two consecutive `make bnns-impact-report` runs at the same SHA + same model artifact produce byte-identical files except for `latency_ms` (which is wall-clock and varies; the JSON encoder writes it last via `CodingKeys` ordering so a `jq 'del(.all_tracks[].latency_ms)'` diff is byte-identical)

9. **Cancellation cooperation via `private throws` helper, NOT IIFE (Codex MAJOR #8 / P4 — resolves Story 4.3 deferred-work entry).**

   **Given** the existing `analyzeBPM` body at `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:279-337` (Story 4-4 close-out shape with the IIFE-`guard` ML evaluation block at lines 311-317)
   **When** Story 4.5 ships
   **Then** the IIFE-`guard` block at lines 311-317 is REPLACED with a single call to a new private static helper:
   ```swift
   // In analyzeBPM body, replacing existing lines 311-317:
   let mlEvaluation = try evaluateMLIfActive(options: options, trace: corroborated.trace)

   // New private static helper (in extension AudioAnalysisService, placed
   // below degradationMessage near line 358):
   private static func evaluateMLIfActive(
     options: Options, trace: BPMDiagnosticTrace?
   ) throws -> MLEvaluation? {
     guard options.ensemblePolicy != .dspOnly,
           let ml = options.mlTechnique,
           let trace
     else { return nil }
     if options.isCancelled() { throw CancellationError() }
     return ml.evaluate(trace: trace)
   }
   ```
   **And** the helper accepts `BPMDiagnosticTrace?` (matches the `corroborated.trace` Optional shape; the helper handles the unwrap so the call site stays terse)
   **And** the cancellation check uses `options.isCancelled` (the injectable closure per ADR-1, default `Task.isCancelled`) — NOT `Task.isCancelled` directly (preserves the deterministic-test injection contract)
   **And** a unit test `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift::cancellationBeforeMLEvaluateThrows` (NEW file per AC #10's new-files-only convention; uses `RecordingMockMLTechnique` from `BoomBoomBoomKitTestSupport` — does NOT require a real `BNNSTechnique` instance) verifies: `Options.isCancelled = { true }` + `Options.mlTechnique = RecordingMockMLTechnique()` + `Options.ensemblePolicy = .mlOnly` → `analyzeBPM` throws `CancellationError` AND `RecordingMockMLTechnique.callCount == 0` (proves the check fires BEFORE evaluate)
   **And** Story 4-4 AC #14 invariant (`RecordingMockMLTechnique.callCount == 0` on `.dspOnly` regardless of cancellation) is preserved — the helper's first guard returns nil before reaching the cancellation check
   **And** the deferred-work entry "Story 4.5/4.6 — Cancellation cooperation across `MLTechnique.evaluate` boundary" (`deferred-work.md:244`) is marked **RESOLVED BY STORY 4.5** with this story's commit SHA (entry covers both 4.5 and 4.6; mark RESOLVED but leave a note that 4.6 inherits the fix — no separate entry needed)

10. **Construction-level proof: diff scope is bounded; ALL new test assertions go in NEW files (Amelia's pick (a) — option vs option-(b) reconciliation per Codex MAJOR #10 / P11).**

    **Given** Story 4.5's authorized diff scope
    **When** the dev runs `git diff --stat <pre-story-SHA>..HEAD` at PR time
    **Then** the proof artifact at `_bmad-output/implementation-artifacts/4-5-diff-scope-proof.txt` shows:
    - **Modified (Sources):** `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (cancellation helper extraction per AC #9; `runPreCorroborationPipeline` propagates `captureMLFeatures` flag per AC #4), `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` (internal `Options.captureMLFeatures` flag + retention path for `MLFeatureFrames`), `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (new `mlFeatures` field + `MLFeatureFrames` and `TensorLayout` types per AC #3), `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` (real Shape A-prime conformance per AC #1, AC #2)
    - **New (Sources):** zero new files in `Sources/BoomBoomBoomKit/` (typed-evidence types live alongside existing ones per the Story 3-3b precedent); zero new files in `Sources/BoomBoomBoomKitML/` (BNNSTechnique.swift extended in place)
    - **Modified (Tests):** ZERO existing test files modified — all new assertions go in NEW files per Amelia's option (a). The `BNNSTechnique conforms to MLTechnique` invariant goes in a new `BNNSTechniqueTests` test, NOT inserted into `MetadataCorroborationTests.swift`'s existing architecture-invariants venue. The cancellation test goes in a new `BNNSCancellationTests.swift` (or in `BNNSTechniqueTests.swift`), NOT inserted into the existing `AudioAnalysisServiceTests.swift`. This makes the diff-scope proof mechanically verifiable: `git diff --name-only main...HEAD -- Tests/` shows only adds, zero modify-existing
    - **New (Tests):** `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift` (init success/fail + featurize/resample + abstain + cancellation + RAII deinit + concurrency exposure + raw-API guard tests per AC #1, #2, #5, #9, plus DD #15 lifecycle witness); `Tests/BoomBoomBoomKitTests/MLFeatureFramesTests.swift` (typed-evidence shape invariants + 4 init preconditions + element-wise byte-identity test per AC #3, AC #5); `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift` (env-gated impact report per AC #7, #8)
    - **Modified (Makefile):** `Makefile` gains `bnns-impact-report` target + `BNNS_IMPACT_OUT_DIR ?=` variable per AC #8
    - **Modified (artifacts):** `_bmad-output/implementation-artifacts/deferred-work.md` — Story 4.3 cancellation entry marked RESOLVED BY STORY 4.5; Mary's confidence-rule re-open trigger (DD #9 / cross-review insight d) added as new entry; project-context.md C-interop discipline rule update (Winston's elevation — "any C-resource-owning type owns malloc'd memory through `final class` with `deinit` exercised by ≥1 test")
    - **New (artifacts):** `_bmad-output/implementation-artifacts/4-5-regression-snapshot.json`, `_bmad-output/implementation-artifacts/4-5-bnns-impact-report.json`, `_bmad-output/implementation-artifacts/4-5-diff-scope-proof.txt`
    **And** ZERO modifications to (verify by `git diff --stat | grep -E '<paths>'`): `DSPTechnique.swift` (MLEvaluation/MLTechnique untouched), `EnsembleCombiner.swift`, `EnsemblePolicy.swift`, `EnsembleDecision.swift`, `CandidateMergeStrategy.swift`, `VotingPolicy.swift`, `LUFSAnalyzer.swift`, `MelFilterbank.swift`, `PCMBufferReader.swift`, `FileMetadataReader.swift`, `MetadataPolicy.swift`, `MetadataCorroborator.swift`, `ProgressUpdate.swift`, `Sources/BoomBoomBoomKitML/CoreMLTechnique.swift` (Story 4.6's domain), `Package.swift` (no new deps; BNNS lives in Accelerate which is already linked transitively via `BoomBoomBoomKitML`'s implicit Apple SDK access)

11. **Standard gating checklist — all gates pass.**

    **Given** Story 4.5's source changes are complete
    **When** the standard gating checklist runs
    **Then** ALL of the following pass:
    - `make fmt` — clean (zero diff)
    - `make lint` — single pre-existing `LUFSAnalyzer.swift:94` TODO baseline only (1 violation, 0 serious)
    - `make test` — `@Test(` count is in the band **`[370, 378]`** per DD #13 (revised 2026-05-08 from `[365, 375]`; pre-story baseline is **357**, NOT 355; net additions = 15); zero failures; zero skipped except env-gated benchmarks AND env-gated `BNNSImpactTests` (which is `BNNS_IMPACT=1`-gated, not run by `make test`)
    - `make benchmark` — strict equality vs `4-5-regression-snapshot.json` for the `mlTechnique == nil` path (byte-identical for the default-disabled path)
    - `make benchmark-giantsteps` — strict equality vs snapshot for the `mlTechnique == nil` path
    - `make ablation` — `.optimal` Acc1=55/82 (or post-Story-3-2 floor of ≥55/82) holds; 128 combos pass (no crashes; no new combo introduced — Story 4.5 does NOT add a `DSPTechnique` case)
    - `make perf-benchmark` — mock-on-abstain ratio remains ≤ 1.20x at default config (BNNS-on path measured separately; Completion Notes record the BNNS-on wall-clock per track median for Story 4.6 baseline)
    - `make bnns-impact-report` — produces the JSON per AC #8 schema at the pinned config (`intensity = .thorough`, `ensemblePolicy = .mlOnly`); ≥ 2 of 4 named DnB triplets resolved within ±0.5 BPM (HALT (b) fires otherwise)
    - **Two-run determinism check** — `make bnns-impact-report BNNS_IMPACT_OUT_DIR=/tmp/run1 && make bnns-impact-report BNNS_IMPACT_OUT_DIR=/tmp/run2 && diff <(jq 'del(.all_tracks[].latency_ms)' /tmp/run1/4-5-bnns-impact-report.json) <(jq 'del(.all_tracks[].latency_ms)' /tmp/run2/4-5-bnns-impact-report.json)` returns empty (Codex P10 + AC #8)
    - `swift build --target BoomBoomBoomKit` / `BoomBoomBoomKitTestSupport` / `BoomBoomBoomKitML` — all build independently; zero new framework dependencies in any target (verify via `swift package show-dependencies --format json | jq`)
    - `swift package show-dependencies --format json | jq '.dependencies | length'` returns 0 (the zero-dep posture is preserved)
    - **Trace-field audit (recipes A-E from `.claude/skills/bpm-diagnostic-trace/SKILL.md`)** — ZERO matches against `Sources/` and `Tests/` for the four banned shapes
    - **Raw-API guard greps** — `grep -rn "BNNSFilterCreate\|BNNSFilterApply" Sources/BoomBoomBoomKitML/` AND `grep -rn "BNNSGraph\.Builder\|BNNSGraph\.Context\|BNNSGraph\.makeContext" Sources/BoomBoomBoomKitML/` BOTH return ZERO matches (per AC #1 — Story 4.5 uses raw C only on macOS 15)
    - **Element-wise byte-identity test** — `MLFeatureFramesTests::retainedSpectrogramIsBitExactPostVvlogf` passes (HALT (h) — proves the retention path doesn't mutate intermediate state)
    - **TSan-clean concurrency exposure** — `swift test --sanitize=thread --filter BNNSTechniqueTests/concurrentEvaluateIsContextLocal` reports zero races (axiom-concurrency #5; gated on real-model presence — `Issue.record` skip in CI)
    - **RAII deinit witness** — `BNNSTechniqueTests::storageDeinitFreesGraphData` passes (DD #15 — drops the last reference to a `BNNSTechnique` instance and verifies the C `free` was invoked exactly once)
    - `BNNSTechnique` is reachable from a downstream consumer importing only `BoomBoomBoomKit + BoomBoomBoomKitML` (verified via the existing package-boundary proof pattern from Story 4.1)
    **And** Completion Notes record exact integer counts for ALL gates (test count, OA300 Acc1/Acc2, GiantSteps Acc1/Acc2, ablation `.optimal` Acc1, perf-benchmark ratio, BNNS-on Acc1/Acc2 at pinned config, named-track resolution count `<N>`/4, BNNS inference wall-clock per-track median, two-run determinism diff exit code)
    **And** Completion Notes link to evidence artifact paths for each gate (Mary 2026-05-07 precedent: counts alone are unfalsifiable in 6 months; pair each integer with its supporting artifact path)

12. **Public `MLTechnique` protocol surface frozen in source per DD #18 (codex Item 1).**

    **Given** Story 4.5 is complete
    **When** the dev inspects `Sources/BoomBoomBoomKit/MLTechnique.swift` (or wherever the protocol is defined — was Story 4.3 / current location TBD at Task 0)
    **Then** the protocol matches DD #18's verbatim shape: `func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?`, `: Sendable`, doc comment names backend-agnosticism + thread-safety + abstain-via-nil contract
    **And** `public enum MLTechniqueError: Error, Sendable` is co-located with cases per DD #20 (`modelResourceMissing`, `modelLoadFailed`, `invalidTensorContract`, `binCountMismatch`)
    **And** the protocol has DocC comments rendering as a public type page (codex Item 12)
    **And** a compile-time witness test `Tests/BoomBoomBoomKitTests/MLTechniqueProtocolTests.swift` calls `assertMLTechnique<T: MLTechnique>(_: T.Type) {}` against `BNNSTechnique.self` AND `MockMLTechnique.self` AND a hypothetical `class TestCustomTechnique: MLTechnique { ... }` (proves the protocol is consumer-conformable, not just library-internal)

13. **`BNNSTechnique.init(modelURL:)` injection + `validateContract` runtime invariant per DD #19 + DD #20 (codex Items 3 + 5).**

    **Given** `BNNSTechnique` source
    **When** the dev inspects `Sources/BoomBoomBoomKitML/BNNSTechnique.swift`
    **Then** the public init signature is `public init(modelURL: URL = Self.bundledReferenceURL) throws` where `bundledReferenceURL` is a `static let` resolving to `Bundle.module.url(forResource: "giantsteps_v1", withExtension: "mlmodelc")!` (force-unwrapped at static init since the resource is bundled via Story 4.1's `.copy("Resources")`)
    **And** the init calls `Self.validateContract(graph:)` per DD #20 BEFORE caching `srcIndex` / `dstIndex`
    **And** `validateContract` throws `MLTechniqueError.invalidTensorContract(missing: "input")` when `BNNSGraphGetArgumentPosition(graph, nil, "input") == .max`
    **And** `validateContract` throws `MLTechniqueError.invalidTensorContract(missing: "output")` when output position is `.max`
    **And** `validateContract` throws `MLTechniqueError.binCountMismatch(expected: 256, actual: <N>)` when output tensor's last dimension is not 256
    **And** a unit test `BNNSTechniqueTests/initThrowsOnMismatchedTensorNames` constructs a fixture `.mlmodelc` with renamed tensors (e.g., `var_42` instead of `output`) and asserts the init throws `invalidTensorContract` (4-5-HALT-(i) gate)
    **And** a unit test `BNNSTechniqueTests/initAcceptsCustomModelURL` passes a non-default URL pointing to a fixture `.mlmodelc` (proves the consumer-override path works without `Bundle.module`)

14. **Public DocC on new types per codex Item 12.**

    **Given** Story 4.5 is complete
    **When** the dev runs `swift package generate-documentation` (or inspects DocC source comments)
    **Then** `MLTechnique` protocol has a DocC comment block with: purpose, thread-safety contract, abstain semantics, backend-agnosticism note, link to `tools/coreml-convert/README.md` for the consumer-onboarding flow
    **And** `MLTechniqueError` has a DocC comment block enumerating each case's trigger condition
    **And** `BNNSTechnique` has a DocC comment block with: "default `MLTechnique` implementation backed by BNNSGraph", `init(modelURL:)` ergonomics, link to `tools/coreml-convert/README.md` Path A example
    **And** `MLFeatureFrames` has a DocC comment block per DD #2's semantic-metadata pattern + link to Story 4.6 inheritance discussion
    **And** `TensorLayout` enum has a DocC comment block enumerating `.nchw` semantics
    **And** `Options.mlTechnique` (existing field, may be in `AudioAnalysisService.swift`) has a DocC comment update referencing the four-row selection table from DD #19 (default nil / try? BNNSTechnique() / try? BNNSTechnique(modelURL:) / custom MLTechnique)

15. **Back-propagate finalized API names to `tools/coreml-convert/README.md` (codex Item 13).**

    **Given** Story 4.4b shipped `tools/coreml-convert/README.md` with placeholder API references marked `<!-- FINALIZED-BY-4-5 -->` (per Story 4-4b Task 11.7)
    **When** Story 4.5 is complete
    **Then** all `<!-- FINALIZED-BY-4-5 -->` markers in `tools/coreml-convert/README.md` are replaced with the actual Swift API names settled in this story (`BNNSTechnique`, `Options.mlTechnique`, `MLTechniqueError`)
    **And** the four worked examples in the README compile-check end-to-end with the actual Swift API (the dev runs each example in a scratch consumer app to verify; Completion Notes link to the scratch app's commit SHA)
    **And** zero remaining `<!-- FINALIZED-BY-4-5 -->` markers exist (`grep -rn "FINALIZED-BY-4-5" tools/coreml-convert/` returns empty)

16. **Unified workflow diagram in `tools/coreml-convert/README.md` (codex Item 14).**

    **Given** `tools/coreml-convert/README.md` exists
    **When** the dev opens it
    **Then** the README contains an ASCII diagram of the consumer journey:
    ```
    [your PyTorch .pt] -> tools/coreml-convert/convert.py -> [your.mlmodelc]
                                                                  |
                                                                  v
                                                        [bundle in your app]
                                                                  |
                                                                  v
                              Options.mlTechnique = try? BNNSTechnique(modelURL: ...)
                                                                  |
                                                                  v
                                BPMAnalyzer -> MLFeatureFrames -> evaluate(trace:) -> MLEvaluation
                                                                  |
                                                                  v
                                                      EnsembleCombiner -> result
    ```
    **And** the top-level project `README.md` contains a single-paragraph "Using your own tempo model" section linking to `tools/coreml-convert/README.md` (no duplication of the diagram or worked examples — single source of truth in `tools/coreml-convert/README.md`)

17. **License matrix in `tools/coreml-convert/README.md` opening (codex Item 15-MOD with softened Path C language).**

    **Given** `tools/coreml-convert/README.md` exists
    **When** the dev opens it
    **Then** within the first 30 lines the README contains:
    ```
    | Path                          | Licensor          | Consumer obligation                              |
    | A. Bundled default            | BoomBoomBoomKit   | None — BBBKit license applies (MIT-compatible)   |
    | B. Your custom weights        | You               | Your app's license terms apply to your weights   |
    | C. Third-party (e.g., AGPL)   | Upstream author   | May impose AGPL §13 obligations on your app      |
    |                               |                   | including network-use trigger; consult counsel    |
    ```
    **And** Path C language is "may impose AGPL obligations; consult counsel" (NOT the categorical "AGPL your whole app" framing — codex Item 15-MOD: AGPL effects depend on linkage and network use, not all bundling cases trigger §13 the same way)
    **And** the license matrix is followed by a one-paragraph disclaimer: "BoomBoomBoomKit makes no representation about third-party model licenses. We ship neither weights nor any rights to use them. The license obligations of your chosen weights belong to your app's distribution."

## Tasks / Subtasks

- [ ] **Task 1: Pre-source baseline capture (commit pre-source artifacts BEFORE first source edit) (AC: #5, #6)**
  - [ ] 1.1: Confirm working tree is clean and on a Story-4.5 branch (e.g., `rterhaar/epic-4`).
  - [ ] 1.2: Read `_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json` and verify all 4 `track_id` values resolve to existing files in `OA300_CORPUS_PATH`. If any are missing, HALT (a) and re-run `make oracle-generate` per `epics.md:1038`.
  - [ ] 1.3: Run `make benchmark` AND `make benchmark-giantsteps` against the current SHA. Capture per-track BPM JSON output to `_bmad-output/implementation-artifacts/4-5-regression-snapshot.json` (schema mirrors `4-4-regression-snapshot.json`). Capture both paths: `mlTechnique == nil` (default) AND `mlTechnique != nil + ensemblePolicy = .dspOnly` (A1 short-circuit) — both must be byte-identical post-Story-4.5.
  - [ ] 1.4: Run `make perf-benchmark` to capture pre-source perf baseline JSON (a new entry under `_bmad-output/perf-baselines/`).
  - [ ] 1.5: Verify model availability with the Project Lead. Two paths: (A) real `giantsteps_v1.mlmodelc` artifact available (from external training, e.g., `tempo-cnn` reference) — Task 2 proceeds with real inference; (B) artifact unavailable — Task 2 still proceeds (the conformance + plumbing land), but HALT (b) is anticipated at Task 7 (impact report) and Story 4.6 → Branch C is the planned outcome. Document the chosen path in Task 1 commit message.
  - [ ] 1.6: Commit Task 1 artifacts as a single pre-source commit: `Story 4-5 Task 1: pre-source-change baseline artifacts` (mirrors Story 4-4 Task 1 pattern, commit `757d57c`).

- [ ] **Task 2: Add `MLFeatureFrames` typed-evidence struct + `BPMDiagnosticTrace.mlFeatures` field (AC: #3)**
  - [ ] 2.1: In `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift`, add `MLFeatureFrames` struct definition at the bottom of the file (alongside `BarCandidate`, `SubBandEnergies`, etc.). Use the standard 6-line evidence-type doc pattern (rationale + replacement note for any prior shape).
  - [ ] 2.2: Add `TensorLayout` enum in the same file (just above `MLFeatureFrames` — types are co-located by ownership). Initial case set: `.nchw` only. `String, Sendable, Hashable, CaseIterable`.
  - [ ] 2.3: Add `public var mlFeatures: MLFeatureFrames? = nil` to `BPMDiagnosticTrace` near the existing `// MARK: - Story 4.4: Ensemble Decision` section (insert a new `// MARK: - Story 4.5: ML Feature Frames` MARK before the field).
  - [ ] 2.4: Run the typed-evidence audit recipes A-E from `.claude/skills/bpm-diagnostic-trace/SKILL.md` (or the equivalent grep patterns). Verify ZERO matches against `Sources/` and `Tests/`.

- [ ] **Task 3: Add `BPMAnalyzer.Options.captureMLFeatures` + retention path (AC: #4, #5)**
  - [ ] 3.1: In `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`, find the internal `Options` struct (the existing `Options` near `estimateBPM(samples:sampleRate:options:)`). Add `var captureMLFeatures: Bool = false` (NOT public — internal-only per DD #4).
  - [ ] 3.2: Modify `computeMelOnsetEnvelopeWithSubBands` (lines 488-700+) to retain `logMelFrames: [[Float]]` into a new return-tuple field `mlFeatures: MLFeatureFrames?` when `captureMLFeatures == true`. The retention happens AFTER `vvlogf` (line 583) and BEFORE the temporal-difference loop at line 603 — preserves the bit-exact spectrogram. Concatenate `[[Float]]` into a row-major `[Float]` payload of size `melBands * frames` for the `MLFeatureFrames.logMelData` field. Use `[Float](repeating: 0, count: melBands * frames)` + index-based assignment OR `flatMap` + `.flatMap(\.self)` (vDSP isn't needed here — the operation is a simple memcpy-equivalent).
  - [ ] 3.3: Extend the existing `OnsetEnvelopes` struct with `mlFeatures: MLFeatureFrames?` field, OR refactor the function to thread features via a separate output channel (dev judgment — choose the minimum-churn approach). Update all call sites in `BPMAnalyzer.swift` accordingly.
  - [ ] 3.4: In `AudioAnalysisService.runPreCorroborationPipeline` (`AudioAnalysisService.swift:412+`), set `bpmOptions.captureMLFeatures = shouldBuildTrace && options.mlTechnique != nil && options.ensemblePolicy != .dspOnly` (mirrors the existing `shouldBuildTrace` predicate at lines 289-291). Propagate the resulting `mlFeatures` to `BPMResult.trace?.mlFeatures` for the merged result.
  - [ ] 3.5: Verify byte-identity at AC #5 invariant: when `mlTechnique == nil` OR `ensemblePolicy == .dspOnly`, `captureMLFeatures` is false → `mlFeatures` is nil → `BPMDiagnosticTrace.mlFeatures` is nil. The `[Float]` payload is NEVER allocated on the DSP-only path.

- [ ] **Task 4: Wire `BNNSTechnique` Shape A-prime — public struct + private RAII Storage class + `init() throws` (AC: #1, #5; DD #15, #16)**
  - [ ] 4.1: In `Sources/BoomBoomBoomKitML/BNNSTechnique.swift`, define the private RAII storage class FIRST (per DD #15 — public struct is fine but C lifetime needs a `final class` deinit):
    ```swift
    private final class BNNSGraphHandle: @unchecked Sendable {
      let graph: bnns_graph_t
      init(graph: bnns_graph_t) { self.graph = graph }
      deinit {
        // BNNSGraphCompileFromFile mallocs graph.data; we must free it.
        // BNNSGraphContextDestroy does NOT free the graph — it only frees contexts.
        if let data = graph.data { free(data) }
      }
    }
    ```
  - [ ] 4.2: Replace the placeholder `public struct BNNSTechnique: Sendable { public init() {} }` with the real conformance shape (`@available(macOS 15.0, *)` defense-in-depth per Siri):
    ```swift
    @available(macOS 15.0, *)
    public struct BNNSTechnique: MLTechnique, @unchecked Sendable {
      // Sendable rationale: graph immutable post-compile; per-call contexts isolated;
      // no shared mutable state. nonisolated(unsafe) is NOT used per project-context.md.
      private let handle: BNNSGraphHandle
      private let srcIndex: Int
      private let dstIndex: Int
      // private static let confidenceThreshold: Double = 0.50 — see Task 5.4
      // private static let targetWidth: Int = 512 — see Task 5.1
      // private static let expectedMelBands: Int = 128

      public init() throws {
        guard let url = Bundle.module.url(
          forResource: "giantsteps_v1", withExtension: "mlmodelc"
        ) else { throw BNNSTechniqueError.modelResourceMissing }
        let options = BNNSGraphCompileOptionsMakeDefault()
        defer { BNNSGraphCompileOptionsDestroy(options) }
        let g = url.path().withCString { cpath in   // note url.path(), NOT url.path
          BNNSGraphCompileFromFile(cpath, nil, options)
        }
        guard let data = g.data, g.size != 0 else {
          throw BNNSTechniqueError.graphCompilationFailed(
            underlyingMessage: "BNNSGraphCompileFromFile returned empty graph")
        }
        _ = data  // suppress warning; data is verified non-nil
        // Resolve argument positions by name (DD #16 — never hard-code positions).
        // Input/output names depend on the trained model — verify at Task 1.5
        // and update if needed.
        let src = "input".withCString { BNNSGraphGetArgumentPosition(g, nil, $0) }
        let dst = "output".withCString { BNNSGraphGetArgumentPosition(g, nil, $0) }
        guard src >= 0, dst >= 0 else {
          // graph compiled but argument names didn't resolve — clean up
          if let d = g.data { free(d) }
          throw BNNSTechniqueError.graphCompilationFailed(
            underlyingMessage: "argument positions not found (input=\\(src), output=\\(dst))")
        }
        self.handle = BNNSGraphHandle(graph: g)
        self.srcIndex = Int(src)
        self.dstIndex = Int(dst)
      }
    }

    public enum BNNSTechniqueError: Error, Sendable {
      case modelResourceMissing
      case graphCompilationFailed(underlyingMessage: String)
    }
    ```
  - [ ] 4.3: Multi-paragraph `///` doc-comment on `BNNSTechnique` referencing: (a) Story 4.5 promotion from Story 4.1 placeholder; (b) ADR-4 eager loading; (c) the `giantsteps_v1.mlmodelc` resource convention from Story 4.1; (d) the macOS-15 raw-C-only API surface (DD #7) — explicitly rejecting `BNNSGraph.Builder` / `BNNSGraph.Context(contentsOf:)` / `BNNSGraph.makeContext` as macOS-26-only; (e) Shape A-prime lifecycle (DD #15) — public struct + private `BNNSGraphHandle` final class for `free(graph.data)` discipline; (f) per-call `bnns_graph_context_t` semantics (DD #15); (g) WWDC 2024 #10211 "Support real-time ML inference on the CPU" reference.
  - [ ] 4.4: Run grep guards: `grep -rn "BNNSFilterCreate\|BNNSFilterApply" Sources/BoomBoomBoomKitML/` AND `grep -rn "BNNSGraph\.Builder\|BNNSGraph\.Context\|BNNSGraph\.makeContext" Sources/BoomBoomBoomKitML/` BOTH return zero matches (per AC #1).

- [ ] **Task 5: Implement per-call evaluate body — featurize, BNNSGraph inference via per-call context, decode (AC: #2, #5; DD #15)**
  - [ ] 5.1: In `BNNSTechnique`, add private helper `featurize(_ features: MLFeatureFrames) -> [Float]?` that: (a) returns nil if `features.frames < 32` (DD #9 short-clip guard fires BEFORE resize); (b) z-score-normalizes each mel sub-band across the time axis using `vDSP_meanv` + `vDSP_normalizev` per row (preserves NCHW layout); (c) temporally **resamples** (NOT pools — per DD #9) to W=512 frames via `vDSP.linearInterpolate(elementsOf:using:result:)` per mel band — precompute the 512-element control vector once outside the row loop, reuse across all 128 bands. Output is a fixed-size `[Float]` of length `1 * 1 * 128 * 512 = 65536`.
  - [ ] 5.2: Add private helper `inferTempoCNN(_ inputTensor: [Float]) -> (bpm: Double, confidence: Double)?` that:
    ```swift
    private func inferTempoCNN(_ inputTensor: [Float]) -> (bpm: Double, confidence: Double)? {
      // Per-call context per DD #15 — destroyed even on throw via defer.
      var context = BNNSGraphContextMake(handle.graph)
      defer { BNNSGraphContextDestroy(&context) }
      guard context.data != nil else { return nil }

      // Build BNNSTensor for input (NOT BNNSNDArrayDescriptor — that's classic API).
      // Shape: [1, 1, 128, 512] NCHW row-major. Stride contiguous.
      var input = inputTensor
      var output = [Float](repeating: 0, count: outputBinCount)  // size from graph metadata at init

      let result = input.withUnsafeMutableBytes { inPtr in
        output.withUnsafeMutableBytes { outPtr in
          // Wrap pointers as BNNSTensor → bnns_graph_argument_t per Apple's doc example.
          // (Pseudocode — exact tensor construction follows Apple's BNNSGraphContextExecute
          // example; argument array indexed by srcIndex/dstIndex resolved at init.)
          var arguments: [bnns_graph_argument_t] = makeArguments(
            inputBytes: inPtr, outputBytes: outPtr,
            srcIndex: srcIndex, dstIndex: dstIndex)
          BNNSGraphContextSetArgumentType(&context, BNNSGraphArgumentTypeTensor)
          return BNNSGraphContextExecute(
            context, nil, arguments.count, &arguments, 0, nil)
        }
      }
      guard result == 0 else { return nil }   // BNNSGraphContextExecute returns Int32 status

      // Decode softmax: vDSP.indexOfMaximum for argmax, vDSP.maximum for confidence.
      // Map argmax-bin → BPM via the bin-center mapping declared at init.
      let argmax = vDSP.indexOfMaximum(output)
      let conf = Double(vDSP.maximum(output))
      let bpm = bpmBinCenter(forIndex: Int(argmax))   // helper from model metadata
      return (bpm: bpm, confidence: conf)
    }
    ```
    The exact construction of `bnns_graph_argument_t` follows Apple's `BNNSGraphContextExecute` documented example pattern (`argument.tensor = pointer`); document the bin count (`outputBinCount`) and BPM range mapping in code comments, populated from compiled-graph metadata at init via `BNNSGraphContextGetTensor`.
  - [ ] 5.3: Implement `evaluate(trace:)` body per AC #2:
    ```swift
    public func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
      guard let features = trace.mlFeatures else {
        Self.logNilFeaturesOnce()  // HALT (g) defensive log
        return nil
      }
      guard let inputTensor = featurize(features) else { return nil }
      guard let (bpm, confidence) = inferTempoCNN(inputTensor) else { return nil }
      guard confidence >= Self.confidenceThreshold else { return nil }  // DD #10 abstain
      return MLEvaluation(
        bpm: min(max(bpm, 60.0), 200.0),               // defense-in-depth clamp
        confidence: min(max(confidence, 0.0), 1.0),
        modelIdentifier: "bnns_tempo_v1")
    }
    ```
  - [ ] 5.4: Add `private static let confidenceThreshold: Double = 0.50` per DD #10. Doc-comment the rationale (Schreiber & Muller default; sidecar JSON override path documented as deferred-work).
  - [ ] 5.5: Add the HALT (g) defensive log: `private static func logNilFeaturesOnce()` uses a Swift static lazy property + `os_log(.fault, "...")` to guarantee one-shot logging per process lifetime. Doc-comment cites HALT (g).

- [ ] **Task 6: Add cancellation cooperation via private throws helper (AC: #9; resolves Story 4.3 deferred-work entry)**
  - [ ] 6.1: In `Sources/BoomBoomBoomKit/AudioAnalysisService.swift`, locate the IIFE-`guard` ML evaluation block at lines 311-317 (Story 4-4 close-out shape).
  - [ ] 6.2: Add `private static func evaluateMLIfActive(options:trace:) throws -> MLEvaluation?` in `extension AudioAnalysisService` (private static, same file, placed below `degradationMessage` near line 358). Body per AC #9 sketch:
    ```swift
    private static func evaluateMLIfActive(
      options: Options, trace: BPMDiagnosticTrace?
    ) throws -> MLEvaluation? {
      guard options.ensemblePolicy != .dspOnly,
            let ml = options.mlTechnique,
            let trace
      else { return nil }
      if options.isCancelled() { throw CancellationError() }
      return ml.evaluate(trace: trace)
    }
    ```
  - [ ] 6.3: Replace the IIFE-`guard` block at lines 311-317 with a single line: `let mlEvaluation = try evaluateMLIfActive(options: options, trace: corroborated.trace)`. `analyzeBPM` already `throws`, so no signature churn. The Story 4-4 A1 short-circuit invariant is preserved (helper's first guard returns nil before binding `ml`, so `evaluate` is unreachable on `.dspOnly`).
  - [ ] 6.4: Add a unit test `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift::cancellationBeforeMLEvaluateThrows` per AC #9 (NEW file per AC #10's new-files-only convention; uses `RecordingMockMLTechnique` from `BoomBoomBoomKitTestSupport`): `Options.isCancelled = { true }` + `Options.mlTechnique = RecordingMockMLTechnique()` + `Options.ensemblePolicy = .mlOnly` → `analyzeBPM` throws `CancellationError` AND `RecordingMockMLTechnique.callCount == 0`. ALSO add the contrapositive: `Options.ensemblePolicy = .dspOnly` (any cancellation closure) → `RecordingMockMLTechnique.callCount == 0` regardless (Story 4-4 AC #14 invariant preserved).
  - [ ] 6.5: Update `_bmad-output/implementation-artifacts/deferred-work.md`: mark the entry "Story 4.5/4.6 — Cancellation cooperation across `MLTechnique.evaluate` boundary" as **RESOLVED BY STORY 4.5** with this story's commit SHA cited at close-out. Note: the entry covers both 4.5 and 4.6; mark RESOLVED but leave a note that 4.6 inherits the fix (no separate entry needed).

- [ ] **Task 7: Add `make bnns-impact-report` Makefile target + impact-report `@Test` (AC: #7, #8)**
  - [ ] 7.1: Add `BNNS_IMPACT_OUT_DIR ?= $(CURDIR)/_bmad-output/implementation-artifacts` to the Makefile variable block at file-top (alongside `ML_MODEL_INPUT ?=` near `Makefile:5-9`) — per Amelia's correction that `?=` belongs at file-top, NOT in recipe body. Then add the `bnns-impact-report` target per AC #8 mirroring `click-impact-report` / `duration-impact-report` / `ml-policy-sweep` patterns at `Makefile:101-114`. Recipe uses `BNNS_IMPACT_OUT_DIR="$(BNNS_IMPACT_OUT_DIR)"` (not literal path) so the `make bnns-impact-report BNNS_IMPACT_OUT_DIR=/tmp/run1` override works.
  - [ ] 7.2: Create `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift` with a single env-gated `@Test bnnsImpactReport` per AC #8 schema. Pre-read each OA300 file once into `[TrackAudio]`; iterate surviving tracks; run `analyzeBPM(url:)` with `Options.mlTechnique = try? BNNSTechnique()` (skip the test entirely with `Issue.record("BNNSTechnique unavailable — model artifact missing")` if the conformance is nil); record per-track DSP-winner, ML-winner, ensemble-winner, ground-truth, latency. Emit JSON via `JSONEncoder` with `outputFormatting = [.prettyPrinted, .sortedKeys]`.
  - [ ] 7.3: Add per-track ground-truth lookup: read `_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json` for the 4 named tracks; for non-named tracks use the existing OA300 ground-truth lookup (`Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` per Story 2-4).
  - [ ] 7.4: Compute named-track resolution: for each of the 4 named tracks, check `abs(ensemble_winner - ground_truth) < 0.5`. Aggregate the count. Assert `resolvedCount >= 2` (HALT (b) — fail loudly with the per-track breakdown logged via `Issue.record` so the dev can document failure modes).
  - [ ] 7.5: Verify byte-stability across two runs: `make bnns-impact-report BNNS_IMPACT_OUT_DIR=/tmp/run1 && make bnns-impact-report BNNS_IMPACT_OUT_DIR=/tmp/run2 && diff <(jq 'del(.all_tracks[].latency_ms)' /tmp/run1/4-5-bnns-impact-report.json) <(jq 'del(.all_tracks[].latency_ms)' /tmp/run2/4-5-bnns-impact-report.json)` returns empty. Document the wall-clock asymmetry (latency is excluded from byte-stability; everything else is byte-stable).

- [ ] **Task 8: Unit tests in NEW files only (AC: #1, #2, #3, #4, #5, #9, #10; DD #15, #16)**

  Per AC #10's new-files-only convention (Amelia's option (a) for mechanical diff-scope verifiability), ALL new tests go in NEW files. ZERO modifications to existing test files.

  - [ ] 8.1: Create `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift` (combined service-integration + unit tests):
    - `initReturnsNilWhenResourceMissing` — `try? BNNSTechnique()` returns nil when CI lacks the artifact (the default state).
    - `initThrowsWhenResourceMissing` — `try BNNSTechnique()` throws `BNNSTechniqueError.modelResourceMissing`.
    - `bnnsTechniqueConformsToMLTechnique` — compile-time conformance witness via generic helper (Codex P13): `func assertMLTechnique<T: MLTechnique>(_: T.Type) {}` then `assertMLTechnique(BNNSTechnique.self)`. NO runtime init — pure type-check.
    - `evaluateReturnsNilWhenFeaturesAbsent` — manually constructed `BPMDiagnosticTrace()` with `mlFeatures = nil` returns nil from `evaluate(trace:)` (HALT (g) defensive path; only runs when the model artifact is available locally — guarded by `try? BNNSTechnique()` returning non-nil; otherwise `Issue.record` skip).
    - `featurizeShapeIsCorrect` — synthetic `MLFeatureFrames(melBands: 128, frames: 200, ...)` produces a `[Float]` of length `65536` (1×1×128×512) after z-score + resample (only runs when model is local).
    - `featurizeRejectsShortClips` — synthetic `MLFeatureFrames(melBands: 128, frames: 24, ...)` (frames < 32) → `evaluate(trace:)` returns nil per DD #9 short-clip guard (only runs when model is local).
    - `confidenceBelowThresholdAbstains` — synthetic featurize input + a model that produces softmax max < 0.50 → `evaluate(trace:)` returns nil (only runs when model is local).
    - `dspOnlyByteIdenticalWithBNNSAvailable` — per AC #5: synthetic click-track fixture + `Options.mlTechnique = try? BNNSTechnique()` + `Options.ensemblePolicy = .dspOnly` → `result.bpm.bitPattern == baselineResult.bpm.bitPattern`. Test runs in BOTH CI (where `try?` returns nil) AND locally (where it returns a real instance).
    - `cancellationBeforeMLEvaluateThrows` — per AC #9: `Options.isCancelled = { true }` + `Options.mlTechnique = RecordingMockMLTechnique()` + `Options.ensemblePolicy = .mlOnly` → `analyzeBPM` throws `CancellationError` AND `RecordingMockMLTechnique.callCount == 0`. Uses `RecordingMockMLTechnique` from TestSupport — does NOT require a real `BNNSTechnique` instance.
    - `cancellationDoesNotInvokeMLOnDspOnly` — Story 4-4 AC #14 invariant preserved: `Options.ensemblePolicy = .dspOnly` + `Options.isCancelled = { true }` + `Options.mlTechnique = RecordingMockMLTechnique()` → `analyzeBPM` returns normally (helper's first guard returns nil before reaching cancellation check) AND `RecordingMockMLTechnique.callCount == 0`.
    - `storageDeinitFreesGraphData` — RAII witness per DD #15: spawn a `BNNSTechnique` instance in a tight scope, hold a weak reference to its `BNNSGraphHandle` via reflection or an internal hook, drop the strong reference, verify `BNNSGraphHandle.deinit` ran (this is the C-interop discipline test Winston elevated). Only runs when model is local.
    - `concurrentEvaluateIsContextLocal` — concurrency exposure per axiom-concurrency #5. Run 16 concurrent `evaluate(trace:)` calls against the same `BNNSTechnique` instance via `withTaskGroup`; assert all 16 produce bitwise-identical output (proves per-call context isolation). Runs under `swift test --sanitize=thread` in the gating checklist (AC #11). Only runs when model is local; `Issue.record` skip otherwise.
    - `availableOnMacOS15` — `@available(macOS 15.0, *)` compile-gate witness (Siri's defense-in-depth recommendation). Trivial test that imports `BNNSTechnique` to assert it's reachable on macOS 15.0+.
  - [ ] 8.2: Create `Tests/BoomBoomBoomKitTests/MLFeatureFramesTests.swift`:
    - `initPreconditionRejectsZeroMelBands` — `MLFeatureFrames(melBands: 0, ...)` fatals (using `expectFatalError` pattern or precondition test wrapper).
    - `initPreconditionRejectsZeroFrames` — `MLFeatureFrames(frames: 0, ...)` fatals.
    - `initPreconditionRejectsLayoutMismatch` — `MLFeatureFrames(logMelData: <wrong-size>)` fatals (count != melBands * frames).
    - `initPreconditionRequiresNCHW` — `MLFeatureFrames(tensorLayout: .nhwc-future-case-if-added)` fatals; until other cases land, this test is a placeholder.
    - `equatableHonorsLogMelData` — two `MLFeatureFrames` with identical fields are equal; differing on any field are not.
    - `descriptionFormat` — description string contains `melBands`, `frames`, `tensorLayout`, `featureSetVersion` literals; element count of `logMelData` is shown; full `[Float]` payload is NOT printed (truncated).
    - `tensorLayoutIsCaseIterable` — `TensorLayout.allCases.count == 1` (initial case set per DD #14).
    - `retainedSpectrogramIsBitExactPostVvlogf` — per AC #5 / Codex P7 / HALT (h): invokes `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` with `captureMLFeatures: true` on a synthetic deterministic input via `@testable import`; captures `logOutput` immediately after `vvlogf` (line 583) BEFORE temporal-difference loop (line 603); asserts `MLFeatureFrames.logMelData` equals flattened retained log-mel frames element-by-element.
    - `mlFeaturesNilWhenCaptureFlagOff` — `analyzeBPM` with `Options.mlTechnique = nil` → `result.trace?.mlFeatures == nil`.
    - `mlFeaturesPopulatedWhenCaptureFlagOn` — `analyzeBPM` with `Options.mlTechnique = MockMLTechnique()` + `Options.ensemblePolicy = .mlOnly` + `Options.enableTrace = true` → `result.trace?.mlFeatures != nil` AND `result.trace?.mlFeatures?.melBands == 128` AND `result.trace?.mlFeatures?.featureSetVersion == "v1"`. Uses existing `MockMLTechnique` — no model artifact required.
  - [ ] 8.3: Run `make test`. Capture exact `@Test(` count via `rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l` (must be in band `[370, 378]` per DD #13 / AC #11). If outside band, investigate before proceeding (missed test, accidental duplicate, removed assertion).
  - [ ] 8.5: Add the cancellation test from AC #9 / Task 6.4 to `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift::cancellationBeforeMLEvaluateThrows`.
  - [ ] 8.6: Run `make test`. Capture exact `@Test(` count via `rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l` (must be in band `[365, 375]` per DD #13). If outside band, investigate before proceeding.

- [ ] **Task 9: Capture diff-scope proof artifact (AC: #10)**
  - [ ] 9.1: Run `git diff --stat <Task-1-pre-source-SHA>..HEAD` and capture stdout to `_bmad-output/implementation-artifacts/4-5-diff-scope-proof.txt`.
  - [ ] 9.2: Append `git status -- Sources/` output under a `# Section: untouched files verification` header. Verify NO file is modified outside the AC #10 list.
  - [ ] 9.3: Append `grep -rn "BNNSFilterCreate" Sources/BoomBoomBoomKitML/` output (must be zero matches per AC #1).
  - [ ] 9.4: Append `grep -rn "AudioAnalysisService.combine\|Self.combine" Sources/ Tests/` (must remain zero matches — Story 4.5 doesn't touch the ensemble combiner).
  - [ ] 9.5: Append the trace-field audit output (recipes A-E from `.claude/skills/bpm-diagnostic-trace/SKILL.md`) — must be zero matches.
  - [ ] 9.6: Append `swift package show-dependencies --format json | jq '.dependencies | length'` — must be `0`.

- [ ] **Task 10: Standard gating checklist + Completion Notes (AC: #5, #7, #11)**
  - [ ] 10.1: Run `make fmt`. Verify zero diff.
  - [ ] 10.2: Run `make lint`. Verify only the pre-existing `LUFSAnalyzer.swift:94` TODO baseline.
  - [ ] 10.3: Run `make test`. Capture exact `@Test(` count + zero failures.
  - [ ] 10.4: Run `make benchmark`. Verify byte-identity vs `4-5-regression-snapshot.json` for the `mlTechnique == nil` path. Capture Acc1=N/82, Acc2=N/82.
  - [ ] 10.5: Run `make benchmark-giantsteps`. Same byte-identity check. Capture Acc1=N/661, Acc2=N/661.
  - [ ] 10.6: Run `make ablation`. Verify `.optimal` Acc1=55/82 (or post-Story-3-2 floor) holds. Verify 128 combos complete without crashes.
  - [ ] 10.7: Run `make perf-benchmark`. Verify mock-on-abstain ratio remains ≤ 1.20x.
  - [ ] 10.8: Run `make bnns-impact-report` (requires the real model artifact). Verify per-track JSON output + named-track resolution count `<N>`/4. If `<N> < 2`, HALT (b) — pivot to Branch C close-out (do NOT silently continue).
  - [ ] 10.9: `swift build --target BoomBoomBoomKit` + `BoomBoomBoomKitTestSupport` + `BoomBoomBoomKitML` — all succeed; verify zero new SPM deps.
  - [ ] 10.10: Update Completion Notes with exact integer counts for ALL gates (test count, OA300 Acc1/Acc2, GiantSteps Acc1/Acc2, ablation `.optimal` Acc1, perf-benchmark ratio, BNNS-on Acc1/Acc2 at default config, named-track resolution `<N>`/4, BNNS inference wall-clock per track median).
  - [ ] 10.11: Commit the source changes + tests + Makefile + artifacts as a single commit: `Story 4-5: BNNS MLTechnique conformance + ML feature trace plumbing` (mirrors Story 4-4 commit pattern).
  - [ ] 10.12: Move the story to `review` status. Run `/bmad-code-review _bmad-output/implementation-artifacts/4-5-bnns-mltechnique-conformance.md` per the project workflow.
  - [ ] 10.13: At close-out: announce which Branch (A/A'/B/C) Story 4.6 will inherit, per `epics.md:1102-1127`. Record this in Completion Notes — the SM enforces the dependency manually until `sprint-status.yaml` schema supports `depends_on`.

- [ ] **Task 0 (NEW per codex Item 1, 2026-05-09 cohesion review): Finalize public `MLTechnique` protocol + `MLTechniqueError` enum (AC: #12)**
  - [ ] 0.1: Locate the existing `MLTechnique` protocol declaration (Story 4.3 — likely `Sources/BoomBoomBoomKit/MLTechnique.swift` or in `DSPTechnique.swift`; verify exact location at task start). Promote / freeze the public surface per DD #18 verbatim shape: `func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?`, `: Sendable`, full DocC comment block.
  - [ ] 0.2: Create `Sources/BoomBoomBoomKit/MLTechnique.swift` (if not already there) hosting both the protocol AND the new `public enum MLTechniqueError: Error, Sendable` per DD #20 (4 cases: `modelResourceMissing(URL)`, `modelLoadFailed(underlying: any Error)`, `invalidTensorContract(missing: String)`, `binCountMismatch(expected: Int, actual: Int)`).
  - [ ] 0.3: Add a compile-time witness `Tests/BoomBoomBoomKitTests/MLTechniqueProtocolTests.swift` per AC #12: `assertMLTechnique<T: MLTechnique>(_: T.Type) {}` invoked against `BNNSTechnique.self`, `MockMLTechnique.self`, and a hypothetical `class TestCustomTechnique: MLTechnique` declared inside the test (proves consumer-conformability without any runtime call).
  - [ ] 0.4: Verify project-wide: `grep -rn "MLTechnique" Sources/` lists the protocol declaration + `Options.mlTechnique` field + the `BNNSTechnique` conformance. No stray declarations.
  - [ ] 0.5: This task BLOCKS Tasks 2-9. The protocol shape is the contract everything else depends on; if the surface is wrong, every downstream task ships against an incorrect contract.

- [ ] **Task 11 (NEW per codex Item 3 + Item 5, 2026-05-09 cohesion review): `BNNSTechnique.init(modelURL:) throws` + `validateContract` runtime invariant (AC: #13)**
  - [ ] 11.1: Modify the existing `BNNSTechnique.init() throws` (Story 4.1 placeholder + DD #5 here) to `init(modelURL: URL = Self.bundledReferenceURL) throws`. Add `static let bundledReferenceURL: URL = Bundle.module.url(forResource: "giantsteps_v1", withExtension: "mlmodelc")!` (force-unwrap is safe because Story 4.1 ships `.copy("Resources")` discipline + Story 4-4b ships the `.mlmodelc` directory).
  - [ ] 11.2: Implement `private static func validateContract(graph: bnns_graph_t) throws` per DD #20 (full body in the DD). Call it from `init(modelURL:)` BEFORE caching `srcIndex` / `dstIndex`. If validateContract throws, `init` propagates the throw (caller decides via `try?` or strict `try`).
  - [ ] 11.3: Add fixture `.mlmodelc` to `Tests/Fixtures/` containing a tempo CNN with renamed output tensor (e.g., `var_42` instead of `output`) — used by AC #13's negative test. Generate via `tools/coreml-convert/` with explicit `ct.utils.rename_feature` rename of the output. Document the fixture's provenance in the test comment.
  - [ ] 11.4: Implement test `BNNSTechniqueTests/initThrowsOnMismatchedTensorNames` per AC #13 (asserts `MLTechniqueError.invalidTensorContract(missing: "output")` is thrown for the renamed-output fixture).
  - [ ] 11.5: Implement test `BNNSTechniqueTests/initAcceptsCustomModelURL` per AC #13 (passes a non-default URL, proves consumer-override works).
  - [ ] 11.6: Implement test `BNNSTechniqueTests/initThrowsOnBinCountMismatch` if a fixture with !=256 output bins can be cheaply produced (else mark as deferred-work; not blocking).

- [ ] **Task 12 (NEW per codex Item 12, 2026-05-09 cohesion review): Public DocC on new types (AC: #14)**
  - [ ] 12.1: Author DocC comment blocks for: `MLTechnique` protocol, `MLTechniqueError` enum, `BNNSTechnique` struct, `MLFeatureFrames` struct, `TensorLayout` enum, `Options.mlTechnique` field. Each comment block per AC #14.
  - [ ] 12.2: Run `swift package generate-documentation` and verify each new type renders with its own DocC page (no broken cross-references, no missing parameter docs).
  - [ ] 12.3: Verify each DocC comment block links to `tools/coreml-convert/README.md` (the canonical consumer-onboarding doc per codex Item 14).

- [ ] **Task 13 (NEW per codex Items 13, 14, 15-MOD, 2026-05-09 cohesion review): Back-propagate API names + workflow diagram + license matrix to `tools/coreml-convert/README.md` (AC: #15, #16, #17)**
  - [ ] 13.1: Open `tools/coreml-convert/README.md` (committed by Story 4-4b Task 11.7 with placeholders). `grep -rn "FINALIZED-BY-4-5" tools/coreml-convert/` lists all placeholder markers. Replace each with the actual Swift API name settled in Task 0 / Task 11 (`BNNSTechnique`, `Options.mlTechnique`, `MLTechniqueError`).
  - [ ] 13.2: Verify each of the four worked examples in the README compiles end-to-end: write a scratch consumer Swift package that imports BoomBoomBoomKit + BoomBoomBoomKitML, copy each example's code, run `swift build`. Capture the scratch package's commit SHA in Completion Notes (proves the examples are not broken at landing time).
  - [ ] 13.3: Add the unified workflow diagram per AC #16 to `tools/coreml-convert/README.md` (placement: in the README's "How it works" section, near the top so consumers see it before the worked examples).
  - [ ] 13.4: Add the license matrix per AC #17 to `tools/coreml-convert/README.md` opening (within the first 30 lines, before any code examples). Include the softened Path C language ("may impose AGPL obligations; consult counsel") and the BoomBoomBoomKit-makes-no-representation disclaimer.
  - [ ] 13.5: Verify `grep -rn "FINALIZED-BY-4-5" tools/coreml-convert/` returns empty (AC #15 zero-marker gate).
  - [ ] 13.6: Add a one-paragraph "Using your own tempo model" section to top-level `README.md` linking to `tools/coreml-convert/README.md` (single sentence + diagram link, NOT duplicating the worked examples).

## Dev Notes

### Architecture compliance

- **ADR-4 (Eager model loading at conformance init)** — `architecture.md:222-227`. Story 4.5 implements ADR-4 verbatim: `BNNSTechnique()` loads the model in `init() throws` from `Bundle.module`. Consumer creates the conformance once, passes it to `analyzeBPM`. Graceful degradation via `try? BNNSTechnique()` returning nil.
- **ADR-5 (Configurable ML ensemble voting policy)** — `architecture.md:229-232`. Story 4.4 closed the policy surface; Story 4.5 ships a real `MLTechnique` against it. The impact-report uses `.mlOnly` to isolate the ML signal; production consumers may pick `.highestConfidence` based on Story 4.5 ablation evidence.
- **ADR-6 (Always populate trace when ML technique is present) — INHERITED from Story 4-4 reconciliation.** Story 4.4 reconciled this to: trace built when `mlTechnique != nil` AND `ensemblePolicy != .dspOnly`. Story 4.5 EXTENDS this: when those conditions hold AND the trace is built, `BPMAnalyzer.Options.captureMLFeatures` is also set, populating the new `MLFeatureFrames` field. The `mlFeatures` field is gated by the same `shouldBuildTrace` predicate — DSP-only path is bit-exact to pre-Story-4.5.
- **ADR-11 (Options-first public configuration)** — `architecture.md:247-256`. Story 4.5 does NOT add a new public Options field. The `captureMLFeatures` flag is internal-only (DD #4) — it's not a consumer-facing knob, so it does not extend the public surface.
- **Post-Pipeline Corroboration Boundary** — project-context.md §"Post-Pipeline Corroboration Boundary". Pipeline ordering is unchanged from Story 4-4: `merge → MetadataCorroborator.apply → MLTechnique.evaluate → EnsembleCombiner.combine → AudioAnalysisResult`. Story 4.5 lands a real `MLTechnique` against this contract.
- **Banned trace-field shapes** — project-context.md §"Banned trace-field shapes". The new `MLFeatureFrames` struct passes the typed-evidence rule (named `Sendable` value type, no `[String: Any]`, no stringified-numeric values). The four banned shapes audit (recipes A-E) MUST return zero matches before merge.

### Source pointers (verified at story authoring 2026-05-08)

- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` (28 lines, Story 4.1 placeholder; entire file rewritten by Task 4)
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift`:
  - Line 148 — current `ensembleDecision: EnsembleDecision?` field (Story 4.4); the new `mlFeatures` field lands AFTER this with a new `// MARK: - Story 4.5: ML Feature Frames` section
  - Lines 297-338 — `SubBandEnergies` struct (Story 4-3b); `MLFeatureFrames` and `TensorLayout` land after this, mirroring the placement convention
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`:
  - Lines 488-700+ — `computeMelOnsetEnvelopeWithSubBands` (the function Task 3 modifies)
  - Lines 535-585 — `logMelFrames` construction (the intermediate Task 3 retains)
  - Line 583 — `vvlogf` (the log step that already ships per DD #3)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift`:
  - Lines 289-291 — `shouldBuildTrace` predicate (Story 4-4 A1 short-circuit shape; Task 3.4 mirrors this for `captureMLFeatures`)
  - Lines 311-317 — IIFE-`guard` ML evaluation block (Story 4-4 close-out shape; Task 6.2 inserts the cancellation check inside this body)
- `Sources/BoomBoomBoomKit/DSPTechnique.swift`:
  - Lines 201-233 — `MLEvaluation` struct (Story 4.3) — UNCHANGED in Story 4.5
  - Lines 256-262 — `BNNSGraphContextExecute` synchronous-by-design DocC reference for Task 4.5 doc-comment
  - Lines 278-290 — `MLTechnique` protocol (Story 4.3) — UNCHANGED
- `Sources/BoomBoomBoomKitTestSupport/MockMLTechnique.swift` — UNCHANGED. Used by Task 8.4 (`mlFeaturesPopulatedWhenCaptureFlagOn`) to validate the capture flag without requiring a real model.
- `Makefile:101-114` — `click-impact-report` and `duration-impact-report` targets are the structural template for Task 7.1.
- `_bmad-output/implementation-artifacts/4-4-configurable-ml-ensemble-voting-policy.md` — Story 4.4 close-out (immediate predecessor; ensemble policy + combiner + cancellation deferred-work entry).
- `_bmad-output/implementation-artifacts/4-3-ml-technique-slot-wiring-and-tuple-to-struct-migration.md` — Story 4.3 (`MLTechnique` protocol shape + `MLEvaluation` struct + IIFE call site).
- `_bmad-output/implementation-artifacts/4-1-boomboomboomkitml-package-structure.md` — Story 4.1 (`BNNSTechnique.swift` placeholder + Makefile `compile-model` target + `giantsteps_v1.mlmodelc` resource convention).
- `_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json` — pre-promotion gate artifact (DD #1).

### Why `MLFeatureFrames` lives in `BPMDiagnosticTrace.swift` (and not its own file)

Three reasons:
1. **Symmetry with the typed-evidence pattern** — Story 3-3b precedent. `ClickCorrelationEntry`, `HarmonicRatioEvidence`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`, `SubBandEnergies` all live in `BPMDiagnosticTrace.swift` alongside the trace struct that owns them. `MLFeatureFrames` follows the convention.
2. **DocC discoverability** — types co-located with their owning struct render under the same DocC page; consumers don't have to navigate to a sibling file.
3. **Encapsulation discipline** — the new types are tightly coupled to `BPMDiagnosticTrace` ownership semantics (only the trace owns `mlFeatures`); a separate file would invite drift if a future story misuses the type outside the trace context.

### Why z-score normalization happens INSIDE `BNNSTechnique.evaluate`, not in `BPMAnalyzer`

Two reasons:
1. **DSP pipeline ML-agnosticism.** `BPMAnalyzer` produces the log-mel-spectrogram intermediate; what consumers do with it is their choice. Story 4.6 (CoreML) MAY use a different normalization (e.g., per-frequency-bin instead of per-mel-band) — pushing normalization into `BPMAnalyzer` would force both stories to share or branch on a normalization mode. Keeping it inside the conformance avoids the coupling.
2. **Reproducibility hygiene.** The frozen baseline at Task 1 captures `Options.mlTechnique == nil` per-track BPMs; if normalization were in `BPMAnalyzer`, a future change to the normalization algorithm would mutate trace contents even when ML is disabled (because the trace would carry post-normalization features). Keeping normalization in the conformance means the trace carries raw log-mel; consumers can re-normalize freely without affecting baseline reproducibility.

### Risk / out-of-scope guards

- **Do NOT** modify `MLEvaluation` (keep the struct shape Story 4-3 shipped). The clamp on `bpm` and `confidence` is defense-in-depth in `BNNSTechnique.evaluate`, not a struct-level change.
- **Do NOT** modify `MLTechnique` protocol shape. The protocol input is still `BPMDiagnosticTrace`; the return is still `MLEvaluation?`.
- **Do NOT** change pipeline ordering (per Story 4-4 DD #5).
- **Do NOT** add new `EnsemblePolicy` cases. Story 4-4 closed the case set; new cases ship per Story 4.4 DD #13 forward-pointer in a follow-up.
- **Do NOT** introduce a `DSPTechnique` case for ML — ML is orthogonal (per project-context.md §"Critical Don't-Miss Rules": "Metadata is NOT a `DSPTechnique` case... Same applies to ML"). The 128-combo ablation invariant is unit-test-locked; Story 4.5 does NOT touch it.
- **Do NOT** modify `Sources/BoomBoomBoomKitML/CoreMLTechnique.swift` (Story 4.6's domain). Story 4.5 ships ONLY the BNNS conformance.
- **Do NOT** rename `BNNSTechnique` (Story 4.1 shipped this; pre-1.0 allows rename but no story-level reason to do so here).
- **Do NOT** promote `MLFeatureFrames` to the ML target — it's a core-target type because the trace lives in core. Both `BNNSTechnique` (BoomBoomBoomKitML) and `MockMLTechnique` (BoomBoomBoomKitTestSupport) consume it via `BoomBoomBoomKit` import.
- **Do NOT** change the `giantsteps_v1.mlmodelc` resource name (Story 4.1 settled this convention; renaming would require updating the Makefile defaults + `compile-model` target documentation).
- **Do NOT** add training infrastructure to the repo. Model training is out of scope per `epics.md:1090`. The `.mlmodelc` artifact is acquired externally and dropped in via `make compile-model`.

### Apple-platform notes

- **BNNSGraph minimum macOS = 15.0+ exactly** (axiom-apple-docs CRITICAL #3 / Codex P-CRITICAL-3 — earlier "macOS 14+" was wrong). All four BNNSGraph symbols verified macOS 15.0+ via apple-docs MCP 2026-05-08: `BNNSGraphCompileFromFile`, `BNNSGraphContextMake`, `BNNSGraphContextExecute`, `bnns_graph_t`. Project floor `.macOS(.v15)` exactly satisfies. The `BoomBoomBoomKitML` target inherits the package-level platform constraint; **`@available(macOS 15.0, *)` is added to `BNNSTechnique` and its public init as defense-in-depth per Siri's recommendation** — guards against any future story dropping the package floor. The deferred-work entry "Per-target `platforms:` constraint for BNNS / CoreML availability" is closed by Story 4.5 (satisfied by project floor + per-type `@available`).
- **Swift overlay locked out by macOS 26 floor** — `BNNSGraph.Context(contentsOf:)`, `BNNSGraph.Builder`, and `BNNSGraph.makeContext` are all `@available(macOS 26.0, ...)` per `Accelerate.swiftmodule` SDK evidence (lines 14705-14716, verified 2026-05-08). The macOS 15 SDK only exposes `BNNSGraph.Context.init(compileFromPath:options:) async throws` — async-only; Story 4.5's `init() throws` is sync per ADR-4. Use raw C path until macOS 26 minimum.
- **Synchronous-by-design** — `BNNSGraphContextExecute` is synchronous per **WWDC 2024 #10211 "Support real-time ML inference on the CPU"** (title verified via `mcp__apple-docs__get_wwdc_video` 2026-05-08; the original spec-creation-time attribution "Bring your ML models to Apple silicon" was a fabrication, possibly conflated with WWDC 2024 #10223 "Explore machine learning on Apple platforms" — corrected throughout this spec). Cited in `Sources/BoomBoomBoomKit/DSPTechnique.swift:256-262`. `evaluate(trace:)` is intentionally synchronous; no `await` boundary inside the conformance.
- **BNNSGraph CPU-only** — Per WWDC 2024 #10211 framing: BNNSGraph executes on CPU only. ANE (Neural Engine) inference requires CoreML and is reserved for Story 4.6. NCHW vs NHWC layout is irrelevant for BNNSGraph CPU; the layout choice in DD #8 is locked for symmetry with Story 4.6's `MLShapedArray` (not for ANE-friendliness — the Story 4.5 path is CPU regardless).
- **`bnns_graph_argument_t` for graph execute, NOT `BNNSNDArrayDescriptor`** — Apple's documented `BNNSGraphContextExecute` example uses `BNNSTensor` wrapped in `bnns_graph_argument_t.tensor = pointer`. `BNNSNDArrayDescriptor` is the classic-API descriptor (used by deprecated `BNNSFilter*Layer*` calls); mixing it with graph execute is awkward and inconsistent with Apple's pattern. Construct `BNNSTensor(shape: ..., data_type: .float, layout: ..., stride: ...)` and place in `[bnns_graph_argument_t]` indexed by positions resolved at init via `BNNSGraphGetArgumentPosition` (DD #16). Set `BNNSGraphContextSetArgumentType(context, BNNSGraphArgumentTypeTensor)` once before execute (matches WWDC sample).
- **vDSP normalization primitives** — `vDSP_meanv` (per-row mean) + `vDSP_normalizev` (z-score in-place; takes pointers to `mean` and `stddev` outputs); chained per row via a row-stride loop. Apple's vDSP `normalizev` is the canonical z-score primitive; manual `(x - mean) / stddev` loops are NOT acceptable per project-context.md §"No manual loops over signal data".
- **`vDSP.linearInterpolate(elementsOf:using:result:)` for temporal resampling** (DD #9; macOS 10.15+ per Siri — wraps `vDSP_vlint`). Implementation: 128 row loops, precomputed 512-element control vector (fractional source indices reused across all bands). **Gotchas (Siri-flagged):** zero-length inputs trap (do NOT return empty); preconditions on `result.count == using.count` and `elementsOf.count >= ceil(max(using)) + 2` — guard at call site for short clips (DD #9 short-clip rejection at `frames < 32` covers this). Do NOT use `vDSP.linearInterpolate(values:atIndices:result:)` — that's the sparse-known-values path (`vDSP_vgenp`), wrong shape for fixed-grid resampling. Do NOT use `vImageScale_PlanarF` — image-scaling abstraction wrong-fits "resize 128×N to 128×512 along time only".
- **`URL.path()` is the modern percent-decoded form** (axiom-apple-docs MAJOR #6 + Siri); `URL.path` (the property) was deprecated in macOS 13 / iOS 16 in favor of `path(percentEncoded: Bool = true)`. For filesystem paths use `path(percentEncoded: false)` or the no-arg `path()` form. Story 4.5 init uses `url.path()` — Task 4.2 sketch reflects this. There is no SwiftLint rule for this; manual review or a custom regex (`\.path\b(?!\()`) is the path.
- **Swift 6 strict concurrency for the C-handle struct (DD #15 + axiom-concurrency)** — `BNNSTechnique` is `public struct` + `@unchecked Sendable` (NOT `nonisolated(unsafe)` — that's reserved for sync-only callbacks, test closures, and `FileMetadataReader` scratch buffers per project-context.md). The struct holds `private let handle: BNNSGraphHandle` — a `final class @unchecked Sendable` with `deinit { free(graph.data) }`. The graph is immutable post-compile; per-call `bnns_graph_context_t` is constructed via `BNNSGraphContextMake` and destroyed via `defer { BNNSGraphContextDestroy(&context) }` inside `evaluate(trace:)` — no shared mutable state across concurrent callers. Apple's `BNNSGraphContextExecute` documentation says "You may only use this context on a single thread at a time" — Shape A-prime sidesteps the constraint by per-call construction (no lock contention; full fan-out parallelism).
- **`MLShapedArray<Float>` strides for Story 4.6 inheritance** (axiom-apple-docs MINOR #7) — `MLShapedArray` IS row-major C-order by default (Apple docs example: "C × H × W"), but does NOT allow setting non-contiguous strides at init. Story 4.6 constructs `MLShapedArray<Float>(shape: [1, 1, 128, 512])` and lets the type collapse strides to contiguous. Story 4.5's explicit stride array is for `BNNSTensor` only; do NOT thread it forward to CoreML.

### Previous Story Intelligence

From Story 4.4 (commits `757d57c` Task 1 baseline + the in-tree close-out source at HEAD; logical status `done`):
- **Test count baseline:** Story 4.4 closed at **357** tests in `Tests/BoomBoomBoomKitTests` (verified by Amelia 2026-05-08 via `rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l` at HEAD `757d57c` — the earlier "355" figure was stale from Story 4-4's interim Completion Notes). Story 4.5 band: **`[370, 378]`** per DD #13 (revised from `[365, 375]`).
- **Pattern REPLACED — IIFE-`guard` → private throws helper.** Story 4-4 Task 4.5 settled the IIFE shape after Codex D1 caught a `?.flatMap` Swift bug. Story 4.5 REPLACES the IIFE with a `private static func evaluateMLIfActive(options:trace:) throws -> MLEvaluation?` helper (Codex MAJOR #8 / Amelia: IIFE-with-cancellation forces a control-flow smell because the IIFE returns `MLEvaluation?` and can't throw cleanly). The Story 4-4 A1 short-circuit invariant (`RecordingMockMLTechnique.callCount == 0` on `.dspOnly`) is preserved by the helper's first `guard` clause.
- **Pattern reuse — `JSONEncoder` byte-stable output.** Story 4-4 Task 6.5 used `outputFormatting = [.prettyPrinted, .sortedKeys]` for the `ml-policy-sweep` artifact; Story 4.5 Task 7.2 uses the identical pattern for the impact report.
- **Pattern reuse — env-gated `@Test` + `make X-impact-report` Makefile target.** Story 3-3 (click-impact-report), Story 3-4 (duration-impact-report), Story 4-4 (ml-policy-sweep). Story 4.5 follows the same template for `bnns-impact-report`.
- **Architecture invariant test venue.** `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` is the standing venue for `*.allCases.count == N` invariants. Story 4.5 adds the `TensorLayout.allCases.count == 1` invariant here per DD #13.
- **Cancellation-test pattern.** `RecordingMockMLTechnique.callCount == 0` per Story 4-4 AC #14 — the canonical "MockMLTechnique was NOT invoked" assertion. Story 4.5 Task 6.4 reuses for the cancellation test.
- **Trace-field audit recipes.** `.claude/skills/bpm-diagnostic-trace/SKILL.md` recipes A-E. Story 3-3b is the canonical migration; Story 4-3b's `subBandEnergies` was the most recent typed-evidence migration. Story 4.5 Task 2.4 runs the same audit before merge.
- **Pre-source baseline commit pattern.** Story 4-3 Task 1 (`9fd7c44`) and Story 4-4 Task 1 (`757d57c`) both committed pre-source artifacts as a separate commit BEFORE source edits. Story 4.5 Task 1.6 follows the same convention.

From Story 4.3 (commit `c1ba272`, completed 2026-05-05):
- **`MLEvaluation` struct shape is frozen.** Three fields (`bpm`, `confidence`, `modelIdentifier`); pre-1.0 allows extension but Story 4.5 does NOT extend.
- **Cancellation deferred-work entry filed at this story's review.** Story 4.5 resolves it per Task 6.5.

From Story 4.1 (commit `29ced70`, completed 2026-05-04):
- **`giantsteps_v1.mlmodelc` resource convention.** Story 4.5 reads `Bundle.module.url(forResource: "giantsteps_v1", withExtension: "mlmodelc")`. The Makefile `compile-model` target compiles `_bmad-output/ml-models/giantsteps_v1.mlmodel` → `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/`.
- **`.copy("Resources")` in `Package.swift`.** `.mlmodelc` is a directory tree; `.process` would flatten it. Story 4.1's `Package.swift` is correct. Story 4.5 does NOT modify `Package.swift`.
- **`Bundle.module` discipline.** `BoomBoomBoomKitML` ships its own `Bundle.module`; `BNNSTechnique` MUST use that target's `Bundle.module`, NEVER `BoomBoomBoomKit`'s. Verified at compile time — the core target has no `resources:` declaration so `BoomBoomBoomKit.Bundle.module` would be a compile error.

### Stakeholder Voices (added 2026-05-08 per Mary's roundtable framing — locked / inherited / free trifecta for Story 4.6)

Added per Mary's Pyramid Principle stakeholder analysis. The user story speaks as the library author; the broader stakeholder set:

- **Story 4.6 (CoreML) author** — **highest-priority downstream consumer.** Inherits the BNNSGraph + Shape A-prime architectural decisions Story 4.5 settles. **What 4.6 must NOT relitigate:** raw C-API choice (macOS 15 floor); public-struct + private RAII Storage class shape (DD #15); per-call context lifecycle; `free(graph.data)` discipline. **What 4.6 MUST inherit:** NCHW row-major shape ordering (DD #8); `MLFeatureFrames` semantic metadata struct shape (DD #2 — though 4.6 may bump `featureSetVersion` if it changes the feature pipeline); `giantsteps_v1.mlmodelc` resource convention; sidecar-threshold pattern (DD #10 — for symmetry; 4.6 reads `MLModel.modelDescription.metadata` first then falls back). **What 4.6 is FREE to redesign:** `MLShapedArray` strides (the type doesn't permit non-contiguous strides at init — Story 4.5's explicit stride array does NOT propagate); threshold source (CoreML reads embedded model metadata that BNNSGraph compile strips; 4.6 may drop the sidecar entirely); ANE optimization (BNNSGraph is CPU-only; 4.6 unlocks `.cpuAndNeuralEngine` `MLModelConfiguration`).
- **Story 4.7 (spectral-flux DSP variant) author** — sequencing-deferred per project-lead discretion. **What 4.7 inherits:** if it changes the pre-`vvlogf` mel pipeline (which is its design intent), `MLFeatureFrames.featureSetVersion` MUST bump to `"v2"` AND a full impact-report re-baseline is required. The trigger is encoded in DD #2 + DD #14 — removes ambiguity from the future author.
- **Epic 5 demo-app developer** — surfaces `MLFeatureFrames` and `BNNSTechnique` in the demo UI (likely a feature-visualizer view). Inherits the `Sendable, CustomStringConvertible, Equatable` conformance for SwiftUI bindings; the `featureSetVersion` field for human-readable diagnostics; the `try? BNNSTechnique()` graceful-degradation pattern for environments without the model artifact.
- **`BPMDiagnosticTrace` consumers (today: tests; future: debugger UI)** — inherit the new mandatory `mlFeatures: MLFeatureFrames?` field. Existing trace consumers are not broken (the field is optional); future consumers can rely on the typed-evidence shape for cross-validation.
- **External library consumers (out of scope pre-1.0)** — pre-1.0 framing per project-context.md "Public API Discipline" means BC is NOT a goal. External consumers reading the spec should expect type names, default thresholds, and tensor-layout choices to evolve in follow-up stories.

### DnB baseline coherence (Mary's "two baselines, two purposes")

Two baselines, two purposes, NEVER cross-validated:
1. **`_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json`** (frozen at SHA `9185698`) is the ACCURACY ORACLE. Compare absolute BPM errors (the named-track baseline DD #1). Re-running impact-report on HEAD will produce numerically different absolute errors than this JSON's `current_predicted_bpm` field — that's expected drift (spectrogram retention is new code), NOT regression.
2. **Element-wise byte-identity test** (Codex P7 / AC #5 / HALT (h)) is the COMPUTATIONAL ORACLE. Compare retained spectrogram element-by-element against post-`vvlogf` `logOutput`. Its baseline is captured at the retention-introduction commit (Story 4.5 Task 3), NOT at SHA `9185698`.

Completion Notes MUST document this distinction explicitly so future authors don't accidentally cross-validate.

### Git intelligence

Recent commits inform this story:
- `757d57c` Story 4-4 Task 1: pre-source-change baseline artifacts. **Pattern reuse:** Story 4.5 Task 1 follows the same convention.
- `aa786e3` Story 4-3b: perf-gate threshold tightening to 1.20x + `subBandEnergies` typed migration. Story 4.5 inherits the 1.20x perf threshold AND the typed-evidence migration discipline.
- `c1ba272` Story 4-3: ML technique slot wiring + tuple-to-struct migration. Story 4.5 ships the first real `MLTechnique` against the post-4.3 protocol.
- `9185698` Story 4.2: report effective intensity and graceful ML degradation. Story 4.5 does not touch `effectiveIntensity` or `degradationReason` (orthogonal).
- `29ced70` Story 4.1: scaffold `BoomBoomBoomKitML` SPM target. Story 4.5 promotes the `BNNSTechnique` placeholder to a real conformance.

### Project Structure Notes

After Story 4.5 source changes:
- `Sources/BoomBoomBoomKit/` contains the same 17 files as post-Story-4.4. Three are MODIFIED (`AudioAnalysisService.swift`, `BPMAnalyzer.swift`, `BPMDiagnosticTrace.swift`); zero new files (typed-evidence types co-locate with `BPMDiagnosticTrace`).
- `Sources/BoomBoomBoomKitML/` contains the same 2 files as post-Story-4.1. One is MODIFIED (`BNNSTechnique.swift`); `CoreMLTechnique.swift` is UNCHANGED.
- `Tests/BoomBoomBoomKitTests/` adds 2 new files: `BNNSTechniqueTests.swift`, `MLFeatureFramesTests.swift`. `MetadataCorroborationTests.swift` and `AudioAnalysisServiceTests.swift` are extended with one new invariant + cancellation test respectively.
- `Tests/BoomBoomBoomKitBenchmarkTests/` adds 1 new file: `BNNSImpactTests.swift`.
- `Sources/BoomBoomBoomKitTestSupport/` is UNCHANGED.
- `Package.swift` is UNCHANGED (no new targets, no new deps; BNNS is in `Accelerate` already linked via `BoomBoomBoomKitML`'s implicit Apple SDK access).

### References

- [Source: epics.md:986-1093] — Story 4.5 spec foundation; AC text + Branch A/A'/B/C definitions for Story 4.6 + HALT (b) trigger.
- [Source: epics.md:756-771] — Epic 4 preamble (Definitions: Asserted floors, Current snapshot, Byte-identical, Non-regression gate, Numeric delta gate, New Makefile targets).
- [Source: epics.md:1012-1041] — Pre-promotion ground-truth verification gate (DD #1).
- [Source: _bmad-output/planning-artifacts/architecture.md:222-227] — ADR-4 (Eager model loading at conformance init).
- [Source: _bmad-output/planning-artifacts/architecture.md:229-235] — ADR-5, ADR-6 (ML integration architecture).
- [Source: _bmad-output/planning-artifacts/architecture.md:247-256] — ADR-11 (Options-first public configuration).
- [Source: _bmad-output/project-context.md] — `Sendable`-discipline + value-types-only + zero-dependencies (§"Technology Stack & Versions"); §"Public API Discipline (pre-1.0)"; §"Post-Pipeline Corroboration Boundary"; §"Banned trace-field shapes" (governs the new `MLFeatureFrames` typed-evidence struct); §"Testing Rules" Swift Testing patterns + env-gated benchmarks; §"`nonisolated(unsafe)` discipline" (applies to `bnns_graph_t` C-interop).
- [Source: _bmad-output/implementation-artifacts/4-4-configurable-ml-ensemble-voting-policy.md] — Story 4.4 spec (immediate predecessor; A1 short-circuit + IIFE-`guard` shape + `EnsembleDecision` typed-evidence precedent).
- [Source: _bmad-output/implementation-artifacts/4-3-ml-technique-slot-wiring-and-tuple-to-struct-migration.md] — Story 4.3 spec (`MLTechnique` protocol shape + `MLEvaluation` struct + cancellation deferred-work entry).
- [Source: _bmad-output/implementation-artifacts/4-1-boomboomboomkitml-package-structure.md] — Story 4.1 spec (`BNNSTechnique.swift` placeholder + `giantsteps_v1.mlmodelc` resource convention + Makefile `compile-model` target + `Bundle.module` discipline).
- [Source: _bmad-output/implementation-artifacts/4-dnb-triplet-targets.json] — Pre-promotion gate artifact (`schema_version: 2`; committed at SHA `9185698`).
- [Source: _bmad-output/implementation-artifacts/deferred-work.md:244] — Story 4.5/4.6 cancellation cooperation entry (Story 4.5 resolves per Task 6.5).
- [Source: .claude/skills/bpm-diagnostic-trace/SKILL.md] — Typed-evidence pattern + four banned anti-patterns + five audit grep recipes (A-E) — required reading before adding `MLFeatureFrames`.
- [Reference: Schreiber & Muller (2018) "A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural Network"] — `https://archives.ismir.net/ismir2018/paper/000068.pdf` — shallow CNN architecture (log-mel-spectrogram → multi-filter conv → temporal pooling → dense → softmax over BPM bins). The reference implementation `https://github.com/hendriks73/tempo-cnn` provides a model the dev can convert via `coremltools` → `make compile-model` → `giantsteps_v1.mlmodelc`.
- [Reference: Apple BNNSGraph documentation] — `https://developer.apple.com/documentation/accelerate/bnns/graph` — `BNNSGraph.Builder`, `bnns_graph_t`, `BNNSGraphCompileFromFile`, `BNNSGraphContextExecute`, `BNNSNDArrayDescriptor` — the canonical API surface per DD #7.
- [Reference: WWDC 2024 #10211 "Support real-time ML inference on the CPU"] — `BNNSGraphContextExecute` synchronous-by-design rationale (cited in `Sources/BoomBoomBoomKit/DSPTechnique.swift:256-262`); the canonical compile/context split + per-call `BNNSGraphContextSetBatchSize` pattern. Title VERIFIED via `mcp__apple-docs__get_wwdc_video` 2026-05-08; the original story-creation-time attribution "Bring your ML models to Apple silicon" was a fabrication and has been corrected throughout the spec.
- [Reference: Bello et al. "A Tutorial on Onset Detection in Music Signals"] — Music-IR onset-detection literature for clipped-material handling; informs the log-mel-with-z-score feature design (DD #2).

## Dev Agent Record

### Agent Model Used

(Populated by the dev agent at close-out. Expected: Claude Sonnet 4.6 or Opus 4.7 via /bmad-dev-story workflow.)

### Debug Log References

(Populated by the dev agent during implementation.)

### Completion Notes List

(Populated by the dev agent at close-out. Expected entries: gating-checklist integers table, BNNS-on Acc1/Acc2 vs DSP-only, named-track resolution count `<N>`/4, BNNS inference wall-clock per track median, Branch A/A'/B/C decision for Story 4.6, deferred-work entries created, deferred-work entries resolved, post-review patch summary, commit SHAs.)

### File List

(Populated by the dev agent at close-out, mirroring Story 4-4's file-list shape: Modified Sources, New Sources, Modified Tests, New Tests, Modified Tests/Benchmark, Modified Makefile, New artifacts, Modified artifacts.)

## Change Log

- **2026-05-08 (Story 4-5 pre-implementation 4-layer review + party-mode finalization).** Comprehensive review pass BEFORE any source change, applied 14 patches:

  **Phase 1 — Parallel reviews (4 reviewers):**
  - Codex initial pass via `codex:consult` agent — produced 12 findings (3 CRITICAL, 8 MAJOR, 1 MINOR). Codex thread `019e0abf-48d8-7340-be9e-4fb3fb91675f`.
  - axiom-ai (on-device ML / BNNSGraph correctness) — produced 6 findings (2 CRITICAL, 3 MAJOR, 1 MINOR). Confirmed Codex CRITICAL #1/#2 with WWDC 2024 #10211 evidence. Recommended Swift overlay `BNNSGraph.Context` (later overruled by macOS-26 availability).
  - axiom-concurrency (Swift 6 strict-concurrency for C-interop) — produced 5 findings (2 CRITICAL, 1 MAJOR, 2 MINOR). Picked Shape A (struct + per-call context) over Shape B (final class + lock).
  - axiom-apple-docs (Xcode-bundled docs verification) — produced 8 findings (3 CRITICAL, 3 MAJOR, 2 MINOR). Provided verbatim Apple docs for `BNNSGraphCompileFromFile` / `BNNSGraphContextMake` / `BNNSGraphContextExecute` signatures. Verified macOS 15.0+ minimums and `classic-bnns-api` deprecation scope.

  **Phase 2 — Codex meta-synthesis** (`codex:consult` thread `019e0abf-48d8-7340-be9e-4fb3fb91675f`): resolved three disagreements with SDK-grounded evidence (`Accelerate.swiftmodule/arm64e-apple-macos.swiftinterface:3336-3372, 14705-14716`):
  - (a) **Raw C API wins.** `BNNSGraph.Context(contentsOf:)` and `BNNSGraph.Builder` are macOS 26.0+; the macOS 15 SDK only exposes `BNNSGraph.Context.init(compileFromPath:options:) async throws`. Story 4.5's sync `init() throws` requires the raw C path.
  - (b) **Shape A-prime wins** (neither original Shape A nor Shape B). Public struct + private `final class BNNSGraphHandle: @unchecked Sendable` for RAII (`deinit { free(graph.data) }` — fixes the graph-leakage bug all four single reviews missed) + per-call `bnns_graph_context_t` (no lock, full fan-out parallelism).
  - (c) **`vDSP.linearInterpolate(elementsOf:using:result:)` per row** (NOT `values:atIndices:result:`, NOT `vImageScale_PlanarF`).

  **Phase 3 — `/bmad-party-mode` roundtable** (Winston, Amelia, Mary, Siri):
  - Winston (Architect): Shape A-prime is right; `BNNSGraphHandle` better name than `Storage`; **CLOSE the Branch C plumbing-only escape hatch** (model required for promotion); multi-window option (a) — single ML eval on merged-winner trace; scope creep is real but patches are correctness fixes, not expansion. Elevation: graph-leakage discipline → project-context.md C-interop rule (any C-resource-owning type owns through `final class` with deinit exercised by ≥1 test).
  - Amelia (Dev): pre-story baseline is **357** (NOT 355 — verified via `rg`); new band **`[370, 378]`** (357 + 15 net additions); concrete cancellation helper signature accepts `BPMDiagnosticTrace?`; **Makefile `?=` belongs at file-top, NOT in recipe body** — Codex P10 was under-specified; AC #10 reconciliation: pick option (a), new files only.
  - Mary (Analyst): two baselines two purposes (DnB JSON = accuracy oracle; retention test = computational invariant; never cross-validate); Story 4.6 inheritance trifecta (locked / inherited / free); confidence-rule gap → MAJOR with explicit re-open trigger ("if any post-4.5 corpus run shows >2% Acc1 regression on clips <8s").
  - Siri (Apple Platform): **WWDC 2024 #10211 title is "Support real-time ML inference on the CPU"** (NOT "Bring your ML models to Apple silicon" — original attribution was a fabrication, possibly conflated with WWDC 2024 #10223; verified via `mcp__apple-docs__get_wwdc_video`); `URL.path` deprecated macOS 13+ → use `path()` modern form; sidecar JSON pattern is NOT Apple-canonical (Apple uses `MLModel.modelDescription.metadata` embedded); `vDSP.linearInterpolate(elementsOf:using:result:)` is macOS 10.15+, traps on zero-length input.

  **Phase 4 — 14 patches applied to spec:**
  - **MUST-FIX (4 CRITICALs):** P1 raw BNNS C API + macOS 15 floor + reject `BNNSGraph.Builder/Context(contentsOf:)/makeContext` (DD #7, AC #1, AC #2, Tasks 4 & 5, Apple-platform notes). P2 Shape A-prime — public struct + private `BNNSGraphHandle` final class + per-call context (DD #15 NEW, AC #1, Task 4.1). P3 close Branch C plumbing-only escape hatch — model required for promotion (DD #12 HALT (a') NEW, Task 1.5). P4 cancellation via private throws helper, not IIFE (DD #11, AC #9, Task 6).
  - **SHOULD-FIX (8 MAJORs):** P5 rename "pooling" → "resampling" + correct `vDSP.linearInterpolate` overload + short-clip guard at frames < 32 (DD #9). P6 `MLFeatureFrames` semantic metadata (`sampleRate`, `fftSize`, `hopSize`, `melFmin/Fmax`, `logCompressionScale`, `featureSetVersion`) + 4 init preconditions (DD #2, AC #3). P7 element-wise byte-identity test post-`vvlogf` (AC #5, HALT (h) NEW, Task 8.2). P8 multi-window ownership — single ML eval on merged-winner trace (DD #17 NEW). P9 impact-report config pinned `intensity = .thorough + ensemblePolicy = .mlOnly`; default-config inertness as separate gate (AC #7). P10 Makefile env override fix — `?=` at file-top (AC #8, Task 7.1). P11 AC #10 reconciliation — new files only (Tasks 6, 8, AC #10). P12 BNNSGraph argument lookup by name (DD #16 NEW, AC #1, AC #2, Task 4.2).
  - **NICE-TO-HAVE (2 MINORs):** P13 compile-time conformance test via `assertMLTechnique<T:MLTechnique>(_:)` (Task 8.1). P14 drop `nonisolated(unsafe)` guidance, use `@unchecked Sendable` on struct with rationale (DD #15, Apple-platform notes).

  **Outcomes:**
  - DD count: 14 → 17 (added DD #15 RAII Storage, DD #16 argument-by-name, DD #17 multi-window ownership).
  - HALT count: 7 → 9 (added HALT (a') model-not-acquired and HALT (h) element-wise byte-identity).
  - Test count band: `[365, 375]` → `[370, 378]` (baseline corrected 355 → 357; +15 net additions including RAII deinit, concurrency exposure, raw-API guard greps, 4 init preconditions, element-wise byte-identity, single-ML-eval invariant, 2 impact-report config gates, by-name lookup, compile-time conformance, `@available` witness).
  - WWDC 2024 #10211 title corrected throughout: "Bring your ML models to Apple silicon" → "Support real-time ML inference on the CPU".
  - `URL.path` → `URL.path()` (deprecation fix) reflected in Task 4.2 and Apple-platform notes.
  - Branch C escape hatch CLOSED per Winston: real model required for promotion; HALT (b) is the only honest path to Branch C, requires a real model that genuinely fails the gate.
  - Stakeholder Voices subsection added per Mary; "two baselines two purposes" coherence rule added.
  - Status remains `ready-for-dev`. Sprint status `last_updated` reflects the 2026-05-08 finalization.

- **2026-05-09 (Story 4-5 cohesion-review revision pass triggered by Story 4-4b BYOW pivot).** Story 4-4b pivoted same-day from "train and bundle a model" to "ship reference model + bring-your-own-weights adapter pattern via `MLTechnique` protocol + consumer convert tool at `tools/coreml-convert/`." 4-5 was authored before the pivot and contained contradictions; this revision reconciles. Process:

  **Phase 1 — `/bmad-party-mode` cohesion review** (Winston / Amelia / Paige / Siri):
  - Winston (Architect): 4 load-bearing gaps — 4-5 owns API surface 4-4b pseudocoded but 4-5 doesn't know it; HALT (b) incoherent with 4-4b advisory; convert-tool handoff unmentioned in 4-5; failure semantics underspecified.
  - Amelia (Dev): single blocking item — `MLTechnique` protocol surface not defined in any task in either story. Plus 6 specific edits needed.
  - Paige (Tech Writer): API names finalization back-propagation problem; missing unified workflow diagram; license matrix needed in convert-tool README; documentation cohesion across 3 README locations.
  - Siri (Apple Platform): macOS 14 .mlmodelc / macOS 15 runtime invariant should be explicit; tensor name contract robustness via runtime `validateContract` step; protocol must NOT bake in BNNSGraph; `BNNSGraphCompileOptions.preferredDeviceClass = .cpu` opt-in.

  **Phase 2 — codex per-item verdict** (codex thread `019e0d69-33b8-7320-ad3c-c4a3cd346413`): 15 proposed items reviewed — 9 AGREE, 5 MODIFY, 1 not surveyed. Plus 3 missed items codex flagged: M1 (resolve `BNNSTechnique` vs `BundledTempoClassifier` naming — KEEP `BNNSTechnique`), M2 (remove stale 4-5 pre-pivot contradictions), M3 (define explicit default-options activation story).

  **Phase 3 — edits applied this pass:**
  - **DDs #18-#23 NEW** (post-pivot block): #18 `MLTechnique` protocol surface frozen with verbatim shape (codex Item 1); #19 `Options.mlTechnique`-only override + `BNNSTechnique(modelURL:)` injection + explicit selection (codex Items 2-MOD, 3, 4-MOD); #20 `validateContract` runtime invariant + `MLTechniqueError` enum (codex Item 5 + Siri Item 3); #21 macOS 14/15 forward-compat invariant (codex Item 7); #22 failure semantics — init throws; analyzeBPM never silently masks (codex Item 9-MOD); #23 `BNNSGraphCompileOptions.preferredDeviceClass` SDK-conditional (codex Item 8-MOD).
  - **DD #12 HALT triggers REFRAMED** (codex Item 10-MOD + Item 11): all HALTs renamed `4-5-HALT-<letter>` to disambiguate from 4-4b's `4-4b-HALT-<letter>`. HALT (b) reframed: with 4-4b advisory framing, bundled reference may legitimately ship failing DnB ≥2/4; Branch A (passes) ships default-on; Branch C (fails) ships conformance + override API but `Options.mlTechnique` default stays `nil`. HALT (a') reframed: 4-4b's sanity HALTs determine model availability; consumer-override-only mode is NOT a substitute for shipping bundled reference. NEW HALT (i): `validateContract` test must fire on mismatched-name fixture.
  - **ACs #12-#17 NEW**: #12 protocol surface + compile-time witness; #13 init injection + validateContract enforcement + negative tests; #14 public DocC on new types; #15 back-propagate API names to convert-tool README (close `<!-- FINALIZED-BY-4-5 -->` placeholders); #16 unified workflow diagram in convert-tool README; #17 license matrix (codex Item 15-MOD softened Path C language).
  - **Tasks 0, 11, 12, 13 NEW**: Task 0 finalize protocol + error enum (BLOCKS Tasks 2-9); Task 11 `init(modelURL:)` + `validateContract` + fixture-driven negative tests; Task 12 author public DocC; Task 13 back-propagate names + workflow diagram + license matrix.

  **Cross-story propagation (4-4b updated same revision):**
  - Replaced `useMLModel(at:)` / `setMLTechnique(_:)` pseudocode with `Options.mlTechnique = ...` real signatures throughout 4-4b.
  - Renamed `BundledTempoClassifier` → `BNNSTechnique` (codex M1: keep existing 4-5 / Story 4.1 convention).
  - Updated Consumer Onboarding Path A/B/C in 4-4b Dev Notes with finalized API names.
  - Updated 4-4b Task 11.7 to ship `<!-- FINALIZED-BY-4-5 -->` placeholders that 4-5 Task 13 closes.
  - Marked Med #8 (pseudocode pending Story 4-5) as SUPERSEDED.

  **Codex final recommendation:** "Approve with revisions. Pivot is sound; spec was internally inconsistent and could silently hand Story 4-5 a failing model." All revisions applied this pass.

  **Outcomes:**
  - DD count: 17 → 23 (added 6 post-pivot DDs).
  - HALT count: 9 → 9 + 1 NEW (4-5-HALT-i validateContract). Renamed all to story-prefixed.
  - AC count: 11 → 17 (added 6 post-pivot ACs).
  - Task count: 10 → 14 (added Tasks 0, 11, 12, 13).
  - Status remains `ready-for-dev`. Sprint status unchanged.
