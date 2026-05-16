# Story 4.6: ML Accuracy Investigation and Bundle Decision

Story ID: 4.6
Story Key: 4-6-ml-accuracy-investigation-and-bundle-decision
Epic: 4 — ML-Augmented Detection
Status: done

## Story

As a library author,
given Story 4-5's empirical finding that `BNNSTechnique.evaluate(trace:)` abstains on 100% of OA300 corpus tracks (`ml_acc1 = 0/82`, `named_dnb_resolved = 0/4` per `_bmad-output/implementation-artifacts/4-5-bnns-impact-report.json`) despite producing a confident, in-range prediction on synthetic uniform input (`Array(repeating: 0.5, count: 65536)` → argmax bin 140 → 170 BPM per Story 4-5 Task 1.5d probe at `_bmad-output/implementation-artifacts/4-5-allocator-probe.log`),
I want to (a) instrument `BNNSTechnique` so the impact-report harness can attribute each evaluation to one of six named failure stages (or to the win path), (b) expand the named DnB target set with ≥4 DSP-correct DnB control tracks so the impact metric can detect "ML quietly broke 30 tracks DSP got right" alongside "ML rescued the half-tempo failures", (c) narrow the hypothesis space (threshold-too-aggressive vs featurize-bug vs model-too-weak) by running threshold-disabled, Swift-vs-Python featurization, and confidence-distribution sweeps, (d) apply the indicated remediation (threshold change, featurize fix, OR pull bundle) and (e) re-run the impact report against the expanded target set and frozen ground truth,
So that Epic 4's ML-augmentation promise either ships with measurable accuracy gains (Branch A — bundle retained; ≥2/4 named + ≥4/4 controls preserved; default opt-in retained per Story 4-5 BYOW pivot) OR honestly retreats to "BNNS infrastructure delivered; bundled `giantsteps_v1.mlmodelc` removed from main-shipping path; `BNNSTechnique()` no-arg throws `.modelResourceMissing`; consumers BYOW" (Branch C — bundle pulled per Codex C2 framing). CoreML conformance is OUT OF SCOPE for this story regardless of branch; if Branch A fires, a separate follow-on story (e.g. `4-8-coreml-mltechnique-conformance`) is authored against the post-4-6 baseline.

## Key Design Decisions

The DDs below were authored at story-creation time (2026-05-14) against HEAD `1c8e274` (Story 4-5 review-pass v3 close-out). They capture the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #2, #5, #7, #8 are the most consequential** — they lock the diagnostic-surface shape, the threshold-sweep methodology, the bundle-pull mechanics, and the AC-binding HALT discipline that distinguishes "fix found and applied" from "investigation closed without a fix".

1. **Scope is re-cast from "CoreML conformance" to "BNNS accuracy investigation + bundle decision".** Per `epics.md:1118-1124`, Story 4-5's 0/4 DnB result triggers Epic 4 planning's Branch C, which formally says "Story 4.6 is moved BACK TO `backlog` in `sprint-status.yaml` with `gated_on: research-spike-X.Y` annotation". The Story 4-5 close-out (sprint-status `last_updated` 2026-05-14 — see preamble: "Investigation deferred to Story 4-6 with hard AC") chose to use the existing 4-6 slot AS the research-spike vehicle rather than spawning a separate 4-5b/4-6b spike. This is a pre-1.0 sequencing choice authorized by the Project Lead; CoreML conformance work moves to a future story IFF the investigation succeeds and the bundle stays. The sprint-status key is renamed from `4-6-coreml-mltechnique-conformance` to `4-6-ml-accuracy-investigation-and-bundle-decision` at story-creation time to reflect actual scope.

2. **Always-on `MLDiagnosticSnapshot` typed-evidence struct + derived 5-mode taxonomy as reporting layer (REVISED 2026-05-15 per party-mode + Codex review — see Review Findings v1).** The original DD #2 proposed an `MLAbstainReason` 5-mode enum populated only on the abstain path with the decoded numeric evidence (BPM, softmax max/second-max, gate-fired) appearing ONLY in `confidenceGateRejected`. Codex flagged this as evidence-thin: at thresholds 0.0/0.0 (DD #5 first investigation step), the most useful evidence disappears precisely when investigation needs it most. Winston + Mary + Amelia all converged on Codex's better-alternative: ship the always-on numeric snapshot, derive the discriminated taxonomy as a reporting view.

   **Snapshot shape — new typed-evidence struct in a NEW file `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift`** (Amelia: separate file to keep AC #12 diff-scope honest and `MLTechnique.swift`'s blame history clean):
   ```swift
   public struct MLDiagnosticSnapshot: Sendable, Hashable, CustomStringConvertible, Equatable {
     /// Decoded argmax-derived BPM. `nil` only when the inference path failed
     /// BEFORE producing a logit vector (graph compile/execute/workspace error).
     /// Out-of-range argmax (BPM ∉ 60.0...200.0) DOES populate this field with
     /// the raw out-of-range value — the snapshot reports what the model said,
     /// not what the library would have accepted.
     public let decodedBPM: Double?
     /// Softmax-max probability after host-side softmax. `nil` iff `decodedBPM`
     /// is nil (same root: no logit vector). Range [0.0, 1.0] when present.
     public let softmaxMax: Double?
     /// Softmax-second-max probability after host-side softmax. `nil` iff
     /// `decodedBPM` is nil. Range [0.0, 1.0] when present.
     public let softmaxSecondMax: Double?
     /// Cheap drift-detector: stable hash of the input feature payload Swift
     /// produced for this call. Amelia's "if Swift and Python checksums diverge
     /// on the same WAV, you've found the featurize bug" — replaces the
     /// expensive Swift-vs-Python `.npz` round-trip for the common case where
     /// both pipelines run against the same fixture.
     public let inputFeatureChecksum: UInt64
     /// Categorical view derived from the inference path. `nil` on the win
     /// path (`evaluate(trace:)` returned non-nil); on abstain, identifies
     /// which stage's early-return fired. Use this for histogram reporting
     /// (Story 4-6 impact-report). The numeric fields above are the load-
     /// bearing evidence; `failureStage` is a categorical summary on top.
     public let failureStage: FailureStage?
     public enum FailureStage: String, Sendable, Hashable, CaseIterable {
       case featuresAbsent
       case featureVersionMismatch
       case featurizeRejected
       case graphFailed              // Codex: split out of `inferenceFailed`
       case decodeRejected           // Codex: split out — out-of-range BPM or non-finite logits
       case confidenceGateRejected   // softmax/margin gate fired
       /// Sub-discriminator for `confidenceGateRejected` only. Populated on
       /// the trace via a separate sibling field if needed by the reporting
       /// layer; not in the snapshot itself.
     }
     public let gateFired: Gate?       // populated only when failureStage == .confidenceGateRejected
     public enum Gate: String, Sendable, Hashable, CaseIterable {
       case gate1Softmax
       case gate2Margin
     }
     public var description: String { ... }   // bounded length < 200 chars; includes failureStage + decodedBPM
   }
   ```

   **Population rule (revised, distinct from original DD #2).** The snapshot is populated on **every** evaluation when ML was active (`ensemblePolicy != .dspOnly` AND `mlTechnique != nil` AND trace was built) — both on the win path AND on every abstain path. Specifically:
   - **Win path** (`evaluate` returned non-nil): `decodedBPM`, `softmaxMax`, `softmaxSecondMax`, `inputFeatureChecksum` all populated; `failureStage = nil`; `gateFired = nil`. The existing `ensembleDecision` continues to carry the win signal — the snapshot is parallel evidence, not duplicative.
   - **Abstain path** (`evaluate` returned nil): `decodedBPM`/`softmaxMax`/`softmaxSecondMax` populated when reachable (post-decode abstains: `confidenceGateRejected` and `decodeRejected`-with-out-of-range-BPM); nil for pre-decode abstains (`featurizeRejected` / `graphFailed`). `inputFeatureChecksum` populated when `featurize` ran. `failureStage` populated whenever the snapshot itself is constructed. **For `featuresAbsent` and `featureVersionMismatch`, no snapshot is constructed at all** — the abstain fires before featurize, so there is no feature payload to checksum. The trace's `mlDiagnosticSnapshot` field stays nil on those two paths; the impact-report harness derives the histogram bucket for those tracks from `MLEvaluation == nil && mlDiagnosticSnapshot == nil` at JSON-emit time.
   - **Trace field**: `public var mlDiagnosticSnapshot: MLDiagnosticSnapshot? = nil` on `BPMDiagnosticTrace`. Outer Optional captures the gating layer (`enableTrace` false / ML not active / trace not built → field is nil); inner nil/non-nil fields capture the path-dependent evidence.

   **The 5-mode `MLAbstainReason` enum is DROPPED from the public API.** The histogram reporting in the impact-report harness (AC #7) is derived from `failureStage` at JSON-emit time — no separate `MLAbstainReason` public type ships. This removes one public type, eliminates the discriminated init preconditions (which were a smell flagged by axiom-swift), and lets the reporting layer evolve without changing the library API. The reporting taxonomy lives in `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift` as a private struct.

   **Why a new trace field, not an extension of `MLEvaluation`.** Per Story 4-5 DD #18, the `MLTechnique` protocol surface is frozen at `func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?`. The snapshot is OUT-OF-BAND from the protocol return — it goes to the trace via the new capability-protocol path (DD #3 revised). The frozen protocol stays untouched for consumer-supplied `MLTechnique` implementations.

   **Featurize-drift detection via `inputFeatureChecksum`.** Amelia's framing: per-evaluation `UInt64` checksum of the input feature payload Swift fed into BNNS. The Python reference pipeline at `_bmad-output/ml-training/` can emit the same checksum for the same fixture WAV; if they diverge, that IS the featurize bug, no `.npz` diff needed. Implementation: FNV-1a or xxHash over the `Float` byte representation of the resampled `[Float]` of length 65536. Cost: ~50µs per evaluate, dwarfed by the ~250ms BNNS inference. Hash is stable across runs because the feature payload is deterministic given the same audio.

3. **Diagnostic capability protocol `MLDiagnosticTechnique: MLTechnique` declared in core (REVISED 2026-05-15 per Codex finding #1 + Winston + Amelia + Siri — see Review Findings v1).** The original DD #3 proposed runtime type-narrowing via `if let bnns = ml as? BNNSTechnique` inside `AudioAnalysisService.evaluateMLIfActive` (which lives in the core target `Sources/BoomBoomBoomKit/`). Codex flagged this as architecturally impossible: the package graph is one-way (`BoomBoomBoomKitML` depends on `BoomBoomBoomKit`, NOT vice versa), so `AudioAnalysisService.swift` in core cannot legally name `BNNSTechnique`. Compile error, not smell. The rejection of "diagnostic-capability protocol" in the original DD #3 was reasoned against the wrong constraint set; the package graph makes the rejection untenable.

   **Revised shape — capability protocol in core, conformed in sibling target:**

   **New file `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift`** (Amelia + Winston converge: separate file from `MLTechnique.swift` so the protocol is independently auditable and AC #12 diff-scope stays honest; `MLTechnique.swift` is the frozen Story-4-5 contract whose git blame should not churn for diagnostic additions):
   ```swift
   import Foundation

   /// Optional capability extension that an `MLTechnique` conformer can adopt
   /// to expose per-evaluation numeric diagnostics. Story 4-6 ships
   /// `BNNSTechnique`'s conformance; consumer-supplied `MLTechnique` types may
   /// opt in by implementing this method, or skip it without losing
   /// correctness (the library falls back to the protocol-frozen
   /// `evaluate(trace:)` path).
   ///
   /// ## Why a capability protocol, not a sibling method on a concrete type
   ///
   /// `AudioAnalysisService` lives in the core `BoomBoomBoomKit` target;
   /// `BNNSTechnique` lives in the sibling `BoomBoomBoomKitML` target which
   /// depends on core. The dependency arrow is one-way, so the service cannot
   /// runtime-narrow via `as? BNNSTechnique`. Capability protocols declared
   /// in core (which the sibling target can adopt) are the canonical
   /// resolution — and they double as the consumer-extension point for any
   /// future ML backend that wants the same diagnostic surface.
   ///
   /// ## Frozen invariants
   ///
   /// - Inherits `MLTechnique` (and transitively `Sendable`)
   /// - Single method: `evaluateWithDiagnostic(trace:)` returns a tuple of
   ///   `(MLEvaluation?, MLDiagnosticSnapshot?)`. Snapshot is populated on
   ///   every call when the inference reached at least the featurize step;
   ///   nil only on `featuresAbsent` / `featureVersionMismatch` abstain
   ///   (paths that never produce a feature payload).
   /// - The two-element tuple invariant: `evaluation` and `snapshot` track
   ///   distinct concerns. The win path has BOTH non-nil; the abstain path
   ///   has `evaluation == nil` and `snapshot != nil` (when the abstain
   ///   reached at least featurize) or `snapshot == nil` (when the abstain
   ///   fired before featurize). The `failureStage` field on the snapshot
   ///   disambiguates the abstain mode.
   public protocol MLDiagnosticTechnique: MLTechnique {
       func evaluateWithDiagnostic(
           trace: BPMDiagnosticTrace
       ) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?)
   }
   ```

   **`BNNSTechnique`'s conformance** lives in `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` as a trailing extension (Amelia's pattern: extract the existing `evaluate(trace:)` body into a private `evaluateInternal` returning the tuple; the protocol-public `evaluate(trace:)` becomes a 2-line forward that discards `snapshot`):
   ```swift
   extension BNNSTechnique: MLDiagnosticTechnique {
       public func evaluateWithDiagnostic(
           trace: BPMDiagnosticTrace
       ) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?) {
           evaluateInternal(trace: trace)
       }
   }
   ```

   **Service-side dispatch in `AudioAnalysisService.evaluateMLIfActive`:**
   ```swift
   if let diag = ml as? MLDiagnosticTechnique {
       let (evaluation, snapshot) = diag.evaluateWithDiagnostic(trace: trace)
       // Evaluate into locals — mutation happens AFTER post-evaluate cancellation check
       if options.isCancelled() { throw CancellationError() }
       unwrappedTrace.mlDiagnosticSnapshot = snapshot
       return evaluation
   } else {
       let evaluation = ml.evaluate(trace: trace)
       if options.isCancelled() { throw CancellationError() }
       return evaluation
   }
   ```

   **Consumer-wrapper-loses-diagnostics is `wontfix` pre-1.0.** Codex finding #5 flagged that a consumer wrapping `BNNSTechnique` in a forwarding `MLTechnique` type would lose diagnostics. Amelia + Winston converge: forwarding wrappers are a 1.0 problem. Documented in the protocol doc-comment: "Diagnostic capability requires direct conformance — forwarding wrappers must re-conform if they want the diagnostic path." Trade-off explicitly accepted.

   **Project-wide elevation (Winston).** Story 4-5 elevated the C-resource RAII pattern (`final class Storage` with `deinit` exercised by a test) to a project-context.md rule. Story 4-6 elevates a complementary rule: **"Cross-target type narrowing always goes through a protocol declared in the upstream target, never through `as?` to a downstream concrete type."** Update at story close-out. The lesson generalizes beyond ML: any time a core type needs runtime-narrowing of a sibling-target value, the narrowing surface must be a core-declared protocol.

4. **Expanded DnB target set has TWO partitions: named-failures (the 4 existing tracks) + DSP-correct controls (≥4 new tracks).** Per Codex C5 framing from `deferred-work.md:461-467`. The current `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` lists 4 tracks all in the DSP-known-failure partition. Story 4-6 adds a `dsp_correct_controls` array (≥4 tracks) drawn from the existing OA300 corpus where: (a) DSP currently resolves within ±0.5 BPM at default config per the Story 4-5 impact report; (b) ground truth is in the 155-175 BPM range (so the DnB-half-tempo failure mode is even possible — comparing a 120 BPM track is not a meaningful control); (c) at least one is a DnB-genre / heavily-mastered track to match the named-failure distribution. **Schema bump.** `4-dnb-triplet-targets.json` schema_version increments from 2 to 3 with a new `dsp_correct_controls` array sibling to `targets`:
   ```json
   {
     "schema_version": 3,
     "captured_with": { ... unchanged ... },
     "targets": [ ... 4 existing named-failure tracks unchanged ... ],
     "dsp_correct_controls": [
       {
         "track_id": "10. Hellacopta_Assemby (Xiûa Remix)",
         "ground_truth_bpm": 170.0,
         "source": "oa300_ground_truth",
         "current_predicted_bpm": 169.99288260456274,
         "current_abs_error": 0.00711739543726,
         "rationale": "DSP-correct DnB control — same release family as Story 4-5 named failures (D-Struct/Acid Lab/Owl Remixes from 'Remixes Vol' compilation)"
       }
       // ... ≥3 more entries ...
     ],
     "regression_threshold": { ... unchanged ... }
   }
   ```
   **Frozen baseline.** The `current_predicted_bpm` and `current_abs_error` values for the controls are populated by reading the Story 4-5 impact report (`4-5-bnns-impact-report.json`) at Task 1 and frozen — NOT re-measured at Story 4-6 PR time. This matches Story 4-5 DD #1's "frozen named-track baseline" discipline.

   **Suggested control tracks** (verified DSP-correct in 4-5-bnns-impact-report.json @ ±0.5 BPM):
   - `10. Hellacopta_Assemby (Xiûa Remix).wav` (gt=170, dsp=169.99) — same compilation family as named failures.
   - `3. D3Z_Axons (Offish Remix).wav` (gt=170, dsp=170.18) — same compilation family.
   - `5. Darkgray Heart_Beating Heart Of The Summer Sun (robbyt Remix).wav` (gt=170, dsp=170.40) — same compilation family.
   - `6. HEFT_Fuyu (Akinsa Remix).wav` (gt=170, dsp=169.56) — same compilation family.
   The dev MAY substitute different tracks (e.g., diversify across compilations) but MUST keep ≥4 entries, all in the 155-175 BPM range with `dsp_correct == true` in the 4-5-bnns-impact-report.json. Document the substitution rationale in Completion Notes if deviating.

5. **Threshold sweep methodology — 7-point curve with corpus-wide distribution stats (REVISED 2026-05-15 per Codex finding #3 + Amelia + Mary).** The original DD #5 prescribed a 4-point sweep (0.0/0.0, 0.25/0.05, 0.30/0.05, final-chosen). Codex flagged this as evidence-thin: 4 points is theater; the load-bearing question is whether the model's decoded BPM distribution at zero threshold matches DSP's correct-track distribution. A 7-point curve plus per-run corpus-wide distribution stats makes the answer load-bearing. Per Story 4-5 deferred-work item #3 ("Investigate ML abstain rate on real audio... Either featurize has a subtle bug or the two-gate threshold is too aggressive"), the investigation method is:

   **Revised 7-point sweep ladder.** Run `make bnns-impact-report` 7 times at threshold pairs (confidence / margin):
   `0.00/0.00`, `0.10/0.02`, `0.20/0.04`, `0.30/0.05`, `0.40/0.08`, `0.50/0.10` (Story 4-5 shipped), and a final-chosen `<empirical optimum>` after the dev reads the curve. The 6-point base captures the shape; the 7th locks the production threshold pair.

   **Corpus-wide distribution stats per run** (Amelia's load-bearing addition + Mary's hypothesis-separation discipline). Each run's JSON adds these aggregations to the existing per-track rows:
   ```json
   {
     "thresholds": {"confidence": 0.0, "margin": 0.0},
     "abstain_rate": 0.91,
     "abstain_mode_histogram": {...},
     "wrong_non_abstain_count": <int>,     // ← THE HEADLINE COLUMN
     "decoded_bpm_histogram_5bpm_bins": [<count per 5-BPM bin from 60 to 200>],
     "decoded_bpm_in_range_fraction": <0..1>,        // fraction in [60, 200]
     "decoded_bpm_matches_dsp_within_4pct_fraction": <0..1>,
     "softmax_max_p50": <0..1>,
     "softmax_max_p95": <0..1>,
     "softmax_margin_p50": <0..1>,                   // softmax_max - softmax_secondMax median
     "softmax_margin_p95": <0..1>,
     "input_feature_checksum_unique_count": <int>    // sanity check — should equal corpus track count
   }
   ```
   At `0.00/0.00`, `wrong_non_abstain_count` is the headline number. If high, the model is broken regardless of gating (Outcome B/C below). The decoded-BPM histogram with all gates off tells you whether the model is producing useful predictions, degenerate predictions (all at bin 0 or 255), or threshold-dependent useful predictions. **This corpus-wide aggregation is what distinguishes "threshold too aggressive" from "featurize bug" — at zero gates, a featurize bug produces a non-uniform-but-wrong distribution; a threshold issue produces a useful-but-suppressed distribution.**

   **Revised outcome diagnosis (still 4 outcomes, now distinguishable from the corpus stats):**
   - **Outcome A — threshold too aggressive (highest prior).** At low thresholds, `wrong_non_abstain_count` is low AND `decoded_bpm_matches_dsp_within_4pct_fraction` is high (≥0.5 on DSP-correct tracks) AND named-DnB tracks have correct argmax. → Lower thresholds to the empirical optimum; bundle stays. Branch A.
   - **Outcome B — featurize bug.** At zero thresholds, `decoded_bpm_in_range_fraction` is high BUT `decoded_bpm_matches_dsp_within_4pct_fraction` is low (model produces in-range predictions but they're systematically wrong vs DSP). → Move to DD #6 differential to localize the featurize stage at fault.
   - **Outcome C — degenerate distribution.** At zero thresholds, `decoded_bpm_histogram_5bpm_bins` is concentrated on the boundary bins (60 or 200), indicating the softmax distribution is degenerate (post-decode out-of-range guard absorbs them or argmax is consistently at bin 0/255 BEFORE the decode guard fires). → Featurize bug at a more fundamental level than DD #6 catches; escalate to a model retrain follow-on or Branch C.
   - **Outcome D — model genuinely too weak.** At zero thresholds with a healthy distribution AND no Swift-Python featurize divergence (DD #6 returns clean), `decoded_bpm_matches_dsp_within_4pct_fraction` is still low. → Branch C; bundle pulled, retrain deferred to a future story.

   **The threshold sweep is purely investigative — production threshold remains gate-protected.** If Outcome A fires, the production fix is to lower the thresholds in `BNNSTechnique` constants (`confidenceThreshold` and `marginConfidenceThreshold`) to the empirically-chosen values, NOT to remove the gates entirely. The gates protect against confident-wrong predictions on out-of-distribution input; the question is "at what threshold does the model become useful without becoming reckless".

6. **Swift-vs-Python featurization differential — STRATIFIED 12-track set (REVISED 2026-05-15 per Codex finding #3 + Mary).** The original DD #6 used a single-track (Yin Yang) differential. Codex flagged this as insufficient: one track proves a bug exists but cannot prove corpus-wide absence. Mary's redesign: 12-track stratified set lets the differential isolate whether divergence is consistent (real bug) or track-specific (red herring). The 12 tracks:
   - **4 named-DnB failures** (the existing target set): Charly @ 160, Faraday_Bunker @ 170, Yin Yang @ 170, HEFT_Anagram 6 @ 170 (per `4-dnb-triplet-targets.json` v3 `targets` array).
   - **4 DSP-correct controls** (per DD #4 revised): the same 4 tracks the impact-report Control gate uses (`dsp_correct_controls` array, 155-175 BPM, DSP within ±0.5 BPM at default config).
   - **4 ordinary OA300 tracks**: 4 tracks drawn from outside the named+control set, distributed across BPM ranges (one each near 100, 130, 160, 175). Recommended: `Aeon Flux - Reality (Remaster).wav` (gt=150.95), `Echtoo - The Mummy - Seminal Sounds.wav` (gt=160), `Ironik - The Calling (Remaster).wav` (gt=157.84), `Stakka & Skynet - 11 9000 Series.mp3` (gt=172.96) — all DSP-correct at default config per `4-5-bnns-impact-report.json`.

   **Cheap-first methodology (DD #2 `inputFeatureChecksum` integration).** Before the expensive `.npz` round-trip, run the cheap `inputFeatureChecksum` differential: have the impact-report harness emit `inputFeatureChecksum` for each of the 12 tracks (Swift side), and the Python reference pipeline at `_bmad-output/ml-training/` emit the same checksum for the same WAV (Python side using the equivalent FNV-1a or xxHash over the post-`vvlogf` byte representation). If all 12 checksums agree, featurize is bit-exact → skip the `.npz` round-trip. If any disagree, run the full per-element `.npz` differential on the diverging tracks ONLY.

   **Full per-element methodology (only if cheap path flags divergence).** For each diverging track:
   - Capture `MLFeatureFrames.logMelData` via a NEW develop-only swift-feature-extractor CLI target `_bmad-output/ml-training/swift_feature_extractor/Sources/dump-track/main.swift` (sibling to existing `dump-fixture` and `bnns-probe`). Write the 128 × N row-major `[Float]` as a `.npz` AT THE STORY-4-5 POST-`vvlogf` BIT-EXACT SHAPE.
   - Run the same audio file through the Python tempo-cnn reference pipeline (`make ml-parity` shows the 4-stage Swift/Python parity harness already exists). Load the resulting Python features into the same `.npz`.
   - Compare per-element: max abs diff, RMS diff, transpose-orientation sanity check. If divergent stage is identified, fix the Swift featurize stage, re-run `make ml-parity`, then re-run the impact-report harness to verify recovery.
   - **If Python tempo-cnn produces a correct 170 BPM prediction on the matching features AND BNNS produces 113 on the same features, the bug is in the BNNS inference path itself** (graph compile, argument binding, or tensor-layout) — escalate to a graph-level investigation. This was already covered by Story 4-5's `validateContract` shape guards, so probability is low, but it's the third hypothesis that the differential must rule out.

   **The dev MAY skip this step if DD #5 Outcome A fires** and the threshold fix alone clears the AC gates. The differential is investigation insurance, not a hard-gated AC. **If DD #5 Outcome B or C fires, this step is REQUIRED** — Branch C cannot be declared without ruling out the featurize bug.

   **`tempo-cnn` reference repo not required.** Axiom-ai's question whether to reach into Schreiber & Müller's `tempo-cnn` Python repo (https://github.com/hendriks73/tempo-cnn) as an independent reference is answered: NO. The project's own `make ml-parity` 4-stage harness is sufficient because it tests the SAME feature pipeline that produced the bundled `giantsteps_v1.mlmodelc`. An independent reference would test a different model — interesting science, but not the question this story answers.

7. **Bundle pull mechanics — Branch C is fully specified.** Per Codex C2 framing from `deferred-work.md:423-435`. When Branch C fires (defined as: investigation completes, no remediation reaches ≥2/4 named DnB resolved AND ≥4/4 controls preserved at any threshold setting tried), the bundle is removed from the main-shipping path with these specific file moves:
   - **`Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` is moved to `_bmad-output/ml-models/giantsteps_v1.mlmodelc/` via `git mv`.** The history is preserved on develop; the bundle no longer ships when develop is squash-merged to main per the protocol in `CLAUDE.md` (the move puts it in the "Stays on `develop` ONLY" list).
   - **`Package.swift` keeps `BoomBoomBoomKitML` as a product but REMOVES `resources: [.copy("Resources")]` entirely under Branch C** (REVISED 2026-05-15 per Siri's Apple-platform-docs audit). No Apple precedent exists for "ship infrastructure, bundle nothing"; declaring `.copy("Resources")` against a directory containing only `.gitkeep` is non-idiomatic. Siri checked Foundation Models (Apple-bundled), Vision (Apple-bundled), and CoreML (consumer-supplied, NO `Resources/` directory) — the canonical pattern under Branch C is to remove the `resources:` declaration entirely and delete the empty Resources directory. Add the `resources: [.copy("Resources")]` line back when a higher-quality bundled model returns. Consumers using `BNNSTechnique(modelURL: customURL)` continue to work — they pass their own URL, not relying on `Bundle.module`.
   - **`BNNSTechnique.bundledReferenceURL` returns `nil` deterministically.** The current implementation (`Sources/BoomBoomBoomKitML/BNNSTechnique.swift:90-91`):
     ```swift
     public static let bundledReferenceURL: URL? =
       Bundle.module.url(forResource: "giantsteps_v1", withExtension: "mlmodelc")
     ```
     produces `nil` when the resource is absent. This is already the documented behavior — no code change is required. The constant remains `Optional<URL>` (no force-unwrap regressions).
   - **`BNNSTechnique()` no-arg form throws `MLTechniqueError.modelResourceMissing` deterministically.** Already the documented behavior (`Sources/BoomBoomBoomKitML/BNNSTechnique.swift:162-169`). `try? BNNSTechnique()` returns nil — consumers wanting BYOW use `try? BNNSTechnique(modelURL: myURL)`. The `init(modelURL:)` path with a non-nil URL continues to work unchanged.
   - **DocC on `BNNSTechnique` is updated** to remove the "bundled reference model" framing and replace with "consumer must provide a `.mlmodelc` via the `modelURL:` parameter; see `tools/coreml-convert/README.md` for the conversion workflow". The `bundledReferenceURL` static is documented as "always nil in the current ship; reserved for a future story that re-bundles a higher-quality model".
   - **`tools/coreml-convert/README.md` Path A documentation** ("Use library's bundled reference model") is updated to "removed in Story 4-6; pre-Story-4-6 commits shipped a bundled `giantsteps_v1.mlmodelc` that abstained on 100% of OA300 audio. The bundle was removed pending a higher-quality model." Path B (BYOW with converted weights) and Path C (custom conformance) are unchanged.
   - **`MODEL_CARD.md` is updated** to document the bundle removal: "Status: no bundled model ships in BoomBoomBoomKit ≥ 0.X. The previous `giantsteps_v1.mlmodelc` was removed in Story 4-6 due to 100% abstain on the OA300 test corpus. The training pipeline at `_bmad-output/ml-training/` remains available for consumers wanting to train their own model against compatible features."

   **Branch A bundle-retention requires the inverse mirror.** When the threshold fix or featurize fix lands and the gates pass, the bundle stays at `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` unchanged. No file moves required.

8. **AC-binding HALT discipline distinguishes "fix applied and effective" from "investigation closed without fix" (REVISED 2026-05-15 per Codex finding #6 + Mary — Branch A gate is STRICT 4/4, no slack).** The original DD #8 contained three contradictory statements about the Branch A gate: main text said "≥2/4 named AND ≥4/4 controls (strict)"; HALT-(f) said "≥2 controls broken → HALT" (implying ≥2/4 controls is tolerable); body separately said "≥1 control regression → NOT Branch A". Mary's call (stakeholder voice: the consumer who got 0/4 DnB in Story 4-5 will not thank us for shipping a bundle that wins one previously-broken track at the cost of breaking a previously-correct one): the gate is **strict 4/4** with one named slack option.

   **The story has THREE success paths and ONE failure path:**
   - **Branch A (strict success)** — DD #5 or DD #6 produces a fix; re-run impact report shows `named_dnb_resolved >= 2/4 AND dsp_correct_controls_preserved == 4/4` at default config (post-fix thresholds); bundle stays; story closes with the fix landed. **This is the default success path.**
   - **Branch A-conditional (named slack)** — IF AND ONLY IF the project lead explicitly authorizes at story-close time, a 3/4-controls outcome MAY ship as Branch A-conditional. Requires: (a) explicit MODEL_CARD.md entry naming the regressed control + impact-report row citation; (b) a named re-open trigger filed in Story 4-6 Completion Notes (per DD #15 below — re-open trigger pattern from Story 4-5 DD/Mary): "If a future ablation pass shows >5% Acc1 regression on the previously-passing control set, or if any additional control regresses, Story 4-6's bundle decision re-opens and Branch C is reconsidered."; AND (c) an explicit authorization line recorded verbatim in Completion Notes: `Branch A-conditional authorized YYYY-MM-DD by <name>: <one-sentence reasoning>`. Without ALL THREE of (a), (b), AND (c), 3/4 controls is NOT Branch A-conditional — it falls to Branch C. 2/4 or fewer controls preserved is ALWAYS Branch C, no slack. (Strict 4/4 Branch A does NOT require any of (a)/(b)/(c) — it ships clean.)
   - **Branch C (honest retreat)** — investigation exhausted (DD #5 Outcome D OR Outcome B+C with featurize differential showing no bug); bundle pulled per DD #7; story closes with bundle removed and Epic 4 close-out documented.
   - **NOT a path: silent partial fix.** Silent ratchet down of "≥4/4 controls preserved" to "3/4 controls" without invoking the Branch A-conditional path REQUIRES explicit story-spec amendment and PM sign-off — do not unilaterally relax the gate.

   **HALT triggers (named, story-prefixed per Story 4-5 DD #12 precedent):**
   - **4-6-HALT-(a) — Expanded DnB target set fails to load at Task 1.** Schema version mismatch, duplicate `track_id`, missing source file. → Fix the JSON OR remove the offending track before proceeding.
   - **4-6-HALT-(b) — Diagnostic capability path crashes or violates invariants.** The two-tuple invariant from DD #3 revised (the win path has BOTH `evaluation` and `snapshot` non-nil; the abstain path has `evaluation == nil` and `snapshot` non-nil-when-featurize-ran-or-nil-when-pre-featurize) MUST be enforced by a unit test BEFORE the impact-report harness uses the new path. If the invariant violates at Task 4 (BNNSTechnique conformance), fix the instrumentation BEFORE running Task 7 sweeps.
   - **4-6-HALT-(c) — Threshold-disabled smoke produces NaN/Inf BPMs at scale.** `make bnns-impact-report` with thresholds at 0.0 should still produce in-range `[60, 200]` BPMs OR snapshot-decodedBPM-nil + failureStage=`graphFailed`/`decodeRejected` — the `decodeLogits` BPM-range guard at `BNNSTechnique.swift:520` enforces this. If the harness produces out-of-range values silently passing the gates, decode has regressed.
   - **4-6-HALT-(d) — Asserted floors regress at default config (`mlTechnique == nil`).** Per Epic 4 Definitions (OA300 Acc1 ≥ 57/82, Acc2 ≥ 73/82; GiantSteps Acc1 ≥ 537/661, Acc2 ≥ 546/661). ANY corpus floor breach is an immediate HALT — Story 4-6 must not regress DSP-only correctness, regardless of branch.
   - **4-6-HALT-(e) — DSP-only byte-identity regresses.** Per AC #5. The DSP path (Options.mlTechnique == nil OR Options.ensemblePolicy == .dspOnly) must produce per-track BPM byte-identical to `4-6-regression-snapshot.json` captured pre-source-edit. Diagnostic instrumentation MUST NOT leak into the DSP path.
   - **4-6-HALT-(f) — Branch A claimed without strict 4/4 controls preserved (REVISED).** If the impact report shows `named_resolved >= 2/4` but `controls_preserved < 4/4`, the dev MUST NOT close as Branch A. Two paths forward: (1) Find a different threshold/fix that clears strict 4/4 (preferred); OR (2) Pursue Branch A-conditional (per DD #8 success-paths above) WITH project-lead authorization + MODEL_CARD entry + re-open trigger; OR (3) Fall to Branch C. Silent close as Branch A with `controls_preserved < 4/4` is incoherent and the HALT must fire.
   - **4-6-HALT-(g) — Branch C claimed but bundle still present.** If Completion Notes claim Branch C, the diff scope proof MUST show `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` is absent (moved via `git mv`) AND the `resources: [.copy("Resources")]` line is removed from `Package.swift` (per DD #7 revised). A Branch-C close-out with the bundle still in place is incoherent.
   - **4-6-HALT-(h) — Test count outside band.** Band `[416, 424]` per DD #12 revised. Outside band → investigate test drift.

9. **Bundle pull does NOT remove `BNNSTechnique` from the public API.** Per Story 4-5 BYOW pivot — the conformance + `init(modelURL:)` + tensor-contract validation + protocol surface all ship regardless of whether a model is bundled. The bundle pull is purely a file move from `Sources/.../Resources/` to `_bmad-output/ml-models/`; the consumer-facing API surface is unchanged. The only consumer-observable difference: `BNNSTechnique()` no-arg form throws (Branch C) vs returns a working instance (Branch A). This is already the documented behavior of `init(modelURL:)` since Story 4-5 — the throw fires when the bundled URL resolves to nil.

10. **CoreML conformance is OUT OF SCOPE.** Regardless of branch outcome. The placeholder at `Sources/BoomBoomBoomKitML/CoreMLTechnique.swift` is NOT touched by Story 4-6. If Branch A fires (bundle retained, fix effective), a follow-on story (suggested slug `4-8-coreml-mltechnique-conformance` to avoid colliding with the renamed 4-6 slug) is authored against the post-4-6 baseline. If Branch C fires (bundle pulled), CoreML conformance is dropped from Epic 4 as well — there's no bundled model for it to load, and CoreMLTechnique-with-consumer-supplied-URL is symmetric infrastructure that doesn't add value over BNNSTechnique-with-consumer-supplied-URL.

11. **Pre-1.0 / no-BC posture, restated (REVISED 2026-05-15).** Story 4-6 lands TWO new public types and one new public protocol:
    - `MLDiagnosticSnapshot` struct (with nested `FailureStage` + `Gate` enums) in `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift` — new file.
    - `MLDiagnosticTechnique: MLTechnique` capability protocol in `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift` — new file.
    - `BPMDiagnosticTrace.mlDiagnosticSnapshot: MLDiagnosticSnapshot?` field — added to existing `BPMDiagnosticTrace.swift`.
    The original DD #11 referenced an `MLAbstainReason` struct that has been DROPPED per DD #2 revised — the discriminated taxonomy is no longer a public type; it's a private reporting view in `BNNSImpactTests.swift`.

    Per project-context.md "Public API Discipline (pre-1.0)", these are explicitly NOT 1.0-stable — a future story may rename `MLDiagnosticSnapshot`, add fields beyond the current 5 (decodedBPM/softmaxMax/softmaxSecondMax/inputFeatureChecksum/failureStage+gateFired), add cases to `FailureStage` (e.g., split `graphFailed` further if a second backend lands), or promote the `MLDiagnosticTechnique` protocol to be the primary entry point if a second conformer surfaces consistent needs. The `BNNSTechnique.evaluateWithDiagnostic(trace:)` method is explicitly pre-1.0 — same caveat.

12. **Test count band — `[416, 424]` (REVISED 2026-05-15 per Amelia + axiom-swift parameterized-test collapse; FURTHER REVISED 2026-05-15 per Critique-and-Refine W1 — tightened from `[416, 433]` to `[416, 424]` after Codex flagged the +17 ceiling as a copy-paste artifact).** Pre-story baseline = 400 (`rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l` at HEAD `1c8e274`). Post-review test plan with parameterized collapse:
    - **`MLDiagnosticSnapshotTests.swift` (~6 tests):** initShapeRulesWinPath (all fields non-nil), initShapeRulesPreFeaturizeAbstain (decodedBPM/softmax fields nil), initShapeRulesPostDecodeAbstain (decodedBPM/softmax non-nil, failureStage = .confidenceGateRejected, gateFired non-nil), FailureStage.allCases.count == 6 (NEW count — graphFailed + decodeRejected split out of inferenceFailed), Gate.allCases.count == 2, equatableAndHashable.
    - **`MLDiagnosticTechniqueTests.swift` (+2):** capability-protocol conformance witness (compile-time `assertMLDiagnosticTechnique<T: MLDiagnosticTechnique>(_:)` against BNNSTechnique.self), the protocol inherits `MLTechnique` (compile-time check via existential).
    - **`BNNSTechniqueDiagnosticTests.swift` parameterized via `@Test(arguments:)` (~3 tests collapsing 12 cases):** `evaluateWithDiagnosticPaths` parameterized over the 6 failure stages + 1 win path, asserting the snapshot shape for each; `traceAttachmentInvariants` parameterized over the 4 trace-context cases (win/abstain × enableTrace true/false); `dspOnlyAndNilMlShortCircuit` covering the policy/mlTechnique combinations.
    - **`BNNSTechniqueAbstainFloorTests.swift` (+2 REVISED per Codex finding #9):** `abstainFloorOnRealAudio_DspCorrectControls` (pick 20 OA300 tracks where DSP is correct at intensity 7; run BNNS at thresholds 0.0/0.0; assert `abstain_rate <= 0.30`) + `wrongNonAbstainCeiling_DspCorrectControls` (same 20 tracks; assert `wrong_non_abstain_count <= 4`). Both gated on `BNNS_IMPACT=1` so default CI doesn't pay 5s; promoted to a fast lane via the `BNNSTechnique.thresholdOverride` seam so the impact-report-harness path is the test path.
    - **`DnBTargetsFileLoadingTests.swift` (+1):** loadsSchemaVersion3 (4 named + ≥4 controls + uniqueness across both arrays).
    - **`AudioAnalysisServiceInoutTraceTests.swift` (+2):** `inoutTraceMutationAfterCancellation` (cancellation flips post-evaluate → caller throws AND trace.mlDiagnosticSnapshot remains nil — the strict ordering per DD #3 revised and Codex finding #4); `inoutTraceMutationOnWinPath` (snapshot populated when evaluation non-nil AND no cancellation).

    Sum: 16 new tests (post-collapse). Target = 400 + 16 = 416. Band: `[416, 424]` — target 416 with +8 tolerance for assertion-split refactors during dev (6 new files × ~1 split tolerance each). The band is NOT a "collapse-further" allowance: if the inventory drops below 416, that signals a missing test, and DD #12 must be revised, not the band stretched. Outside band → investigate test drift before merging.

13. **Sequencing: this story BLOCKS any CoreML follow-on.** Per epics.md Branch decision rules. A CoreML conformance story cannot be promoted from `backlog` to `ready-for-dev` until Story 4-6 reaches `done` AND the Story 4-6 close-out commit explicitly names which Branch fired. The Story 4-5 spec referenced "Story 4.6 cannot be promoted until Story 4.5 reaches done" — Story 4-6 carries forward the same discipline for its own successor.

14. **Project-wide architectural elevation (NEW 2026-05-15 per Winston).** Story 4-6 surfaces a complement to Story 4-5's RAII-via-final-class rule: **"Cross-target type narrowing always goes through a protocol declared in the upstream target, never through `as?` to a downstream concrete type."** The lesson generalizes beyond ML — any time a core type needs runtime-narrowing of a sibling-target value, the narrowing surface must be a core-declared protocol. Update `_bmad-output/project-context.md` at story close-out (alongside the Story 4-5 RAII-discipline addition).

15. **Re-open trigger (NEW 2026-05-15 per Mary's stakeholder-rigor pattern, mirrors Story 4-5 Mary-confidence-rule).** Story 4-6 introduces ONE named re-open trigger that applies under Branch A-conditional (DD #8 success-paths) AND optionally as a defensive watch under Branch A strict: **"If a future ablation pass shows >5% Acc1 regression on the previously-passing control set (`dsp_correct_controls` in `4-dnb-triplet-targets.json` v3), or if any additional control regresses (preserved → not-preserved), Story 4-6's bundle decision re-opens and Branch C is reconsidered with a follow-on story."** Filed in Completion Notes at close-out; tracked as a deferred-work entry if Branch A-conditional fires. Without the re-open trigger, "Branch A-conditional" is just "Branch A with a shrug" — the trigger names the condition under which the deferred decision must be revisited.

16. **MODEL_CARD framing under Branch C (NEW 2026-05-15 per Mary).** If Branch C fires, the close-out narrative is not "ML doesn't work" — it's **"*this* reference model (`giantsteps_v1.mlmodelc` trained on lossy 96kbps GiantSteps MP3) doesn't generalize past its training distribution."** That distinction protects the BNNSTechnique infrastructure investment from being misread as a failed experiment. The MODEL_CARD update under Branch C (per Task 9.4 revised) MUST include this framing verbatim or close: the infrastructure (load, featurize, inference, two-gate, diagnostic capability) is unchanged and ready to consume a higher-quality model when one is trained; the bundle was pulled because the specific bundled model didn't generalize, not because the integration architecture failed.

17. **Branch C governance — amend `epics.md:1118-1127` (NEW 2026-05-15 per Codex finding #7 + Mary).** The original DD #1 acknowledged but glossed over the governance drift: epics.md says strict Branch C moves Story 4.6 to backlog and spawns a 4-6b research-spike, but Story 4-6 occupies the 4-6 slot as the spike vehicle directly. Mary's 3-sentence amendment to `epics.md:1118-1127` resolves the drift cleanly:

    > **Authorized 2026-05-14: Story 4-6 occupies the diagnostic-spike role originally scoped for a separate 4-6b spike. If Branch C fires, the bundle moves to develop-only `_bmad-output/ml-models/`; no follow-up story is spawned unless impact evidence justifies it. The slot's acceptance criteria are re-cast from "CoreML conformance" to "diagnostic instrumentation + bundle decision" per the Story 4-6 spec at `_bmad-output/implementation-artifacts/4-6-ml-accuracy-investigation-and-bundle-decision.md`.**

    This amendment is part of Story 4-6's first commit (alongside the spec) — apply it BEFORE the dev agent starts so the governance artifact and the story spec agree. Audit trail preserved; phantom 4-6b spike eliminated.

---

## Background

Story 4-5 shipped the `BNNSTechnique` conformance, the `MLFeatureFrames` typed-evidence trace, the `MLTechnique` public protocol freeze, the `MLTechniqueError` enum, the cancellation helper, the `make bnns-impact-report` Makefile target, and the `tools/coreml-convert/` consumer onboarding doc. The empirical outcome (per `_bmad-output/implementation-artifacts/4-5-bnns-impact-report.json` summary block):

| Metric | Value | Interpretation |
|---|---|---|
| OA300 total tracks | 82 | full corpus |
| DSP-only Acc1 | 58/82 (70.7%) | baseline; unchanged from pre-Story-4-5 |
| ML-only Acc1 | 0/82 | BNNSTechnique abstains on every single track |
| Ensemble Acc1 (`.mlOnly` policy) | 58/82 | identical to DSP-only (ML never wins; DSP fallback every time) |
| Named DnB triplets resolved (±0.5 BPM) | 0/4 | HALT (b) fires per Story 4-5 |
| Named DnB resolved via DSP fallback | 0/4 | even the DSP path fails on the 4 named tracks |

The Story 4-5 dev agent's Task 1.5d probe (`_bmad-output/implementation-artifacts/4-5-allocator-probe.log`) showed the bundled `giantsteps_v1.mlmodelc` CAN produce a confident, in-range prediction on synthetic uniform input — `Array(repeating: 0.5, count: 65536)` → argmax bin 140 → 170 BPM. The model is functionally loadable; the BNNS inference path runs end-to-end; the host-side softmax produces a valid distribution. The 100% abstain is therefore NOT a graph-level failure, NOT an inference path failure, NOT a softmax decode failure. It is one of:

- **Featurize bug** — z-score normalizing along the wrong axis, transpose orientation off, resample direction inverted, vDSP_normalize emitting NaN on constant rows that propagates through the graph.
- **Threshold too aggressive** — Story 4-5 DD #10 calibrated `confidenceThreshold = 0.50` and `marginConfidenceThreshold = 0.10` for "the lossy 96 kbps GiantSteps training distribution"; real OA300 audio (varied bitrates, varied production aesthetics) may sit below those thresholds on the model's natural confidence distribution.
- **Model genuinely too weak** — the model was trained on a specific corpus; real-world DnB material with limiter-flattened dynamic range may simply be out of distribution.

These three hypotheses produce DIFFERENT remediations:
- Featurize bug → fix the featurization step (one-shot code change; re-run impact report; bundle retained).
- Threshold too aggressive → lower the constants in `BNNSTechnique` (one-shot code change; re-run impact report; bundle retained).
- Model too weak → no software fix; bundle pulled; consumers BYOW.

**Story 4-6's job is to distinguish which hypothesis is true and apply the indicated remediation.** The six-stage diagnostic snapshot (DD #2 revised) is the instrument; the 7-point threshold-disabled smoke (DD #5 revised) is the first measurement; the stratified 12-track Swift-vs-Python differential (DD #6 revised) is the backup measurement if the first is inconclusive; the bundle-pull mechanics (DD #7 revised) is the documented retreat path.

**Why this isn't a Branch C research-spike under a new slug.** Per epics.md Branch C rules, the strict treatment is: move Story 4.6 BACK to backlog, write a new research-spike story (e.g., 4-6b), promote that, finish it, then re-promote 4-6 with re-spec'd ACs based on spike findings. The Story 4-5 close-out instead chose to fold the spike into Story 4-6 itself with hard AC — the rationale (per sprint-status `last_updated` 2026-05-14): a single-story package with concrete success/failure gates and a clear remediation path is more honest than spawning a separate spike just for procedural alignment. The 4-6 slot is the only natural place to capture both the investigation AND the resulting bundle decision.

**Why the bundle decision must land in this story.** Per Codex C2 framing: "Pre-1.0 is exactly when to be strict about not shipping an ineffective bundled binary." Story 4-5 closed with the bundle still shipping at `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` even though it produces zero ML wins. Continuing to ship a binary that adds zero value to the main-shipping path violates the project's quality discipline. The bundle either earns its place (Branch A — investigation finds and fixes the issue) or gets pulled (Branch C — investigation confirms the model is the limit, not the wiring).

## Acceptance Criteria

1. **`MLDiagnosticSnapshot` public typed-evidence struct + nested `FailureStage` / `Gate` enums (REVISED 2026-05-15 — see DD #2 revised).** Story 4-6 lands `MLDiagnosticSnapshot` instead of the original `MLAbstainReason`. The old `MLAbstainReason` discriminated-enum design is DROPPED from the public API — its histogram view becomes a private reporting struct in `BNNSImpactTests.swift`.

   **Given** the current public-API surface defined in Story 4-5 (`MLEvaluation`, `MLTechnique`, `MLTechniqueError` in `Sources/BoomBoomBoomKit/MLTechnique.swift`)
   **When** Story 4-6 ships
   **Then** a NEW file `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift` contains a `public struct MLDiagnosticSnapshot: Sendable, Hashable, CustomStringConvertible, Equatable` per DD #2 verbatim shape (5 fields: `decodedBPM: Double?`, `softmaxMax: Double?`, `softmaxSecondMax: Double?`, `inputFeatureChecksum: UInt64`, `failureStage: FailureStage?`; plus `gateFired: Gate?` populated only when `failureStage == .confidenceGateRejected`)
   **And** the file contains `public enum FailureStage: String, Sendable, Hashable, CaseIterable` with EXACTLY 6 cases (`featuresAbsent`, `featureVersionMismatch`, `featurizeRejected`, `graphFailed`, `decodeRejected`, `confidenceGateRejected`) — `FailureStage.allCases.count == 6` locked by unit test. Note: 6 cases, not the original 5 — `inferenceFailed` is split into `graphFailed` (BNNSGraph call returned non-zero) and `decodeRejected` (out-of-range BPM or non-finite logits) per Codex finding #2 + Amelia.
   **And** the file contains `public enum Gate: String, Sendable, Hashable, CaseIterable` with exactly 2 cases (`gate1Softmax`, `gate2Margin`)
   **And** the `init` enforces shape rules via `precondition` — but NOTE: for `featuresAbsent` / `featureVersionMismatch`, no `MLDiagnosticSnapshot` is constructed at all (the abstain fires before featurize so there is no feature payload to checksum). The trace's `mlDiagnosticSnapshot` field stays nil on those paths per DD #2 Population rule; this AC's precondition rules therefore apply ONLY when a snapshot IS constructed. The construct-time preconditions: on the win path (`failureStage == nil`), `decodedBPM`/`softmaxMax`/`softmaxSecondMax`/`inputFeatureChecksum` are all non-nil; on `featurizeRejected`, `inputFeatureChecksum` is mandatory but decode fields are nil; on `graphFailed`/`decodeRejected`, decode fields are nil but `inputFeatureChecksum` is mandatory (featurize ran); on `confidenceGateRejected`, decode fields + `gateFired` + `inputFeatureChecksum` are all non-nil.
   **And** the `description` string contains `failureStage?.rawValue ?? "win"` literal AND `decodedBPM` literal when populated; bounded length (< 200 chars).

2. **`BPMDiagnosticTrace.mlDiagnosticSnapshot: MLDiagnosticSnapshot?` field is added; populated on every ML-active evaluation that reaches featurize (REVISED).**

   **Given** the current trace shape at `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (existing `mlFeatures: MLFeatureFrames?` and `ensembleDecision: EnsembleDecision?` fields from Stories 4-5 and 4-4)
   **When** Story 4-6 ships
   **Then** the trace gains `public var mlDiagnosticSnapshot: MLDiagnosticSnapshot?` under a new `// MARK: - Story 4.6: ML Diagnostic Snapshot` section
   **And** the field is populated by `AudioAnalysisService.evaluateMLIfActive` AFTER the conformance returns from `evaluateWithDiagnostic(trace:)` (per AC #3 revised) — populated on the win path AND on abstain paths that reached featurize (`featurizeRejected`, `graphFailed`, `decodeRejected`, `confidenceGateRejected`); LEFT NIL on the two pre-featurize abstain paths (`featuresAbsent`, `featureVersionMismatch`) where the conformance returns `(nil, nil)` per DD #3 tuple invariant
   **And** the trace-population invariant holds: `mlDiagnosticSnapshot != nil` requires ALL of (a) `mlTechnique` conforms to `MLDiagnosticTechnique`, (b) `ensemblePolicy != .dspOnly`, (c) a trace was built (`shouldBuildTrace` was true), (d) `enableTrace == true` (consumer-facing gate), AND (e) the conformance's `evaluateWithDiagnostic` returned a non-nil snapshot (i.e., featurize ran)
   **And** `mlDiagnosticSnapshot` is `nil` on every DSP-only call, on every call where the conformer does NOT adopt `MLDiagnosticTechnique` (consumer-supplied `MLTechnique` types fall back to `evaluate(trace:)` plain path; their snapshot field stays nil), AND on the two pre-featurize abstain paths above

3. **`BNNSTechnique` conforms to `MLDiagnosticTechnique` capability protocol (REVISED).**

   **Given** the new `MLDiagnosticTechnique: MLTechnique` capability protocol in `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift` (per DD #3 revised)
   **When** Story 4-6 ships
   **Then** `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` gains an `extension BNNSTechnique: MLDiagnosticTechnique` trailing the existing type declaration, with `public func evaluateWithDiagnostic(trace: BPMDiagnosticTrace) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?)` forwarding to a new private `evaluateInternal` helper that holds the inference + decode + threshold logic
   **And** the protocol-public `evaluate(trace:)` continues to work; it is rewritten as a 2-line forward returning `evaluateInternal(trace:).evaluation`. The two paths share inference + decode + threshold logic — no duplication.
   **And** the two-element tuple invariant holds: snapshot is populated on every call when `featurize` ran (win, decodeRejected, confidenceGateRejected); snapshot is non-nil with `decodedBPM`/`softmaxMax`/`softmaxSecondMax` nil for `graphFailed`; snapshot is non-nil with only `inputFeatureChecksum` populated for `featurizeRejected`; snapshot is `nil` ONLY for `featuresAbsent` / `featureVersionMismatch` (pre-featurize abstains). A parameterized unit test locks this contract with input fixtures exercising all 7 paths (6 failure stages + win).
   **And** the protocol surface `MLTechnique` is UNCHANGED — Story 4-5 DD #18 freeze preserved. `grep -rn "evaluateWithDiagnostic" Sources/BoomBoomBoomKit/MLTechnique.swift` returns zero matches; the new method lives on `MLDiagnosticTechnique.swift`.

4. **`AudioAnalysisService.evaluateMLIfActive` routes via `MLDiagnosticTechnique` capability narrowing, with strict mutation-after-cancellation ordering (REVISED per Codex finding #1 + #4).**

   **Given** the existing helper at `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:416-427` (Story 4-5 cancellation cooperation helper)
   **When** Story 4-6 ships
   **Then** the helper signature changes from `private static func evaluateMLIfActive(options: Options, trace: BPMDiagnosticTrace?) throws -> MLEvaluation?` to `private static func evaluateMLIfActive(options: Options, trace: inout BPMDiagnosticTrace?) throws -> MLEvaluation?`
   **And** the body performs runtime narrowing via the CORE-DECLARED `MLDiagnosticTechnique` protocol (NOT the concrete `BNNSTechnique` type — which lives in the sibling target and cannot be named from core; per Codex finding #1):
   ```swift
   guard options.ensemblePolicy != .dspOnly, let ml = options.mlTechnique, let unwrappedTrace = trace
   else { return nil }
   if options.isCancelled() { throw CancellationError() }
   // Evaluate into locals — NO trace mutation yet
   let localEvaluation: MLEvaluation?
   let localSnapshot: MLDiagnosticSnapshot?
   if let diag = ml as? MLDiagnosticTechnique, options.enableTrace {
       let result = diag.evaluateWithDiagnostic(trace: unwrappedTrace)
       localEvaluation = result.evaluation
       localSnapshot = result.snapshot
   } else {
       localEvaluation = ml.evaluate(trace: unwrappedTrace)
       localSnapshot = nil
   }
   // Post-evaluate cancellation check BEFORE any trace mutation (Codex finding #4)
   if options.isCancelled() { throw CancellationError() }
   // Mutation strictly last — cancellation cannot strand a stale snapshot in the trace
   var mutableTrace = unwrappedTrace
   mutableTrace.mlDiagnosticSnapshot = localSnapshot
   trace = mutableTrace
   return localEvaluation
   ```
   **And** the cancellation contract from Story 4-5 is preserved AND tightened: pre-evaluate AND post-evaluate `options.isCancelled()` checks bracket both call paths; trace mutation strictly follows the post-evaluate cancellation check (NEW). A unit test in `AudioAnalysisServiceInoutTraceTests.swift` (per DD #12 revised) injects cancellation flipping post-evaluate and asserts `trace.mlDiagnosticSnapshot == nil` after the throw — proving the strict ordering.
   **And** the `analyzeBPM` call site at `AudioAnalysisService.swift:328-329` is updated to thread the trace by `&` (inout). Because `BPMResult.trace` is a `let` field on the post-corroboration BPMResult, the call site pulls `corroborated.trace` into a local `var`, passes `&`, then reconstructs `corroborated` with the mutated trace before `EnsembleCombiner.combine`.

5. **DSP-only path byte-identity preserved.**

   **Given** the Story 4-6 source changes
   **When** `make benchmark` and `make benchmark-giantsteps` run pre-merge with `Options.mlTechnique == nil` (default) OR `Options.ensemblePolicy == .dspOnly`
   **Then** the non-regression gate per Epic 4 Definitions holds — asserted floors hold (OA300 Acc1 ≥ 57/82, Acc2 ≥ 73/82; GiantSteps Acc1 ≥ 537/661, Acc2 ≥ 546/661) AND per-track BPM JSON output is byte-identical (`Double.bitPattern` equality on `bpm` and `confidence`, element-wise on `candidates`) to the pre-Story-4-6 snapshot at `_bmad-output/implementation-artifacts/4-6-regression-snapshot.json`
   **And** the snapshot is captured BEFORE the Story 4-6 first dev commit (Task 1) and verified at PR time
   **And** Completion Notes link to the snapshot artifact AND the byte-equality opt-out test (`Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-3-baseline-bpms.json` continues to serve as the frozen per-track baseline; Story 4-6 verifies the snapshot matches it on the DSP-only path)
   **And** `mlDiagnosticSnapshot` is `nil` on every DSP-only call — `Options.mlTechnique == nil` short-circuits before the helper even checks the protocol conformance, and `Options.ensemblePolicy == .dspOnly` short-circuits at the helper's first guard. A unit test locks both paths.

6. **Expanded `4-dnb-triplet-targets.json` with `dsp_correct_controls` partition (≥4 tracks; schema_version 3).**

   **Given** the current `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` (schema_version 2, 4 named-failure tracks)
   **When** Story 4-6 ships
   **Then** the file is updated to schema_version 3 per DD #4 verbatim shape — same 4 entries in `targets`, plus a new `dsp_correct_controls` array with ≥4 entries
   **And** every entry in `dsp_correct_controls` resolves to an existing file in `OA300_CORPUS_PATH` AND has `current_predicted_bpm` within ±0.5 BPM of `ground_truth_bpm` (verified by reading `4-5-bnns-impact-report.json` at story-authoring time and propagating the values)
   **And** all entries are in the 155-175 BPM range per DD #4 — the DSP-correct controls must be in the same tempo neighborhood as the named failures so the half-tempo failure mode is mechanically possible
   **And** at least one entry is rationaled as "DnB-genre or heavily-mastered" in its `rationale` field — controls that are too acoustically dissimilar to the named failures provide weak signal
   **And** the `BNNSImpactTests` schema_version + uniqueness invariants (existing review-fix-N8) extend to validate `dsp_correct_controls`: schema_version must be 3, no duplicate `track_id` across `targets` ∪ `dsp_correct_controls`. A test locks this

7. **Diagnostic-instrumented impact report under six-stage attribution.**

   **REVISED 2026-05-16 — harmonized with running-benchmarks skill envelope.** The original AC #7 (below) prescribed `schema_version: 2` at the spec-literal filename `_bmad-output/implementation-artifacts/4-6-bnns-impact-report.json`. During Story 4-6 close-out the schema was harmonized with the `running-benchmarks` skill's perf-baselines envelope: `schema_version: 3` adds top-level provenance fields (`recorded_at`, `git_sha`, `build_configuration`, `hardware{}`, `applied_thresholds`, `corpus_distribution`) matching the same shape `PerformanceBenchmarkTests` baseline records use; fingerprint-named files live under `_bmad-output/perf-baselines/bnns-impact/{fingerprint}--{buildConfig}--{recordedAt}--{gitSHA}--{shortUUID}.json` so per-run records are immutable + jq-filterable by SHA/threshold/build-config; `snapshot_sha` is removed (`git_sha` carries that signal). The 7-bucket `failure_stage_histogram` was extended to 9 buckets in Story 4-6 code review P18 (Codex Option B) — adds `mlNotRun` (BNNS init/run failed entirely) and `diagnosticSnapshotMissing` (consumer's MLTechnique conformer did NOT adopt `MLDiagnosticTechnique`) as explicit accountability buckets so the conservation invariant `histogramSum == allRows.count` holds unconditionally. The schema diagram and field list below describe v2 as originally specified; the post-close-out implementation in `BNNSImpactTests.swift` is the authoritative v3 reference.

   **Given** the diagnostic plumbing from ACs #1-4 + the expanded target set from AC #6 + the existing `BNNSImpactTests` harness from Story 4-5
   **When** `make bnns-impact-report` runs with `OA300_CORPUS_PATH` set against HEAD post-Story-4-6
   **Then** the resulting `_bmad-output/implementation-artifacts/4-6-bnns-impact-report.json` (note: NEW filename `4-6-bnns-impact-report.json`, NOT overwriting Story 4-5's artifact) is produced with a schema extending Story 4-5's:
   ```json
   {
     "schema_version": 2,
     "snapshot_sha": "<post-fix commit SHA>",
     "model_identifier": "bnns_tempo_v1",
     "pinned_config": { "intensity": 8, "ensemble_policy": "mlOnly" },
     "named_dnb_track_results": [ ... 4 named-failure results, same shape as Story 4-5 ... ],
     "dsp_correct_control_results": [
       {
         "track_id": "<id>",
         "ground_truth_bpm": <bpm>,
         "ensemble_winner_bpm": <bpm>,
         "dsp_winner_bpm": <bpm>,
         "abs_error_bpm": <bpm>,
         "preserved_within_05": <bool>,
         "ml_diagnostic_snapshot": { "failure_stage": "<one of 6 stages or null on win>", "decoded_bpm": <bpm or null>, "softmax_max": <float or null>, "softmax_second_max": <float or null>, "input_feature_checksum": <UInt64 or null>, "gate_fired": "<gate1Softmax|gate2Margin|null>" }
       }
     ],
     "all_tracks": [ ... 82 tracks, extending the Story 4-5 schema with `ml_diagnostic_snapshot` field per track ... ],
     "failure_stage_histogram": {
       "featuresAbsent": <count>,
       "featureVersionMismatch": <count>,
       "featurizeRejected": <count>,
       "graphFailed": <count>,
       "decodeRejected": <count>,
       "confidenceGateRejected": <count>,
       "noAbstain": <count>
     },
     "summary": {
       "total_tracks": <int>,
       "dsp_acc1": <int>,
       "ml_acc1": <int>,
       "ensemble_acc1": <int>,
       "named_dnb_resolved": <int>,
       "named_dnb_resolved_via_dsp_fallback": <int>,
       "named_dnb_total": 4,
       "dsp_correct_controls_preserved": <int>,
       "dsp_correct_controls_total": <int>
     }
   }
   ```
   **And** the histogram MUST account for all 82 tracks: `sum(histogram values) == total_tracks`
   **And** at the post-fix configuration (whichever branch fires), Branch A success requires `named_dnb_resolved >= 2` AND `dsp_correct_controls_preserved == dsp_correct_controls_total` (≥4/4)
   **And** Completion Notes record the failure-stage histogram before AND after the fix (two snapshots: pre-fix at Task 3.1, post-fix at Task 6.x). The diff between the two histograms is the empirical proof of which hypothesis was correct

8. **Threshold-disabled smoke + investigation deliverable.**

   **REVISED 2026-05-16 — harmonized with running-benchmarks skill envelope.** Under the v3 schema (see AC #7 revised) each `make bnns-impact-report` invocation writes one fingerprint-named JSON to `_bmad-output/perf-baselines/bnns-impact/`. The original AC #8 prescribed a single aggregated `_bmad-output/implementation-artifacts/4-6-threshold-sweep.json` containing all 7 runs; the harmonized convention writes 7 separate per-run files (each with its own `applied_thresholds` field) that downstream `jq` recipes aggregate at review time — same data, immutable per-run, no out-of-band aggregation file. The `running-benchmarks` SKILL.md documents the threshold-sweep workflow (set `BNNS_THRESHOLD_OVERRIDE_CONFIDENCE` + `BNNS_THRESHOLD_OVERRIDE_MARGIN` env vars across 7 invocations, compare via `jq -s 'sort_by(.applied_thresholds.confidence)'`). Story 4-6 close-out's sweep evidence lives as these per-run files plus the Completion Notes narrative summarizing Outcome D.

   **Given** the diagnostic instrumentation from ACs #1-4
   **When** the dev runs Task 3 (threshold-disabled smoke) per DD #5
   **Then** an artifact `_bmad-output/implementation-artifacts/4-6-threshold-sweep.json` is produced with at least 7 runs per DD #5 revised (thresholds `0.00/0.00`, `0.10/0.02`, `0.20/0.04`, `0.30/0.05`, `0.40/0.08`, `0.50/0.10` Story-4-5-shipped, and a final chosen production pair)
   **And** each run records: (threshold pair, full failure-stage histogram, named_dnb_resolved count, dsp_correct_controls_preserved count, plus the corpus-wide distribution stats per DD #5 revised: `wrong_non_abstain_count`, `decoded_bpm_histogram_5bpm_bins`, `decoded_bpm_in_range_fraction`, `decoded_bpm_matches_dsp_within_4pct_fraction`, `softmax_max_p50/p95`, `softmax_margin_p50/p95`, `input_feature_checksum_unique_count`)
   **And** Completion Notes identify which DD #5 outcome (A/B/C/D) fired AND document the chosen remediation path
   **And** when DD #5 Outcome B or C fires, an artifact `_bmad-output/implementation-artifacts/4-6-featurize-differential.json` is produced per DD #6 (Swift-vs-Python featurization comparison; if this step is skipped because Outcome A fired, Completion Notes explicitly say "DD #6 skipped — Outcome A cleared the gates")

9. **Corpus-anchored abstain-floor test prevents silent regression on real audio (REVISED 2026-05-15 per Codex finding + Amelia).** The original AC #9 prescribed a synthetic-input test (5 deterministic arrays). Codex flagged this as evidence-thin: the synthetic-uniform path ALREADY worked in Story 4-5 — only real audio abstained. A synthetic-only test would have passed in 4-5 without catching the actual defect. The revised AC #9 anchors on real audio.

   **Given** Codex C4 framing from `deferred-work.md:452-459` — `make bnns-impact-report` is develop-only; CI's `make test` never exercises the impact harness, so the 100%-abstain artifact landed without observable CI failure
   **When** Story 4-6 ships
   **Then** a new env-gated test suite `Tests/BoomBoomBoomKitTests/BNNSTechniqueAbstainFloorTests.swift` contains TWO tests under `BNNS_IMPACT=1` (matching the Story 4-5 impact-harness gate; promoted via the `BNNSTechnique.thresholdOverride` testing seam from Task 7.1):
   - **`abstainFloorOnRealAudio_DspCorrectControls`** — Pick 20 OA300 tracks where DSP currently resolves correctly at `intensity = .default` (Acc1 == true per `4-5-bnns-impact-report.json`). Run `BNNSTechnique` against each at thresholds `0.0/0.0` (override via the testing seam). Assert `abstain_rate <= 0.30` (≤ 6 of 20 abstain). The Story 4-5 100%-abstain regression would have produced abstain_rate ~= 1.0 here — caught instantly.
   - **`wrongNonAbstainCeiling_DspCorrectControls`** — Same 20 tracks, same threshold override. Of the non-abstaining tracks, assert `wrong_non_abstain_count <= 4` (the ones where ML emits a non-abstaining prediction OUTSIDE the 4% Acc1 tolerance of DSP's correct value). Catches the "doesn't abstain but predicts garbage" branch Codex flagged in finding #2 + #5.

   **And** the tests run under `BNNS_IMPACT=1` (NOT the default `make test`) — runtime budget ~30s (20 tracks × ~1.5s per call including I/O). Default CI keeps the 5s smoke budget; the impact lane catches the real-audio regression.
   **And** the tests skip gracefully with `Issue.record` if `OA300_CORPUS_PATH` is unset OR the bundled `.mlmodelc` is missing (i.e., Branch C builds skip; Branch A builds run).
   **And** the 20-track set is defined as a static constant in the test file, drawn from the post-Story-4-6 `dsp_correct_controls` partition PLUS 16 more DSP-correct tracks from the wider OA300 corpus (NOT a re-implementation of the impact-report's full 82-track sweep — this is a fast sanity check). Document the 20-track selection rationale in the test's doc-comment.
   **And** the original "synthetic input safety net" idea is dropped — the synthetic path already works in 4-5; testing it further is not load-bearing.

10. **Branch decision and bundle-pull mechanics applied if Branch C fires (REVISED 2026-05-15 — strict 4/4 controls gate per DD #8 revised).**

    **Given** the AC #7 impact report + the AC #8 sweep + the AC #5 byte-identity preservation
    **When** Story 4-6 close-out is authored
    **Then** Completion Notes explicitly name which Branch fired (per DD #8 revised — three success paths and one failure path):
    - **Branch A (strict success)**: `named_dnb_resolved >= 2 && dsp_correct_controls_preserved == dsp_correct_controls_total` (4/4) at the chosen post-fix configuration. Bundle stays. CoreML conformance follow-on (suggested slug `4-8-coreml-mltechnique-conformance`) is unblocked. The fix (threshold change OR featurize patch) is documented in Completion Notes with the specific code diff.
    - **Branch A-conditional (3/4 controls, named slack)**: `named_dnb_resolved >= 2 && dsp_correct_controls_preserved == dsp_correct_controls_total - 1` (3/4) AT THE EXPLICIT AUTHORIZATION of the Project Lead at story-close time. Requires ALL THREE of (a) `MODEL_CARD.md` entry naming the regressed control + the impact-report row citation AND (b) the named re-open trigger from DD #15 added to Completion Notes AND (c) the verbatim authorization line in Completion Notes per DD #8 revised: `Branch A-conditional authorized YYYY-MM-DD by <name>: <one-sentence reasoning>`. Without ALL THREE, 3/4 controls is NOT Branch A-conditional — it falls to Branch C. **2/4 or fewer is ALWAYS Branch C, no slack.**
    - **Branch C (honest retreat)**: investigation exhausted; no post-fix configuration cleared the strict-or-conditional gate. Bundle is pulled per DD #7 revised file moves (including REMOVING `resources: [.copy("Resources")]` from `Package.swift`) AND DocC updates AND MODEL_CARD.md updates. The diff-scope proof (AC #11) shows `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` absent (the directory itself may be absent post-cleanup; verify `ls` output). Epic 4 close-out documents the BNNS infrastructure-only ship per DD #16 framing.

    **And** if `controls_preserved < 4/4` AND Branch A-conditional was NOT authorized OR its (a)+(b) requirements were NOT met, the dev MUST HALT per 4-6-HALT-(f) revised — silent partial fixes that trade wins for losses are NOT Branch A.
    **And** if Branch C fires AND the diff-scope shows the bundle still present OR `Package.swift` still has the `resources:` line, the dev MUST HALT per 4-6-HALT-(g) revised — incoherent close-out.
    **And** if Branch A-conditional fires, the re-open trigger from DD #15 ("If a future ablation pass shows >5% Acc1 regression on the previously-passing control set, or if any additional control regresses, Story 4-6's bundle decision re-opens") is added as a deferred-work entry AND mirrored in Completion Notes.

11. **Diff-scope proof + standard gating checklist + Completion Notes integers.**

    **Given** the Story 4-5 diff-scope proof pattern at `_bmad-output/implementation-artifacts/4-5-diff-scope-proof.txt`
    **When** Story 4-6 close-out is authored
    **Then** `_bmad-output/implementation-artifacts/4-6-diff-scope-proof.txt` is produced with the same sections: (1) `git diff --stat <Task-1-pre-source-SHA>..HEAD`; (2) trace-field audit recipes A-E (all zero matches outside the AC #2 added `mlDiagnosticSnapshot` field); (3) raw-BNNS-API guards (`grep -rn "BNNSFilterCreate\|BNNSFilterApply" Sources/BoomBoomBoomKitML/` zero); (4) external-deps invariant (`swift package show-dependencies --format json | jq '.dependencies | length'` == 0); (5) Branch-specific addendum — for Branch C, `test ! -d Sources/BoomBoomBoomKitML/Resources` exits 0 (the Resources directory itself is absent post-bundle-pull) AND the BoomBoomBoomKitML target block in `Package.swift` no longer contains `.copy("Resources")`
    **And** the standard gating checklist runs and is recorded in Completion Notes:
    - `make fmt` clean (zero diff)
    - `make lint` ≤ pre-existing baseline (Story 4-5 baseline = 1 LUFSAnalyzer.swift:94 TODO; venv-bundled Swift warnings excluded per Story 4-5 deferred-work #4 — if that exclusion lands, expect 1 violation total; if not, ~158)
    - `make test` 400 → in band `[416, 424]` per DD #12 revised, zero failures
    - `make benchmark` (OA300 default config) byte-identical to `4-6-regression-snapshot.json`, Acc1≥57/82 Acc2≥73/82
    - `make benchmark-giantsteps` byte-identical, Acc1≥537/661 Acc2≥546/661
    - `make perf-benchmark` wall-clock ≤ 1.20× pre-Story-4-6 baseline (the diagnostic path adds tuple unpacking + trace mutation per ML call; should be tens-of-µs, not multi-ms)
    - `make bnns-impact-report` produces the AC #7 schema-version-2 artifact under whichever branch fired
    - `swift test --sanitize=address --filter BNNSTechniqueTests` (Story 4-5 strict witness inheritance — still passes; the diagnostic surface adds no new allocator pressure)
    **And** Completion Notes record exact integers: pre-fix and post-fix abstain mode histograms (6 counts each), test count, OA300 Acc1/Acc2, GiantSteps Acc1/Acc2, BNNS-on Acc1 at post-fix config, named-DnB resolved count post-fix, DSP-correct controls preserved count post-fix, BNNS inference wall-clock per-track p50/p95
    **And** Completion Notes name the chosen branch (A or C) AND the rationale + evidence link

12. **File scope discipline (REVISED 2026-05-15 — new core files for capability protocol + snapshot, new tests).**

    **Given** Story 4-5 AC #10 precedent (new files only for new tests) AND the revised architecture from DD #2 + DD #3 that requires two new core source files
    **When** Story 4-6 ships
    **Then** ALL new tests go in NEW files:
    - `Tests/BoomBoomBoomKitTests/MLDiagnosticSnapshotTests.swift` (snapshot shape rules / CaseIterable witnesses for FailureStage + Gate / equatable / description)
    - `Tests/BoomBoomBoomKitTests/MLDiagnosticTechniqueTests.swift` (capability protocol conformance witness + protocol-inherits-MLTechnique compile check)
    - `Tests/BoomBoomBoomKitTests/BNNSTechniqueDiagnosticTests.swift` (parameterized via `@Test(arguments:)` covering 6 failure stages + win path + trace attachment + DSP-only short-circuit)
    - `Tests/BoomBoomBoomKitTests/BNNSTechniqueAbstainFloorTests.swift` (AC #9 revised corpus-anchored under `BNNS_IMPACT=1`)
    - `Tests/BoomBoomBoomKitTests/DnBTargetsFileLoadingTests.swift` (schema v3 + uniqueness)
    - `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceInoutTraceTests.swift` (inout mutation-after-cancellation ordering per AC #4 revised)
    Zero modifications to existing test files.
    **And** the existing test file `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift` IS modified (it's the harness that consumes the new diagnostic surface; modifying it is the work, not the scope creep) — but the modifications are surgical: ADD per-track `ml_diagnostic_snapshot` field to `TrackRow` struct, ADD `abstain_mode_histogram` section to `BNNSImpactReport` struct (derived from snapshot `failureStage` at JSON-emit time), ADD `dsp_correct_control_results` section, ADD per-control accumulator, ADD corpus-wide distribution stats per AC #7 + DD #5 revised. Pre-existing logic (DSP path, ML path, ground-truth lookup) is unchanged.
    **And** source-file scope: the following files MUST be the ONLY non-test files modified or added —
    - **NEW** `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift` (the snapshot struct + FailureStage + Gate enums — per DD #2 revised)
    - **NEW** `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift` (the capability protocol — per DD #3 revised)
    - `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (add `mlDiagnosticSnapshot` field + MARK section)
    - `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (modify `evaluateMLIfActive` signature to `inout` + capability-protocol dispatch + call-site `var` reconstruction)
    - `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` (add `MLDiagnosticTechnique` conformance extension + `evaluateInternal` private helper; refactor `evaluate(trace:)` as thin wrapper; add `internal static var thresholdOverride: Mutex<(Double, Double)?>` testing seam per Task 7.1 revised)
    - `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` (schema_version bump 2→3 + add controls)
    - `_bmad-output/planning-artifacts/epics.md` (3-sentence amendment at lines 1118-1127 per DD #17)
    - `Makefile` (potentially extends `bnns-impact-report` recipe with a `BNNS_THRESHOLD_OVERRIDE` env var that the test harness reads — dev judgment)
    - **Branch-C-only**: `git mv Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` → `_bmad-output/ml-models/`; REMOVE `resources: [.copy("Resources")]` line from `Package.swift` (per DD #7 revised); update `MODEL_CARD.md` (per DD #16 framing); update `tools/coreml-convert/README.md` Path A documentation; update `CLAUDE.md` "Ships to main" inventory.
    **And** the diff-scope proof (AC #11) verifies the source-file list AND the new files are added to the proof's allowlist (Amelia: "Don't pretend the architecture fix is zero-diff").
    **And** NO `Codable` conformance is added to `MLDiagnosticSnapshot`, `FailureStage`, or `Gate` (REVISED 2026-05-15 post-Critique-and-Refine sixth pass + Codex verification). `BPMDiagnosticTrace` itself is NOT currently `Codable` (verified at `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:15` — declared `public struct BPMDiagnosticTrace: Sendable` only); no encode/init synthesis exists to migrate. The earlier draft's "Codable synthesis check" was based on an incorrect assumption that the trace was already `Codable`. JSON emission for the impact-report harness uses a private mirror struct (`DiagnosticSnapshotJSON`) in `BNNSImpactTests.swift` per Task 6.1 — that mirror struct is `Codable` for the harness's needs; the public types are not.

---

## Tasks / Subtasks

> **NOTICE (2026-05-15):** The Tasks below were authored against the pre-review-pass type names (`MLAbstainReason`, `mlAbstainReason`, sibling-method-on-concrete-type routing). The 2026-05-15 party-mode + Codex review pass revised the architecture — see `## Review Findings v1` at the bottom of this file for the 17 patches applied. **The DDs and ACs above are the authoritative source of truth post-review.** The Tasks below remain as the implementation roadmap; the dev agent SHALL substitute the revised type names + routing throughout per this mapping:
>
> | Pre-review (in Tasks) | Post-review (per DDs/ACs) | Source |
> |---|---|---|
> | `MLAbstainReason` (public struct) | `MLDiagnosticSnapshot` (public struct) + `FailureStage` enum (6 cases incl. split `graphFailed`/`decodeRejected`) + `Gate` enum | DD #2 revised, AC #1 revised |
> | `mlAbstainReason: MLAbstainReason?` (trace field) | `mlDiagnosticSnapshot: MLDiagnosticSnapshot?` (trace field) | DD #2 revised, AC #2 revised |
> | `Mode` nested enum (5 cases) | `FailureStage` (6 cases — `inferenceFailed` split into `graphFailed` + `decodeRejected`); see DD #2 + AC #1 | Codex #2 |
> | `evaluateWithDiagnostic` returns `(MLEvaluation?, MLAbstainReason?)` | `evaluateWithDiagnostic` returns `(MLEvaluation?, MLDiagnosticSnapshot?)` and lives on the **`MLDiagnosticTechnique`** capability protocol declared in **`Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift`** (new file) | DD #3 revised, AC #3 revised |
> | `if let bnns = ml as? BNNSTechnique` (service narrowing) | `if let diag = ml as? MLDiagnosticTechnique` (service narrowing through CORE protocol) — required because BNNSTechnique lives in sibling target and cannot be named from core | DD #3 revised (Codex #1), AC #4 revised |
> | `MLAbstainReason(mode: .featuresAbsent, ...)` constructor calls in Task 4.5 | `MLDiagnosticSnapshot(...)` constructor with revised field set; `failureStage = .featuresAbsent` etc. The 6 cases include `featuresAbsent`/`featureVersionMismatch`/`featurizeRejected`/`graphFailed`/`decodeRejected`/`confidenceGateRejected` | DD #2 revised |
> | Threshold sweep ladder of 4 points | 7-point ladder (0.0/0.0, 0.10/0.02, 0.20/0.04, 0.30/0.05, 0.40/0.08, 0.50/0.10, final-chosen) + corpus-wide distribution stats per run including `wrong_non_abstain_count`, `decoded_bpm_histogram_5bpm_bins`, `softmax_max_p50/p95`, `softmax_margin_p50/p95` | DD #5 revised |
> | Single-track Yin Yang featurize differential | 12-track stratified differential (4 named + 4 controls + 4 ordinary); cheap-first via `inputFeatureChecksum` field (added to `MLDiagnosticSnapshot` per Amelia) | DD #6 revised |
> | Branch C: `git mv ... && .gitkeep` + `resources: [.copy("Resources")]` retained | Branch C: `git mv ...` + **REMOVE `resources: [.copy("Resources")]` line from `Package.swift` entirely** (no `.gitkeep` needed) | DD #7 revised (Siri) |
> | Branch A gate: contradictory (≥2/4 vs strict 4/4 vs ≥2 broken) | Branch A: strict 4/4 controls preserved. Branch A-conditional: 3/4 only with project-lead authorization + MODEL_CARD entry + re-open trigger. 2/4 or fewer: always Branch C. | DD #8 revised |
> | `internal static var thresholdOverride: (Double, Double)?` plain mutable static | `internal static let thresholdOverride = Mutex<(confidence: Double, margin: Double)?>(nil)` from `Synchronization` module (macOS 15+) | Task 7.1 revised (Siri) |
> | Task 10.1 `MLAbstainReasonTests.swift` with 10 tests | Two NEW files: `MLDiagnosticSnapshotTests.swift` (~6 tests) + `MLDiagnosticTechniqueTests.swift` (capability-protocol witness) | DD #12 revised, AC #12 revised |
> | Task 10.2 `BNNSTechniqueDiagnosticTests.swift` with 12 separate test functions | Same file but parameterized via `@Test(arguments:)` — ~3 collapsed test functions covering 6 failure stages × win/abstain paths | DD #12 revised |
> | AC #9 abstain-floor test (5 synthetic inputs in default `make test`) | AC #9 revised: `BNNSTechniqueAbstainFloorTests.swift` env-gated under `BNNS_IMPACT=1`; 20 OA300 DSP-correct tracks at thresholds 0.0/0.0; assert `abstain_rate ≤ 0.30` AND `wrong_non_abstain_count ≤ 4` | AC #9 revised |
> | Inout cancellation: "post-evaluate check matches Story 4-5 contract" | **STRICT** ordering: evaluate into locals → post-evaluate cancellation check → ONLY THEN mutate inout trace. New `AudioAnalysisServiceInoutTraceTests.swift` test locks the ordering. | AC #4 revised (Codex #4) |
> | epics.md amendment: not mentioned in Tasks | NEW: 3-sentence amendment to `_bmad-output/planning-artifacts/epics.md:1118-1127` is part of Task 1 first commit | DD #17 NEW |
> | Codable migration check: not mentioned (pre-review) → AC #12 revised "add Codable" (post-17-patch) → **DELETED entirely** (post-Critique-and-Refine W4) | NO Codable conformance is added to any public type. `BPMDiagnosticTrace` is not currently `Codable` (verified at `BPMDiagnosticTrace.swift:15` — only `Sendable`); no synthesis exists to migrate. The impact-report harness uses a private mirror struct (`DiagnosticSnapshotJSON`) in `BNNSImpactTests.swift` for JSON emission — that mirror IS `Codable`; the public types are not. | AC #12 revised + W4 |
>
> Where a Task body references a pre-review name, substitute the post-review name + adjacent semantics. Where a Task body references a pre-review file structure (e.g. "add to MLTechnique.swift"), the post-review pattern uses NEW files (`MLDiagnosticSnapshot.swift`, `MLDiagnosticTechnique.swift`) per AC #12 revised. Where a Task body conflicts with a revised AC, the AC wins.

- [ ] **Task 1: Pre-source baseline capture (commit pre-source artifacts BEFORE first source edit) (AC: #5, #6, #11) — ALSO apply epics.md amendment per DD #17 NEW + (Branch-C-prep) verify `Package.swift` `resources:` line is in scope for removal**
  - [ ] 1.1: Confirm working tree is clean and on a Story-4-6 branch (currently `rterhaar/epic-4`).
  - [ ] 1.2: Read `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` and `_bmad-output/implementation-artifacts/4-5-bnns-impact-report.json`. Identify ≥4 DSP-correct control tracks per DD #4 (155-175 BPM range, dsp_correct = true). Stage the schema-3 update (do not commit yet).
  - [ ] 1.3: Run `make benchmark` AND `make benchmark-giantsteps` against the current SHA (`1c8e274` or later). Capture per-track BPM JSON output to `_bmad-output/implementation-artifacts/4-6-regression-snapshot.json` mirroring the Story 4-5 schema. Capture both paths: `mlTechnique == nil` (default) AND `mlTechnique != nil + ensemblePolicy = .dspOnly` (short-circuit) — both MUST be byte-identical post-Story-4-6.
  - [ ] 1.4: Run `make perf-benchmark` to capture pre-source perf baseline JSON (a new entry under `_bmad-output/perf-baselines/`).
  - [ ] 1.5: Run `make bnns-impact-report` against the current SHA (the artifact at `4-5-bnns-impact-report.json` is from `0b2d8dc-dirty` per Story 4-5 close-out; this Task 1.5 re-run produces a clean baseline at the pre-source SHA so the AC #7 post-fix snapshot is a direct comparison). The artifact lands at `_bmad-output/implementation-artifacts/4-5-bnns-impact-report.json` — DO NOT rename or modify until Task 6.x produces the post-fix `4-6-bnns-impact-report.json`. Note the pre-fix histogram counts (all in mode `confidenceGateRejected` per the hypothesis, OR — if some are in other modes, that's a hypothesis-narrowing surprise to document).
  - [ ] 1.6: Commit Task 1 artifacts as a single pre-source commit: `Story 4-6 Task 1: pre-source-change baseline artifacts` (mirrors Story 4-5 Task 1 pattern).

- [ ] **Task 2: Add `MLDiagnosticSnapshot` public type in NEW `MLDiagnosticSnapshot.swift` (AC: #1, #5; DD #2 revised)**
  - [ ] 2.1: Create NEW file `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift`. Add the `MLDiagnosticSnapshot` struct + nested `FailureStage` enum (6 cases per DD #2 revised) + nested `Gate` enum (2 cases) per DD #2 verbatim shape. Per Amelia + Winston (P15): separate file from `MLTechnique.swift` so the snapshot type's diff-scope is independently auditable and `MLTechnique.swift`'s blame history stays clean.
  - [ ] 2.2: Author the multi-paragraph DocC comment block covering: (a) Story 4-6 introduction context; (b) the 6-stage `FailureStage` taxonomy + the win-path semantics (`failureStage == nil`); (c) the snapshot Population rule per DD #2 revised — including the "no snapshot for `featuresAbsent`/`featureVersionMismatch`" rule; (d) the "frozen for 1.0" framing (this type IS pre-1.0 — explicit no-BC notice); (e) cross-reference to `MLDiagnosticTechnique.evaluateWithDiagnostic(trace:)` as the producer.
  - [ ] 2.3: Implement the `init` with the precondition rules per AC #1 revised. Use `precondition(_:_:)` (not `assert`) — these are runtime safety contracts, not debug-only checks. The pre-featurize abstain paths (`featuresAbsent` / `featureVersionMismatch`) do NOT call `init` at all; they return `(nil, nil)` from the conformance per DD #3 tuple invariant.
  - [ ] 2.4: Implement `var description: String` per AC #1 (bounded length < 200 chars, includes `failureStage?.rawValue ?? "win"` + conditional decoded fields).
  - [ ] 2.5: Auto-derived conformances (`Sendable`, `Hashable`, `Equatable`) compile-time check via the Swift compiler — no explicit implementation needed for struct-of-Hashable-fields. NO `Codable` conformance per W4 + AC #12 revised — the trace is not Codable, and the impact-report harness uses a private mirror struct `DiagnosticSnapshotJSON` for JSON emission.
  - [ ] 2.6: Run the typed-evidence audit recipes A-E from `.claude/skills/bpm-diagnostic-trace/SKILL.md` (the four banned trace-field shapes). Verify ZERO matches against `Sources/` and `Tests/`.
  - [ ] 2.7 (NEW): Create NEW file `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift` containing the `MLDiagnosticTechnique: MLTechnique` capability protocol per DD #3 revised verbatim shape. Author the full doc-comment block (including the "consumer-wrapper-loses-diagnostics wontfix pre-1.0" note from P16).

- [ ] **Task 3: Add `BPMDiagnosticTrace.mlDiagnosticSnapshot` field + service-side plumbing via capability protocol (AC: #2, #4, #5; DD #3 revised)**
  - [ ] 3.1: In `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift`, add `public var mlDiagnosticSnapshot: MLDiagnosticSnapshot? = nil` under a new `// MARK: - Story 4.6: ML Diagnostic Snapshot` section, placed between the existing `// MARK: - Story 4.4: Ensemble Decision` and `// MARK: - Story 4.5: ML Feature Frames` sections (chronological discipline).
  - [ ] 3.2: Author DocC for the field per AC #2 revised: (a) Population rule (only when `MLDiagnosticTechnique` conformance + trace built + `enableTrace` true + featurize ran — see AC #2 for the full 5-condition invariant); (b) `Options.enableTrace` gating; (c) the "diagnostic, not load-bearing" framing (consumers can ignore it without losing functionality); (d) cross-reference to `MLDiagnosticSnapshot`.
  - [ ] 3.3: In `Sources/BoomBoomBoomKit/AudioAnalysisService.swift`, modify `evaluateMLIfActive` signature to take `trace: inout BPMDiagnosticTrace?` per AC #4 revised. The signature change is a breaking change to an internal helper — call site at line 328 updates with `&<local var>` (but `corroborated.trace` is `let` — see 3.4).
  - [ ] 3.4: The call site at `analyzeBPM`-line 328 currently reads:
    ```swift
    let mlEvaluation = try Self.evaluateMLIfActive(
      options: options, trace: corroborated.trace)
    ```
    `corroborated` is from `MetadataCorroborator.apply(to:input:)` which returns a `(BPMResult, [MetadataBPMEvidence])`. `BPMResult.trace` is a `let` field on a struct — to mutate it, the dev must construct a new BPMResult with the mutated trace OR use an intermediate `var` for the trace. The minimum-churn pattern: pull `corroborated.trace` into a local `var trace = corroborated.trace`; pass `&trace` to the helper; if the helper mutated trace AND corroborated.trace exists, reconstruct `corroborated = BPMResult(bpm: corroborated.bpm, confidence: corroborated.confidence, candidates: corroborated.candidates, trace: trace)` before the `EnsembleCombiner.combine` call.
  - [ ] 3.5: Inside `evaluateMLIfActive`, route via the CORE-declared `MLDiagnosticTechnique` capability protocol with STRICT mutation-after-cancellation ordering per AC #4 revised verbatim sketch (see AC #4 code block). Critical: evaluate into LOCALS first → post-evaluate cancellation check BEFORE any trace mutation → only then assign to `trace`. Trace mutation must NEVER precede the post-evaluate cancellation check, or a stranded snapshot can outlive a thrown CancellationError. `AudioAnalysisServiceInoutTraceTests.swift` (per AC #12 revised) locks this ordering with a cancellation-flips-post-evaluate fixture.
  - [ ] 3.6: Verify byte-identity at AC #5 invariant: when `mlTechnique == nil` OR `ensemblePolicy == .dspOnly`, the helper's first guard returns nil before any type-narrowing → `mlDiagnosticSnapshot` is never written → trace is unchanged from `corroborated.trace`. The `[Float]` payload (mlFeatures) on the DSP-only path is similarly untouched. Additionally: when the `MLTechnique` conformer does NOT adopt `MLDiagnosticTechnique` (e.g., a consumer-supplied wrapper around BNNSTechnique), the `as? MLDiagnosticTechnique` cast returns nil and the plain `ml.evaluate(trace:)` path runs — `mlDiagnosticSnapshot` stays nil. This is the documented `wontfix pre-1.0` consumer-wrapper limitation per P16.

- [ ] **Task 4: Add `BNNSTechnique: MLDiagnosticTechnique` conformance + `evaluateWithDiagnostic(trace:)` (AC: #3, #5; DD #3 revised)**
  - [ ] 4.1: In `Sources/BoomBoomBoomKitML/BNNSTechnique.swift`, extract the existing `evaluate(trace:)` body into a new private helper `private func evaluateInternal(trace: BPMDiagnosticTrace) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?)`. The helper performs all the same steps (mlFeatures unwrap → featurize → infer → decode → two-gate) but constructs an `MLDiagnosticSnapshot` on every path that reaches featurize. The two pre-featurize abstains (`featuresAbsent` / `featureVersionMismatch`) return `(nil, nil)` per DD #3 tuple invariant — no snapshot is constructed because there is no feature payload to checksum. All other paths return `(nil, snapshot)` on abstain or `(evaluation, snapshot)` on win.
  - [ ] 4.2: Add a trailing `extension BNNSTechnique: MLDiagnosticTechnique` with the public `evaluateWithDiagnostic(trace:)` method that returns the tuple directly (one-liner: `evaluateInternal(trace: trace)`).
  - [ ] 4.3: Rewrite the protocol-public `evaluate(trace:)` as a thin wrapper: `return evaluateInternal(trace: trace).evaluation`. This discards the snapshot — the protocol-level callers (consumer code, plain `MLTechnique` existential) don't see it. Behavior is unchanged for any caller that doesn't go through `evaluateWithDiagnostic`.
  - [ ] 4.4: Author DocC on `evaluateWithDiagnostic` per AC #3 revised: (a) Story 4-6 introduction context; (b) the two-tuple invariant (snapshot is nil ONLY for the pre-featurize abstains; non-nil otherwise; evaluation tracks the win/abstain decision orthogonally); (c) the "for diagnostic consumers; protocol path unchanged" framing; (d) cross-reference to `MLDiagnosticSnapshot` + `MLDiagnosticTechnique`.
  - [ ] 4.5: Map each existing `evaluate(trace:)` early-return to the correct return value:
    - `guard let features = trace.mlFeatures else { return nil }` → `return (nil, nil)` (pre-featurize; no snapshot).
    - `guard features.featureSetVersion == "v1" else { return nil }` → `return (nil, nil)` (pre-featurize; no snapshot).
    - `guard let inputTensor = featurize(features) else { return nil }` → `return (nil, MLDiagnosticSnapshot(failureStage: .featurizeRejected, inputFeatureChecksum: <hash of features payload>, decodedBPM: nil, softmaxMax: nil, softmaxSecondMax: nil, gateFired: nil))`.
    - `guard let decoded = inferTempoCNN(inputTensor) else { return nil }` → split into TWO paths per Codex #2: graph call failed → `.graphFailed` with decoded fields nil; graph succeeded but `decodeLogits` rejected out-of-range BPM or non-finite logits → `.decodeRejected` with `decodedBPM` populated (it's the raw out-of-range or NaN value — see DD #2 doc-comment on `decodedBPM`).
    - Gate 1 fail (`decoded.confidence < effectiveConfidenceThreshold`) → `.confidenceGateRejected` with `decodedBPM: decoded.bpm, softmaxMax: decoded.confidence, softmaxSecondMax: decoded.secondMax, gateFired: .gate1Softmax`.
    - Gate 2 fail (`margin < effectiveMarginThreshold`) → `.confidenceGateRejected` with `gateFired: .gate2Margin`.
    - Win path → `return (MLEvaluation(bpm: decoded.bpm, confidence: decoded.confidence), MLDiagnosticSnapshot(failureStage: nil, ...all decode fields populated...))`.
  - [ ] 4.6: The `logNilFeaturesOnce()` defensive log from Story 4-5 continues to fire on the `featuresAbsent` path (HALT (g) inheritance) — keep the existing call before the early return.
  - [ ] 4.7 (NEW): Compute `inputFeatureChecksum: UInt64` via FNV-1a or xxHash over the byte representation of the resampled `[Float]` of length 65536 (per DD #2). Cost: ~50µs per evaluate. Hash is deterministic given the same audio. Used by DD #6 cheap-first featurize differential.

- [ ] **Task 5: Expand `4-dnb-triplet-targets.json` to schema_version 3 (AC: #6, #11)**
  - [ ] 5.1: Re-read `_bmad-output/implementation-artifacts/4-5-bnns-impact-report.json`. Filter for tracks where `dsp_correct == true` AND `ground_truth >= 155 AND ground_truth <= 175` AND `named_dnb_track == false`. Pick ≥4 entries per DD #4 — the suggested 4 (Hellacopta, D3Z_Axons, Darkgray Heart, HEFT_Fuyu) are the same-compilation-family controls; dev may substitute with rationale.
  - [ ] 5.2: Update `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` to schema_version 3 with the added `dsp_correct_controls` array. The existing `targets` array (4 named-failure entries) is unchanged; `captured_with` and `regression_threshold` blocks are unchanged. Each control entry has the AC #6 fields including the `rationale` string.
  - [ ] 5.3: In `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift`, update the loader's schema_version expectation from 2 to 3. Extend the `DnBTargetsFile` struct with `dsp_correct_controls: [DnBControl]`. Add a `DnBControl` struct mirroring `DnBTarget` shape but with a `rationale: String` field added. Extend the duplicate-id check to include controls.
  - [ ] 5.4: Add a per-track ground-truth lookup analogue for controls (parallel to the existing `dnbTarget(for:)` method). Name: `dnbControl(for:)`. Returns the control entry if the filename matches a control's `track_id`, else nil.
  - [ ] 5.5: Add a unit test `Tests/BoomBoomBoomKitTests/DnBTargetsFileLoadingTests.swift::loadsSchemaVersion3` — round-trip the JSON, assert schema_version is 3, assert `targets.count == 4`, assert `dsp_correct_controls.count >= 4`, assert no duplicate `track_id` across both arrays.

- [ ] **Task 6: Extend `BNNSImpactTests` to emit `4-6-bnns-impact-report.json` with diagnostic histogram + control results (AC: #7, #11)**
  - [ ] 6.1: In `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift`, extend the `TrackRow` struct with `ml_diagnostic_snapshot: DiagnosticSnapshotJSON?` field. `DiagnosticSnapshotJSON` is a private Codable struct mirroring the `MLDiagnosticSnapshot` shape: `failure_stage: String?, decoded_bpm: Double?, softmax_max: Double?, softmax_second_max: Double?, input_feature_checksum: UInt64?, gate_fired: String?`. Conversion helper between `MLDiagnosticSnapshot` and `DiagnosticSnapshotJSON` lives in the same file. The `DiagnosticSnapshotJSON` mirror is the ONLY Codable surface — `MLDiagnosticSnapshot` itself is NOT Codable per AC #12 revised + W4.
  - [ ] 6.2: Extend the `BNNSImpactReport` struct with `failure_stage_histogram: [String: Int]` field (7 keys per AC #7 revised: 6 failure stages + `noAbstain` for the win path).
  - [ ] 6.3: Extend `BNNSImpactReport` with `dsp_correct_control_results: [DnBControlResult]` field. `DnBControlResult` struct shape per AC #7.
  - [ ] 6.4: Modify the per-track loop to read `bnnsResult?.trace?.mlDiagnosticSnapshot` and convert to `DiagnosticSnapshotJSON`. The conversion is straightforward field-by-field — note that for the two pre-featurize abstain paths (`featuresAbsent` / `featureVersionMismatch`), `mlDiagnosticSnapshot` is nil on the trace per DD #2 revised; the harness derives the histogram bucket for those tracks from `MLEvaluation == nil && mlDiagnosticSnapshot == nil`. The conversion + nil rule is wrapped in a private helper to avoid scattering the logic across the loop.
  - [ ] 6.5: Modify the per-track loop to accumulate the histogram. Every track contributes exactly one count to exactly one bucket: 6 failure stages + `noAbstain` (for the win path). Assert `histogram.values.sum == allRows.count` before writing the report. Bucket-assignment rule: snapshot non-nil → use `failureStage?.rawValue` (or "noAbstain" if failureStage is nil); snapshot nil AND evaluation nil → infer from trace state (`mlFeatures == nil` → featuresAbsent; `featureSetVersion != "v1"` → featureVersionMismatch).
  - [ ] 6.6: Modify the per-track loop to also accumulate `dsp_correct_control_results`: for each track in `dnbControl(for:)`, compute `preserved_within_05 = abs(ensembleBPM - gt) < 0.5` (parallel to named-failure `resolved_within_05`). Note: the metric for controls is PRESERVATION (DSP was right; did ML break it?), NOT RESOLUTION (DSP was wrong; did ML fix it?). The HALT discipline differs: for controls, `preserved_within_05 == false` is the regression signal.
  - [ ] 6.7: Update the output filename: the report writes to `4-6-bnns-impact-report.json` (NOT overwriting Story 4-5's artifact). The schema_version bumps from 1 to 2 to reflect the new fields. Filename change requires either a parameterized output path OR a new Makefile target `bnns-impact-report-v2` (dev judgment — the minimum-churn approach is to make the test write `4-6-bnns-impact-report.json` and leave the old `bnns-impact-report` Makefile target as-is, since the harness file is being modified anyway).
  - [ ] 6.8: Update the named-DnB resolution assertion: continue to fire `Issue.record` for `named_dnb_resolved < 2` (Story 4-5 HALT (b) inheritance), but ALSO add the symmetric control-preservation gate: `Issue.record` for `dsp_correct_controls_preserved < dsp_correct_controls.count`. The dev MUST NOT silently ratchet either gate.

- [ ] **Task 7: Threshold-disabled smoke + investigation deliverable (AC: #8; DD #5, #6)**
  - [ ] 7.1: Add an INTERNAL-ACCESS threshold-override seam for the develop-only investigation, **`Mutex<(Double, Double)?>` wrapped** per Siri's Apple-platform audit (REVISED 2026-05-15). The original recommendation was `internal static var thresholdOverride: (confidence: Double, margin: Double)?` — a plain mutable static. Siri flagged this as a foot-gun under parallel test execution (Swift Testing runs tests concurrently by default; Story 4-5's `concurrentEvaluateIsContextLocal` test already runs 16 concurrent evaluations). The Mutex-wrapped variant is the cleanest macOS-15+ option:
    ```swift
    import Synchronization

    extension BNNSTechnique {
        /// Story 4-6 threshold-sweep testing seam. INTERNAL access only —
        /// settable via `@testable import BoomBoomBoomKitML` from the
        /// impact-report harness; consumer-facing public API is unchanged.
        /// Mutex-wrapped per Siri's Apple-platform audit: parallel-test
        /// safety, no `nonisolated(unsafe)` permanent escape hatch.
        ///
        /// Production behavior: `confidenceThreshold` / `marginConfidenceThreshold`
        /// constants remain the source of truth; this override only fires
        /// when set by a test harness.
        internal static let thresholdOverride = Mutex<(confidence: Double, margin: Double)?>(nil)

        private static var effectiveConfidenceThreshold: Double {
            thresholdOverride.withLock { $0?.confidence ?? confidenceThreshold }
        }

        private static var effectiveMarginThreshold: Double {
            thresholdOverride.withLock { $0?.margin ?? marginConfidenceThreshold }
        }
    }
    ```
    Test usage in `BNNSImpactTests.swift`:
    ```swift
    BNNSTechnique.thresholdOverride.withLock { $0 = (0.0, 0.0) }
    defer { BNNSTechnique.thresholdOverride.withLock { $0 = nil } }   // reset after sweep
    // ... run impact report at threshold 0.0/0.0 ...
    ```
    Alternatives rejected:
    - `nonisolated(unsafe) static var` — REJECTED. Permanent escape hatch; axiom-swift `swift-modern.md` says each `nonisolated(unsafe)` should have a removal ticket. The Mutex<T> alternative is equally simple and safer.
    - Parameterized `init(modelURL:, confidenceThreshold:, marginThreshold:)` overload — REJECTED. Adds permanent public API for a one-time investigation knob; pre-1.0 framing notwithstanding, every new public API has carrying cost.
    - Env-vars read at init time — REJECTED. Couples production code to harness env vars; harder to test deterministically across parallel test runs.

    Story 4-6 close-out: if Branch A fires AND the chosen thresholds differ from the defaults, the production constants `confidenceThreshold` / `marginConfidenceThreshold` are UPDATED to the chosen values; the `thresholdOverride` Mutex seam REMAINS as testing infrastructure. If Branch C fires, the constants are unchanged and the seam remains for future investigation work.
  - [ ] 7.2: Run 7 sweeps via `make bnns-impact-report` with thresholds per DD #5 revised:
    - `0.00/0.00` — both gates disabled. The "is the model itself capable?" measurement. **The headline column `wrong_non_abstain_count` is read off THIS run** — if high, Outcome B/C; if low + `decoded_bpm_matches_dsp_within_4pct_fraction` high, Outcome A is the leading hypothesis.
    - `0.10/0.02` — first relaxation.
    - `0.20/0.04` — second step.
    - `0.30/0.05` — middle ground.
    - `0.40/0.08` — fourth step.
    - `0.50/0.10` — Story-4-5-shipped baseline (the comparison anchor).
    - Final-chosen-production-thresholds — empirical optimum read off the curve (could match `0.50/0.10` if Outcome B/C/D fires; or a lowered pair if Outcome A fires).
    Each run produces a separate `4-6-bnns-impact-report-sweep-N.json` artifact (suffix-based; the dev MAY also append entries to a single `4-6-threshold-sweep.json` aggregate).
  - [ ] 7.3: Aggregate the sweep results into `_bmad-output/implementation-artifacts/4-6-threshold-sweep.json` per AC #8 revised verbatim shape (7 runs × failure-stage histogram + named + controls + corpus-wide distribution stats per run).
  - [ ] 7.4: Determine DD #5 outcome (A/B/C/D). Document in Completion Notes.
  - [ ] 7.5: If DD #5 Outcome A fires (threshold fix sufficient): pick the optimum threshold pair, update the constants in `BNNSTechnique.swift` (`confidenceThreshold` and `marginConfidenceThreshold` private static lets), proceed to Task 6.x final impact report. Document the constant values + rationale in Completion Notes.
  - [ ] 7.6: If DD #5 Outcome B or C fires (threshold zero, still abstaining or wrong): proceed to Task 8 (featurize differential).
  - [ ] 7.7: If DD #5 Outcome D fires (model genuinely weak): proceed to Task 9 (Branch C).

- [ ] **Task 8 (CONDITIONAL): Swift-vs-Python featurization differential (AC: #8; DD #6)**

  Skip this task if DD #5 Outcome A fires (Task 7.5 close-out). Run if Outcome B or C fires.

  - [ ] 8.1: Add a develop-only CLI target `_bmad-output/ml-training/swift_feature_extractor/Sources/dump-track/main.swift` (sibling to existing `dump-fixture` and `bnns-probe`). Update `Package.swift` in that directory to expose the new target. The CLI: takes `--track-path <wav>` + `--out <npz>`; loads the audio via PCMBufferReader; runs `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` with `captureMLFeatures: true`; writes the resulting `MLFeatureFrames.logMelData` as a 128 × N row-major `.npy` (or `.npz` if extending to multiple fields).
  - [ ] 8.2: Run the cheap-first pass per DD #6 revised: emit `inputFeatureChecksum` for all 12 stratified tracks (4 named + 4 controls + 4 ordinary) from BOTH the Swift impact-report harness AND the Python reference pipeline. If all 12 checksums match, featurize is bit-exact → skip the expensive `.npz` round-trip (write `4-6-featurize-differential.json` with `"divergence": "none", "method": "checksum"`). If ANY diverge, proceed to 8.3 for the diverging tracks only.
  - [ ] 8.3: Run the Python tempo-cnn reference featurization on the SAME audio file. Use the existing `_bmad-output/ml-training/` pipeline — `uv run python -m boomboomboomkit_ml.featurize --track <wav> --out <npz>` (exact command TBD per the actual scripts in that directory; dev verifies and documents).
  - [ ] 8.4: Compare the two `.npz` arrays: max abs diff, RMS diff, per-row correlation. Document results in `_bmad-output/implementation-artifacts/4-6-featurize-differential.json` per AC #8.
  - [ ] 8.5: If the two arrays diverge: identify the divergent stage (transpose direction, z-score axis, resample direction). Fix the Swift featurize. Re-run `make ml-parity` to confirm the existing 4-stage parity harness still passes. Re-run Task 7 sweep at the production thresholds to verify recovery.
  - [ ] 8.6: If the two arrays match: featurize is correct. Run Python tempo-cnn inference on the same features. If Python is also wrong, the model is the limit (Outcome D, go to Task 9). If Python is correct but Swift BNNS is wrong, escalate to BNNS-inference-path investigation (graph compile or argument binding; not anticipated given Task 1.5d evidence, but document the surprise).

- [ ] **Task 9 (BRANCH-C-ONLY): Bundle pull + DocC updates + MODEL_CARD.md update (AC: #10; DD #7)**

  Skip this task entirely if Branch A fires (Task 7.5 outcome OR Task 8.5 fix recovers accuracy). Run if Branch C fires.

  - [ ] 9.1: `git mv Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/ _bmad-output/ml-models/giantsteps_v1.mlmodelc/`. Then `rmdir Sources/BoomBoomBoomKitML/Resources/` (the directory is now empty and per DD #7 revised + Siri's P8 it must NOT survive — the `resources:` declaration in Package.swift is removed in step 9.2 below, so the directory itself should be absent for the spec to be coherent).
  - [ ] 9.2 (REVISED post-Critique-and-Refine — no `.gitkeep`): In `Package.swift`, REMOVE the `resources: [.copy("Resources")]` line from the `BoomBoomBoomKitML` target declaration entirely per DD #7 revised. Do NOT create `.gitkeep`; the directory must be absent. Verify with `test ! -d Sources/BoomBoomBoomKitML/Resources` (exits 0). Verify with `grep -nE '\.copy\("Resources"\)' Package.swift` returns zero matches under the BoomBoomBoomKitML target (note: other targets in Package.swift may legitimately retain `.copy("Resources")` for their own resources — the grep is scoped to the BoomBoomBoomKitML target block).
  - [ ] 9.3: Update `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` DocC: rewrite the type-level doc-comment lines 27-83 to reflect the absent bundle. Specifically: remove "The library ships a bundled reference model at `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/`, trained by Story 4-4b against the GiantSteps tempo corpus" framing. Replace with "No bundled model ships in this version. Consumers must provide a `.mlmodelc` via `init(modelURL:)`. See `tools/coreml-convert/README.md` for the conversion workflow and `MODEL_CARD.md` for historical context." Update the `bundledReferenceURL` constant's doc-comment to "Always `nil` in the current ship — the previous bundle (Story 4-5 ship) was removed in Story 4-6. Reserved for a future story that re-bundles a higher-quality model."
  - [ ] 9.4: Update `MODEL_CARD.md`: add a "## Status (as of Story 4-6, YYYY-MM-DD)" section at the top documenting: (a) no bundled model ships; (b) the previous `giantsteps_v1.mlmodelc` was pulled because of 100% abstain on the OA300 test corpus; (c) reproduction recipe via `_bmad-output/ml-training/` is unchanged; (d) the BNNSTechnique infrastructure (load, featurize, inference, two-gate) is unchanged and ready to consume a higher-quality model when one is trained. The pre-Story-4-6 model-card content is preserved below the new status section for historical accuracy.
  - [ ] 9.5: Update `tools/coreml-convert/README.md`: update Path A documentation from "Use library's bundled reference model — `Options.mlTechnique = try? BNNSTechnique()`" to a strikethrough or deprecation note: "~~Path A: bundled reference model~~ (removed in Story 4-6 — see MODEL_CARD.md). Use Path B (your converted weights) or Path C (custom conformance)." Update the workflow diagram if Path A is illustrated.
  - [ ] 9.6: Update `CLAUDE.md`'s "Ships to `main`" table — remove `giantsteps_v1.mlmodelc` from the `Sources/BoomBoomBoomKitML/Resources/` directory inventory. The other entries (Package.swift, Sources/, Tests/, etc.) are unchanged.
  - [ ] 9.7: Verify no test references the bundled `.mlmodelc` path directly. The existing tests use `try? BNNSTechnique()` which gracefully degrades to `Issue.record` skip when missing — that's the documented Branch C behavior.
  - [ ] 9.8 (NEW): Run `test ! -d Sources/BoomBoomBoomKitML/Resources && echo "directory absent"` (must print `directory absent`). Run `grep -nE '\.copy\("Resources"\)' Package.swift` scoped to the BoomBoomBoomKitML target block — must return zero matches in that block (other target blocks may legitimately retain `.copy("Resources")` for their own resources).

- [ ] **Task 10: Unit tests in NEW files only (AC: #1, #2, #3, #5, #9, #12; DD #2, #12)**
  - [ ] 10.1-10.3 (SUPERSEDED 2026-05-15 by Critique-and-Refine W6 + 17-patch review): See DD #12 revised + AC #12 revised for the authoritative test inventory. The pre-review test list enumerated here referenced the dropped `MLAbstainReason` type + pre-revision field names + the synthetic-only abstain-floor test that AC #9 revised replaced with real-audio under `BNNS_IMPACT=1`. The post-review file set is:
    - `MLDiagnosticSnapshotTests.swift` (~6 tests — shape rules / CaseIterable / equatable / description)
    - `MLDiagnosticTechniqueTests.swift` (+2 — capability protocol witness + protocol-inherits-MLTechnique compile check)
    - `BNNSTechniqueDiagnosticTests.swift` (~3 parameterized via `@Test(arguments:)` — 6 failure stages + win + trace-attachment + DSP-only short-circuit)
    - `BNNSTechniqueAbstainFloorTests.swift` (+2 under `BNNS_IMPACT=1` — `abstainFloorOnRealAudio_DspCorrectControls` + `wrongNonAbstainCeiling_DspCorrectControls` per AC #9 revised)
    - `DnBTargetsFileLoadingTests.swift` (+1 — schema_version 3 + uniqueness; see Task 5.5)
    - `AudioAnalysisServiceInoutTraceTests.swift` (+2 — inout mutation-after-cancellation ordering per AC #4 revised)

    Total: 16 new tests. Target = 400 + 16 = 416. Band `[416, 424]` per DD #12 revised.
  - [ ] 10.4: Create `Tests/BoomBoomBoomKitTests/DnBTargetsFileLoadingTests.swift` per Task 5.5: `loadsSchemaVersion3` test asserting schema_version 3 + 4 named + ≥4 controls + no duplicate ids.
  - [ ] 10.5: Run `make test`. Capture exact `@Test(` count via `rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l` (must be in band `[416, 424]` per DD #12 revised).
  - [ ] 10.6: NO MODIFICATIONS to existing test files. Per AC #12 — except `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift` which IS the harness being modified (the changes are surgical extensions, not new tests).

- [ ] **Task 11: Capture diff-scope proof artifact (AC: #11, #12)**
  - [ ] 11.1: Run `git diff --stat <Task-1-pre-source-SHA>..HEAD` and capture stdout to `_bmad-output/implementation-artifacts/4-6-diff-scope-proof.txt`.
  - [ ] 11.2: Append `git status -- Sources/` output. Verify NO file outside the AC #12 revised list is modified (the list: NEW `MLDiagnosticSnapshot.swift`, NEW `MLDiagnosticTechnique.swift`, BPMDiagnosticTrace.swift, AudioAnalysisService.swift, BNNSTechnique.swift, the JSON fixture; Branch-C-only additionally: `Package.swift` (resources line removal), Resources/ directory removal, MODEL_CARD.md, tools/coreml-convert/README.md, CLAUDE.md).
  - [ ] 11.3: Append `grep -rn "BNNSFilterCreate\|BNNSFilterApply" Sources/BoomBoomBoomKitML/` output (must be zero matches per inherited Story 4-5 invariant).
  - [ ] 11.4: Append the trace-field audit output (recipes A-E from `.claude/skills/bpm-diagnostic-trace/SKILL.md`) — must be zero matches OUTSIDE the new `mlDiagnosticSnapshot` field declaration.
  - [ ] 11.5: Append `swift package show-dependencies --format json | jq '.dependencies | length'` — must be `0` (zero-external-deps invariant preserved).
  - [ ] 11.6: Branch-C-only: append `test ! -d Sources/BoomBoomBoomKitML/Resources && echo "directory absent"` (must print `directory absent`) AND `grep -nE '\.copy\("Resources"\)' Package.swift` scoped to the BoomBoomBoomKitML target block (must return zero matches in that block).

- [ ] **Task 12: Standard gating checklist + Completion Notes (AC: #5, #7, #11)**
  - [ ] 12.1: Run `make fmt`. Verify zero diff.
  - [ ] 12.2: Run `make lint`. Verify no new violations beyond pre-existing baseline (Story 4-5 close-out baseline: 1 LUFSAnalyzer.swift:94 TODO; venv-bundled Swift warnings noted as pre-existing).
  - [ ] 12.3: Run `make test`. Capture exact `@Test(` count + zero failures.
  - [ ] 12.4: Run `make benchmark`. Verify byte-identity vs `4-6-regression-snapshot.json` for `mlTechnique == nil` path. Capture Acc1=N/82, Acc2=N/82.
  - [ ] 12.5: Run `make benchmark-giantsteps`. Same byte-identity check. Capture Acc1=N/661, Acc2=N/661.
  - [ ] 12.6: Run `make perf-benchmark`. Verify mock-on-abstain ratio remains ≤ 1.20×.
  - [ ] 12.7: Run `make bnns-impact-report` (Branch A — requires the real model artifact; Branch C — produces the diagnostic histogram against the absent bundle, which gracefully degrades via `try? BNNSTechnique()` skip). Verify the AC #7 schema-version-2 artifact is produced AND lands at `_bmad-output/implementation-artifacts/4-6-bnns-impact-report.json`.
  - [ ] 12.8: `swift build --target BoomBoomBoomKit` + `BoomBoomBoomKitTestSupport` + `BoomBoomBoomKitML` — all succeed; verify zero new SPM deps.
  - [ ] 12.9: Update Completion Notes with: branch identifier (A or C); exact integers per AC #11 (pre-fix and post-fix histograms, test count, OA300 Acc1/Acc2, GiantSteps Acc1/Acc2, BNNS-on Acc1 at post-fix config, named-DnB resolved count post-fix, controls preserved count, BNNS inference p50/p95); fix description (threshold values + rationale, OR featurize diff, OR Branch C bundle-pull file moves); deferred-work entries created OR resolved (Story 4-5's deferred items #2 + #3 should be RESOLVED here regardless of branch — confidence-threshold sweep IS the threshold sweep this story ran; ML-abstain investigation IS this story).
  - [ ] 12.10: Commit the source changes + tests + artifacts as a single commit: `Story 4-6: BNNS ML accuracy investigation and bundle decision` (mirrors prior story commit pattern; no business jargon).
  - [ ] 12.11: Move the story to `review` status. Run `/bmad-code-review _bmad-output/implementation-artifacts/4-6-ml-accuracy-investigation-and-bundle-decision.md` per the project workflow.
  - [ ] 12.12: At close-out: announce which Branch (A or C) fired AND, if Branch A, suggest the follow-on story slug (`4-8-coreml-mltechnique-conformance`) and confirm whether `epic-4-retrospective` should be promoted from `optional` to active in `sprint-status.yaml`.

---

## Dev Notes

### Architecture compliance

- **ADR-4 (Eager model loading at conformance init)** — `architecture.md:222-227`. Story 4-6 does NOT change ADR-4. `BNNSTechnique()` continues to load eagerly; the bundle-pull branch makes the bundled URL nil so the throw fires deterministically.
- **ADR-5 (Configurable ML ensemble voting policy)** — `architecture.md:229-232`. Story 4-6 does NOT change ADR-5. The impact-report continues to use `.mlOnly` to isolate ML signal.
- **ADR-6 (Always populate trace when ML technique is present) — inherited from Story 4-4 and 4-5.** Story 4-6 EXTENDS the trace surface with `mlDiagnosticSnapshot` but the gating logic is identical: trace built when `mlTechnique != nil` AND `ensemblePolicy != .dspOnly` AND `enableTrace` (the consumer-facing gate). The internal `captureMLFeatures` flag still governs the upstream feature retention (Story 4-5's contract); Story 4-6 adds NO new internal flags.
- **ADR-11 (Options-first public configuration)** — `architecture.md:247-256`. Story 4-6 does NOT add new public Options fields. The threshold-sweep mechanism (Task 7.1) uses an init parameter on `BNNSTechnique` (or an env-var), NOT a new `Options` field — investigation tooling is not a consumer-facing knob in the production sense; the dev's choice between options (a)/(b)/(c) for Task 7.1 controls whether the override surfaces in production at all.
- **Post-Pipeline Corroboration Boundary** — project-context.md §"Post-Pipeline Corroboration Boundary". Pipeline ordering is unchanged from Story 4-5: `merge → MetadataCorroborator.apply → MLTechnique.evaluate → EnsembleCombiner.combine → AudioAnalysisResult`. Story 4-6's trace mutation happens at the same call site as Story 4-5's evaluate — between `MetadataCorroborator.apply` and `EnsembleCombiner.combine` — so the boundary is preserved.
- **Banned trace-field shapes** — project-context.md §"Banned trace-field shapes". The new `MLDiagnosticSnapshot` struct passes the typed-evidence rule (named `Sendable` value type, no `[String: Any]`, no stringified-numeric values, no boolean-pair flags). The four banned shapes audit (recipes A-E) MUST return zero matches before merge.

### Source pointers (verified at story authoring 2026-05-14, HEAD `1c8e274`)

- `Sources/BoomBoomBoomKit/MLTechnique.swift:34-66` — `MLEvaluation` struct.
- `Sources/BoomBoomBoomKit/MLTechnique.swift:98-126` — `MLTechnique` protocol (frozen per Story 4-5 DD #18).
- `Sources/BoomBoomBoomKit/MLTechnique.swift:140-182` — `MLTechniqueError` enum.
- `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift` (NEW FILE) — `MLDiagnosticSnapshot` struct + nested `FailureStage` (6 cases) + nested `Gate` (2 cases) per DD #2 revised land here.
- `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift` (NEW FILE) — `MLDiagnosticTechnique: MLTechnique` capability protocol per DD #3 revised lands here.
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:147-148` — `ensembleDecision` field (Story 4-4).
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:174` — `mlFeatures` field (Story 4-5).
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (NEW INSERT POINT — between line 148 and line 174, under a new `// MARK: - Story 4.6: ML Diagnostic Snapshot` header) — `mlDiagnosticSnapshot` lands here.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:299-306` — `shouldBuildTrace` predicate (Story 4-4 DD #2).
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:328-329` — `evaluateMLIfActive` call site.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:416-427` — `evaluateMLIfActive` body (Story 4-5 cancellation helper).
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:84-205` — public struct + init (Story 4-5 Shape A-prime).
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:209-234` — `evaluate(trace:)` body (Story 4-5; to be refactored as thin wrapper in Task 4.3).
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:743-781` — `BNNSGraphHandle` RAII storage (Story 4-5 DD #15).
- `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:84-401` — existing harness (to be extended in Task 6).
- `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` — schema v2 (to be bumped to v3 in Task 5).

### Why `MLDiagnosticSnapshot` and `MLDiagnosticTechnique` live in separate files (REVISED 2026-05-15 post-review)

Pre-review draft co-located the diagnostic type with `MLTechnique.swift` on the rationale that diagnostic types should sit next to the protocol they support. The 17-patch review pass (Amelia + Winston, P15) rejected this:

- **Diff-scope honesty.** Adding ~150 lines of diagnostic infrastructure to `MLTechnique.swift` (the Story 4-5 frozen protocol home) muddles AC #12's "what changed" audit. Separate files keep the protocol's blame history clean and let reviewers see exactly what Story 4-6 added without scrolling past unrelated Story 4-5 declarations.
- **Independent auditability.** The capability protocol `MLDiagnosticTechnique` is the architectural fix for Codex finding #1 (package graph one-way). Putting it in its own file makes the new cross-target narrowing seam visually distinct from the frozen `MLTechnique` it inherits from — future readers see two protocols, not one file with a hidden second protocol.
- **Same-module imports inside `Sources/`.** Pre-review draft worried that a separate file referencing `BPMDiagnosticTrace` would need a same-module import. It does not — types in the same Swift module share a namespace; no import is needed.

So the post-review pattern: `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift` holds the snapshot struct + `FailureStage` + `Gate`; `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift` holds the capability protocol; `Sources/BoomBoomBoomKit/MLTechnique.swift` is untouched (Story 4-5 freeze preserved).

### Why a new trace field, not an extension of `MLEvaluation` or `EnsembleDecision`

Three alternatives were considered:

- **Extend `MLEvaluation` with abstain semantics** (e.g., `MLEvaluation(bpm:confidence:abstainReason:)` with one of bpm/abstainReason non-nil). REJECTED — breaks the "nil means abstain" contract on the protocol return. Every consumer would have to learn the new semantics. Story 4-5 DD #18 explicitly froze the protocol return.
- **Extend `EnsembleDecision` with an `mlDiagnosticSnapshot` field**. REJECTED — `EnsembleDecision` is populated by `EnsembleCombiner.combine`, which runs AFTER `MLTechnique.evaluate(trace:)` and only when ML returned non-nil. Putting the diagnostic snapshot on a struct that is itself nil-on-abstain creates a paradox.
- **NEW typed-evidence struct on the trace.** ACCEPTED. The diagnostic snapshot is independent of both the protocol return (which is nil-or-MLEvaluation) and the ensemble decision (which is nil-or-EnsembleDecision-on-win-path). Adding `mlDiagnosticSnapshot: MLDiagnosticSnapshot?` alongside `ensembleDecision: EnsembleDecision?` is the cleanest factoring — both are optional diagnostic surfaces on the trace, gated by `enableTrace`, with non-overlapping population rules.

### Risk / out-of-scope guards

- **Do NOT touch CoreMLTechnique.swift.** Per DD #10, CoreML conformance is out of scope. The placeholder at `Sources/BoomBoomBoomKitML/CoreMLTechnique.swift:26-28` (`public struct CoreMLTechnique: Sendable { public init() {} }`) stays unchanged. If a future story implements CoreML conformance, it can adopt the same `evaluateWithDiagnostic` pattern via type-narrowing in `evaluateMLIfActive` (a second `if let coreml = ml as? CoreMLTechnique` branch).
- **Do NOT modify `MLTechnique` protocol.** Per Story 4-5 DD #18 + Story 4-6 DD #3. The diagnostic surface is `BNNSTechnique`-specific. Future stories may promote it to protocol if a second conformer needs it.
- **Do NOT change `MLEvaluation` shape.** Per Story 4-5 DD #18.
- **Do NOT change `MLFeatureFrames` shape.** Adding the abstain-reason diagnostic does NOT require any changes to the feature-frames typed-evidence struct.
- **Do NOT touch `EnsembleCombiner.swift`.** The combiner consumes `(dspWinner, mlEvaluation, policy)` and produces a `BPMResult` — it has no business knowing about diagnostic snapshots (those are upstream of the combine step). The diagnostic snapshot is written to the trace BEFORE the combiner runs; the combiner just propagates the trace forward.
- **Do NOT touch `EnsemblePolicy.swift` or `EnsembleDecision.swift`.** Same reasoning.
- **Do NOT introduce sidecar JSON model metadata** (Story 4-5 DD #10 deferred-work item). Threshold values stay as private static constants in `BNNSTechnique`. The `init(modelURL:confidenceThreshold:marginThreshold:)` overload from Task 7.1 (recommended option (c)) is a public-API extension; the constants remain the defaults. No metadata JSON load path is added in this story.
- **Do NOT rename or restructure the impact-report Makefile target.** `make bnns-impact-report` continues to work. The output filename changes from `4-5-bnns-impact-report.json` to `4-6-bnns-impact-report.json` via the harness change; the Makefile target name is unchanged. If the dev judges that a separate `4-6-bnns-impact-report` Makefile target is cleaner for future-proofing, that's acceptable but not required.

### Apple-platform notes

- **macOS 15 floor unchanged.** Story 4-5 set the `@available(macOS 15.0, *)` defense-in-depth on `BNNSTechnique`. Story 4-6 does NOT touch the availability annotations.
- **No new framework dependencies.** `MLDiagnosticSnapshot` is a pure value type using only Foundation primitives. `evaluateWithDiagnostic` uses the same `Accelerate` (BNNS) + `Foundation` imports as `evaluate(trace:)`. Task 7.1's threshold-override seam adds an `import Synchronization` to `BNNSTechnique.swift` (macOS 15+ Mutex<T>) — this is a system framework, not an external dep. The zero-external-deps invariant is preserved.
- **`os_log` use unchanged.** Story 4-5's HALT (g) defensive log for `featuresAbsent` continues to fire via `BNNSTechnique.logNilFeaturesOnce()`. Story 4-6 does NOT add new `os_log` calls; the diagnostic snapshot is the diagnostic surface (consumer-readable via trace) and `os_log` would duplicate it.

### Previous Story Intelligence

**Story 4-5 dev-agent deferred-work entries (recorded at close-out in commits, not yet in `deferred-work.md`):**

- **#1 Strict DD #15 deinit witness** — kept as deferred (not blocking 4-6 scope).
- **#2 Confidence-threshold sweep on a higher-quality bundled model** — RESOLVED by Story 4-6 Task 7. The sweep happens against the existing bundled model; "higher-quality model" framing is deferred to a future story IFF Branch C fires and a retrain effort is greenlit.
- **#3 Investigate ML abstain rate on real audio (Branch A path)** — RESOLVED by Story 4-6 Tasks 7 + 8. THIS IS THE STORY.
- **#4 `tools/coreml-convert/.venv/` lint exclusion** — kept as deferred (Story 4-4b cleanup, not in 4-6 scope).

**Story 4-5 review-pass v3 deferred-work entries (`deferred-work.md:401-467`):**

- **C1 — 100% abstain hides 6 failure stages; need diagnostic instrumentation.** RESOLVED by Story 4-6 Tasks 2 + 4 (6-stage `FailureStage` enum post-Codex-#2 split of `inferenceFailed` into `graphFailed` + `decodeRejected`). Blocks 4-6 → THIS STORY.
- **C2 — Bundle-pull decision deferred to Story 4-6.** RESOLVED by Story 4-6 Tasks 7 + 9. Blocks 4-6 → THIS STORY.
- **C3 — `4-5-regression-snapshot.json` naming muddy.** NOT addressed by 4-6 (informational; real byte-identity gate is `4-3-baseline-bpms.json` per Story 4-5). Continues as deferred-work.
- **C4 — Impact-report HALT gate is develop-only, not in CI.** RESOLVED by Story 4-6 Task 10.3 (AC #9 — fast-running `BNNSTechniqueAbstainFloorTests` in default `make test` lane).
- **C5 — DnB target list lacks DSP-correct control set.** RESOLVED by Story 4-6 Task 5 (schema_version 3 + `dsp_correct_controls` partition).

**Pattern inheritance from Story 4-5:**

- Story 4-5's typed-evidence struct pattern (`MLFeatureFrames` — `Sendable`, `Hashable`, `CustomStringConvertible`, `Equatable` with semantic metadata fields and bounded `description`). Story 4-6's `MLDiagnosticSnapshot` follows the same shape (6 fields: `decodedBPM`, `softmaxMax`, `softmaxSecondMax`, `inputFeatureChecksum`, `failureStage`, `gateFired` + bounded description).
- Story 4-5's "frozen pre-source baseline" discipline for the named-track baseline (DD #1). Story 4-6 extends this to the controls — the `current_predicted_bpm` values are populated by reading the Story 4-5 impact report at Task 1 and frozen, NOT re-measured.
- Story 4-5's "diff-scope proof" artifact discipline (Task 9). Story 4-6 produces `4-6-diff-scope-proof.txt` with the same sections plus a Branch-C-specific addendum.
- Story 4-5's "new files only for new tests" discipline (AC #10). Story 4-6 inherits this — all new unit tests go in NEW files; the impact-report harness is the only existing file modified, and those changes are surgical extensions.
- Story 4-5's "HALT discipline + named, story-prefixed HALTs" (DD #12). Story 4-6 inherits the format (4-6-HALT-(a) through (h) per DD #8).

### Git intelligence

Recent commits (`git log --oneline -10`):

- `1c8e274` — Story 4-5 review pass v3: vDSP adoption, doc fixes, scope close-out.
- `4027b34` — Story 4-5 review pass v2: regenerate post-fix artifacts.
- `0b2d8dc` — Story 4-5 review pass v2: C1-C4 + M1-M7 + N1-N13 fixes.
- `dedd53b` — Story 4-5 Tasks 12 + 13 + close-out.
- `2be87bb` — Story 4-5 Task 9: diff-scope proof artifact.

Story 4-5 close-out is fresh (today's date 2026-05-14 per sprint-status `last_updated`). Story 4-6 should NOT add scope creep — the spec deliberately scopes tightly to diagnostic + investigation + branch decision, with CoreML conformance moved to a future story regardless of branch.

The most recent commit (`1c8e274`) is the Story 4-5 review-pass-v3 close-out — the source baseline this story's Task 1 captures against. Confirm by `git log -1 --pretty=format:%H` at story-start.

### Project Structure Notes

- **`Sources/BoomBoomBoomKit/`** — core library (DSP, types, public protocol). Story 4-6 additions: NEW `MLDiagnosticSnapshot.swift`, NEW `MLDiagnosticTechnique.swift`. Modifications: `BPMDiagnosticTrace.swift`, `AudioAnalysisService.swift`. (Story 4-5's `MLTechnique.swift` is NOT modified — Story 4-5 DD #18 freeze preserved.)
- **`Sources/BoomBoomBoomKitML/`** — ML conformance + optional bundled `.mlmodelc`. Story 4-6 modifications: `BNNSTechnique.swift` (add `MLDiagnosticTechnique` conformance + `Mutex<...>` threshold-override seam); Branch-C-only: `Package.swift` `resources:` line removed, `Resources/` directory removed entirely.
- **`Sources/BoomBoomBoomKitTestSupport/`** — shared test fixtures + mocks. Story 4-6: no modifications.
- **`Tests/BoomBoomBoomKitTests/`** — unit tests. Story 4-6 additions: `MLDiagnosticSnapshotTests.swift`, `MLDiagnosticTechniqueTests.swift`, `BNNSTechniqueDiagnosticTests.swift`, `BNNSTechniqueAbstainFloorTests.swift`, `DnBTargetsFileLoadingTests.swift`, `AudioAnalysisServiceInoutTraceTests.swift`.
- **`Tests/BoomBoomBoomKitBenchmarkTests/`** — env-gated benchmarks + impact reports. Story 4-6: modify `BNNSImpactTests.swift`; update `Fixtures/4-dnb-triplet-targets.json` to schema_version 3.
- **`_bmad-output/implementation-artifacts/`** — story artifacts. Story 4-6 adds: `4-6-regression-snapshot.json`, `4-6-bnns-impact-report.json`, `4-6-diff-scope-proof.txt`, `4-6-threshold-sweep.json`, optionally `4-6-featurize-differential.json` and `4-6-yin-yang-swift-logmel.npz`.
- **`_bmad-output/ml-models/`** — Branch-C-only target for the bundle move.
- **`_bmad-output/ml-training/swift_feature_extractor/`** — optional Branch-not-A target for `dump-track` CLI (Task 8.1).

### References

- **Story 4-5 spec** — `_bmad-output/implementation-artifacts/4-5-bnns-mltechnique-conformance.md` (the parent story; 4-6 inherits DD patterns, HALT format, file-scope discipline, gating-checklist shape).
- **Story 4-5 close-out** — `4-5-bnns-mltechnique-conformance.md` lines 1063-1184 (Branch C declared; gating-checklist evidence; commit graph; deferred-work entries that 4-6 resolves).
- **Story 4-5 impact report** — `4-5-bnns-impact-report.json` (the 0/4 evidence; the named-DnB results that 4-6's expanded target set extends; the per-track abs_error and dsp_correct values that drive control selection).
- **Story 4-5 review-pass v3 deferred-work** — `deferred-work.md:401-467` (C1-C5 entries; the story-readiness handoff to 4-6).
- **Story 4-5 dev-agent deferred-work** — `4-5-bnns-mltechnique-conformance.md:1117-1122` (the four entries from close-out; #2 and #3 RESOLVED by this story).
- **Epic 4 plan + Branch decision rules** — `_bmad-output/planning-artifacts/epics.md:1095-1127` (the original Branch A/A'/B/C language; 4-6 is the de-facto research-spike vehicle per Story 4-5 close-out choice).
- **Codex C1 / C2 analysis (referenced in deferred-work.md:401-435)** — the 5-failure-mode taxonomy and the bundle-pull framing.
- **Story 4-5 Task 1.5d allocator probe** — `_bmad-output/implementation-artifacts/4-5-allocator-probe.log` (the synthetic-input-produces-confident-prediction evidence that makes "threshold too aggressive" the leading hypothesis).
- **`make ml-parity`** — `_bmad-output/ml-training/test_feature_parity.py` (the existing Swift/Python featurization parity harness used as the reference for DD #6 revised differential).
- **CLAUDE.md release protocol** — the squash-merge protocol for develop → main; Branch C moves the bundle from "Ships to `main`" to "Stays on `develop` ONLY".
- **WWDC 2024 #10211 "Support real-time ML inference on the CPU"** — Story 4-5's reference for BNNSGraph CPU-only semantics; unchanged for 4-6.

---

## Dev Agent Record

### Agent Model Used

(Populated by the dev agent at story start. Expected: Claude Opus 4.7 (`claude-opus-4-7`) or successor via the `/bmad-dev-story` workflow.)

### Debug Log References

(Populated by the dev agent during implementation.)

### Completion Notes List

(Populated by the dev agent at close-out. Expected entries:
- Branch identifier (A / A-conditional / C) + one-sentence rationale. If Branch A-conditional, the verbatim authorization line per W2: `Branch A-conditional authorized YYYY-MM-DD by <name>: <one-sentence reasoning>`.
- Pre-fix failure-stage histogram (7 counts: 6 stages + noAbstain) from Task 1.5 impact report.
- Post-fix failure-stage histogram (7 counts) from Task 6.x final impact report.
- DD #5 outcome (A/B/C/D) + chosen remediation path.
- For Branch A: threshold values (confidenceThreshold and marginConfidenceThreshold) chosen + rationale + sweep evidence link.
- For Branch A with featurize fix: diff summary + ml-parity result.
- For Branch C: file moves performed + DocC updates + MODEL_CARD.md update + tools/coreml-convert/README.md Path A update.
- BNNS-on Acc1 at post-fix config; named-DnB resolved count; controls preserved count.
- BNNS inference wall-clock p50 / p95 per-track from final impact report.
- Test count (must be in band [416, 424] per DD #12 revised).
- OA300 Acc1/Acc2 at default config (must clear floors AND match snapshot byte-identically on DSP-only).
- GiantSteps Acc1/Acc2 same.
- Deferred-work entries created (if any new ones surface from the investigation) AND entries resolved (Story 4-5 dev-agent #2 + #3; review-pass v3 C1 + C2 + C4 + C5; possibly C3 depending on how the regression-snapshot question is treated).
- Commit graph for this story.
- Suggested follow-on story slug (Branch A: `4-8-coreml-mltechnique-conformance` against post-4-6 baseline; Branch C: `epic-4-retrospective` promotion).
)

### File List

(Populated by the dev agent at close-out. Expected entries:

**New Sources:**
- `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift` (NEW — MLDiagnosticSnapshot struct + nested FailureStage (6 cases) + Gate (2 cases) enums per DD #2 revised).
- `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift` (NEW — MLDiagnosticTechnique capability protocol per DD #3 revised).

**Modified Sources:**
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (new mlDiagnosticSnapshot field + Story 4.6 MARK section).
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (evaluateMLIfActive signature change to `inout BPMDiagnosticTrace?` + capability-protocol narrowing + strict mutation-after-cancellation ordering).
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` (`MLDiagnosticTechnique` conformance extension + evaluateInternal helper + evaluate as thin wrapper + `Mutex<(Double, Double)?>` threshold-override seam per Task 7.1 revised).

**Modified for Branch C only:**
- `Package.swift` (REMOVE `resources: [.copy("Resources")]` from BoomBoomBoomKitML target declaration).

**Branch-C-only modified sources:**
- `MODEL_CARD.md` (new Status section).
- `tools/coreml-convert/README.md` (Path A removal).
- `CLAUDE.md` (Resources/ inventory update).

**New Tests:**
- `Tests/BoomBoomBoomKitTests/MLDiagnosticSnapshotTests.swift`.
- `Tests/BoomBoomBoomKitTests/MLDiagnosticTechniqueTests.swift`.
- `Tests/BoomBoomBoomKitTests/BNNSTechniqueDiagnosticTests.swift` (parameterized via `@Test(arguments:)`).
- `Tests/BoomBoomBoomKitTests/BNNSTechniqueAbstainFloorTests.swift` (env-gated under `BNNS_IMPACT=1` per AC #9 revised).
- `Tests/BoomBoomBoomKitTests/DnBTargetsFileLoadingTests.swift`.
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceInoutTraceTests.swift` (inout mutation-after-cancellation ordering per AC #4 revised).

**Modified Tests:**
- `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift` (surgical extensions per Task 6).
- `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` (schema_version 3 + dsp_correct_controls).

**Branch-C-only file moves + Package.swift edit:**
- `git mv Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/ _bmad-output/ml-models/giantsteps_v1.mlmodelc/`.
- `rmdir Sources/BoomBoomBoomKitML/Resources/` (directory removed entirely per DD #7 revised + W5 Critique-and-Refine refinement; no `.gitkeep`).
- `Package.swift` — REMOVE `resources: [.copy("Resources")]` line from the BoomBoomBoomKitML target declaration (per DD #7 revised + Siri P8).

**Optional develop-only tooling (only if Task 8 fires):**
- `_bmad-output/ml-training/swift_feature_extractor/Sources/dump-track/main.swift` (new CLI).
- `_bmad-output/ml-training/swift_feature_extractor/Package.swift` (modified to expose dump-track target).

**New artifacts:**
- `_bmad-output/implementation-artifacts/4-6-regression-snapshot.json`.
- `_bmad-output/implementation-artifacts/4-6-bnns-impact-report.json`.
- `_bmad-output/implementation-artifacts/4-6-threshold-sweep.json`.
- `_bmad-output/implementation-artifacts/4-6-diff-scope-proof.txt`.
- Optional: `_bmad-output/implementation-artifacts/4-6-featurize-differential.json` (only if Task 8 fires).
- Optional: `_bmad-output/implementation-artifacts/4-6-yin-yang-swift-logmel.npz` (only if Task 8 fires).

**Modified artifacts:**
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (Story 4-6 status: ready-for-dev → in-progress → review at close-out).
- `_bmad-output/implementation-artifacts/4-6-ml-accuracy-investigation-and-bundle-decision.md` (Status, Tasks checkboxes, Dev Agent Record, File List, Change Log — workflow-permitted sections only).

)

## Change Log

- **2026-05-15 (Story 4-6 Critique-and-Refine sixth-reviewer pass + Codex thread continuation).** Sixth-pass critique on the post-17-patch spec surfaced 6 surgical contradictions/weaknesses. Codex consulted via thread `019e29dc-23ef-7b92-8f72-dbc74658aa5d` (codex-reply pattern, no new thread). Codex accepted W2/W3/W5/W6 (with tweaks), modified W1 (tighten to `[416, 424]` not `[416, 433]`), pushed back on W4 (BPMDiagnosticTrace is NOT currently `Codable` per `BPMDiagnosticTrace.swift:15` — the entire Codable migration requirement was based on a false premise, so DELETE the requirement entirely rather than adding `Codable` to the new types). Codex also did an adversarial grep pass identifying ~40 remaining stale `MLAbstainReason` / `mlAbstainReason` / `.gitkeep` / `5-mode` / `inferenceFailed` / `as? BNNSTechnique` / Yin-Yang-single-track / 4-sweep references in the operational sections (Story header, Background, AC #1/#2/#7/#8/#11, Tasks 2/3/4/6/7/8/9/11, Dev Notes Architecture/Source-pointers/Why-co-located/Why-trace-field/Risk/Apple-platform/Previous-Story/Project-Structure/References, Completion Notes, File List). All swept in this pass. Outcomes:

  - **W1**: Test count band tightened from `[416, 433]` (+17 = copy-paste artifact) to `[416, 424]` (+8 = 6 files × ~1 split tolerance each). DD #12 + HALT-(h) + AC #11 + Task 10.5 + Completion Notes all aligned. Below-target = missing test; above-target ceiling = drift signal.
  - **W2**: Branch A-conditional now requires THREE artifacts: MODEL_CARD entry (a), re-open trigger (b), AND verbatim authorization line `Branch A-conditional authorized YYYY-MM-DD by <name>: <reasoning>` in Completion Notes (c). Without ALL THREE, 3/4 controls falls to Branch C. Strict 4/4 Branch A still requires none of (a)/(b)/(c). DD #8 + AC #10 aligned; clarification added that strict-4/4 doesn't require the authorization line.
  - **W3**: Resolved the AC #1 / DD #2 / AC #2 three-way contradiction on pre-featurize snapshot population. Authoritative rule: for `featuresAbsent` and `featureVersionMismatch`, NO snapshot is constructed (the abstain fires before featurize; no feature payload to checksum); the trace's `mlDiagnosticSnapshot` stays nil. The conformance returns `(nil, nil)` from `evaluateWithDiagnostic` on those two paths per DD #3 tuple invariant. The harness derives the histogram bucket from `MLEvaluation == nil && mlDiagnosticSnapshot == nil` + trace-state inspection.
  - **W4**: DELETED the Codable migration requirement entirely. Reason: `BPMDiagnosticTrace` is currently declared `public struct BPMDiagnosticTrace: Sendable` only (no `Codable`); there is no `encode(to:)` / `init(from:)` synthesis to migrate. The original AC #12 Codable check was based on a false premise. Public types remain non-Codable; JSON emission for the impact-report harness uses a private mirror struct (`DiagnosticSnapshotJSON`) in `BNNSImpactTests.swift` per Task 6.1.
  - **W5**: Resolved the `.gitkeep` contradiction across 3 places. Post-Critique-and-Refine end-state: Branch C removes the `Resources/` directory entirely (`rmdir`) AND removes the `resources: [.copy("Resources")]` line from `Package.swift`'s BoomBoomBoomKitML target. No `.gitkeep`. Task 9.2 rewritten; AC #11 Branch-C addendum + Task 11.6 updated with corrected proof commands (`test ! -d` instead of `ls`; target-scoped grep for `.copy("Resources")` instead of unscoped `resources:` grep — other targets legitimately retain resources blocks). File List Branch-C section updated.
  - **W6**: Tasks 10.1-10.3 (pre-review enumerated test list, ~25 lines of stale type names) replaced with a single redirect to DD #12 + AC #12 + the post-review file inventory. The pre-review test file `MLAbstainReasonTests.swift` is dropped (the type is dropped); the synthetic-only abstain-floor test is replaced by AC #9 revised real-audio test. Tasks 10.4 (`DnBTargetsFileLoadingTests`), 10.5 (test count band), 10.6 (no modifications to existing test files) preserved.
  - **Stale-residue sweep**: ~40 individual line edits sweeping `MLAbstainReason`→`MLDiagnosticSnapshot`, `mlAbstainReason`→`mlDiagnosticSnapshot`, `Mode`→`FailureStage`, `5/five mode/failure modes`→`6/six stages`, `inferenceFailed`→`graphFailed`/`decodeRejected`, `AbstainReasonJSON`→`DiagnosticSnapshotJSON`, `as? BNNSTechnique`→`as? MLDiagnosticTechnique`, `4 sweeps`→`7 sweeps`, single-Yin-Yang→12-track-stratified, `.gitkeep`→absent. Audit-trail sections (Review Findings v1 lines 1031-1167, prior Change Log entries) explicitly preserved per Codex guidance.
  - **Task 4.7 NEW**: explicitly added FNV-1a/xxHash computation of `inputFeatureChecksum: UInt64` (was implicit in DD #2 + DD #6; now a numbered task subitem).
  - **Task 2.7 NEW**: explicit subtask to create `MLDiagnosticTechnique.swift` alongside `MLDiagnosticSnapshot.swift` (was buried in the substitution table).
  - **Task 9.8 NEW**: explicit verification step that `Resources/` directory is absent AND the `Package.swift` target-block grep returns zero matches.
  - DD count: 17 → 17 (no new DDs; the W1-W6 fixes are tightenings of existing DDs).
  - Public types: still 1 struct (`MLDiagnosticSnapshot`) + 1 protocol (`MLDiagnosticTechnique`) + 1 trace field. No type-surface change.
  - Test count band: `[416, 433]` → `[416, 424]` per W1.
  - Status: remains `ready-for-dev` post-Critique-and-Refine. Codex thread `019e29dc-23ef-7b92-8f72-dbc74658aa5d` open for further dev-time consultation.

- **2026-05-14 (Story 4-6 story-creation).** Created from the Story 4-5 close-out handoff in `deferred-work.md:401-467` (review-pass v3 C1-C5 findings) + Story 4-5 dev-agent deferred-work entries #2 + #3 (post-close-out commit notes). Scope re-cast from the original epic.md "CoreML MLTechnique Conformance (Production)" framing to "BNNS ML Accuracy Investigation and Bundle Decision" per the Project Lead's explicit choice in sprint-status `last_updated` 2026-05-14: "Investigation deferred to Story 4-6 with hard AC; see deferred-work.md 'Story 4-5 review-pass v3 — Chunk 3 impact-report findings' for full triage. Story 4-5 closes as 'BNNS infrastructure delivered'; ML accuracy validation moves to Story 4-6." The story-key in sprint-status.yaml is renamed from `4-6-coreml-mltechnique-conformance` to `4-6-ml-accuracy-investigation-and-bundle-decision` to reflect actual scope; CoreML conformance work moves to a future story slug (suggested `4-8-coreml-mltechnique-conformance`) IFF Branch A fires. 13 design decisions authored against HEAD `1c8e274`. Status: `ready-for-dev`.

- **2026-05-15 (Story 4-6 pre-implementation 5-reviewer party-mode + Codex review pass).** Comprehensive review BEFORE any source change, applied 17 patches across 5 independent reviewers — see `## Review Findings v1` below for full detail. Process:

  **Phase 1 — 5 parallel reviewers:**
  - **Codex (gpt-5.5 plan review)** via `codex:plan-review` skill — verdict "not ready as written"; 8 major findings + better-alternative proposal (always-on `MLDiagnosticSnapshot` vs discriminated `MLAbstainReason`). Codex thread `019e29dc-23ef-7b92-8f72-dbc74658aa5d`.
  - **axiom-ai** (on-device AI / BNNSGraph / Core ML perspective)
  - **axiom-concurrency** (Swift 6 strict concurrency / inout / Mutex<T> vs nonisolated(unsafe))
  - **axiom-apple-docs** (Xcode-bundled `existential-any.md` + `Swift-Concurrency-Updates.md` + Bundle.module / @testable / SPM patterns)
  - **axiom-swift** (modern Swift idioms / @Test(arguments:) parameterized tests / type-narrowing patterns)

  **Phase 2 — 4 BMad party-mode roundtable agents** (Winston, Amelia, Mary, Siri) react to Codex's findings + Axiom cross-checks:
  - Winston (Architect): package-graph fix via capability protocol is load-bearing; sibling-method on concrete type was reasoned against wrong constraint set. Always-on snapshot lives on trace, doesn't reshape MLTechnique. Branch C governance = epics.md amendment wins. Project-wide elevation rule: "Cross-target type narrowing always goes through a protocol declared in the upstream target."
  - Amelia (Dev): concrete file:line diff for capability protocol fix; always-on snapshot is less work than splitting the enum; 7-point sweep curve with `wrong_non_abstain_count` headline column; concrete inout-after-cancellation code; revised test count band `[416, 433]` with parameterized collapse.
  - Mary (Analyst): controls are accuracy oracle (never cross-validate); Branch A strict 4/4 with named "Branch A-conditional" slack option for 3/4 + re-open trigger + MODEL_CARD entry; epics.md 3-sentence amendment; stratified 12-track featurize differential; MODEL_CARD framing "*this* reference model doesn't generalize" not "ML doesn't work".
  - Siri (Apple Platform): Bundle.module + empty Resources/.gitkeep is non-idiomatic — REMOVE `resources:` line entirely under Branch C; Mutex<T> from `Synchronization` module is the cleanest macOS 15+ threshold-override seam; `as? ConcreteType` through `any P` is valid Swift but the package-graph constraint is the real blocker (Codex finding stands); `inputFeatureChecksum` field — no Apple-shipped softmax primitive on macOS 15+.

  **Phase 3 — 17 patches applied to spec in-place:**
  - **P1 (CRITICAL — Codex finding #1):** DD #3 rewritten — capability protocol `MLDiagnosticTechnique: MLTechnique` in NEW core file `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift`; `BNNSTechnique` conforms in sibling target; service narrows via `as? MLDiagnosticTechnique` not `as? BNNSTechnique`. Was structurally impossible per package graph.
  - **P2 (CRITICAL — Codex finding #2 + better alternative):** DD #2 rewritten — always-on `MLDiagnosticSnapshot` struct in NEW core file `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift`; 6-case `FailureStage` enum (splits `inferenceFailed` into `graphFailed` + `decodeRejected`); `inputFeatureChecksum: UInt64` field for cheap featurize-drift detection (Amelia's contribution); the discriminated `MLAbstainReason` enum is DROPPED from public API and becomes a private reporting view.
  - **P3 (CRITICAL — Codex finding #4):** AC #4 rewritten — strict mutation-after-cancellation ordering in `evaluateMLIfActive`: evaluate into locals → post-evaluate cancellation check → ONLY THEN mutate inout trace. New `AudioAnalysisServiceInoutTraceTests.swift` test locks the ordering.
  - **P4 (SHOULD-FIX — Codex finding #3 + Mary):** DD #5 rewritten — 7-point sweep ladder (0.0, 0.10, 0.20, 0.30, 0.40, 0.50 + final-chosen) with per-run corpus-wide distribution stats (`wrong_non_abstain_count`, decoded-BPM histogram in 5-BPM bins, softmax p50/p95, etc.). Was 4-point theater.
  - **P5 (SHOULD-FIX — Codex finding #3 + Mary):** DD #6 rewritten — stratified 12-track featurize differential (4 named + 4 controls + 4 ordinary). Cheap-first via `inputFeatureChecksum` (P2); full `.npz` round-trip only on diverging tracks. Was single-track.
  - **P6 (SHOULD-FIX — Codex finding #6 + Mary):** DD #8 + AC #10 + HALT-(f) rewritten — Branch A gate is STRICT 4/4 controls preserved; Branch A-conditional named slack for 3/4 requires project-lead authorization + MODEL_CARD entry + re-open trigger; 2/4 or fewer is ALWAYS Branch C, no slack. Was three contradictory statements.
  - **P7 (SHOULD-FIX — Codex finding #7 + Mary):** DD #17 NEW + DD #1 annotated — epics.md governance amendment (Mary's 3-sentence text) part of Story 4-6 first commit. Resolves the "use 4-6 as the spike vehicle without amending epics.md" drift.
  - **P8 (SHOULD-FIX — Siri):** DD #7 rewritten — Branch C REMOVES `resources: [.copy("Resources")]` line from `Package.swift` entirely. No Apple precedent for ship-infrastructure-bundle-nothing; the `.gitkeep` pattern was non-idiomatic.
  - **P9 (SHOULD-FIX — Codex finding "AC #9 weak"):** AC #9 rewritten — abstain-floor test anchors on real audio (20 OA300 DSP-correct tracks at thresholds 0.0/0.0, `abstain_rate ≤ 0.30`, `wrong_non_abstain_count ≤ 4`). Was synthetic-uniform-input test which already worked in 4-5.
  - **P10 (SHOULD-FIX — Siri):** Task 7.1 rewritten — `Mutex<(Double, Double)?>` threshold-override seam (macOS 15 `Synchronization` module) replaces the original `nonisolated(unsafe) static var`. Parallel-test-safe.
  - **P11 (NICE-TO-HAVE — Winston):** DD #14 NEW — project-wide elevation rule "Cross-target type narrowing always goes through a protocol declared in the upstream target." Captured at story close-out for project-context.md.
  - **P12 (NICE-TO-HAVE — Mary):** DD #15 NEW — re-open trigger named for Branch A-conditional and as defensive watch under Branch A strict. "If a future ablation pass shows >5% Acc1 regression on control set, or any additional control regresses, bundle decision re-opens."
  - **P13 (NICE-TO-HAVE — Mary):** DD #16 NEW — MODEL_CARD Branch-C framing: "*this* reference model doesn't generalize past GiantSteps" not "ML doesn't work". Protects BNNS infrastructure investment from misread.
  - **P14 (NICE-TO-HAVE — Amelia):** DD #12 rewritten — test count band `[416, 433]` (was [415, 432]) reflecting parameterized-test collapse + new tests for capability protocol + always-on snapshot + inout cancellation ordering.
  - **P15 (NICE-TO-HAVE — Amelia):** AC #12 expanded — file scope adds two NEW core files (`MLDiagnosticSnapshot.swift`, `MLDiagnosticTechnique.swift`); 6 NEW test files; Codable synthesis migration check; `epics.md` amendment scope; Branch-C `Package.swift` `resources:` line removal.
  - **P16 (NICE-TO-HAVE — Codex deferred):** Documented `wontfix pre-1.0` — consumer-wrapped BNNSTechnique loses diagnostics. Protocol doc-comment notes "diagnostic capability requires direct conformance — forwarding wrappers must re-conform if they want the diagnostic path."
  - **P17 (NICE-TO-HAVE — Siri):** Deferred-work entry filed — `vDSP.softmax` primitive watch for WWDC 2026 (currently no Apple-shipped 1-line softmax on macOS 15; the manual `vForce.exp + vDSP.sum + vDSP_vsdiv` pattern is canonical).

  **Outcomes:**
  - DD count: 13 → 17 (added DD #14 elevation rule, DD #15 re-open trigger, DD #16 MODEL_CARD framing, DD #17 epics.md amendment).
  - HALT count: 8 → 8 (no count change but HALT-(b), HALT-(f), HALT-(g), HALT-(h) reworded for the revised types and gate).
  - Public types: was 1 struct (`MLAbstainReason`) + 1 trace field; now 2 structs (`MLDiagnosticSnapshot` + nested enums) + 1 protocol (`MLDiagnosticTechnique`) + 1 trace field (`mlDiagnosticSnapshot`).
  - Test count band: `[415, 432]` → `[416, 433]` per parameterized-test collapse.
  - File scope: was 5 source files; now 6 (added `MLDiagnosticSnapshot.swift`) + new `MLDiagnosticTechnique.swift` + Branch-C `Package.swift` edit.
  - Branch A gate: strict 4/4 controls preserved (was contradictory).
  - Branch C bundle pull: `Package.swift` `resources:` line removed entirely (was retained with `.gitkeep`).
  - Threshold override seam: `Mutex<(Double, Double)?>` (was `nonisolated(unsafe) static var`).
  - epics.md amendment: 3-sentence Branch C governance update part of first commit.
  - Status: remains `ready-for-dev` post-patches.

---

## Review Findings v1 (party-mode + Codex 2026-05-15)

Comprehensive 5-reviewer pre-implementation review pass. The full review responses are preserved below for audit trail; the spec body above has been patched in-place per the 17 patches enumerated in the Change Log entry.

### Codex plan review (gpt-5.5)

**Verdict:** the plan is not ready as written. It has one architectural impossibility, a few places where the evidence model is too lossy to answer the question it claims to answer, and one procedural dodge that would let Story 4-6 repeat Story 4-5's failure mode under a nicer rubric.

**Major findings:**

1. **AC #4 cannot compile in the current package graph.** `AudioAnalysisService` lives in the core target, while `BNNSTechnique` lives in `BoomBoomBoomKitML`; the dependency arrow is one-way: ML depends on core, not vice versa (`Package.swift:13-28`). So `AudioAnalysisService.swift` cannot legally do `ml as? BNNSTechnique` without creating a cycle. The story's central routing plan is therefore structurally invalid, not merely inelegant. The right abstraction is a capability protocol declared in core, e.g. `MLDiagnosticTechnique: MLTechnique`, which BNNS conforms to in the sibling target; then the core service narrows to that protocol, not the concrete ML target. The story explicitly rejected this family of solution in DD #3, but the package graph makes the rejection untenable.

2. **The five-mode abstain taxonomy is not sufficient to distinguish the five claimed hypotheses.** `decodeLogits` already returns `nil` for out-of-range BPM and other decode failures before the confidence gates. The story folds all of that into `inferenceFailed`. Those are not the same diagnosis: "graph failed," "softmax became non-finite," and "decoded argmax mapped outside 60…200" point to different remediation paths. Worse, the story only exposes decoded BPM / softmax metrics on `confidenceGateRejected`, so once thresholds are disabled the most useful evidence disappears on successful-but-wrong calls.

3. **The threshold sweep does not actually separate "threshold too aggressive" from "featurize bug".** At 0.0/0.0, a featurization bug can absolutely produce non-abstaining, wrong predictions. Single-track Swift-vs-Python differential proves a bug exists, not that the corpus-wide issue is absent. The story needs: always-on decoded BPM + top-2 confidence on every evaluation; threshold sweep summaries over the whole corpus distribution; featurization differential on a small stratified set.

4. **The `inout trace` plan weakens the Story 4-5 cancellation contract unless mutation is delayed.** Today the helper brackets evaluation with pre/post cancellation checks. The new story doesn't require the write to occur **after** the post-evaluate cancellation check. Require: evaluate into locals → post-check cancellation → only then mutate the inout trace.

5. **The runtime type-narrowing story is wrong even beyond the package-cycle problem.** User-supplied wrappers/decorators around `BNNSTechnique` would immediately lose diagnostics even though the underlying behavior is identical. Trace semantics depend on object topology, not model behavior.

6. **Branch A's control gate is internally inconsistent.** The story's main success rule is strict (`controls_preserved == controls_total`) but AC #10 then adds a HALT only when Branch A breaks ≥2 controls. Three contradictory statements. Controls should be 4/4 or no Branch A.

7. **The Branch C process exception is too casual.** `epics.md` is explicit: Story 4.5 resolving `<2/4` means Story 4.6 goes back to backlog and a research spike is created before re-promotion. The new story simply declares that it is using the 4-6 slot as the spike vehicle while leaving the governing artifact unchanged. Governance drift.

8. **CoreML being out of scope is correct; landing it opportunistically would be a mistake.** The story is right here.

**Better alternative (Codex):** Always-on `MLDiagnosticSnapshot` exposing `decodedBPM?`, `softmaxMax?`, `softmaxSecondMax?`, `failureStage?` on EVERY evaluation. Abstain becomes a derived conclusion, not the only observable.

(Full Codex thread: `019e29dc-23ef-7b92-8f72-dbc74658aa5d`.)

### Winston (Architect) verdict

🏗️ The capability protocol is the right shape, and Codex's diagnosis is structurally correct. The package graph is one-way: ML → core. `AudioAnalysisService` in core literally cannot name `BNNSTechnique`. `as? BNNSTechnique` inside core is a compile error, not a smell. DD #3's rejection was reasoned against the wrong constraint set — it weighed elegance, not graph legality.

Shape to ship: declare `MLDiagnosticTechnique: MLTechnique` in core, separate file `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift`. `BNNSTechnique` conforms to both — `MLTechnique` stays frozen, `MLDiagnosticTechnique` is the additive surface. Service does `as? MLDiagnosticTechnique`. Consumer wrappers can opt in by forwarding; if they don't, they lose diagnostics but keep correctness. That's the right failure mode.

Always-on snapshot vs 5-mode enum: Codex is right on the substance, and it does NOT require reshaping `MLTechnique`. The snapshot should live on the trace, populated by `evaluateWithDiagnostic`. `MLTechnique` stays a single-method protocol returning `MLEvaluation?`. Abstain becomes a derived view (`evaluation == nil`), with the snapshot explaining why — including the successful-but-wrong case, which the 5-mode enum genuinely cannot represent.

Branch C governance — epics.md wins. Not equivalent. "Use the slot as the spike" silently changes what the slot's acceptance criteria measure. A spike has different exit criteria than a feature story.

Bundle-pull mechanics — Codex is right on the assertion. Test the load-bearing invariants: `swift build` green, `Bundle.module` resolves without throwing, `BNNSTechnique.bundledReferenceURL == nil` deterministically across clean checkout and rebuild.

Elevation: don't make it "diagnostic capability lives in core." Too narrow. Elevate the underlying rule: **"Cross-target type narrowing always goes through a protocol declared in the upstream target, never through `as?` to a downstream concrete type."** That's the durable lesson.

Net call: the story is fixable, not broken. Findings #1, #2, #4, #7 are load-bearing.

### Amelia (Senior Software Engineer) verdict

💻 **Verdict: not ready.** Codex finding #1 alone blocks compile.

Capability protocol — exact diff: new file `Sources/BoomBoomBoomKit/MLDiagnosticTechnique.swift` (do NOT colocate in `MLTechnique.swift` — keeps the protocol independently auditable and AC #12's diff-scope honest). `BNNSTechnique.swift:209-234`: split `evaluate` body into `evaluateWithDiagnostic` returning the tuple; `evaluate` becomes a 2-line forward. Add `extension BNNSTechnique: MLDiagnosticTechnique {}` at file bottom. Codex finding #5 (wrapped BNNS loses diagnostics) is **wontfix pre-1.0** — document it in the protocol doc-comment.

Taxonomy — ship the always-on snapshot. Keep the 5-mode enum, but attach `MLDiagnosticSnapshot` to `BPMDiagnosticTrace` populated on every evaluation. Add `inputFeatureChecksum: UInt64` — catches featurize drift cheaply. Less work than splitting the enum.

Threshold sweep — 4 runs insufficient. Add per-run aggregation to sweep JSON: `wrong_non_abstain_count`, `decoded_bpm_histogram`, `top_minus_second_p50/p95`. Sweep 7 points: 0.0/0.0, 0.10/0.02, 0.20/0.04, 0.30/0.05, 0.40/0.08, 0.50/0.10, plus the 4-5 shipped values.

Inout fix — exact code: evaluate into locals → post-eval cancel check → mutate trace last. Test: inject `isCancelled` returning `true` after evaluate; assert `trace?.mlAbstainReason == nil`.

Revised test count band — `[416, 433]`. Add 12 mandatory tests, collapse 12 BNNSTechniqueDiagnosticTests via `@Test(arguments:)` → -11. Net effectively unchanged.

AC #9 — right test: real-audio abstain-rate ceiling on a fixed corpus subset. Pick 20 OA300 tracks where DSP is correct. Run BNNS with thresholds 0.0/0.0. Assert `abstain_rate <= 0.30`. The 4-5 defect would have produced ≥0.90 here — caught instantly.

Still seeing: Branch A gate (pick strict, drop slack). Branch C governance (amend epics.md). AC #12 diff-scope: add new files explicitly. Migration from 4-5: confirm `Codable` synthesis on trace.

Land the protocol fix, the snapshot, the inout ordering, and the corpus-anchored AC #9. Then it compiles, then it proves something, then I'll dev it.

### Mary (Business Analyst) verdict

📊 The treasure here isn't the model — it's the *evidence architecture* underneath.

Two-baseline rule for `dsp_correct_controls`: controls are an **accuracy oracle**, full stop. They assert "DSP labeled these correctly; ML must not undo that win." The computational-oracle role already belongs to the impact report's wall-clock columns.

Branch A gate — strict 4/4, name the slack explicitly. Strict gate: `named_resolved ≥ 2/4 AND controls_preserved == 4/4`. If the project lead wants a 3/4 escape hatch, that's "Branch A-conditional", ships with documented re-open trigger and an explicit MODEL_CARD entry naming the regressed control. Honesty over flexibility.

Branch C governance — amend epics.md, lightly. Pretending epics.md still governs creates a phantom 4-6b that no one is writing. Lightest amendment: one paragraph reading *"Authorized 2026-05-14: Story 4-6 occupies the diagnostic-spike role originally scoped for 4-6b. If Branch C fires, the bundle moves to develop-only; no follow-up story is spawned unless impact evidence justifies it."*

Hypothesis separation — the question is well-posed; the test isn't. Threshold and featurize are not independent at the 0.0/0.0 corner. Redesign: always-on decoded BPM + top-2 softmax on every evaluation; corpus-wide distribution statistics per threshold run; stratified featurize differential — 4 named + 4 controls + 4 ordinary = 12 tracks.

Always-on snapshot AND derived taxonomy — yes, both. Ship `MLDiagnosticSnapshot` as the durable evidence layer. Derive the 5-mode `MLAbstainReason` histogram as a reporting layer on top. Trade-off: ~32 bytes per evaluation. Pay it.

Re-open trigger — yes, exactly: "If a future ablation pass shows >5% Acc1 regression on the previously-passing control set, or if any additional control regresses, Story 4-6's bundle decision re-opens and Branch C is reconsidered." Without it, "conditional Branch A" is just "Branch A with a shrug."

One thing nobody's said: if Branch C fires, the honest framing is not "ML doesn't work" — it's "*this* reference model doesn't generalize past GiantSteps." That distinction protects the BNNSTechnique infrastructure investment from being misread as a failed experiment.

**Verdict:** Story is close but not ready. Fix hypothesis separation, Branch A gate, epics.md amendment, and the treasure map reads true.

### Siri (Apple Platform Documentation Expert) verdict

🍎 Apple-platform validation on Story 4-6.

**Bundle.module with empty `Resources/.gitkeep` (Branch C, DD #7):** SPM's `.copy("Resources")` documentation is silent on the empty-directory case. I cannot find Apple-documented precedent for "ship infrastructure, bundle nothing." Foundation Models bundles models. Vision ships its own models. CoreML is consumer-supplied but doesn't ship a `Resources/` directory at all. My recommendation: **remove the `resources:` line under Branch C**. Keeping `.copy("Resources")` pointing at a directory that contains only a `.gitkeep` is non-idiomatic; I have not seen this pattern in any Apple sample.

**`.mlmodelc` interop between BNNS and CoreML:** Apple's CoreML documentation confirms `.mlmodelc` is the compiled artifact loaded by `MLModel(contentsOf:)`. What Apple does NOT document anywhere I can find: that the *same* `.mlmodelc` is loadable by both `BNNSGraphCompileFromFile` and `MLModel(contentsOf:)`. BNNSGraph's documented input is "a compiled CoreML model file"; bidirectional interop is implied, not stated.

**Host-side softmax:** Apple's canonical pattern. There is no 1-line softmax in Accelerate as of macOS 15 SDK — `vDSP` has no `softmax` primitive. BNNS has `BNNSActivationFunctionSoftmax` for in-graph activations, but for host-side post-processing on a logit vector returned from a graph, the manual 3-5 call pattern is canonical. Deferred-work item: WWDC 2026 may introduce `vDSP.softmax`.

**`as? BNNSTechnique` through `any MLTechnique`:** Swift 6 strict-concurrency permits this where `Sendable` is preserved across the cast. SE-0335. Codex package-graph finding is the real blocker.

**`@testable` + `internal static var thresholdOverride`:** The two-`@testable`-usage pattern is not a smell. Of your three options, **`Mutex<(Double, Double)?>`** (Swift 6 / `Synchronization` module, macOS 15+) is the cleanest. `nonisolated(unsafe)` with "set before fork" is a foot-gun in test parallelism.

**`inout BPMDiagnosticTrace?`:** Codex pattern ("evaluate into locals → check cancellation → mutate inout") matches Apple's documented async cancellation guidance: never mutate observable state after `Task.checkCancellation()` would throw. Correct call.

**DocC framing for "no bundled model":** Closest Apple precedent is **CoreML's `MLModel(contentsOf:)`** — consumer supplies URL, framework provides infrastructure. Foundation Models is the wrong analog. Do not lean on `Bundle.module` in the DocC narrative under Branch C — point consumers at `init(modelURL:)` as the primary entry point.

**Other flags:** WWDC25 Session 10208 ("Explore on-device ML with BNNSGraph") is the canonical BNNSGraph diagnostics reference. Swift 6.2 `@concurrent` does NOT interact with your testing seam (testing seam is a stored property, not a function). No deprecated API drift on BNNS C-API between Story 4-5 and 4-6.

**Memory commit:** `as? <concrete>` through `any P` is Swift-canonical; package-graph one-way is the real architectural constraint (Codex's call stands).

---

### Summary of patches applied (17)

| ID | Severity | Reviewer | Patch |
|---|---|---|---|
| P1 | CRITICAL | Codex #1 / Winston / Amelia / Siri | DD #3 + AC #3 + AC #4: capability protocol `MLDiagnosticTechnique` in core (new file) |
| P2 | CRITICAL | Codex alternative / Winston / Amelia / Mary | DD #2 + AC #1 + AC #2: always-on `MLDiagnosticSnapshot` + 6-case `FailureStage` enum (splits inferenceFailed); MLAbstainReason dropped from public API; `inputFeatureChecksum` added |
| P3 | CRITICAL | Codex #4 / Amelia | AC #4: strict mutation-after-cancellation ordering + new test |
| P4 | SHOULD-FIX | Codex #3 / Amelia / Mary | DD #5 + AC #8: 7-point threshold sweep + corpus-wide distribution stats |
| P5 | SHOULD-FIX | Codex #3 / Mary | DD #6: 12-track stratified featurize differential (cheap-first via `inputFeatureChecksum`) |
| P6 | SHOULD-FIX | Codex #6 / Mary | DD #8 + AC #10 + HALT-(f): strict 4/4 Branch A gate; named Branch A-conditional slack |
| P7 | SHOULD-FIX | Codex #7 / Mary | DD #17 NEW: epics.md 3-sentence amendment part of first commit |
| P8 | SHOULD-FIX | Siri | DD #7: Branch C removes `resources:` line from Package.swift entirely |
| P9 | SHOULD-FIX | Codex weakness / Amelia | AC #9: real-audio corpus-anchored abstain-floor test (20 DSP-correct tracks at 0.0/0.0) |
| P10 | SHOULD-FIX | Siri / axiom-concurrency | Task 7.1: `Mutex<(Double, Double)?>` threshold-override seam (was `nonisolated(unsafe)`) |
| P11 | NICE-TO-HAVE | Winston | DD #14 NEW: project-wide elevation rule (cross-target narrowing via core protocol) |
| P12 | NICE-TO-HAVE | Mary | DD #15 NEW: named re-open trigger for Branch A-conditional |
| P13 | NICE-TO-HAVE | Mary | DD #16 NEW: MODEL_CARD Branch-C framing ("*this* model doesn't generalize") |
| P14 | NICE-TO-HAVE | Amelia / axiom-swift | DD #12: test count band [416, 433] with parameterized-test collapse |
| P15 | NICE-TO-HAVE | Amelia | AC #12: file scope adds new core files + Codable migration check |
| P16 | NICE-TO-HAVE | Codex #5 | Documented `wontfix pre-1.0` — consumer-wrapped BNNS loses diagnostics; protocol doc-comment notes the limitation |
| P17 | NICE-TO-HAVE | Siri | Deferred-work entry: `vDSP.softmax` watch for WWDC 2026 |

### Story-readiness verdict (post-patches)

All 5 reviewers converge: the story is `ready-for-dev` post-patch. The structural compile-blocker (Codex #1) is resolved. The evidence model (Codex #2, #3) is strengthened to corpus-wide stats + always-on numeric snapshot. The Branch A/C governance + gate definitions are unambiguous. The architecture rule "cross-target narrowing through upstream protocol" is captured for project-wide elevation.

Codex thread `019e29dc-23ef-7b92-8f72-dbc74658aa5d` remains open if the dev needs to drill in on specific patches during implementation.

---

## Completion Notes (2026-05-16, Branch C close-out)

### Branch identifier

**Branch C — bundle pulled.** The previously-bundled `giantsteps_v1.mlmodelc` is removed from the main-shipping path; the `BNNSTechnique` infrastructure stays unchanged and ready to consume a higher-quality model when one is trained. CoreML conformance is DROPPED from Epic 4 (no bundled model warrants a second runtime per DD #10/#11); the follow-on `4-8-coreml-mltechnique-conformance` story is unblocked only if a future Branch-A retrain delivers a bundle-worthy model.

### Evidence (AC #11 — exact integers)

Captured at HEAD `8d932da` + this close-out commit's source state:

- **Pre-fix histogram** (Story 4-5 era, before diagnostic instrumentation landed): `ml_acc1 = 0/82`, `named_dnb_resolved = 0/4`, every track collapsed to a single undifferentiated `nil` from `BNNSTechnique.evaluate(trace:)` — see `_bmad-output/implementation-artifacts/4-5-bnns-mltechnique-conformance.md` close-out section for the original five-way ambiguity.
- **Post-fix histogram** (Story 4-6 threshold sweep at `0.00 / 0.00`): `failure_stage_histogram = { noAbstain: 82, featuresAbsent: 0, featureVersionMismatch: 0, featurizeRejected: 0, graphFailed: 0, decodeRejected: 0, confidenceGateRejected: 0 }`. Disambiguation complete: every track reached decode; the bundled model produced finite predictions for all 82, but only `ml_acc1 = 2/82` correct, with `wrong_non_abstain_count = 54/82` (66% wrong-confident). At production thresholds (`0.50 / 0.10`), `confidenceGateRejected = 82` instead — the gate was correctly suppressing low-confidence garbage. There was no wiring bug; the model itself doesn't generalize.
- **Corpus distribution at 0.00 / 0.00**: `softmax_max_p50 = 0.085`, `softmax_max_p95 = 0.294`, `softmax_margin_p50 = 0.010`, `softmax_margin_p95 = 0.051`, bimodal predictions at ~125 BPM and ~175 BPM regardless of ground-truth content, `decoded_bpm_matches_dsp_within_4pct_fraction = 4.88%`.
- **DSP-correct controls preservation**: `dsp_correct_controls_preserved = 4/4` at production thresholds (the gates DO protect the safe-fallback) but collapses to `0/4` once the gates are disabled — proves lowering thresholds is not a recovery path.
- **Swift/Python featurize parity**: `make ml-parity` PASSES across all 4 stages, ruling out a featurize bug.
- **Test count**: 420 `@Test(` occurrences across `Tests/BoomBoomBoomKitTests/` (in band per DD #12 `[416, 424]`). The bmad-code-review pass (2026-05-16) added 5 test functions across two new files — `AudioAnalysisServiceInoutTraceTests.swift` (4 tests covering inout-trace mutation ordering + the new `enableMLDiagnostics` flag, P17+P20) and `MLDiagnosticSnapshotPathCoverageTests.swift` (1 parameterized test covering 9 path cases × trace-attachment round-trip, P14). Pre-review-pass count was 415 (1 below band lower bound, exactly the missing inout-trace test the Acceptance Auditor flagged).
- **OA300 Acc1/Acc2 at default config (`mlTechnique = nil`)**: byte-identical to `4-6-regression-snapshot.json` pre-source baseline (see Task 12.4 gate output in the diff-scope proof).
- **GiantSteps Acc1/Acc2 at default config**: same — byte-identical to baseline (see Task 12.5 gate output).
- **BNNS-on Acc1 post-fix at production config**: 0/82 (the bundle is no longer present; `BNNSTechnique()` no-arg throws `.modelResourceMissing` and the impact-report harness gracefully skips).
- **Named-DnB resolved post-fix**: 0/4 (same — Branch C means BNNS doesn't fire in main).
- **BNNS inference p50/p95**: N/A under Branch C (no production ML runs in main without an explicit `modelURL:`).

### Branch C fix description — file-by-file

- `git mv Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/ _bmad-output/ml-models/giantsteps_v1.mlmodelc/` + deleted empty `Sources/BoomBoomBoomKitML/Resources/` directory (including `.gitkeep`).
- `Package.swift`: removed `resources: [.copy("Resources")]` from the `BoomBoomBoomKitML` target.
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift`: `bundledReferenceURL` hardcoded to `nil` literal (was `Bundle.module.url(forResource:withExtension:)` — would have compile-broken once the manifest line was removed). DocC at lines 29-34, 87-104, 170-177, 203-219 rewritten to Branch C / BYOW voice. Sentinel-URL message at modelResourceMissing throw-path tightened.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` line 144: consumer-intent table row reframed — `try? BNNSTechnique()` documented as returning nil under Branch C.
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` lines 469-477: doc-comment block reframed to remove Path A and update melBands reference framing.
- Tests (`BNNSTechniqueTests.swift`, `BNNSTechniqueAbstainFloorTests.swift`, `BNNSImpactTests.swift`): comments reframed; ZERO test logic changes. `.disabled(if: bundledModelMissing())` traits and `try? BNNSTechnique()` guards continue to work because the predicate now resolves to true.
- Consumer docs: `README.md` (BYOW-only framing), `tools/coreml-convert/README.md` (Path A reframed as BYOW; Path D wiring summary updated), `MODEL_CARD.md` (new Status section prepended with Task 16's "*this* reference model doesn't generalize" verbatim framing), `CLAUDE.md:21` ("Ships to main" row + new "Stays on develop" entry for `_bmad-output/ml-models/giantsteps_v1.mlmodelc/`).
- `Makefile`: `ML_MODEL_OUT_DIR` retargeted from `Sources/BoomBoomBoomKitML/Resources` to `_bmad-output/ml-models` (develop-only).

### Re-open trigger (Task 15 verbatim)

> If a future ablation pass shows >5% Acc1 regression on the previously-passing control set (`dsp_correct_controls` in `4-dnb-triplet-targets.json` v3), or if any additional control regresses (preserved → not-preserved), Story 4-6's bundle decision re-opens and Branch C is reconsidered with a follow-on story.

Filed in `_bmad-output/implementation-artifacts/deferred-work.md` as the live re-open entry alongside the squash-merge invariant from John ("post-squash diff against main must NOT include `Sources/BoomBoomBoomKitML/Resources/`"; under Branch C also must NOT include `_bmad-output/ml-models/giantsteps_v1.mlmodelc/`).

### Diff-scope proof (HALT-(g) reference)

See `_bmad-output/implementation-artifacts/4-6-diff-scope-proof.txt` for the full 6-section artifact: (1) `git diff --stat` from the Task-1 pre-source SHA, (2) `git status -- Sources/` showing only expected files, (3) `grep` for deprecated BNNSFilter* / Swift overlay APIs (zero matches), (4) trace-field audit recipes A-E (zero matches outside the `mlDiagnosticSnapshot` field landed in Story 4-6 Task 3), (5) SPM external-deps count (zero), (6) **Branch-C addendum** — `test ! -d Sources/BoomBoomBoomKitML/Resources` prints `directory absent`, AND `grep -nE '\.copy\("Resources"\)' Package.swift` scoped to the BoomBoomBoomKitML target block returns zero matches.

### Deferred-work entries — resolved or created

**Resolved (cite this Story 4-6 close-out as the resolution):**

- deferred-work.md "MODEL_CARD GiantSteps split sums to 661" entry — obsolete as a current shipping risk because no model ships in main; the discrepancy survives in the historical MODEL_CARD section but no longer affects consumer-facing claims.
- deferred-work.md "README 'non-recommended accuracy default' framing" entry — superseded by Branch C; the bundled-model paragraph is gone entirely from README.md.
- deferred-work.md "Bundle-pull decision deferred to Story 4-6" entry (the live one filed during Story 4-5 close-out) — RESOLVED with Branch C outcome. Bundle pulled, infrastructure retained, BYOW path documented.

**Kept (live entries):**

- deferred-work.md "Corpus quality: GiantSteps train+val is 96kbps MP3" entry — the genuine retrain lesson for a future Branch-A-on-better-corpus story. A higher-quality training corpus (320kbps source or PCM, optionally augmented with simulated MP3-codec round-trips) is the prerequisite for a future bundled model that might satisfy the Story 4-6 re-open trigger.

**Created:**

- John's squash-merge invariant — filed verbatim as a deferred-work entry. CLAUDE.md release protocol relies on operator vigilance; this entry names the specific paths to audit pre-squash.

### Status flip

`sprint-status.yaml` `4-6-ml-accuracy-investigation-and-bundle-decision: in-progress → review`. Final flip to `done` waits on the `/bmad-code-review` pass per Task 12.11.

### Out-of-scope side effects this close-out did NOT make

- No `BNNSTechnique` logic changes. Init / featurize / evaluate / decodeLogits / validateContract / extension surfaces all byte-identical (only DocC strings changed, one sentinel-URL message, the `bundledReferenceURL` static literal flip).
- No `MLTechnique` / `MLDiagnosticTechnique` / `MLDiagnosticSnapshot` / `BPMDiagnosticTrace.mlDiagnosticSnapshot` API changes — all already landed in commit `8d932da`.
- No test logic changes. Comments only.
- No CoreMLTechnique work — that placeholder is unaffected; the product decision to drop CoreML from Epic 4 is recorded above + in DD #10/#11.

### Codex review thread

The Branch C plan was reviewed by Codex (thread `019e3167-6132-7bb0-9e2e-f763307002bc`) before execution. Codex's eight findings — including the compile-break risk at `BNNSTechnique.swift:91-92` (`Bundle.module` lookup would fail once `resources:` was removed from the manifest) — were all addressed in the executed plan at `/Users/rterhaar/.claude/plans/valiant-growing-deer.md`.

### Review Findings (bmad-code-review, 2026-05-16)

Four parallel review layers: Claude Blind Hunter (diff-only), Claude Edge Case Hunter (diff + project read), Claude Acceptance Auditor (diff + spec + project-context), and Codex Blind Hunter (diff-only, second-opinion). Findings deduplicated and triaged. Layers that converged on the same finding are noted in-line.

#### Decision-Needed (RESOLVED 2026-05-16)

- [x] [Review][Decision] **Capability narrowing gates on `options.enableTrace`** [Sources/BoomBoomBoomKit/AudioAnalysisService.swift:475] — **RESOLVED: split into separate flag.** Add `Options.enableMLDiagnostics` (default `false`); `enableTrace` keeps its DSP-trace meaning, ML diagnostics get their own opt-in gate. Promoted to patch P17 below. (Claude BH; Edge Case Hunter corroborates.)
- [x] [Review][Decision] **Histogram conservation invariant vs silent-skip bucket** [Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:598-630] — **RESOLVED: Codex Option B with refinement.** Split the two `bucketKey = ""` paths into two explicit buckets — `"mlNotRun"` for the `trace == nil` case (BNNS init/etc. failed) and `"diagnosticSnapshotMissing"` for the trace-exists-but-no-snapshot case (custom conformer protocol violation). Conservation invariant `histogramSum == allRows.count` holds unchanged AND the two failure modes stay diagnostically distinguishable. Promoted to patch P18 below. (Codex thread `019e31bd-1d84-7c62-ae6a-446ff7c02bfa`.)
- [x] [Review][Decision] **Impact-report and threshold-sweep artifacts MISSING from disk** [_bmad-output/perf-baselines/bnns-impact/ does not exist; no 4-6-threshold-sweep.json] — **RESOLVED: run + commit JSONs now.** Run `make bnns-impact-report` to produce the fingerprint-named JSON at `_bmad-output/perf-baselines/bnns-impact/{fingerprint}--*.json`, plus the 7-point threshold sweep producing `_bmad-output/implementation-artifacts/4-6-threshold-sweep.json` (or its harmonized equivalent under `perf-baselines/`). Promoted to patch P19 below. (Acceptance Auditor.)
- [x] [Review][Decision] **`AudioAnalysisServiceInoutTraceTests.swift` MISSING** [Tests/BoomBoomBoomKitTests/AudioAnalysisServiceInoutTraceTests.swift absent] — **RESOLVED: add the two tests now.** Author `inoutTraceMutationAfterCancellation` and `inoutTraceMutationOnWinPath` per AC #4 + DD #12. Promoted to patch P20 below. (Acceptance Auditor.)

#### Patch (unambiguous fixes)

- [x] [Review][Patch] **Env var name drift between docs and code** [.claude/skills/running-benchmarks/SKILL.md:68,164 vs Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:368-371] — Doc says `BNNS_THRESHOLD_OVERRIDE_CONFIDENCE`; code reads `BNNS_THRESHOLD_OVERRIDE_CONF`. Threshold sweeps run from the docs silently use defaults. Align to one name. (Claude BH + Codex.)
- [x] [Review][Patch] **Console banner says "schema v2" but JSON writes `schema_version: 3`** [Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:847] — Print statement `=== BNNS Impact Report (Story 4-6 schema v2) ===` contradicts the JSON's `schema_version: 3`. Operators reading stdout misidentify the schema. (Claude BH + Codex.)
- [x] [Review][Patch] **Hardcoded `"v1"` literal instead of `BNNSTechnique.supportedFeatureSetVersion`** [Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:614-621] — Harness bucket logic uses `trace?.mlFeatures?.featureSetVersion != "v1"`. The constant `BNNSTechnique.supportedFeatureSetVersion` exists at `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:176` — promote to internal and reference. (Claude BH + Codex.)
- [x] [Review][Patch] **`Issue.record + return` is not a skip — Story 4-5 M12 lesson regressed** [Tests/BoomBoomBoomKitTests/BNNSTechniqueAbstainFloorTests.swift:67-82,114-118 and Tests/BoomBoomBoomKitTests/BNNSTechniqueDiagnosticTests.swift:41-48] — Under Branch C bundle-pull, `try? BNNSTechnique()` returns nil and these tests `Issue.record + return`. `Issue.record` records a **failure**, not a skip. Every CI run reports false test failures. Use `.disabled(if:)` at suite level (already used elsewhere) or early-return without `Issue.record`. (Claude BH + Codex; Story 4-5 M12 explicitly called this anti-pattern out.)
- [x] [Review][Patch] **Stale `mlDiagnosticSnapshot` never cleared on subsequent evaluation returning nil** [Sources/BoomBoomBoomKit/AudioAnalysisService.swift:489-493] — Trace mutation is gated by `if localSnapshot != nil`; no symmetric `else { trace.mlDiagnosticSnapshot = nil }`. The trace field is documented as "snapshot of the most recent evaluation" but actually holds whatever the most-recent-non-nil eval set. Narrow blast radius (typical traces are fresh per call), but contract violation. Add the else-branch. (Codex.)
- [x] [Review][Patch] **`modelIdentifier: "bnns_tempo_v1"` hardcoded regardless of BYOW URL** [Sources/BoomBoomBoomKitML/BNNSTechnique.swift:~1150] — Every win-path `MLEvaluation` advertises `"bnns_tempo_v1"` even when the consumer passed their own `modelURL`. Downstream tooling filtering by `model_identifier` will misattribute results. Either derive from `modelURL.deletingPathExtension().lastPathComponent`, accept an `identifier:` init param, or default to `nil` for BYOW. (Claude BH.)
- [x] [Review][Patch] **`dnbControl(for:)` denominator shrinks silently — 4/4 gate can become 3/3 or 0/0** [Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:298-301,693-704,810-812,905-909] — Fixture load requires `dsp_correct_controls.count >= 4`, but results are appended only inside `if let control = dnbControl(for:)`. The gate compares `controlsPreserved < controlResults.count`, not `< fixture.count`. Missing tracks turn "4/4 controls preserved" into "3/3" or "0/0" and still pass. Add `#expect(controlResults.count == fixture.dsp_correct_controls.count)` at gate site OR compare against the fixture count. (Codex.)
- [x] [Review][Patch] **P8 RECLASSIFIED → dismiss (Claude reviewer miscall, 2026-05-16)** — During patch application I re-verified the test count and discovered the discrepancy was a measurement-convention mismatch, not a Completion Notes error. The spec-preferred command `rg '@Test(' Tests/BoomBoomBoomKitTests | wc -l` (unit-test target only, per DD #12 line 281 + Task 10.5 line 725) returns `415` — exactly what Completion Notes claim. My initial 469 count globbed both test targets (`grep -rh '@Test(' Tests/`) which includes the benchmark target's ~54 tests. Acceptance Auditor's original finding stands: 415 IS 1 below the DD #12 [416, 424] band. **Resolution**: authoring `AudioAnalysisServiceInoutTraceTests.swift` (P20) adds 2 tests → 417 → in band. The Completion Notes integer is correct; no edit needed there.
- [x] [Review][Patch] **Strict-less-than `< 0.5` BPM tolerance comment says "within ±0.5"** [Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:690-705] — Comment says "within ±0.5 BPM" but code uses `absErr < 0.5`. A control exactly 0.5 BPM away is incorrectly counted as not preserved. Use `absErr <= 0.5`. (Codex.)
- [x] [Review][Patch] **BPM histogram bin off-by-one at exactly 200.0** [Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:645-650] — `floor((200-60)/5) = 28` clamps via `min(27, ...)` into bin 27 (195-200). Exact 200.0 BPM silently conflated with [195, 200). Either document the half-open `[60.0, 200.0)` semantics or expand bin array to 28. (Codex + Edge Case Hunter.)
- [x] [Review][Patch] **Redundant `Equatable` conformance on `MLDiagnosticSnapshot`** [Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift:489] — `Hashable` already requires `Equatable`. Drop the explicit `Equatable` declaration. (Claude BH.)
- [x] [Review][Patch] **ISO-8601 "basic form" comment doesn't match implementation** [Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:36-38,755-769] — Schema comment says `recorded_at` is basic-form ISO-8601; code writes extended form (with `-` and `:` separators). Update the comment. (Codex.)
- [x] [Review][Patch] **Threshold-override two-read race within single evaluate** [Sources/BoomBoomBoomKitML/BNNSTechnique.swift:142-149,383-396] — `effectiveConfidenceThreshold` and `effectiveMarginThreshold` each take a separate `withLock`. A test resetting the override between the two reads observes mixed-state thresholds. Single `withLock { ($0?.confidence, $0?.margin) }` returning both atomically. (Edge Case Hunter + Codex.)
- [x] [Review][Patch] **Diagnostic tests not parameterized over all 6 failure stages** [Tests/BoomBoomBoomKitTests/BNNSTechniqueDiagnosticTests.swift:39-54,175-191] — AC #3 last clause requires parameterized coverage of all 7 paths (6 failure stages + win path). Only `featuresAbsent`, `featureVersionMismatch`, and `featurizeRejected` are exercised — `graphFailed`, `decodeRejected` (non-finite and out-of-range argmax variants), `confidenceGateRejected × {gate1Softmax, gate2Margin}` are NOT. Add fixtures + parameterized cases for the remaining paths. (Acceptance Auditor + Codex.)
- [x] [Review][Patch] **`MLDiagnosticTechniqueTests` are performative — pass even if nothing runs** [Tests/BoomBoomBoomKitTests/MLDiagnosticTechniqueTests.swift:18-47] — First test only asserts the compile-time witness. Second swallows `BNNSTechnique()` failure with `catch { return }` rather than recording. Either use `.disabled(if:)` at suite level OR keep the compile-time witness test and split the runtime test to fail (not silently pass) when BNNS construction fails. (Codex.)
- [x] [Review][Patch] **AC #7 / AC #8 prose should be amended to reflect harmonized envelope** [_bmad-output/implementation-artifacts/4-6-ml-accuracy-investigation-and-bundle-decision.md:~425] — AC #7 still describes the v2 schema at the spec-literal filename. The user authorized the v3 schema + fingerprint-named files under `_bmad-output/perf-baselines/bnns-impact/` to conform with the `running-benchmarks` skill. Update AC #7 and AC #8 to reflect the harmonized envelope so future readers don't see a phantom v2/v3 deviation. (Acceptance Auditor, reclassified post user clarification.)
- [x] [Review][Patch] **P17: Add `Options.enableMLDiagnostics` flag** [Sources/BoomBoomBoomKit/AudioAnalysisService.swift Options + line 475] — From D1. Add `public var enableMLDiagnostics: Bool = false` to `AudioAnalysisService.Options`. Change the `evaluateMLIfActive` capability narrowing from `if let diag = ml as? MLDiagnosticTechnique, options.enableTrace` to `if let diag = ml as? MLDiagnosticTechnique, options.enableMLDiagnostics`. Update the `mlDiagnosticSnapshot` doc-comment on `BPMDiagnosticTrace` to reflect the new gate. Add a unit test asserting (a) `enableMLDiagnostics == false` produces `trace.mlDiagnosticSnapshot == nil` even when ML is active, and (b) `enableMLDiagnostics == true` produces non-nil snapshot.
- [x] [Review][Patch] **P18: Split silent-skip branches into `mlNotRun` and `diagnosticSnapshotMissing` buckets** [Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:598-630] — From D2 (Codex Option B refinement). Replace the two `bucketKey = ""` paths: the `trace == nil` branch sets `bucketKey = "mlNotRun"`; the trace-exists-but-no-snapshot branch sets `bucketKey = "diagnosticSnapshotMissing"`. Remove the `if !bucketKey.isEmpty` guard. Add both bucket names to the histogram's expected-keys whitelist. Conservation `histogramSum == allRows.count` now holds unconditionally; the two new bucket counts surface in the JSON report. Update any test fixtures or schema docs that enumerate failure-stage keys.
- [x] [Review][Patch] **P19: Run + commit Story 4-6 impact-report + threshold-sweep JSONs** [_bmad-output/perf-baselines/bnns-impact/ + _bmad-output/implementation-artifacts/4-6-threshold-sweep.json] — From D3. Run `make bnns-impact-report` producing one fingerprint-named JSON at default (production) thresholds; then run the 7-point threshold sweep at the DD #5 threshold pairs (0.00/0.00, 0.25/0.05, 0.40/0.08, 0.50/0.10, 0.55/0.12, 0.60/0.15, 0.65/0.20 — or whichever 7 pairs DD #5 specifies, re-read at run time). Commit all artifacts. Verify Completion Notes' numeric claims (ml_acc1, softmax_max_p95, wrong_non_abstain_count, controls preserved) match the JSON-emitted values; fix the narrative if mismatched.
- [x] [Review][Patch] **P20: Author `AudioAnalysisServiceInoutTraceTests.swift`** [Tests/BoomBoomBoomKitTests/AudioAnalysisServiceInoutTraceTests.swift (new)] — From D4. Two tests: (1) `inoutTraceMutationAfterCancellation` — set up an `MLDiagnosticTechnique` mock that returns a valid `(MLEvaluation?, MLDiagnosticSnapshot)` tuple but with `isCancelled` flipping true between the evaluate call and the post-evaluate cancellation check; assert that `evaluateMLIfActive` throws `CancellationError` AND `trace.mlDiagnosticSnapshot == nil` after the throw (mutation never happened). (2) `inoutTraceMutationOnWinPath` — same mock, `isCancelled` returns false throughout; assert that the snapshot is written to the trace's `mlDiagnosticSnapshot` field. Use an injected mock conformer; do not require BNNS or a model file.

#### Deferred (real but out-of-scope or pre-existing)

- [x] [Review][Defer] **`MLDiagnosticSnapshot` public init traps via `precondition`** [Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift:179-239] — deferred, intentional design per DD #2 (revised). The validating-init pattern is the explicit choice over `throws`. However, the precondition matrix is hostile to BYOW consumers constructing snapshots manually. Worth revisiting in a future API-ergonomics story. (Claude BH + Codex.)
- [x] [Review][Defer] **FNV-1a checksum claims "same across machines" but hashes native host bytes** [Sources/BoomBoomBoomKitML/BNNSTechnique.swift:444-455] — deferred, pre-existing scope. The doc-comment overstates cross-arch portability — across Apple Silicon hosts (the realistic parity target) the contract holds; cross-arch (x86 vs ARM64) it does not. Tighten doc-comment in a docs pass. (Codex.)
- [x] [Review][Defer] **Doc-comment cites non-existent test `inoutTraceMutationAfterCancellation`** [Sources/BoomBoomBoomKit/AudioAnalysisService.swift:287] — deferred, fix when D4 (missing `AudioAnalysisServiceInoutTraceTests.swift` decision) is resolved. (Claude BH.)
- [x] [Review][Defer] **`dnbControl(for:)` prefix matcher is loose** [Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:1866-1870] — deferred, practical risk is zero (no `foo.wav.bak` files in the corpus). Tighten to exact-match in a future hardening pass. (Claude BH.)

#### Dismissed (false positive, authorized, or out-of-scope noise)

- `BNNSTechniqueDiagnosticTests` suite-wide `.disabled(if: bundledModelMissing())` — authorized under Branch C; suite re-activates under a future Branch-A retrain story.
- Schema bump v2 → v3 — authorized by user to conform with `running-benchmarks` skill workflow.
- Output location moved to `_bmad-output/perf-baselines/bnns-impact/` — authorized by user.
- Acceptance Auditor's DD #12 HALT-(h) test count violation — based on miscount; actual count is 469, not 415.
- Edge Case Hunter NaN/Inf/denormal/subnormal float input theoretical paths — dismissed; featurize `>= 32` frame gate + finite-isfinite guards block realistic paths.
- Edge Case Hunter future-SDK paranoia (`withMemoryRebound` capacity drift, `BNNS_MAX_TENSOR_DIMENSION` changes, signal-handler reentrance) — dismissed as future-SDK speculation; not actionable now.
- Claude BH "`BPMResult` reconstructed via positional args" — dismissed; per project Options-struct pattern memory, that pattern applies to public service methods, not internal `BPMResult` construction.
