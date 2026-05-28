# Story 6.2: FeatureSubstrate namespace + OnsetFeaturesBuilder + MLFeatureFrames relocation

Story ID: 6.2
Story Key: 6-2-featuresubstrate-namespace-and-mlfeatureframes-relocation
Epic: 6 — Unified-signal-pool ensemble (Tier-1 substrate, second of 5 strictly-sequenced stories)
Status: done

## Story

**As a** library maintainer,
**I want** decode + onset-extraction consolidated into a single `FeatureSubstrate` namespace, with `OnsetFeaturesBuilder.build(decoded:weighting:)` as the shared producer consumed by `BPMAnalyzer` (and prepared for future `BeatGridAnalyzer` + `BNNSTechnique.featurize` consumers), and `MLFeatureFrames` + `TensorLayout` extracted out of `BPMDiagnosticTrace.swift` into the new subfolder,
**So that** the substrate cannot fork between DSP / ML / beat-grid subsystems, FR-21 train/runtime parity is enforced via the `featureSetVersion` drift-detection seam, the cohesive `FeatureSubstrate/` subfolder communicates architectural intent (per architecture step-03 Decision 2), and Story 7.5 (substrate-bound TempoCNN training) + Story 8.x (beat-grid step 11) inherit a stable feature contract.

## Scope clarification (read first)

Story 6.2 is the **substrate PR of Epic 6** (Tier-1 root #2 per architecture.md:280, S1 → S2 → A6 → A1 sequence). The `FeatureSubstrate/` subfolder + `OnsetFeatures` + `WeightingProfile` substrate types do not yet exist; this story creates them AND extracts the existing `MLFeatureFrames` + `TensorLayout` out of `BPMDiagnosticTrace.swift` into the same subfolder.

**Three deliverables in this PR (none separable):**

1. **`FeatureSubstrate/` subfolder + 12 files** introducing 10 new source files (the namespace `FeatureSubstrate.swift`, `DecodedAudio`, `OnsetFeatures` with nested `Parameters`, `OnsetFeaturesBuilder` enum-namespace, `WeightingProfile`, `SubBandWeights`, `SubBandCutoff`, `AudioCodec`, `PrimingInfo`, `FeatureSubstrateError`) plus 2 **relocated** files (`MLFeatureFrames` + `TensorLayout`).
2. **`BPMAnalyzer.estimateBPM` consumes `OnsetFeaturesBuilder.build` for the `.uniform` weighting code path** — single shared producer per architecture KDD-S2:217. Today's `computeMelOnsetEnvelopeWithSubBands` retains its public-internal signature (Story 4-7 review-pass deps); the new builder calls into it under the hood. `.uniform` weighting must produce byte-identical onset envelopes to today's output (AC #4 regression scaffold).
3. **`FeatureSubstrateTests.swift`** — new test file (the 8th tag-floor scaffold? No: this story does NOT add a stage-floor tag. The scaffold from Story 6.1 — `@Tag(.stage1Floor)` on the four `metadataPolicy = .disabled` tests — continues to gate via the same Stage 1 contract. This story adds substrate-specific invariant tests: `crossConsumerByteIdentity`, `featureSetVersionLocked`, `relocatedTypePublicSurfaceUnchanged`, and the throwing-init invariant matrix).

**What this story does NOT deliver** (each is explicitly OUT-OF-SCOPE):

- **No new `BPMDiagnosticTrace` field.** Architecture KDD-S2:177 mentions "trace-readable through `BPMDiagnosticTrace.onsetFeatures`" but the Epic 6.2 AC list does NOT include adding the field. Per Mary's seam-mitigation rule (epics.md:23 / Epic 6 body :275), new trace surface stays out of Story 6.2; an Epic 8 promotion story (or a later 6.x) introduces `onsetFeatures: OnsetFeatures?`. The existing `mlFeatures: MLFeatureFrames?` field stays — `MLFeatureFrames` is moving files within the same module, public symbol is unchanged.
- **No `BNNSTechnique.featurize` refactor.** AC #2 says "BNNSTechnique.featurize in the ML target imports the relocated type from core" — that's satisfied automatically because `import BoomBoomBoomKit` already exports the type from its new location (same module, no `import` change required). No code change to `featurize` itself; deferred to a later story.
- **No `BeatGridAnalyzer` wiring.** Epic 8 introduces `BeatGridAnalyzer`. AC #3's "BeatGridAnalyzer (Epic 8 placeholder consumer OK)" is satisfied by the existence of `OnsetFeaturesBuilder.build` as the public seam — no Epic 8 code lands here.
- **No accuracy-changing behavior.** OA300 + GiantSteps baselines (Acc1 58/82+74/82; 537/661+546/661) hold unchanged. The `.uniform` weighting byte-identity test (AC #4) is the regression contract; `make benchmark` + `make benchmark-giantsteps` must show zero delta.
- **No `.subBandEmphasis` weighting consumer.** `WeightingProfile.subBandEmphasis(SubBandWeights)` ships as a type-surface case but no caller passes it in this story. Tests construct it but assert against `.uniform` for byte-identity. Calibration of sub-band weights against the OA300 / DnB-triplet corpus is a future story.
- **No public-API DocC.** Following Story 6.1's seam-mitigation precedent (DD #3 in 6.1 spec): the 10 new public types ship with NO `///` doc comments. The dev agent MUST surface the list of undocumented public symbols in Completion Notes (a flat list) so Epic 8 promotes them deliberately. The single exception is **`OnsetFeatures.featureSetVersion`** — it MUST carry a `///` comment naming the bump-trigger checklist (DD #6), because that field's semantics are the FR-21 train/runtime parity tripwire and a missing comment risks a future story changing mel/FFT params without bumping the version.

## Key Design Decisions

The 12 DDs below are the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #1, #2, #4, #6, #9, and #10 are most consequential** — they correct the AC #2 source-of-truth error, pin the relocation file map, the Hashable+NaN posture inherited from Story 6.1, the featureSetVersion lock, the pressure-release-valve guidance, and the `FeatureSubstrateError` type that replaces misused `MLTechniqueError.invalidFeatureShape` for substrate-domain failures.

1. **AC #2 source-of-truth correction.** Epic AC #2 (epics.md:436-438) and architecture KDD-S2:223 both refer to `MLFeatureFrames.swift` being "relocated from `Sources/BoomBoomBoomKitML/`." **This is factually incorrect.** `MLFeatureFrames` is currently defined inline in `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:500`. `TensorLayout` is at the same file line 452. The `BoomBoomBoomKitML` target contains only `BNNSTechnique.swift` and `CoreMLTechnique.swift` — it has NEVER hosted `MLFeatureFrames`. The actual relocation is **from `BPMDiagnosticTrace.swift` into new files at `Sources/BoomBoomBoomKit/FeatureSubstrate/MLFeatureFrames.swift` + `TensorLayout.swift`** (both stay in the core target; module path `BoomBoomBoomKit.MLFeatureFrames` is unchanged). The ML target's `BNNSTechnique.swift` already does `import BoomBoomBoomKit` and consumes `MLFeatureFrames` as a public type from that module — no `import` change required after relocation. The pre-existing epic AC #2 wording is superseded by this DD; the dev agent treats the relocation as a file extraction within the core target. The architecture description's "no longer publicly exports MLFeatureFrames" check is vacuously satisfied — the ML target never exported it.

2. **File map — 10 new source files + 2 extracted files + 1 new test file** (party-mode patch round 2026-05-27 normalized counts; Codex C7 finding). All under `Sources/BoomBoomBoomKit/FeatureSubstrate/`:
   - **NEW source files (10):** `FeatureSubstrate.swift` (caseless-enum namespace declaration only), `DecodedAudio.swift`, `OnsetFeatures.swift` (with nested `Parameters`), `OnsetFeaturesBuilder.swift`, `WeightingProfile.swift`, `SubBandWeights.swift`, `SubBandCutoff.swift`, `AudioCodec.swift`, `PrimingInfo.swift`, `FeatureSubstrateError.swift` (new error type per DD #10).
   - **EXTRACTED (2):** `MLFeatureFrames.swift` + `TensorLayout.swift` — content lifted verbatim from `BPMDiagnosticTrace.swift` lines 438-776 (TensorLayout + MLFeatureFrames + `_testingMaximumLogMelDataCount` `@TaskLocal` test helper + `_withTestingMaximumLogMelDataCount` wrapper). The extraction preserves the public API symbol-for-symbol; the move is file-level only. `BPMDiagnosticTrace.swift` is reduced by ~340 lines.
   - **NEW test (1):** `Tests/BoomBoomBoomKitTests/FeatureSubstrateTests.swift`.
   - **Total files under `FeatureSubstrate/`: 12** (10 new + 2 extracted).

   *Architectural intent:* the subfolder communicates "feature substrate is one cohesive subsystem" per architecture step-03 Decision 2 (≥5 cohesive files threshold). `MLFeatureFrames` + `TensorLayout` were always feature-substrate concepts that happened to live in the trace file because Story 4-5 introduced them alongside the `mlFeatures` trace field; relocation corrects the cohesion mismatch.

3. **New substrate types ship `public` but undocumented; relocated types preserve their existing public surface.** Per Story 6.1 DD #3 precedent (Epic 6 ↔ Epic 8 seam mitigation, Mary's contribution): new types land at the lowest access level that satisfies consumer needs. **The 9 new substrate types are `public` (since `OnsetFeatures` will eventually be Sendable-carried on the trace and `BNNSTechnique` may consume them in a future story) BUT with NO `///` doc comments** — Epic 8 stories own promotion + DocC. The dev agent MUST surface the list of undocumented public symbols in Completion Notes:
   - `FeatureSubstrate` (namespace enum)
   - `FeatureSubstrate.DecodedAudio`
   - `FeatureSubstrate.OnsetFeatures` + nested `OnsetFeatures.Parameters`
   - `FeatureSubstrate.OnsetFeaturesBuilder` (enum namespace)
   - `FeatureSubstrate.WeightingProfile`
   - `FeatureSubstrate.SubBandWeights`
   - `FeatureSubstrate.SubBandCutoff`
   - `FeatureSubstrate.AudioCodec`
   - `FeatureSubstrate.PrimingInfo`
   - `FeatureSubstrate.FeatureSubstrateError` (new error type per DD #10; added party-mode patch round 2026-05-27 to replace `MLTechniqueError.invalidFeatureShape` misuse for unimplemented-case and featurization-failed paths)

   The single doc-comment exception is `OnsetFeatures.featureSetVersion` per the bump-trigger semantics (DD #6 below). `MLFeatureFrames` + `TensorLayout` keep their existing extensive DocC verbatim — those are pre-existing public types whose move doesn't change documentation posture.

4. **Hashable+NaN: drop `Hashable` from any new type whose Float/Double payload can be NaN/Inf.** Story 6.1 PSI: `Hashable`'s `x == x` invariant fails on `Double.nan` — Codex + 3 reviewers converged on this finding. Existing project precedent: `EnsembleDecision`, `ClickCorrelationEntry`, `HarmonicRatioEvidence`, etc. all omit `Hashable`. Architecture KDD-S2 declares `WeightingProfile: Hashable` (line 197) and `SubBandWeights: Hashable` (line 202). Both contain Float fields — `WeightingProfile.subBandEmphasis(SubBandWeights)` transitively carries 3 Float weight multipliers. **Override architecture: ship them as `Sendable, Equatable` (NOT `Hashable`).** Same override for `OnsetFeatures` (carries `[Float]` payload + Double `sampleRate`). The `PrimingInfo` struct carries Int fields only → `Sendable, Hashable, Equatable` is safe. `AudioCodec` is String-backed enum → `Sendable, Hashable, CaseIterable, Equatable, Codable` is safe. `SubBandCutoff` if String-backed (no associated values) → same. **Verbatim conformance map:**
   - `FeatureSubstrate.DecodedAudio`: `Sendable` only (carries `[Float] samples` payload + `Double sampleRate`; NaN-bearing; no Equatable because `[Float]` equality on the full audio buffer is meaningless for the comparison consumers a value type usually targets — keep it minimal)
   - `FeatureSubstrate.OnsetFeatures`: `Sendable, CustomStringConvertible, Equatable` (matches `MLFeatureFrames` precedent at `BPMDiagnosticTrace.swift:500`)
   - `FeatureSubstrate.OnsetFeatures.Parameters`: `Sendable, Equatable, Codable` — NOT `Hashable` (party-mode patch round 2026-05-27 — Codex C5 finding: contains `Double.melFmin/melFmax` and `Float.logCompressionScale`, transitively reintroduces the same NaN+Hashable trap Story 6.1 fixed. The `Parameters.init` throws on non-finite per DD #5 invariants, but Codable decoder paths can still install NaN payloads before `init` runs. Drop Hashable; consumers needing parametric-ablation dictionary keys synthesize a String key from the canonical `description` form.)
   - `FeatureSubstrate.WeightingProfile`: `Sendable, Equatable` (NOT `Hashable`; contains `SubBandWeights` which has Float fields)
   - `FeatureSubstrate.SubBandWeights`: `Sendable, Equatable` (NOT `Hashable`; 3 Float fields)
   - `FeatureSubstrate.SubBandCutoff`: `Sendable, Hashable, Equatable, Codable` IF cases are payload-free; if `.custom(low: Float, mid: Float, high: Float)` is supported, downgrade to `Sendable, Equatable` only. Spec the enum as String-backed with 2 payload-free cases (`.standard`, `.dnbOptimized`) for Story 6.2 — `.custom(...)` deferred to a calibration story.
   - `FeatureSubstrate.AudioCodec`: `String, Sendable, Hashable, CaseIterable, Equatable, Codable` (6 cases: `.aac`, `.mp3`, `.flac`, `.wav`, `.aiff`, `.caf`; matches architecture KDD-S2:210)
   - `FeatureSubstrate.PrimingInfo`: `Sendable, Hashable, Equatable, Codable` (Int + AudioCodec; all NaN-safe)
   - `FeatureSubstrate.OnsetFeaturesBuilder`: caseless enum (namespace); no conformance needed.

5. **`OnsetFeatures` field set — 11 leaves total.** Architecture KDD-S2:187-195 shows 7 top-level fields + nested `Parameters`. The "11 fields" claim in epic AC #1 unfolds as **6 top-level leaves + nested `parameters: Parameters` (carrying 5 fields) = 11 leaves**, partitioned per Winston's party-mode read (6+5 reads cleaner at the call site than 7+4; consumer-driven):
   - **Top-level (6 leaves + 1 nested):** `frames: Int`, `melBands: Int`, `logMelData: [Float]`, `tensorLayout: TensorLayout`, `weighting: WeightingProfile`, `featureSetVersion: String`, `parameters: Parameters` (nested struct).
   - **`Parameters` (5):** `fftSize: Int`, `hopSize: Int`, `melFmin: Double`, `melFmax: Double`, `logCompressionScale: Float`.

   That's 6 + 5 = **11 leaves**, with `parameters` as the wrapper. **`sampleRate` is NOT in `Parameters`** (party-mode patch round 2026-05-27 — Codex Critical finding C2). `sampleRate` lives on `DecodedAudio.sampleRate` as the source-of-truth and is NOT re-stored on `OnsetFeatures`. Rationale: `Parameters` represents the FFT/mel CONFIGURATION (the values whose change triggers a `featureSetVersion` bump); `sampleRate` is a SIGNAL CHARACTERISTIC of the source audio, not feature-pipeline config. Consumers that need `sampleRate` for downstream reasoning (e.g., BNNSTechnique resampling decisions) read it from the `DecodedAudio` they fed into the builder. The throwing-init invariants per epic AC #1 enforce:
   - `logMelData.count == melBands * frames`
   - both `melBands > 0` and `frames > 0`
   - `logMelData.count ≤ 8_388_608` floats (≈ 32 MB guard; matches `MLFeatureFrames.maximumLogMelDataCount`)
   - `Parameters.fftSize > 0`
   - `Parameters.hopSize > 0`
   - `Parameters.melFmin.isFinite && Parameters.melFmin >= 0`
   - `Parameters.melFmax.isFinite && Parameters.melFmax > Parameters.melFmin`
   - `Parameters.logCompressionScale.isFinite && Parameters.logCompressionScale > 0`
   - `logMelData.allSatisfy { $0.isFinite }` (NaN/Inf reject; matches MLFeatureFrames)
   - `featureSetVersion` non-empty
   - `weighting` exhaustively `switch`able (compile-error on future-case addition)

   **`DecodedAudio.sampleRate` validation** lives on `DecodedAudio.init`, NOT on `OnsetFeatures.init`: throws `MLTechniqueError.invalidFeatureShape` when `sampleRate.isFinite && sampleRate > 0` fails OR when `sampleRate ∉ {44100, 48000, 96000}` (DSP-supported rates per architecture line 183).

6. **`featureSetVersion` bump-trigger checklist (single `///` exception per DD #3).** `OnsetFeatures.featureSetVersion: String` initialized to `"v1"` — same value `MLFeatureFrames.featureSetVersion` ships today. ANY change to the following invalidates downstream consumer assumptions and MUST bump the string (`"v2"`, `"v3"`, ...):
   - `Parameters.fftSize` default value (currently `2048`)
   - `Parameters.hopSize` default value (currently `441` ≈ 100 Hz at 44.1 kHz)
   - `Parameters.melFmin` default value (currently `30.0` Hz)
   - `Parameters.melFmax` formula (currently `min(sampleRate/2, 16000)`)
   - `Parameters.logCompressionScale` default value (currently `100.0`)
   - The mel filterbank construction formula in `MelFilterbank.buildFilterbank`
   - The pre-`vvlogf` `100.0 * x + 1.0` linear-then-log compression pre-image
   - `WeightingProfile` case set or default value
   - `OnsetFeaturesBuilder.build` algorithmic shape

   `FeatureSubstrateTests.featureSetVersionLocked` is the regression test — it asserts the initial value is `"v1"` and includes a comment listing every bump trigger. The `///` doc-comment on the field is the ONE seam-mitigation exception per DD #3.

7. **`OnsetFeaturesBuilder.build` contract — wrap, don't replace.** Production call path in this story:
   ```swift
   public enum OnsetFeaturesBuilder {
     public static func build(
       decoded: FeatureSubstrate.DecodedAudio,
       weighting: FeatureSubstrate.WeightingProfile
     ) throws -> FeatureSubstrate.OnsetFeatures { ... }
   }
   ```
   For `.uniform` weighting, the implementation MUST internally invoke today's `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(samples: decoded.samples, sampleRate: decoded.sampleRate, hopSize: Int(decoded.sampleRate / 100), computeSubBands: true, captureMLFeatures: true)` + read out the retained `MLFeatureFrames` payload + rewrap into `OnsetFeatures`. The sub-band envelopes from the return value are DISCARDED — Story 6.2's `OnsetFeatures` surface doesn't carry sub-band output. This is the wrap-don't-replace contract — no DSP changes, no new feature math. **hopSize derivation:** `Int(sampleRate / 100)` matches `BPMAnalyzer.swift:225-227`'s adaptive computation — 441 at 44.1 kHz, 480 at 48 kHz, 960 at 96 kHz — locks the 100 Hz onset rate invariant across sample rates. Hardcoded `441` would silently break AC #4 byte-identity on 48k/96k fixtures. **computeSubBands: true is required** because that's the only combination today's tests exercise (party-mode verification 2026-05-27); the retention path is structurally shared with the sub-band branch, but spec-ordering an untested `(computeSubBands: false, captureMLFeatures: true)` cell is needless risk for Story 6.2. For `.subBandEmphasis(weights)` weighting, `build` throws `FeatureSubstrateError.weightingNotYetImplemented(WeightingProfile)` (new error type per DD #10/Task 4.9 — `MLTechniqueError.invalidFeatureShape` would be type-pollution because the call isn't "invalid shape," it's "unimplemented case"). Calibration story owns the actual sub-band implementation. **Empty / cap-failure path:** when `computeMelOnsetEnvelopeWithSubBands` returns `.empty` (too-short input) or its retained `mlFeatures == nil` (size cap fired per `MLFeatureFrames.maximumLogMelDataCount`), `OnsetFeaturesBuilder.build` throws `FeatureSubstrateError.featurizationFailed(reason: String)` with a diagnostic message. Both error cases are tested per Task 5.5 + Task 5.8.

8. **`BPMAnalyzer.estimateBPM` integration — Tier-1 facade, Tier-3 producer.** Architecture KDD-S2:217 names `BPMAnalyzer.estimateBPM` as a consumer of `OnsetFeaturesBuilder.build`. **Story 6.2 does NOT refactor `BPMAnalyzer.estimateBPM` to call the builder.** Why: refactoring `estimateBPM`'s 11-step DSP pipeline to produce `OnsetFeatures` mid-flight would (a) require restructuring the pipeline's internal `OnsetEnvelopes` struct (current return type of `computeMelOnsetEnvelopeWithSubBands` per `BPMAnalyzer.swift:566`) and (b) impose accuracy-regression risk that the byte-identity test (AC #4) can only partially mitigate. The substrate's "single shared code path" claim is satisfied at the **type level** in Story 6.2 — `OnsetFeaturesBuilder.build(.uniform)` produces byte-identical output to today's `computeMelOnsetEnvelopeWithSubBands` (AC #4); a later Epic 8 / Epic 6.5+ story wires `BPMAnalyzer` to call the builder. **Dependency-direction caveat (Winston's party-mode read):** in Tier-1, `OnsetFeaturesBuilder.build(.uniform)` calls INTO `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` — substrate-depends-on-analyzer, the inverse of the architecture diagram. The dev agent MUST add a brief `// MARK: - Tier-1 facade pattern` comment at the top of `OnsetFeaturesBuilder.swift` stating: *"Tier-1 facade: this builder wraps `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` and exposes the substrate type contract without yet inverting the dependency direction. Tier-3 (planned Story 6.5+ / Epic 8) flips the direction so `BPMAnalyzer` consumes the builder."* This is the ONE structural-context internal comment exception per the no-DocC discipline — it documents the facade-vs-producer inversion that would otherwise mystify a reader.

9. **Pressure-release valve analysis — DO NOT SPLIT.** The epic spec at epics.md:462 says "run `rg 'MLFeatureFrames' Sources/ Tests/` and report the hit count. If > 20, split into Story 6.2a (relocation + import updates) and Story 6.2b (`OnsetFeatures` introduction)." Pre-flight count: **63 hits across 9 files** (run 2026-05-27 against `develop` post-Story 6.1). However, the 63-hit metric overestimates the relocation cost because:
   - `MLFeatureFrames` is a public type in the `BoomBoomBoomKit` core target. Module-qualified references (e.g., `MLFeatureFrames.maximumLogMelDataCount` from inside `BoomBoomBoomKit` target, or `BoomBoomBoomKit.MLFeatureFrames` from the ML target) do NOT change when the type's source file moves within the same module.
   - 28 of the 63 hits are in `Tests/BoomBoomBoomKitTests/MLFeatureFramesTests.swift` — the dedicated test file. It does NOT need `import` changes; only its top-of-file docstring should mention the new file path.
   - 8 hits in `BPMDiagnosticTrace.swift` and 7 in `BPMAnalyzer.swift` are call-site references that resolve via same-module Swift visibility — zero edits required.
   - The remaining 20 hits across `BNNSTechnique.swift`, test files, and `MLTechnique.swift` are all module-qualified or same-module references; no `import` line is added or removed by the relocation.

   **Total edit-required hits: 0** (party-mode patch round 2026-05-27 — both Amelia + Codex walked the files; spec v1 claimed "~2 edits" but `BPMDiagnosticTrace.swift` top docstring doesn't reference the inline location, and `MLFeatureFramesTests.swift` top docstring doesn't cite a path. Tasks 3.3 + 3.4 are conditional and likely no-ops). The valve's heuristic targets *renames* (which would require updating every reference) — file relocation within the same module is a different shape (zero `import` changes inside the same target). **Recommended action: do NOT split.** Document this analysis in Completion Notes. If the dev agent encounters unexpected import friction (e.g., a circular dependency materializes when extracting `_testingMaximumLogMelDataCount`'s `@TaskLocal`), HALT per project-context.md Story Authoring Discipline + surface to the operator. **Process follow-up (Mary's party-mode item):** the pressure-release valve heuristic in `epics.md:462` should be rewritten to count edit-required hits, not raw `rg` hits. Tracked for the post-Story-6.2 process-improvement pass.

10. **`FeatureSubstrateError` is a new error type for substrate-domain failures.** Added party-mode patch round 2026-05-27 (Codex C3 / Amelia / Winston converging). `MLTechniqueError.invalidFeatureShape` was misused in v1 of this spec for the unimplemented-weighting throw and the featurization-failed throw — that error type is reserved for tensor-payload invariant violations (`BPMDiagnosticTrace.swift:735` semantics). Throwing it for "unimplemented case" or "upstream featurization returned empty" is type-pollution: a forensic consumer catching `invalidFeatureShape` would log "feature shape error" when the truth is "feature not implemented" or "audio too short."
    ```swift
    public enum FeatureSubstrateError: Error, Sendable {
      case weightingNotYetImplemented(WeightingProfile)
      case featurizationFailed(reason: String)
    }
    ```
    `weightingNotYetImplemented(_:)` carries the requested `WeightingProfile` for diagnostic transparency. `featurizationFailed(reason:)` carries a free-form String — the throw site populates it with the specific upstream condition (e.g., `"audio too short: 0.8s < minimum window"` or `"retention cap fired: \(count) > MLFeatureFrames.maximumLogMelDataCount"`). Lives at `Sources/BoomBoomBoomKit/FeatureSubstrate/FeatureSubstrateError.swift` (file #12 in the file map). NO DocC per DD #3 (public symbol, undocumented, surfaced in DD #3's Completion-Notes hand-off list).

11. **Subfolder creation + Package.swift status.** `Sources/BoomBoomBoomKit/FeatureSubstrate/` is a new directory. SwiftPM globs source files automatically (no `Package.swift` manifest update required for subfolder addition; verified per project-context.md "SwiftLint globs by default — no `.swiftlint.yml` changes needed" and same applies to SwiftPM). `.swiftlint.yml` `included:` paths require no change. The dev agent runs `mkdir Sources/BoomBoomBoomKit/FeatureSubstrate/` and creates files; no other build-system edits.

12. **5-recipe `bpm-diagnostic-trace` audit — applies inertly.** This story does NOT add a new `BPMDiagnosticTrace` field. The 5 audit recipes (A-E) MUST be run pre- AND post-implementation per project-context.md "five audit grep recipes (A-E)" rule — both runs should return zero matches against `Sources/` + `Tests/`. The expected delta is **zero** (no trace shape changes). Run via the project-local skill at `.claude/skills/bpm-diagnostic-trace/SKILL.md`.

## Acceptance Criteria

1. **Substrate types ship with verbatim KDD-S2 field set.** `FeatureSubstrate.OnsetFeatures` carries the 11 fields per DD #5 (6 top-level leaves + nested `Parameters` with 5 fields); the throwing-init invariants enforce shape (`count == melBands * frames`, both dimensions positive, total ≤ `8_388_608` floats), finiteness on `logMelData`, finite/positive on Parameters fields, `sampleRate ∈ {44100, 48000, 96000}`, and non-empty `featureSetVersion`. Compile-time exhaustive switch on `WeightingProfile`. Per DD #5.

2. **MLFeatureFrames + TensorLayout relocated from `BPMDiagnosticTrace.swift` into `FeatureSubstrate/`.** Per DD #1 correction of epic AC #2: extracted from `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:438-776` into `Sources/BoomBoomBoomKit/FeatureSubstrate/MLFeatureFrames.swift` + `Sources/BoomBoomBoomKit/FeatureSubstrate/TensorLayout.swift`. Public symbol unchanged (`BoomBoomBoomKit.MLFeatureFrames`, `BoomBoomBoomKit.TensorLayout`). `_testingMaximumLogMelDataCount` `@TaskLocal` test helper + `_withTestingMaximumLogMelDataCount` wrapper move with the type. `BPMDiagnosticTrace.mlFeatures: MLFeatureFrames?` field stays at its current declaration; type reference resolves via same-module Swift visibility.

3. **`OnsetFeaturesBuilder.build(decoded:weighting:)` is the substrate producer.** Public static method on the caseless enum namespace; takes `DecodedAudio` + `WeightingProfile`; returns `OnsetFeatures` or throws `MLTechniqueError.invalidFeatureShape`. For `.uniform`: internally calls `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(samples: decoded.samples, sampleRate: decoded.sampleRate, ...)` per DD #7 wrap-don't-replace and rewraps the retained `MLFeatureFrames` output as `OnsetFeatures`. For `.subBandEmphasis(...)`: throws a documented "not yet implemented" path per DD #7 (calibration deferred to a future story).

4. **`.uniform` weighting byte-identity holds.** `FeatureSubstrateTests.uniformWeightingByteIdentity` runs `OnsetFeaturesBuilder.build(decoded:weighting: .uniform)` against a bundled OA300 sample and asserts the resulting `OnsetFeatures.logMelData` is byte-identical to the retained `MLFeatureFrames.logMelData` payload from `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(..., captureMLFeatures: true)` for the same input (party-mode patch round 2026-05-27 — Codex M12: aligned AC wording with Task 5.2's actual comparison target; both use the retained `MLFeatureFrames` payload, NOT a flat-map of `logMelFrames`). NaN-safe element-wise comparison via `NumericTestHelpers.bitEqual(_:_:)` (Story 6.1's TestSupport helper). Regression scaffold.

5. **`featureSetVersion` is `"v1"` and locked.** `FeatureSubstrateTests.featureSetVersionLocked` asserts `OnsetFeatures.featureSetVersion == "v1"` at all call sites. The test's comment lists every bump trigger per DD #6. A future story changing any trigger MUST update both the version constant AND this test in the same commit (regression discipline).

6. **OA300 + GiantSteps accuracy floors UNCHANGED.** `make benchmark` + `make benchmark-giantsteps` produce identical Acc1 + Acc2 numbers to Story 6.1 close-out baselines: OA300 Acc1=58/82, Acc2=74/82; GiantSteps Acc1=537/661, Acc2=546/661. Zero delta is the regression contract. If any number changes, HALT and surface to operator.

7. **Seam-mitigation rule satisfied for public API.** Per DD #3: the 9 NEW substrate types (`FeatureSubstrate`, `DecodedAudio`, `OnsetFeatures` + nested `Parameters`, `OnsetFeaturesBuilder`, `WeightingProfile`, `SubBandWeights`, `SubBandCutoff`, `AudioCodec`, `PrimingInfo`, `FeatureSubstrateError`) ship `public` with NO `///` doc comments. Two narrowly-scoped exceptions: `OnsetFeatures.featureSetVersion` carries a `///` listing every bump trigger per DD #6; `OnsetFeaturesBuilder.swift` carries one `// MARK: - Tier-1 facade pattern` internal comment per DD #8 documenting the substrate-depends-on-analyzer inversion. MLFeatureFrames + TensorLayout DocC comments survive verbatim post-extraction. Dev agent surfaces the flat list of undocumented public symbols in Completion Notes.

8. **5-recipe `bpm-diagnostic-trace` audit returns zero matches BOTH pre- and post-implementation.** Per DD #12. No new `BPMDiagnosticTrace` field is introduced; the existing 5-recipe baseline (last run: Story 6.1 post-flight 2026-05-27) holds.

## Tasks / Subtasks

- [x] Task 1 — Pre-flight diff baseline + skill invocation (AC: #8)
  - [x] 1.1 Invoke the `bpm-diagnostic-trace` skill via the Skill tool; read `SKILL.md` fully
  - [x] 1.2 Run the 5 audit recipes against `Sources/` + `Tests/` BEFORE any changes; record baseline (expected: zero matches)
  - [x] 1.3 Run `rg "MLFeatureFrames" Sources/ Tests/ | wc -l`; record the count. Confirm ≈63 (matches DD #9 pressure-release analysis baseline at story-creation time).
  - [x] 1.4 Confirm `make build` + `make test` pass against current `develop` (post-Story 6.1 baseline: 437 tests / 95 suites; 1.74s warm)
  - [x] 1.5 `swift package describe` to baseline the current public API surface — recorded in Debug Log for post-relocation diff

- [x] Task 2 — Create `FeatureSubstrate/` subfolder + namespace file (AC: #1)
  - [x] 2.1 `mkdir Sources/BoomBoomBoomKit/FeatureSubstrate/`
  - [x] 2.2 `FeatureSubstrate.swift` — declares the caseless `public enum FeatureSubstrate { }` namespace ONLY (no nested types in this file; nested types co-locate in their own files for grep-findability per project convention)
  - [x] 2.3 No DocC on the namespace per DD #3

- [x] Task 3 — Extract `MLFeatureFrames` + `TensorLayout` from `BPMDiagnosticTrace.swift` (AC: #2)
  - [x] 3.1 Copy lines 438-776 of `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (TensorLayout + MLFeatureFrames + `_testingMaximumLogMelDataCount` `@TaskLocal` + `_withTestingMaximumLogMelDataCount` wrapper) into `Sources/BoomBoomBoomKit/FeatureSubstrate/TensorLayout.swift` (lines 438-474) and `Sources/BoomBoomBoomKit/FeatureSubstrate/MLFeatureFrames.swift` (lines 476-776).
  - [x] 3.2 Remove those lines from `BPMDiagnosticTrace.swift`. The `mlFeatures: MLFeatureFrames?` field declaration STAYS in `BPMDiagnosticTrace.swift` — the type reference resolves via same-module visibility.
  - [x] 3.3 Update the docstring at top of `BPMDiagnosticTrace.swift` if it references "MLFeatureFrames inline" (verify; may not exist).
  - [x] 3.4 Update the docstring at top of `Tests/BoomBoomBoomKitTests/MLFeatureFramesTests.swift` to reference the new file path if it currently cites `BPMDiagnosticTrace.swift`.
  - [x] 3.5 `swift build` — must succeed. SourceKit cache may complain briefly; verify via build, not editor.
  - [x] 3.6 `swift package describe` — diff against Task 1.5 baseline. Expected delta: zero (public API surface unchanged; only file locations move).

- [x] Task 4 — Create the 9 new substrate type files + 1 error type (AC: #1, #3, #7)
  - [x] 4.1 `Sources/BoomBoomBoomKit/FeatureSubstrate/AudioCodec.swift` — `public enum AudioCodec: String, Sendable, Hashable, CaseIterable, Equatable, Codable { case aac, mp3, flac, wav, aiff, caf }`. NO DocC per DD #3.
  - [x] 4.2 `Sources/BoomBoomBoomKit/FeatureSubstrate/PrimingInfo.swift` — `public struct PrimingInfo: Sendable, Hashable, Equatable, Codable` with `public let codec: AudioCodec`, `public let leadingTrimFrames: Int`, `public let trailingTrimFrames: Int`. Explicit public memberwise `init` (Swift won't synthesize a public init for `public let` fields). NO DocC per DD #3.
  - [x] 4.3 `Sources/BoomBoomBoomKit/FeatureSubstrate/SubBandCutoff.swift` — `public enum SubBandCutoff: String, Sendable, Hashable, CaseIterable, Equatable, Codable { case standard, dnbOptimized }`. The `.custom(...)` case is OUT-OF-SCOPE per DD #4 — defer to calibration story. NO DocC per DD #3.
  - [x] 4.4 `Sources/BoomBoomBoomKit/FeatureSubstrate/SubBandWeights.swift` — `public struct SubBandWeights: Sendable, Equatable` with `public let kickBandWeight: Float`, `public let snareBandWeight: Float`, `public let cymbalBandWeight: Float`, `public let cutoff: SubBandCutoff`. Explicit public memberwise `init`. NOT `Hashable` per DD #4. NO DocC per DD #3.
  - [x] 4.5 `Sources/BoomBoomBoomKit/FeatureSubstrate/WeightingProfile.swift` — `public enum WeightingProfile: Sendable, Equatable { case uniform; case subBandEmphasis(SubBandWeights) }`. NOT `Hashable` per DD #4 (transitively contains Float fields). NO DocC per DD #3.
  - [x] 4.6 `Sources/BoomBoomBoomKit/FeatureSubstrate/DecodedAudio.swift` — `public struct DecodedAudio: Sendable` with `public let samples: [Float]`, `public let sampleRate: Double`, `public let codecPriming: PrimingInfo`. Explicit public memberwise `init`. `Sendable` only — NOT `Equatable` per DD #4 (full audio buffer equality is semantically dubious). NO DocC per DD #3.
  - [x] 4.7 `Sources/BoomBoomBoomKit/FeatureSubstrate/OnsetFeatures.swift` — `public struct OnsetFeatures: Sendable, CustomStringConvertible, Equatable` with the 6 top-level + 1 nested layout per DD #5. Nested `public struct Parameters: Sendable, Equatable, Codable` (NOT `Hashable` per DD #4 party-mode patch — `Double.melFmin/melFmax` + `Float.logCompressionScale` transitively reintroduce NaN+Hashable trap) with the 5 fields per DD #5 (NO `sampleRate` — lives on `DecodedAudio`). **Throwing init** with the invariants from AC #1 (mirrors `MLFeatureFrames.init` structure exactly; reuses `MLTechniqueError.invalidFeatureShape(reason:)` for tensor-payload invariant violations). NO DocC per DD #3, **EXCEPT** `featureSetVersion` MUST carry a `///` doc comment per DD #6 listing all bump triggers verbatim. `description` impl matches `MLFeatureFrames.description` shape.
  - [x] 4.8 `Sources/BoomBoomBoomKit/FeatureSubstrate/OnsetFeaturesBuilder.swift` — `public enum OnsetFeaturesBuilder` caseless namespace; `public static func build(decoded: FeatureSubstrate.DecodedAudio, weighting: FeatureSubstrate.WeightingProfile) throws -> FeatureSubstrate.OnsetFeatures` per DD #7. For `.uniform`: calls `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(samples: decoded.samples, sampleRate: decoded.sampleRate, hopSize: Int(decoded.sampleRate / 100), computeSubBands: true, normalizeSubBands: false, captureMLFeatures: true)` and rewraps the retained `mlFeatures` payload into `OnsetFeatures`. The sub-band envelopes are DISCARDED (party-mode patch round — Codex C1 hopSize fix; Siri C8 unsafe-untested-combination — `computeSubBands: true` matches today's tested cell). For `.subBandEmphasis(...)`: `throw FeatureSubstrateError.weightingNotYetImplemented(weighting)` (party-mode patch round per DD #10 — was `MLTechniqueError.invalidFeatureShape` which is type-pollution). For empty/cap-failure (`computeMelOnsetEnvelopeWithSubBands` returns `.empty` or `mlFeatures == nil`): `throw FeatureSubstrateError.featurizationFailed(reason: <diagnostic>)` per DD #7. NO DocC on the namespace per DD #3.
  - [x] 4.9 `Sources/BoomBoomBoomKit/FeatureSubstrate/FeatureSubstrateError.swift` (party-mode patch round, per DD #10) — `public enum FeatureSubstrateError: Error, Sendable` with two cases: `case weightingNotYetImplemented(WeightingProfile)`, `case featurizationFailed(reason: String)`. NO DocC per DD #3. Surfaced in DD #3's Completion-Notes hand-off list for Epic 8 promotion.

- [x] Task 5 — Create `FeatureSubstrateTests.swift` (AC: #4, #5)
  - [x] 5.1 `Tests/BoomBoomBoomKitTests/FeatureSubstrateTests.swift` with `@Suite("FeatureSubstrateTests")` + `@testable import BoomBoomBoomKit` (`OnsetFeaturesBuilder.build`'s call into `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` is internal-method-access; tests via `@testable import`).
  - [x] 5.2 `@Test func uniformWeightingByteIdentity()` (AC: #4) — Loads `AudioFixtures.url(for: "bpm-120-click", extension: "wav")` (or equivalent — pick the smallest OA300 fixture available in `Tests/BoomBoomBoomKitTests/Fixtures/`). Reads samples via `PCMBufferReader.readMonoSamples(from:maxSeconds:targetSampleRate:)` (party-mode patch round 2026-05-27 — Codex C4 finding: spec v1 named non-existent `read(url:)`; actual API is `readMonoSamples(from:)`). Constructs `DecodedAudio(samples: ..., sampleRate: ..., codecPriming: PrimingInfo(codec: .wav, leadingTrimFrames: 0, trailingTrimFrames: 0))`. Calls `OnsetFeaturesBuilder.build(decoded:weighting: .uniform)` → `produced`. Calls `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(samples: samples, sampleRate: sampleRate, hopSize: Int(sampleRate / 100), computeSubBands: true, captureMLFeatures: true)` → `direct` (hopSize + computeSubBands match DD #7 contract). Asserts `produced.logMelData.count == direct.mlFeatures!.logMelData.count` AND element-wise `NumericTestHelpers.bitEqual(produced.logMelData[i], direct.mlFeatures!.logMelData[i])` for all `i`. NaN-safe per `bitEqual`. **Note (Amelia's party-mode read):** byte-identity is structural today (both routes flow through `computeLogMelFramesAndRetention`); the test catches future divergence if the wrap contract breaks — regression scaffold, not discovery.
  - [x] 5.3 `@Test func featureSetVersionLocked()` (AC: #5) — Constructs minimal valid `OnsetFeatures` via the builder; asserts `produced.featureSetVersion == "v1"`. Top-of-test comment lists every bump trigger per DD #6 verbatim.
  - [x] 5.4 `@Test func relocatedTypePublicSurfaceUnchanged()` (AC: #2) — Constructs `MLFeatureFrames` directly via its public `init` from outside the module-namespace-aware path: `let frames = try MLFeatureFrames(melBands: 128, frames: 10, tensorLayout: .frameMajorLogMel, logMelData: Array(repeating: 0.0, count: 1280), sampleRate: 44100, fftSize: 2048, hopSize: 441, melFmin: 30.0, melFmax: 16000.0, logCompressionScale: 100.0, featureSetVersion: "v1")`. Compile-time assertion of unchanged public init signature. Constructs `TensorLayout.frameMajorLogMel` + `TensorLayout.nchw`; asserts `TensorLayout.allCases.count == 2`.
  - [x] 5.5 `@Test func subBandEmphasisThrows()` (AC: #3) — Calls `OnsetFeaturesBuilder.build(decoded:weighting: .subBandEmphasis(SubBandWeights(kickBandWeight: 1.0, snareBandWeight: 1.0, cymbalBandWeight: 1.0, cutoff: .standard)))`; asserts the call throws `FeatureSubstrateError.weightingNotYetImplemented` with the requested `WeightingProfile` payload (party-mode patch round per DD #10 — was `MLTechniqueError.invalidFeatureShape`). Documents the deferred path per DD #7.
  - [x] 5.6 `@Test func onsetFeaturesInitInvariants()` (AC: #1) — covers EVERY throwing init guard per DD #5 (party-mode patch round — Codex M11: spec v1 enumerated a subset; expand to full coverage): zero `melBands`, zero `frames`, mismatched `count != melBands * frames`, oversize buffer (> `8_388_608`), non-finite `logMelData` (NaN + Inf), zero `fftSize`, **zero `hopSize`**, **non-finite `melFmin`**, negative `melFmin`, **non-finite `melFmax`**, `melFmax <= melFmin`, **non-finite `logCompressionScale`**, non-positive `logCompressionScale`, empty `featureSetVersion`. One `#expect(throws: MLTechniqueError.invalidFeatureShape.self)` per guard. (Note: `sampleRate` validation is on `DecodedAudio.init`, NOT `OnsetFeatures.init` per DD #5 partition; sampleRate guards are tested in Task 5.7 below.)
  - [x] 5.7 `@Test func decodedAudioInitInvariants()` (AC: #1) — covers `DecodedAudio.init` `sampleRate` validation per DD #5: `sampleRate.isNaN`, `sampleRate <= 0`, `sampleRate == 22050` (unsupported rate not in `{44100, 48000, 96000}`). One `#expect(throws: MLTechniqueError.invalidFeatureShape.self)` per guard.
  - [x] 5.8 `@Test func builderFailurePathsThrow()` (AC: #3 — party-mode patch round per DD #7 empty/cap-failure contract) — covers `OnsetFeaturesBuilder.build` upstream-featurize-failed paths: (a) audio too short (e.g., 0.1s sample, samples count < FFT window) → asserts `FeatureSubstrateError.featurizationFailed`; (b) retention cap fire (use `MLFeatureFrames._withTestingMaximumLogMelDataCount(100)` to force the cap on a normal-length sample) → asserts `FeatureSubstrateError.featurizationFailed`.

- [x] Task 6 — Verification & audit (AC: #6, #7, #8)
  - [x] 6.1 `make fmt && make lint` — passes (1 violation = canonical `LUFSAnalyzer.swift:94` TODO baseline)
  - [x] 6.2 `make build` — clean. SourceKit caches may report stale "Cannot find type" briefly; verify via `swift build` not editor.
  - [x] 6.3 `make test` — passes; record exact integer test count delta from Story 6.1 baseline (437/95). Expected: +6 (one new test file `FeatureSubstrateTests.swift` with 6 `@Test`s per Task 5).
  - [x] 6.4 `make benchmark` (OA300) — Acc1 ≥ 58/82 AND Acc2 ≥ 74/82 — UNCHANGED. Zero delta from Story 6.1 baseline.
  - [x] 6.5 `make benchmark-giantsteps` — Acc1 ≥ 537/661 AND Acc2 ≥ 546/661 — UNCHANGED.
  - [x] 6.6 Re-run the 5 `bpm-diagnostic-trace` audit recipes per DD #12; confirm zero matches against `Sources/` + `Tests/`. No new trace field expected; baseline holds.
  - [x] 6.7 `swift package describe` — diff against Task 1.5 baseline. Expected delta: 9 new public types under `FeatureSubstrate` namespace (including `FeatureSubstrateError`) + `MLFeatureFrames` / `TensorLayout` at unchanged module path. Record the diff in Completion Notes.
  - [x] 6.8 Surface the flat list of undocumented public symbols (DD #3) in Completion Notes for Epic 8 hand-off.

## Dev Notes

### Architecture pointers (read before coding)

- **KDD-S2 verbatim spec:** `_bmad-output/planning-artifacts/architecture.md:175-235`. The Swift type sketch at lines 179-215 + the producer / trade-off / aubio-attachment / FR-21 parity / boundary-with-KDD-S1 / test-invariants subsections. Read fully — the substrate is one of 4 load-bearing Tier-1 roots (line 280-285).
- **Subfolder threshold rule:** `architecture.md:249` ("Codified threshold: subdir when ≥5 cohesive files; root otherwise") — 10 substrate files clear the threshold.
- **Mary's seam-mitigation rule:** `epics.md:23` (party-mode amendment) + Epic 6 body (`epics.md:269-275`). Internal-or-undocumented; Epic 8 promotes via dedicated story spec. Cite when reviewing your own diff.
- **`bpm-diagnostic-trace` project skill:** `.claude/skills/bpm-diagnostic-trace/SKILL.md` — invoke via Skill tool. The 5 audit recipes (A-E) are required pre-flight + post-flight per DD #11.

### Existing code to read (UPDATE files, per checklist rule)

The story modifies **2 existing source files** plus extracts content from one of them. Read each completely before editing:

- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (lines 438-776 of the current file are extracted to `FeatureSubstrate/`; remaining lines stay; the `mlFeatures: MLFeatureFrames?` field declaration at the existing line ~225-227 STAYS unchanged). Read the full file before editing — the extraction is large (~340 lines lifted) and SourceKit will show transient errors during the move.
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — read `computeMelOnsetEnvelopeWithSubBands` at line 558+ + the `OnsetEnvelopes` return type. `OnsetFeaturesBuilder.build` calls this method internally for `.uniform` weighting per Task 4.8. **No edits to `BPMAnalyzer.swift` in this story.** (Future story wires `BPMAnalyzer.estimateBPM` to call the builder.)
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` — read `featurize(_ features: MLFeatureFrames)` at line 526+ to understand the consumer pattern. **No edits in this story.** The `import BoomBoomBoomKit` line at line 20 resolves `MLFeatureFrames` from its new location automatically.
- `Tests/BoomBoomBoomKitTests/MLFeatureFramesTests.swift` — top-of-file docstring may need a one-line update if it cites the old `BPMDiagnosticTrace.swift` host location (Task 3.4).

### File list (what this story creates / updates)

**NEW source files (10):**
- `Sources/BoomBoomBoomKit/FeatureSubstrate/FeatureSubstrate.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/DecodedAudio.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/OnsetFeatures.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/OnsetFeaturesBuilder.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/WeightingProfile.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/SubBandWeights.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/SubBandCutoff.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/AudioCodec.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/PrimingInfo.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/FeatureSubstrateError.swift` (party-mode patch round; per DD #10)

**EXTRACTED files (2):**
- `Sources/BoomBoomBoomKit/FeatureSubstrate/TensorLayout.swift` (extracted from BPMDiagnosticTrace.swift)
- `Sources/BoomBoomBoomKit/FeatureSubstrate/MLFeatureFrames.swift` (extracted from BPMDiagnosticTrace.swift)

**NEW tests (1):**
- `Tests/BoomBoomBoomKitTests/FeatureSubstrateTests.swift`

**UPDATED files (2):**
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — lines 438-776 removed (extracted to `FeatureSubstrate/`); `mlFeatures: MLFeatureFrames?` field declaration unchanged
- `Tests/BoomBoomBoomKitTests/MLFeatureFramesTests.swift` — top-of-file docstring path reference update only (if applicable per Task 3.4)

**EXPLICITLY NOT TOUCHED:**
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` (read-only reference; `OnsetFeaturesBuilder` calls into it as-is)
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` (consumer; reads `MLFeatureFrames` via `import BoomBoomBoomKit`, unchanged)
- `Sources/BoomBoomBoomKitML/CoreMLTechnique.swift` (intentional non-conforming placeholder; unchanged)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (no service-layer changes; Story 6.1's `buildStage1SignalPool` call site untouched)
- `Sources/BoomBoomBoomKit/MLTechnique.swift` (protocol unchanged)
- `Package.swift` (no manifest changes; SwiftPM globs subfolder automatically)
- `.swiftlint.yml` (no `included:` changes; SwiftLint globs by default per project-context.md)
- All existing test files except `MLFeatureFramesTests.swift` docstring (Task 3.4)

### Testing standards

- Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`) — NOT XCTest. Per project-context.md.
- `@testable import BoomBoomBoomKit` for tests calling `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` (which is `static func` not `public`).
- `NumericTestHelpers.bitEqual(_:_:)` from Story 6.1's TestSupport target for all Float / Double comparisons that may carry NaN.
- Test fixtures via `AudioFixtures.url(for:extension:)` from `BoomBoomBoomKitTestSupport`.
- Each `@Test` is independent (Swift Testing reruns init per test).

### Pre-1.0 framing reminder

Per project-context.md "Pre-1.0 release posture: no backwards-compatibility promised" — the 9 new substrate types are public but undocumented (DD #3). Epic 8 promotion stories own DocC. The Hashable+NaN downgrade for `WeightingProfile` / `SubBandWeights` / `OnsetFeatures` / `OnsetFeatures.Parameters` (DD #4) is a pre-1.0 architecture override against KDD-S2's `Hashable` declaration — captured here in the spec AND scheduled for the **mid-Epic-6 architecture amendment commit** (see next subsection), NOT deferred to retro.

### Pending Architectural Amendment (mid-Epic-6, between 6.2 and 6.3)

Operator chose during the 2026-05-27 party-mode patch round to amend `architecture.md` in a standalone commit between Story 6.2 dev close-out and Story 6.3 spec-create, rather than continuing the Story 6.1 D1 "defer to retro" precedent. Six divergences accumulated by Story 6.2 close that the amendment commit must reconcile:

1. **`architecture.md:197` — `WeightingProfile: Sendable, Hashable`** → drop `Hashable` (transitively carries Float fields via `SubBandWeights`). Story 6.2 DD #4.
2. **`architecture.md:202` — `SubBandWeights: Sendable, Hashable`** → drop `Hashable` (Float fields directly). Story 6.2 DD #4.
3. **`architecture.md:223` — "replace `MLFeatureFrames` with `FeatureSubstrate.OnsetFeatures`"** → factually incorrect about source location (says ML target; actual location is `BPMDiagnosticTrace.swift:500`). Story 6.2 DD #1.
4. **`architecture.md:998` — file-layout MOVED-from-BoomBoomBoomKitML annotation** → factually incorrect on same point. Story 6.2 DD #1.
5. **`architecture.md:128-146` — `SignalParticipation` / `AbstainReason` / `DemotionReason` Hashable** → all 3 dropped. Story 6.1 D1.
6. **`architecture.md:983-998` — `FeatureSubstrate/` file layout** → spec ships 12 files (10 new source + 2 extracted), arch shows 10 — add `FeatureSubstrateError.swift`; clarify TensorLayout + MLFeatureFrames are EXTRACTED from `BPMDiagnosticTrace.swift`, not from `BoomBoomBoomKitML/`.

**Why standalone, not bundled into 6.2 dev close-out:** project-context.md "Commit messages — story commit pattern: `Story X-Y: <imperative-summary>`" — coupling architecture-doc edits to a story commit violates story-scoped commits. The amendment commit gets its own scope: `Epic 6 architecture amendment: reconcile KDD-S1+KDD-S2 with Story 6.1+6.2 PSI` (or similar). Operator owns the timing.

### Project Structure Notes

- New subfolder `Sources/BoomBoomBoomKit/FeatureSubstrate/` is the second new subfolder Epic 6 introduces (after `Sources/BoomBoomBoomKit/SignalPool/` in Story 6.1). Communicates "feature substrate is one cohesive subsystem" per architecture step-03 Decision 2 (line 247-249).
- SwiftPM globs source files — no `Package.swift` edit required.
- `.swiftlint.yml` `included:` paths require no change (SwiftLint globs by default).
- Demo project (`Demo/BoomBoomBoomBPM/`) does NOT consume `FeatureSubstrate` types in this story (substrate is BPM-only DSP plumbing). Demo build untouched.

### Previous Story Intelligence (Story 6.1 close-out 2026-05-27)

Story 6.1 commit `d9095b2` landed clean (16 files / +796 / -88). PSI items inherited by Story 6.2:

1. **Hashable+NaN contract violation is real.** 4 reviewers (Blind Hunter, Edge Case Hunter, Acceptance Auditor, Codex Blind Hunter MCP) converged on the finding: `Hashable`'s `x == x` invariant fails on `Double.nan` payloads. Project precedent (`EnsembleDecision.swift:44` plus the entire typed-evidence family) omits `Hashable` on types carrying Float/Double payloads. **Apply same posture in Story 6.2:** `WeightingProfile`, `SubBandWeights`, `OnsetFeatures` ship as `Sendable, Equatable` — NOT `Hashable` — even though architecture KDD-S2 declares them `Hashable`. Override captured in DD #4. Equatable preserved so `==` is synthesized for tests.

2. **`NumericTestHelpers.bitEqual(_:_:)` is the canonical NaN-safe float comparison.** Lives at `Sources/BoomBoomBoomKitTestSupport/NumericTestHelpers.swift` (caseless-enum namespace; Patch M15 form). Use it in `FeatureSubstrateTests.uniformWeightingByteIdentity` (Task 5.2) — do NOT hand-roll `lhs.bitPattern == rhs.bitPattern` inline.

3. **KDD-T0 SAME-PR rule does NOT fire here.** Story 6.1 added `signalParticipationTrace` + `SignalParticipationTraceEntry` in one commit per KDD-T0 SAME-PR. Story 6.2 does NOT add a new trace field — `MLFeatureFrames` only moves files. The 5-recipe audit must still run pre + post; baseline holds.

4. **Internal-or-undocumented seam mitigation has full precedent.** Story 6.1 deliberately shipped 7 public types without DocC (Patch M14 surfaces the list in Completion Notes for Epic 8 hand-off). Story 6.2 follows the same pattern for 8 new types + makes ONE explicit exception per DD #3 (`OnsetFeatures.featureSetVersion` DocC) for FR-21 train/runtime-parity-tripwire visibility.

5. **`@TaskLocal` extraction was test-isolated in Story 4-5 review pass v2.** `MLFeatureFrames._testingMaximumLogMelDataCount` is the canonical pattern (review fix N5 v2). When extracting MLFeatureFrames in Task 3.1-3.2, the `@TaskLocal` declaration + `_withTestingMaximumLogMelDataCount` wrapper must move atomically with the type — splitting them risks per-task override leakage that the v2 fix already plugged. Do NOT refactor or simplify during extraction.

6. **Operator-owned closeout discipline.** Per project-context.md Story Authoring Discipline: code-review on different LLM after dev close-out (or via Codex MCP arm if same LLM), final commit on 1Password GPG signer. Pending pre-merge: `/bmad-code-review` pass on staged diff.

### 5-layer review cadence (applies to Story 6.2)

Story 6.2 introduces new public API (9 new substrate types under `FeatureSubstrate` namespace) AND modifies an architecturally-load-bearing file (`BPMDiagnosticTrace.swift` loses ~340 lines via extraction). Per project-context.md Story Authoring Discipline:

1. **Failure Mode Analysis** — pre-PR single-pass against this spec
2. **Self-Consistency review** — 3 parallel Codex agents (Blind Hunter + Edge Case Hunter + Acceptance Auditor) on the post-FMA spec
3. **Code review** on the staged diff (project's `/bmad-code-review` skill)
4. **Codex MCP `codex:consult`** cross-validation (warranted given Tier-1 substrate-root status)
5. **GitHub Copilot inline review** at PR open, triaged into patches/defers/dismissals

Findings persisted to `deferred-work.md` per the canonical-SoT pattern (Epic 4 retro A2).

### References

- [Source: _bmad-output/planning-artifacts/epics.md:424-462] — Story 6.2 user-story + 6 ACs + pressure-release valve
- [Source: _bmad-output/planning-artifacts/architecture.md:175-235] — KDD-S2 verbatim spec (Decision / Producer / Trade-offs / aubio attachment / FR-21 parity / Boundary with KDD-S1 / Test invariants)
- [Source: _bmad-output/planning-artifacts/architecture.md:247-249] — Subfolder threshold (≥5 cohesive files)
- [Source: _bmad-output/planning-artifacts/architecture.md:282-285] — Tier-1 sequence S1 → S2 → A6 → A1
- [Source: _bmad-output/planning-artifacts/architecture.md:983-998] — `FeatureSubstrate/` subfolder file layout
- [Source: _bmad-output/project-context.md "Banned trace-field shapes"] — 4 prohibited shapes + 5 audit recipes (audit applies inertly to Story 6.2; no new trace field)
- [Source: _bmad-output/project-context.md "Public API Discipline (pre-1.0)"] — Internal→public promotion ceremony; story 6.2 ships 9 new public types under seam-mitigation pattern (DD #3)
- [Source: _bmad-output/implementation-artifacts/6-1-signalparticipation-contract-and-pool-stage-1-adapter.md:288-326] — Story 6.1 code-review findings (Hashable+NaN convergent finding; informs DD #4)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md:3-35] — Story 6.1 W47-W61 deferred items (all Stage 2+ / Story 6.5 lane; none reopen-triggered by Story 6.2)
- [Source: Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:438-776] — Source extraction range for `TensorLayout` + `MLFeatureFrames` + `@TaskLocal` test helper
- [Source: Sources/BoomBoomBoomKit/BPMAnalyzer.swift:558-700] — `computeMelOnsetEnvelopeWithSubBands` consumer pattern for `OnsetFeaturesBuilder.build(.uniform)`
- [Source: Sources/BoomBoomBoomKitML/BNNSTechnique.swift:60-77, 526] — `featurize(_:)` post-relocation `import` resolution (unchanged)

## Dev Agent Record

### Agent Model Used

claude-opus-4-7

### Debug Log References

- **Pre-flight (Task 1.2):** 5 `bpm-diagnostic-trace` audit recipes (A-E) returned zero matches against `Sources/` + `Tests/`. Clean baseline.
- **Pre-flight (Task 1.3):** `rg "MLFeatureFrames" Sources/ Tests/ | wc -l` = `63`. Matches DD #9 pressure-release analysis baseline exactly. Recommend-do-not-split decision held.
- **Pre-flight (Task 1.4):** `swift build` clean (0.13s); `swift test --parallel --filter BoomBoomBoomKitTests` = 437 tests / 95 suites passed in 1.721s. Matches Story 6.1 close-out baseline.
- **Pre-flight (Task 1.5):** `swift package describe --type json` baseline persisted to `/tmp/spm-baseline.json` — core target sources_count = `27`, tests = `30`.
- **Task 3.3:** `BPMDiagnosticTrace.swift` top docstring does NOT reference "MLFeatureFrames inline" — verified. No-op as predicted by DD #9.
- **Task 3.4:** `Tests/BoomBoomBoomKitTests/MLFeatureFramesTests.swift` top docstring cites `BoomBoomBoomKitTests` target only, not a specific host-file path — verified. No-op (matches DD #9 "0 edit-required hits" claim).
- **Task 3.6:** Post-extraction `swift package describe` confirms zero public API surface delta beyond the +3 source files (`FeatureSubstrate.swift`, `TensorLayout.swift`, `MLFeatureFrames.swift`); public symbols `BoomBoomBoomKit.MLFeatureFrames` and `BoomBoomBoomKit.TensorLayout` resolve at unchanged module paths.
- **Mid-flight lint (Task 6.1):** SwiftLint `nesting` rule fired on `OnsetFeatures.Parameters` (third-level: `FeatureSubstrate` → `OnsetFeatures` → `Parameters`). Applied targeted `// swiftlint:disable:next nesting` per project precedent (`BPMAnalyzer.swift:1644` + `CorpusTracks.swift:63`); preserves DD #5 nested-struct shape. Lint back to canonical 1 violation = `LUFSAnalyzer.swift:94` TODO baseline.

### Completion Notes List

**Gating gauntlet results:**

- `make fmt && make lint` — 1 violation, 0 serious (canonical `LUFSAnalyzer.swift:94` TODO baseline UNCHANGED).
- `make build` — clean (0.92s).
- `make test` — 444 tests / 96 suites passed in 1.791s (delta from Story 6.1 baseline 437/95: +7 / +1; new `FeatureSubstrateTests` suite has 7 `@Test` methods matching the explicit Task 5.2-5.8 enumeration — the sprint-status `+6` projection was off-by-one).
- `make benchmark` (OA300, default intensity 7) — Acc1=58/82 (70.7%), Acc2=74/82 (90.2%). **UNCHANGED** from Story 6.1 close-out baseline (AC #6 zero-delta contract holds).
- `make benchmark-giantsteps` — Acc1=537/661 (81.2%), Acc2=546/661 (82.6%). **UNCHANGED** from Story 6.1 close-out baseline (AC #6 zero-delta contract holds).
- Post-flight `bpm-diagnostic-trace` audit (Task 6.6): all 5 recipes (A-E) returned zero trace-relevant matches against `Sources/` + `Tests/` — no new trace field landed, DD #12 inert-audit prediction confirmed. (Codex review 2026-05-28 noted that broad Recipe-B `String(format: "%.1f", r.bpm)` matches exist in `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift:223` + `Tests/BoomBoomBoomKitTests/AblationQuickTests.swift:105`, but these are benchmark-report formatting, not banned-shape trace writes — wording tightened from "zero matches" to "zero trace-relevant matches" to reflect this.)
- Post-flight `swift package describe` diff (Task 6.7): core target sources_count `27 → 39` (+12: 10 new + 2 extracted under `FeatureSubstrate/`); tests `30 → 31` (+1: `FeatureSubstrateTests.swift`); other targets unchanged. Module paths for `BoomBoomBoomKit.MLFeatureFrames` and `BoomBoomBoomKit.TensorLayout` unchanged (extraction is file-level only).

**File-count reconciliation:** 12 files under `Sources/BoomBoomBoomKit/FeatureSubstrate/` at completion = 10 NEW (`FeatureSubstrate.swift`, `AudioCodec.swift`, `PrimingInfo.swift`, `SubBandCutoff.swift`, `SubBandWeights.swift`, `WeightingProfile.swift`, `DecodedAudio.swift`, `OnsetFeatures.swift`, `OnsetFeaturesBuilder.swift`, `FeatureSubstrateError.swift`) + 2 EXTRACTED (`TensorLayout.swift`, `MLFeatureFrames.swift`). Matches DD #2 file map exactly. `BPMDiagnosticTrace.swift` shrunk from 776 → 434 lines (delta −342, close to spec's "~340 lines lifted" estimate).

**Undocumented public symbols requiring Epic 8 promotion** (per DD #3 / AC #7 hand-off list):

- `FeatureSubstrate` (caseless-enum namespace)
- `FeatureSubstrate.AudioCodec`
- `FeatureSubstrate.PrimingInfo`
- `FeatureSubstrate.SubBandCutoff`
- `FeatureSubstrate.SubBandWeights`
- `FeatureSubstrate.WeightingProfile`
- `FeatureSubstrate.DecodedAudio`
- `FeatureSubstrate.OnsetFeatures` + nested `OnsetFeatures.Parameters`
- `FeatureSubstrate.OnsetFeaturesBuilder` (caseless-enum namespace)
- `FeatureSubstrate.FeatureSubstrateError`

Single doc-comment exception: `OnsetFeatures.featureSetVersion` carries a `///` listing every bump trigger per DD #6. `MLFeatureFrames` + `TensorLayout` retain their pre-existing extensive DocC verbatim (relocated, not promoted).

**Architectural facade caveat:** `OnsetFeaturesBuilder.swift` carries one `// MARK: - Tier-1 facade pattern` internal comment per DD #8 documenting the substrate-depends-on-analyzer inversion until Tier-3 wiring (planned Story 6.5+ / Epic 8). Single internal-comment exception per the no-DocC discipline.

**No HALT events fired.** Auto-mode single-shot implementation; pressure-release valve did not need to fire (0 edit-required hits as predicted by DD #9; lint nesting violation handled via targeted disable comment per project precedent without scope expansion).

**Pending operator action** (per project-context.md operator-owned closeout ceremony):

- `/bmad-code-review` pass on staged diff (project convention: fresh-context different LLM, or via Codex MCP arm if same LLM).
- Mid-Epic-6 architecture.md amendment commit (per Dev Notes "Pending Architectural Amendment" subsection) — standalone commit between Story 6.2 dev close-out and Story 6.3 spec-create, reconciling the 6 named architecture.md divergences.
- Final commit on 1Password GPG signer. Suggested commit message: `Story 6-2: FeatureSubstrate namespace + OnsetFeaturesBuilder + MLFeatureFrames relocation`.

### File List

**NEW source files (10) under `Sources/BoomBoomBoomKit/FeatureSubstrate/`:**

- `FeatureSubstrate.swift`
- `AudioCodec.swift`
- `PrimingInfo.swift`
- `SubBandCutoff.swift`
- `SubBandWeights.swift`
- `WeightingProfile.swift`
- `DecodedAudio.swift`
- `OnsetFeatures.swift`
- `OnsetFeaturesBuilder.swift`
- `FeatureSubstrateError.swift`

**EXTRACTED source files (2) under `Sources/BoomBoomBoomKit/FeatureSubstrate/`:**

- `TensorLayout.swift` (content lifted from `BPMDiagnosticTrace.swift:438-474`)
- `MLFeatureFrames.swift` (content lifted from `BPMDiagnosticTrace.swift:476-776` including `@TaskLocal _testingMaximumLogMelDataCount` + `_withTestingMaximumLogMelDataCount` wrapper)

**NEW tests (1):**

- `Tests/BoomBoomBoomKitTests/FeatureSubstrateTests.swift`

**UPDATED files (1):**

- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — lines 436-776 removed (TensorLayout + MLFeatureFrames + `@TaskLocal` test helper extracted to `FeatureSubstrate/`); `mlFeatures: MLFeatureFrames?` field declaration unchanged. File 776 → 434 lines.

**Tasks 3.3 + 3.4 confirmed as no-ops** — `BPMDiagnosticTrace.swift` top docstring did not reference inline location; `MLFeatureFramesTests.swift` top docstring did not cite a specific file path. Matches DD #9 "0 edit-required hits" claim.

### Review Findings

`/bmad-code-review` 3-layer pass (Blind Hunter + Edge Case Hunter + Acceptance Auditor, 2026-05-28). Acceptance Auditor confirmed AC #1-#8 + DD #1-#12 SATISFIED (zero violations against the spec contract). Hunter layers surfaced API-hardening and diagnostic-accuracy concerns; one DD-internal contradiction (DD #5 vs DD #10 on `DecodedAudio` error type) needs operator decision. 1 decision-needed, 4 patches kept active, 12 items deferred to `deferred-work.md`, 9 dismissed as by-design or speculative.

- [x] [Review][Decision-resolved] DD #5 ↔ DD #10 contradiction — `Codex consult` recommended **Option D**: drop the phantom `{44100, 48000, 96000}` constraint (not enforced by `MelFilterbank` or `BPMAnalyzer` — the constraint lives only in `LUFSAnalyzer`'s precomputed K-weighting coefficients, which is off this code path); make `DecodedAudio.init` non-throwing with `precondition(sampleRate.isFinite && sampleRate > 0)`; push the recoverable user-input validation up to `PCMBufferReader.readMonoSamples` where external audio metadata first enters the system. Removes the DD #10 ↔ DD #5 error-type question entirely. Codex threadId `019e6d0f-f955-7031-bdf8-1a1ecc57e590`. Applied as Patch 5 + Patch 6 below. Mid-Epic-6 architecture amendment removes the phantom claim from `architecture.md:199`.

- [x] [Review][Patch] Reword "size cap fired" diagnostic for accuracy [`OnsetFeaturesBuilder.swift:47-54`] — `envelopes.mlFeatures == nil` is set whenever ANY `MLFeatureFrames.init` invariant throws inside `BPMAnalyzer.computeLogMelFramesAndRetention`'s `try?` (cap, overflow, count-mismatch, finiteness). Message now enumerates all causes.

- [x] [Review][Patch] Rename `too_many` → `tooMany` [`FeatureSubstrateTests.swift:158,161`].

- [x] [Review][Patch] Promote length-equality `#expect` to `try #require` [`FeatureSubstrateTests.swift:45`].

- [x] [Review][Patch] Reorder `OnsetFeatures.description` fields to match `MLFeatureFrames.description` shape [`OnsetFeatures.swift:154-162`] — now leads with `melBands` then `frames`.

- [x] [Review][Patch] Drop phantom `{44100, 48000, 96000}` constraint; `DecodedAudio.init` becomes non-throwing with `precondition(sampleRate.isFinite && sampleRate > 0)` [`DecodedAudio.swift:18-31`]. `decodedAudioInitInvariants` test deleted (-1 test: 444→443).

- [x] [Review][Patch] Add finite+positive `sampleRate` validation at file-read boundary [`PCMBufferReader.swift:64-79`] — `format.sampleRate.isFinite && >= 8000` (source-file path; tightened from initial `> 0` per Codex follow-up) and `targetSampleRate.isFinite && > 0` (downsample-knob path; permissive per Codex follow-up — caller opts into low rates explicitly, BPM-pipeline trap fires later at DecodedAudio.init if needed). Mirrors the existing `fileDuration` precedent at `PCMBufferReader.swift:160-163`.

- [x] [Review][Patch-Codex-follow-up] Tighten `DecodedAudio` precondition + PCMBufferReader source-file guard to `sampleRate >= 8000` Hz [`DecodedAudio.swift:23-32`, `PCMBufferReader.swift:64-69`] — Codex `/codex:diff-review` (threadId `019e6d19-1f7b-7c80-a541-06b6a15503f5`) High finding: removing the phantom rate set without replacing the actual derived-hop invariant left a `hopSize == 0` hang for `0 < sampleRate < 100` since `OnsetFeaturesBuilder.swift:31` computes `Int(decoded.sampleRate / 100)`. 8 kHz floor matches audio-engineering practical minimum (G.711 telephone quality); FFT 2048 at 8 kHz is ~256 ms per frame which is the lowest workable for onset detection.

- [x] [Review][Patch-Codex-follow-up] Fix `MLFeatureFrames.sampleRate` DocC drift [`MLFeatureFrames.swift:79-86`] — relocated file's DocC still referenced phantom `{44100, 48000, 96000}` constraint. Rewrote to clarify the BPM/onset pipeline accepts any rate at or above 8 kHz; three-rate set is LUFS-only.

- [x] [Review][Patch-Codex-follow-up] Tighten Patch-1 diagnostic wording from claiming-exhaustive to "common causes include..." [`OnsetFeaturesBuilder.swift:47-57`] — Codex Low: original Patch-1 wording overpromised that the listed 4 causes were exhaustive. `MLFeatureFrames.init` actually has 9 rejection paths; reworded to "common causes include {cap, overflow, count, finite}; other invariants are unreachable through current builder call shape but can fire on direct `MLFeatureFrames.init`."

- [x] [Review][Patch-Codex-follow-up] Reword "zero matches" claim to "zero trace-relevant matches" [`6-2-...md` Review Findings → Completion Notes Task 6.6] — Codex Low: literal `rg` for Recipe B finds two benign formatting matches in benchmark / ablation tests; neither is a banned-shape trace write. Wording tightened.

- [x] [Review][Defer] Codex follow-up Medium — spec DD #5 text still says throwing init + rate-set validation, doesn't match what landed. Operator directed: handle in mid-Epic-6 architecture-amendment commit (per their "more commits for follow-up stuff" framing). → mid-Epic-6 amendment

- [x] [Review][Defer] `DecodedAudio.init` doesn't validate `samples` finiteness — NaN/Inf in `samples` propagates through DSP, fails inside MLFeatureFrames finiteness guard, surfaces as `featurizationFailed` (now made accurate by the patch above). Not spec'd; future hardening. → deferred-work
- [x] [Review][Defer] `PrimingInfo` accepts negative / `Int.max` trim frames — no validation today; future consumers slicing audio would crash. Symmetric with samples-finiteness gap. → deferred-work
- [x] [Review][Defer] `SubBandWeights` accepts NaN / Inf / negative weights — `.subBandEmphasis` unimplemented in this story; tightening at calibration story. → deferred-work
- [x] [Review][Defer] `OnsetFeatures.init` and `MLFeatureFrames.init` duplicate the invariant-validation matrix verbatim — two sources of truth for the same guard list; will drift. Future shared-validator extraction. → deferred-work
- [x] [Review][Defer] `OnsetFeatures.init` doesn't validate `hopSize <= fftSize` — degenerate overlap not rejected; sensible invariant absent from spec. → deferred-work
- [x] [Review][Defer] `builderFailurePathsThrow` test (b) asserts "something threw `FeatureSubstrateError`" not "cap fired specifically" — would pass on any upstream failure mode reaching the `mlFeatures == nil` path. Tighten by propagating discriminator. → deferred-work
- [x] [Review][Defer] `featureSetVersion` accepts whitespace-only / special-character strings — `!isEmpty` only; benchmark-log parsers vulnerable to malformed tags. Future regex tightening. → deferred-work
- [x] [Review][Defer] `OnsetFeatures.Parameters` is `Codable` but accepts NaN / Inf — `JSONEncoder.encode` throws at the serialization boundary, not at construction. Validate finiteness in `Parameters.init` to fail at boundary. → deferred-work
- [x] [Review][Defer] `AudioCodec` / `PrimingInfo` are public dead API surface today — no consumer reads codec for behavior. Forward-facing per substrate FR-21 intent; ship-or-document. → deferred-work
- [x] [Review][Defer] `OnsetFeatures.init` doesn't extract + validate `SubBandWeights` payload — once `.subBandEmphasis` is wired, init silently stores bad weights. → deferred-work
- [x] [Review][Defer] AC #3 spec wording stale pre-DD #10 — AC #3 prose still says "throws `MLTechniqueError.invalidFeatureShape`" but DD #10 supersedes (implementation correctly throws `FeatureSubstrateError`). Tighten AC text at mid-Epic-6 architecture-amendment commit. → deferred-work
- [x] [Review][Defer] AC #1 spec wording on sampleRate location — AC #1 lists `sampleRate ∈ {44100, 48000, 96000}` among `OnsetFeatures.init` invariants but DD #5 partitions that check to `DecodedAudio.init`; implementation correctly puts it on `DecodedAudio`. Tighten AC text. → deferred-work

### Change Log

- 2026-05-28 — Auto-mode dev-agent implementation via `/bmad-dev-story 6-2-...`. All 6 Tasks + 26 subtasks landed in single execution. Status flipped `ready-for-dev → in-progress → review`. Zero accuracy delta on OA300 (58/82 + 74/82) and GiantSteps (537/661 + 546/661) — AC #6 contract held. Test count 437/95 → 444/96 (+7/+1). 5-recipe `bpm-diagnostic-trace` audit zero matches pre- and post-flight. No HALT events; one mid-flight SwiftLint nesting-rule patch (targeted disable comment on `OnsetFeatures.Parameters` per project precedent). Pending operator: `/bmad-code-review` + standalone mid-Epic-6 architecture.md amendment commit + final commit on 1Password GPG signer.
- 2026-05-28 — `/bmad-code-review` 3-layer pass (Blind Hunter + Edge Case Hunter + Acceptance Auditor). Auditor confirmed all 8 ACs + 12 DDs SATISFIED. Hunter layers surfaced 1 decision-needed (DD #5 ↔ DD #10 contradiction on `DecodedAudio` error type), 4 small patches (diagnostic-message accuracy, snake_case rename, `#expect → require` short-circuit, `description` field-order alignment), 12 deferred-to-deferred-work items, 9 dismissed by-design / speculative. Findings written above.
- 2026-05-28 — Codex consult on the decision-needed (threadId `019e6d0f-f955-7031-bdf8-1a1ecc57e590`) surfaced the phantom-constraint finding: `{44100, 48000, 96000}` is not enforced by `MelFilterbank.buildFilterbank` or `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` — it lives only in `LUFSAnalyzer`'s precomputed K-weighting coefficients (off this code path). Codex recommended Option D: drop the phantom constraint, non-throwing `DecodedAudio.init` with finite+positive `precondition`, push recoverable validation up to `PCMBufferReader.readMonoSamples`. Final patch set landed: 6 patches (4 original + 2 from Codex). Tests 444→443 (-1 from `decodedAudioInitInvariants` deletion); lint baseline (1 canonical violation) unchanged; `swift build` clean. Mid-Epic-6 architecture.md amendment now also removes the phantom `DecodedAudio.sampleRate ∈ {44100, 48000, 96000}` claim from `architecture.md:199` and clarifies that the three-rate set lives in LUFS alone.
- 2026-05-28 — `/codex:diff-review` follow-up (threadId `019e6d19-1f7b-7c80-a541-06b6a15503f5`) surfaced 1 High + 1 Medium + 3 Low. High finding: removing the phantom rate set without replacing it with the actual derived-hop invariant left a `hopSize == 0` hang risk for `0 < sampleRate < 100`, since `OnsetFeaturesBuilder.swift:31` derives `Int(decoded.sampleRate / 100)`. Operator chose to tighten both `DecodedAudio` precondition AND PCMBufferReader source-file guard to `sampleRate >= 8000` (audio-engineering practical minimum; G.711 telephone quality). PCMBufferReader's `targetSampleRate` guard stays permissive (`> 0`) because callers explicitly opt into low rates — e.g., the existing `downsample 44.1kHz to 4410 Hz` test verifies the downsampler infrastructure at 4410 Hz, well below the BPM-pipeline threshold; the BPM-pipeline trap fires later at `DecodedAudio.init` if a downsampled buffer is fed forward. Three Low fixes also landed: (a) MLFeatureFrames.swift:79 DocC drift on `sampleRate` field — removed phantom `{44100, 48000, 96000}` reference; (b) OnsetFeaturesBuilder Patch-1 diagnostic wording tightened from claiming-exhaustive to "common causes include..." with explicit note that other `MLFeatureFrames.init` invariants are unreachable through current builder shape; (c) "zero matches against Sources + Tests" wording tightened to "zero trace-relevant matches" — Codex noted two benign `String(format: "%.1f", r.bpm)` matches in benchmark-report formatting (`OA300BenchmarkTests.swift:223` + `AblationQuickTests.swift:105`), not banned-shape trace writes. Medium spec-line-89 finding deferred to the mid-Epic-6 architecture-amendment commit per operator direction ("more commits for follow-up stuff — no need to amend"). Post-fix: `make build` clean (0.45s), `make test` 443/96 in 1.983s (unchanged), `make lint` 1 violation 0 serious (canonical baseline UNCHANGED). Codex confirmed: Patches 2-4 correct, Patch 6 covers all readMonoSamples entry paths, deleting `decodedAudioInitInvariants` is correct under Swift Testing (precondition traps not `#expect`-catchable).
