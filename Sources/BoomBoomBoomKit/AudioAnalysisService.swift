//
//  AudioAnalysisService.swift
//  BoomBoomBoomKit
//
//  Stateless service coordinating PCM read + BPM analysis.
//  Zero coupling to MediaDiffCore types.
//  Allowed imports: Foundation only (uses PCMBufferReader and BPMAnalyzer from same module).
//

import Foundation

/// Result of audio analysis containing BPM and confidence.
public struct AudioAnalysisResult: Sendable {
  /// Estimated tempo in beats per minute.
  public let bpm: Double
  /// Confidence score (0.0 - 1.0) indicating reliability of the estimate.
  public let confidence: Double
  /// Top candidates pre-disambiguation (for benchmark analysis).
  public let candidates: [(bpm: Double, score: Float)]
  /// Diagnostic trace capturing per-step pipeline state. Nil unless `enableTrace` was true.
  public let trace: BPMDiagnosticTrace?
  /// Per-source observations from file-metadata corroboration. Empty when
  /// ``AudioAnalysisService/Options/metadataPolicy`` is ``MetadataPolicy/disabled``,
  /// or when no enabled tag formats were present in the file. One entry is emitted
  /// per parsed tag — including parse-phase and corroboration rejections — so callers
  /// can audit which tags were read and what the library did with them.
  public let metadataEvidence: [MetadataBPMEvidence]
  /// The effective DSP-level depth reported for this analysis.
  ///
  /// Equals ``AudioAnalysisService/Options/intensity`` for requests in 1-7 (DSP-only
  /// range) and for requests in 8-10 when ``AudioAnalysisService/Options/mlTechnique``
  /// is non-nil. When intensity 8-10 is requested without an ``MLTechnique``
  /// conformance, this is reported as ``AnalysisIntensity/default`` (7) and
  /// ``degradationReason`` carries the explanation.
  ///
  /// Note: today the pipeline runs at the requested intensity unchanged — levels 8-10
  /// currently produce identical DSP output to level 7 by switch-default coincidence
  /// in ``AnalysisIntensity``; future stories may change level 8-10 semantics, in
  /// which case this field will continue to report what was effectively achieved.
  public let effectiveIntensity: AnalysisIntensity
  /// A display-oriented explanation when the requested intensity was not honoured
  /// (e.g., when 8-10 was requested but no ``MLTechnique`` conformance was supplied).
  /// `nil` when no degradation occurred.
  ///
  /// Today's message format is `"Requested intensity \(requested) requires
  /// BoomBoomBoomKitML package. Running at intensity \(effective) (DSP-only)."` —
  /// this exact text is asserted by Story 4.2's regression tests, but consumers
  /// should treat it as display text; pre-1.0 / no-BC framing allows wording revision
  /// in a future story.
  ///
  /// **For control flow, do NOT string-parse this field — call
  /// ``AudioAnalysisService/maximumSupportedIntensity(mlTechnique:)`` BEFORE
  /// analysis to query whether the configuration supports the requested intensity.**
  public let degradationReason: String?
}

/// Stateless service that coordinates PCM reading and BPM estimation.
public struct AudioAnalysisService {

  /// Single source of truth for the DSP-only intensity ceiling. Intensities
  /// 8-10 are reserved for ML augmentation; without an ``MLTechnique``
  /// conformance the effective ceiling is ``AnalysisIntensity/default`` (7).
  /// Reused by ``analyzeBPM(url:options:)``, the degradation message builder,
  /// and ``maximumSupportedIntensity(mlTechnique:)``.
  private static let dspOnlyMaxIntensity: AnalysisIntensity = .default

  /// Configuration options for BPM analysis.
  ///
  /// All fields have sensible defaults. Use `Options()` and mutate as needed:
  /// ```swift
  /// var opts = AudioAnalysisService.Options()
  /// opts.intensity = .fastest
  /// ```
  ///
  /// **Field-style convention.** Non-optional fields are always-present configuration
  /// with a sensible default (e.g., `intensity`, `mergeStrategy`, `votingPolicy`,
  /// `votingThreshold`, `maxSeconds`, `enableTrace`, `durationHint`,
  /// `durationHintMinFileSeconds`). Optional fields (`techniqueSet`, `mlTechnique`,
  /// `onProgress`) are opt-in features: callers explicitly opt in by setting a non-nil
  /// value; `nil` means "use the existing default behavior" or "feature inactive". See
  /// ADR-11 (_bmad-output/planning-artifacts/architecture.md) for the Options-first
  /// public configuration policy.
  public struct Options: Sendable {
    /// Maximum seconds of audio to read from the file (default: 120).
    /// This caps the PCM buffer size, not the analysis window. The pipeline
    /// performs energy scan on this buffer to find the musical onset, then
    /// takes analysis windows (30s/60s/90s) from that point. The default of
    /// 120s covers ~30s of intro headroom plus the longest 90s analysis window.
    public var maxSeconds: Double = 120

    /// Analysis intensity level (default: `.default`, which is level 7).
    /// Controls pipeline depth: which DSP stages run, how many candidates
    /// are considered, and whether progressive retry across multiple windows is used.
    /// See ``techniqueSet`` to override the intensity-derived technique set with a
    /// specific ``TechniqueSet`` (e.g., a public preset like ``TechniqueSet/clickAugmented``).
    public var intensity: AnalysisIntensity = .default

    /// Optional override of the technique set derived from ``intensity``.
    ///
    /// When non-nil, this `TechniqueSet` is used directly by the pipeline and the
    /// intensity-derived technique set is ignored. When `nil` (default), the technique
    /// set is derived from ``intensity`` (e.g., ``AnalysisIntensity/default`` resolves
    /// to ``TechniqueSet/optimal``).
    ///
    /// Use this to opt into public presets that no intensity level maps to —
    /// e.g., ``TechniqueSet/clickAugmented`` for click-track rescoring on top of
    /// the optimal pipeline. ``intensity`` is still consulted for window sizes and
    /// progressive-retry threshold, so window behavior remains intensity-driven.
    public var techniqueSet: TechniqueSet?

    /// Optional ML technique consulted post-pipeline to refine the DSP estimate.
    ///
    /// When non-`nil` AND ``ensemblePolicy`` is not ``EnsemblePolicy/dspOnly``,
    /// the pipeline runs as usual and the resulting populated
    /// ``BPMDiagnosticTrace`` (with DSP candidates carried in
    /// ``BPMDiagnosticTrace/candidatesAfterBoost``) is passed to
    /// ``MLTechnique/evaluate(trace:)`` for an alternative estimate. The
    /// ``MLEvaluation?`` return value flows through the internal
    /// inlined ensemble combiner alongside the DSP winner; the resulting BPM and
    /// confidence depend on ``ensemblePolicy``. When `nil` (default), the
    /// feature is inactive and the DSP result is returned unchanged.
    ///
    /// **Story 4.4 A1 short-circuit.** Under
    /// ``EnsemblePolicy/dspOnly`` (the default policy), setting `mlTechnique`
    /// has NO effect: ``MLTechnique/evaluate(trace:)`` is NOT invoked, and the
    /// ML-feeding ``BPMDiagnosticTrace`` branch is NOT constructed internally
    /// (`shouldBuildTrace` falls back to ``enableTrace`` alone). To exercise
    /// `mlTechnique`, pair it with ``EnsemblePolicy/mlOnly`` or
    /// ``EnsemblePolicy/highestConfidence``.
    ///
    /// **Public-trace gating.** The internal ML-feeding trace and the public
    /// ``AudioAnalysisResult/trace`` are distinct: the public surface stays
    /// gated by ``enableTrace`` regardless of `mlTechnique` or
    /// ``ensemblePolicy``. Set ``enableTrace`` to `true` if you want the
    /// trace (and any attached ``EnsembleDecision``) returned to your caller.
    ///
    /// **Story 4-5 BYOW selection (DD #19).** Consumers pick exactly one
    /// of the four ML options below; there is no implicit fallback or
    /// precedence chain.
    ///
    /// | Consumer intent | Code |
    /// |---|---|
    /// | Disable ML entirely (default — DSP-only) | `Options.mlTechnique = nil` |
    /// | Use a bundled reference model | _no bundled model ships as of Story 4-6; see `MODEL_CARD.md` for the Branch C close-out rationale. `try? BNNSTechnique()` returns nil because the no-arg form throws `.modelResourceMissing`_ |
    /// | Use your converted weights, same architecture | `Options.mlTechnique = try? BNNSTechnique(modelURL: myURL)` |
    /// | Use a custom architecture or different framework | `Options.mlTechnique = MyCustomMLTechnique()` |
    ///
    /// See `tools/coreml-convert/README.md` for the consumer-onboarding
    /// flow that converts PyTorch / Core ML weights against the same
    /// tensor contract `BNNSTechnique` validates at `init(modelURL:)`.
    ///
    /// Slot reserved by Story 3-3a per ADR-11 (Options-first public configuration).
    public var mlTechnique: (any MLTechnique)?

    /// Strategy for combining candidates across analysis windows (default: `.maxConfidence`).
    /// Only applies at intensity 6+ where multiple windows are analyzed.
    public var mergeStrategy: BPMSelectionPolicy = .maxConfidence

    /// Resolution policy used when ``mergeStrategy`` is
    /// ``BPMSelectionPolicy/windowVoting``. Has no effect for any other
    /// strategy. Default ``VotingPolicy/simpleMajority`` reproduces the
    /// post-Story-3-3a baseline byte-for-byte. See ``VotingPolicy`` for the
    /// per-case semantics.
    public var votingPolicy: VotingPolicy = .simpleMajority

    /// Acceptance threshold for ``VotingPolicy/thresholdGated`` (range
    /// `[0.0, 1.0]`). Out-of-range values silently clamp; non-finite values
    /// (NaN, ±Infinity, signaling NaN) silently fall back to `0.0`. Has no
    /// effect when ``votingPolicy`` is not ``VotingPolicy/thresholdGated``,
    /// or when ``mergeStrategy`` is not ``BPMSelectionPolicy/windowVoting``.
    /// Default `0.0` makes the gate permissive (equivalent to
    /// ``VotingPolicy/simpleMajority``) so a benchmark sweep can dial up the
    /// threshold without recompiling.
    public var votingThreshold: Double = 0.0

    /// Resolution policy for the DSP+ML ensemble combiner (Story 4.4).
    ///
    /// Selects how ``AudioAnalysisService/combineEnsemble(dspWinner:mlEvaluation:policy:)``
    /// reconciles the post-corroboration DSP candidate with an optional
    /// ``MLEvaluation`` from ``mlTechnique``. Always-present configuration
    /// per ADR-11 (`_bmad-output/planning-artifacts/architecture.md`) — the
    /// field is non-optional with a sensible default and is mutated rather
    /// than threaded as a method parameter on
    /// ``analyzeBPM(url:options:)``.
    ///
    /// Default ``EnsemblePolicy/dspOnly`` is operation-inert: when this
    /// policy is selected, ``MLTechnique/evaluate(trace:)`` is NOT invoked
    /// even if ``mlTechnique`` is non-nil (Story 4-4 short-circuit at the
    /// call site). This makes the configuration `Options.mlTechnique != nil`
    /// + `Options.ensemblePolicy = .dspOnly` valid for users who load a model
    /// but want to disable the ensemble per-call without dropping the model.
    /// Output is byte-identical to the no-ML pipeline under this default.
    ///
    /// Set ``EnsemblePolicy/mlOnly`` or ``EnsemblePolicy/highestConfidence``
    /// to opt into ML-influenced final BPM. See ``EnsemblePolicy`` for the
    /// per-case selection logic and the tag-bias caveat on
    /// ``EnsemblePolicy/highestConfidence``.
    public var ensemblePolicy: EnsemblePolicy = .dspOnly

    /// When `true`, populates `result.trace` with per-step diagnostic data.
    public var enableTrace: Bool = false

    /// When `true`, the service routes ``mlTechnique`` calls through the
    /// ``MLDiagnosticTechnique`` capability path (when the conformer
    /// adopts it) and writes the resulting ``MLDiagnosticSnapshot`` to
    /// ``BPMDiagnosticTrace/mlDiagnosticSnapshot``.
    ///
    /// **Default `false`** — opt-in feature. ML diagnostics surface
    /// inference internals (decoded BPM, softmax probabilities, input
    /// feature checksum, abstain-path categorization) that the
    /// `BNNSImpactTests` harness consumes for threshold sweeps. Production
    /// consumers can leave this off; setting it has no functional effect
    /// beyond populating the trace field.
    ///
    /// **Independent of ``enableTrace``.** This flag controls whether
    /// the diagnostic capability path runs and writes a snapshot;
    /// ``enableTrace`` controls whether the entire ``BPMDiagnosticTrace``
    /// is surfaced on ``AudioAnalysisResult/trace`` at all. With
    /// ``enableMLDiagnostics == true`` and ``enableTrace == false``, the
    /// snapshot is constructed internally for ensemble decision-making
    /// but is not externally visible.
    ///
    /// Story 4-6 code review P17: split out of ``enableTrace`` because
    /// the previous wiring tied snapshot visibility to a trace flag
    /// whose name didn't say "ML diagnostics" — two paths to the same
    /// conformer with different observability gated by a flag with
    /// misleading naming.
    public var enableMLDiagnostics: Bool = false

    /// When `true` (default), the duration-derived BPM hint runs at step 9.7 of the BPM
    /// pipeline.
    ///
    /// Auto-reads the file duration via `AVAudioFile` metadata (cheap, sub-millisecond)
    /// and boosts DSP candidates that match common bar-count-derived BPMs by 10%.
    /// Weak corroborative prior — never damps unmatched candidates. Default-on per
    /// ADR-11 because the cost is negligible and the no-regression gate (Story 3-4 AC #4)
    /// guards accuracy on OA300 and GiantSteps.
    ///
    /// Setting to `false` skips both the metadata read AND the boost — bytewise-equivalent
    /// to the pre-Story-3-4 pipeline (validated by Story 3-4 AC #5).
    public var durationHint: Bool = true

    /// Minimum file duration (seconds) below which the duration-derived BPM hint
    /// is suppressed. Default 180 (3 minutes).
    ///
    /// Bar-count math (`bars * 4 * 60 / fileDurationSeconds`) only produces structurally
    /// plausible BPMs when the file IS the full song — clips, loops, and previews
    /// violate that assumption (a 60-second clip of a 4-minute song has 32 bars of a
    /// 192-bar work, not 32 bars total). Below the threshold the hint is skipped so
    /// the boost cannot reinforce octave errors driven by partial-song duration math.
    ///
    /// 180 seconds reflects "very few dance songs are shorter than 3 minutes" and was
    /// added in response to a measured AC #4 GiantSteps regression at the pre-threshold
    /// values (the GiantSteps Tempo Dataset's 30-120s clips fail the structural
    /// assumption). Lower this to a smaller value if your audio includes legitimate
    /// short tracks where you still want the hint to fire.
    public var durationHintMinFileSeconds: Double = 180

    /// File-metadata corroboration policy (Story 3.6).
    ///
    /// Default ``MetadataPolicy/default`` reads embedded BPM tags from MP4/M4A
    /// (`tmpo`), MP3/AIFF (ID3v2 `TBPM`), and FLAC (Vorbis `BPM=`), then boosts
    /// or penalizes DSP candidates per the corroboration / consensus rules.
    /// All file I/O is direct container parsing — AVFoundation is never
    /// consulted for metadata.
    ///
    /// Set ``MetadataPolicy/disabled`` for byte-identical pre-Story-3.6
    /// behavior: zero file-metadata I/O beyond the existing PCM read, no
    /// merge-stage boost, empty ``AudioAnalysisResult/metadataEvidence``.
    public var metadataPolicy: MetadataPolicy = .default

    /// Closure checked before each analysis window. When it returns `true`,
    /// the analysis throws `CancellationError`. Defaults to `Task.isCancelled`,
    /// giving automatic structured-concurrency support.
    /// Inject a custom closure for deterministic testing.
    public var isCancelled: @Sendable () -> Bool = { Task.isCancelled }

    /// Called before each window begins analysis. Receives a ``ProgressUpdate``
    /// with `windowsCompleted` (0-based) and `windowsTotal`. `nil` by default
    /// (no overhead when unused).
    public var onProgress: (@Sendable (ProgressUpdate) -> Void)?

    public init() {}
  }

  /// Analyzes the BPM of an audio file with default options.
  ///
  /// Cancellation is supported automatically via `Task.isCancelled` (the default
  /// in ``Options/isCancelled``). When the parent task is cancelled, the analysis
  /// throws `CancellationError` between window iterations.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  /// - Returns: An `AudioAnalysisResult` with BPM and confidence, or `nil`
  ///   for silence, too-short input, or non-musical content.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read.
  ///   `CancellationError` if the task is cancelled.
  public static func analyzeBPM(
    url: URL
  ) throws -> AudioAnalysisResult? {
    try analyzeBPM(url: url, options: .init())
  }

  /// Analyzes the BPM of an audio file using intensity-controlled progressive analysis.
  ///
  /// Checks ``Options/isCancelled`` before the PCM read and before each analysis
  /// window. If cancellation is detected, throws `CancellationError` — previously
  /// completed window results are discarded (no partial results).
  ///
  /// When ``Options/onProgress`` is non-nil, it is called before each window with
  /// a ``ProgressUpdate`` reporting `windowsCompleted` (0-based) and `windowsTotal`.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - options: Configuration controlling read length, intensity, merge strategy,
  ///     cancellation, progress, and tracing.
  /// - Returns: An `AudioAnalysisResult` with BPM and confidence, or `nil`
  ///   for silence, too-short input, or non-musical content.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read.
  ///   `CancellationError` if cancelled via `options.isCancelled`.
  public static func analyzeBPM(
    url: URL,
    options: Options
  ) throws -> AudioAnalysisResult? {
    // Story 4.3 + ADR-6 reconciled by Story 4.4 DD #2: trace is built when
    // `mlTechnique != nil` AND the selected policy can consume the
    // evaluation. Under `.dspOnly` the trace ML branch is moot because
    // `MLTechnique.evaluate(trace:)` is short-circuited below — building the
    // trace there would be wasted work and would also create the false
    // expectation that ML inference is running.
    let shouldBuildTrace =
      options.enableTrace
      || (options.mlTechnique != nil && options.ensemblePolicy.invokesMLInference)

    let pre = try Self.runPreCorroborationPipeline(
      url: url, options: options, enableTrace: shouldBuildTrace)

    // Story 6.5b (KDD-A6 Stage 3): Phase 1 (cross-window aggregation) + Phase 2a
    // (pool-authoritative multiplicative metadata corroboration) collapse into a
    // single pool-consuming entry point — `BPMSelectionPolicy.select(from:)`. The
    // former `merge → weave pool entries → MetadataCorroborator.apply` chain is
    // gone; the authoritative `UnifiedSignalPool` (built unconditionally in
    // `runPreCorroborationPipeline`) is the selection input. Empty pool → nil
    // (FR-8 / DD #7). `weights.fileMetadata` scales the corroboration strength
    // (DD #2); for every non-`weightedVoting`/`default` policy it resolves to
    // `1.0`, byte-reproducing the pre-6.5b corroboration.
    let resolvedWeights = Self.resolveWeights(options.ensemblePolicy)
    guard
      let selection = options.mergeStrategy.select(
        from: pre.pool,
        weights: resolvedWeights,
        votingPolicy: options.votingPolicy,
        votingThreshold: options.votingThreshold)
    else { return nil }
    let corroborated = selection.result
    let evidence = selection.evidence

    // Story 4-5 / DD #11 / AC #9: ML evaluation runs AFTER metadata
    // corroboration via a private throws helper that checks cancellation
    // BEFORE calling evaluate. Replaces the Story 4-4 IIFE-`guard` shape
    // because the IIFE couldn't `throw CancellationError()` cleanly while
    // returning `MLEvaluation?`. Story 4-4 AC #14 invariant
    // (`RecordingMockMLTechnique.callCount == 0` on `.dspOnly`) is
    // preserved by the helper's first guard, which returns nil before
    // binding `ml` (so `evaluate(trace:)` is unreachable when ML is off).
    // Resolves the `deferred-work.md` cancellation entry filed at Story
    // 4-3 close-out.
    //
    // Story 4-6 AC #4: helper signature is `trace: inout BPMDiagnosticTrace?`
    // so the diagnostic snapshot from ``MLDiagnosticTechnique`` conformers
    // is written back to the trace under STRICT mutation-after-cancellation
    // ordering. `BPMResult.trace` is a `let` field on the corroborated
    // struct, so we pull it into a local `var` and reconstruct the result
    // post-helper. Single-window paths and DSP-only short-circuit return
    // identical bytes — the trace is unchanged on those paths.
    var localTrace = corroborated.trace
    let mlEvaluation = try Self.evaluateMLIfActive(
      options: options, trace: &localTrace)
    let corroboratedWithSnapshot = corroborated.with(trace: localTrace)
    // Phase 2b: cross-signal ML fusion + KDD-A5 weighted resolution. Weights are
    // derived from the policy inside `combineEnsemble` (same `resolveWeights`
    // mapping Phase 2a used for the corroboration scale).
    let combined = Self.combineEnsemble(
      dspWinner: corroboratedWithSnapshot,
      mlEvaluation: mlEvaluation,
      policy: options.ensemblePolicy)

    // Story 4.2: post-pipeline reporting of effective intensity + degradation
    // reason. Computed AFTER both `runPreCorroborationPipeline` and
    // `MetadataCorroborator.apply` return — pure reporting, no DSP mutation.
    let effective = computeEffectiveIntensity(
      requested: options.intensity, mlTechnique: options.mlTechnique)
    let reason = degradationMessage(
      requested: options.intensity, effective: effective)

    return AudioAnalysisResult(
      bpm: combined.bpm, confidence: combined.confidence,
      candidates: combined.candidates,
      trace: options.enableTrace ? combined.trace : nil,
      metadataEvidence: evidence,
      effectiveIntensity: effective, degradationReason: reason)
  }

  // MARK: - Story 4.2: effective intensity reporting + maximum supported query

  /// Returns the effective DSP-level depth for a (requested intensity,
  /// ML technique) pair. Caps requests in 8-10 to ``dspOnlyMaxIntensity``
  /// when no ``MLTechnique`` conformance is supplied; otherwise returns
  /// the requested intensity unchanged.
  private static func computeEffectiveIntensity(
    requested: AnalysisIntensity, mlTechnique: (any MLTechnique)?
  ) -> AnalysisIntensity {
    if requested.rawValue <= dspOnlyMaxIntensity.rawValue { return requested }
    if mlTechnique != nil { return requested }
    return dspOnlyMaxIntensity
  }

  /// Returns a display-oriented degradation message when ``requested`` was
  /// not honoured (i.e., ``effective`` is the DSP-only cap), or `nil` when
  /// no degradation occurred. Uses the integer `rawValue` of each intensity
  /// so the message does NOT leak named-constant identifiers (`.thorough`,
  /// `.maximum`) into developer-facing text.
  private static func degradationMessage(
    requested: AnalysisIntensity, effective: AnalysisIntensity
  ) -> String? {
    if requested == effective { return nil }
    return
      "Requested intensity \(requested.rawValue) requires BoomBoomBoomKitML "
      + "package. Running at intensity \(effective.rawValue) (DSP-only)."
  }

  // MARK: - Story 4.5: Cancellation cooperation helper

  /// Story 4-5 / DD #11 / AC #9 — evaluates `options.mlTechnique` against
  /// `trace` only when ML is active (policy != `.dspOnly` AND
  /// `mlTechnique != nil` AND a trace was built), with cancellation
  /// checks on either side of the call that throw `CancellationError`
  /// instead of quietly running expensive inference on a cancelled task
  /// or returning a stale ML evaluation to a caller that has already
  /// given up.
  ///
  /// **ML-only cancellation checkpoint.** The policy/ml/trace guard
  /// fires FIRST. When the helper would not run `evaluate(trace:)`
  /// anyway — because `.dspOnly` is set, no trace was built, or no
  /// technique is wired up — the function returns `nil` silently
  /// regardless of cancellation state. Cancellation is observed only on
  /// the path that would actually call `evaluate(trace:)`. This preserves
  /// Story 4-4 AC #14's `RecordingMockMLTechnique.callCount == 0`
  /// invariant on `.dspOnly` and avoids surfacing cancellation noise to
  /// callers who deliberately opted out of the ML pipeline phase.
  ///
  /// Cancellation latency contract (axiom-concurrency audit + Story 4-5
  /// review pass v3). Two checks bracket `ml.evaluate(trace:)`:
  ///
  /// 1. **Pre-evaluate check** — fires before any inference work runs.
  /// 2. **Post-evaluate check** — fires after `evaluate(trace:)` returns
  ///    so that cancellation flipping DURING the atomic call still
  ///    surfaces to the caller. The ML evaluation is discarded if
  ///    cancellation was observed; the caller sees `CancellationError`
  ///    just as if the entire call had been pre-empted.
  ///
  /// The helper still does NOT thread a cancellation closure into the
  /// conformance — BNNSGraph inference is atomic from the consumer's
  /// perspective. A cancelled task will wait the full inference wall-
  /// clock (50-1000 ms) before observing cancellation. ADR-1's per-
  /// window granularity is satisfied (checks fire BEFORE each window
  /// AND BEFORE+AFTER each evaluate call); finer mid-inference
  /// cancellation is documented as deferred-work.
  ///
  /// **Story 4-6 — diagnostic snapshot via capability-protocol narrowing.**
  /// When the active ``MLTechnique`` conformer ALSO adopts
  /// ``MLDiagnosticTechnique`` (Story 4-6's bundled ``BNNSTechnique``
  /// does), the helper routes the call through
  /// ``MLDiagnosticTechnique/evaluateWithDiagnostic(trace:)`` and writes
  /// the returned ``MLDiagnosticSnapshot?`` into
  /// ``BPMDiagnosticTrace/mlDiagnosticSnapshot`` on the inout trace.
  /// Consumer-supplied plain ``MLTechnique`` types that do NOT adopt
  /// the diagnostic capability fall back to the original
  /// ``MLTechnique/evaluate(trace:)`` path and leave the trace field
  /// nil — documented as `wontfix pre-1.0` (forwarding wrappers must
  /// re-conform to ``MLDiagnosticTechnique`` if they want diagnostics).
  ///
  /// **STRICT mutation-after-cancellation ordering (AC #4 revised; Codex
  /// finding #4).** The evaluation runs into LOCALS first; the
  /// post-evaluate cancellation check fires BEFORE any trace mutation;
  /// only on the no-cancellation path does the snapshot get written.
  /// A cancellation observed AFTER `evaluate` returned but BEFORE the
  /// snapshot landed produces `CancellationError` from this helper with
  /// `trace.mlDiagnosticSnapshot` left at whatever the caller passed in
  /// (nil for a fresh trace). The
  /// ``AudioAnalysisServiceInoutTraceTests/inoutTraceMutationAfterCancellation``
  /// test locks this ordering.
  ///
  /// The capability narrowing additionally requires
  /// ``Options/enableMLDiagnostics`` to be `true` (Story 4-6 code
  /// review P17; was ``Options/enableTrace`` pre-review). Splitting
  /// the gate out of `enableTrace` resolved the second-route
  /// observability hole where two paths to the same conformer used
  /// different observability — and `enableTrace`'s name didn't
  /// signal that flipping it turned ML diagnostics on/off. Now
  /// ``enableTrace`` governs whether the trace itself is returned to
  /// the caller; ``enableMLDiagnostics`` governs whether the snapshot
  /// is written into it. The two are independent.
  private static func evaluateMLIfActive(
    options: Options, trace: inout BPMDiagnosticTrace?
  ) throws -> MLEvaluation? {
    guard options.ensemblePolicy.invokesMLInference,
      let ml = options.mlTechnique,
      let unwrappedTrace = trace
    else { return nil }
    if options.isCancelled() { throw CancellationError() }
    // Evaluate into locals — NO trace mutation yet (Codex finding #4
    // strict ordering).
    let localEvaluation: MLEvaluation?
    let localSnapshot: MLDiagnosticSnapshot?
    if let diag = ml as? MLDiagnosticTechnique, options.enableMLDiagnostics {
      let result = diag.evaluateWithDiagnostic(trace: unwrappedTrace)
      localEvaluation = result.evaluation
      localSnapshot = result.snapshot
    } else {
      localEvaluation = ml.evaluate(trace: unwrappedTrace)
      localSnapshot = nil
    }
    // Post-evaluate cancellation check BEFORE any trace mutation. A
    // cancellation flipping at this point throws CancellationError; the
    // snapshot is discarded so the caller never sees a stale snapshot
    // stranded in a trace it has already given up on.
    if options.isCancelled() { throw CancellationError() }
    // Mutation strictly last — only on the no-cancellation path. Story
    // 4-6 code review P5: write BOTH branches so the trace field
    // always reflects THIS evaluation. Previously a non-diagnostic
    // conformer (or the plain `evaluate(trace:)` fallback) left
    // `localSnapshot == nil` and skipped the mutation, which meant a
    // caller reusing a trace across two evaluations could observe a
    // snapshot from the FIRST eval persisting through the second.
    // Trace doc-comment promises "most recent evaluation"; the explicit
    // nil write upholds that contract.
    var mutableTrace = unwrappedTrace
    mutableTrace.mlDiagnosticSnapshot = localSnapshot
    trace = mutableTrace
    return localEvaluation
  }

  // MARK: - Story 6.4 (KDD-A6 Stage 3, Part 1): ML ensemble combiner (inlined)

  /// Combines the post-corroboration DSP winner with an optional ML evaluation
  /// under the supplied policy, producing the final ``BPMResult``.
  ///
  /// Inlined verbatim from the removed `EnsembleCombiner.combine` (Story 6.4 /
  /// KDD-A6 Stage 3, Part 1): the standalone ensemble-arbiter type was removed
  /// to collapse the post-merge boundary by one stage. The logic is
  /// byte-identical; this is a testable seam (the former `EnsembleCombiner`
  /// unit suites drive it via `@testable import`). The genuine fold of ensemble
  /// selection into the unified pool (`select(from: pool)`) lands in Story 6.5.
  ///
  /// ## Sanitization (two independent sentinels)
  /// Non-finite ML `bpm` (NaN, ±∞) abstains to DSP (`mlAbstained: true`);
  /// finite-but-out-of-range `bpm` clamps to `60.0...200.0`. Non-finite
  /// `confidence` collapses to `0.0` (does NOT abstain); out-of-range clamps to
  /// `0.0...1.0`. The two sentinels are independent.
  ///
  /// ## EnsembleDecision matrix
  /// `ensembleDecision != nil` iff ``MLTechnique/evaluate(trace:)`` returned a
  /// non-nil ``MLEvaluation``. The rule applies at this seam's output; the
  /// public ``AudioAnalysisResult/trace`` is independently gated by
  /// ``Options/enableTrace``. The `.dspOnly` branch never consults
  /// `mlEvaluation` (HALT-(b) guard) and attaches no decision.
  ///
  /// ## Tag-bias caveat (`.highestConfidence`)
  /// `dspWinner.confidence` may already have been boosted to the `0.95` ceiling
  /// (``MetadataPolicy/maxBoostedConfidence``) by metadata corroboration before
  /// reaching this seam. Comparing it raw against ML confidence biases toward
  /// DSP on tag-corroborated tracks (Story 4.4 DD #6 surfaced the risk but did
  /// not mitigate — re-open trigger is the Story 6.5 pool-vote re-expression,
  /// where this comparison becomes a `.present`/`.demoted` vote rather than a
  /// raw confidence compare).
  static func combineEnsemble(
    dspWinner: BPMResult,
    mlEvaluation: MLEvaluation?,
    policy: EnsemblePolicy
  ) -> BPMResult {
    switch policy {
    case .dspOnly:
      // HALT (b) guard: DSP-only must not consult `mlEvaluation`. The DSP winner
      // carries unchanged; no decision attached. Byte-identical to Story 4-3's
      // default-DSP-wins behavior.
      _ = mlEvaluation
      return dspWinner

    case .default, .weightedVoting:
      // KDD-A5 (Story 6.5b): pool-authoritative weighted resolution — the live
      // activation of the two cases Story 6.5a shipped inert. The DSP voice is
      // the Phase-1-aggregated, Phase-2a-corroborated candidate; the ML voice
      // participates only when a technique ran (``EnsemblePolicy/invokesMLInference``
      // is true for these cases). Winner is the higher
      // `effectiveVote = confidence × weights[source]` (KDD-A3); DSP wins ties
      // (deterministic tiebreak). `.default` uses ``SignalWeights/default``
      // (equal weighting — the balanced peer ensemble); `.weightedVoting(w)`
      // uses `w`. Emits ``EnsembleWeightResolution`` (NOT ``EnsembleDecision``).
      //
      // Weights are derived from the policy here (`.weightedVoting(w)` → `w`;
      // `.default` → equal) rather than passed in — the policy is the single
      // source of truth, so a caller cannot drift a `weights:` argument from the
      // policy's own ``SignalWeights`` payload (Story 6.5b code-review).
      let weights = Self.resolveWeights(policy)
      //
      // BOTH votes sanitize their confidence (non-finite → 0, clamp to [0,1])
      // before weighting — symmetric handling so a non-finite/out-of-range DSP
      // confidence cannot poison the comparison (Story 6.5b code-review HIGH;
      // defense-in-depth — the corroboration confidence is already floored).
      // Identity for the normal finite-[0,1] case.
      let dspVote = sanitizeEnsembleConfidence(dspWinner.confidence) * weights.dsp
      guard let ml = mlEvaluation, ml.bpm.isFinite else {
        // No ML voice (no technique wired up, or non-finite ML bpm abstains):
        // the DSP voice carries unchanged.
        let resolution = EnsembleWeightResolution(
          policyKey: policy.stableKey, weights: weights,
          dspEffectiveVote: dspVote, mlEffectiveVote: nil,
          winner: .dsp, selectedBPM: dspWinner.bpm)
        return dspWinner.with(
          trace: weightResolutionTrace(resolution: resolution, base: dspWinner.trace))
      }
      let clampedBPM = clampEnsembleBPM(ml.bpm)
      let mlConf = sanitizeEnsembleConfidence(ml.confidence)
      let mlVote = mlConf * weights.ml
      if mlVote > dspVote {
        let resolution = EnsembleWeightResolution(
          policyKey: policy.stableKey, weights: weights,
          dspEffectiveVote: dspVote, mlEffectiveVote: mlVote,
          winner: .ml, selectedBPM: clampedBPM)
        return dspWinner.with(
          bpm: clampedBPM, confidence: mlConf,
          trace: weightResolutionTrace(resolution: resolution, base: dspWinner.trace))
      } else if mlVote == dspVote {
        let resolution = EnsembleWeightResolution(
          policyKey: policy.stableKey, weights: weights,
          dspEffectiveVote: dspVote, mlEffectiveVote: mlVote,
          winner: .tie, selectedBPM: dspWinner.bpm)
        return dspWinner.with(
          trace: weightResolutionTrace(resolution: resolution, base: dspWinner.trace))
      } else {
        let resolution = EnsembleWeightResolution(
          policyKey: policy.stableKey, weights: weights,
          dspEffectiveVote: dspVote, mlEffectiveVote: mlVote,
          winner: .dsp, selectedBPM: dspWinner.bpm)
        return dspWinner.with(
          trace: weightResolutionTrace(resolution: resolution, base: dspWinner.trace))
      }

    case .mlOnly:
      guard let ml = mlEvaluation else {
        return dspWinner
      }
      // Non-finite bpm → sentinel abstain to DSP.
      guard ml.bpm.isFinite else {
        let decision = EnsembleDecision(
          policy: .mlOnly, winner: .dsp,
          dspConfidence: dspWinner.confidence,
          mlConfidence: nil, mlAbstained: true,
          selectedBPM: dspWinner.bpm)
        return dspWinner.with(trace: ensembleTrace(decision: decision, base: dspWinner.trace))
      }
      let clampedBPM = clampEnsembleBPM(ml.bpm)
      let mlConf = sanitizeEnsembleConfidence(ml.confidence)
      let decision = EnsembleDecision(
        policy: .mlOnly, winner: .ml,
        dspConfidence: dspWinner.confidence,
        mlConfidence: mlConf, mlAbstained: false,
        selectedBPM: clampedBPM)
      return dspWinner.with(
        bpm: clampedBPM, confidence: mlConf,
        trace: ensembleTrace(decision: decision, base: dspWinner.trace))

    case .highestConfidence:
      guard let ml = mlEvaluation else {
        return dspWinner
      }
      guard ml.bpm.isFinite else {
        let decision = EnsembleDecision(
          policy: .highestConfidence, winner: .dsp,
          dspConfidence: dspWinner.confidence,
          mlConfidence: nil, mlAbstained: true,
          selectedBPM: dspWinner.bpm)
        return dspWinner.with(trace: ensembleTrace(decision: decision, base: dspWinner.trace))
      }
      let clampedBPM = clampEnsembleBPM(ml.bpm)
      let mlConf = sanitizeEnsembleConfidence(ml.confidence)
      // Compare confidences. DSP wins ties (deterministic tiebreak).
      if mlConf > dspWinner.confidence {
        let decision = EnsembleDecision(
          policy: .highestConfidence, winner: .ml,
          dspConfidence: dspWinner.confidence,
          mlConfidence: mlConf, mlAbstained: false,
          selectedBPM: clampedBPM)
        return dspWinner.with(
          bpm: clampedBPM, confidence: mlConf,
          trace: ensembleTrace(decision: decision, base: dspWinner.trace))
      } else if mlConf == dspWinner.confidence {
        let decision = EnsembleDecision(
          policy: .highestConfidence, winner: .tie,
          dspConfidence: dspWinner.confidence,
          mlConfidence: mlConf, mlAbstained: false,
          selectedBPM: dspWinner.bpm)
        return dspWinner.with(trace: ensembleTrace(decision: decision, base: dspWinner.trace))
      } else {
        let decision = EnsembleDecision(
          policy: .highestConfidence, winner: .dsp,
          dspConfidence: dspWinner.confidence,
          mlConfidence: mlConf, mlAbstained: false,
          selectedBPM: dspWinner.bpm)
        return dspWinner.with(trace: ensembleTrace(decision: decision, base: dspWinner.trace))
      }
    }
  }

  /// Clamp a finite ML `bpm` to the DSP range-normalization window `60.0...200.0`.
  private static func clampEnsembleBPM(_ bpm: Double) -> Double {
    min(max(bpm, 60.0), 200.0)
  }

  /// Non-finite confidence collapses to `0.0`; finite-but-out-of-range clamps to `0.0...1.0`.
  private static func sanitizeEnsembleConfidence(_ c: Double) -> Double {
    guard c.isFinite else { return 0.0 }
    return min(max(c, 0.0), 1.0)
  }

  /// Returns a copy of `base` with `ensembleDecision` set, or `nil` when `base`
  /// is `nil` (no trace was built — nothing to attach to).
  private static func ensembleTrace(
    decision: EnsembleDecision, base: BPMDiagnosticTrace?
  ) -> BPMDiagnosticTrace? {
    guard var updated = base else { return nil }
    updated.ensembleDecision = decision
    return updated
  }

  /// Returns a copy of `base` with `ensembleWeightResolution` set, or `nil` when
  /// `base` is `nil` (no trace was built — the default path attaches nothing, so
  /// the weighted-policy output stays byte-identical to a DSP-wins resolution
  /// when no ML voice changed the winner). Story 6.5b / KDD-A5.
  private static func weightResolutionTrace(
    resolution: EnsembleWeightResolution, base: BPMDiagnosticTrace?
  ) -> BPMDiagnosticTrace? {
    guard var updated = base else { return nil }
    updated.ensembleWeightResolution = resolution
    return updated
  }

  /// Maximum analysis intensity supported by the current configuration.
  ///
  /// - Parameter mlTechnique: The ML technique that will be supplied via
  ///   ``Options/mlTechnique`` — pass `nil` to ask "what's the ceiling without
  ///   the BoomBoomBoomKitML package?" or pass a real conformance to ask
  ///   "what's the ceiling with my chosen ML model?"
  /// - Returns: ``AnalysisIntensity/default`` (7) when `mlTechnique` is `nil`;
  ///   ``AnalysisIntensity/maximum`` (10) when non-nil.
  public static func maximumSupportedIntensity(
    mlTechnique: (any MLTechnique)?
  ) -> AnalysisIntensity {
    mlTechnique == nil ? dspOnlyMaxIntensity : .maximum
  }

  // MARK: - Story 3-6b: pre-corroboration pipeline (test-shareable)

  /// Captured output of the pre-corroboration pipeline: the merged DSP
  /// ``BPMResult`` plus the ``MetadataCorroborationInput`` that the
  /// production service hands to ``MetadataCorroborator/apply(to:input:)``.
  ///
  /// Returning both values together encodes the production orchestration
  /// order (cancellation → metadata read → duration → PCM → window loop →
  /// merge) as a structural invariant — a future refactor that reordered
  /// cancellation or metadata I/O would be forced to break this signature
  /// rather than silently diverge from a hand-replicated copy.
  struct PreCorroborationOutput: Sendable {
    let metadataInput: MetadataCorroborationInput
    /// Story 6.5b (KDD-A6 Stage 3): the AUTHORITATIVE ``UnifiedSignalPool`` —
    /// the per-window DSP candidates, parsed metadata, and pre-computed ML
    /// participation that ``BPMSelectionPolicy/select(from:weights:equivalence:votingPolicy:votingThreshold:)``
    /// consumes. Built UNCONDITIONALLY (authoritative, not nil on the default
    /// path); Phase 1 (`merge`) now runs inside `select`, not in this helper.
    let pool: UnifiedSignalPool
  }

  /// Runs the full pre-corroboration sequence in production order:
  /// cancellation check → metadata read → duration read → PCM read →
  /// window loop with cancellation/progress → ``BPMSelectionPolicy/merge``.
  ///
  /// Called by ``analyzeBPM(url:options:)`` for production AND by the
  /// disabled-policy bitPattern regression test in
  /// `MetadataCorroborationTests.swift`. Single source of truth for the
  /// pre-corroboration pipeline ordering invariant — the disabled-policy
  /// test asserts that production output matches this helper byte-for-byte
  /// (`bitPattern` equality of `bpm`, `confidence`, and per-candidate
  /// fields), so any future refactor that diverges the production path
  /// from this helper's output is loud rather than silent.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - options: Configuration controlling read length, intensity, merge,
  ///     cancellation, and progress.
  ///   - enableTrace: Whether ``BPMAnalyzer`` should populate a
  ///     ``BPMDiagnosticTrace`` for each window. Computed by the caller
  ///     (Story 4.3, ADR-6: trace is forced on whenever
  ///     ``Options/mlTechnique`` is non-nil so ``MLTechnique`` always
  ///     receives a populated trace) — the helper does not consult
  ///     ``Options/enableTrace`` directly so that pre-corroboration code
  ///     stays free of post-corroboration concerns.
  /// - Returns: ``PreCorroborationOutput`` carrying the merged DSP
  ///   candidate (nil for silence/too-short/no-result) and the metadata
  ///   input destined for ``MetadataCorroborator/apply(to:input:)``.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read.
  ///   `CancellationError` if cancelled via `options.isCancelled`.
  static func runPreCorroborationPipeline(
    url: URL, options: Options, enableTrace: Bool
  ) throws -> PreCorroborationOutput {
    // Early cancellation check — avoid ~10MB PCM read on pre-cancelled calls.
    if options.isCancelled() { throw CancellationError() }

    // Story 3.6: read embedded BPM tags once, before the PCM read. Empty-source
    // policy (e.g., `.disabled`) short-circuits to zero file-metadata I/O.
    let metadataInput = buildMetadataInput(
      url: url, policy: options.metadataPolicy)

    // Story 3-4: read the file duration once (cheap AVAudioFile metadata open) so the
    // BPM pipeline can compute structurally-plausible bar-count BPMs at step 9.7.
    // `try?` swallows the throw — graceful degradation if the file briefly fails the
    // duration read (AC #3b). `flatMap { $0.isFinite && $0 > 0 ? $0 : nil }` collapses
    // both the zero-length contract AND non-finite metadata (`+Inf` / `NaN`) to nil so
    // the analyzer skips the hint cleanly. Finiteness gate from code-review Patch #3.
    let fileDurationSeconds: Double? =
      options.durationHint
      ? (try? PCMBufferReader.fileDuration(url: url))
        .flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
      : nil

    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
      from: url, maxSeconds: options.maxSeconds
    )
    // Story 8-2 commit 1: wrap in the DecodedAudio currency with placeholder
    // provenance (carrier-only — nothing downstream branches on it). The
    // content-true codec tagging arrives with the `decodeOnce` funnel /
    // `readDecodedAudio` producer in the seam commit.
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .unknown, trimState: .unknown))

    // Resolve the technique set once: explicit override wins, otherwise derive from
    // intensity. BPMAnalyzer.estimateBPM repeats this resolution internally, but we need
    // the resolved set here for `candidateCount` so the merge step matches what the
    // pipeline actually extracted.
    let resolvedTechniqueSet = options.techniqueSet ?? options.intensity.techniqueSet

    // Story 4-5 / AC #4 / DD #4: capture log-mel features for `MLTechnique.evaluate`
    // ONLY when the trace will actually feed an ML conformance. Mirror of the
    // `shouldBuildTrace` predicate at the analyzeBPM call site so the DSP-only
    // path stays bit-exact to pre-Story-4.5 (HALT (e) byte-identity contract).
    let captureMLFeatures =
      enableTrace
      && options.mlTechnique != nil
      && options.ensemblePolicy.invokesMLInference

    // Collect results from all windows.
    var windowResults: [BPMResult] = []
    let windowSizes = options.intensity.windowSizes
    let total = windowSizes.count
    var completed = 0

    for windowSeconds in windowSizes {
      if options.isCancelled() { throw CancellationError() }
      options.onProgress?(ProgressUpdate(windowsCompleted: completed, windowsTotal: total))

      guard
        let bpmResult = BPMAnalyzer.estimateBPM(
          decoded: decoded,
          options: .init(
            analysisWindowSeconds: windowSeconds,
            intensity: options.intensity,
            techniqueSet: options.techniqueSet,
            enableTrace: enableTrace,
            fileDurationSeconds: fileDurationSeconds,
            durationHintMinFileSeconds: options.durationHintMinFileSeconds,
            captureMLFeatures: captureMLFeatures)
        )
      else {
        completed += 1
        continue
      }

      windowResults.append(bpmResult)
      completed += 1

      // Non-progressive intensities (1-5): single window, break immediately.
      if options.intensity.progressiveThreshold == nil {
        break
      }
    }

    // Story 6.5b (KDD-A6 Stage 3): build the AUTHORITATIVE UnifiedSignalPool —
    // the per-window DSP candidates, the parsed metadata signal, and the
    // pre-computed ML participation that `BPMSelectionPolicy.select(from:)`
    // consumes. Phase 1 (`merge`) now runs INSIDE `select`, so this helper no
    // longer merges; it bundles the raw selection inputs. Built unconditionally
    // (authoritative, not nil on the default path).
    //
    // ML participation is options-derived: `.absent` when no technique is wired
    // up or the selected policy does not invoke ML; otherwise an
    // `ml-eval-deferred` abstain (W48 named constant; ML inference runs
    // post-selection to preserve the no-accuracy-change ordering, so it has not
    // run at pool-construction time).
    let mlParticipation: SignalParticipation =
      (options.mlTechnique == nil || !options.ensemblePolicy.invokesMLInference)
      ? .absent
      : .abstained(.sourceSpecific(AbstainReason.mlEvalDeferred))
    let pool = UnifiedSignalPool(
      dspWindows: windowResults,
      metadataInput: metadataInput,
      candidateCount: resolvedTechniqueSet.candidateCount,
      mlParticipation: mlParticipation,
      weight: 1.0)

    return PreCorroborationOutput(metadataInput: metadataInput, pool: pool)
  }

  // MARK: - Story 6.5b: weight resolution (KDD-A5)

  /// Resolves the per-source ``SignalWeights`` for the selected policy. Only
  /// ``EnsemblePolicy/weightedVoting(_:)`` carries an explicit weight set; every
  /// other policy resolves to ``SignalWeights/default`` (all `1.0`), so Phase 2a
  /// corroboration scales by `fileMetadata == 1.0` (byte-reproducing the pre-6.5b
  /// corroboration) and Phase 2b weighted resolution treats DSP and ML equally.
  static func resolveWeights(_ policy: EnsemblePolicy) -> SignalWeights {
    switch policy {
    case .weightedVoting(let weights):
      return weights
    case .default, .dspOnly, .mlOnly, .highestConfidence:
      return .default
    }
  }

  // MARK: - Story 3.6: metadata read + consensus

  /// Reads embedded BPM tags from `url` and computes the consensus signal
  /// passed to ``MetadataCorroborator/apply(to:input:)``. Skips I/O entirely
  /// when no source is enabled.
  private static func buildMetadataInput(
    url: URL, policy: MetadataPolicy
  ) -> MetadataCorroborationInput {
    if policy.enabledSources.isEmpty {
      return MetadataCorroborationInput(
        consensusBPM: nil, participatingTags: [],
        conflictDetected: false, policy: policy)
    }
    let foundTags = FileMetadataReader.readTags(from: url, policy: policy)
    if foundTags.isEmpty {
      return MetadataCorroborationInput(
        consensusBPM: nil, participatingTags: [],
        conflictDetected: false, policy: policy)
    }

    // Build initial evidence (parse-phase outcome only).
    let initialEvidence: [MetadataBPMEvidence] = foundTags.map { t in
      MetadataBPMEvidence(
        source: t.source, rawValue: t.rawString,
        parsedBPM: t.parsedBPM, corroboratedWith: nil,
        ratioMatched: nil, boostApplied: 1.0,
        rejectionReason: t.rejectionReason)
    }

    // Compute consensus from valid (non-rejected) tags.
    let validValues = initialEvidence.compactMap { e -> Double? in
      e.rejectionReason == nil ? e.parsedBPM : nil
    }
    let consensusBPM: Double?
    let conflictDetected: Bool
    if validValues.count >= 2 {
      let lo = validValues.min() ?? 0
      let hi = validValues.max() ?? 0
      if hi - lo <= policy.consensusTolerance {
        // Unanimous within tolerance.
        let mean = validValues.reduce(0, +) / Double(validValues.count)
        consensusBPM = mean
        conflictDetected = false
      } else {
        consensusBPM = nil
        conflictDetected = true
      }
    } else {
      // 0 or 1 valid tag — single-tag (or all rejected).
      consensusBPM = nil
      conflictDetected = false
    }

    return MetadataCorroborationInput(
      consensusBPM: consensusBPM,
      participatingTags: initialEvidence,
      conflictDetected: conflictDetected,
      policy: policy)
  }

  /// Measures loudness per ITU-R BS.1770-5 / EBU R 128 and returns a
  /// chart-ready ``LUFSReport``: integrated loudness, max true-peak
  /// (BS.1770-5 Annex 2), loudness range (EBU Tech 3342 §3.1), and
  /// momentary/short-term time series on the shared 100ms grid
  /// (EBU Tech 3341 §2.2).
  ///
  /// Analyzes the FULL file by default — integrated loudness is
  /// whole-programme by definition. Bound the cost via
  /// ``LUFSOptions/maxSeconds``.
  ///
  /// Nil-vs-throw contract: throwing means the measurement could not run
  /// (unreadable file, unsupported sample rate); `nil` means the audio was
  /// measured but produced no result (all-silence after gating, or input
  /// shorter than one 400ms gating block).
  ///
  /// Runs to completion — no cooperative cancellation in this entry point
  /// (decode dominates wall-clock; the DSP passes are O(n) vDSP). Cancellation
  /// plumbing arrives with Story 8.2's shared-decode orchestration.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - options: Analysis options (``LUFSOptions``); the default analyzes
  ///     the full file.
  /// - Returns: A ``LUFSReport``, or `nil` for silence or sub-400ms input.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read;
  ///   ``LUFSAnalysisError/unsupportedSampleRate(sampleRate:supported:)`` if
  ///   the decoded rate has no K-weighting coefficient set (44.1/48/96 kHz
  ///   are supported).
  public static func analyzeLUFS(
    url: URL,
    options: LUFSOptions = LUFSOptions()
  ) throws -> LUFSReport? {
    // Sanitize maxSeconds at the use site (the votingThreshold silently-clamp
    // precedent): non-finite, non-positive, or absurdly large values are
    // treated as nil (full file). Unsanitized, Int64(sampleRate * maxSeconds)
    // inside the reader traps on NaN/Inf/overflow. 1e9 s ≈ 31.7 years — far
    // above any real file, safely below Int64 overflow at any supported rate.
    let maxSeconds = options.maxSeconds.flatMap { value in
      value.isFinite && value > 0 && value < 1.0e9 ? value : nil
    }
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
      from: url, maxSeconds: maxSeconds
    )
    guard LUFSAnalyzer.supportedSampleRates.contains(sampleRate) else {
      throw LUFSAnalysisError.unsupportedSampleRate(
        sampleRate: sampleRate, supported: LUFSAnalyzer.supportedSampleRates)
    }
    // Story 8-2 commit 1: DecodedAudio currency with placeholder provenance
    // (see runPreCorroborationPipeline for the rationale).
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .unknown, trimState: .unknown))
    guard let result = LUFSAnalyzer.measureLoudness(decoded: decoded) else {
      return nil
    }
    return LUFSReport(
      integratedLUFS: result.integratedLoudness,
      maxTruePeakDBTP: result.maxTruePeakDBTP,
      loudnessRangeLU: result.loudnessRange,
      lraLowLUFS: result.lraLow,
      lraHighLUFS: result.lraHigh,
      momentaryLUFS: result.blockLoudnessValues,
      shortTermLUFS: result.shortTermLoudnessValues,
      stepSeconds: result.blockStepSeconds)
  }
}

// MARK: - Story 6.4 (W52): BPMResult value-type forwarding

extension BPMResult {
  /// Returns a copy of this result with the given fields overridden and the rest
  /// forwarded. `candidates` is always forwarded from `self`.
  ///
  /// Story 6.4 (W52): collapses the field-enumerating post-merge rebuild sites
  /// (the inlined ensemble combiner + the trace-snapshot rebuilds in
  /// ``AudioAnalysisService/analyzeBPM(url:options:)``) into one forwarding
  /// helper, so a future ``BPMResult`` field is not silently dropped at any
  /// rebuild site.
  func with(
    bpm newBPM: Double? = nil,
    confidence newConfidence: Double? = nil,
    trace newTrace: BPMDiagnosticTrace?
  ) -> BPMResult {
    BPMResult(
      bpm: newBPM ?? bpm,
      confidence: newConfidence ?? confidence,
      candidates: candidates,
      trace: newTrace)
  }
}
