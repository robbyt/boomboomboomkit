//
//  MLFeatureFrames.swift
//  BoomBoomBoomKit
//
//  Typed-evidence carrier for per-frame log-mel spectrogram model input.
//

import Foundation

/// Typed-evidence carrier for the per-frame log-mel spectrogram fed into
/// ``MLTechnique/evaluate(trace:)``. Surfaces the raw model input on the
/// trace so consumers can audit what the ML conformance actually saw —
/// and so future-story authors can detect when the pre-`vvlogf` pipeline
/// drifts away from the trained model's expected feature distribution.
///
/// The struct follows the typed-evidence pattern established by
/// ``ClickCorrelationEntry`` / ``SubBandEnergies`` / ``BarCandidate`` etc.
/// (Story 3-3b precedent): named `Sendable` value type, NO `[String: Any]`
/// payloads, NO stringified-numeric values. The accompanying
/// ``featureSetVersion`` field is the load-bearing seam that detects
/// pre-`vvlogf` pipeline drift — see project-context.md §"Banned trace-
/// field shapes" for the discipline. Story 7.5 ships `"v2"` against the
/// current `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` pre-image;
/// any change to `BPMAnalyzer.hopSize` / `melBands` / `melFmin` /
/// `melFmax` / `fftSize` / `logCompressionScale` / mel filterbank formula
/// MUST bump the version (DD #2 + DD #14 bump-trigger checklist).
///
/// See `tools/coreml-convert/README.md` for the canonical consumer-onboarding
/// flow — Path B (your converted weights) and Path C (third-party / AGPL
/// caveats). Story 4-6 removed the historical Path A (library-bundled
/// reference model); the README documents the BYOW-only paths now. The
/// worked examples show how a custom ``MLTechnique`` conformance
/// consumes this struct.
public struct MLFeatureFrames: Sendable, CustomStringConvertible, Equatable {

  /// Number of mel bands per frame. Equals `128` for the reference
  /// architecture trained by Story 4-4b (the previously-bundled
  /// `giantsteps_v1.mlmodelc` was 128-mel; BYOW consumers converting
  /// against the same architecture inherit the same value).
  public let melBands: Int

  /// Pre-resample source frame count along the time axis. The
  /// ``BNNSTechnique`` conformance resamples to a fixed `W=512` BEFORE
  /// feeding the graph; this is the count BEFORE that resample step so
  /// readers can audit the source-rate-derived frame budget.
  public let frames: Int

  /// Logical tensor layout for ``logMelData``. Story 4.5 ships
  /// ``TensorLayout/frameMajorLogMel`` (the ``BPMAnalyzer`` producer's
  /// actual on-the-wire shape) and ``TensorLayout/nchw`` (reserved for
  /// future producers); ``CaseIterable`` lets future stories add cases
  /// without breaking the precondition guard.
  ///
  /// **TensorLayout is a tag, not a constraint.** The initializer does
  /// not (and cannot) inspect ``logMelData`` to verify the bytes match
  /// the declared layout. Producers MUST set this field truthfully — a
  /// mislabeled payload (e.g., frame-major bytes tagged ``nchw``) will
  /// be fed transposed into a consumer ``MLTechnique`` and produce
  /// silently wrong predictions. The standard library producer
  /// (``BPMAnalyzer``) always emits ``frameMajorLogMel``.
  public let tensorLayout: TensorLayout

  /// Log-mel payload whose interpretation depends on ``tensorLayout``:
  /// - ``TensorLayout/frameMajorLogMel`` (current ``BPMAnalyzer``
  ///   producer): `[frame0_mel0, frame0_mel1, …, frame0_melLast,
  ///   frame1_mel0, …]`. Equivalent to `logMelFrames.flatMap { $0 }`
  ///   where each inner row is one frame's mel band values.
  /// - ``TensorLayout/nchw``: `[N=1, C=1, H=melBands, W=frames]`
  ///   row-major, i.e., mel-major (`[mel0_frame0, mel0_frame1, …,
  ///   mel0_frameLast, mel1_frame0, …]`).
  ///
  /// Throwing-init invariants: `count == melBands * frames`, both
  /// dimensions positive, and total element count `<= 8_388_608` (≈ 32
  /// MB on a `[Float]`; defends the public initializer against
  /// accidental construction of arbitrarily-large payloads on a
  /// `Sendable` boundary).
  public let logMelData: [Float]

  /// DSP source rate from which the spectrogram was derived, in Hz. The
  /// BPM/onset pipeline (`BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands`
  /// + `MelFilterbank.buildFilterbank`) accepts any positive sample rate
  /// at or above the audio-engineering practical minimum (8 kHz). The
  /// `{44_100, 48_000, 96_000}` set applies only to ``LUFSAnalyzer``
  /// (precomputed K-weighting biquad coefficients) and is off the
  /// MLFeatureFrames code path. Surfaced for completeness; `BNNSTechnique`
  /// does not resample audio.
  public let sampleRate: Double

  /// FFT window size used by `BPMAnalyzer.computeMelOnsetEnvelope...`
  /// at retention time. `2048` for Story 4.5; bump
  /// ``featureSetVersion`` if this changes.
  public let fftSize: Int

  /// Hop size in samples for the mel STFT. `441` samples (≈ 100 Hz onset
  /// rate at 44.1 kHz) for Story 4.5; bump ``featureSetVersion`` if this
  /// changes.
  public let hopSize: Int

  /// Mel filterbank low-frequency bound. `30.0` Hz for Story 4.5.
  public let melFmin: Double

  /// Mel filterbank high-frequency bound. `min(sampleRate/2, 16000)` per
  /// `BPMAnalyzer`'s current convention.
  public let melFmax: Double

  /// Linear pre-`vvlogf` scale factor. `100.0` for Story 4.5 (per
  /// `BPMAnalyzer.logCompressionScale`).
  public let logCompressionScale: Float

  /// Pre-`vvlogf` pipeline version tag. Story 7.5 ships `"v2"` (the
  /// substrate-locked, FR-18-evaluable feature contract; `"v1"` was Story
  /// 4.5/6.2's pre-substrate scaffolding). Bumps per the DD #2 + DD #14
  /// bump-trigger checklist. Consumer ``MLTechnique`` conformances SHOULD
  /// check this against the version their model was trained on and abstain
  /// (return `nil` from `evaluate(trace:)`) if the versions disagree.
  public let featureSetVersion: String

  /// Single source of truth for the feature-set version this build of the
  /// library produces and the bundled-architecture model expects (Story 7.5
  /// DD #1/#12). `BPMAnalyzer`'s `MLFeatureFrames` producer stamps every
  /// payload with this value, and `BNNSTechnique.supportedFeatureSetVersion`
  /// references it, so the runtime emission and the model expectation can
  /// never silently diverge — the abstain guard then fires only on a genuine
  /// consumer/BYOW mismatch (e.g. feeding `"v1"` features to a `"v2"` runtime).
  /// Bumping the feature contract (mel/FFT/log shape, or the substrate
  /// producer) means bumping THIS constant; the multi-seed *model generation*
  /// rides on the `giantsteps_v2_seed_*` filename + `MLEvaluation.modelIdentifier`,
  /// NOT on this string (DD #14).
  public static let currentFeatureSetVersion = "v2"

  /// Maximum allowed `logMelData.count` (= 8 Mi floats = 32 MB at
  /// 4 bytes/float). Comfortably accommodates the default
  /// `AudioAnalysisService.Options.maxSeconds = 120` budget
  /// (120 s × 100 fps × 128 mel = 1.536 Mi floats) with ~5× headroom for
  /// stories that bump `maxSeconds` toward 10 minutes. Consumers with
  /// `maxSeconds = 1800` (rare) trip the cap and route through abstain
  /// (`try?` in the producer → `mlFeatures = nil`).
  ///
  /// **Retention-side defense, not boundary defense (review fix N13):** the cap
  /// fires inside the initializer AFTER the caller has already allocated the
  /// `[Float]` payload. Its job is to defend the ``BPMAnalyzer`` retention path
  /// against pathologically-long analysis windows producing a multi-hundred-MB
  /// `mlFeatures` value (the `try`/`catch invalidFeatureShape` in the producer
  /// routes the failure through the documented abstain path). Callers that
  /// pre-allocate their own `logMelData` MUST validate the allocation size
  /// themselves — this initializer cannot.
  public static var maximumLogMelDataCount: Int {
    _testingMaximumLogMelDataCount ?? 8_388_608
  }

  /// Test-only override of ``maximumLogMelDataCount``. Implemented as a Swift
  /// `@TaskLocal` so the override is per-task — concurrent tests
  /// constructing larger ``MLFeatureFrames`` outside the
  /// ``_withTestingMaximumLogMelDataCount(_:_:)`` scope continue to see the
  /// production cap. The v1 implementation used `nonisolated(unsafe) static var`
  /// which silenced Swift 6 strict-concurrency checking but didn't actually
  /// isolate parallel tests — Codex review pass flagged this as a real bug,
  /// not just a smell (review fix N5 v2 / codex 019e28bb).
  ///
  /// **Propagation caveat (Story 4-5 review pass v3 / Edge Case Hunter #8).**
  /// Swift `@TaskLocal` values propagate to *structured* child tasks
  /// (`async let`, `TaskGroup.addTask`) but NOT to *unstructured*
  /// `Task { }` instances spawned inside the override scope. A test that
  /// wraps `analyzeBPM` in `Task { try analyzeBPM(...) }.value` from
  /// inside ``_withTestingMaximumLogMelDataCount(_:_:)`` runs on a
  /// fresh task tree that sees the production cap, not the override.
  /// Tests must call `analyzeBPM` directly inside the override (or via
  /// `async let` / `TaskGroup`).
  ///
  /// Production code MUST NOT touch this directly.
  @TaskLocal internal static var _testingMaximumLogMelDataCount: Int?

  /// Test-only helper that temporarily lowers ``maximumLogMelDataCount`` for the
  /// duration of `body`. The override is task-local — concurrent tests on
  /// other tasks see the production cap. The wrapper still uses `defer`-style
  /// scoping via `TaskLocal.withValue` semantics so the override doesn't
  /// leak past the closure even if `body` throws (review fix N5 v2).
  ///
  /// See ``_testingMaximumLogMelDataCount`` for the unstructured-`Task { }`
  /// propagation caveat.
  internal static func _withTestingMaximumLogMelDataCount<R>(
    _ cap: Int, _ body: () throws -> R
  ) rethrows -> R {
    try $_testingMaximumLogMelDataCount.withValue(cap, operation: body)
  }

  /// Throwing initializer enforcing the public-API invariants documented
  /// on each field. Replaces the pre-review `precondition()` calls so a
  /// malformed payload routes through an abstain path rather than
  /// crashing the host app.
  ///
  /// Throws `MLTechniqueError.invalidFeatureShape` when any invariant
  /// fires; see ``MLTechniqueError/invalidFeatureShape(reason:)`` for the
  /// abstain semantics.
  ///
  /// **Validation order (cheap-to-expensive).** Scalar shape and
  /// semantic-metadata checks fire first; the O(N) `allSatisfy(\.isFinite)`
  /// scan over `logMelData` runs last so a malformed-shape payload short-
  /// circuits before the cost of walking the buffer is paid.
  public init(
    melBands: Int,
    frames: Int,
    tensorLayout: TensorLayout,
    logMelData: [Float],
    sampleRate: Double,
    fftSize: Int,
    hopSize: Int,
    melFmin: Double,
    melFmax: Double,
    logCompressionScale: Float,
    featureSetVersion: String
  ) throws {
    // MARK: Shape invariants
    guard melBands > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "melBands must be positive (got \(melBands))")
    }
    guard frames > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "frames must be positive (got \(frames))")
    }
    // Use multipliedReportingOverflow to defend against
    // `Int.max`-sized inputs that would trap on the unguarded
    // multiplication.
    let (expectedCount, overflow) = melBands.multipliedReportingOverflow(by: frames)
    guard !overflow else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "melBands * frames overflowed Int (melBands=\(melBands), frames=\(frames))")
    }
    guard logMelData.count == expectedCount else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "logMelData.count (\(logMelData.count)) != melBands * frames (\(expectedCount))")
    }
    guard expectedCount <= Self.maximumLogMelDataCount else {
      throw MLTechniqueError.invalidFeatureShape(
        reason:
          "logMelData.count \(expectedCount) exceeds size cap \(Self.maximumLogMelDataCount) "
          + "(≈32 MB); bump cap or trim the analysis window")
    }
    // `tensorLayout` is `CaseIterable` with closed-set membership; the
    // `switch` lets future-case extension surface as a non-exhaustive
    // compile error rather than a silent precondition trap.
    switch tensorLayout {
    case .frameMajorLogMel, .nchw:
      break
    }

    // MARK: Semantic-metadata invariants (Story 4-5 review pass v3)
    // The metadata fields are part of the tensor's typed contract per
    // DD #2 — a consumer ``MLTechnique`` aligning its training-time
    // pipeline against these values must be able to trust them. Storing
    // garbage (NaN sample rates, zero hop sizes, fmax < fmin, empty
    // version tag) without checking would silently bypass the
    // pipeline-drift detection seam ``featureSetVersion`` exists to
    // provide.
    guard sampleRate.isFinite, sampleRate > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "sampleRate must be finite and positive (got \(sampleRate))")
    }
    guard fftSize > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "fftSize must be positive (got \(fftSize))")
    }
    guard hopSize > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "hopSize must be positive (got \(hopSize))")
    }
    guard melFmin.isFinite, melFmin >= 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "melFmin must be finite and non-negative (got \(melFmin))")
    }
    guard melFmax.isFinite, melFmax > melFmin else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "melFmax must be finite and strictly greater than melFmin "
          + "(melFmin=\(melFmin), melFmax=\(melFmax))")
    }
    guard logCompressionScale.isFinite, logCompressionScale > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "logCompressionScale must be finite and positive (got \(logCompressionScale))")
    }
    guard !featureSetVersion.isEmpty else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "featureSetVersion must not be empty (DD #2 pipeline-drift detection)")
    }

    // MARK: Payload finiteness — O(N) scan last
    // Real-world audio with sustained loud peaks can push pre-`vvlogf`
    // mel energies into the upper `Float` range; `100.0 * x + 1.0`
    // overflows `Float.infinity` at `x ≈ 3.4e36`. Producing `+inf` /
    // `NaN` in the tensor would propagate through downstream `vDSP`
    // normalization (mean/stddev become `NaN`) and break synthesized
    // `Equatable` (`Float.nan != Float.nan`). Reject at the boundary.
    guard logMelData.allSatisfy({ $0.isFinite }) else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "logMelData contains non-finite values (NaN or Inf); upstream "
          + "DSP pre-image overflowed or produced an invalid log")
    }

    self.melBands = melBands
    self.frames = frames
    self.tensorLayout = tensorLayout
    self.logMelData = logMelData
    self.sampleRate = sampleRate
    self.fftSize = fftSize
    self.hopSize = hopSize
    self.melFmin = melFmin
    self.melFmax = melFmax
    self.logCompressionScale = logCompressionScale
    self.featureSetVersion = featureSetVersion
  }

  /// Compact diagnostic representation. The full ``logMelData`` payload is
  /// NOT printed (would be `melBands * frames` floats; up to hundreds of
  /// thousands of values at default intensity). Element count is shown
  /// instead so readers can verify the shape matches the metadata.
  public var description: String {
    // `featureSetVersion` is quoted so descriptions of payloads carrying
    // malformed version tags (containing commas, colons, or other
    // separator-looking characters) remain machine-parseable in
    // benchmark logs and ablation reports.
    "MLFeatureFrames(melBands: \(melBands), frames: \(frames), "
      + "layout: \(tensorLayout), logMelData.count: \(logMelData.count), "
      + "sampleRate: \(sampleRate), fftSize: \(fftSize), hopSize: \(hopSize), "
      + "melFmin: \(melFmin), melFmax: \(melFmax), "
      + "logCompressionScale: \(logCompressionScale), "
      + "featureSetVersion: \"\(featureSetVersion)\")"
  }
}
