---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - '_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md'
  - '_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/.decision-log.md'
  - '_bmad-output/project-context.md'
  - 'CLAUDE.md'
workflowType: 'architecture'
project_name: 'BoomBoomBoomKit'
user_name: 'robbyt'
date: '2026-05-25'
status: 'complete'
completedAt: '2026-05-26'
lastStep: 8
prdReference: 'prd-BoomBoomBoomKit-2026-05-25 (status: final, 51 FRs across 5 epics, ~25 deferred KDDs)'
archivedPredecessor: '_bmad-output/planning-artifacts/archive/architecture-2026-03-31.md'
---

# Architecture Decision Document — BoomBoomBoomKit

_Architecture for the 2026-05-25 PRD (ML retraining, multi-signal ensemble, selection-strategy documentation). The 2026-03-31 architecture (Phases 1-3 of pre-Epic-4 work) is archived under `archive/architecture-2026-03-31.md`._

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements — 51 FRs across 5 epics:**

- **Epic A (FR-1 through FR-11a) — Unified-signal-pool refactor.** Replaces sequential pipeline (DSP → `merge` → `MetadataCorroborator.apply` → `EnsembleCombiner`) with single weighted voting pool where DSP, ML, and file-metadata are peer signals. Configurable per-source weighting, octave-equivalence, ML execution policy. `AnalysisIntensity` becomes compute-budget dial across ensemble.
- **Epic B (FR-12 through FR-25) — ML retraining on Tony corpus.** 1,344 hand-labeled tracks + ~4,700 unlabeled for semi-supervised. Audio-only features (no library-curator artifacts). Octave-aware loss. Trained model clears 4 DnB sentinels + OA300 > 55/82 + GiantSteps ≥ 537/661 + calibration floor before bundling; otherwise BYOW.
- **Epic C (FR-26 through FR-35) — Public LUFS + beat-grid + ModelRegistry.** Long-file sync stability + playback-aligned timestamps under codec priming. Shared-decode seam for combined analysis.
- **Epic D (FR-36 through FR-44) — Demo ensemble + ML UX.** Named presets in primary view; raw weights in advanced sidebar (`.inspector(isPresented:)`). Security-scoped bookmark persistence. Beat-grid timeline (no waveform). Strategy popover wired to Epic E docs with graceful degradation.
- **Epic E (FR-45 through FR-52) — Selection-strategy docs.** Per-case `.docs: AttributedString` accessor. SPM Markdown resource bundle (`.copy`, not `.process`). Drift detection in CI. `DocumentedCase` protocol family capped at one pre-1.0. `AnalysisIntensity` reshape (struct → enum) to participate.

**Non-Functional Requirements — 10 NFRs:** Swift 6 strict concurrency (NFR-1); zero external dependencies (NFR-2); macOS 15+ minimum (NFR-3); pre-1.0 framing authorizes breaking changes (NFR-4); no prose duplication library→consumers (NFR-5); perf budgets ≤15% OA300 + bounded beat-grid + shared-decode (NFR-6); accuracy floors as unconditional CI assertions (NFR-7); byte-equality opt-out tests as refactor scaffolding (NFR-8); demo App Store compliance with `bookmarks.app-scope` (NFR-9); no new internet requests (NFR-10).

### Project Scale Assessment

- **Complexity: High.** 5 epics, 51 FRs, ~25 deferred KDDs. Spans library architecture refactor (Epic A), full ML training pipeline (Epic B), three new public API surfaces (Epic C), demo UX with security-scoped bookmarks (Epic D), and runtime-documentation system (Epic E). ML system has Python training and Swift runtime paths requiring feature-pipeline parity.
- **Primary technical domain:** Apple-platform Swift library (audio DSP + on-device ML + file I/O) with bundled macOS demo. Pure value-type architecture; no classes.
- **Architecture invariants are unit-test-locked:** `DSPTechnique.allCases.count == 8`, `TechniqueSet.allDSPCombinations().count == 256`, `MetadataSource.allCases.count == 3`, `CandidateMergeStrategy.allCases.count == 8`. Each invariant becomes load-bearing for KDD resolution (e.g., KDD-A1 split route deletes one assertion, replaces with 2 + 1 struct-shape test).

### Technical Constraints & Dependencies

**Apple-platform constraints:**

- Zero external dependencies — only Apple system frameworks. CryptoKit's `SHA256.hash(data:)` is the canonical answer for KDD-C5 integrity check (hardware-accelerated, ~150 ms for 200 MB; CMS is for signed distribution, BLAKE3 has no Apple-native impl).
- vDSP for bulk numerics, Double precision for IIR filters. aubio's weighted-spectral-filtering technique implements as `vDSP_mmul` against a weighted mel matrix (existing `MelFilterbank` pattern), not a cascade of biquads. WWDC 2018 session 701 covers the matrix-multiply pattern.
- KDD-C1 beat-tracking — **no Apple sample code exists.** MusicKit is metadata-only, SoundAnalysis is fixed-graph classification, AVFoundation has zero beat-tracking surface. Hand-rolled on Davies & Plumbley Rayleigh-weighted DP in pure Swift+vDSP, reusing existing `BPMAnalyzer` autocorrelation output.
- KDD-E2 per-instance `.docs: AttributedString` is genuinely novel — no closer Apple precedent than the philosophical `CaseDisplayRepresentable` reference. Document as project-specific in DocC; don't force-fit Apple shape.

**Swift / Concurrency / Pre-1.0 framing:**

- Swift 6 strict concurrency; all public types `Sendable`. Three sanctioned `nonisolated(unsafe)` contexts only.
- All types are value types (structs/enums, no classes). Analyzers stateless with `static` methods.
- `MLTechnique` protocol frozen (`evaluate(trace:) -> MLEvaluation?`); `MLEvaluation` field set frozen (`bpm: Double` + `confidence: Double` only).
- **Pre-1.0 break authorization (NFR-4) explicitly applies to Epic A's load-bearing invariants:** post-merge corroboration boundary collapse (KDD-A6), frozen 41-call-site `merge` signature break, `EnsembleCombiner` removal, `AnalysisIntensity` struct → enum reshape (KDD-E4). Note that `AnalysisIntensity` carries **two** breaking changes (struct → enum + ensemble-budget semantic expansion) — bundle them in one Epic-E story to pay the break once. Bias toward a minimal v1.0 case list (`.fastest`, `.default`, `.thorough`, `.maximum`, `.ensembleBudget(Int)`).
- Pipeline step numbers are stable identifiers — never renumber. Beat-grid extraction inserts as **step 11**, not interleaved; reuses `PipelineBuffers` / `ACFBuffers` per ADR-3 lifetime pattern, with a possible fourth buffer struct for comb-filter phase estimation.

**License + provenance:**

- aubio is **GPL-3.0** — study the *technique* (weighted-spectral-onset filtering, Davies & Plumbley DP), do not transcribe code, do not link.
- No `.mlmodelc` ships on `main` (Story 4-6 Branch C); ML stays BYOW via `BNNSTechnique(modelURL:) throws`.
- `tools/coreml-convert/` is the only Python on `main` (Story 4-4b DD #13 exception).

**Future iOS/visionOS expansion is a Non-Goal** (PRD Non-Goal #6) — the library may not bind to AppKit in public API, and beyond that the architecture should remain platform-neutral by avoiding these traps where possible:

- AVAudioSession asymmetry — keep session management out of the library entirely; let the consumer own category/interruption/route handling.
- Background execution semantics — iOS gives ~30 s after backgrounding (vs. macOS indefinite). The injectable `isCancelled` closure already handles this — preserve it.
- File coordination — iOS/visionOS shared containers require `NSFileCoordinator`. `PCMBufferReader` accepts `URL` agnostically; consumer coordinates.
- Security-scoped bookmark scopes — `app-scope` vs `document-scope` entitlements differ across platforms. Keep bookmark creation in the demo (FR-38), never in the library.
- Sandbox temp directories — `ModelRegistry` needs an injectable cache-root URL.

**Demo distribution bifurcated from library:** library consumers clone `main` (clean SPM); App Store consumers download a `.xcarchive` built from `develop` via `make demo-archive`.

### Cross-Cutting Concerns Identified

Ten concerns the architect must resolve coherently across epics. Order reflects cascade depth — earlier items have the highest downstream blast radius.

1. **Post-merge corroboration boundary (KDD-A6) — load-bearing root.** Either collapse `MetadataCorroborator.apply` into the unified pool (per FR-7) or keep it as a post-merge shim that emits unified-pool voters. The collapse is what Epic A's FR-7 implies; the shim preserves the frozen 41-call-site `merge` signature. **Implementation realism (Amelia):** the collapse must be staged across three stories — (a) introduce `UnifiedSignalPool` type as adapter alongside legacy candidate array, `merge` signature unchanged; (b) migrate `MetadataCorroborator` and `runPreCorroborationPipeline` to consume the pool; (c) flip `merge` parameter type as a single mechanical PR. One-story big-bang loses reviewability.

2. **Shared feature substrate** (consolidates "signal-pool contract" + "perf envelope" + the aubio weighted-filtering signal). The onset front-end (mel-spectrogram, weighted filtering, sub-band normalization) feeds DSP candidates, beat-grid, AND ML training features. If KDD-C1 picks a weighted onset front-end while KDD-B1 trains on the un-weighted mel-spectrogram `BPMAnalyzer` already emits, the substrate forks. **Resolves coherently across:** FR-21 (Python/Swift parity), KDD-B1 (ML training architecture), KDD-C1 (beat-tracking onset), KDD-C3 (disagreement-surfacing), the 15% OA300 perf budget (FR-11), the shared-decode seam (FR-35). **aubio weighted filtering lives here** — implementable as a `Float` weight vector applied during the existing `MelFilterbank` matrix multiply (~half-day add; no new pipeline stage). Detailed contract: see KDD-S2 below.

3. **Failure-mode taxonomy across signals.** Each signal type has its own abstain semantics — ML returns `nil`, metadata can be absent or wrong, beat-grid can fail on long-form material, DSP can hit silence. The unified pool needs a **single abstain / disagreement / demotion contract** — otherwise weighted voting silently treats "absent" and "low-confidence" as the same thing. None of the 25 PRD-named KDDs cover this; the architect adds it. Detailed contract: see KDD-S1 below.

4. **Metadata-as-actually-peer guardrail.** Vision says DSP, ML, and metadata are peers. But if KDD-A6 keeps the post-merge boundary, metadata stays a second-class citizen no matter what the type names look like. **Mandatory architect contract:** opt-in to invoke, peer once invoked. The voting weights cannot reconstruct the old DSP-first hierarchy via the back door (e.g., metadata participating only after merge selects a DSP winner).

5. **Signal-weight unit non-equivalence.** DSP confidence (`[0.0, 1.0]` derived from periodicity-fusion score) and ML softmax-max (`[0.0, 1.0]` derived from output distribution) are not the same unit — same range, different semantics. The unified pool's weight formula has to either (a) calibrate them onto a common scale, or (b) explicitly per-source-weight to compensate. Resolves with KDD-A3 (source-weight formula layering) but the architect must surface the unit problem first.

6. **Octave-equivalence policy spans three layers** — training loss (Epic B FR-16), runtime voting (Epic A FR-3), evaluation metrics (FR-23). Architecture defines once and references everywhere; train/runtime mismatch is a defect that blocks model acceptance (FR-23).

7. **Type taxonomy alignment** — KDD-A1 (umbrella vs split policy types), KDD-A2 (weights shape), KDD-A4 (ML execution policy surface), KDD-A5 (`EnsemblePolicy` fate), KDD-E4 (`AnalysisIntensity` reshape) must resolve coherently or the demo's preset list (FR-36) and Epic E's documented enums (FR-45) fork. **Implementation realism (Amelia):** the KDD-A1 split route replaces `CandidateMergeStrategy.allCases.count == 8` with two new count assertions plus a struct-shape drift test for `SignalWeights`.

8. **DocC + runtime Markdown bundle are parallel surfaces (KDD-E8)** — not a single-sourcing problem to solve. Library exposes a public accessor (`BoomBoomBoomKitDocs.attributedString(for:)`) so the demo target never references `Bundle.module` directly (`Bundle.module` is synthesized only for SPM resource-bearing targets, invisible from an Xcode app target).

9. **ML bundle-vs-BYOW conditional, not preordained (KDD-B5)** — gated by FR-18's four evaluation gates (4 DnB sentinels + OA300 > 55/82 + GiantSteps ≥ 537/661 + calibration floor). Architecture cannot assume the bundle path. Library binary size, default-config accuracy claim, and consumer onboarding all hinge on this.

10. **Test scaffolding survives the refactor.** Byte-equality opt-out tests no longer mandatory as default contract (NFR-8), but explicitly retained as architecture-refactor regression scaffolding. Drift-detection tests for documented cases (FR-50) gate CI. The `TechniqueSet.full` footgun (deferred-work W1) — `.full` auto-includes `.superFluxOnset` despite Branch-B inert-ship — is Epic A's natural opportunity to fix.

### Architecture Decision Sequencing

Of the 25 named KDDs plus the 2 architecture-introduced KDDs below (KDD-S1 + KDD-S2), four are load-bearing roots that gate everything else. The remaining 23 derive from these.

**Tier 1 — Load-bearing roots** (resolve first, in this order):

1. **KDD-S1** — failure-mode taxonomy contract (defines what a "signal" means before architecture wires signals together). Codex's plan-review ranked this highest blast radius.
2. **KDD-S2** — shared feature substrate contract (defines what produces signal evidence). Gates KDD-B1, KDD-B2, KDD-C1, KDD-C3.
3. **KDD-A6** — post-merge corroboration boundary (collapse or hold). Cascades into every other Epic A KDD.
4. **KDD-A1** — type taxonomy for signal voting (umbrella vs split). Once S1 + S2 + A6 are locked, taxonomy falls out mechanically. KDD-A2, KDD-A4, KDD-A5, KDD-E4 then derive.

**Tier 2 — Downstream architectural decisions:** A2, A4, A5, B2, B3, C2, C4, C6, D1-D5, E1, E2, E3, E5, E6, E7. Each resolves once Tier 1 is locked.

**Tier 3 — Gate-driven (deferred until Epic B evaluation lands):** KDD-B5 (bundle vs BYOW). Output of FR-18 gates determines the answer; no architectural decision to make until then.

### Architecture-Introduced KDDs (resolve before the 25 PRD KDDs)

These two KDDs surfaced during advanced elicitation as Tier-1 prerequisites. They are not in the PRD's KDD list — the PRD authored them up to the level of "what becomes true for developers"; the architecture layer is where they get a contract shape.

---

#### KDD-S1 — Failure-Mode Taxonomy Contract

**Decision.** The unified signal pool participates via a four-state `SignalParticipation` enum (`Sendable, Hashable`) — every signal source (DSP, ML, file metadata, beat-grid) maps its result into one of `.absent` / `.abstained(reason)` / `.demoted(signal, reason)` / `.present(signal)`. There is no bare optional return from any source into the pool.

```swift
public enum SignalParticipation: Sendable, Hashable {
    case absent                                              // pool never received an entry (source not invoked)
    case abstained(AbstainReason)                            // source invoked, returned no usable signal
    case demoted(WeightedSignal, reason: DemotionReason)     // signal received at reduced source weight
    case present(WeightedSignal)                             // signal received at full source weight
}

public enum AbstainReason: Sendable, Hashable {
    case policyDisabled                  // ML disabled, metadata source not in enabledSources, intensity skip
    case inputBelowMinimum               // silence detected, file shorter than required
    case confidenceBelowFloor            // signal produced result but self-reported confidence below abstain floor
    case sourceSpecific(String)          // escape hatch — surfaced in trace, opaque to pool weight math
}

public enum DemotionReason: Sendable, Hashable {
    case implausibleForContext           // tag implausible-for-genre, ML disagrees with strong DSP consensus
    case sourceSpecific(String)          // surfaced in trace, opaque to pool weight math
}
```

**Pool voting rules.** `.absent` and `.abstained` contribute zero to cluster vote weights. `.abstained` additionally increments a per-source abstain counter (trace-only — distinguishes "DSP not invoked" from "DSP ran and silenced out"). `.demoted` contributes its `WeightedSignal` at reduced source weight (replaces today's `MetadataCorroborator.skepticismPenalty = 0.85` mechanism). `.present` contributes at full source weight.

**Trade-offs considered.**

- *Three-state enum* (`.absent` / `.abstained` / `.present`) — simpler, but collapses today's `skepticismPenalty` demotion path into either full-weight present or zero-weight abstain. Rejected.
- *Bare optional + sidecar reason* (`WeightedSignal?` + optional `AbstainReason?` field) — keeps the existing `MLTechnique.evaluate(trace:) -> MLEvaluation?` shape but loses the per-source abstain audit at the pool layer. Rejected; the frozen `MLTechnique` protocol surface stays — the four-state enum lives one layer above, populated by an adapter.
- *Flat `AbstainReason` enum with all source-specific cases* (`.modelGateRejected`, `.tagMalformed`, etc.) — clear at the type level but proliferates as new sources land. Rejected in favor of typed universal cases + `.sourceSpecific(String)` escape hatch surfaced in trace.

**Boundary contract.** `MLTechnique.evaluate(trace:) -> MLEvaluation?` stays frozen. The adapter (Stage 1 of Amelia's KDD-A6 migration) wraps:

- `mlTechnique == nil` → `.absent`
- `evaluate(trace:) == nil` AND `mlTechnique != nil` → `.abstained(.confidenceBelowFloor)` or `.abstained(.sourceSpecific(…))` based on what the technique surfaced in its `MLDiagnosticSnapshot` (capability-protocol-conforming techniques only; non-conforming defaults to `.confidenceBelowFloor`)
- `evaluate(trace:) == some MLEvaluation` → `.present(WeightedSignal(from: evaluation))`

Demotion of an ML signal (e.g., ML disagrees with strong DSP consensus + tag agreement) is a pool-level decision, not an MLTechnique decision. The pool emits `.demoted` based on cluster context.

**Test invariants.**

- `total signals attempted == present + abstained + demoted + absent` per analysis.
- Every `MLTechnique.evaluate(trace:) == nil` maps to one of `{.absent, .abstained(.confidenceBelowFloor), .abstained(.sourceSpecific)}` — never silent loss.
- `Codable` round-trip preserves all four cases byte-identically (including `WeightedSignal` payload in `.present` / `.demoted`).
- Per-source contract assertion: DSP source must produce ≥ 1 of `{.present, .abstained, .demoted}`; never `.absent` (DSP always runs at every intensity).

**Migration shape.** Survives Amelia's three-stage KDD-A6 staging — Stage 1 (UnifiedSignalPool adapter) wraps existing `BPMResult.candidates` as `.present(...)` and existing `Options.metadataPolicy = .disabled` as `.absent` without changing any of the 41 `merge` call sites.

---

#### KDD-S2 — Shared Feature Substrate Contract

**Decision.** Decode + onset-extraction is a single substrate consumed by DSP, beat-grid, and ML feature pipelines via an internal `OnsetFeaturesBuilder.build(decoded:weighting:)` enum namespace. Three result types — `DecodedAudio`, `OnsetFeatures`, `WeightingProfile` — are public Sendable structs/enums; trace-readable through `BPMDiagnosticTrace.onsetFeatures` when `enableTrace = true`.

```swift
public enum FeatureSubstrate {                              // namespace, no cases
    public struct DecodedAudio: Sendable {
        public let samples: [Float]
        public let sampleRate: Double                       // 44100/48000/96000 — unsupported throws PCMBufferReaderError
        public let codecPriming: PrimingInfo
    }

    public struct OnsetFeatures: Sendable {
        public let frames: Int
        public let melBands: Int                            // current arch: 128
        public let logMelData: [Float]                      // frame-major flat buffer
        public let tensorLayout: TensorLayout               // reuses MLFeatureFrames.TensorLayout
        public let weighting: WeightingProfile
        public let parameters: Parameters                   // fftSize, hopSize, melFmin, melFmax, logCompressionScale
        public let featureSetVersion: String                // FNV-1a checksum of post-vvlogf log-mel byte stream
    }

    public enum WeightingProfile: Sendable, Hashable {
        case uniform                                        // pre-substrate behavior; matches existing MelFilterbank
        case subBandEmphasis(SubBandWeights)                // aubio-inspired; parameterized
    }

    public struct SubBandWeights: Sendable, Hashable {
        public let kickBandWeight: Float                    // 60–250 Hz emphasis multiplier
        public let snareBandWeight: Float                   // 250–2000 Hz
        public let cymbalBandWeight: Float                  // 2000–8000 Hz
        public let cutoff: SubBandCutoff                    // .standard / .dnbOptimized / .custom(low:mid:high:)
    }

    public struct PrimingInfo: Sendable, Hashable {
        public let codec: AudioCodec                        // .aac / .mp3 / .flac / .wav / .aiff / .caf
        public let leadingTrimFrames: Int                   // for FR-30 playback alignment
        public let trailingTrimFrames: Int
    }
}
```

**Producer.** `OnsetFeaturesBuilder.build(decoded:weighting:)` is the single shared code path. Called by `BPMAnalyzer.estimateBPM`, `BeatGridAnalyzer.estimateBeatGrid` (new, Epic C step 11), and `BNNSTechnique.featurize`. Substrate cannot fork because all three consumers hit the same builder.

**Trade-offs considered.**

- *Keep substrate internal, never publicly typed* — minimal API surface, but loses FR-21 train/runtime parity visibility (consumers can't verify what features the model trained against). Rejected.
- *Promote substrate to public service method `analyzeFeatures(url:options:) -> OnsetFeatures`* — gives Python training and Swift consumers a first-class API but expands public surface beyond Epic C's scope. Deferred to a future story.
- *Unify with existing `MLFeatureFrames`* — `MLFeatureFrames` (Story 4-5) already carries `frames`, `melBands`, `logMelData`, `tensorLayout`, `featureSetVersion`. The substrate's `OnsetFeatures` overlaps significantly. **Recommendation (pre-1.0 break authorized):** replace `MLFeatureFrames` with `FeatureSubstrate.OnsetFeatures`. `featureSetVersion` bump catches the migration. Final decision deferred to step-04 KDD-A1/A6 resolution. Option (b) — keep `MLFeatureFrames` as adapter wrapping `OnsetFeatures` — preserves the frozen `MLTechnique` ABI but adds parallel-type maintenance.

**aubio attachment.** `WeightingProfile.subBandEmphasis(SubBandWeights)` is the seam. Implementation: Float weight vector applied during the existing `MelFilterbank.applyMatrix` (`vDSP_mmul`) — not a new pipeline stage, not a biquad cascade. Reference cites in `///` doc comments: aubio `src/onset/onset.c` weighting, Davies & Plumbley 2007 onset analysis section. No linked or transcribed aubio code; GPL fence intact.

**FR-21 parity tripwire.** Python training pipeline emits `OnsetFeatures` with byte-identical `featureSetVersion` FNV-1a checksum on the post-`vvlogf` log-mel byte stream. Mismatch blocks model acceptance (existing pattern from `MLDiagnosticSnapshot` per Story 4-5).

**Boundary with KDD-S1.** Substrate always succeeds (or throws `PCMBufferReaderError` if decode fails — never abstains). Failure-mode taxonomy (S1) is downstream — only `WeightedSignal` consumers (DSP / ML / beat-grid / metadata) participate in the S1 enum.

**Test invariants.**

- `OnsetFeaturesBuilder.build(decoded:weighting: .uniform)` produces byte-identical output to today's `BPMAnalyzer` mel-spectrogram step 3 (regression scaffolding).
- `featureSetVersion` changes only when any field of `Parameters` or `WeightingProfile` changes; locked via dedicated test.
- Per-consumer assertion: `BPMAnalyzer`, `BeatGridAnalyzer`, `BNNSTechnique.featurize` all consume identical `OnsetFeatures` for the same `(decoded, weighting)` input.

## Starter Template Evaluation

Step-03 is not a no-op — no `create-xyz`-style starter applies (brownfield Swift Package Manager library), but the step IS the moment to re-vet SPM target boundaries and package structure before the Epic-A-through-E work lands. The following structural decisions are pinned here.

### Brownfield framing

The project was bootstrapped with `swift package init --type library` and accumulated 30+ stories of conventions since. The existing 5-target SPM layout, Swift 6 strict concurrency, zero external dependencies, value-type discipline (structs/enums only, no classes), Swift Testing, branch model (`main` = library only; `develop` = AI tooling + Demo), demo distribution bifurcated via `make demo-archive` — all load-bearing conventions documented in `CLAUDE.md` and `_bmad-output/project-context.md`. Not revisited here.

### Structural decisions pinned

**1. SPM target layout — no new product targets.** Beat-grid (Epic C), unified-pool types (Epic A), LUFS public API (Epic C), `ModelRegistry` (Epic C), `DocumentedCase` protocol family (Epic E) all land in the existing `BoomBoomBoomKit` core target. Rationale: zero new framework dependencies, Apple-idiomatic capability bundling (Vision / SoundAnalysis / MusicKit precedent), no link-time win for splitting. **Beat-grid carve-out into `BoomBoomBoomKitBeatGrid` was considered and rejected** — `BoomBoomBoomKitML` opt-in is justified by BNNS surface area + consumer-supplied model file; beat-grid is pure Swift+vDSP on the same decode pipeline. Pre-1.0 keeps the split reversible if measured build/binary cost ever justifies it.

**2. Two new subfolders inside `Sources/BoomBoomBoomKit/` for cohesive subsystems.** `Sources/BoomBoomBoomKit/SignalPool/` (Epic A unified-pool types + KDD-S1 `SignalParticipation` family) and `Sources/BoomBoomBoomKit/FeatureSubstrate/` (KDD-S2 `OnsetFeatures` / `WeightingProfile` / `OnsetFeaturesBuilder`). LUFS, beat-grid, `ModelRegistry`, and `DocumentedCase` remain at the directory root (each is 1-3 files). **Codified threshold: subdir when ≥5 cohesive files; root otherwise.** Folders communicate architectural intent without changing the module boundary — zero-risk readability win.

**3. Public-API facade stays as `AudioAnalysisService`.** New methods `analyzeLUFS(url:options:)` and `analyzeBeatGrid(url:options:)` land as siblings to `analyzeBPM(url:options:)`. No `LUFSService` / `BeatGridService` sibling structs. The shared-decode `DecodedAudio` seam (FR-35) is the actual reason — three methods on one facade share decode state internally; sibling structs cannot without leaking state.

**4. Markdown documentation bundle ships with the core library via `.process`.** New `Sources/BoomBoomBoomKit/Resources/Documentation/*.md` directory plus `resources: [.process("Resources/Documentation")]` line on the `BoomBoomBoomKit` SPM target. `.process` is SwiftPM's documented default; keeps the resource-pipeline seam open for future localization or compression. The ~10 KB total (5 enums × ~2 KB each) is binary-size noise floor; **separate `BoomBoomBoomKitDocs` product was considered and rejected as gold-plating.** Library-internal accessor `BoomBoomBoomKitDocs.attributedString(for:)` hides `Bundle.module` from the demo target (`Bundle.module` is synthesized only for SPM resource-bearing targets, invisible from an Xcode app target).

**5. iOS / visionOS neutrality tripwire — expand `platforms:` array now.** `Package.swift`'s `platforms:` updates from `[.macOS(.v15)]` to `[.macOS(.v15), .iOS(.v18), .visionOS(.v2)]`. Per SE-0236 semantics, declared platforms are "compiles cleanly here," not "tested here." Any accidental `import AppKit` (or other macOS-only) in the public library surface fails compile on the next `swift build` for iOS — not a six-months-later surprise during the iOS port. Pre-1.0 is the cheapest moment to set the tripwire. **Maintenance cost: one CI lane (`swift build -Xswiftc -sdk -Xswiftc iphoneos`).** Architecture remains macOS-15+ for testing and benchmarks; iOS / visionOS expansion remains a Non-Goal per PRD.

**6. 10 KB per-file Markdown ceiling guard.** Each `.md` in `Resources/Documentation/` ≤ 10 KB. Prevents a documented case's prose from becoming a wall the runtime accessor can't render fast. Codified in the Epic E doc-authoring style guide (KDD-E7).

### Items flagged for separate review (not step-03 decisions)

- **`BoomBoomBoomKitTestSupport` access level** — currently public (consumer test fixtures consumed via SPM by downstream packages). Whether it should remain public or become an internal test-only dependency carries consumer-impact implications and warrants a dedicated story spec.
- **`tools/coreml-convert/` semver tag cadence** — only consumer-facing Python on `main`; consumers will eventually pin against it. Tagging cadence and stability commitment are operational concerns deferred to a future tools-versioning story.

### What did NOT change

- No new SPM products (no `BoomBoomBoomKitBeatGrid`, no `BoomBoomBoomKitDocs`).
- No `swiftLanguageVersion` change (stays Swift 6.0).
- No new test targets.
- No demo restructure — `Demo/BoomBoomBoomBPM.xcodeproj` stays as a separate Xcode project per Apple sample-code pattern. SPM executable targets can't host SwiftUI previews properly and can't ship to App Store.
- No DocC catalog merge with runtime Markdown. DocC compiles to `.doccarchive` (symbol-linked Quick Help via Xcode); the runtime Markdown bundle is a separate runtime feature for in-app help rendering via `AttributedString`. Single-sourcing is impractical. KDD-E8 framing: not "two parallel surfaces" but "DocC is the canonical doc surface; runtime Markdown is a separate runtime feature."

### Initialization command — N/A

Project is already bootstrapped. No new initialization story. Subfolder creation (`Sources/BoomBoomBoomKit/SignalPool/`, `Sources/BoomBoomBoomKit/FeatureSubstrate/`) and `Package.swift` updates (`platforms:` expansion, `resources: [.process("Resources/Documentation")]`) happen inside their respective epic stories — not as a separate scaffolding story.

## Core Architectural Decisions

### Decision Priority Analysis

**Tier 1 (Load-bearing roots — strict sequence S1 → S2 → A6 → A1):**

- **KDD-S1** — `SignalParticipation` 4-state failure-mode taxonomy
- **KDD-S2** — `FeatureSubstrate` namespace + `OnsetFeaturesBuilder`
- **KDD-A6** — Post-merge corroboration boundary collapse, staged across 3 stories
- **KDD-A1** — Type taxonomy split into 3 (`SignalWeights` / `OctaveEquivalencePolicy` / `BPMSelectionPolicy`)

**Tier 1.5 (Cross-cutting discipline — lands in parallel with Tier 1):**

- **KDD-T0** — Typed-evidence trace extension. Trigger: types that affect winner selection, weight resolution, or gate firing, AND where the emitted boundary would otherwise be ambiguous or collision-prone at the call site (Winston × John synthesis, Codex-confirmed). First instance (`SignalParticipationTraceEntry`) ships with KDD-S1 in the same PR.

**Tier 2 (Downstream — lands inside epic stories):**

- Epic A: KDD-A2, A3, A4, A4a, A5
- Epic B: KDD-B1, B2, B3, B4
- Epic C: KDD-C1, C2, C3, C4, C5, C6
- Epic D: KDD-D1, D2, D3, D4, D5
- Epic E: KDD-E1, E2, E3, E4, E5, E6, E7, E8

**Tier 3 (Gate-driven — deferred to Epic B close-out):**

- **KDD-B5** — Bundle vs BYOW determination, gated by FR-18 expanded evaluation gates

### Vision wording update (propagating back to PRD)

PRD Vision wording revised to clarify the peer-once-invoked contract:

> "DSP, ML, and metadata can act as peer signals in unified weighted ensembles; ML augmentation is opt-in through ensemble selection."

This resolves John's pushback that `mlFraction = 0` / `EnsemblePolicy.dspOnly` / `MLExecutionPolicy.never` / `signalWeights.ml = 0` are legal configurations contradicting "DSP, ML, and metadata are peer signals" in the original phrasing. Codex's verdict: peer-ness is contextual, not mandatory presence. `.dspOnly` becomes a coherent deliberate ensemble that makes no peer-voting claim. `ComputeBudget` stays an implementation carrier, not the semantic source of truth for signal legitimacy. No type-system enforcement of non-zero ML floors.

### Epic A — Unified-signal-pool architecture

#### KDD-A6 — Post-merge corroboration boundary

**Decision:** Thin shim, staged across 3 stories. `MetadataCorroborator` retained as caseless-enum namespace; `apply(to:input:)` removed. Metadata produces `SignalParticipation` values that the pool ingests as peer voters. Old `corroborationBoost = 1.25` and `skepticismPenalty = 0.85` multipliers become per-source weight presets or `.demoted(...)` invocations.

**Staging (Amelia's three-story migration):**

1. Stage 1 — Introduce `UnifiedSignalPool` as internal-only adapter constructed at `MetadataCorroborator.apply` entry point. Zero call sites change. Byte-equality tests in `Tests/BoomBoomBoomKitTests/MergeByteEqualityTests.swift` run unchanged against all 8 strategies × OA300 sample subset. Tracking checkpoint = stage-1 commit.
2. Stage 2 — Migrate `MetadataCorroborator`'s body + `runPreCorroborationPipeline` to consume pool. `MetadataCorroborator.apply(to:input:)` signature unchanged at this stage. Byte-equality tests still pass.
3. Stage 3 — Flip `merge` parameter type to `UnifiedSignalPool`. Single mechanical PR. Byte-equality tests REPLACED in the same commit by `MergeSemanticEqualityTests.swift` (not failing for a week). NFR-8 retention applies to stages 1-2 only. Pre-1.0 break authorized.

**Story spec requirement:** stage N regression floor = stage N-1 measurement. No week-long red intervals.

#### KDD-A1 — Type taxonomy split

**Decision:** Split into three typed policies. Renames `CandidateMergeStrategy` → `BPMSelectionPolicy`.

```swift
public struct SignalWeights: Sendable, Hashable {
    public var dsp: Double            // default 1.0
    public var ml: Double             // default 1.0; set to 0 to suppress ML voting
    public var fileMetadata: Double   // default 1.0; set to 0 for byte-identical pre-Story-3-6 behavior
    public var beatGrid: Double       // default 1.0; affects beat-grid signal weight (Epic C)
    public static let `default`: SignalWeights
}

public enum OctaveEquivalencePolicy: String, CaseIterable, Sendable, Hashable {
    case collapseToFundamental    // 87 and 174 cluster together
    case octaveAwareWithPenalty   // cluster but penalize off-octave
    case exactMatchOnly           // no octave collapsing
}

public enum BPMSelectionPolicy: String, CaseIterable, Sendable, Hashable {
    case maxConfidence, dedup, quorum, average, median, weightedAverage, union, windowVoting
}
```

**Invariants:** `BPMSelectionPolicy.allCases.count == 8` (replaces `CandidateMergeStrategy.allCases.count == 8`); `OctaveEquivalencePolicy.allCases.count == 3` (new); `SignalWeights` field-set drift detection via Codable round-trip or field enumeration test in `Tests/BoomBoomBoomKitTests/InvariantTests.swift`.

#### KDD-A2 — `SignalWeights` shape

**Decision:** Typed struct with field-style members (resolved by KDD-A1 above). Apple precedent: `URLSessionConfiguration`, `Animation` (Siri).

#### KDD-A3 — Source-weight formula

**Decision:** 2-layer — `effectiveVote = signalConfidence × signalWeights[source]`. Per-source unit non-equivalence (DSP fusion-score vs ML softmax-max — Cross-Cutting Concern 5) absorbed via consumer `SignalWeights` tuning. No automatic cross-source calibration in v1.0; future-epic concern.

#### KDD-A4 — ML execution policy

**Decision:** 3-case enum.

```swift
public enum MLExecutionPolicy: Sendable, Hashable {
    case never                              // ML disabled regardless of mlTechnique field
    case always                             // ML invoked every analysis
    case whenDSPConfidenceBelow(Double)     // ML invoked only when DSP self-confidence < threshold
}
extension MLExecutionPolicy {
    public static let `default`: MLExecutionPolicy = .whenDSPConfidenceBelow(0.85)
}
```

**FR-11a interaction:** when `MLExecutionPolicy = .always` AND `intensity = .fastest`, the explicit policy wins (intensity is the budget hint, the explicit policy is the override).

#### KDD-A4a — `ComputeBudget` carrier (NEW, paired with KDD-E4)

**Decision:** Add `ComputeBudget` struct as the actual carrier of FR-11a's compute-budget-dial semantic. `AnalysisIntensity`'s 10 named cases become presets over this budget space.

```swift
public struct ComputeBudget: Sendable, Hashable {
    public var dspFraction: Double         // [0.0, 1.0]; default 1.0 (full DSP)
    public var mlFraction: Double          // [0.0, 1.0]; default 1.0 when ML in ensemble, else 0.0
    public var beatGridFraction: Double    // [0.0, 1.0]; default 1.0 when beat-grid in ensemble, else 0.0
}

extension AnalysisIntensity {
    public var budget: ComputeBudget { /* derived from case via internal lookup table */ }
}
```

**Field-count justification (per John #1):** These three fractions exist because the unified ensemble identifies three independent cost centers — DSP candidate generation, ML inference, beat-grid extraction. The number is determined by the cost-center count, not by the subsystem count we happened to build. Adding a fourth cost center (e.g., future spectral fingerprinting) extends the struct; the rule is "one fraction per independent cost center the consumer can trade off."

**Vision compliance:** `mlFraction = 0` is a legal value (peer-once-invoked semantics per Vision update). `ComputeBudget` does NOT enforce non-zero ML floors — peer-ness is achieved at the ensemble layer, not the budget layer.

#### KDD-A5 — `EnsemblePolicy` facade

**Decision:** Preserve as 5-case facade. Apple precedent: `URLSession.shared` / `AVAudioSession.Category`.

```swift
public enum EnsemblePolicy: Sendable, Hashable {
    case `default`                          // balanced configuration
    case dspOnly                            // signalWeights.ml = 0, signalWeights.fileMetadata = 0
    case mlOnly                             // signalWeights.dsp = 0, signalWeights.fileMetadata = 0
    case highestConfidence                  // pre-Epic-A behavior preserved
    case weightedVoting(SignalWeights)      // consumer-supplied weights
}
```

Demo presets (FR-36 / KDD-D1) map directly: `Default → .default`, `DSP only → .dspOnly`, `ML augmented → .weightedVoting(SignalWeights(dsp: 1.0, ml: 1.5, fileMetadata: 1.0, beatGrid: 1.0))`, `Trust file tags → .weightedVoting(SignalWeights(dsp: 1.0, ml: 1.0, fileMetadata: 2.0, beatGrid: 1.0))`.

### Epic B — ML retraining

#### KDD-B1 — Training architecture

**Decision:** TempoCNN-style retain. Previous bundle (`giantsteps_v1.mlmodelc`) failure was data quality + calibration, not architecture. Retrain on Tony's better-labeled corpus.

#### KDD-B2 — Semi-supervised method (expanded ablation)

**Decision:** Head-to-head ablation of two training paths, winner enters FR-18 bundling gates:

- Path (a): Supervised-only-with-augmentation. Augmentation = tempo-class-preserving time-stretch + octave-aware pitch-shift + noise injection.
- Path (b): Masked-mel pretraining → fine-tune.

**Comparison axes (expanded per Mary #1):** accuracy + inference latency + memory footprint + **calibration quality** (Expected Calibration Error / reliability diagram / softmax entropy distribution) + **leave-artist-out delta vs random-split delta** (the gap IS the overfit signal).

**Calibration tiebreaker (informational, per Mary):** Hendrycks & Gimpel 2017 documents that pretraining (Devlin-style MLM objectives) produces flatter softmaxes pre-fine-tuning — masked-mel may have a calibration advantage over supervised-only on majority-class regions (the 125/175 bimodal trap). Use `ECE_half_double` as the tiebreaker if Acc1 lands within ±2 tracks.

#### KDD-B3 — Marginal-tier reintroduction

**Decision:** None initial; FixMatch deferred. Initial training pass uses Strong + Solid only (1,078 tracks). Marginal (241 at 0.55-0.65) excluded — reserved for error analysis (see KDD-B4 for protocol).

**Reopen triggers (Codex's 5 named signals):**
1. Strong/Solid validation accuracy plateaus below target while train accuracy is materially higher
2. Leave-artist-out or GiantSteps underperforms despite good in-domain validation
3. Error analysis shows many failures are near marginal-style ambiguity (half/double confusions, 87/174, 130/65/260, breakbeat/DnB edge cases)
4. Masked-mel pretraining helps materially, implying unlabeled/ambiguous audio structure is useful
5. Marginal tracks receive stable, high-confidence predictions across seeds/checkpoints/augmentations and do not degrade sentinels

#### KDD-B4 — Diagnostic suite (structural requirements only)

**Decision:** Architecture pins structural requirements; specific diagnostic list iterates inside training plan.

- Artifact format = JSON + human-readable Markdown report
- Artifact location = `_bmad-output/ml-training/corpus-diagnostics-v1.json` + `_bmad-output/ml-training/corpus-diagnostics-v1.md`
- Gate position = produced + reviewed before training begins (per FR-12)
- **Marginal-tier consumption (Mary #2):** the training plan MUST name how the 241 marginal tracks are used: (i) failure-categorization lens (half/double vs DSP failure vs metadata conflict, using original 5-signal disagreement vectors as taxonomy); (ii) disagreement-geometry input to corpus-diagnostics-v1.json; (iii) post-bundle regression watchlist. Tier is NOT permitted to sit unused on disk.

#### KDD-B5 — Bundle vs BYOW (Tier-3, deferred)

**Decision deferred until Epic B close-out.** FR-18 expanded gates determine: clear all → re-bundle on `main`; any fail → ship BYOW reference at `_bmad-output/ml-models/`.

### Epic B + FR-18 — Expanded bundling gates

A trained model must clear ALL of the following before being bundled in `Sources/BoomBoomBoomKitML/Resources/`:

1. **4 DnB sentinels correct initially**; expand to **n=12 by Epic B mid-point**; **Wilson 95% lower-bound ≥ 0.75** at Epic B close-out (Mary — Wilson interval, not Bayesian / bootstrap)
2. **OA300 Acc1 > 55/82 strictly** (ML must beat pure DSP single-window ceiling)
3. **GiantSteps Acc1 ≥ 537/661** (current floor)
4. **Calibration floor: ECE_half_double < 0.10.** Concrete metric: bin softmax_max into deciles, compute |confidence − accuracy| per bin, average across bins, but only over tracks where true_BPM ∈ {half, double} of any DSP candidate top-3. Tony failure-mode anchor: previous bundle was ECE_half_double ≈ 0.5. Report ECE_overall alongside as contextualizer.
5. **Tail-error P95 absolute BPM error**: GiantSteps < 8 BPM / OA300 < 5 BPM / Sentinels < 3 BPM
6. **Statistical-confidence treatment of small n**: per item 1, Wilson lower-bound at n=12

**Genre scope for v1.0 default-shipped model: breaks + DnB only.** Tony's corpus includes ~120-130 BPM techno tracks; for v1.0 the bundled model is trained and gated against breaks + DnB representative material. Other genres (house, techno, hip-hop, downtempo, etc.) are explicitly out of scope for the v1.0 bundled model and supported via **BYOM (bring-your-own-model)** / **TYOM (train-your-own-model)** workflows. The library accepts any consumer-trained model via `BNNSTechnique(modelURL:) throws`; training tooling at `_bmad-output/ml-training/` (develop-only) supports custom-corpus retraining. Future epics may expand the bundled-model genre scope conditional on corpus growth.

### Epic C — Public API expansion

#### KDD-C1 — Beat-tracking baseline

**Decision:** Davies & Plumbley 2004-2005 Rayleigh-weighted causal DP. Pure Swift + Accelerate/vDSP. Reuses existing `BPMAnalyzer` autocorrelation + `ACFBuffers` (per ADR-3 lifetime pattern). Beat-grid stage inserts as **step 11** in the pipeline (Amelia — pipeline step numbers stable, never renumber).

**License:** aubio (`github.com/aubio/aubio`) is GPL-3.0 — study only, no linkage, no transcription. Reference cite in `///` doc comments: aubio `src/tempo/beattracking.c` + Davies & Plumbley ISMIR 2004 / AES 118 2005. No Apple sample code exists for beat tracking (Siri).

#### KDD-C2 — `BeatGrid` result type shape

**Decision:** Tri-state `DownbeatResult` enum + `BeatTimestamp` with `confidence` + `strength`:

```swift
public struct BeatGrid: Sendable, Hashable {
    public let beats: [BeatTimestamp]
    public let downbeats: DownbeatResult
    public let estimatedTempo: Double
    public let confidence: Float
    public let tempoAgreedWithBPMStage: Bool?   // see KDD-C3
}

public enum DownbeatResult: Sendable, Hashable {
    case notAttempted
    case noneDetected
    case detected([BeatTimestamp])
}

public struct BeatTimestamp: Sendable, Hashable {
    public let presentationTime: Double      // seconds, playback-aligned per FR-30
    public let confidence: Float             // detection certainty [0.0, 1.0]
    public let strength: Float               // beat prominence [0.0, 1.0]
}
```

**`BeatTimestamp.strength` provenance (Amelia #2):** value = `onsetEnvelope[frame] / onsetEnvelopeMax`, NaN-free (clamp at construction). `frame = round(presentationTime * sampleRate / hopSize)`. vDSP integration: `vDSP_maxv` on the existing onset envelope buffer in `PipelineBuffers.onsetEnvelope` (already computed in step 3, reused not recomputed). Marginal cost: ~80 beats per 30s window × 1 float read = negligible. No new buffer allocation. Consumer multiplies by 10 or 100 for display-friendly coarse scales.

#### KDD-C3 — Disagreement-surfacing pattern (FR-31)

**Decision:** Explicit `tempoAgreedWithBPMStage: Bool?` field. Nil when no BPM analysis ran in same call; `true`/`false` when both computed.

#### KDD-C4 — Internal shared-decode seam (FR-35)

**Decision:** `FeatureSubstrate.DecodedAudio` is the seam (from KDD-S2). `BPMAnalyzer`, `BeatGridAnalyzer`, `LUFSAnalyzer` all consume `DecodedAudio` from a single decode pass when `AudioAnalysisService` orchestrates it. Today's separate `analyzeBPM` / `analyzeLUFS` / `analyzeBeatGrid` each pay their own decode (3× cost when called separately). Combined public `analyze(...)` API deferred to follow-up story.

#### KDD-C5 — Integrity-check algorithm

**Decision:** CryptoKit `SHA256.hash(data:)`. Hardware-accelerated on Apple Silicon. Zero new dependencies (CryptoKit is system framework). `import CryptoKit` in `ModelRegistry.swift`.

```swift
public enum ModelRegistryError: Error, Sendable {
    case integrityCheckFailed(expected: SHA256.Digest, actual: SHA256.Digest)
    // ... other cases
}
```

Implementation: SHA-256 over `.mlmodelc` directory contents (sorted-by-relative-path, concatenated bytes). Computed once per model registration; result cached for subsequent loads.

#### KDD-C6 — Beat-grid engine abstraction

**Decision:** No public engine abstraction in v1.0. `BeatGridAnalyzer` is internal, single Davies & Plumbley concrete implementation. Public surface = `analyzeBeatGrid(url:options:) -> BeatGrid?`. Engine protocol introduced only when a second concrete implementation lands (mirrors `MLTechnique` protocol-introduced-after-BNNS precedent).

### Epic D — Demo UX

- **KDD-D1 — Preset list:** 4 PRD presets verbatim, mapped to `EnsemblePolicy` per KDD-A5.
- **KDD-D2 — Timeline rendering:** SwiftUI `Canvas` (simplest direct-drawing primitive). Demo-only concern.
- **KDD-D3 — Bookmark persistence:** `UserDefaults`. Matches Story 5-6 `MergeStrategyPersistence` precedent. Native `Data` support for security-scoped bookmarks. ~1-20 user-added models.
- **KDD-D4 — Popover style:** SwiftUI `.popover()`. Anchored to "?" button, auto-positions, tap-outside dismisses. Apple HIG.
- **KDD-D5 — Diagnostic table:** SwiftUI `Table` with `sortOrder:` parameter (macOS 13+). Read-only, sortable by column. 5-15 rows per analysis.

### Epic E — Selection-strategy docs

#### KDD-E1 — Protocol family cap

**Decision:** One protocol only (`DocumentedCase`) pre-1.0. Sibling protocols (`DefaultProvidable`, `PerformanceAnnotated`, `DeprecatedIn`, etc.) require explicit story-spec authorization. Metadata (versioning, deprecation, performance notes) lives in YAML front-matter, NOT as sibling protocols (Paige #5).

#### KDD-E2 — Protocol shape

**Decision:** Per-instance `var docs: AttributedString` computed property; default impl reads from `Bundle.module` via library-internal accessor.

```swift
public protocol DocumentedCase: Sendable, Hashable {
    static var documentedKind: String { get }
    var documentationID: String { get }
    var docs: AttributedString { get }
}

extension DocumentedCase {
    public var docs: AttributedString {
        BoomBoomBoomKitDocs.attributedString(for: Self.documentedKind, id: documentationID)
    }
}
```

#### KDD-E3 — `documentationID` derivation

**Decision:** Raw-value default + exhaustive switch fallback.

```swift
extension DocumentedCase where Self: RawRepresentable, Self.RawValue == String {
    public var documentationID: String { rawValue }
}
// For enums with associated values, conformer provides explicit switch.
```

#### KDD-E4 — `AnalysisIntensity` reshape

**Decision:** 10-level `String, CaseIterable, Sendable, Hashable` enum with static-let convenience aliases.

```swift
public enum AnalysisIntensity: String, CaseIterable, Sendable, Hashable {
    case level1, level2, level3, level4, level5, level6, level7, level8, level9, level10
}

extension AnalysisIntensity {
    // Convenience aliases for the four well-known levels.
    // Comparison only — not pattern-matchable in `switch`.
    public static let fastest: AnalysisIntensity = .level1
    public static let `default`: AnalysisIntensity = .level7
    public static let thorough: AnalysisIntensity = .level8
    public static let maximum: AnalysisIntensity = .level10
}
```

**Pre-1.0 break (Amelia #3):** Bundles two breaking changes (struct → enum + ensemble-budget semantic via KDD-A4a) in one Epic-E story. `static let default` aliases are NOT pattern-matchable as `case .default:` in `switch` — Swift treats `case .default:` as the default-case keyword; static-let constants only match via `Equatable` (`==` or `if case`). DocC on each alias documents the limitation. **Custom SwiftLint rule** bans `case .default:` against `AnalysisIntensity` to prevent the footgun. Each level gets its own `.md` doc file.

#### KDD-E5 — Cache primitive

**Decision:** `Mutex<[CacheKey: AttributedString]>` from Swift 6's `Synchronization` module (SE-0433).

```swift
import Synchronization

public enum BoomBoomBoomKitDocs {
    private static let cache = Mutex<[CacheKey: AttributedString]>([:])
    private struct CacheKey: Hashable, Sendable { let kind: String; let id: String }
    
    public static func attributedString(for kind: String, id: String) -> AttributedString {
        let key = CacheKey(kind: kind, id: id)
        // Double-checked locking: I/O OUTSIDE the lock.
        // Fast path — most calls hit the cache and never read the bundle.
        if let cached = cache.withLock({ $0[key] }) { return cached }
        // Slow path — parse outside the lock to avoid serializing concurrent readers
        // behind the slowest disk read AND to keep Mutex<T>'s non-reentrant
        // contract safe against any future recursive call via parseFromBundle.
        let parsed = parseFromBundle(kind: kind, id: id)
        return cache.withLock { storage in
            if let raced = storage[key] { return raced }   // re-check under lock; lose-the-race winner wins
            storage[key] = parsed
            return parsed
        }
    }
}
```

**Why double-checked locking (Axiom Concurrency audit):** `Mutex<T>` from `Synchronization` is non-reentrant — if `parseFromBundle` ever recurses back into the accessor (directly or via a future logging / attribute-resolver hook), `withLock` deadlocks on the same thread. Holding the lock across file I/O also serializes every concurrent reader behind the slowest disk read, defeating the cache. Double-checked locking releases the lock during I/O at the cost of an occasional duplicate parse under contention (idempotent, throwaway).

`OSAllocatedUnfairLock` is the iOS 16-17 fallback only; macOS 15+ supports `Mutex<T>` natively (Axiom Concurrency guidance, confirmed via skill consultation).

#### KDD-E6 — SPM resource rule

**Decision:** `resources: [.process("Resources/Documentation")]` (resolved in step-03). Keeps the SPM resource-pipeline seam open for future localization or compression. `.copy` rejected as defensive-against-speculative-future-toolchain.

#### KDD-E7 — Front-matter YAML schema

**Decision:** Minimal 2-field schema with optional payload tag (Paige's trim).

```yaml
---
id: maxConfidence                     # case name (required)
title: Highest-confidence selection   # human-readable (required)
payload: Double                       # optional — present for associated-value cases (e.g., MLExecutionPolicy.whenDSPConfidenceBelow)
---
```

**Trimmed from earlier draft:**
- `kind` field — derivable from parent directory (`Resources/Documentation/<Type>/<case>.md`). Redundant.
- `version: 1` field — YAGNI until the schema actually breaks. Reintroduce only when a breaking schema change requires per-file versioning.

**Filenames match the Swift case identifier 1:1 — no associated-value suffix.** `whenDSPConfidenceBelow.md`, not `whenDSPConfidenceBelow_threshold.md`. Authors document the *pattern* the case represents, not the specific payload value. The `payload:` front-matter field carries the type-level hint for cases that have one.

#### KDD-E8 — DocC integration (Codex-confirmed transclude pattern)

**Decision:** Parallel surfaces, one-way transclude.

- **Canonical source:** `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md`. ~46 files across `BPMSelectionPolicy`, `VotingPolicy`, `EnsemblePolicy`, `DSPTechnique`, `AnalysisIntensity`, `OctaveEquivalencePolicy`, `MLExecutionPolicy`, `DownbeatResult`, plus `*Reason` enums.
- **DocC catalog:** `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases/<case>.md` — generated build artifact, `.gitignore`'d, NOT hand-edited.
- **Generator:** `make docc-transclude` Makefile target. Cats each runtime `.md` into a DocC `<Discussion>` wrapper. Inline shell until ≥10 lines, then extract to `scripts/docc-transclude.py` (develop-only, never ships) per `scripts/demo-bump-build.py` precedent.

**Authoring style guide:**
- 10 KB per-file ceiling (codified in step-03)
- 200-400 words per case (Paige #2)
- Three bold-lead paragraphs structure: `**What it does.**` / `**When to pick it.**` / `**Tradeoff.**`
- No tables, no fenced code blocks, no images, no DocC `<doc:...>` symbol links, no heading hierarchy
- Comparison matrices live in DocC catalog articles, NOT per-case runtime docs (per-case docs are local explanations, not survey articles)

**CI validator (mandatory, Codex requirement):** Swift Testing suite at `Tests/BoomBoomBoomKitTests/DocumentationValidatorTests.swift` (per Amelia). Rejects in canonical runtime `.md`:
- fenced code blocks (```)
- tables (`| col | col |`)
- images (`![alt](url)`)
- DocC symbol links (`<doc:SomeSymbol>`)
- heading hierarchy beyond AttributedString tolerance (no H1/H2/H3)
- files over 10 KB
- missing required bold leads
- DocC backtick-style symbol links if they render as literal text

**Rendering smoke test:** loads every `.md` via `AttributedString(markdown:)` and fails on parse errors.

**Failure ergonomics (Amelia #4):** per-file per-line violations with copy-pasteable stubs. Each violation formatted as `Resources/Documentation/<Type>/<case>.md:12 — fenced code block not allowed (rule: no-fenced-code)`. One `#expect` per rule category. Missing-case stub failures include file path + heredoc of three required bold leads.

**Drift detection (FR-50, Paige #4):** exhaustive switch over `CaseIterable` checked at test time, NOT compile-time macro. Clean failure message names every missing case. Debuggable, removable for local iteration, CI-enforceable.

**Authoring workflow (Paige #1):** CI drift check IS the workflow. When a new case is added without doc file, the failure message includes the exact path the file belongs at + copy-pasteable front-matter stub. Compiler/test failure IS the generator. `make doc-stub CASE=BPMSelectionPolicy.maxConfidence` exists as convenience but CI failure carries the load.

### Tier-1.5 — Cross-cutting discipline

#### KDD-T0 — Typed-evidence trace extension

**Decision:** Adds typed-evidence structs on `BPMDiagnosticTrace` for new public types meeting both criteria below.

**Trigger (Winston × John synthesis, Codex-confirmed):** Add typed evidence structs only for public trace surfaces that
1. affect winner selection, weight resolution, or gate firing, AND
2. would otherwise be ambiguous or collision-prone at the call site without a typed struct.

Both criteria must hold. Pre-1.0 anti-bloat guard.

**Initial set (qualifies under both criteria):**

```swift
public struct SignalParticipationTraceEntry: Sendable, Hashable, CustomStringConvertible {
    public let source: SignalSource         // .dsp / .ml / .fileMetadata / .beatGrid
    public let participation: SignalParticipation
    public let weight: Double               // resolved source weight
    public let contribution: Double         // effectiveVote = signalConfidence × weight
    public var description: String { ... }
}

public struct MLExecutionDecision: Sendable, Hashable, CustomStringConvertible {
    public let policy: MLExecutionPolicy
    public let outcome: Outcome             // .invoked / .skipped(reason)
    public let dspConfidence: Double?       // present when .whenDSPConfidenceBelow gated
    public var description: String { ... }
    public enum Outcome: Sendable, Hashable { case invoked; case skipped(String) }
}

public struct EnsembleWeightResolution: Sendable, Hashable, CustomStringConvertible {
    public let policy: EnsemblePolicy
    public let resolvedWeights: SignalWeights
    public var description: String { ... }
}
```

**Timing (Winston #2):**
- `SignalParticipationTraceEntry` ships in the SAME PR as `SignalParticipation` (KDD-S1). Non-negotiable. Story 3-3b's audit recipes exist because every "we'll typify it later" became a 6-month debt.
- `MLExecutionDecision` ships with KDD-A4's `MLExecutionPolicy` consumer.
- `EnsembleWeightResolution` ships with KDD-A5's `EnsemblePolicy.weightedVoting` consumer.

**Enforcement:** the 5-recipe BPMDiagnosticTrace audit (project-local skill `bpm-diagnostic-trace`) returns zero matches against `Sources/` and `Tests/` after each trace-field addition. KDD-T0 trigger language added to `_bmad-output/project-context.md` alongside the existing "Banned trace-field shapes" section (Winston nit). Otherwise the rule lives only in this conversation and erodes by month 3.

### Implementation Sequence

**Tier-1 strict sequence:** KDD-S1 (+ KDD-T0 `SignalParticipationTraceEntry`) → KDD-S2 → KDD-A6 (3 stages) → KDD-A1 type-taxonomy split.

**Tier-1.5 parallel:** KDD-T0 trigger codified in project-context.md before any Tier-1 PR.

**Tier-2 lands inside epic stories:** Each KDD pairs with its consumer epic. Story-spec authorship cites the Tier-1 + Tier-1.5 dependencies.

**Tier-3 deferred:** KDD-B5 resolves at Epic B close-out based on FR-18 expanded gate outcome.

### Cross-Component Dependencies

- KDD-S1 → KDD-T0 `SignalParticipationTraceEntry` (same PR)
- KDD-S1 + KDD-S2 → KDD-A6 (boundary collapse consumes participation + substrate)
- KDD-A6 → KDD-A1 (type taxonomy split lands against stable `UnifiedSignalPool` shape)
- KDD-A1 (split) → KDD-E2 (`DocumentedCase` conformances on `BPMSelectionPolicy`, `OctaveEquivalencePolicy`, plus existing `VotingPolicy`, `EnsemblePolicy`, `DSPTechnique`)
- KDD-S2 (`OnsetFeatures`) → Epic B FR-21 Python/Swift feature-parity contract; Epic C beat-grid consumes same substrate
- KDD-A5 (`EnsemblePolicy` facade) → KDD-D1 (demo presets); KDD-A4a `ComputeBudget` derives per-source budgets from active `EnsemblePolicy`
- KDD-E4 (`AnalysisIntensity` reshape) ↔ KDD-A4a (`ComputeBudget`); levels are presets over the budget space (FR-11a)
- KDD-C5 (CryptoKit SHA-256) → `ModelRegistry` integrity check at registration time
- KDD-E5 (`Mutex<T>`) → `BoomBoomBoomKitDocs` accessor consumed by Epic D's strategy popover (FR-42)

### Imports inventory (Package.swift / Sources)

- `import Foundation` — pervasive
- `import Accelerate` — DSP (existing)
- `import AVFoundation` — `@preconcurrency` for PCMBufferReader (existing)
- `import CryptoKit` — NEW, `ModelRegistry.swift` SHA-256 integrity check
- `import Synchronization` — NEW, `BoomBoomBoomKitDocs.swift` `Mutex<T>` cache
- `import BNNSGraph` (via BoomBoomBoomKitML target) — existing

`Package.swift` updates:
- `platforms: [.macOS(.v15), .iOS(.v18), .visionOS(.v2)]` (step-03 expansion; visionOS 2 requires `swift-tools-version:6.0` which is already set)
- `resources: [.process("Resources/Documentation")]` on `BoomBoomBoomKit` target (Epic E)
- `.swiftlint.yml` `included:` paths verified for new subfolders (`Sources/BoomBoomBoomKit/SignalPool/`, `Sources/BoomBoomBoomKit/FeatureSubstrate/`) — no change needed; SwiftLint globs by default.

## Implementation Patterns & Consistency Rules

The 113 rules in `_bmad-output/project-context.md` apply unconditionally. This section covers ONLY patterns net-new to this architecture or where this architecture creates new conflict points beyond the existing rules. The skill's default decision categories (database naming, REST endpoint patterns, JSON field naming, event systems, state management) don't apply to a Swift library.

### Inheritance from project-context.md (unchanged, applies as-is)

- Swift 6 strict concurrency; all new public types `Sendable`
- Zero external dependencies; Apple frameworks only
- All types value types (structs/enums, no classes)
- ADR-11 Options-first public configuration
- Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), not XCTest
- vDSP for bulk numerics; Double precision for IIR filters
- Pipeline step numbers are stable identifiers — never renumber
- `@preconcurrency import AVFoundation` in PCMBufferReader
- Three sanctioned `nonisolated(unsafe)` contexts only
- Analyzers never throw; `AudioAnalysisService` throws `PCMBufferReaderError` + `CancellationError` only
- Four banned trace-field shapes (5 audit recipes return zero matches)
- Story authoring discipline (DD block, PSI, multi-pass review, HALT, deferred-work as SoT)
- Branch model: `main` = library only; `develop` = all AI tooling
- 5-layer review cadence for public API or DSP behavior

### Net-new patterns this architecture introduces

**1. Subfolder organization threshold.** `Sources/BoomBoomBoomKit/<Subsystem>/` for cohesive subsystems with ≥5 files. New subfolders this architecture adds: `SignalPool/`, `FeatureSubstrate/`. LUFS / BeatGrid / ModelRegistry / DocumentedCase stay at the root (1-3 files each). SwiftLint globs by default — no `.swiftlint.yml` changes needed.

**2. `DocumentedCase` conformance pattern.** Every public mode enum (`BPMSelectionPolicy`, `VotingPolicy`, `EnsemblePolicy`, `DSPTechnique`, `AnalysisIntensity`, `OctaveEquivalencePolicy`, `MLExecutionPolicy`, `DownbeatResult`, `*Reason` enums) conforms to `DocumentedCase`. `documentationID` derived from raw-value when `RawRepresentable where RawValue == String`; explicit `switch` for associated-value enums. Each case has a corresponding `.md` file at `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md`.

**3. Typed-evidence struct trigger (KDD-T0).** Add typed evidence structs on `BPMDiagnosticTrace` only when BOTH:
- the public type affects winner selection, weight resolution, or gate firing, AND
- the emitted boundary would otherwise be ambiguous or collision-prone at the call site without a typed struct.

Codified in `_bmad-output/project-context.md` alongside "Banned trace-field shapes." Initial set: `SignalParticipationTraceEntry`, `MLExecutionDecision`, `EnsembleWeightResolution`. `SignalParticipationTraceEntry` ships in the SAME PR as KDD-S1's `SignalParticipation` — non-negotiable.

**4. Signal-source contract: 4-state `SignalParticipation`, never bare optional.** Every signal source (DSP, ML, file metadata, beat-grid) maps its result into one of `.absent` / `.abstained(reason)` / `.demoted(signal, reason)` / `.present(signal)`. Adapter layer translates frozen `MLTechnique.evaluate(trace:) -> MLEvaluation?` into the 4-state enum. Pool voting rules:
- `.absent` and `.abstained` contribute zero
- `.abstained` increments a per-source abstain counter (trace-only)
- `.demoted` contributes at reduced source weight
- `.present` contributes at full source weight

**5. Markdown authoring style guide (Epic E).** Three bold-lead paragraphs per case: `**What it does.**` / `**When to pick it.**` / `**Tradeoff.**`. 200-400 words target. 10 KB per-file ceiling. No tables, no fenced code blocks, no images, no `<doc:...>` symbol links, no heading hierarchy. Comparison matrices live in DocC catalog articles, NOT in per-case runtime docs.

**6. KDD-A6 stage-gating regression pattern.** For any multi-stage migration touching frozen public signatures, byte-equality scaffolding is the regression backbone for stages that preserve outputs; semantic-equality replaces it in the same commit as the breaking change. Story spec MUST state: "stage N regression floor = stage N-1 measurement." No week-long red intervals.

**7. `Mutex<T>` for new thread-safe synchronous caches (macOS 15+).** Use `Mutex<T>` from the `Synchronization` module (SE-0433), not `OSAllocatedUnfairLock`. Generic over protected value, `Sendable` by construction, closure-based `withLock { ... }` API. **Apply double-checked locking when the cached value is computed via I/O or recursion-risk paths** (per Axiom Concurrency audit): fast-path lookup inside one `withLock`, expensive computation outside the lock, race-resolution re-check inside a second `withLock`. Reference: `BoomBoomBoomKitDocs.cache` in KDD-E5.

**8. `Package.swift` platforms-array as iOS-neutrality tripwire — plus CI grep gate.** `[.macOS(.v15), .iOS(.v18), .visionOS(.v2)]`. Declared platforms are "compiles cleanly here," not "tested here" (SE-0236). Accidental unguarded `import AppKit` in public surface fails compile on the next `swift build` for iOS.

**Tripwire false negatives the platforms-array alone misses (per Axiom macOS audit):**
- `#if os(macOS) import AppKit #endif` blocks (compiles to zero AppKit refs under iOS SDK; semantically iOS-broken if the iOS branch is `fatalError`)
- `if #available(macOS 15, *)` runtime checks (compiler accepts symbol even when iOS-incompatible)

**Required CI grep gate complementing the platforms tripwire:**

```bash
grep -rE "^import AppKit" Sources/ | grep -v "#if os(macOS)"
```

Returns zero matches as a CI gate. Catches `#if os(macOS) import AppKit then iOS-stub` patterns that the platforms array silently passes. Combined with the platforms-array compile-fail, this is the iOS-neutrality contract.

**9. SPM resource handling — `.process` not `.copy` for runtime Markdown.** `resources: [.process("Resources/Documentation")]` keeps the resource-pipeline seam open for future localization or compression. `.copy` rejected as defensive-against-speculative-future-toolchain.

**10. Library-internal accessor pattern — `Bundle.module` invisible to demo.** `Bundle.module` is synthesized only for SPM resource-bearing targets and invisible from Xcode app targets (demo). The library exposes `BoomBoomBoomKitDocs.attributedString(for:id:)` as the consumer-facing accessor; the demo never references `Bundle.module` directly. Same pattern applies to any future bundled resources accessed by an external consumer.

**11. `@Tag`-based stage-gating for multi-stage migrations + NaN-safe `bitPattern` byte-equality.** For KDD-A6's 3-stage migration (and any future staged refactor of frozen public signatures), encode "stage N regression floor = stage N-1 measurement" via Swift Testing `@Tag`, NOT story-spec checklists. Story-spec checklists drift; tags are CI-enforced and visible in Test Navigator.

```swift
extension Tag {
    @Tag static var stage1Floor: Self
    @Tag static var stage2Floor: Self
}

@Test(.tags(.stage1Floor)) func byteEqualityFloor() { ... }
```

CI invocation: `swift test --filter-tag stage1Floor` proves the floor still passes on the feature branch before merging the next stage. The Stage 3 PR atomically deletes the tagged tests AND introduces `MergeSemanticEqualityTests.swift` replacement in the same commit — auditable in `git log -p`, not buried in a story spec.

**NaN safety in byte-equality helpers:** `MetadataCorroborator` outputs can carry quiet NaNs (existing `EnsembleDecision` documents this is why the type is not `Hashable`). Byte-equality tests MUST use `Double.bitPattern` comparison, not `==`. Helper lives in `BoomBoomBoomKitTestSupport`:

```swift
public extension Double {
    func bitEqual(to other: Double) -> Bool { self.bitPattern == other.bitPattern }
}
```

Applied to `bpm`, `confidence`, and per-element on `candidates` arrays. Existing Story 3-6 byte-equality opt-out test for `metadataPolicy = .disabled` already uses this pattern; KDD-A6 staging inherits the helper without duplication.

### Conflict points where AI agents could drift

The following are the specific scenarios where an AI agent implementing a story might make a different choice than this architecture requires:

| # | Conflict scenario | Architecture pin |
|---|---|---|
| 1 | New SPM target for beat-grid / ModelRegistry / docs | No — all in `BoomBoomBoomKit` core target. Subfolders only. |
| 2 | Demo references `Bundle.module` directly | No — use `BoomBoomBoomKitDocs.attributedString(for:id:)` accessor. |
| 3 | New `DSPTechnique` case added without updating ablation matrix | Unit-test invariant `allCases.count == 8` and `allDSPCombinations().count == 256` fail at unit-test time. |
| 4 | `MetadataCorroborator.apply` re-introduced after KDD-A6 Stage 2 | Story 3-6 byte-equality `Options.metadataPolicy = .disabled` test still applies; semantic-equality test replaces it in Stage 3. |
| 5 | `case .default:` in `switch` over `AnalysisIntensity` | SwiftLint custom rule rejects it. DocC on `.default` alias documents "comparison only — not pattern-matchable." |
| 6 | `OSAllocatedUnfairLock` used for new thread-safe cache instead of `Mutex<T>` | Code review catches; macOS 15+ targets `Mutex<T>` per pattern #7. |
| 7 | aubio code transcribed into Swift (GPL contamination) | License-check at code-review time; `///` doc comment must cite aubio file + Davies & Plumbley papers, not paste source. |
| 8 | Markdown file with tables / code blocks / images / `<doc:...>` / headings | `DocumentationValidatorTests` Swift Testing suite fails CI with per-file per-line violations. |
| 9 | `.copy` used for new resource bundle | Code review catches; `.process` is the architecture-pinned default. |
| 10 | Public mode enum added without `DocumentedCase` conformance + `.md` file | FR-50 drift detection test fails CI (exhaustive switch over `CaseIterable` checks file presence). |
| 11 | `MLEvaluation` extended with new field | Story 4-5 DD #18 freezes the field set; pre-existing rule. Field expansion requires named story spec. |
| 12 | `MLTechnique` evolves with `name` property | Story 4-3 HALT-(b) unit-test invariant — zero `mlTechnique.name` matches. |
| 13 | New decision-boundary public type added without `Sendable` typed-evidence struct on `BPMDiagnosticTrace` | KDD-T0 trigger language in project-context.md; review-time discipline. |
| 14 | `SignalParticipation` value treated as bare optional return from a signal source | Per-source contract assertion: DSP must produce ≥1 of `{.present, .abstained, .demoted}`; never `.absent`. |
| 15 | New ML model bundle attempted without all FR-18 gates clearing | Gate set in architecture doc; Epic B close-out decision per KDD-B5. |
| 16 | File I/O held inside a `Mutex<T>.withLock` block | Code review catches; pattern #7's double-checked locking is the architecture-pinned form. |
| 17 | `#if os(macOS) import AppKit #endif` block with iOS-stub or `fatalError` branch | CI grep gate from pattern #8 catches; platforms-array tripwire alone silently passes this. |
| 18 | Byte-equality test uses `==` instead of `Double.bitPattern` comparison | NaN-safe `bitEqual` helper required (pattern #11). Reviewable by grep for `XCTAssertEqual(.*bpm` patterns in test files. |
| 19 | KDD-A6 stage progression without `@Tag`-gated floor checks | Story spec author MUST use `@Test(.tags(.stageNFloor))` and run `swift test --filter-tag` in CI before merging next stage. |

### Enforcement mechanisms

- **Unit-test-locked invariants** (existing + new):
  - `DSPTechnique.allCases.count == 8`
  - `TechniqueSet.allDSPCombinations().count == 256`
  - `MetadataSource.allCases.count == 3`
  - `BPMSelectionPolicy.allCases.count == 8` (renamed from `CandidateMergeStrategy`)
  - `OctaveEquivalencePolicy.allCases.count == 3` (new)
  - `MLExecutionPolicy.allCases` invariant (one case has associated value, count test uses pattern check)
  - `DownbeatResult.allCases` invariant (one case has associated value)
  - `AnalysisIntensity.allCases.count == 10` (new)
  - `OA300 Acc1 ≥ 58/82, Acc2 ≥ 74/82` (existing)
  - `GiantSteps Acc1 ≥ 537/661, Acc2 ≥ 546/661` (existing)
  - `.optimal` Acc1 ≥ 55/82 floor (existing)
- **CI validators (new):** `Tests/BoomBoomBoomKitTests/DocumentationValidatorTests.swift` (Markdown rule enforcement, per-rule `@Test` for category-level aggregation; rendering smoke test parameterized on file URLs for per-file failure granularity); FR-50 drift detection test (exhaustive switch over each `CaseIterable`).
- **SwiftLint custom rule (new):** ban `case .default:` against `AnalysisIntensity`.
- **CI grep gate (new):** `grep -rE "^import AppKit" Sources/ | grep -v "#if os(macOS)"` returns zero matches.
- **BPMDiagnosticTrace audit recipes:** 5 grep recipes in `.claude/skills/bpm-diagnostic-trace/SKILL.md` return zero matches against `Sources/` and `Tests/` after every trace-field change. Existing + KDD-T0 reinforces.
- **`@Tag`-based stage-gating (new):** per Pattern #11. `swift test --filter-tag stage1Floor` (and `stage2Floor`) before each stage merges. Stage 3 PR atomically deletes the tagged tests + introduces semantic-equality replacement.
- **`Double.bitPattern` byte-equality helper:** `BoomBoomBoomKitTestSupport.Double.bitEqual(to:)`. Required for any new accuracy-affecting feature's byte-equality opt-out test.
- **Code review at PR time:** GPL contamination (no aubio source), `Bundle.module` access patterns, `Mutex<T>` vs `OSAllocatedUnfairLock` choice for new caches, `.process` vs `.copy` for resource lines, file I/O inside `withLock` (pattern #16 violation).

#### `DocumentationValidatorTests` concrete layout

Per-rule `@Test` methods for category-level aggregation. Rendering smoke test parameterized on file URLs for per-file failure granularity:

```swift
@Suite struct DocumentationValidatorTests {
    // One @Test per rule category — aggregates all violations of that rule across all files
    @Test func noFencedCodeBlocks() throws { ... }
    @Test func noTables() throws { ... }
    @Test func noImages() throws { ... }
    @Test func noDocCSymbolLinks() throws { ... }
    @Test func noHeadingHierarchy() throws { ... }
    @Test func filesUnder10KB() throws { ... }
    @Test func requiredBoldLeadsPresent() throws { ... }
    
    // Per-file parameterized smoke test — re-runnable from Xcode Test Navigator
    @Test(arguments: BoomBoomBoomKitDocs.allCanonicalMarkdownFiles())
    func rendersWithoutError(file: URL) throws {
        let markdown = try String(contentsOf: file, encoding: .utf8)
        _ = try AttributedString(markdown: markdown)   // parse-error → test failure
    }
}
```

### Pattern enforcement summary

- **Build-time:** SwiftLint custom rules; compile errors from `platforms:` iOS-neutrality tripwire; Swift 6 strict concurrency.
- **Test-time:** unit-test invariants; `DocumentationValidatorTests`; byte-equality opt-out tests (NaN-safe via `bitEqual`); accuracy floors; `@Tag`-filtered stage-floor tests.
- **CI-grep-time:** `import AppKit` outside `#if os(macOS)` gate; BPMDiagnosticTrace audit recipes.
- **Review-time:** GPL contamination check; KDD-T0 trigger; internal→public promotion ceremony; 5-layer review cadence; file I/O inside `withLock` review.
- **Documentation-time:** project-context.md additions (KDD-T0 trigger language); DocC catalog (parallel surface); runtime Markdown (canonical prose).

## Project Structure & Boundaries

The library's post-architecture structure is largely additive — new subfolders + new types within existing SPM targets. No new top-level products. Tree below shows the COMPLETE post-architecture state with party-mode amendments applied.

### Complete project directory structure

```
BoomBoomBoomKit/
├── Package.swift                                      # UPDATED: platforms array expansion, .process resource
├── README.md
├── LICENSE
├── MODEL_CARD.md
├── .swiftlint.yml
├── .gitignore                                          # UPDATED: BoomBoomBoomKit.docc/Cases/ build artifact
├── Makefile                                            # UPDATED: docc-transclude, docc-validate, new-case scaffolder (`make new-case TYPE=X CASE=y`)
│
├── Sources/
│   ├── BoomBoomBoomKit/                                # Main library target (kept as one product per Winston)
│   │   ├── AudioAnalysisService.swift                  # facade — analyzeBPM, analyzeLUFS, analyzeBeatGrid (Epic C)
│   │   ├── AnalysisIntensity.swift                     # UPDATED: struct → 10-level enum (KDD-E4)
│   │   ├── DSPTechnique.swift                          # unchanged (8 cases)
│   │   ├── TechniqueSet.swift                          # unchanged
│   │   ├── VotingPolicy.swift                          # unchanged (3 cases)
│   │   ├── BPMSelectionPolicy.swift                    # RENAMED from CandidateMergeStrategy (KDD-A1)
│   │   ├── OctaveEquivalencePolicy.swift               # NEW (KDD-A1, 3 cases)
│   │   ├── EnsemblePolicy.swift                        # UPDATED: 5-case facade (KDD-A5)
│   │   ├── MLExecutionPolicy.swift                     # NEW (KDD-A4, 3 cases)
│   │   ├── ComputeBudget.swift                         # NEW (KDD-A4a)
│   │   ├── ProgressUpdate.swift                        # unchanged
│   │   ├── PCMBufferReader.swift                       # unchanged
│   │   ├── MelFilterbank.swift                         # internal namespace
│   │   ├── BPMAnalyzer.swift                           # internal — consumes OnsetFeaturesBuilder
│   │   ├── BPMResult.swift                             # internal
│   │   ├── BPMDiagnosticTrace.swift                    # UPDATED: new typed-evidence fields (KDD-T0)
│   │   ├── LUFSAnalyzer.swift                          # internal
│   │   ├── LUFSResult.swift                            # internal
│   │   ├── LUFSReport.swift                            # NEW public (Epic C FR-26 — integrated, true-peak, LRA)
│   │   ├── FileMetadataReader.swift                    # internal
│   │   ├── MetadataPolicy.swift                        # unchanged
│   │   ├── MetadataSource.swift                        # unchanged (3 cases)
│   │   ├── MetadataBPMEvidence.swift                   # unchanged
│   │   ├── HarmonicRatio.swift                         # unchanged
│   │   ├── ClickCorrelationEntry.swift                 # typed-evidence (existing)
│   │   ├── HarmonicRatioEvidence.swift                 # typed-evidence (existing)
│   │   ├── SubBandVoteEvidence.swift                   # typed-evidence (existing)
│   │   ├── DurationHintEvidence.swift                  # typed-evidence (existing)
│   │   ├── BarCandidate.swift                          # typed-evidence (existing)
│   │   ├── SubBandEnergies.swift                       # typed-evidence (existing)
│   │   │
│   │   ├── SignalPool/                                 # NEW subfolder (KDD-A1)
│   │   │   ├── UnifiedSignalPool.swift                 # NEW (KDD-A6 Stage 1)
│   │   │   ├── SignalParticipation.swift               # NEW (KDD-S1 4-state enum)
│   │   │   ├── AbstainReason.swift                     # NEW (KDD-S1)
│   │   │   ├── DemotionReason.swift                    # NEW (KDD-S1)
│   │   │   ├── WeightedSignal.swift                    # NEW (KDD-S1 payload)
│   │   │   ├── SignalSource.swift                      # NEW (.dsp / .ml / .fileMetadata / .beatGrid)
│   │   │   ├── SignalWeights.swift                     # NEW (KDD-A1 struct)
│   │   │   ├── SignalParticipationTraceEntry.swift     # NEW typed-evidence (KDD-T0, ships with KDD-S1 same PR)
│   │   │   ├── MLExecutionDecision.swift               # NEW typed-evidence (KDD-T0)
│   │   │   ├── EnsembleWeightResolution.swift          # NEW typed-evidence (KDD-T0)
│   │   │   └── MetadataCorroborator.swift              # MOVED + UPDATED (KDD-A6 thin shim, namespace only)
│   │   │
│   │   ├── FeatureSubstrate/                           # NEW subfolder (KDD-S2)
│   │   │   ├── DecodedAudio.swift                      # NEW (KDD-S2 + KDD-C4 shared-decode seam)
│   │   │   ├── OnsetFeatures.swift                     # NEW (KDD-S2)
│   │   │   ├── OnsetFeaturesBuilder.swift              # NEW internal namespace
│   │   │   ├── WeightingProfile.swift                  # NEW (KDD-S2, aubio-inspired sub-band emphasis)
│   │   │   ├── SubBandWeights.swift                    # NEW (KDD-S2)
│   │   │   ├── SubBandCutoff.swift                     # NEW (KDD-S2)
│   │   │   ├── AudioCodec.swift                        # NEW (KDD-S2 PrimingInfo)
│   │   │   ├── PrimingInfo.swift                       # NEW (KDD-S2, FR-30 playback alignment)
│   │   │   ├── TensorLayout.swift                      # RELOCATED from root (intra-target — already public in core per CLAUDE.md)
│   │   │   └── MLFeatureFrames.swift                   # MOVED from BoomBoomBoomKitML/ (Winston — one source of truth for feature contract)
│   │   │
│   │   ├── BeatGrid.swift                              # NEW public (Epic C FR-27)
│   │   ├── BeatTimestamp.swift                         # NEW (Epic C, KDD-C2 + strength field)
│   │   ├── DownbeatResult.swift                        # NEW (Epic C, KDD-C2 tri-state enum)
│   │   ├── BeatGridAnalyzer.swift                      # NEW internal (KDD-C1 Davies & Plumbley DP, step 11)
│   │   │
│   │   ├── ModelRegistry.swift                         # NEW public (Epic C FR-32)
│   │   ├── ModelRegistryEntry.swift                    # NEW public (Epic C FR-32)
│   │   ├── ModelRegistryError.swift                    # NEW public (Epic C FR-33, CryptoKit SHA-256)
│   │   │
│   │   ├── DocumentedCase.swift                        # NEW protocol (Epic E FR-45, KDD-E1/E2)
│   │   ├── BoomBoomBoomKitDocs.swift                   # NEW accessor (Mutex<T> cache, KDD-E5 + double-checked locking)
│   │   │
│   │   ├── BoomBoomBoomKit.docc/                       # DocC catalog (parallel doc surface, KDD-E8)
│   │   │   ├── BoomBoomBoomKit.md                      # Library-level article
│   │   │   ├── Articles/                               # NARRATIVE — comparison matrices, decision trees, "how to choose" (DocC-rich Markdown allowed: tables, code, symbol links, headings)
│   │   │   │   ├── SelectionStrategies.md              # Comparison matrix; ends with "For per-case prose, see Cases/" pointer per Paige
│   │   │   │   └── EnsemblePresets.md                  # Decision tree; ends with same pointer
│   │   │   └── Cases/                                  # REFERENCE — generated build artifact (.gitignore'd)
│   │   │       └── *.md                                # transcluded from Resources/Documentation/ via `make docc-transclude`
│   │   │
│   │   └── Resources/
│   │       ├── README.md                               # NEW (Winston) — explains the runtime-resource convention so devs don't grep Sources/ confusedly
│   │       └── Documentation/                          # NEW canonical-source Markdown (Epic E)
│   │           ├── BPMSelectionPolicy/                 # 8 .md files
│   │           ├── VotingPolicy/                       # 3 .md files
│   │           ├── EnsemblePolicy/                     # 5 .md files
│   │           ├── DSPTechnique/                       # 8 .md files
│   │           ├── AnalysisIntensity/                  # 10 .md files (level1.md - level10.md)
│   │           ├── OctaveEquivalencePolicy/            # 3 .md files
│   │           ├── MLExecutionPolicy/                  # 3 .md files (filenames match Swift case identifiers 1:1, no associated-value suffix)
│   │           ├── DownbeatResult/                     # 3 .md files
│   │           └── *Reason/                            # SignalParticipation reason enums
│   │
│   ├── BoomBoomBoomKitTestSupport/                     # Shared fixtures target
│   │   ├── AudioFixtures.swift                         # existing
│   │   ├── TestSignalGenerators.swift                  # existing
│   │   ├── NumericTestHelpers.swift                    # NEW: Double.bitEqual(to:) + future numeric helpers (Amelia — namespace not single-extension)
│   │   └── Resources/AudioFixtures/                    # existing
│   │
│   └── BoomBoomBoomKitML/                              # Opt-in BNNS product
│       ├── BNNSTechnique.swift                         # existing — now imports MLFeatureFrames from core
│       ├── CoreMLTechnique.swift                       # existing placeholder (Story 4-8 dropped)
│       ├── MLEvaluation.swift                          # existing (frozen field set)
│       ├── MLTechnique.swift                           # existing (frozen protocol)
│       ├── MLDiagnosticTechnique.swift                 # existing capability protocol
│       ├── MLDiagnosticSnapshot.swift                  # existing
│       └── MLTechniqueError.swift                      # existing
│       # MLFeatureFrames MOVED to BoomBoomBoomKit/FeatureSubstrate/ (Winston — one source of truth for feature contract)
│       # NO Resources/ (no .mlmodelc ships on main, Story 4-6 Branch C)
│
├── Tests/
│   ├── BoomBoomBoomKitTests/                           # Unit tests, run by `make test`
│   │   ├── (existing test files)
│   │   ├── DocumentationValidatorTests.swift           # NEW (Epic E CI validator, per-rule + per-file)
│   │   ├── InvariantTests.swift                        # UPDATED: new count assertions
│   │   ├── SignalPoolTests.swift                       # NEW (KDD-S1 + KDD-A6)
│   │   ├── FeatureSubstrateTests.swift                 # NEW (KDD-S2)
│   │   ├── BeatGridTests.swift                         # NEW (Epic C)
│   │   ├── ModelRegistryTests.swift                    # NEW (Epic C + CryptoKit SHA-256)
│   │   ├── DocumentedCaseTests.swift                   # NEW (FR-50 drift detection)
│   │   ├── MergeByteEqualityTests.swift                # UPDATED: @Tag(.stage1Floor), @Tag(.stage2Floor)
│   │   └── MergeSemanticEqualityTests.swift            # NEW at KDD-A6 Stage 3 PR (replaces byte equality atomically)
│   │
│   └── BoomBoomBoomKitBenchmarkTests/                  # Env-gated corpus benchmarks (unchanged) — test target, NOT a Product
│       └── (existing benchmark files)
│
├── Demo/                                               # macOS SwiftUI demo (separate .xcodeproj, not SPM)
│   └── BoomBoomBoomBPM/
│       ├── BoomBoomBoomBPM.xcodeproj
│       └── BoomBoomBoomBPM/
│           ├── (existing files)
│           ├── EnsemblePresetPicker.swift              # NEW (Epic D FR-36 — 4 PRD presets)
│           ├── ModelPickerView.swift                   # NEW (Epic D FR-37 + FR-38 bookmarks)
│           ├── BeatGridTimelineView.swift              # NEW (Epic D FR-39, SwiftUI Canvas)
│           ├── LUFSReadoutView.swift                   # NEW (Epic D FR-40)
│           ├── SignalPoolDiagnosticTable.swift         # NEW (Epic D FR-41, sortable Table)
│           ├── HelpButton.swift                        # NEW generic over DocumentedCase (FR-42)
│           └── BookmarkPersistence.swift               # NEW (Epic D KDD-D3, UserDefaults)
│
├── tools/
│   └── coreml-convert/                                 # Consumer convert CLI (unchanged, only Python on main)
│       ├── pyproject.toml
│       ├── convert.py
│       └── tests/
│
└── _bmad-output/                                       # DEVELOP-ONLY, never ships to main
    ├── planning-artifacts/
    │   └── architecture.md                             # THIS DOCUMENT
    ├── ml-training/                                    # Develop-only Python training pipeline
    │   ├── corpus-diagnostics-v1.json                  # NEW (KDD-B4 artifact, gate before training)
    │   ├── corpus-diagnostics-v1.md                    # NEW (KDD-B4 human-readable report)
    │   ├── training-architecture-ablation.json        # NEW (KDD-B2 ablation comparison)
    │   ├── corpus_splits.json                          # UPDATED (FR-22 leave-artist-out)
    │   └── (existing files: tony-corpus/, swift_feature_extractor/, etc.)
    └── ml-models/                                      # BYOW models (develop-only; no .mlmodelc on main)
        └── (trained model artifacts)
```

**Root ceiling follow-up (Amelia):** the existing "subdir when ≥5 cohesive files" rule keeps Epic C's BeatGrid (4 files) and ModelRegistry (3 files) at the root. Cumulative root file count is approaching ~50 in `Sources/BoomBoomBoomKit/`. Step-07 should codify a "root ceiling = 35 files; force subfolders above" tripwire as an additional discipline rule, to be evaluated against the post-implementation state.

### Architectural boundaries

**Target boundaries (5 SPM products):**

- `BoomBoomBoomKit` (library, public) — pure DSP + unified signal pool + public APIs + DocumentedCase + ModelRegistry + beat-grid + MLFeatureFrames (relocated per Winston). Imports: Foundation, Accelerate, AVFoundation (`@preconcurrency`), CryptoKit (NEW), Synchronization (NEW).
- `BoomBoomBoomKitTestSupport` (library, public) — shared fixtures + `NumericTestHelpers.swift` (folds `Double.bitEqual(to:)` and future numeric test helpers into one namespace per Amelia). Access-level question (should TestSupport stay public or become test-only?) is deferred to a separate story.
- `BoomBoomBoomKitML` (library, public, OPT-IN) — `MLTechnique` protocol + `BNNSTechnique` BYOW. `MLFeatureFrames` moved to core (Winston — eliminates cross-target adapter risk on `featureSetVersion` bumps). Depends on `BoomBoomBoomKit` for shared types. `MLEvaluation` and `MLTechnique` are candidates for migration to core in a future story (`BoomBoomBoomKitML` may shrink further).
- `BoomBoomBoomKitTests` (test target, NOT a Product) — unit tests, runs in `make test`.
- `BoomBoomBoomKitBenchmarkTests` (test target, NOT a Product) — env-gated corpus benchmarks.

**Demo boundary:** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM.xcodeproj` — separate Xcode project, not SPM. Consumes `BoomBoomBoomKit` + `BoomBoomBoomKitML` via SPM. Distributes via `.xcarchive` (`make demo-archive`), never via `git` to consumers.

**`tools/coreml-convert/` boundary:** Ships on `main` AND on `develop`. Consumer-facing PyTorch → CoreML CLI. Not consumed by any SPM target.

**Branch boundary:** `main` carries `Package.swift`, `Sources/`, `Tests/`, `tools/coreml-convert/`, `.swiftlint.yml`, `LICENSE`, `README.md`, `MODEL_CARD.md`. `develop` carries `main`'s content PLUS `.claude/`, `_bmad/`, `_bmad-output/`, `CLAUDE.md`, `Makefile`, `scripts/`, `Demo/`. Squash-merge protocol per CLAUDE.md.

### Requirements-to-structure mapping (epic-level)

**Epic A — Unified-signal-pool architecture:**
- New files: `Sources/BoomBoomBoomKit/SignalPool/*` (10 new files)
- Modified: `BPMAnalyzer.swift`, `AudioAnalysisService.swift`, `BPMDiagnosticTrace.swift`, `EnsemblePolicy.swift`
- Renamed: `CandidateMergeStrategy.swift` → `BPMSelectionPolicy.swift`
- Tests: `Tests/BoomBoomBoomKitTests/SignalPoolTests.swift`, `MergeByteEqualityTests.swift` (`@Tag`-gated), `MergeSemanticEqualityTests.swift` (Stage 3 atomic replacement)

**Epic B — ML retraining:**
- No library changes (BYOW + frozen `MLTechnique` protocol)
- Develop-only: `_bmad-output/ml-training/corpus-diagnostics-v1.{json,md}`, `training-architecture-ablation.json`, updated `corpus_splits.json`
- Trained model artifact at `_bmad-output/ml-models/` (develop-only); bundling decision at KDD-B5

**Epic C — Public API expansion:**
- New files: `LUFSReport.swift`, `BeatGrid.swift`, `BeatTimestamp.swift`, `DownbeatResult.swift`, `BeatGridAnalyzer.swift` (internal), `ModelRegistry.swift`, `ModelRegistryEntry.swift`, `ModelRegistryError.swift`, `FeatureSubstrate/*` (10 files including relocated MLFeatureFrames)
- Modified: `AudioAnalysisService.swift` (adds `analyzeLUFS` + `analyzeBeatGrid` siblings), `BPMAnalyzer.swift` (step 11 insertion)
- Tests: `BeatGridTests.swift`, `ModelRegistryTests.swift`, `FeatureSubstrateTests.swift`

**Epic D — Demo UX:**
- New files: 7 SwiftUI views in `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/`
- Modified: Demo's main window views to integrate the new components

**Epic E — Selection-strategy docs:**
- New files: `DocumentedCase.swift`, `BoomBoomBoomKitDocs.swift`, `Resources/README.md`, `Resources/Documentation/<Type>/*.md` (~46 files)
- DocC catalog: `BoomBoomBoomKit.docc/` with `Articles/` (hand-authored narrative) + `Cases/` (build-artifact reference, `.gitignore`'d)
- Modified: `Package.swift` (`.process` resource line)
- Tests: `DocumentationValidatorTests.swift`, `DocumentedCaseTests.swift`
- Makefile: `make docc-transclude`, `make docc-validate`, `make new-case TYPE=X CASE=y` scaffolder (per Paige)

### Integration points

**Internal communication (within library):**
- `AudioAnalysisService` orchestrates: `PCMBufferReader.read(url:)` → `OnsetFeaturesBuilder.build(decoded:weighting:)` → fan-out to `BPMAnalyzer`, `LUFSAnalyzer`, `BeatGridAnalyzer` → `UnifiedSignalPool` aggregates → `MetadataCorroborator.participate(...)` injects metadata voters → `BPMSelectionPolicy` selects winner → `BPMDiagnosticTrace` records `SignalParticipationTraceEntry` per source
- Shared decode: single `DecodedAudio` consumed by all three analyzers (FR-35); combined `analyze(url:)` API deferred
- Cancellation: `isCancelled` closure checked between windows; injected per ADR-1
- Progress: `onProgress(ProgressUpdate)` fires before each window

**Cross-target communication:**
- `BoomBoomBoomKitML.BNNSTechnique` implements `MLTechnique` (defined in `BoomBoomBoomKit` core). Frozen protocol surface. `BNNSTechnique` imports `MLFeatureFrames` from core (post-relocation).
- `BoomBoomBoomKitTestSupport` consumed by both library tests and external consumer packages (access-level deferred)
- Demo target imports both `BoomBoomBoomKit` and `BoomBoomBoomKitML` via SPM

**External integration (consumer-facing):**
- Public surface: `AudioAnalysisService.analyzeBPM/LUFS/BeatGrid(url:options:)`
- BYOW model loading: `BNNSTechnique(modelURL:) throws`
- Per-case docs: `mergeStrategy.docs` returns `AttributedString`
- Strategy popover (demo): `BoomBoomBoomKitDocs.attributedString(for:id:)` accessor hides `Bundle.module`

**Data flow:**
```
File URL
  → PCMBufferReader.read(url:) → [Float] samples + sampleRate + PrimingInfo
  → OnsetFeaturesBuilder.build(decoded:weighting:) → OnsetFeatures (mel-spectrogram, optionally aubio-weighted)
  → [parallel fan-out]
       → BPMAnalyzer.estimateBPM(features:) → [BPMResult.candidates]
       → BeatGridAnalyzer.estimateBeatGrid(features:) → BeatGrid
       → BNNSTechnique.featurize → MLFeatureFrames (core type) → BNNS inference → MLEvaluation
  → MetadataCorroborator.participate(file:policy:) → metadata SignalParticipation
  → UnifiedSignalPool aggregates all signals as SignalParticipation
  → BPMSelectionPolicy.select(from: pool, weights:, equivalence:) → winning candidate
  → BPMDiagnosticTrace populated (typed-evidence per KDD-T0)
  → AudioAnalysisResult returned
```

### File organization patterns

- **Configuration files (Package.swift, .swiftlint.yml, Makefile, .gitignore)** — root of repo. Updated per architecture: new `Package.swift` resource line + platforms expansion; new Makefile targets including `make new-case`; `.gitignore` excludes `BoomBoomBoomKit.docc/Cases/`.
- **Source code organization** — flat at root with cohesive-subsystem subfolders (per pattern #1 in step-05): subdir when ≥5 cohesive files. `SignalPool/` and `FeatureSubstrate/` are the two subfolders in this architecture. Root ceiling tripwire (~35 files) flagged for step-07 codification (Amelia).
- **Tests** — `Tests/BoomBoomBoomKitTests/` for unit; `Tests/BoomBoomBoomKitBenchmarkTests/` for env-gated corpus benchmarks. No new test targets.
- **Resources** — `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md` canonical Markdown. Audio fixtures stay in `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/`. `Sources/BoomBoomBoomKit/Resources/README.md` explains the runtime-resource convention to prevent dev grep confusion (Winston).
- **DocC catalog** — `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/` with `Articles/` (hand-authored *narrative*) and `Cases/` (generated *reference* build artifact, `.gitignore`'d). Re-framing per Paige: narrative vs reference, two cognitive modes. Each `Articles/` file ends with a "For per-case prose, see `Cases/`" pointer.
- **Build/distribution** — `.build/` SPM build dir (`.gitignore`'d). Demo `.xcarchive` at `build/BoomBoomBoomBPM.xcarchive` (also `.gitignore`'d).

### Development workflow integration

- **Development:** `swift build`, `swift test --filter BoomBoomBoomKitTests`, `make fmt && make lint` before commit. New case authoring: `make new-case TYPE=BPMSelectionPolicy CASE=maxConfidence` scaffolds the `.md` with front-matter + bold-lead template (Paige).
- **Build process:** `swift build -c release` for the library; `make demo-build` / `make demo-archive` for the App Store-bound macOS demo; `make compile-model` for develop-only `.mlmodel` → `.mlmodelc` (consumers don't run this); `make docc-transclude` for DocC catalog generation pre-archive.
- **CI gates:** `make test` (unit + invariant + validator + drift detection); `make benchmark` / `make benchmark-giantsteps` (corpus-gated); `make ablation` (256-combo); `make perf-benchmark` (15% OA300 budget); `make docc-validate` (Markdown subset enforcement); `swift build -Xswiftc -sdk -Xswiftc iphoneos` (iOS-neutrality tripwire); `grep -rE "^import AppKit" Sources/ | grep -v "#if os(macOS)"` (AppKit gate); `@Tag`-filtered stage-floor tests during KDD-A6 migration.
- **Release:** Manual `git checkout main && git merge --squash develop`; delete AI tooling paths from staging; commit with public-facing message. `Demo/.xcarchive` distributed separately via App Store Connect.

## Architecture Validation Results

### Coherence Validation

**Decision compatibility:** All decisions cohere. Apple-frameworks-only set is internally consistent (Foundation + Accelerate/vDSP + AVFoundation + CryptoKit + Synchronization + BNNSGraph). All versions align at macOS 15+ / Swift 6.0 (no `#available` guards needed for `Mutex<T>`, `Table.sortOrder`, `AttributedString(markdown:)`, `.inspector(isPresented:)`, `CryptoKit.SHA256`). Vision wording update ("peer-once-invoked") resolves the `ComputeBudget` peer-ness conflict cleanly.

**Pattern consistency:** Net-new patterns interlock correctly — `SignalParticipation` 4-state + `Mutex<T>` double-checked locking + `.process` resource handling + `@Tag` stage gating + typed-evidence trigger (KDD-T0) + `case .default` SwiftLint rule + CI grep gate all serve different constraints with no overlap or contradiction. Inheritance from project-context.md's 113 rules is additive, not contradictory.

**Structure alignment:** Project tree supports all decisions. `SignalPool/` subfolder houses KDD-A6 + KDD-S1 + KDD-T0 typed-evidence together. `FeatureSubstrate/` houses KDD-S2 + relocated `MLFeatureFrames` + `TensorLayout`. Single-target approach (`BoomBoomBoomKit`) absorbs the growth without forcing premature public-API splits.

### Requirements Coverage Validation

**Epic coverage (5 epics, 51 FRs):**

- **Epic A (FR-1 through FR-11a, 12 FRs):** All covered. FR-1/7 (unified pool + metadata peer) → KDD-A6 + KDD-S1. FR-2/3 (per-source weights + octave) → KDD-A1 split + A3 formula. FR-4 (ML execution policy) → KDD-A4. FR-5 (common ensemble cases) → KDD-A5 facade. FR-6 (per-window caps) → KDD-A1 voting rules. FR-8 (empty pool nil) → KDD-S1 `.absent` semantics. FR-9 (trace surfaces pool) → KDD-T0 typed-evidence. FR-10/11 (accuracy floors + perf budget) → CI invariants + `make perf-benchmark`. FR-11a (intensity dial) → KDD-E4 + KDD-A4a `ComputeBudget`.
- **Epic B (FR-12 through FR-25, 14 FRs):** All covered. Architecture pins B1 (TempoCNN retain), B2 (ablation with expanded axes), B3 (None initial + FixMatch deferred), B4 (structural artifact requirements), B5 (gate-driven, deferred). FR-15/22 (audio-only features + leave-artist-out) flow through training-plan implementation; architecture-level requirements set.
- **Epic C (FR-26 through FR-35, 10 FRs):** All covered. FR-26 LUFS → `LUFSReport`. FR-27/28 beat-grid → `BeatGrid` + `DownbeatResult` tri-state. FR-29/30 sync stability + playback alignment → KDD-S2 `PrimingInfo`. FR-31 BPM/beat-grid consistency → KDD-C3 `tempoAgreedWithBPMStage`. FR-32 model registry → `ModelRegistry`. FR-33 integrity → KDD-C5 CryptoKit SHA-256. FR-34 acceptance corpus → committed in architecture. FR-35 shared decode → KDD-S2 `DecodedAudio` seam.
- **Epic D (FR-36 through FR-44, 9 FRs):** All covered. FR-36 presets → KDD-D1 mapped to `EnsemblePolicy` facade. FR-37 model selection → `ModelPickerView` + `BookmarkPersistence`. FR-38 security-scoped bookmarks → demo-owned. FR-39 timeline → KDD-D2 `Canvas`. FR-40 LUFS readout → `LUFSReadoutView`. FR-41 diagnostic table → KDD-D5 sortable `Table`. FR-42 popover + graceful degradation → `HelpButton<T: DocumentedCase>` + `BoomBoomBoomKitDocs` accessor. FR-43/44 sidebar discipline + confidence labels → demo views + Epic E style guide.
- **Epic E (FR-45 through FR-52, 6 FRs):** All covered. FR-45 typed property → KDD-E2 `var docs`. FR-46/52 offline + bundled → SPM resource bundle. FR-47 what+why → 3-bold-lead authoring guide. FR-49 informative fallback → `BoomBoomBoomKitDocs.attributedString(for:id:)` non-throwing non-optional. FR-50 drift detection → `DocumentedCaseTests` + exhaustive switch.

**NFR coverage (10 NFRs):**

- NFR-1 Swift 6 strict concurrency — `Mutex<T>`, Sendable on all new public types
- NFR-2 Zero external deps — Apple frameworks only
- NFR-3 macOS 15+ — `platforms:` declaration + iOS-neutrality tripwire
- NFR-4 Pre-1.0 no BC — `CandidateMergeStrategy` → `BPMSelectionPolicy` rename, `merge` signature flip, `EnsembleCombiner` removal, `AnalysisIntensity` reshape all authorized
- NFR-5 No prose duplication — DocC transclude from canonical runtime Markdown
- NFR-6 Perf budgets — 15% OA300, bounded beat-grid, shared decode
- NFR-7 Accuracy floors — CI invariants on all four floors
- NFR-8 Test discipline — `@Tag` stage-floor + NaN-safe `bitEqual`
- NFR-9 App Store compliance — demo sandboxed, `bookmarks.app-scope`
- NFR-10 No new internet — FR-46 + FR-52 enforced

### Implementation Readiness Validation

**Decision completeness:** 27 KDDs resolved (25 PRD + KDD-S1/S2). 1 deferred by design (KDD-B5 gate-driven). 1 cross-cutting (KDD-T0). 1 paired addition (KDD-A4a `ComputeBudget`).

**Pattern completeness:** 11 net-new patterns + 19 specific conflict scenarios mapped with enforcement mechanism per row.

**Structure completeness:** Full project tree with file-level annotations. Epic-to-file mapping for all 5 epics. Integration points + data flow documented.

### Gap Analysis Results

**Critical gaps:** None blocking. KDD-B5 deferral is by design (gate-driven).

**Important gaps (flagged-for-separate-story):**
- `BoomBoomBoomKitTestSupport` access level (public vs internal-test-only) — Winston flagged twice; dedicated story spec required, not architecture-pinnable.
- `tools/coreml-convert/` semver tag cadence — operational concern; deferred to a future tools-versioning story.
- Root ceiling 35-file tripwire codification — Amelia recommended; flagged for step-07 codification but kept advisory pending post-implementation file-count measurement.

**Nice-to-have gaps:**
- `Sources/BoomBoomBoomKit/Resources/README.md` content not drafted (convention note Winston recommended); ships in Epic E implementation story
- `make new-case TYPE=X CASE=y` scaffolder script content not drafted; ships in Epic E implementation story
- `Articles/` narrative-to-`Cases/` reference pointer prose not drafted; ships in Epic E doc-authoring story

**Architectural deferrals (intentional, not gaps):**
- Combined `analyze(url:options:) -> AudioAnalysisReport` public API — deferred to follow-up story; `DecodedAudio` seam reserves the path
- `MLEvaluation` and `MLTechnique` protocol migration from `BoomBoomBoomKitML` → core — candidate future story per Winston
- DocC and runtime Markdown true single-sourcing — deferred post-1.0; transclude pattern handles pre-1.0
- Genre-stratified bundling gates expansion (house / techno / hip-hop / downtempo / breakbeat) — BYOM/TYOM workflows handle non-DnB v1.0

### Validation Issues Addressed

- **During step-04 (KDD walk):** all party-mode + Codex tiebreaks applied verbatim. ComputeBudget peer-ness conflict resolved via Vision update.
- **During step-05 (Patterns):** 4 Axiom-skill audit findings applied — `Mutex<T>` double-checked locking, `@Tag` stage-gating + NaN-safe `bitEqual`, AppKit grep gate complementing platforms tripwire, file-URL parameterization of rendering smoke test.
- **During step-06 (Structure):** 7 party-mode amendments applied — `MLFeatureFrames` relocated to core, `TensorLayout` wording corrected, YAML schema trimmed, filenames match Swift identifiers 1:1, `Resources/README.md` added, scaffolder Makefile target added, `Articles/`-as-narrative vs `Cases/`-as-reference re-framing, `DoubleBitEquality.swift` → `NumericTestHelpers.swift` namespace.

### Architecture Completeness Checklist

**Requirements Analysis**
- [x] Project context thoroughly analyzed (113 rules + PRD + decision log + audit recipes)
- [x] Scale and complexity assessed (high, 51 FRs / 27 KDDs / 5 epics)
- [x] Technical constraints identified (Apple-only, Swift 6 strict, macOS 15+, pre-1.0, GPL boundary on aubio, frozen `MLTechnique`)
- [x] Cross-cutting concerns mapped (10 concerns step-02 + KDD-T0 trigger)

**Architectural Decisions**
- [x] Critical decisions documented with versions (Swift 6.0, macOS 15.0, iOS 18.0, visionOS 2.0, CryptoKit, Synchronization)
- [x] Technology stack fully specified
- [x] Integration patterns defined (signal pool, feature substrate, shared decode)
- [x] Performance considerations addressed (FR-11/29/34/35 + 15% OA300 budget)

**Implementation Patterns**
- [x] Naming conventions established (inheritance from project-context.md + 11 net-new patterns)
- [x] Structure patterns defined (subfolder threshold, value types, no-class rule)
- [x] Communication patterns specified (`SignalParticipation` 4-state, `EnsemblePolicy` facade, `BoomBoomBoomKitDocs` accessor)
- [x] Process patterns documented (error handling, KDD-A6 staging, audit recipes, double-checked locking)

**Project Structure**
- [x] Complete directory structure defined (step-06 tree with file-level annotations)
- [x] Component boundaries established (5 SPM targets + Demo + tools)
- [x] Integration points mapped (data flow + cross-target communication)
- [x] Requirements to structure mapping complete (epic-level mapping for all 5 epics)

All 16 items checked.

### Architecture Readiness Assessment

**Overall Status:** **READY FOR IMPLEMENTATION** (all 16 checklist items checked; no critical gaps; 3 important gaps flagged for separate stories — not blocking).

**Confidence Level:** High — with one caveat: KDD-B5 (bundle vs BYOW) outcome is empirical (FR-18 gate clearance is determined by training results, not architectural decision). Architecture pins both paths; the actual decision waits for Epic B evaluation.

**Key strengths:**
- 27 KDDs resolved with traceability to specific FRs
- 2 architecture-introduced KDDs (KDD-S1 failure-mode taxonomy, KDD-S2 shared feature substrate) plus KDD-T0 cross-cutting discipline — surfaces concerns the PRD didn't name
- 5-layer review cadence applied: 4 party-mode rounds + 4 Codex consultations + 4 Axiom skill audits + Apple-docs MCP queries
- Pre-1.0 break authorization explicit; no hidden BC compromise
- Enforcement mechanisms map to specific test-locked invariants + CI gates + grep gates + review-time checks
- KDD-A6 staged migration shape preserves byte-equality regression scaffolding (NaN-safe via `bitEqual`); 3-stage atomic-replace pattern
- Vision wording updated to honestly reflect "peer-once-invoked" rather than mandatory-presence peer-ness
- aubio GPL fence maintained throughout (study only, no transcription); Davies & Plumbley citation pattern established

**Areas for future enhancement:**
- TestSupport access-level dedicated story (public vs internal-test-only)
- `tools/coreml-convert/` semver tagging cadence (operational)
- Root ceiling 35-file tripwire codification (post-implementation review)
- Combined `analyze(url:options:) -> AudioAnalysisReport` public API
- `MLEvaluation` + `MLTechnique` protocol migration to core (`BoomBoomBoomKitML` may shrink further)
- DocC + runtime Markdown true single-sourcing (post-1.0)
- Genre-stratified bundling gates for non-DnB (BYOM/TYOM v1.0 → bundled v1.1+)
- Beat-grid engine abstraction (KDD-C6 deferred until second concrete impl lands)

### Implementation Handoff

**AI Agent Guidelines:**
- Follow all 27 KDD resolutions exactly as documented in the Core Architectural Decisions section
- Use implementation patterns from step-05 consistently (11 net-new patterns + inheritance from project-context.md's 113 rules)
- Respect project structure from step-06 (subfolder threshold, target boundaries, branch model)
- Refer to this document for all architectural questions before improvising
- Apply 5-layer review cadence per project-context.md for any story with new public API or DSP behavior
- For KDD-A6: stage migrations across 3 stories, `@Tag`-gated floors per stage, atomic byte→semantic equality replacement at Stage 3

**First implementation priority:**

Tier-1 Story A1 — introduce `SignalParticipation` (KDD-S1) + `SignalParticipationTraceEntry` (KDD-T0, same PR) + `UnifiedSignalPool` adapter (KDD-A6 Stage 1). Pre-1.0 break authorized; byte-equality scaffolding remains green. This is the foundation every other epic builds on.

**Recommended story sequence:**

1. Story A1: KDD-S1 + KDD-T0 typed-evidence + KDD-A6 Stage 1 adapter
2. Story A2: KDD-S2 `FeatureSubstrate` + `OnsetFeaturesBuilder` (+ `MLFeatureFrames` relocation)
3. Story A3: KDD-A6 Stage 2 — migrate `MetadataCorroborator` to consume pool
4. Story A4: KDD-A6 Stage 3 — flip `merge` signature; semantic-equality replaces byte-equality atomically
5. Story A5: KDD-A1 type taxonomy split (`SignalWeights` + `OctaveEquivalencePolicy` + `BPMSelectionPolicy` rename) + KDD-A2/A3/A4/A4a/A5 derivations
6. Epic B / C / D / E stories can begin in parallel after Story A4 lands (some Epic E preparation can pre-stage)


