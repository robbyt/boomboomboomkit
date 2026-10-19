//
//  FramewiseObservations.swift
//  BoomBoomBoomKit
//
//  Story 15.6 (Epic 15, Phase 6) — internal value type carrying per-frame
//  beat and downbeat probabilities, their timing on the decoded-PCM
//  timeline, and the identity of the model + frontend that produced them.
//
//  Kept DELIBERATELY SEPARATE from MLTechnique / MLEvaluation. That API
//  returns one scalar tempo evaluation per call; a framewise observation
//  stream cannot live on top of it. This type is the input to
//  `BarStateDecoder` and `MetricalLevelSelector`, and `FramewiseObservationProducer`
//  is the protocol a stub (today) or trained (future) producer conforms to.
//
//  Public API is unchanged by this story: everything in this file is
//  `internal` to the `BoomBoomBoomKit` target.
//

/// Per-frame beat and downbeat probabilities for a decoded-audio span.
///
/// ## Timing
/// Observations are emitted at a fixed cadence of ``frameRate`` frames per
/// second on the decoded-PCM timeline (same timeline as
/// ``BeatTimestamp/presentationTime``). One statement governs every frame:
/// ``timeForFrame(_:)`` returns the instant frame `i` represents, which is
/// `firstFrameOriginSeconds + i / frameRate`, so
/// `firstFrameOriginSeconds == timeForFrame(0)`. The producer chooses the
/// origin so that this instant matches its own frame-time convention; a
/// consumer converts a frame index to a time only through
/// ``timeForFrame(_:)``. The usable coverage window is
/// ``coverageWindowSeconds`` seconds of frames counted from frame 0. Values
/// outside the coverage window are not available even if the arrays contain
/// data at that index.
///
/// ## Probability ranges
/// Each of ``beatProbabilities`` and ``downbeatProbabilities`` is in
/// `[0, 1]`. A beat and a downbeat can co-occur at the same frame — a
/// strong downbeat typically also carries a strong beat probability. The
/// implied "no-beat" class is `1 - beatProbabilities[i]` and is not stored
/// separately.
///
/// ## Identity for drift detection
/// ``modelIdentifier`` and ``frontendIdentifier`` are opaque strings. A
/// consumer saving an observation stream for later comparison can store
/// these and refuse to re-run against a non-matching producer. The stub
/// producer shipped in Story 15.6 reports model identifier `dsp-stub.v1`
/// and frontend identifier `bpmanalyzer-onset.v1`.
internal struct FramewiseObservations: Sendable, Hashable {

  /// Frame cadence in Hz. 100 fps matches the published Böck et al.
  /// ISMIR 2016 reference.
  let frameRate: Double

  /// Decoded-PCM instant represented by frame 0; equal to
  /// `timeForFrame(0)`. See the type's Timing section.
  let firstFrameOriginSeconds: Double

  /// Usable observation span in seconds, counted in frames from frame 0. A
  /// producer that saw less audio than
  /// requested reports a smaller window; consumers must not read
  /// `beatProbabilities[i]` where `Double(i) / frameRate > coverageWindow`.
  let coverageWindowSeconds: Double

  /// Per-frame beat probability, `[0, 1]`.
  let beatProbabilities: [Float]

  /// Per-frame downbeat probability, `[0, 1]`.
  let downbeatProbabilities: [Float]

  /// Opaque identifier for the producer. Stub producers use
  /// `dsp-stub.v1`; a future trained producer would use a stable name
  /// such as `boeck-ismir2016.v1`.
  let modelIdentifier: String

  /// Opaque identifier for the feature frontend. Stubs derive from
  /// ``BPMAnalyzer``'s existing envelope path, so the identifier is
  /// `bpmanalyzer-onset.v1`.
  let frontendIdentifier: String

  init(
    frameRate: Double,
    firstFrameOriginSeconds: Double,
    coverageWindowSeconds: Double,
    beatProbabilities: [Float],
    downbeatProbabilities: [Float],
    modelIdentifier: String,
    frontendIdentifier: String
  ) {
    precondition(frameRate.isFinite && frameRate > 0, "frameRate must be finite and positive")
    precondition(
      firstFrameOriginSeconds.isFinite && firstFrameOriginSeconds >= 0,
      "firstFrameOriginSeconds must be finite and non-negative")
    precondition(
      coverageWindowSeconds.isFinite && coverageWindowSeconds >= 0,
      "coverageWindowSeconds must be finite and non-negative")
    precondition(
      beatProbabilities.count == downbeatProbabilities.count,
      "beat and downbeat probability arrays must be the same length"
    )
    self.frameRate = frameRate
    self.firstFrameOriginSeconds = firstFrameOriginSeconds
    self.coverageWindowSeconds = coverageWindowSeconds
    self.beatProbabilities = beatProbabilities
    self.downbeatProbabilities = downbeatProbabilities
    self.modelIdentifier = modelIdentifier
    self.frontendIdentifier = frontendIdentifier
  }

  /// Number of frames stored. May include a short run beyond the usable
  /// ``coverageWindowSeconds``.
  var frameCount: Int { beatProbabilities.count }

  /// Decoded-PCM instant represented by frame `i`:
  /// `firstFrameOriginSeconds + i / frameRate`.
  func timeForFrame(_ i: Int) -> Double {
    firstFrameOriginSeconds + Double(i) / frameRate
  }
}

/// Produces a ``FramewiseObservations`` stream from a decoded-audio span.
///
/// Phase 6 of Story 15.6 ships one conformer: ``DSPStubObservationProducer``,
/// which divides ``BPMAnalyzer``'s existing full-band onset envelope by its
/// maximum to populate the beat channel and scales that by a flat 0.5 for
/// the downbeat channel. A trained conformer (bar-state neural model) is a follow-up.
internal protocol FramewiseObservationProducer: Sendable {
  /// Opaque identifier recorded on every emitted
  /// ``FramewiseObservations/modelIdentifier``.
  var modelIdentifier: String { get }

  /// Produces the observation stream, or `nil` if the input is too short
  /// or otherwise unusable. The producer must set every metadata field on
  /// the returned value; a `nil` return is the ONLY abstention path.
  func produce(decoded: FeatureSubstrate.DecodedAudio) -> FramewiseObservations?
}
