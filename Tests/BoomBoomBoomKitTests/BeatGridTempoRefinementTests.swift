//
//  BeatGridTempoRefinementTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.10 tests for the continuous beat-grid tempo refinement: the
//  fractional-BPM fit from a coarse seed, the monotonic reject-guard (aperiodic /
//  flat-constant / too-short → seed, bit-identical), octave safety, the
//  refit × BeatGridTempoLock precedence matrix, and the default-OFF byte-identity
//  opt-out contract.
//
//  `@testable` reaches the internal `BeatGridAnalyzer` / `BPMAnalyzer` for the
//  deterministic refit tests; the lock matrix runs through the public combined
//  `analyze(decoded:)` path.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("BeatGridTempoRefinementTests")
struct BeatGridTempoRefinementTests {

  // MARK: - Helpers

  private static let onsetRate = 100.0
  private static let hop = 441
  private static let sr = 44100.0

  /// Onset envelope at 100 Hz with unit impulses placed at *fractional* frame
  /// positions `k·periodFrames`, each split linearly across the two adjacent
  /// integer frames — a sub-frame periodic comb the integer-grid 8.4 approach
  /// could not represent.
  private static func fractionalImpulseEnvelope(frames: Int, periodFrames: Double) -> [Float] {
    var env = [Float](repeating: 0, count: frames)
    var pos = 0.0
    while Int(pos) + 1 < frames {
      let i = Int(pos)
      let frac = Float(pos - Double(i))
      env[i] += 1 - frac
      env[i + 1] += frac
      pos += periodFrames
    }
    return env
  }

  /// Integer-period unit-impulse comb.
  private static func impulseEnvelope(frames: Int, periodFrames: Int) -> [Float] {
    var env = [Float](repeating: 0, count: frames)
    for f in stride(from: 0, to: frames, by: periodFrames) { env[f] = 1 }
    return env
  }

  private static func grid(
    env: [Float], seedBPM: Double, refine: Bool,
    sink: ((BeatGridTempoRefinementEvidence) -> Void)? = nil
  ) -> BeatGrid? {
    BeatGridAnalyzer.estimateBeatGrid(
      onsetEnvelope: env, onsetRate: onsetRate, hopSize: hop, sampleRate: sr,
      acf: env, tempoBPM: seedBPM, windowStartSample: 0,
      refineBeatGridTempo: refine, refinementSink: sink ?? { _ in })
  }

  /// A deterministic 30 s fractional-BPM (127.3) click — the shared input for the
  /// public `estimateBPM` byte-identity runs below (built once per call; the
  /// generator is deterministic, so independent calls produce identical samples).
  private static func clickDecoded() -> FeatureSubstrate.DecodedAudio {
    FeatureSubstrate.DecodedAudio.synthetic(
      generateClickTrack(bpm: 127.3, sampleRate: 44100, durationSeconds: 30),
      sampleRate: 44100)
  }

  /// A minimal constant-tempo `BeatGrid` (no beats needed — `applyTempoLock` reads
  /// and rewrites only `estimatedTempo`) for directly exercising the lock policy.
  private static func constantGrid(estimatedTempo: Double) -> BeatGrid {
    BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: estimatedTempo, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
  }

  // MARK: - AC8: fractional refine from a coarse seed

  /// A constant-tempo click at a fractional BPM (127.3), fitted from a coarse seed
  /// (127.0, 0.3 BPM off — the deliberately-coarse seed AC #8 requires so "strictly
  /// closer than seed" is satisfiable): the refined tempo lands within ±0.05 BPM of
  /// truth AND strictly closer than the seed.
  @Test func refinesFractionalBPMWithinTolerance() throws {
    let trueBPM = 127.3
    let truePeriod = Self.onsetRate * 60.0 / trueBPM
    let env = Self.fractionalImpulseEnvelope(frames: 6000, periodFrames: truePeriod)
    let seedBPM = 127.0

    var evidence: BeatGridTempoRefinementEvidence?
    let g = try #require(Self.grid(env: env, seedBPM: seedBPM, refine: true) { evidence = $0 })

    let refined = g.estimatedTempo
    #expect(abs(refined - trueBPM) <= 0.05, "refined \(refined) not within 0.05 BPM of \(trueBPM)")
    #expect(
      abs(refined - trueBPM) < abs(seedBPM - trueBPM),
      "refined \(refined) must be strictly closer to \(trueBPM) than the seed \(seedBPM)")

    let e = try #require(evidence)
    #expect(e.accepted)
    #expect(e.supportRefined > e.supportSeed)
    #expect(e.coarseTempo == seedBPM)
    #expect(e.refinedTempo == refined)
  }

  /// The fitted value comes from the continuous onset-comb objective, NOT the
  /// integer-frame inter-beat-interval median (AC #2 — the reverted 8.4 trap). The
  /// integer-median of a 47.13-frame comb is exactly 47 frames → 127.66 BPM; the
  /// refined value must NOT be that quantized integer-median tempo.
  @Test func fittedValueIsNotIntegerIntervalMedian() throws {
    let trueBPM = 127.3
    let truePeriod = Self.onsetRate * 60.0 / trueBPM
    let env = Self.fractionalImpulseEnvelope(frames: 6000, periodFrames: truePeriod)
    let g = try #require(Self.grid(env: env, seedBPM: 127.0, refine: true))
    let integerMedianBPM = Self.onsetRate * 60.0 / (truePeriod.rounded())  // 100*60/47 = 127.66
    #expect(
      abs(g.estimatedTempo - integerMedianBPM) > 0.1,
      "refined \(g.estimatedTempo) collapsed onto the integer-interval-median tempo \(integerMedianBPM)"
    )
  }

  // MARK: - AC3: monotonic reject-guard (seed returned, bit-identical)

  /// Flat-constant envelope: no comb concentration at any period → the periodicity
  /// abstain fires and the seed is returned bit-for-bit.
  @Test func flatConstantEnvelopeReturnsSeedBitIdentical() throws {
    let seedBPM = 120.0
    let env = [Float](repeating: 1, count: 2000)  // period 50 frames, ~40 beats
    let g = try #require(Self.grid(env: env, seedBPM: seedBPM, refine: true))
    #expect(g.estimatedTempo.bitPattern == seedBPM.bitPattern)
  }

  /// Aperiodic (narrow-band noise) envelope: contrast ≈ 1 → abstain → seed
  /// bit-identical. Deterministic generator so the result is reproducible.
  @Test func aperiodicEnvelopeReturnsSeedBitIdentical() throws {
    let seedBPM = 120.0
    var state: UInt64 = 0x1234_5678_9abc_def0
    func nextUnit() -> Float {
      state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      return Float(state >> 40) / Float(1 << 24)  // [0, 1)
    }
    // Narrow band [0.4, 0.6]: no phase concentrates onset energy.
    let env = (0..<4000).map { _ in 0.4 + 0.2 * nextUnit() }
    let g = try #require(Self.grid(env: env, seedBPM: seedBPM, refine: true))
    #expect(g.estimatedTempo.bitPattern == seedBPM.bitPattern)
  }

  /// Too-short span (fewer than the minimum beat count): the min-span abstain
  /// fires and the seed is returned bit-identical.
  @Test func tooShortSpanAbstainsToSeedBitIdentical() throws {
    let seedBPM = 120.0
    // period 50 frames; ~5 beats over 300 frames → below the 8-beat floor.
    let env = Self.impulseEnvelope(frames: 300, periodFrames: 50)
    let g = try #require(Self.grid(env: env, seedBPM: seedBPM, refine: true))
    #expect(g.estimatedTempo.bitPattern == seedBPM.bitPattern)
  }

  // MARK: - AC4: octave safety (the window bound)

  /// Seeded at HALF the true tempo (true 240 BPM / period 25; seed 120 / period
  /// 50): the bounded window cannot reach the true octave, so the refined tempo
  /// stays near the seed octave (within the few-percent window) and never snaps to
  /// 2×. Octave selection is the BPM stage's job, not the refit's.
  @Test func halfTimeSeedDoesNotSnapToOctave() throws {
    let seedBPM = 120.0
    let env = Self.impulseEnvelope(frames: 6000, periodFrames: 25)  // true 240 BPM
    let g = try #require(Self.grid(env: env, seedBPM: seedBPM, refine: true))
    // Stays within ~5% of the seed octave — does NOT jump toward 240.
    #expect(
      abs(g.estimatedTempo - seedBPM) / seedBPM <= 0.05,
      "refined \(g.estimatedTempo) escaped the seed octave (seed \(seedBPM))")
    #expect(abs(g.estimatedTempo - 2 * seedBPM) / (2 * seedBPM) > 0.4)
  }

  // MARK: - AC5: default-OFF byte identity

  /// With `refineBeatGridTempo` OFF, the grid reports the coarse seed VERBATIM
  /// (byte-identical to Story 8.4/8.5) and the full `BeatGrid` graph is identical
  /// to the no-flag default path. A paired ON run proves the flag is not inert.
  @Test func defaultOffIsByteIdenticalAndOnIsNotInert() throws {
    let trueBPM = 127.3
    let truePeriod = Self.onsetRate * 60.0 / trueBPM
    let env = Self.fractionalImpulseEnvelope(frames: 6000, periodFrames: truePeriod)
    let seedBPM = 127.0

    let off = try #require(Self.grid(env: env, seedBPM: seedBPM, refine: false))
    // OFF reports the coarse seed verbatim.
    #expect(off.estimatedTempo.bitPattern == seedBPM.bitPattern)

    // Full-graph byte identity: OFF == the no-flag default path (Equatable over
    // the whole BeatGrid graph — beats, gridOrigin, confidence, coverage).
    let defaultPath = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: Self.onsetRate, hopSize: Self.hop, sampleRate: Self.sr,
        acf: env, tempoBPM: seedBPM, windowStartSample: 0))
    #expect(off == defaultPath)

    // ON moves the tempo (the flag is not inert).
    let on = try #require(Self.grid(env: env, seedBPM: seedBPM, refine: true))
    #expect(on.estimatedTempo.bitPattern != seedBPM.bitPattern)
  }

  /// AC #5 (BPM-field half): refinement is isolated to the grid's `estimatedTempo`
  /// and NEVER perturbs `bpm` / `confidence` / `candidates`. Three runs of the public
  /// `estimateBPM` over the SAME deterministic click — a pristine no-flag baseline, an
  /// explicit refine-OFF (grid on), and a refine-ON (grid on) — must report
  /// bit-identical `bpm` / `confidence` / `candidates`. This proves explicit-OFF
  /// matches the no-flag pipeline (the byte-identity promise for these fields) AND that
  /// the ON path never feeds BPM winner selection (AC #10, made observable).
  ///
  /// Non-inertness (ON actually moves the tempo) is locked deterministically by
  /// `defaultOffIsByteIdenticalAndOnIsNotInert` above (60 s env, coarse seed); here the
  /// `.optimal` seed through the `.analysisWindow` fan-out is often already sub-BPM, so
  /// the strict reject-guard legitimately abstains. We assert only that the refit PATH
  /// executed on the ON run (it produced a grid and populated the trace evidence).
  @Test func refinementDoesNotPerturbBPMFields() throws {
    let decoded = Self.clickDecoded()

    // Pristine no-flag baseline: untouched Options (computeBeatGrid + refine both off).
    let baseline = try #require(
      BPMAnalyzer.estimateBPM(decoded: decoded, options: BPMAnalyzer.Options()))

    var offOpts = BPMAnalyzer.Options()
    offOpts.computeBeatGrid = true
    let off = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: offOpts))

    var onOpts = BPMAnalyzer.Options()
    onOpts.computeBeatGrid = true
    onOpts.refineBeatGridTempo = true
    onOpts.enableTrace = true
    let on = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: onOpts))

    // bpm / confidence / candidates bit-identical across all three runs.
    for result in [off, on] {
      #expect(result.bpm.bitPattern == baseline.bpm.bitPattern)
      #expect(result.confidence.bitPattern == baseline.confidence.bitPattern)
      #expect(result.candidates.count == baseline.candidates.count)
      for (a, b) in zip(result.candidates, baseline.candidates) {
        #expect(a.bpm.bitPattern == b.bpm.bitPattern)
        #expect(a.score.bitPattern == b.score.bitPattern)
      }
    }

    // Meaningfulness: the refit path executed on the ON run (grid produced + evidence
    // populated) — so the isolation above held WHILE refinement ran, not vacuously.
    #expect(on.beatGrid != nil)
    let evidence = try #require(on.trace?.beatGridTempoRefinement)
    #expect(evidence.coarseTempo > 0)
  }

  // MARK: - AC6: refit × BeatGridTempoLock precedence matrix

  /// Runs the combined `analyze(decoded:)` path over a 30 s fractional-BPM click
  /// with refinement ON for the given lock.
  private static func analyzeRefined(lock: BeatGridTempoLock) throws -> CombinedAnalysisResult {
    let samples = generateClickTrack(bpm: 127.3, sampleRate: 44100, durationSeconds: 30)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 44100)
    var opts = AudioAnalysisService.Options()
    opts.refineBeatGridTempo = true
    opts.beatGridTempoLock = lock
    return try #require(try AudioAnalysisService.analyze(decoded: decoded, options: opts))
  }

  @Test func lockMatrixPrecedence() throws {
    let unlocked = try Self.analyzeRefined(lock: .off)
    let refinedTempo = try #require(unlocked.beatGrid).estimatedTempo
    #expect(refinedTempo > 0)

    // .bpmStage OVERRIDES the refined tempo with the (coarse) stage BPM,
    // octave-normalized — the sub-0.1 precision is discarded. Asserted EXACTLY (not
    // "within 2%"): a within-2% assertion passes even when the lock fails to override
    // and the refined tempo merely sits near the stage tempo — the weak-test gap that
    // hid the `.bpmStage` no-op bug (8-10-D5). Exact equality distinguishes a real
    // override.
    let bpmStage = try Self.analyzeRefined(lock: .bpmStage)
    let bpmStageGrid = try #require(bpmStage.beatGrid)
    let stageBPM = bpmStage.bpm.bpm
    #expect(
      bpmStageGrid.estimatedTempo == stageBPM
        || bpmStageGrid.estimatedTempo == 2 * stageBPM
        || bpmStageGrid.estimatedTempo == 0.5 * stageBPM,
      "bpmStage grid tempo \(bpmStageGrid.estimatedTempo) is not exactly the stage tempo \(stageBPM) (or an octave of it)"
    )

    // .bpm(NaN) is a documented no-op → the refined tempo STANDS (bit-identical to
    // the unlocked refined grid on the same deterministic input).
    let nanLock = try Self.analyzeRefined(lock: .bpm(.nan))
    #expect(try #require(nanLock.beatGrid).estimatedTempo.bitPattern == refinedTempo.bitPattern)

    // .bpm(absurd 1.0) disagrees by more than an octave → no-op → refined stands.
    let absurd = try Self.analyzeRefined(lock: .bpm(1.0))
    #expect(try #require(absurd.beatGrid).estimatedTempo.bitPattern == refinedTempo.bitPattern)

    // .bpm(valid = the refined tempo itself) locks to it exactly.
    let pinned = try Self.analyzeRefined(lock: .bpm(refinedTempo))
    #expect(try #require(pinned.beatGrid).estimatedTempo == refinedTempo)
  }

  /// Standalone `analyzeBeatGrid` ignores `beatGridTempoLock` (there is no BPM
  /// stage to lock to) — the lock leaves the refined grid unchanged.
  @Test func standaloneAnalyzeBeatGridIgnoresLock() throws {
    let samples = generateClickTrack(bpm: 127.3, sampleRate: 44100, durationSeconds: 30)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 44100)
    var noLock = AudioAnalysisService.Options()
    noLock.refineBeatGridTempo = true
    var withLock = noLock
    withLock.beatGridTempoLock = .bpm(60.0)  // would be a huge change IF honored
    let a = try #require(
      try AudioAnalysisService.analyzeBeatGrid(decoded: decoded, options: noLock))
    let b = try #require(
      try AudioAnalysisService.analyzeBeatGrid(decoded: decoded, options: withLock))
    #expect(a.estimatedTempo.bitPattern == b.estimatedTempo.bitPattern)
  }

  // MARK: - AC7: diagnostic evidence on the trace

  /// The refinement evidence surfaces on `BPMDiagnosticTrace` only when tracing is
  /// on AND the step-11 fan-out refined; the `accepted` flag distinguishes a real
  /// refit from a held seed.
  @Test func traceCarriesRefinementEvidence() throws {
    let samples = generateClickTrack(bpm: 127.3, sampleRate: 44100, durationSeconds: 30)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 44100)
    var opts = BPMAnalyzer.Options()
    opts.enableTrace = true
    opts.computeBeatGrid = true
    opts.refineBeatGridTempo = true
    let result = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: opts))
    let evidence = try #require(result.trace?.beatGridTempoRefinement)
    #expect(evidence.coarseTempo > 0)
    #expect(evidence.refinedTempo > 0)
    if evidence.accepted {
      #expect(evidence.supportRefined > evidence.supportSeed)
    } else {
      #expect(evidence.refinedTempo.bitPattern == evidence.coarseTempo.bitPattern)
    }

    // Off → no evidence.
    var offOpts = opts
    offOpts.refineBeatGridTempo = false
    let offResult = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: offOpts))
    #expect(offResult.trace?.beatGridTempoRefinement == nil)
  }

  // MARK: - Ticket #71: trace evidence on .window / .fullTrack coverage

  /// Drives the combined `analyze(decoded:)` path over a long deterministic click
  /// at the given coverage with refinement on, and returns the result.
  private static func analyzeCovered(
    coverage: BeatGridCoverage, refine: Bool = true, detectDownbeats: Bool = false,
    downbeatStrategy: DownbeatStrategy = .metricalAccent, enableTrace: Bool = true,
    durationSeconds: Double = 90
  ) throws -> CombinedAnalysisResult {
    let samples = generateClickTrack(
      bpm: 127.3, sampleRate: 44100, durationSeconds: durationSeconds)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 44100)
    var opts = AudioAnalysisService.Options()
    opts.enableTrace = enableTrace
    opts.refineBeatGridTempo = refine
    opts.detectDownbeats = detectDownbeats
    opts.downbeatStrategy = downbeatStrategy
    opts.beatGridCoverage = coverage
    return try #require(try AudioAnalysisService.analyze(decoded: decoded, options: opts))
  }

  /// On `.fullTrack` coverage, the refinement evidence reaches
  /// `CombinedAnalysisResult.bpm.trace` — the gap ticket #71 fixes (it was `nil`
  /// before, even though the refit ran on the coverage-span grid).
  @Test func fullTrackCoverageCarriesRefinementEvidence() throws {
    let result = try Self.analyzeCovered(coverage: .fullTrack)
    #expect(result.beatGrid != nil)
    let evidence = try #require(result.bpm.trace?.beatGridTempoRefinement)
    #expect(evidence.coarseTempo > 0)
    #expect(evidence.refinedTempo > 0)
    // Mirror `traceCarriesRefinementEvidence`'s accepted-branch invariant.
    if evidence.accepted {
      #expect(evidence.supportRefined > evidence.supportSeed)
    } else {
      #expect(evidence.refinedTempo.bitPattern == evidence.coarseTempo.bitPattern)
    }
  }

  /// The seam covers `.window(seconds:)` too, not only `.fullTrack`.
  @Test func windowCoverageCarriesRefinementEvidence() throws {
    let result = try Self.analyzeCovered(coverage: .window(seconds: 60))
    #expect(result.beatGrid != nil)
    let evidence = try #require(result.bpm.trace?.beatGridTempoRefinement)
    #expect(evidence.coarseTempo > 0)
    #expect(evidence.refinedTempo > 0)
  }

  /// The downbeat sibling: with `detectDownbeats` on (default `.metricalAccent`
  /// strategy), `.fullTrack` coverage surfaces the downbeat-strategy evidence.
  @Test func fullTrackCoverageCarriesDownbeatEvidence() throws {
    let result = try Self.analyzeCovered(coverage: .fullTrack, detectDownbeats: true)
    #expect(result.beatGrid != nil)
    let evidence = try #require(result.bpm.trace?.downbeatStrategy)
    #expect(evidence.strategy == .metricalAccent)
    #expect(evidence.confidence >= 0)
  }

  /// `.structuralDrop` strategy also populates the evidence on `.fullTrack` (the
  /// estimator runs; `strategy` is recorded regardless of detect/abstain outcome).
  @Test func fullTrackCoverageCarriesStructuralDropDownbeatEvidence() throws {
    let result = try Self.analyzeCovered(
      coverage: .fullTrack, detectDownbeats: true, downbeatStrategy: .structuralDrop)
    #expect(result.beatGrid != nil)
    let evidence = try #require(result.bpm.trace?.downbeatStrategy)
    #expect(evidence.strategy == .structuralDrop)
  }

  /// Refit OFF on `.fullTrack`: the field is gated on the flag, not coverage — it
  /// stays `nil`. Downbeats are also off, so `downbeatStrategy` stays `nil` too.
  @Test func refinementOffOnFullTrackLeavesEvidenceNil() throws {
    let result = try Self.analyzeCovered(coverage: .fullTrack, refine: false)
    #expect(result.beatGrid != nil)
    #expect(result.bpm.trace?.beatGridTempoRefinement == nil)
    #expect(result.bpm.trace?.downbeatStrategy == nil)
  }

  /// `enableTrace == false` on `.fullTrack` with refinement on: no trace is returned
  /// at all (and the stitching path builds none).
  @Test func tracingOffOnFullTrackReturnsNoTrace() throws {
    let result = try Self.analyzeCovered(coverage: .fullTrack, enableTrace: false)
    #expect(result.beatGrid != nil)
    #expect(result.bpm.trace == nil)
  }

  // MARK: - .bpmStage lock authority (post-merge Codex bot P2)

  /// `.bpmStage` is the pipeline's authoritative tempo, so it must override even a
  /// within-octave (>2%) disagreement — the exact case an accepted refit (up to the
  /// 4% window) or a single- vs multi-window split introduces. Previously the lock
  /// routed through the gated `octaveNormalizedLockTempo`, classified the divergence
  /// as `.disagree`, and silently no-oped, leaving the refined grid standing.
  @Test func stageLockTempoIsAuthoritativeWithinOctave() {
    typealias Svc = AudioAnalysisService
    // .agree → target.
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 122) == 120)
    // Within-octave .disagree (>2%) → target (the fix; was a silent no-op).
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 124) == 120)
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 235) == 120)  // ratio 1.96, within octave
    // Octave-equivalent → octave-shifted target (factor maps to ×2 / ×0.5, never ×−2).
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 240) == 240)
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 60) == 60)
    // True >octave divergence → nil (grid stays unlocked) — the >octave guard holds.
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 480) == nil)
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 245) == nil)  // ratio 2.04, >octave
    // Non-finite / non-positive target → nil.
    #expect(Svc.stageLockTempo(target: .nan, gridTempo: 120) == nil)
    #expect(Svc.stageLockTempo(target: 0, gridTempo: 120) == nil)
    #expect(Svc.stageLockTempo(target: -120, gridTempo: 120) == nil)
    // Non-finite / non-positive grid (the "no estimate" sentinel) → the stage tempo
    // wins (no octave to compare against).
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 0) == 120)
    #expect(Svc.stageLockTempo(target: 120, gridTempo: .nan) == 120)
  }

  /// Integration through `applyTempoLock`: a grid whose tempo diverged >2% from the
  /// stage tempo (124 vs 120) is restored to the stage tempo by `.bpmStage`, while
  /// the same divergence leaves arbitrary `.bpm(120)` caller input gated (no-op).
  /// This is the regression the weak `lockMatrixPrecedence` `.bpmStage` cell missed.
  @Test func applyTempoLockBpmStageOverridesDivergentGrid() throws {
    let grid = Self.constantGrid(estimatedTempo: 124)

    // .bpmStage authoritatively restores the stage tempo (was the no-op bug).
    let staged = try #require(
      AudioAnalysisService.applyTempoLock(grid, lock: .bpmStage, bpmStageTempo: 120))
    #expect(staged.estimatedTempo == 120)

    // Contrast: .bpm(120) — arbitrary caller input — stays gated and no-ops on the
    // same within-octave >2% disagreement (codifies current `.bpm` behavior, NOT an
    // endorsement of it; see deferred 8-10-D6).
    let bpmLock = try #require(
      AudioAnalysisService.applyTempoLock(grid, lock: .bpm(120), bpmStageTempo: 120))
    #expect(bpmLock.estimatedTempo == 124)

    // .off leaves the grid untouched.
    let off = try #require(
      AudioAnalysisService.applyTempoLock(grid, lock: .off, bpmStageTempo: 120))
    #expect(off.estimatedTempo == 124)
  }

  /// Characterization test (issue #66): the authoritative `stageLockTempo` and the
  /// gated `octaveNormalizedLockTempo` (reached through `applyTempoLock(_:lock: .bpm,
  /// ...)`) share the `.agree` / `.octaveEquivalent` octave arithmetic — `stageLockTempo`
  /// now reuses `octaveNormalizedLockTempo`, the single copy of that arithmetic. This pins
  /// that shared-arm equivalence so a
  /// future drift between the two octave-shift code paths fails loudly. The two
  /// resolvers must still DIFFER only on within-octave `.disagree`: the authoritative
  /// path restores the stage tempo, the gated path no-ops.
  ///
  /// Mutation-verification (recorded per the issue #66 test plan): before the
  /// shared-helper refactor, temporarily breaking ONE resolver's `.octaveEquivalent`
  /// arm (e.g. flipping `octaveNormalizedLockTempo`'s `factor == 2` branch) makes the
  /// `.octaveEquivalent` rows below diverge between the two paths and this test goes
  /// red; the shared-helper refactor makes it green again.
  @Test func stageAndGatedResolversShareOctaveArms() throws {
    typealias Svc = AudioAnalysisService

    /// Drive the gated `octaveNormalizedLockTempo` through its only public seam.
    func gated(target: Double, gridTempo: Double) throws -> Double {
      try #require(
        AudioAnalysisService.applyTempoLock(
          Self.constantGrid(estimatedTempo: gridTempo), lock: .bpm(target), bpmStageTempo: 0)
      ).estimatedTempo
    }

    // .agree → both paths return the target.
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 122) == 120)
    #expect(try gated(target: 120, gridTempo: 122) == 120)

    // .octaveEquivalent ×2 → both paths octave-shift up.
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 240) == 240)
    #expect(try gated(target: 120, gridTempo: 240) == 240)

    // .octaveEquivalent ×½ → both paths octave-shift down.
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 60) == 60)
    #expect(try gated(target: 120, gridTempo: 60) == 60)

    // Differ ONLY on within-octave .disagree (124 vs 120, >2%): the authoritative
    // resolver restores the stage tempo; the gated resolver no-ops. This asymmetry
    // must survive the de-duplication (issue #66 OUT-OF-SCOPE: the policy difference
    // itself, deferred 8-10-D6).
    #expect(Svc.stageLockTempo(target: 120, gridTempo: 124) == 120)
    #expect(try gated(target: 120, gridTempo: 124) == 124)
  }
}
