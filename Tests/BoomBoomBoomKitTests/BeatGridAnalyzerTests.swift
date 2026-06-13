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

import BoomBoomBoomKitTestSupport
import Foundation
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
    // BPM stage's job (the grid faithfully inherits the octave it was handed,
    // covered by the OA300/GiantSteps benchmarks). That the grid's reported tempo
    // is octave-LOCKED to the tempo it actually tracked — the C2 snap's
    // contract — is proven deterministically by `nearestOctaveEquivalentSnapsToReferenceOctave`.
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

    // Story 8.4 scope: beats only, no BPM stage alongside.
    #expect(grid.downbeats == .notAttempted)
    #expect(grid.tempoAgreedWithBPMStage == nil)
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
    // their octave choices can legitimately differ. The strict C2 contract (the
    // grid agreeing with the SAME single-window tempo it tracked against) is
    // proven by `nearestOctaveEquivalentSnapsToReferenceOctave`; cross-stage
    // octave agreement is not what this fixture-level check asserts.
    #expect(Self.matchesWithinOctave(grid.estimatedTempo, bpmResult.bpm))
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

  // MARK: - C2 octave snap (deterministic)

  /// Proves the `estimatedTempo` octave-lock contract directly on the snap
  /// helper: a half/double tracked tempo snaps to the BPM-stage octave, in-octave
  /// drift is preserved, a non-octave ratio passes through unchanged, and a
  /// degenerate `measured` returns the reference. (With `tightness = 100` the DP
  /// will not produce an octave-split median from a clean periodic envelope, so
  /// the snap's non-identity behavior is proven here at the unit level rather than
  /// end-to-end.)
  @Test func nearestOctaveEquivalentSnapsToReferenceOctave() {
    #expect(BeatGridAnalyzer.nearestOctaveEquivalent(of: 240, to: 120) == 120)  // double -> snap down
    #expect(BeatGridAnalyzer.nearestOctaveEquivalent(of: 60, to: 120) == 120)  // half -> snap up
    // In-octave drift preserved (not forced to the reference).
    #expect(abs(BeatGridAnalyzer.nearestOctaveEquivalent(of: 119.3, to: 120) - 119.3) < 1e-9)
    // Non-octave (3:4) passes through unchanged — resolving that is not the snap's job.
    #expect(BeatGridAnalyzer.nearestOctaveEquivalent(of: 75, to: 100) == 75)
    // Degenerate measured -> reference.
    #expect(BeatGridAnalyzer.nearestOctaveEquivalent(of: 0, to: 120) == 120)
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
}
