//
//  BeatGridAnalyzerTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.4 tests for the Davies & Plumbley DP beat-tracker (BeatGridAnalyzer),
//  the step-11 fan-out, and the public analyzeBeatGrid service methods:
//  click-track recovery, real-fixture agreement with analyzeBPM, strength/
//  confidence bounds, degenerate-input nil paths, track-relative timestamps,
//  the C2 octave-snap contract, the small-tempo guard, and the default-path
//  byte-identity contract (AC4).
//
//  `@testable` is required to reach the internal `BeatGridAnalyzer` /
//  `BPMAnalyzer` / `BPMResult` for the deterministic DP tests and the
//  byte-identity proof; the public path is exercised through
//  `AudioAnalysisService.analyzeBeatGrid`.
//

import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Synchronization
import Testing

@testable import BoomBoomBoomKit

@Suite("BeatGridAnalyzerTests")
struct BeatGridAnalyzerTests {

  // MARK: - Helpers

  /// Onset envelope at 100 Hz with unit impulses every `periodFrames` frames.
  private static func impulseEnvelope(frames: Int, periodFrames: Int) -> [Float] {
    var env = [Float](repeating: 0, count: frames)
    for f in stride(from: 0, to: frames, by: periodFrames) { env[f] = 1 }
    return env
  }

  /// True when `a` is within `tol` BPM of `b` at the unison, half, or double
  /// octave — DSP octave choice on a click track is not the contract under test.
  private static func matchesWithinOctave(_ a: Double, _ b: Double, tol: Double = 5)
    -> Bool
  {
    [0.5, 1.0, 2.0].contains { abs(a - b * $0) <= tol }
  }

  // MARK: - Synthetic click-track recovery (AC9)

  @Test(
    arguments: [
      ("bpm-120-click", 120.0),
      ("bpm-140-click", 140.0),
      ("bpm-170-click", 170.0),
      ("bpm-85-click", 85.0),
    ])
  func recoversClickTrackTempo(name: String, expectedBPM: Double) throws {
    let url = try AudioFixtures.url(for: name, extension: "wav")
    let grid = try #require(try AudioAnalysisService.analyzeBeatGrid(url: url))

    #expect(grid.beats.count > 0)
    #expect(grid.estimatedTempo > 0)
    // Octave-tolerant vs the click track's true tempo: octave correctness is the
    // BPM stage's job (the grid reports the BPM-stage tempo it tracked against,
    // whose octave is covered by the OA300/GiantSteps benchmarks).
    #expect(Self.matchesWithinOctave(grid.estimatedTempo, expectedBPM))

    // Monotonically increasing presentation times.
    for i in 1..<grid.beats.count {
      #expect(grid.beats[i].presentationTime > grid.beats[i - 1].presentationTime)
    }

    // strength / confidence bounds (also guaranteed by BeatTimestamp clamping;
    // asserted here as the analyzer's own contract).
    for b in grid.beats {
      #expect(b.strength >= 0 && b.strength <= 1)
      #expect(b.confidence >= 0 && b.confidence <= 1)
    }
    #expect(grid.confidence >= 0 && grid.confidence <= 1)

    // Standalone beat grid: no BPM stage compared alongside (Story 8.5 sets
    // tempoAgreement only inside the combined `analyze(...)` path).
    #expect(grid.downbeats == .notAttempted)
    #expect(grid.tempoAgreement == .notCompared)
  }

  // MARK: - Real-fixture agreement with analyzeBPM (AC6)

  @Test(arguments: ["Meta_Man", "Quantum_Cascade"])
  func agreesWithAnalyzeBPM(name: String) throws {
    let url = try AudioFixtures.url(for: name, extension: "mp3")
    let bpmResult = try #require(try AudioAnalysisService.analyzeBPM(url: url))
    let grid = try #require(try AudioAnalysisService.analyzeBeatGrid(url: url))

    #expect(grid.beats.count > 0)
    #expect(grid.estimatedTempo > 0)
    // Octave-tolerant on purpose: `analyzeBPM` aggregates multiple windows +
    // metadata corroboration, while `analyzeBeatGrid` tracks a single window, so
    // their octave choices can legitimately differ. Cross-stage octave agreement
    // is the combined-`analyze` consistency contract's job (TempoAgreement), not
    // what this standalone fixture-level check asserts.
    #expect(Self.matchesWithinOctave(grid.estimatedTempo, bpmResult.bpm))
  }

  // MARK: - Tempo lock (BeatGridTempoLock)

  /// Runs the combined `analyze(decoded:)` path over a 12 s synthetic click track
  /// (computeBeatGrid on) for the given lock mode.
  private static func analyzeClick(bpm: Double, lock: BeatGridTempoLock) throws
    -> CombinedAnalysisResult
  {
    let samples = generateClickTrack(bpm: bpm, sampleRate: 44100, durationSeconds: 12)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 44100)
    var opts = AudioAnalysisService.Options()
    opts.beatGridTempoLock = lock
    return try #require(try AudioAnalysisService.analyze(decoded: decoded, options: opts))
  }

  @Test func tempoLockBpmStageSnapsToAuthoritativeTempoAtGridOctave() throws {
    let off = try Self.analyzeClick(bpm: 120, lock: .off)
    let locked = try Self.analyzeClick(bpm: 120, lock: .bpmStage)
    let offGrid = try #require(off.beatGrid)
    let lockedGrid = try #require(locked.beatGrid)
    // Locking never changes the octave: the locked tempo stays within the 2% band
    // of the tracker's own tempo (it does NOT halve/double the grid).
    #expect(
      abs(lockedGrid.estimatedTempo - offGrid.estimatedTempo) / offGrid.estimatedTempo <= 0.02)
    // The locked tempo IS the authoritative BPM-stage tempo, octave-normalized.
    #expect(Self.matchesWithinOctave(lockedGrid.estimatedTempo, locked.bpm.bpm))
    // When tracker and BPM stage already share an octave (the clean-click case),
    // lock pulls the grid tempo exactly onto the BPM-stage value — drift removed.
    if abs(offGrid.estimatedTempo - locked.bpm.bpm) / locked.bpm.bpm <= 0.02 {
      #expect(lockedGrid.estimatedTempo == locked.bpm.bpm)
    }
  }

  @Test func tempoLockOffKeepsTrackerTempoAndAgreementDiagnostic() throws {
    let off = try Self.analyzeClick(bpm: 120, lock: .off)
    let grid = try #require(off.beatGrid)
    #expect(grid.estimatedTempo > 0)
    // .off keeps the tracker's measured tempo and a real agreement classification
    // (the combined path always classifies; locking only overrides the scalar).
    #expect(grid.tempoAgreement != .notCompared)
  }

  @Test func tempoLockExplicitBPMLocksWithinOctaveAndIgnoresAbsurd() throws {
    let off = try Self.analyzeClick(bpm: 120, lock: .off)
    let offTempo = try #require(off.beatGrid).estimatedTempo

    // Pin to the tracker's own tempo -> same octave -> locks to it exactly.
    let pinned = try Self.analyzeClick(bpm: 120, lock: .bpm(offTempo))
    #expect(try #require(pinned.beatGrid).estimatedTempo == offTempo)

    // An absurd 1 BPM target disagrees by more than an octave -> NOT locked; the
    // tracker's tempo stands (identical to .off on the same deterministic input).
    let absurd = try Self.analyzeClick(bpm: 120, lock: .bpm(1.0))
    #expect(try #require(absurd.beatGrid).estimatedTempo == offTempo)
  }

  // MARK: - Deterministic DP recovery (no decode)

  @Test func recoversBeatsFromSyntheticPeriodicEnvelope() throws {
    let onsetRate = 100.0
    let hop = 441
    let sr = 44100.0
    let period = 50  // 100 Hz / (120 BPM / 60) = 50 frames per beat
    let env = Self.impulseEnvelope(frames: 1000, periodFrames: period)

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: onsetRate, hopSize: hop, sampleRate: sr,
        acf: env, tempoBPM: 120, windowStartSample: 0))

    // ~20 beats over 1000 frames at period 50.
    #expect(grid.beats.count >= 15)
    #expect(abs(grid.estimatedTempo - 120) <= 5)

    // Beats land on (or within one frame of) the impulse positions.
    for b in grid.beats {
      let frame = Int((b.presentationTime * sr / Double(hop)).rounded())
      let phase = frame % period
      #expect(phase <= 1 || phase >= period - 1)
    }
  }

  /// Regression for the windowed-endpoint silent-tail GHOST beat (Codex diff
  /// review): onsets at frames 0/50/100/150/200 followed by > dMax (= 2·period =
  /// 100) frames of silence. The real last beat (frame 200) is excluded from the
  /// final endpoint window `[n − dMax, n)`, and the DP's inherited score stays
  /// positive through the silent tail, so without trimming the endpoint lands on
  /// a ghost beat in the silence. After trimming, every detected beat sits on a
  /// real onset and the last beat IS the last real onset.
  @Test func trimsGhostBeatsInTrailingSilence() throws {
    let sr = 44100.0
    let hop = 441
    let onsetRate = 100.0
    let period = 50
    var env = [Float](repeating: 0, count: 350)  // last onset at 200, silence to 349
    for f in stride(from: 0, to: 201, by: period) { env[f] = 1 }

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: onsetRate, hopSize: hop, sampleRate: sr,
        acf: env, tempoBPM: 120, windowStartSample: 0))

    // No beat in the silent tail: every detected beat has real onset strength.
    #expect(grid.beats.allSatisfy { $0.strength > 0 })
    // The last beat is the last real onset (frame 200), not a ghost past it.
    let lastFrame = Int((grid.beats.last!.presentationTime * sr / Double(hop)).rounded())
    #expect(
      lastFrame == 200, "last beat at frame \(lastFrame) — expected the last real onset (200)")
  }

  /// A2: the first/last REAL onsets are QUIET (0.02 — below the old `envMax * 0.05` =
  /// 0.05 global floor). The old per-beat-salience trim wrongly dropped them as ghosts;
  /// the local contiguous-silent-region test keeps them (their span carries their own
  /// onset) and trims only the genuinely silent tail. Fails under the old logic.
  @Test func keepsQuietRealEdgeBeats() throws {
    let sr = 44100.0
    let hop = 441
    let onsetRate = 100.0
    let period = 50
    var env = [Float](repeating: 0, count: 350)
    for f in stride(from: 0, to: 201, by: period) { env[f] = 1 }
    env[0] = 0.02  // quiet fade-in first beat
    env[200] = 0.02  // quiet fade-out last beat

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: onsetRate, hopSize: hop, sampleRate: sr,
        acf: env, tempoBPM: 120, windowStartSample: 0))

    let frames = grid.beats.map { Int(($0.presentationTime * sr / Double(hop)).rounded()) }
    #expect(frames.first == 0, "quiet first beat (frame 0) must be kept, got \(frames)")
    #expect(frames.last == 200, "quiet last beat (frame 200) must be kept, got \(frames)")
  }

  /// A2 honest limit (Codex): a real beat whose onset envelope is exactly 0 (e.g. an
  /// onset `adaptiveThreshold` zeroed upstream) is INDISTINGUISHABLE from a ghost and is
  /// trimmed. Locked so the limitation is intentional, not accidental.
  @Test func thresholdedToZeroEdgeBeatIsTrimmed() throws {
    let sr = 44100.0
    let hop = 441
    let onsetRate = 100.0
    let period = 50
    var env = [Float](repeating: 0, count: 350)
    for f in stride(from: 0, to: 201, by: period) { env[f] = 1 }
    env[200] = 0  // a real last beat whose onset was zeroed → trimmed (cannot tell from a ghost)

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: onsetRate, hopSize: hop, sampleRate: sr,
        acf: env, tempoBPM: 120, windowStartSample: 0))

    let lastFrame = Int((grid.beats.last!.presentationTime * sr / Double(hop)).rounded())
    #expect(lastFrame == 150, "a zeroed-onset last beat is trimmed; last real onset is 150")
  }

  /// A2 honest limit (Codex): a silent tail with a low-level noise floor ABOVE
  /// `silenceEps` (0.0005 > envMax·1e-4 = 1e-4) is not "silent" to the local test, so a
  /// DP ghost in it is RETAINED. Conservative by design (keeping a beat is safer than
  /// dropping a real one); locked so the limit is intentional, not accidentally "fixed".
  @Test func noisyTailRetainsGhostConservatively() throws {
    let sr = 44100.0
    let hop = 441
    let onsetRate = 100.0
    let period = 50
    var env = [Float](repeating: 0.0005, count: 350)  // noise floor in the "silent" tail
    for f in stride(from: 0, to: 201, by: period) { env[f] = 1 }

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: onsetRate, hopSize: hop, sampleRate: sr,
        acf: env, tempoBPM: 120, windowStartSample: 0))

    let lastFrame = Int((grid.beats.last!.presentationTime * sr / Double(hop)).rounded())
    #expect(
      lastFrame > 200, "noisy tail (> silenceEps) retains a ghost past frame 200, got \(lastFrame)")
  }

  /// A2 scale-invariance (Codex PR #40): the trim threshold is RELATIVE to `envMax`, so a
  /// scaled-down envelope (`envMax << 1`, even below `1e-4`) keeps the same edge beats as
  /// the loud one — the tracker normalizes by `envMax` everywhere and the trim must too.
  /// An absolute floor would strip every edge beat once the peak dropped below it.
  @Test func ghostTrimIsScaleInvariant() throws {
    let sr = 44100.0
    let hop = 441
    let onsetRate = 100.0
    let period = 50
    var env = [Float](repeating: 0, count: 350)
    for f in stride(from: 0, to: 201, by: period) { env[f] = 1 }
    env[0] = 0.02  // quiet fade-in first beat
    env[200] = 0.02  // quiet fade-out last beat

    func edgeFrames(scale: Float) throws -> (first: Int, last: Int) {
      let scaled = env.map { $0 * scale }
      let grid = try #require(
        BeatGridAnalyzer.estimateBeatGrid(
          onsetEnvelope: scaled, onsetRate: onsetRate, hopSize: hop, sampleRate: sr,
          acf: scaled, tempoBPM: 120, windowStartSample: 0))
      let frames = grid.beats.map { Int(($0.presentationTime * sr / Double(hop)).rounded()) }
      return (frames.first!, frames.last!)
    }

    // Loud (envMax = 1) keeps the quiet edges; a 1e-5-scaled copy (envMax = 1e-5 << 1e-4)
    // must keep exactly the same edges — not get stripped by an absolute floor.
    #expect(try edgeFrames(scale: 1) == (0, 200))
    #expect(
      try edgeFrames(scale: 1e-5) == (0, 200),
      "scaled-down envelope (envMax << 1) must keep the edge beats")
  }

  @Test func presentationTimeIsTrackRelative() throws {
    let env = Self.impulseEnvelope(frames: 1000, periodFrames: 50)
    let offsetSamples = 44100  // 1 second of leading audio before the window

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100.0, hopSize: 441, sampleRate: 44100.0,
        acf: env, tempoBPM: 120, windowStartSample: offsetSamples))

    // Every beat is shifted by the window start offset (DD #6 track-relative time).
    #expect(grid.beats.allSatisfy { $0.presentationTime >= 1.0 })
  }

  // MARK: - Per-beat confidence reads the last EMITTED beat frame (#56)

  /// On a perfectly periodic envelope every inter-beat interval equals `period`,
  /// so `log(interval / period) == 0` and confidence `exp(0) == 1`. Pins the
  /// post-fix behavior: interior-beat confidence is ~1.0. (RED proof: pointing the
  /// interval source at a constant wrong frame makes these intervals != period,
  /// dropping the confidences below 1.0 — verified out-of-band, then reverted.)
  @Test func evenlySpacedBeatsHaveUnitConfidence() throws {
    let env = Self.impulseEnvelope(frames: 1000, periodFrames: 50)
    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44100,
        acf: env, tempoBPM: 120, windowStartSample: 0))

    // Skip index 0 (its confidence is raw strength, no prior interval).
    for b in grid.beats.dropFirst() {
      #expect(abs(b.confidence - 1.0) < 1e-3)
    }
    // No NaN/Inf confidence anywhere.
    #expect(grid.beats.allSatisfy { $0.confidence.isFinite })
  }

  /// Locks per-beat confidence to the interval against the actual previous
  /// EMITTED beat frame (the invariant the #56 fix establishes by reading
  /// `beatFrames.last`). Reconstructs each adjacent emitted-frame interval from
  /// the track-relative presentation times and recomputes the closed-form
  /// confidence; the buggy `frames[k-1]` form would violate this the moment a
  /// frame is skipped.
  @Test func perBeatConfidenceMatchesEmittedFrameInterval() throws {
    let hop = 441
    let sr = 44100.0
    let period = 50.0
    let env = Self.impulseEnvelope(frames: 1000, periodFrames: Int(period))

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: hop, sampleRate: sr,
        acf: env, tempoBPM: 120, windowStartSample: 0))
    try #require(grid.beats.count >= 2)

    func frame(_ t: Double) -> Int { Int((t * sr / Double(hop)).rounded()) }
    for i in 1..<grid.beats.count {
      let prev = frame(grid.beats[i - 1].presentationTime)
      let cur = frame(grid.beats[i].presentationTime)
      let interval = Double(cur - prev)
      let r = interval > 0 ? log(interval / period) : 0
      let expected = Float(exp(-r * r))
      #expect(abs(grid.beats[i].confidence - expected) < 1e-2)
    }
  }

  // MARK: - Degenerate inputs return nil (AC9)

  @Test func emptyEnvelopeReturnsNil() {
    #expect(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: [], onsetRate: 100, hopSize: 441, sampleRate: 44100,
        acf: [], tempoBPM: 120, windowStartSample: 0) == nil)
  }

  @Test func nonPositiveOrNonFiniteTempoReturnsNil() {
    let env = [Float](repeating: 1, count: 500)
    for bad in [0.0, -120.0, Double.nan, Double.infinity] {
      #expect(
        BeatGridAnalyzer.estimateBeatGrid(
          onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44100,
          acf: env, tempoBPM: bad, windowStartSample: 0) == nil)
    }
  }

  /// A tiny-but-finite tempo makes `period` enormous-but-finite (here ~6e20),
  /// which must be rejected as "shorter than one beat period" BEFORE the
  /// `Int((period * 2).rounded())` conversion — otherwise that conversion traps
  /// (Double outside Int range) or the `txCost` span over-allocates. The
  /// `period <= Double(n)` guard closes both.
  @Test func absurdlySmallTempoReturnsNil() {
    let env = [Float](repeating: 1, count: 1000)
    #expect(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44100,
        acf: env, tempoBPM: 1e-17, windowStartSample: 0) == nil)
  }

  @Test func allZeroEnvelopeReturnsNil() {
    let env = [Float](repeating: 0, count: 500)
    #expect(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44100,
        acf: env, tempoBPM: 120, windowStartSample: 0) == nil)
  }

  /// A window of EXACTLY one beat period is degenerate: it cannot hold the two
  /// beats `selectGridOrigin`'s phase path needs, so `estimateBeatGrid` must
  /// reject it (the doc promises nil for "a window shorter than two beat
  /// periods"). At 120 BPM / onsetRate 100, `period == 50`, so `n == period`. (#57)
  @Test func oneBeatPeriodWindowReturnsNil() {
    let env = Self.impulseEnvelope(frames: 50, periodFrames: 50)  // period == n == 50
    #expect(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44100,
        acf: env, tempoBPM: 120, windowStartSample: 0) == nil)
  }

  /// Just below two periods (`n == 2*period - 1`) is still rejected — pins the
  /// lower side of the new cutoff. (#57)
  @Test func justUnderTwoBeatPeriodsReturnsNil() {
    let env = Self.impulseEnvelope(frames: 99, periodFrames: 50)  // n = 2*period - 1
    #expect(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44100,
        acf: env, tempoBPM: 120, windowStartSample: 0) == nil)
  }

  /// At exactly two periods (`n == 2*period`) a grid IS produced, with >= 2 beats
  /// — pins the upper side of the new cutoff. (#57)
  @Test func exactlyTwoBeatPeriodsProducesMultiBeatGrid() throws {
    let env = Self.impulseEnvelope(frames: 100, periodFrames: 50)  // n = 2*period
    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44100,
        acf: env, tempoBPM: 120, windowStartSample: 0))
    #expect(grid.beats.count >= 2)
  }

  @Test func tooShortFileReturnsNil() throws {
    // 1 second is below the BPM pipeline's 4 s minimum → estimateBPM nil → grid nil.
    let samples = [Float](repeating: 0.5, count: 44100)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 44100)
    #expect(try AudioAnalysisService.analyzeBeatGrid(decoded: decoded) == nil)
  }

  @Test func silentFileReturnsNil() throws {
    // 10 s of silence: passes the duration gate, fails the silence check → nil.
    let samples = [Float](repeating: 0, count: 44100 * 10)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 44100)
    #expect(try AudioAnalysisService.analyzeBeatGrid(decoded: decoded) == nil)
  }

  @Test func floorSampleRateIsAcceptedNotRejected() throws {
    // A1: the analyzer's `minOnsetSampleRate` floor (8 kHz) mirrors `DecodedAudio`'s
    // precondition and must be INCLUSIVE — a carrier at exactly 8 kHz still produces a
    // grid. The guard prevents the `hopSize == 0` / non-finite-`Int` trap; it must not
    // over-reject the floor. Sub-8 kHz (and non-finite) rates are unconstructable via
    // `DecodedAudio`'s precondition, so the guard's rejection path is defense-in-depth.
    let samples = generateClickTrack(bpm: 120, sampleRate: 8000, durationSeconds: 12)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 8000)
    #expect(try AudioAnalysisService.analyzeBeatGrid(decoded: decoded) != nil)
  }

  @Test func absurdSampleRateOrWindowIsRejectedNotTrapped() throws {
    // A1: a huge-but-finite sample rate (allowed by DecodedAudio's `>= 8000` precondition)
    // is above the onset ceiling → rejected (nil), so `Int(sampleRate)` / `Int(sampleRate
    // / 100)` cannot overflow-trap.
    let samples = generateClickTrack(bpm: 120, sampleRate: 48000, durationSeconds: 12)
    let tooHigh = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 1_000_000)
    #expect(try AudioAnalysisService.analyzeBeatGrid(decoded: tooHigh) == nil)

    // A hostile huge-but-finite `analysisWindowSeconds` must CLAMP to the buffer, not trap
    // `Int(seconds * sampleRate)` — a valid result still comes back.
    let ok = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 48000)
    var bpmOptions = BPMAnalyzer.Options()
    bpmOptions.analysisWindowSeconds = 1e300
    #expect(BPMAnalyzer.estimateBPM(decoded: ok, options: bpmOptions) != nil)
  }

  @Test func withTempoAgreementKeepsAnchorConsistent() throws {
    // A4 composition: `with(tempoAgreement:)` re-enters `BeatGrid.init`, so the anchor
    // rebuild composes through the W52 forwarding copy. The grid's anchor is already
    // repaired at construction (a hostile in-range anchor → rebuilt from its beat); the
    // restamp keeps it consistent (the rebuild is idempotent — no drift).
    let beats = (0..<6).map {
      BeatTimestamp(presentationTime: Double($0) * 0.5, confidence: 0.8, strength: 0.5)
    }
    let grid = BeatGrid(
      beats: beats, downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared,
      gridOrigin: BeatGridAnchor(
        beatIndex: 1, presentationTime: 999, confidence: 0.1, strength: 0.05,
        source: .strongestBeat),
      coverage: .analysisWindow)
    #expect(grid.gridOrigin?.presentationTime == beats[1].presentationTime)  // repaired
    let restamped = grid.with(tempoAgreement: .agree)
    #expect(restamped.tempoAgreement == .agree)
    #expect(restamped.gridOrigin == grid.gridOrigin)  // idempotent, stays consistent
  }

  // MARK: - Default-path byte-identity (AC4)

  @Test func defaultPathLeavesBPMResultByteIdentical() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)

    // Default options: the fan-out branch is not entered.
    let baseline = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: .init()))
    #expect(baseline.beatGrid == nil)

    // Enabling computeBeatGrid must NOT perturb bpm / confidence / candidates —
    // beat grid is a parallel output, the DSP result is unchanged.
    var withGrid = BPMAnalyzer.Options()
    withGrid.computeBeatGrid = true
    let augmented = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: withGrid))

    #expect(augmented.beatGrid != nil)
    // Byte-identity: bitPattern equality (the project "byte-equality opt-out"
    // convention), not `==` — distinguishes ±0.0 and would not silently pass a
    // NaN mismatch.
    #expect(augmented.bpm.bitPattern == baseline.bpm.bitPattern)
    #expect(augmented.confidence.bitPattern == baseline.confidence.bitPattern)
    try #require(augmented.candidates.count == baseline.candidates.count)
    for i in 0..<augmented.candidates.count {
      #expect(augmented.candidates[i].bpm.bitPattern == baseline.candidates[i].bpm.bitPattern)
      #expect(augmented.candidates[i].score.bitPattern == baseline.candidates[i].score.bitPattern)
    }
  }

  // MARK: - Story 8.5 helpers

  /// Decode-count probe for the shared-decode structural test (Mutex-backed so
  /// the `@Sendable` observer is strict-concurrency-clean).
  private final class DecodeProbe: Sendable {
    private let state = Mutex<Int>(0)
    func record() { state.withLock { $0 += 1 } }
    var count: Int { state.withLock { $0 } }
  }

  /// Writes mono `samples` to a temp lossless file (WAV LPCM or FLAC) via
  /// AVFoundation, then returns the URL. Lossless → the decoded PCM is
  /// sample-exact, so detected beats land on the known impulse positions (AC3).
  private static func writeLossless(
    _ samples: [Float], sampleRate: Double, formatID: AudioFormatID, ext: String
  ) throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("bbb-grid-\(UUID().uuidString).\(ext)")
    var settings: [String: Any] = [
      AVFormatIDKey: formatID,
      AVSampleRateKey: sampleRate,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 16,
    ]
    if formatID == kAudioFormatLinearPCM {
      settings[AVLinearPCMIsFloatKey] = false
      settings[AVLinearPCMIsBigEndianKey] = false
    }
    let file = try AVAudioFile(forWriting: url, settings: settings)
    let srcFormat = try #require(
      AVAudioFormat(
        commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1,
        interleaved: false))
    let buffer = try #require(
      AVAudioPCMBuffer(
        pcmFormat: srcFormat, frameCapacity: AVAudioFrameCount(samples.count)))
    buffer.frameLength = AVAudioFrameCount(samples.count)
    let dst = try #require(buffer.floatChannelData)
    samples.withUnsafeBufferPointer { src in
      dst[0].update(from: src.baseAddress!, count: samples.count)
    }
    try file.write(from: buffer)
    return url
  }

  /// Distance (in samples) from `samplePos` to the nearest impulse `k·period`.
  private static func distanceToNearestImpulse(samplePos: Double, period: Int) -> Double {
    let k = (samplePos / Double(period)).rounded()
    return abs(samplePos - k * Double(period))
  }

  // MARK: - AC3: decoded-PCM-relative alignment (independent ground truth)

  /// The decoded-PCM-relative timestamp contract (FR-30), tested via independent
  /// ground truth — NOT the circular `presentationTime → frame` round-trip.
  ///
  /// Click → lossless FLAC AND lossless WAV on disk → decode each via
  /// `PCMBufferReader` → assert:
  ///
  /// 1. **Codec-independence (the decisive check).** FLAC and WAV are both
  ///    lossless, so they decode to the same PCM with the same origin — the beats
  ///    land at the SAME times (within one hop). If priming were subtracted for
  ///    one container and not the other, they'd diverge by the encoder delay
  ///    (~thousands of samples). Equal times prove "decoded-PCM-relative, no
  ///    codec-dependent priming correction".
  /// 2. **Clean periodic grid with a constant, bounded onset latency.** Detected
  ///    beats sit at `impulse + L` for a single fixed `L` (the mel-onset / spectral-
  ///    flux detection delay — a DSP constant, NOT codec priming): every beat's
  ///    signed distance to its nearest impulse is within one hop of the mean, and
  ///    `|L|` is small (≤ ~10 hops). This is the honest form of "beats land on the
  ///    impulse grid": on-grid up to a fixed detection latency, not zero-latency.
  @Test func decodedPCMRelativeAlignmentIsCodecIndependent() throws {
    let bpm = 120.0
    let sampleRate = 44100.0
    let samplesPerBeat = Int(sampleRate * 60.0 / bpm)  // 22050
    let hopSize = Int(sampleRate / 100)  // 441
    let samples = generateClickTrack(bpm: bpm, sampleRate: sampleRate, durationSeconds: 40)

    let flacURL = try Self.writeLossless(
      samples, sampleRate: sampleRate, formatID: kAudioFormatFLAC, ext: "flac")
    let wavURL = try Self.writeLossless(
      samples, sampleRate: sampleRate, formatID: kAudioFormatLinearPCM, ext: "wav")
    defer {
      try? FileManager.default.removeItem(at: flacURL)
      try? FileManager.default.removeItem(at: wavURL)
    }

    let flacGrid = try #require(
      try AudioAnalysisService.analyzeBeatGrid(
        decoded: PCMBufferReader.readDecodedAudio(from: flacURL)))
    let wavGrid = try #require(
      try AudioAnalysisService.analyzeBeatGrid(
        decoded: PCMBufferReader.readDecodedAudio(from: wavURL)))
    #expect(flacGrid.beats.count > 0)

    // (1) Codec-independent decoded-PCM-relative timing: lossless FLAC and WAV
    // yield the SAME beat times (no priming subtraction differs between formats).
    try #require(flacGrid.beats.count == wavGrid.beats.count)
    let hopSeconds = Double(hopSize) / sampleRate
    for (f, w) in zip(flacGrid.beats, wavGrid.beats) {
      #expect(
        abs(f.presentationTime - w.presentationTime) <= hopSeconds,
        "FLAC beat \(f.presentationTime)s vs WAV \(w.presentationTime)s differ by more than one hop — a codec-dependent priming offset"
      )
    }

    // (2) Periodic grid at a constant, bounded onset latency — robust to the
    // occasional off-grid beat the DP places at a window edge (which is exactly
    // WHY a consumer anchors on `gridOrigin` instead of trusting every beat).
    // Use the MEDIAN phase and require the vast majority of beats to sit on it.
    let phases = wavGrid.beats.map { beat -> Double in
      let pos = beat.presentationTime * sampleRate
      let k = (pos / Double(samplesPerBeat)).rounded()
      return pos - k * Double(samplesPerBeat)  // signed distance to nearest impulse
    }
    let medianPhase = phases.sorted()[phases.count / 2]
    let onGrid = phases.filter { abs($0 - medianPhase) <= Double(hopSize) }.count
    let fraction = Double(onGrid) / Double(phases.count)
    #expect(
      fraction >= 0.9,
      "only \(Int(fraction * 100))% of beats sit on the constant-latency grid (median phase \(medianPhase))"
    )
    #expect(
      abs(medianPhase) <= Double(10 * hopSize),
      "onset latency \(medianPhase) samples exceeds the ~10-hop bound — unexpectedly large detection delay"
    )
  }

  // MARK: - AC4: gridOrigin lands on a real beat, phase-consistency selected

  @Test func gridOriginIsPhaseConsistent() throws {
    let samples = generateClickTrack(bpm: 120, sampleRate: 44100, durationSeconds: 40)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 44100)
    let grid = try #require(try AudioAnalysisService.analyzeBeatGrid(decoded: decoded))

    let anchor = try #require(grid.gridOrigin)
    // Anchor indexes a real beat and reports that beat's exact time. An auto-produced
    // anchor is always COUPLED (non-nil beatIndex); only a manual `.exactTime` reposition
    // decouples it (Story 8.12).
    let beatIndex = try #require(anchor.beatIndex)
    try #require(beatIndex >= 0 && beatIndex < grid.beats.count)
    #expect(anchor.presentationTime == grid.beats[beatIndex].presentationTime)
    #expect(anchor.confidence >= 0 && anchor.confidence <= 1)
    #expect(anchor.strength >= 0 && anchor.strength <= 1)
    // A clean periodic click → phase consistency fires (not a fallback).
    #expect(anchor.source == .medianConsistentBeat)
  }

  @Test func gridOriginNilWhenNoBeats() {
    // All-zero envelope → no beats → estimateBeatGrid returns nil (so no anchor
    // to test); the empty-grid `nil` anchor path is covered by the sentinel
    // shape in BeatGridTypesTests. Here we assert the degenerate analyzer path.
    #expect(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: [Float](repeating: 0, count: 500), onsetRate: 100, hopSize: 441,
        sampleRate: 44100, acf: [Float](repeating: 0, count: 500), tempoBPM: 120,
        windowStartSample: 0) == nil)
  }

  // MARK: - AC7: tempo-agreement classification (deterministic, on the classifier)

  @Test func tempoAgreementClassification() {
    // Octave: grid is 2× the BPM stage → +2; grid is ½× → -2 (2manyDJs 87/174).
    #expect(
      AudioAnalysisService.classifyTempoAgreement(gridTempo: 174, bpmTempo: 87)
        == .octaveEquivalent(factor: 2))
    #expect(
      AudioAnalysisService.classifyTempoAgreement(gridTempo: 87, bpmTempo: 174)
        == .octaveEquivalent(factor: -2))
    // Within ~2% relative → agree.
    #expect(
      AudioAnalysisService.classifyTempoAgreement(gridTempo: 120, bpmTempo: 121)
        == .agree)
    #expect(
      AudioAnalysisService.classifyTempoAgreement(gridTempo: 128, bpmTempo: 128)
        == .agree)
    // Non-octave mismatch → disagree (120 vs 137).
    #expect(
      AudioAnalysisService.classifyTempoAgreement(gridTempo: 120, bpmTempo: 137)
        == .disagree)
    // 4× is NOT an octave-equivalent (2× only) → disagree.
    #expect(
      AudioAnalysisService.classifyTempoAgreement(gridTempo: 120, bpmTempo: 30)
        == .disagree)
    // Degenerate inputs → the safe "don't auto-sync" answer.
    #expect(
      AudioAnalysisService.classifyTempoAgreement(gridTempo: 0, bpmTempo: 120) == .disagree)
    #expect(
      AudioAnalysisService.classifyTempoAgreement(gridTempo: 120, bpmTempo: .nan)
        == .disagree)
  }

  // MARK: - AC6 / AC10: combined analyze() shares one decode + leaves BPM byte-identical

  @Test func combinedAnalyzeSharesOneDecode() throws {
    let url = try AudioFixtures.url(for: "Quantum_Cascade", extension: "mp3")
    let probe = DecodeProbe()
    let result = try AudioAnalysisService.analyze(
      url: url, options: .init(), decodeObserver: { _ in probe.record() })
    #expect(result != nil)
    #expect(probe.count == 1, "analyze(url:) must decode exactly once (FR-35)")
  }

  @Test func combinedAnalyzeLeavesStandaloneBPMByteIdentical() throws {
    let url = try AudioFixtures.url(for: "Quantum_Cascade", extension: "mp3")
    let standalone = try #require(try AudioAnalysisService.analyzeBPM(url: url))
    let combined = try #require(try AudioAnalysisService.analyze(url: url))

    #expect(combined.bpm.bpm.bitPattern == standalone.bpm.bitPattern)
    #expect(combined.bpm.confidence.bitPattern == standalone.confidence.bitPattern)
    try #require(combined.bpm.candidates.count == standalone.candidates.count)
    for i in 0..<standalone.candidates.count {
      #expect(combined.bpm.candidates[i].bpm.bitPattern == standalone.candidates[i].bpm.bitPattern)
      #expect(
        combined.bpm.candidates[i].score.bitPattern == standalone.candidates[i].score.bitPattern)
    }
  }

  @Test func combinedAnalyzeResolvesTempoAgreement() throws {
    let url = try AudioFixtures.url(for: "Quantum_Cascade", extension: "mp3")
    let result = try #require(try AudioAnalysisService.analyze(url: url))
    let grid = try #require(result.beatGrid)
    // Both stages ran → agreement was compared (never .notCompared on this path).
    #expect(grid.tempoAgreement != .notCompared)
    // Both raw tempos remain accessible (2manyDJs recovers octave cases from them).
    #expect(result.bpm.bpm > 0)
    #expect(grid.estimatedTempo > 0)
  }

  // MARK: - AC8: per-file consistency invariant over enumerated committed fixtures

  /// Enumerated ANALYZABLE committed fixtures only. The 1-second
  /// `sample-with-cover.*` / `test-audio.*` / `sample.wav` clips the spec listed
  /// are below the BPM pipeline's 4 s minimum, so `analyze` correctly returns
  /// `nil` (no BPM stage) — they cannot exercise a BPM/grid consistency invariant.
  /// The real-music fixtures (30 s) + the 5 s BWF + the committed click WAVs are
  /// the honest set.
  @Test(
    arguments: [
      ("Meta_Man", "mp3"), ("Quantum_Cascade", "mp3"), ("Submerged_Lament", "mp3"),
      ("test-bwf", "wav"),
      ("bpm-85-click", "wav"), ("bpm-120-click", "wav"),
      ("bpm-140-click", "wav"), ("bpm-170-click", "wav"),
    ])
  func consistencyContract(name: String, ext: String) throws {
    let url = try AudioFixtures.url(for: name, extension: ext)
    let result = try #require(
      try AudioAnalysisService.analyze(url: url),
      "\(name).\(ext): analyze returned nil")
    let grid = try #require(result.beatGrid, "\(name).\(ext): no beat grid")
    // Both stages ran.
    #expect(
      grid.tempoAgreement != .notCompared,
      "\(name).\(ext): tempoAgreement is .notCompared — a stage did not run")
    // Non-pathological committed music: sync-usable (agree or a recoverable octave),
    // never a hard disagreement.
    let usable: Bool
    switch grid.tempoAgreement {
    case .agree, .octaveEquivalent:
      usable = true
    case .disagree, .notCompared:
      usable = false
    }
    #expect(
      usable,
      "\(name).\(ext): tempoAgreement is \(grid.tempoAgreement) (grid \(grid.estimatedTempo) vs bpm \(result.bpm.bpm)) — expected agree/octaveEquivalent"
    )
  }

  // MARK: - AC2: long-file sync stability

  /// Primary (default `.analysisWindow`, the consumer path): anchor + tempo
  /// extrapolation is drift-free on constant tempo. Uses a NON-integer-frame-period
  /// BPM (127 → samplesPerBeat = Int(20834.6) = 20834 ≈ 47.24 onset frames/beat) so
  /// the tempo estimate must be sub-frame accurate for the "drift-free by
  /// construction" claim to hold — the bound genuinely bites. The audio need only be
  /// long enough for a solid anchor; "minute 5" is the mathematical true-beat
  /// position, not decoded audio.
  ///
  /// **What this constrains** (three independent checks, so the 30 ms bound is
  /// not vacuous). Uses a NON-integer-frame-period BPM (127 → samplesPerBeat =
  /// Int(20834.6) = 20834 ≈ 47.24 onset frames/beat) precisely so the tempo
  /// estimate must be sub-frame accurate to pass — the bound genuinely bites:
  /// 1. **Tempo accuracy** — `estimatedTempo` lands on the true tempo within a
  ///    fraction of a BPM. The sub-frame inlier-mean estimator achieves this; the
  ///    old median-of-integer-frame estimate would round 47.24 → 47 and report
  ///    ~127.66 BPM (0.66 off), failing both this check and the drift bound below
  ///    (a 0.66-BPM error is ~1.5 s of drift at minute 5).
  /// 2. **Anchor accuracy** — the anchor lands on a real beat near a true impulse
  ///    (within the bounded onset-detection latency), not on garbage.
  /// 3. **Drift** — the ACCUMULATED spacing error `n·|extrapPeriod − truePeriod|`
  ///    over the ~600 beats to minute 5 stays ≤ 30 ms. The constant onset latency
  ///    is anchored out (it is an offset, not drift); the residual is pure tempo
  ///    error × distance, which check (1) keeps small.
  @Test func longFileSyncStabilityAnchorExtrapolation() throws {
    let bpm = 127.0
    let sampleRate = 44100.0
    let samplesPerBeat = Int(sampleRate * 60.0 / bpm)  // 20834 (non-integer-exact)
    let truePeriod = Double(samplesPerBeat) / sampleRate
    let trueTempo = 60.0 / truePeriod
    let hopSize = Int(sampleRate / 100)
    let samples = generateClickTrack(bpm: bpm, sampleRate: sampleRate, durationSeconds: 45)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: sampleRate)

    let grid = try #require(try AudioAnalysisService.analyzeBeatGrid(decoded: decoded))
    let anchor = try #require(grid.gridOrigin)
    try #require(grid.estimatedTempo > 0)

    // (1) Tempo accuracy: the reported tempo equals the true generator tempo to
    // within 0.1 BPM (the old integer-frame median missed by ~0.66, an inlier-mean
    // re-measurement by ~0.22 — both would fail here and the drift bound below).
    #expect(
      abs(grid.estimatedTempo - trueTempo) <= 0.1,
      "estimatedTempo \(grid.estimatedTempo) is not the true tempo \(trueTempo)")

    // (2) Anchor accuracy: the anchor is a real beat sitting within the bounded
    // onset latency (~10 hops) of a true impulse. An auto anchor is always coupled.
    let anchorIndex = try #require(anchor.beatIndex)
    #expect(anchor.presentationTime == grid.beats[anchorIndex].presentationTime)
    let anchorPos = anchor.presentationTime * sampleRate
    let anchorImpulseDist = Self.distanceToNearestImpulse(
      samplePos: anchorPos, period: samplesPerBeat)
    #expect(
      anchorImpulseDist <= Double(10 * hopSize),
      "anchor at sample \(anchorPos) is \(anchorImpulseDist) samples from the nearest impulse (> 10 hops)"
    )

    // (3) Drift: accumulated spacing error from the anchor out to minute 5.
    let extrapPeriod = 60.0 / grid.estimatedTempo
    let n = ((300.0 - anchor.presentationTime) / extrapPeriod).rounded()
    let driftMs = abs(extrapPeriod * n - truePeriod * n) * 1000.0
    #expect(
      driftMs <= 30.0,
      "anchor+tempo extrapolation accumulates \(driftMs) ms of drift to minute 5 (> 30 ms)")
  }

  /// Secondary (`.fullTrack`): over a real 5+ minute decode at a NON-integer-exact
  /// BPM (127 → samplesPerBeat = Int(20834.6) = 20834), the detected grid HOLDS
  /// PHASE across the whole file — the late beats sit at the same offset-to-impulse
  /// as the early beats, so there is no accumulating drift.
  ///
  /// **Drift, not latency.** Each detected beat carries the same constant
  /// onset-detection latency (~50 ms — see the codec-independence test). That is
  /// not drift. So compare the LAST beat's phase (signed distance to the nearest
  /// true generator-period impulse) to the FIRST beat's phase: the constant
  /// latency cancels and the difference is the accumulated drift over 5 minutes.
  /// Compared against the generator's KNOWN integer period (independent ground
  /// truth), NOT the grid's own `estimatedTempo` (which would round-trip).
  ///
  /// **Why relative phase, not the AC's literal "last detected beat" bound.** AC2's
  /// literal secondary names `firstBeatTime + period·beatIndex` for the last *detected*
  /// beat. The raw detected beats snap to the nearest ~10 ms onset frame, and that
  /// per-beat quantization accumulates to ~40-50 ms over 5 minutes — so an absolute
  /// raw-last-beat bound is NOT a property the library guarantees. The drift-free
  /// mid-track contract is `gridOrigin + estimatedTempo` EXTRAPOLATION (proven ≤ 30 ms
  /// in `longFileSyncStabilityAnchorExtrapolation`); consumers extrapolate rather than
  /// trusting each raw `beats` entry. This test bounds the detected grid's RELATIVE
  /// phase stability (early vs late median) — the faithful "no accumulating drift"
  /// realization for the detected beats — and the absolute bound lives with the
  /// extrapolation, where the contract puts it.
  @Test func longFileSyncStabilityFullTrackDrift() throws {
    let bpm = 127.0
    let sampleRate = 44100.0
    let samplesPerBeat = Int(sampleRate * 60.0 / bpm)  // 20834 (non-integer-exact)
    let truePeriod = Double(samplesPerBeat) / sampleRate
    let samples = generateClickTrack(bpm: bpm, sampleRate: sampleRate, durationSeconds: 305)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: sampleRate)

    var options = AudioAnalysisService.Options()
    options.beatGridCoverage = .fullTrack
    options.maxSeconds = 400  // admit the full 305 s decode

    let grid = try #require(
      try AudioAnalysisService.analyzeBeatGrid(decoded: decoded, options: options))
    #expect(grid.coverage == .fullTrack)
    // Full coverage → far more than the ~64 beats a 30 s window would yield.
    #expect(grid.beats.count > 400, "expected full-track beat coverage, got \(grid.beats.count)")

    let last = try #require(grid.beats.last)
    #expect(
      last.presentationTime > 290.0,
      "last detected beat at \(last.presentationTime)s — full track not covered")

    // Signed phase (distance to nearest true impulse, in seconds).
    func phase(_ t: Double) -> Double {
      let k = (t / truePeriod).rounded()
      return t - k * truePeriod
    }
    func median(_ xs: ArraySlice<Double>) -> Double {
      let s = xs.sorted()
      return s[s.count / 2]
    }
    // Compare the MEDIAN phase of the first 10% of beats to the last 10%. Medians
    // are robust to the handful of loose beats at the DP's window edges (the
    // endpoint beat in particular is chosen by score, not guaranteed on-impulse);
    // any real ACCUMULATING drift would shift the late median away from the early
    // one. Phase-locked tracking → the two medians match within 30 ms.
    let phases = grid.beats.map { phase($0.presentationTime) }
    let chunk = max(1, phases.count / 10)
    let earlyMedian = median(phases.prefix(chunk))
    let lateMedian = median(phases.suffix(chunk))
    let driftMs = abs(lateMedian - earlyMedian) * 1000.0
    #expect(
      driftMs <= 30.0,
      "grid phase drifts \(driftMs) ms from the first 10% to the last 10% of beats over 5 min (> 30 ms)"
    )
  }
}
