//
//  AudioAnalysisService.swift
//  BoomBoomBoomKit
//
//  Stateless service coordinating PCM read + BPM analysis.
//  Zero coupling to MediaDiffCore types.
//  Allowed imports: Foundation only (uses PCMBufferReader and BPMAnalyzer from same module).
//

import Foundation
import Synchronization

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

  /// Returns a copy with `trace` replaced, every other field forwarded verbatim
  /// (ticket #71). Used by the combined ``AudioAnalysisService/analyze(url:options:)``
  /// path to stitch the beat-grid coverage pass's refinement / downbeat evidence
  /// onto the BPM result's trace, so `CombinedAnalysisResult.bpm.trace` carries it
  /// on every ``AudioAnalysisService/Options/beatGridCoverage``. A forwarder (not a
  /// field-enumerating re-init at the call site) so a future field is never
  /// silently dropped here (mirrors the ``BPMResult/with(bpm:confidence:trace:)``
  /// W52 pattern).
  func with(trace newTrace: BPMDiagnosticTrace?) -> AudioAnalysisResult {
    AudioAnalysisResult(
      bpm: bpm,
      confidence: confidence,
      candidates: candidates,
      trace: newTrace,
      metadataEvidence: metadataEvidence,
      effectiveIntensity: effectiveIntensity,
      degradationReason: degradationReason)
  }
}

/// Result of combined BPM + beat-grid analysis over a single shared decode
/// (Story 8.5, FR-35 / KDD-C4): the output of
/// ``AudioAnalysisService/analyze(url:options:)``.
///
/// Both raw tempos stay accessible — the full multi-window, metadata-corroborated
/// BPM (`bpm.bpm`) AND the beat grid's own tempo (`beatGrid?.estimatedTempo`) —
/// so a consumer that wants to reconcile an octave disagreement can do so from
/// the raw pair rather than only the collapsed ``BeatGrid/tempoAgreement`` enum.
///
/// **Scope: BPM + beat grid only — no LUFS** (DD #1). The consistency contract
/// relates the BPM and beat-grid stages; loudness is unrelated. For combined
/// loudness, decode once and call ``AudioAnalysisService/analyzeLUFS(decoded:options:)``
/// on the same carrier.
public struct CombinedAnalysisResult: Sendable {

  /// The full multi-window, metadata-corroborated BPM result (the same value
  /// ``AudioAnalysisService/analyzeBPM(url:options:)`` would return).
  public let bpm: AudioAnalysisResult

  /// The beat grid, or `nil` when the grid could not be tracked (the ``bpm``
  /// result is still present — BPM succeeded, the grid did not). When non-nil,
  /// its ``BeatGrid/tempoAgreement`` has been resolved against ``bpm``'s tempo.
  public let beatGrid: BeatGrid?

  public init(bpm: AudioAnalysisResult, beatGrid: BeatGrid?) {
    self.bpm = bpm
    self.beatGrid = beatGrid
  }
}

/// Independent outcomes from one shared URL decode of BPM/beat-grid and
/// loudness analysis.
///
/// Rhythmic analyzability and loudness measurability are intentionally
/// independent: a file with no BPM result can still have a usable loudness
/// report, while an unsupported loudness sample rate does not discard a BPM
/// and beat-grid result. Shared decode and cancellation failures still throw
/// from ``AudioAnalysisService/analyzeFull(url:options:lufsOptions:)``.
public struct FullAnalysisResult: Sendable {

  /// The BPM and beat-grid outcome, or `nil` when the BPM stage found no
  /// analyzable rhythmic content.
  public let bpmAndBeatGrid: CombinedAnalysisResult?

  /// The loudness outcome. A successful `nil` means loudness was measured but
  /// no report was available (for example, silence or sub-400ms input); a
  /// failure means only that loudness cannot measure this sample rate.
  public let loudness: Result<LUFSReport?, LUFSAnalysisError>

  public init(
    bpmAndBeatGrid: CombinedAnalysisResult?,
    loudness: Result<LUFSReport?, LUFSAnalysisError>
  ) {
    self.bpmAndBeatGrid = bpmAndBeatGrid
    self.loudness = loudness
  }
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
    ///
    /// Non-finite, non-positive, or absurdly large (≥ 1e9 s) values are
    /// sanitized to a FULL-FILE read (DD #3b, same rule as
    /// ``LUFSOptions/maxSeconds``) — never a trap and never an empty read.
    /// Callers computing a dynamic budget must not let it underflow to 0
    /// expecting a cheap call: pre-8.2 a non-positive cap read zero frames,
    /// post-8.2 it reads (and analyzes) the entire file.
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

    /// How much of the track the beat grid's *detected* ``BeatGrid/beats`` array
    /// covers (Story 8.5). Affects ``analyzeBeatGrid(url:options:)`` and the
    /// beat grid produced by ``analyze(url:options:)``; ignored by
    /// ``analyzeBPM(url:options:)`` / ``analyzeLUFS(url:options:)``.
    ///
    /// Default ``BeatGridCoverage/analysisWindow`` is the **cheap** path: the
    /// detected beats cover the BPM analysis window the pipeline already computed,
    /// at zero extra onset cost. The Rekordbox-style mid-track contract —
    /// ``BeatGrid/gridOrigin`` + ``BeatGrid/estimatedTempo`` — extrapolates the
    /// infinite grid drift-free on constant-tempo material regardless of this
    /// setting, so the default is what a beat-math consumer usually wants.
    ///
    /// ``BeatGridCoverage/window(seconds:)`` and ``BeatGridCoverage/fullTrack``
    /// trigger a second, coverage-length onset pass (O(track)); use them for
    /// waveform display or QA, not for sync math. ``BeatGridCoverage/fullTrack``
    /// is bounded by ``maxSeconds`` like every decode.
    public var beatGridCoverage: BeatGridCoverage = .analysisWindow

    /// Opt-in downbeat (bar-start) detection (Story 8.5a). Default `false` keeps
    /// ``BeatGrid/downbeats`` ``DownbeatResult/notAttempted`` and the BPM/beat-grid
    /// output byte-identical to 8.5. When `true`, ``analyzeBeatGrid(url:options:)``
    /// (both overloads) and the grid produced by ``analyze(url:options:)`` run a
    /// conservative, fixed-4/4 downbeat-phase estimator: ``BeatGrid/downbeats``
    /// becomes ``DownbeatResult/detected(estimate:)`` on a strong recurring accent
    /// (and ``BeatGrid/gridOrigin`` is repointed to the first downbeat with
    /// ``BeatGridAnchorSource/downbeat``), or ``DownbeatResult/noneDetected`` — an
    /// honest abstain — when the rhythmic evidence is weak. A wrong downbeat on a
    /// live deck is worse than no downbeat, so the estimator abstains rather than
    /// guess; gate bar-snap on `gridOrigin.source == .downbeat`. Ignored by
    /// ``analyzeBPM(url:options:)`` / ``analyzeLUFS(url:options:)``.
    public var detectDownbeats: Bool = false

    /// Which ``DownbeatStrategy`` places the bar phase when ``detectDownbeats`` is
    /// `true` (Story 8.11). Default ``DownbeatStrategy/metricalAccent`` reproduces
    /// the Story-8.5a estimator bit-for-bit; ``DownbeatStrategy/structuralDrop``
    /// anchors the downbeat to the track's main energy drop, and
    /// ``DownbeatStrategy/combined`` cross-validates the two. Ignored when
    /// ``detectDownbeats`` is `false` and by
    /// ``analyzeBPM(url:options:)`` / ``analyzeLUFS(url:options:)``.
    public var downbeatStrategy: DownbeatStrategy = .metricalAccent

    /// Locks the beat-grid tempo to an authoritative constant BPM instead of the
    /// tracker's measured tempo — see ``BeatGridTempoLock``. Default
    /// ``BeatGridTempoLock/off`` reproduces prior behavior byte-for-byte. Honored
    /// only on the combined ``analyze(url:options:)`` / ``analyze(decoded:options:)``
    /// path (which has the BPM-stage tempo); standalone
    /// ``analyzeBeatGrid(url:options:)`` ignores it. The target tempo is
    /// octave-normalized to the grid's tempo before it is applied, and a
    /// more-than-an-octave disagreement leaves the grid unlocked.
    public var beatGridTempoLock: BeatGridTempoLock = .off

    /// Opt-in continuous beat-grid tempo refinement (Story 8.10). Default `false`
    /// reproduces prior behavior byte-for-byte (the grid reports the coarse
    /// BPM-stage tempo). When `true`, the grid's ``BeatGrid/estimatedTempo`` is
    /// refined to sub-0.1-BPM precision by fitting a continuous interpolated
    /// onset-comb against the audio's own onset evidence (seeded by the BPM-stage
    /// tempo), guarded so the result is never worse than the seed — this removes
    /// the dominant beat-grid accuracy loss (a few-tenths-of-a-BPM rate error that
    /// accumulates into within-track drift over a multi-minute track).
    ///
    /// **Scope.** Honored by ``analyzeBeatGrid(url:options:)``,
    /// ``analyzeBPM(url:options:)`` (when `computeBeatGrid` is set internally),
    /// and the grid produced by ``analyze(url:options:)``. Because sub-0.1-BPM
    /// precision needs a long lever arm, the refit frequently abstains on the
    /// short default ``BeatGridCoverage/analysisWindow`` (~30 s) span and delivers
    /// its precision on ``BeatGridCoverage/window(seconds:)`` /
    /// ``BeatGridCoverage/fullTrack`` coverage.
    ///
    /// **Interaction with ``beatGridTempoLock`` (combined ``analyze`` path).** The
    /// lock is the explicit override and wins: a non-``BeatGridTempoLock/off`` lock
    /// REPLACES the auto-refined tempo. In particular ``BeatGridTempoLock/bpmStage``
    /// substitutes the COARSE stage BPM and DISCARDS the sub-0.1 precision (the
    /// refit becomes a no-op on output) — authoritatively, even when the refit moved
    /// the grid more than the 2% agreement band away from the stage tempo — while a
    /// ``BeatGridTempoLock/bpm(_:)`` with a non-finite/≤0/more-than-an-octave value
    /// is itself a no-op, leaving the refined tempo standing. ``BPMResult/bpm`` (`bpm.bpm`) is never affected — a
    /// consumer may legitimately observe `bpm.bpm != beatGrid.estimatedTempo`.
    public var refineBeatGridTempo: Bool = false

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
    try analyzeBPM(url: url, options: options, decodeObserver: nil)
  }

  /// Internal observer-threaded overload (Story 8-2 DD #9): the public
  /// method passes `decodeObserver: nil`; AC1's structural decode-count
  /// tests reach this seam via `@testable import`. The url path IS the
  /// funnel (DD #2): URL-bound signal gathering + `decodeOnce` + the SAME
  /// shared core (`preCorroborationCore` → `finishBPMAnalysis`) that
  /// ``analyzeBPM(decoded:options:)`` calls.
  static func analyzeBPM(
    url: URL,
    options: Options,
    decodeObserver: (@Sendable (FeatureSubstrate.DecodedAudio) -> Void)?
  ) throws -> AudioAnalysisResult? {
    let inputs = try urlBPMInputs(url: url, options: options)
    let decoded = try decodeOnce(
      url: url, maxSeconds: options.maxSeconds,
      isCancelled: options.isCancelled, observer: decodeObserver)
    let pre = try preCorroborationCore(
      decoded: decoded,
      metadataInput: inputs.metadataInput,
      fileDurationSeconds: inputs.fileDurationSeconds,
      options: options,
      enableTrace: shouldBuildTrace(options))
    return try finishBPMAnalysis(pre: pre, options: options)
  }

  /// Analyzes the BPM of already-decoded audio — the Story 8-2 shared-decode
  /// seam (KDD-C4). Pair with ``PCMBufferReader/readDecodedAudio(from:maxSeconds:)``
  /// and ``analyzeLUFS(decoded:options:)`` so combined analysis pays for the
  /// decode exactly once:
  ///
  /// ```swift
  /// let decoded = try PCMBufferReader.readDecodedAudio(from: url)
  /// let bpm = try AudioAnalysisService.analyzeBPM(decoded: decoded)
  /// let loudness = try AudioAnalysisService.analyzeLUFS(decoded: decoded)
  /// ```
  ///
  /// **URL-bound signals are absent on this path (DD #2, by design):**
  /// file-metadata corroboration never runs (no URL — `FileMetadataReader`
  /// has nothing to read; ``AudioAnalysisResult/metadataEvidence`` is always
  /// empty), and the duration-derived BPM hint is off
  /// (`fileDurationSeconds = nil`; it is NOT derived from `samples.count`,
  /// which would be wrong under a capped decode). Under
  /// ``Options/metadataPolicy`` `.disabled` and ``Options/durationHint``
  /// `false`, output is regression-locked equal to the url path on
  /// LPCM-payload and FLAC fixtures — verified by tests, not guaranteed by
  /// the platform (Apple documents no bit-stability contract for
  /// `AVAudioFile`).
  ///
  /// ``Options/maxSeconds`` applies as a prefix slice mirroring the reader's
  /// partial-read cap arithmetic bit-for-bit (DD #3b), so a capped analysis
  /// of a full decode equals an analysis of a capped decode on the locked
  /// fixture set (the locked path has no sample-rate conversion).
  ///
  /// Cancellation (``Options/isCancelled``) is checked before each analysis
  /// window — same semantics as the url path. Progress
  /// (``Options/onProgress``) fires before each window.
  ///
  /// - Parameters:
  ///   - decoded: Decoded mono PCM carrier, typically from
  ///     ``PCMBufferReader/readDecodedAudio(from:maxSeconds:)``.
  ///   - options: Same options as the url path; URL-bound fields
  ///     (`metadataPolicy`, `durationHint`) are inert here as documented.
  /// - Returns: An `AudioAnalysisResult`, or `nil` for silence, too-short
  ///   input, or non-musical content.
  /// - Throws: `CancellationError` if cancelled via `options.isCancelled`.
  public static func analyzeBPM(
    decoded: FeatureSubstrate.DecodedAudio,
    options: Options = .init()
  ) throws -> AudioAnalysisResult? {
    // Early checkpoint BEFORE the maxSeconds prefix slice — a pre-cancelled
    // call must not pay a potentially multi-MB prefix copy first (mirrors
    // the url path's pre-decode check and the LUFS decoded path's ordering).
    // The window loop re-checks before each window as on the url path.
    if options.isCancelled() { throw CancellationError() }
    // No URL → metadata can never participate; the empty input mirrors what
    // `buildMetadataInput` produces for a tag-free file.
    let emptyMetadata = MetadataCorroborationInput(
      consensusBPM: nil, participatingTags: [],
      conflictDetected: false, policy: options.metadataPolicy)
    let pre = try preCorroborationCore(
      decoded: applyCap(decoded, maxSeconds: options.maxSeconds),
      metadataInput: emptyMetadata,
      fileDurationSeconds: nil,
      options: options,
      enableTrace: shouldBuildTrace(options))
    return try finishBPMAnalysis(pre: pre, options: options)
  }

  /// Story 4.3 + ADR-6 reconciled by Story 4.4 DD #2: trace is built when
  /// `mlTechnique != nil` AND the selected policy can consume the
  /// evaluation. Under `.dspOnly` the trace ML branch is moot because
  /// `MLTechnique.evaluate(trace:)` is short-circuited in
  /// `finishBPMAnalysis` — building the trace there would be wasted work and
  /// would also create the false expectation that ML inference is running.
  private static func shouldBuildTrace(_ options: Options) -> Bool {
    options.enableTrace
      || (options.mlTechnique != nil && options.ensemblePolicy.invokesMLInference)
  }

  /// Post-pipeline half shared VERBATIM by the url and decoded paths
  /// (Story 8-2 DD #2 — one code path, so the trace-write / ML-trace /
  /// progress divergence class is shared behavior, not a reconciliation
  /// burden): pool selection → ML evaluation → ensemble combination →
  /// effective-intensity reporting → result assembly.
  private static func finishBPMAnalysis(
    pre: PreCorroborationOutput, options: Options
  ) throws -> AudioAnalysisResult? {
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
    if requested <= dspOnlyMaxIntensity { return requested }
    if mlTechnique != nil { return requested }
    return dspOnlyMaxIntensity
  }

  /// Returns a display-oriented degradation message when ``requested`` was
  /// not honoured (i.e., ``effective`` is the DSP-only cap), or `nil` when
  /// no degradation occurred. Uses the ordinal ``AnalysisIntensity/level`` of
  /// each intensity so the message does NOT leak named-constant identifiers
  /// (`.thorough`, `.maximum`) into developer-facing text.
  private static func degradationMessage(
    requested: AnalysisIntensity, effective: AnalysisIntensity
  ) -> String? {
    if requested == effective { return nil }
    return
      "Requested intensity \(requested.level) requires BoomBoomBoomKitML "
      + "package. Running at intensity \(effective.level) (DSP-only)."
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

  /// URL-derived BPM inputs gathered before a shared decode. Keeping these
  /// separate lets ``analyzeFull(url:options:lufsOptions:)`` preserve the URL
  /// path's metadata corroboration and duration hint while choosing a decode
  /// cap that satisfies both feature lanes.
  private struct URLBPMInputs: Sendable {
    let metadataInput: MetadataCorroborationInput
    let fileDurationSeconds: Double?
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
    url: URL, options: Options, enableTrace: Bool,
    decodeObserver: (@Sendable (FeatureSubstrate.DecodedAudio) -> Void)? = nil
  ) throws -> PreCorroborationOutput {
    let inputs = try urlBPMInputs(url: url, options: options)

    // Story 8-2 (DD #9 / AC1): the funnel — the only PCM decode on this path.
    let decoded = try decodeOnce(
      url: url, maxSeconds: options.maxSeconds,
      isCancelled: options.isCancelled, observer: decodeObserver)

    return try preCorroborationCore(
      decoded: decoded,
      metadataInput: inputs.metadataInput,
      fileDurationSeconds: inputs.fileDurationSeconds,
      options: options,
      enableTrace: enableTrace)
  }

  /// Gathers the URL-bound inputs that the BPM path needs before decoding.
  /// This is shared by the standalone URL entry and the full-analysis URL
  /// entry so their metadata and duration semantics remain identical.
  private static func urlBPMInputs(
    url: URL, options: Options
  ) throws -> URLBPMInputs {
    // Early cancellation check — avoid metadata I/O and a potentially large PCM read.
    if options.isCancelled() { throw CancellationError() }
    let metadataInput = buildMetadataInput(url: url, policy: options.metadataPolicy)
    let fileDurationSeconds: Double? =
      options.durationHint
      ? (try? PCMBufferReader.fileDuration(url: url))
        .flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
      : nil
    return URLBPMInputs(
      metadataInput: metadataInput, fileDurationSeconds: fileDurationSeconds)
  }

  /// Decode-agnostic half of the pre-corroboration pipeline, shared VERBATIM
  /// by the url path (via ``runPreCorroborationPipeline(url:options:enableTrace:decodeObserver:)``)
  /// and the decoded overload ``analyzeBPM(decoded:options:)`` — Story 8-2
  /// DD #2's "the url path IS the funnel". Window loop ordering
  /// (cancellation → progress → window) is unchanged from the pre-8.2
  /// production order.
  private static func preCorroborationCore(
    decoded: FeatureSubstrate.DecodedAudio,
    metadataInput: MetadataCorroborationInput,
    fileDurationSeconds: Double?,
    options: Options,
    enableTrace: Bool
  ) throws -> PreCorroborationOutput {
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

      // Non-progressive intensities (1-5, `progressiveThreshold == nil`): stop
      // after this first successful window. Progressive intensities (6-10, non-nil)
      // fall through and attempt every remaining window. The threshold's numeric
      // value is intentionally NOT consulted — only its nil-ness gates the loop.
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

  // MARK: - Story 8-2: decodeOnce funnel + decoded-path cap (DD #9 / DD #3b)

  /// The ONLY decode entry inside `AudioAnalysisService` (AC1d — grep-locked:
  /// no direct `readMonoSamples` call survives in this file). Checks
  /// cancellation immediately before the decode, decodes exactly once via
  /// ``PCMBufferReader/readDecodedAudio(from:maxSeconds:)``, and fires the
  /// internal `observer` once per actual decode (the AC1 structural-gate
  /// seam — public Options structs are untouched, DD #9).
  static func decodeOnce(
    url: URL,
    maxSeconds: Double?,
    isCancelled: @Sendable () -> Bool,
    observer: (@Sendable (FeatureSubstrate.DecodedAudio) -> Void)?
  ) throws -> FeatureSubstrate.DecodedAudio {
    if isCancelled() { throw CancellationError() }
    let decoded = try PCMBufferReader.readDecodedAudio(
      from: url, maxSeconds: maxSeconds)
    observer?(decoded)
    return decoded
  }

  /// Applies a `maxSeconds` prefix slice to an already-decoded carrier,
  /// mirroring the reader's partial-read cap arithmetic bit-for-bit via
  /// ``PCMBufferReader/cappedSampleCount(sampleRate:maxSeconds:totalSamples:)``
  /// (DD #3b — sanitization included). No-op (and no copy) when the cap
  /// meets or exceeds the sample count.
  private static func applyCap(
    _ decoded: FeatureSubstrate.DecodedAudio, maxSeconds: Double?
  ) -> FeatureSubstrate.DecodedAudio {
    let capped = PCMBufferReader.cappedSampleCount(
      sampleRate: decoded.sampleRate, maxSeconds: maxSeconds,
      totalSamples: decoded.samples.count)
    guard capped < decoded.samples.count else { return decoded }
    return FeatureSubstrate.DecodedAudio(
      samples: Array(decoded.samples.prefix(capped)),
      sampleRate: decoded.sampleRate,
      codecPriming: decoded.codecPriming)
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
  /// Supports cooperative cancellation via ``LUFSOptions/isCancelled``
  /// (default `Task.isCancelled`): checked before the decode and after the
  /// decode / before measurement. An in-flight measurement runs to
  /// completion (O(n) vDSP passes — service-level granularity only, same
  /// ADR-1 rationale as the BPM side's between-windows-only checks).
  ///
  /// For combined BPM + loudness analysis, decode once via
  /// ``PCMBufferReader/readDecodedAudio(from:maxSeconds:)`` and use
  /// ``analyzeLUFS(decoded:options:)`` — this url entry point pays its own
  /// decode.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - options: Analysis options (``LUFSOptions``); the default analyzes
  ///     the full file.
  /// - Returns: A ``LUFSReport``, or `nil` for silence or sub-400ms input.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read;
  ///   ``LUFSAnalysisError/unsupportedSampleRate(sampleRate:supported:)`` if
  ///   the decoded rate has no K-weighting coefficient set (44.1/48/96 kHz
  ///   are supported); `CancellationError` if cancelled via
  ///   ``LUFSOptions/isCancelled``.
  public static func analyzeLUFS(
    url: URL,
    options: LUFSOptions = LUFSOptions()
  ) throws -> LUFSReport? {
    try analyzeLUFS(url: url, options: options, decodeObserver: nil)
  }

  /// Internal observer-threaded overload (Story 8-2 DD #9) — same seam
  /// pattern as the BPM side; the public method passes `decodeObserver: nil`.
  ///
  /// Cancellation checkpoints (DD #8): before decode (inside ``decodeOnce``;
  /// a pre-cancelled call observes decode count 0) and after decode / before
  /// measurement. An in-flight measurement runs to completion.
  static func analyzeLUFS(
    url: URL,
    options: LUFSOptions,
    decodeObserver: (@Sendable (FeatureSubstrate.DecodedAudio) -> Void)?
  ) throws -> LUFSReport? {
    // DD #3b: the shared sanitize rule (PCMBufferReader.sanitizedMaxSeconds)
    // replaces 8-1's inline use-site sanitization. `decodeOnce` →
    // `readDecodedAudio` re-applies it idempotently; sanitizing here keeps
    // the rule visible at the service entry as well.
    let decoded = try decodeOnce(
      url: url,
      maxSeconds: PCMBufferReader.sanitizedMaxSeconds(options.maxSeconds),
      isCancelled: options.isCancelled,
      observer: decodeObserver)
    // Post-decode / pre-measurement checkpoint (DD #8).
    if options.isCancelled() { throw CancellationError() }
    return try lufsReport(decoded: decoded)
  }

  /// Measures loudness of already-decoded audio — the Story 8-2 shared-decode
  /// seam (KDD-C4). Pair with ``PCMBufferReader/readDecodedAudio(from:maxSeconds:)``
  /// and ``analyzeBPM(decoded:options:)`` so combined analysis pays for the
  /// decode exactly once (see ``analyzeBPM(decoded:options:)`` for the
  /// shared snippet).
  ///
  /// Same nil-vs-throw contract as the url path: throwing means the
  /// measurement could not run (unsupported sample rate), `nil` means the
  /// audio was measured but produced no result. ``LUFSOptions/maxSeconds``
  /// applies as a prefix slice mirroring the reader's cap arithmetic
  /// bit-for-bit (DD #3b). ``LUFSOptions/isCancelled`` is checked once,
  /// before measurement; an in-flight measurement runs to completion.
  ///
  /// - Parameters:
  ///   - decoded: Decoded mono PCM carrier, typically from
  ///     ``PCMBufferReader/readDecodedAudio(from:maxSeconds:)``.
  ///   - options: Analysis options; the default measures the full carrier.
  /// - Returns: A ``LUFSReport``, or `nil` for silence or sub-400ms input.
  /// - Throws: ``LUFSAnalysisError/unsupportedSampleRate(sampleRate:supported:)``
  ///   if `decoded.sampleRate` has no K-weighting coefficient set (44.1/48/96
  ///   kHz are supported); `CancellationError` if cancelled.
  public static func analyzeLUFS(
    decoded: FeatureSubstrate.DecodedAudio,
    options: LUFSOptions = LUFSOptions()
  ) throws -> LUFSReport? {
    // Pre-measurement checkpoint (DD #8) — the decoded path never decodes
    // (no URL parameter), so this is its only checkpoint.
    if options.isCancelled() { throw CancellationError() }
    return try lufsReport(decoded: applyCap(decoded, maxSeconds: options.maxSeconds))
  }

  /// Measurement core shared VERBATIM by the url and decoded LUFS paths:
  /// rate guard (throw = cannot measure) → analyzer (nil = measured, no
  /// result) → report assembly.
  private static func lufsReport(
    decoded: FeatureSubstrate.DecodedAudio
  ) throws -> LUFSReport? {
    guard LUFSAnalyzer.supportedSampleRates.contains(decoded.sampleRate) else {
      throw LUFSAnalysisError.unsupportedSampleRate(
        sampleRate: decoded.sampleRate,
        supported: LUFSAnalyzer.supportedSampleRates)
    }
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

  // MARK: - Full BPM, beat-grid, and loudness analysis

  /// Runs BPM, beat-grid, and loudness analysis from one shared URL decode.
  ///
  /// The result deliberately keeps the feature lanes independent: BPM can be
  /// absent while loudness succeeds, and an unsupported loudness sample rate is
  /// returned as ``FullAnalysisResult/loudness`` failure without discarding a
  /// BPM/grid result. URL-backed BPM metadata corroboration and duration hints
  /// remain active on this path.
  ///
  /// The decoder reads the union of the two requested caps (the full file when
  /// either cap is full), then each feature receives its own prefix cap before
  /// analysis. This gives the same feature-level cap semantics as the existing
  /// standalone APIs without decoding the file twice.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - options: BPM and beat-grid configuration.
  ///   - lufsOptions: Loudness configuration.
  /// - Returns: Independent BPM/grid and loudness outcomes from one decode.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read, or
  ///   `CancellationError` when either feature's cancellation closure fires.
  public static func analyzeFull(
    url: URL,
    options: Options = .init(),
    lufsOptions: LUFSOptions = LUFSOptions()
  ) throws -> FullAnalysisResult {
    try analyzeFull(
      url: url, options: options, lufsOptions: lufsOptions, decodeObserver: nil)
  }

  /// Internal observer-threaded overload for the shared-decode structural test.
  static func analyzeFull(
    url: URL,
    options: Options,
    lufsOptions: LUFSOptions,
    decodeObserver: (@Sendable (FeatureSubstrate.DecodedAudio) -> Void)?
  ) throws -> FullAnalysisResult {
    let isCancelled: @Sendable () -> Bool = {
      options.isCancelled() || lufsOptions.isCancelled()
    }
    var bpmOptions = options
    bpmOptions.isCancelled = isCancelled
    var loudnessOptions = lufsOptions
    loudnessOptions.isCancelled = isCancelled

    let inputs = try urlBPMInputs(url: url, options: bpmOptions)
    let decoded = try decodeOnce(
      url: url,
      maxSeconds: unionDecodeCap(options.maxSeconds, lufsOptions.maxSeconds),
      isCancelled: isCancelled,
      observer: decodeObserver)
    if isCancelled() { throw CancellationError() }

    let bpmCarrier = applyCap(decoded, maxSeconds: options.maxSeconds)
    let pre = try preCorroborationCore(
      decoded: bpmCarrier,
      metadataInput: inputs.metadataInput,
      fileDurationSeconds: inputs.fileDurationSeconds,
      options: bpmOptions,
      enableTrace: shouldBuildTrace(bpmOptions))
    let bpmAndBeatGrid: CombinedAnalysisResult?
    if let bpm = try finishBPMAnalysis(pre: pre, options: bpmOptions) {
      if isCancelled() { throw CancellationError() }
      bpmAndBeatGrid = try combineGridWithBPM(
        decoded: bpmCarrier, options: bpmOptions, bpm: bpm)
    } else {
      bpmAndBeatGrid = nil
    }

    if isCancelled() { throw CancellationError() }
    let loudness: Result<LUFSReport?, LUFSAnalysisError>
    do {
      loudness = .success(
        try lufsReport(
          decoded: applyCap(decoded, maxSeconds: loudnessOptions.maxSeconds)))
    } catch let error as LUFSAnalysisError {
      loudness = .failure(error)
    }
    // LUFS measurement itself is intentionally non-interruptible, matching the
    // standalone API. Honor a cancellation that arrived while it ran before
    // publishing this aggregate result.
    if isCancelled() { throw CancellationError() }
    return FullAnalysisResult(bpmAndBeatGrid: bpmAndBeatGrid, loudness: loudness)
  }

  /// The decode cap required to satisfy two independently-capped feature
  /// analyses. A nil/invalid cap means full-file decode, so it dominates.
  private static func unionDecodeCap(_ bpmCap: Double?, _ loudnessCap: Double?) -> Double? {
    let sanitizedBPM = PCMBufferReader.sanitizedMaxSeconds(bpmCap)
    let sanitizedLoudness = PCMBufferReader.sanitizedMaxSeconds(loudnessCap)
    guard let sanitizedBPM, let sanitizedLoudness else { return nil }
    return max(sanitizedBPM, sanitizedLoudness)
  }

  // MARK: - Story 8.4: beat-grid extraction

  /// Extracts a beat grid from an audio file — the public sibling of
  /// ``analyzeBPM(url:options:)`` and ``analyzeLUFS(url:options:)``.
  ///
  /// Runs the DSP BPM pipeline on a single analysis window with step-11 beat-grid
  /// extraction enabled, then returns the resulting ``BeatGrid``. The grid's
  /// ``BeatGrid/estimatedTempo`` is octave-locked to the tempo resolved for
  /// tracking *in this call*. Because that tempo comes from a single-window,
  /// DSP-only `BPMAnalyzer` pass — not the multi-window, metadata-corroborated
  /// ``analyzeBPM(url:options:)`` — it can differ from `analyzeBPM` on the same
  /// file, including by an octave; do not assume close agreement between the two.
  /// Beats carry decoded-PCM-relative ``BeatTimestamp/presentationTime`` (`t=0`
  /// is the decoded file start, energy-scan drop included, with no codec-priming
  /// subtraction — AVFoundation already removes declared priming; apply any
  /// output-latency or manual offset with ``BeatGrid/offset(by:)``) and a per-beat
  /// onset ``BeatTimestamp/strength``.
  ///
  /// **Standalone scope.** This entry does NOT compare against a BPM result, so
  /// ``BeatGrid/tempoAgreement`` is ``TempoAgreement/notCompared`` — use the
  /// combined ``analyze(url:options:)`` to get a resolved agreement. ``BeatGrid/downbeats``
  /// is ``DownbeatResult/notAttempted`` unless ``Options/detectDownbeats`` is set,
  /// in which case the conservative fixed-4/4 downbeat-phase estimator runs and the
  /// grid carries ``DownbeatResult/detected(estimate:)`` (``BeatGrid/gridOrigin``
  /// repointed to the first downbeat, ``BeatGridAnchorSource/downbeat``) or an
  /// honest ``DownbeatResult/noneDetected`` abstain. For continuous sync /
  /// sub-beat math, anchor on ``BeatGrid/gridOrigin`` + ``BeatGrid/estimatedTempo``
  /// rather than trusting every entry of ``BeatGrid/beats``.
  ///
  /// ``Options/beatGridCoverage`` controls what span the detected beats cover
  /// (default ``BeatGridCoverage/analysisWindow``, the cheap path).
  ///
  /// - Note: Assumes a **constant tempo**. The tracker does not detect or adapt
  ///   to tempo changes (accelerando, rubato, tempo-change sections); on
  ///   variable-tempo material the beats drift out of phase. Supply
  ///   constant-tempo audio for a meaningful grid.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - options: Analysis options; ``Options/intensity``,
  ///     ``Options/techniqueSet``, ``Options/maxSeconds``,
  ///     ``Options/beatGridCoverage``, and ``Options/isCancelled`` apply. URL-bound
  ///     and ensemble fields (`metadataPolicy`, `ensemblePolicy`, `mlTechnique`)
  ///     do not affect the grid.
  /// - Returns: A ``BeatGrid``, or `nil` for silence, too-short input, or
  ///   non-musical content (the same nil contract as ``analyzeBPM(url:options:)``).
  /// - Throws: `PCMBufferReaderError` if the file cannot be read;
  ///   `CancellationError` if cancelled via ``Options/isCancelled``.
  public static func analyzeBeatGrid(
    url: URL,
    options: Options = .init()
  ) throws -> BeatGrid? {
    try analyzeBeatGrid(url: url, options: options, decodeObserver: nil)
  }

  /// Internal observer-threaded overload (Story 8-2 DD #9 seam) — the public
  /// method passes `decodeObserver: nil`. Cancellation checkpoints mirror
  /// ``analyzeLUFS(url:options:decodeObserver:)``: before decode (inside
  /// ``decodeOnce``) and after decode / before analysis.
  static func analyzeBeatGrid(
    url: URL,
    options: Options,
    decodeObserver: (@Sendable (FeatureSubstrate.DecodedAudio) -> Void)?
  ) throws -> BeatGrid? {
    let decoded = try decodeOnce(
      url: url,
      maxSeconds: PCMBufferReader.sanitizedMaxSeconds(options.maxSeconds),
      isCancelled: options.isCancelled,
      observer: decodeObserver)
    // Post-decode / pre-analysis checkpoint.
    if options.isCancelled() { throw CancellationError() }
    return try beatGrid(decoded: decoded, options: options)
  }

  /// Extracts a beat grid from already-decoded audio — the Story 8-2
  /// shared-decode seam (KDD-C4). Pair with
  /// ``PCMBufferReader/readDecodedAudio(from:maxSeconds:)``,
  /// ``analyzeBPM(decoded:options:)``, and ``analyzeLUFS(decoded:options:)`` so
  /// combined analysis pays for the decode exactly once.
  ///
  /// ``Options/maxSeconds`` applies as a prefix slice mirroring the reader's cap
  /// arithmetic (DD #3b). ``Options/isCancelled`` is checked once, before
  /// analysis. See ``analyzeBeatGrid(url:options:)`` for scope, the anchor +
  /// tempo extrapolation contract, and ``Options/beatGridCoverage``.
  ///
  /// - Note: Assumes a **constant tempo** — see ``analyzeBeatGrid(url:options:)``.
  ///   Variable-tempo material (accelerando, rubato, tempo-change sections) is
  ///   not tracked; the beats drift out of phase.
  ///
  /// - Parameters:
  ///   - decoded: Decoded mono PCM carrier, typically from
  ///     ``PCMBufferReader/readDecodedAudio(from:maxSeconds:)``.
  ///   - options: Same options as the url path.
  /// - Returns: A ``BeatGrid``, or `nil` for silence, too-short, or non-musical
  ///   input.
  /// - Throws: `CancellationError` if cancelled via ``Options/isCancelled``.
  public static func analyzeBeatGrid(
    decoded: FeatureSubstrate.DecodedAudio,
    options: Options = .init()
  ) throws -> BeatGrid? {
    if options.isCancelled() { throw CancellationError() }
    return try beatGrid(
      decoded: applyCap(decoded, maxSeconds: options.maxSeconds), options: options)
  }

  /// Beat-grid core shared by the url, decoded, and combined ``analyze`` paths.
  ///
  /// Routes by ``Options/beatGridCoverage`` (Story 8.5):
  ///
  /// - ``BeatGridCoverage/analysisWindow`` (default) — the cheap path: a single
  ///   ``BPMAnalyzer/estimateBPM(decoded:options:)`` pass with step-11 beat-grid
  ///   extraction enabled. The grid covers the BPM analysis window with **zero
  ///   extra onset cost** (reuses the in-scope envelope).
  /// - ``BeatGridCoverage/window(seconds:)`` / ``BeatGridCoverage/fullTrack`` —
  ///   resolve the single-window DSP tempo first (`computeBeatGrid: false`, so the
  ///   window grid is not built), then track the coverage span against that tempo
  ///   via ``BPMAnalyzer/estimateBeatGrid(decoded:tempoBPM:coverage:options:)``
  ///   (DD #10 — a second O(track) onset pass). ``Options/isCancelled`` is checked
  ///   between the two passes so a cancel aborts before the long pass (DD #4).
  ///
  /// The grid is a parallel pipeline output: no metadata corroboration / ensemble
  /// / multi-window pool path is involved. ``BeatGrid/tempoAgreement`` is
  /// ``TempoAgreement/notCompared`` (the analyzer sets it; the combined ``analyze``
  /// path re-stamps it). Tracking against the single-window tempo (not the full
  /// multi-window BPM) keeps ``BeatGrid/estimatedTempo`` an independent estimate
  /// the consistency contract can compare against (AC7).
  private static func beatGrid(
    decoded: FeatureSubstrate.DecodedAudio, options: Options
  ) throws -> BeatGrid? {
    // Standalone beat-grid analysis returns no trace, so keep it allocation-free
    // even when the caller set `enableTrace`: the no-op sinks would discard any
    // grid-pass trace anyway (Copilot review). `enableTrace` is output-inert, so
    // forcing it off here leaves the grid value unchanged.
    var untraced = options
    untraced.enableTrace = false
    return try beatGrid(
      decoded: decoded, options: untraced,
      refinementSink: { _ in }, downbeatSink: { _ in })
  }

  /// Trace-threaded overload (ticket #71). The combined ``analyze`` paths pass live
  /// `refinementSink` / `downbeatSink` closures (only when `options.enableTrace`)
  /// so the beat-grid coverage pass's refinement / downbeat evidence can be stitched
  /// onto the returned `CombinedAnalysisResult.bpm.trace` regardless of coverage.
  /// The standalone ``analyzeBeatGrid`` paths call the no-sink overload above, so
  /// their behavior — and the `enableTrace == false` allocation profile — is
  /// unchanged.
  ///
  /// On ``BeatGridCoverage/analysisWindow`` the grid is built inside the
  /// `computeBeatGrid: true` `estimateBPM` pass, whose own step-11 fan-out owns the
  /// sinks; we therefore enable that pass's trace ONLY when a live sink is wanted
  /// (`options.enableTrace`) and forward its captured evidence to the sinks. On the
  /// `.window(seconds:)` / `.fullTrack` second pass the sinks are threaded straight
  /// into ``BPMAnalyzer/estimateBeatGrid(decoded:tempoBPM:coverage:options:refinementSink:downbeatSink:)``.
  private static func beatGrid(
    decoded: FeatureSubstrate.DecodedAudio, options: Options,
    refinementSink: (BeatGridTempoRefinementEvidence) -> Void,
    downbeatSink: (DownbeatStrategyEvidence) -> Void
  ) throws -> BeatGrid? {
    if case .analysisWindow = options.beatGridCoverage.sanitized {
      let bpmOptions = BPMAnalyzer.Options(
        intensity: options.intensity,
        techniqueSet: options.techniqueSet,
        enableTrace: options.enableTrace,
        computeBeatGrid: true,
        detectDownbeats: options.detectDownbeats,
        downbeatStrategy: options.downbeatStrategy,
        refineBeatGridTempo: options.refineBeatGridTempo)
      guard let result = BPMAnalyzer.estimateBPM(decoded: decoded, options: bpmOptions)
      else { return nil }
      // The step-11 fan-out wrote the evidence onto this pass's own trace (present
      // only when `enableTrace`); forward it to the sinks so the combined path can
      // stitch it onto the BPM result's trace.
      if let refinement = result.trace?.beatGridTempoRefinement { refinementSink(refinement) }
      if let downbeat = result.trace?.downbeatStrategy { downbeatSink(downbeat) }
      return result.beatGrid
    }

    // .window(seconds:) / .fullTrack — second-pass coverage seam. The shared
    // `bpmOptions` carries `detectDownbeats` for the second-pass grid; the
    // tempo-resolution pass leaves `computeBeatGrid` false, so forcing sub-bands
    // (gated on `computeBeatGrid && detectDownbeats`) does not affect it.
    let bpmOptions = BPMAnalyzer.Options(
      intensity: options.intensity,
      techniqueSet: options.techniqueSet,
      detectDownbeats: options.detectDownbeats,
      downbeatStrategy: options.downbeatStrategy,
      refineBeatGridTempo: options.refineBeatGridTempo)
    guard let tempo = BPMAnalyzer.estimateBPM(decoded: decoded, options: bpmOptions)?.bpm
    else { return nil }
    // Checkpoint before the long O(track) onset pass (DD #4).
    if options.isCancelled() { throw CancellationError() }
    return BPMAnalyzer.estimateBeatGrid(
      decoded: decoded,
      tempoBPM: tempo,
      coverage: options.beatGridCoverage,
      options: bpmOptions,
      refinementSink: refinementSink,
      downbeatSink: downbeatSink)
  }

  /// Runs ``beatGrid(decoded:options:)`` and, when `options.enableTrace`, captures
  /// the grid pass's refinement / downbeat evidence into a local trace stitched onto
  /// the supplied BPM result (ticket #71) — so `CombinedAnalysisResult.bpm.trace`
  /// carries the evidence on every coverage. When tracing is off, no trace is built
  /// and the BPM result is returned verbatim (allocation-free).
  private static func beatGridStitchingTrace(
    decoded: FeatureSubstrate.DecodedAudio, options: Options, bpm: AudioAnalysisResult
  ) throws -> (grid: BeatGrid?, bpm: AudioAnalysisResult) {
    guard options.enableTrace else {
      return (try beatGrid(decoded: decoded, options: options), bpm)
    }
    var gridTrace = bpm.trace ?? BPMDiagnosticTrace()
    let grid = try beatGrid(
      decoded: decoded, options: options,
      refinementSink: { gridTrace.beatGridTempoRefinement = $0 },
      downbeatSink: { gridTrace.downbeatStrategy = $0 })
    return (grid, bpm.with(trace: gridTrace))
  }

  // MARK: - Story 8.5: combined BPM + beat-grid analysis (FR-31 / FR-35, KDD-C4)

  /// Analyzes BPM **and** beat grid over a single shared decode, and reports how
  /// the two tempos agree (Story 8.5).
  ///
  /// This is the combined entry KDD-C4 deferred to a follow-up story. It decodes
  /// the file exactly once and runs both the full multi-window,
  /// metadata-corroborated BPM pipeline AND beat-grid extraction over that one
  /// decode (FR-35) — strictly cheaper than calling ``analyzeBPM(url:options:)``
  /// and ``analyzeBeatGrid(url:options:)`` separately, which would decode twice.
  ///
  /// The returned grid's ``BeatGrid/tempoAgreement`` is set by comparing the
  /// grid's ``BeatGrid/estimatedTempo`` (an independent single-window estimate)
  /// against the full BPM result (NOT the single-window tempo the grid tracked,
  /// which would be tautological — AC7). Both raw tempos remain accessible on the
  /// result so a consumer can reconcile an octave case itself.
  ///
  /// Cancellation (``Options/isCancelled``) is honored at the same checkpoints as
  /// ``analyzeBPM(url:options:)`` plus once more before the (separate) beat-grid
  /// pass — so cancelling a library batch-index aborts the in-flight file
  /// promptly. ``Options/beatGridCoverage`` controls the grid's detected-beat span.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - options: Configuration; the BPM, beat-grid coverage, cancellation, and
  ///     (BPM-side) metadata/duration fields all apply.
  /// - Returns: A ``CombinedAnalysisResult``, or `nil` when there is no analyzable
  ///   audio (silence, too-short, or non-musical — the BPM stage's `nil` contract).
  ///   A non-nil result with `beatGrid == nil` means BPM succeeded but the grid
  ///   could not be tracked.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read;
  ///   `CancellationError` if cancelled via ``Options/isCancelled``.
  public static func analyze(
    url: URL,
    options: Options = .init()
  ) throws -> CombinedAnalysisResult? {
    try analyze(url: url, options: options, decodeObserver: nil)
  }

  /// Internal observer-threaded overload (Story 8-2 DD #9 seam): the public
  /// method passes `decodeObserver: nil`. The combined path captures the BPM
  /// url path's single decode and reuses it for the grid (one decode total —
  /// the FR-35 shared-decode property the structural tests assert); any caller
  /// observer is chained so it still sees exactly one decode.
  static func analyze(
    url: URL,
    options: Options,
    decodeObserver: (@Sendable (FeatureSubstrate.DecodedAudio) -> Void)?
  ) throws -> CombinedAnalysisResult? {
    let capture = DecodedCapture()
    let chained: @Sendable (FeatureSubstrate.DecodedAudio) -> Void = { decoded in
      capture.set(decoded)
      decodeObserver?(decoded)
    }
    guard let bpm = try analyzeBPM(url: url, options: options, decodeObserver: chained)
    else { return nil }
    guard let decoded = capture.value else {
      // analyzeBPM produced a result, so it decoded and the observer fired;
      // this is unreachable, but fail safe by returning BPM with no grid.
      return CombinedAnalysisResult(bpm: bpm, beatGrid: nil)
    }
    // Checkpoint before the (separate) beat-grid pass (AC6).
    if options.isCancelled() { throw CancellationError() }
    return try combineGridWithBPM(decoded: decoded, options: options, bpm: bpm)
  }

  /// Combined analysis over an already-decoded carrier — the shared-decode seam
  /// (KDD-C4). URL-bound BPM signals (file-metadata corroboration, duration hint)
  /// are inert here, exactly as on ``analyzeBPM(decoded:options:)``.
  ///
  /// - Parameters:
  ///   - decoded: Decoded mono PCM carrier.
  ///   - options: Same options as the url path.
  /// - Returns: A ``CombinedAnalysisResult``, or `nil` when there is no analyzable
  ///   audio.
  /// - Throws: `CancellationError` if cancelled via ``Options/isCancelled``.
  public static func analyze(
    decoded: FeatureSubstrate.DecodedAudio,
    options: Options = .init()
  ) throws -> CombinedAnalysisResult? {
    if options.isCancelled() { throw CancellationError() }
    // Cap once so the BPM pass and the grid pass see the identical buffer
    // (`analyzeBPM(decoded:)` re-applies the cap idempotently).
    let capped = applyCap(decoded, maxSeconds: options.maxSeconds)
    guard let bpm = try analyzeBPM(decoded: capped, options: options) else { return nil }
    if options.isCancelled() { throw CancellationError() }
    return try combineGridWithBPM(decoded: capped, options: options, bpm: bpm)
  }

  /// The grid-pass tail shared by both combined ``analyze`` entry points: run the
  /// beat-grid pass over `decoded` (stitching its trace onto `bpm` when tracing is
  /// on), resolve the grid's ``TempoAgreement`` against that BPM result, and apply
  /// the configured ``BeatGridTempoLock``. The url and decoded paths differ only in
  /// which carrier they pass here.
  private static func combineGridWithBPM(
    decoded: FeatureSubstrate.DecodedAudio, options: Options, bpm: AudioAnalysisResult
  ) throws -> CombinedAnalysisResult {
    let (grid, tracedBPM) = try beatGridStitchingTrace(
      decoded: decoded, options: options, bpm: bpm)
    let resolved = grid.map { resolveTempoAgreement($0, against: tracedBPM) }
    return CombinedAnalysisResult(
      bpm: tracedBPM,
      beatGrid: applyTempoLock(
        resolved, lock: options.beatGridTempoLock, bpmStageTempo: tracedBPM.bpm))
  }

  /// Stamps the resolved ``TempoAgreement`` onto a grid the analyzer produced
  /// with ``TempoAgreement/notCompared``, via the ``BeatGrid/with(tempoAgreement:)``
  /// forwarder (W52 — never a field-enumerating re-init).
  private static func resolveTempoAgreement(
    _ grid: BeatGrid, against bpm: AudioAnalysisResult
  ) -> BeatGrid {
    grid.with(
      tempoAgreement: classifyTempoAgreement(
        gridTempo: grid.estimatedTempo, bpmTempo: bpm.bpm))
  }

  /// Applies ``BeatGridTempoLock`` to a grid in the combined-analysis path,
  /// AFTER ``resolveTempoAgreement`` so the grid keeps its pre-lock
  /// ``BeatGrid/tempoAgreement`` diagnostic (overriding the tempo first would
  /// make it artificially ``TempoAgreement/agree`` and hide the exact drift this
  /// feature exists to fix).
  ///
  /// The two locking cases differ in authority:
  /// - ``BeatGridTempoLock/bpmStage`` is the pipeline's OWN authoritative tempo, so
  ///   it overrides even a within-octave disagreement — an accepted refit (up to the
  ///   4% search window) or a single- vs multi-window split can push the grid >2%
  ///   from it, and the documented precedence is that `.bpmStage` still wins. Only a
  ///   true >octave divergence (or a non-finite/non-positive stage tempo) leaves the
  ///   grid unlocked. Octave-normalized to the grid's octave (see ``stageLockTempo``).
  /// - ``BeatGridTempoLock/bpm(_:)`` is arbitrary caller input, so it stays GATED:
  ///   octave-normalized to the grid, and a target that disagrees by more than an
  ///   octave — or is non-finite/non-positive — leaves the grid unlocked
  ///   (``octaveNormalizedLockTempo``).
  static func applyTempoLock(
    _ grid: BeatGrid?, lock: BeatGridTempoLock, bpmStageTempo: Double
  ) -> BeatGrid? {
    guard let grid else { return nil }
    let locked: Double?
    // The lock target before octave normalization — the caller's `.bpm(value)`
    // or the BPM-stage tempo for `.bpmStage`. Used ONLY to surface the applied
    // octave factor (issue #62); `.off` returns early before the factor compute.
    let target: Double
    switch lock {
    case .off: return grid
    case .bpmStage:
      target = bpmStageTempo
      locked = stageLockTempo(target: bpmStageTempo, gridTempo: grid.estimatedTempo)
    case .bpm(let value):
      target = value
      locked = octaveNormalizedLockTempo(target: value, gridTempo: grid.estimatedTempo)
    }
    guard let locked else { return grid }
    // Surface the octave factor the snap applied (issue #62) from the SAME
    // `classifyTempoAgreement` source of truth both resolvers used — do NOT
    // re-derive a `locked / target` ratio (it could disagree at the 2% boundary).
    // `.octaveEquivalent(factor:)` is the only shifting case; `.agree` (target
    // already shared the grid's octave) and the within-octave `.disagree`
    // `.bpmStage` pass-through leave the factor at the neutral `1`.
    let octaveFactor: Int
    if case .octaveEquivalent(let factor) =
      classifyTempoAgreement(gridTempo: grid.estimatedTempo, bpmTempo: target)
    {
      octaveFactor = factor
    } else {
      octaveFactor = 1
    }
    return grid.with(estimatedTempo: locked, tempoLockOctaveFactor: octaveFactor)
  }

  /// The authoritative ``BeatGridTempoLock/bpmStage`` resolver: the target IS the
  /// BPM stage's own tempo, so a within-octave disagreement with the (possibly
  /// refined) grid must NOT silently no-op (the bug that let a 2–4% refit leave the
  /// refined grid standing instead of restoring the stage tempo). Returns `target`
  /// octave-shifted to the grid's octave, or `target` itself on a within-octave
  /// disagreement; `nil` only when `target` is non-finite/≤0 or the two genuinely
  /// disagree by more than an octave (which the bounded refit cannot produce, but a
  /// single- vs multi-window split could). Unlike ``octaveNormalizedLockTempo`` it
  /// does NOT reject a within-octave `.disagree`.
  static func stageLockTempo(target: Double, gridTempo: Double) -> Double? {
    guard target.isFinite, target > 0 else { return nil }
    if let shifted = octaveNormalizedLockTempo(target: target, gridTempo: gridTempo) {
      return shifted
    }
    // `.disagree`/`.notCompared`: `.disagree` conflates within-octave (>2%) with true
    // >octave. The stage tempo is authoritative within an octave; only a real >octave
    // gap (ratio outside (0.5, 2.0)) leaves the grid unlocked. A non-finite/≤0 grid
    // tempo (the "no estimate" sentinel) has no octave to compare, so the stage tempo
    // wins.
    guard gridTempo.isFinite, gridTempo > 0 else { return target }
    let ratio = gridTempo / target
    return ratio > 0.5 && ratio < 2.0 ? target : nil
  }

  /// Returns `target` octave-shifted (×1, ×2, or ×½) to whichever octave lands within the
  /// 2% agreement band of `gridTempo`, or `nil` when none does (a more-than-an-octave
  /// `.disagree`/`.notCompared`, or a non-finite/non-positive input — each caller decides
  /// what to do with that `nil`). **Single source of truth for the lock octave arithmetic:**
  /// the gated ``BeatGridTempoLock/bpm(_:)`` path uses it directly, and ``stageLockTempo``
  /// reuses it before applying its own within-octave `.disagree` policy — so the two
  /// resolvers can never drift. Reuses ``classifyTempoAgreement`` so the lock's octave logic
  /// and the cross-stage agreement classifier never drift apart.
  private static func octaveNormalizedLockTempo(target: Double, gridTempo: Double) -> Double? {
    switch classifyTempoAgreement(gridTempo: gridTempo, bpmTempo: target) {
    case .agree: return target
    case .octaveEquivalent(let factor): return factor == 2 ? target * 2.0 : target * 0.5
    case .disagree, .notCompared: return nil
    }
  }

  /// Classifies how a beat-grid tempo relates to a BPM-stage tempo (AC7 / FR-31).
  ///
  /// `.agree` iff within ~2% **relative** (`abs(a-b)/min(a,b) ≤ 0.02`, the
  /// library's own `isNearMatch` band — NOT an absolute BPM delta, which is
  /// 6.7% of 30 BPM but 0.67% of 300). Else `.octaveEquivalent(factor:)` iff the
  /// grid tempo is within that band of `bpmTempo·2` (`factor = +2`) or
  /// `bpmTempo·½` (`factor = -2`). Else `.disagree`. **One octave only** — a
  /// genuine 4×/¼× relationship is `.disagree` (a four-octaves-off track should
  /// prompt the user, not auto-sync to a quarter tempo). Non-positive/non-finite
  /// inputs are `.disagree` (the safe "don't auto-sync" answer).
  static func classifyTempoAgreement(gridTempo: Double, bpmTempo: Double) -> TempoAgreement {
    guard gridTempo.isFinite, gridTempo > 0, bpmTempo.isFinite, bpmTempo > 0 else {
      return .disagree
    }
    if isWithin2PercentRelative(gridTempo, bpmTempo) { return .agree }
    if isWithin2PercentRelative(gridTempo, bpmTempo * 2.0) {
      return .octaveEquivalent(factor: 2)
    }
    if isWithin2PercentRelative(gridTempo, bpmTempo * 0.5) {
      return .octaveEquivalent(factor: -2)
    }
    return .disagree
  }

  /// `abs(a-b)/min(a,b) ≤ 0.02` — the same relative band as
  /// `BPMSelectionPolicy.isNearMatch`. Both must be positive.
  private static func isWithin2PercentRelative(_ a: Double, _ b: Double) -> Bool {
    let lo = min(a, b)
    guard lo > 0 else { return false }
    return abs(a - b) / lo <= 0.02
  }
}

// MARK: - Shared-decode capture (Story 8.5)

/// Captures the single ``FeatureSubstrate/DecodedAudio`` the BPM url path
/// produces so ``AudioAnalysisService/analyze(url:options:)`` can reuse it for
/// the beat-grid pass — one decode total. The decode observer fires
/// synchronously within the `analyzeBPM` call; the `Mutex` keeps the capture
/// `Sendable`-clean under Swift 6 strict concurrency without an `@unchecked`.
private final class DecodedCapture: Sendable {
  private let storage = Mutex<FeatureSubstrate.DecodedAudio?>(nil)
  func set(_ decoded: FeatureSubstrate.DecodedAudio) { storage.withLock { $0 = decoded } }
  var value: FeatureSubstrate.DecodedAudio? { storage.withLock { $0 } }
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
      trace: newTrace,
      beatGrid: beatGrid)
  }
}
