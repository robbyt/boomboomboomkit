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
    /// ``EnsembleCombiner`` alongside the DSP winner; the resulting BPM and
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
    /// | Use library's bundled reference model | `Options.mlTechnique = try? BNNSTechnique()` |
    /// | Use your converted weights, same architecture | `Options.mlTechnique = try? BNNSTechnique(modelURL: myURL)` |
    /// | Use a custom architecture or different framework | `Options.mlTechnique = MyCustomMLTechnique()` |
    ///
    /// See `tools/coreml-convert/README.md` for the consumer-onboarding
    /// flow that converts PyTorch / Core ML weights against the bundled
    /// tensor contract.
    ///
    /// Slot reserved by Story 3-3a per ADR-11 (Options-first public configuration).
    public var mlTechnique: (any MLTechnique)?

    /// Strategy for combining candidates across analysis windows (default: `.maxConfidence`).
    /// Only applies at intensity 6+ where multiple windows are analyzed.
    public var mergeStrategy: CandidateMergeStrategy = .maxConfidence

    /// Resolution policy used when ``mergeStrategy`` is
    /// ``CandidateMergeStrategy/windowVoting``. Has no effect for any other
    /// strategy. Default ``VotingPolicy/simpleMajority`` reproduces the
    /// post-Story-3-3a baseline byte-for-byte. See ``VotingPolicy`` for the
    /// per-case semantics.
    public var votingPolicy: VotingPolicy = .simpleMajority

    /// Acceptance threshold for ``VotingPolicy/thresholdGated`` (range
    /// `[0.0, 1.0]`). Out-of-range values silently clamp; non-finite values
    /// (NaN, ±Infinity, signaling NaN) silently fall back to `0.0`. Has no
    /// effect when ``votingPolicy`` is not ``VotingPolicy/thresholdGated``,
    /// or when ``mergeStrategy`` is not ``CandidateMergeStrategy/windowVoting``.
    /// Default `0.0` makes the gate permissive (equivalent to
    /// ``VotingPolicy/simpleMajority``) so a benchmark sweep can dial up the
    /// threshold without recompiling.
    public var votingThreshold: Double = 0.0

    /// Resolution policy for the DSP+ML ensemble combiner (Story 4.4).
    ///
    /// Selects how ``EnsembleCombiner/combine(dspWinner:mlEvaluation:policy:)``
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
      || (options.mlTechnique != nil && options.ensemblePolicy != .dspOnly)

    let pre = try Self.runPreCorroborationPipeline(
      url: url, options: options, enableTrace: shouldBuildTrace)
    guard let merged = pre.result else { return nil }

    // Story 3.6: post-merge metadata corroboration. Runs unconditionally so
    // single-window paths (intensity 1-5, where `merge` short-circuits) still
    // get the corroboration pass.
    let (corroborated, evidence) = MetadataCorroborator.apply(
      to: merged, input: pre.metadataInput)

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
    let mlEvaluation = try Self.evaluateMLIfActive(
      options: options, trace: corroborated.trace)
    let combined = EnsembleCombiner.combine(
      dspWinner: corroborated,
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
  private static func evaluateMLIfActive(
    options: Options, trace: BPMDiagnosticTrace?
  ) throws -> MLEvaluation? {
    guard options.ensemblePolicy != .dspOnly,
      let ml = options.mlTechnique,
      let trace
    else { return nil }
    if options.isCancelled() { throw CancellationError() }
    let evaluation = ml.evaluate(trace: trace)
    if options.isCancelled() { throw CancellationError() }
    return evaluation
  }

  // MARK: - Story 4.4: ML ensemble combiner promoted to EnsembleCombiner.swift

  // The internal `combine(dspWinner:mlEvaluation:)` helper that lived here in
  // Story 4.3 has been promoted to ``EnsembleCombiner/combine(dspWinner:mlEvaluation:policy:)``.
  // The call site now lives inline in ``analyzeBPM(url:options:)`` (above)
  // alongside the A1 short-circuit IIFE that decides whether ML inference
  // runs at all.

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
    let result: BPMResult?
    let metadataInput: MetadataCorroborationInput
  }

  /// Runs the full pre-corroboration sequence in production order:
  /// cancellation check → metadata read → duration read → PCM read →
  /// window loop with cancellation/progress → ``CandidateMergeStrategy/merge``.
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
      && options.ensemblePolicy != .dspOnly

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
          samples: samples, sampleRate: sampleRate,
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

    // Merge candidates across windows using the selected strategy.
    let merged = CandidateMergeStrategy.merge(
      windowResults: windowResults,
      candidateCount: resolvedTechniqueSet.candidateCount,
      strategy: options.mergeStrategy,
      votingPolicy: options.votingPolicy,
      votingThreshold: options.votingThreshold)

    return PreCorroborationOutput(result: merged, metadataInput: metadataInput)
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

  /// Measures integrated loudness per ITU-R BS.1770-5.
  /// Returns the integrated loudness in LUFS, or nil for silence/too-short/unsupported sample rate.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - maxSeconds: Maximum seconds of audio to analyze (default: 30).
  /// - Returns: Integrated loudness in LUFS, or `nil` for silence, too-short, or unsupported input.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read.
  public static func analyzeLUFS(
    url: URL,
    maxSeconds: Double = 30
  ) throws -> Double? {
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
      from: url, maxSeconds: maxSeconds
    )
    return LUFSAnalyzer.measureLoudness(
      samples: samples, sampleRate: sampleRate
    )?.integratedLoudness
  }
}
