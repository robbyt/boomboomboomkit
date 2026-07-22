//
//  BNNSResampleClampTests.swift
//  BoomBoomBoomKitTests
//
//  GH-140 regression suite for the Step 3 resample control-vector clamp in
//  `BNNSTechnique.modelInputTensor(from:)` (resolves deferred 7-5-D1). The
//  pre-fix clamp lowered the last control entry one ULP below its own
//  computed value, NOT below F-1; whenever `vDSP_vramp`'s float32 rounding
//  overshot F-1 (reachable for both upsampling AND downsampling F),
//  `vDSP_vlint` read `A[F]` — cross-band contamination of the last output
//  column for mel bands 0-126, and a one-float heap over-read past the
//  `melMajor` allocation for band 127. The fixed clamp is the two-step
//  `min(controlVector[W-1], Float(F-1)).nextDown`, mirroring the Python
//  training pipeline.
//
//  vDSP_vramp rounding is hardware/library dependent, so overshooting F
//  values are RUNTIME-PROBED rather than hardcoded. Two predicates matter:
//
//  - OOB-exists (`last.nextDown >= Float(F-1)`): the read goes out of
//    bounds pre-fix, but a 1-ULP overshoot lands the clamped entry exactly
//    on F-1 with frac == 0 — value-invisible (`vDSP_vlint` still reads
//    `C[q+1]` unconditionally per Apple's contract, then erases it with
//    frac 0). Address Sanitizer CANNOT observe that read either: it
//    executes inside uninstrumented Accelerate code (verified empirically
//    during GH-140 — zero sanitizer reports on the pre-fix clamp). The
//    biting guard for this class is the debug `assert` directly after the
//    clamp in `modelInputTensor`; the always-on boundary smoke test below
//    guarantees `modelInputTensor` executes at an OOB-exists F whenever
//    this hardware has one, so the assert is exercised in every debug
//    test run on such machines. `make test-asan` remains as
//    defense-in-depth for future instrumented-code OOBs only.
//    Mutation-verification note: with the assert in place, a regressed
//    clamp SIGABRTs at the assert BEFORE any contamination #expect can
//    report — to re-verify the value net in isolation, strip the assert
//    along with the clamp (round-2 mutations 1b/2b did exactly that).
//  - STRICT overshoot (`last.nextDown > Float(F-1)`): frac > 0, so the
//    contamination is value-detectable. The contamination tests select via
//    this predicate — with a minimum-frac floor so the expected signal
//    clears the comparison tolerance — and SKIP (via `.enabled(if:)`)
//    on hardware where no qualifying F exists, rather than silently
//    passing degraded assertions.
//
//  Empirical anchors on the authoring machine (checked first as preferred
//  candidates, never assumed): upsampling [32, 511] has 201 OOB-exists /
//  113 strict hits (anchor F=445, overshoot ~1.22e-4); downsampling over
//  the API-constructible range [513, 65536] (the MLFeatureFrames 8.4M-float
//  cap bounds F at 65,536 for 128 bands) has 25,556 OOB-exists / 13,344
//  strict hits (first OOB at 584, first strict at 696); F=32 itself is
//  an OOB-exists (frac-0) case here.
//
//  Contamination detection design (see the GH-140 spec Design Notes): each
//  mel band gets a spike-first row whose spike SCALES WITH F (20x the ramp
//  top), so post-z-score the NEXT band's z[0] is a large positive outlier
//  above the victim band's ramp top at every F. A fixed spike does not
//  survive downsampling: at F > ~10,000 the ramp top overtakes a constant
//  100.0 spike and the band-local upper bound goes inert (found by
//  mutation testing in review round 1). Pre-fix, the victim band's last
//  column becomes `z[F-1] + frac * (zNextBand[0] - z[F-1])`, exceeding the
//  band-local bound z[F-1]; the fixed pipeline interpolates strictly
//  inside [z[F-2], z[F-1]].
//

import Accelerate
import BoomBoomBoomKit
import Testing

@_spi(FeatureParity) @testable import BoomBoomBoomKitML

@Suite("GH-140 BNNS resample control-vector clamp")
struct BNNSResampleClampTests {

  /// Mirrors `BNNSTechnique.targetWidth` (private; the tensor width is
  /// pinned by the frozen `[1, 1, 128, 512]` model-input contract).
  private static let W = 512
  private static let melBands = 128

  /// Minimum strict-overshoot fraction a probed F must clear before the
  /// contamination tests will use it: the pre-fix signal is
  /// `frac * (zSpike - zTop)` with `zSpike - zTop` conservatively >= 3
  /// under the F-scaled spike design, so 5e-5 guarantees a signal
  /// >= 1.5e-4 — 1.5x the 1e-4 comparison tolerance in the worst case
  /// (empirical signals run 18-29x). Below the floor a broken clamp
  /// could pass inside tolerance — skip instead of lying. Do NOT raise
  /// the floor to 1e-4 for more margin: the upsampling frac ceiling on
  /// Apple silicon is ~9.2e-5 (F=445), so a 1e-4 floor would skip the
  /// upsampling contamination test on the reference hardware.
  private static let minDetectableFrac: Float = 5e-5

  // MARK: - vDSP_vramp probing

  /// Runs the REAL `vDSP_vramp` exactly as `modelInputTensor` does and
  /// returns the last control entry — the value both overshoot predicates
  /// are evaluated against.
  private static func vrampLastEntry(frames F: Int) -> Float {
    var control = [Float](repeating: 0, count: W)
    var rampStart: Float = 0
    var rampStep = Float(F - 1) / Float(W - 1)
    vDSP_vramp(&rampStart, &rampStep, &control, 1, vDSP_Length(W))
    return control[W - 1]
  }

  /// STRICT overshoot: after the buggy clamp the last control entry still
  /// exceeds F-1, so `floor == F-1` and `frac > 0` — the only F values
  /// where the `A[F]` over-read is value-detectable.
  private static func strictOvershootFrac(frames F: Int) -> Float {
    vrampLastEntry(frames: F).nextDown - Float(F - 1)
  }

  /// Selects a strict-overshoot F in `range` whose frac clears
  /// `minDetectableFrac`: the `preferred` empirical anchor if it qualifies
  /// on THIS machine, else the in-range F maximizing the overshoot
  /// fraction. Returns nil when no qualifying F exists — the contamination
  /// tests then SKIP via their `.enabled(if:)` trait (visible in test
  /// output), never silently pass.
  private static func selectStrictOvershootF(in range: ClosedRange<Int>, preferred: Int) -> Int? {
    if range.contains(preferred), strictOvershootFrac(frames: preferred) >= minDetectableFrac {
      return preferred
    }
    var best: (f: Int, frac: Float)?
    for f in range {
      let frac = strictOvershootFrac(frames: f)
      if frac >= minDetectableFrac, frac > (best?.frac ?? 0) {
        best = (f, frac)
      }
    }
    return best?.f
  }

  /// Probed once per process; nil means the corresponding contamination
  /// test is skipped on this hardware (visible SKIP, never a silent
  /// pass). The downsampling scan covers the full constructible range —
  /// the probe is a few million float writes, milliseconds — so the
  /// real-track regime (a ~3-minute track at hop 441 lands near F=18k)
  /// is inside the scanned window.
  private static let upsamplingStrictF: Int? =
    selectStrictOvershootF(in: 32...511, preferred: 445)
  private static let downsamplingStrictF: Int? =
    selectStrictOvershootF(in: 513...65_536, preferred: 696)

  /// Weaker OOB-exists probe (`last.nextDown >= F-1`, no frac floor) for
  /// the always-on boundary smoke test: these F values over-read pre-fix
  /// even when the contamination signal is value-invisible (frac 0), so
  /// running `modelInputTensor` at one exercises the debug assert — the
  /// only net for that class — in every debug test run.
  private static func selectOOBExistsF(in range: ClosedRange<Int>, preferred: Int) -> Int? {
    if range.contains(preferred),
      vrampLastEntry(frames: preferred).nextDown >= Float(preferred - 1)
    {
      return preferred
    }
    return range.first { f in
      vrampLastEntry(frames: f).nextDown >= Float(f - 1)
    }
  }

  // MARK: - Input construction

  /// Builds the spike-first `.nchw` (mel-major passthrough) payload: every
  /// band is `[spike, 0.01, 0.02, ..., (F-1) * 0.01]` where
  /// `spike = F * 0.2` — 20x the ramp top at every F, so post-z-score the
  /// spike at index 0 is a large positive outlier above the band's ramp
  /// top REGARDLESS of F (a fixed spike sinks below the ramp top for
  /// downsampling F > ~10,000, muting the band-local bound). Cross-band
  /// contamination at the last output column reads the NEXT band's z[0]
  /// spike and lands far above the band-local final-segment bound.
  private static func spikeRampFeatures(frames F: Int) throws -> MLFeatureFrames {
    var data = [Float](repeating: 0, count: melBands * F)
    // Test-local scalar loops computing input/expected values are exempt
    // from the vDSP bulk-ops rule.
    for mel in 0..<melBands {
      data[mel * F] = Float(F) * 0.2
      for j in 1..<F {
        data[mel * F + j] = Float(j) * 0.01
      }
    }
    return try MLFeatureFrames(
      melBands: melBands, frames: F, tensorLayout: .nchw,
      logMelData: data,
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: "v1"
    )
  }

  // MARK: - Scalar reference pipeline

  /// Replicates the fixed `modelInputTensor` pipeline for `.nchw` input:
  /// identity passthrough (Step 1), per-band z-score via the SAME
  /// `vDSP_normalize` call (Step 2 — bit-exact by construction, including
  /// its population stddev), then the REAL `vDSP_vramp` control vector with
  /// the FIXED two-step clamp applied and a scalar
  /// `A[floor(c)] + frac * (A[floor(c)+1] - A[floor(c)])` interpolation
  /// (Step 3). Returns both the z-scored rows (for band-local range
  /// assertions) and the expected tensor. The `upper` index is clamped to
  /// the row so a hypothetical interior control entry >= F-1 produces a
  /// diagnosable #expect divergence rather than an index trap.
  private static func referencePipeline(
    data: [Float], frames F: Int
  ) -> (zScored: [Float], tensor: [Float]) {
    let M = melBands
    var zScored = data
    zScored.withUnsafeMutableBufferPointer { buf in
      guard let base = buf.baseAddress else { return }
      var mean: Float = 0
      var stddev: Float = 0
      for mel in 0..<M {
        let row = base + mel * F
        vDSP_normalize(row, 1, row, 1, &mean, &stddev, vDSP_Length(F))
        if stddev == 0 || !stddev.isFinite {
          vDSP_vclr(row, 1, vDSP_Length(F))
        }
      }
    }
    var control = [Float](repeating: 0, count: W)
    var rampStart: Float = 0
    var rampStep = Float(F - 1) / Float(W - 1)
    vDSP_vramp(&rampStart, &rampStep, &control, 1, vDSP_Length(W))
    control[W - 1] = min(control[W - 1], Float(F - 1)).nextDown
    var tensor = [Float](repeating: 0, count: M * W)
    for mel in 0..<M {
      for w in 0..<W {
        let c = control[w]
        let lower = Int(c)  // c >= 0 everywhere, so trunc == floor
        let frac = c - Float(lower)
        let a = zScored[mel * F + lower]
        let b = lower + 1 < F ? zScored[mel * F + lower + 1] : a
        tensor[mel * W + w] = a + frac * (b - a)
      }
    }
    return (zScored, tensor)
  }

  // MARK: - Shared assertion body

  /// The biting GH-140 assertion set at a given F:
  /// 1. a mid-tensor column matches the scalar reference (validates the
  ///    reference itself, away from the boundary);
  /// 2. every band's LAST output column matches the reference within 1e-4
  ///    (pre-fix at a qualifying strict-overshoot F this is off by >= 5e-4
  ///    per the minDetectableFrac floor);
  /// 3. every band's last column stays within its own final-segment range
  ///    (bounded above by z[F-1], the interpolation ceiling of the
  ///    [z[F-2], z[F-1]] segment the fixed clamp confines the read to —
  ///    pre-fix the next band's z[0] spike pushes it above that bound;
  ///    this is the only assertion independent of the reference pipeline,
  ///    guarding against a shared-error "simplification" applied to both).
  /// Band 127 has no next band pre-fix (heap garbage, non-assertable by
  /// value) — that class is guarded by the debug assert after the clamp
  /// in `modelInputTensor`, not by anything here.
  private static func assertBandLocalLastColumn(frames F: Int) throws {
    let features = try spikeRampFeatures(frames: F)
    let tensor = try #require(
      BNNSTechnique.modelInputTensor(from: features),
      "modelInputTensor returned nil for valid \(melBands)x\(F) input")
    #expect(tensor.count == melBands * W)

    let (zScored, reference) = referencePipeline(data: features.logMelData, frames: F)

    // All 128 bands are asserted: post-fix every band (127 included) is
    // deterministic and reference-checkable. Pre-fix, band 127's last
    // column is heap-dependent — a spurious PASS there is acceptable
    // because bands 0-126 and the debug assert carry the bite.
    for mel in 0..<melBands {
      // Reference sanity away from the boundary.
      let mid = W / 2
      #expect(
        abs(tensor[mel * W + mid] - reference[mel * W + mid]) <= 1e-4,
        "band \(mel) mid column diverges from scalar reference at F=\(F)")

      // The biting assertions on the last column.
      let last = tensor[mel * W + (W - 1)]
      let expected = reference[mel * W + (W - 1)]
      #expect(
        abs(last - expected) <= 1e-4,
        "band \(mel) LAST column diverges from the fixed-clamp reference at F=\(F) (got \(last), expected \(expected)) — GH-140 cross-band contamination"
      )
      let bandFinalSegmentTop = zScored[mel * F + (F - 1)]
      #expect(
        last <= bandFinalSegmentTop + 1e-5,
        "band \(mel) LAST column \(last) exceeds its own final-segment bound \(bandFinalSegmentTop) at F=\(F) — GH-140 cross-band contamination"
      )
    }
  }

  // MARK: - Tests

  @Test(
    "last column stays band-local at a strict-overshoot UPSAMPLING F",
    .enabled(
      if: BNNSResampleClampTests.upsamplingStrictF != nil,
      "no strict-overshoot F in the probed range [32, 511] clears the detectability floor on this hardware"
    ))
  func contaminationGuardUpsampling() throws {
    try Self.assertBandLocalLastColumn(frames: #require(Self.upsamplingStrictF))
  }

  @Test(
    "last column stays band-local at a strict-overshoot DOWNSAMPLING F",
    .enabled(
      if: BNNSResampleClampTests.downsamplingStrictF != nil,
      "no strict-overshoot F in the probed range [513, 65536] clears the detectability floor on this hardware"
    ))
  func contaminationGuardDownsampling() throws {
    // Downsampling reachability is the GH-140 correction to the 7-5-D1
    // record ("upsampling only" was wrong — first strict downsampling hit
    // at F=696 on the authoring machine, well inside real-track range).
    try Self.assertBandLocalLastColumn(frames: #require(Self.downsamplingStrictF))
  }

  @Test("min clamp engages at an OOB-exists boundary F (always-on)")
  func oobExistsBoundarySmoke() throws {
    // Always-on (no trait gate): guarantees modelInputTensor executes at
    // an OOB-exists F whenever this hardware has one, so a regressed
    // clamp trips the debug assert in every debug test run — the frac-0
    // class has no value signal for the contamination tests to catch
    // (round-2 mutations 2/2b: the assert alone kills the min-less
    // mutation). F=32, the short-clip guard minimum, is the preferred
    // anchor: on the authoring machine it is an OOB-exists, min-ACTIVE
    // case (vramp lands one ULP above 31, the min shifts the clamp
    // source from the computed entry to F-1). Runs F=32 regardless, so
    // the production minimum always gets pipeline coverage.
    var candidates: [Int] = [32]
    if let oob = Self.selectOOBExistsF(in: 32...511, preferred: 32), oob != 32 {
      candidates.append(oob)
    }
    for F in candidates {
      try Self.assertBandLocalLastColumn(frames: F)
    }
  }

  @Test("tensor is bit-identical across two invocations on identical input")
  func bitIdenticalDeterminism() throws {
    // Property pin, NOT a GH-140 regression net: pre-fix, back-to-back
    // calls read the SAME adjacent heap contents, so bit-identity held
    // even with the band-127 over-read (mutation-verified in review
    // round 1). The biting nets are the contamination tests above and the
    // debug assert after the clamp; this test pins the determinism
    // property itself so a future nondeterministic featurize path (of any
    // cause) cannot land silently.
    let F = Self.upsamplingStrictF ?? 64
    let features = try Self.spikeRampFeatures(frames: F)
    let first = try #require(BNNSTechnique.modelInputTensor(from: features))
    let second = try #require(BNNSTechnique.modelInputTensor(from: features))
    #expect(first.count == second.count)
    for i in 0..<first.count {
      #expect(
        first[i].bitPattern == second[i].bitPattern,
        "tensor element \(i) not bit-identical across invocations at F=\(F)")
    }
  }

  @Test("non-overshooting F: the min clamp is a bit-exact no-op")
  func nonOvershootFIsClampNoOp() throws {
    // AC: at any F where vDSP_vramp does NOT overshoot, output is
    // bit-identical before and after the fix. Proven structurally: when
    // `last <= F-1`, `min(last, Float(F-1))` returns `last` unchanged, so
    // the fixed clamp computes the exact pre-fix expression. F=64 is the
    // spot-check anchor; if THIS machine's vramp overshoots at 64, pick a
    // non-overshooting F dynamically. If NO non-overshooting F exists in
    // the full production range (F=32 included), the property is
    // untestable here and the #require fails loudly by design.
    var F = 64
    if Self.vrampLastEntry(frames: F).nextDown >= Float(F - 1) {
      let fallback = (32...511).first { f in
        Self.vrampLastEntry(frames: f).nextDown < Float(f - 1)
      }
      F = try #require(fallback, "no non-overshooting F in [32, 511] on this machine")
    }
    // F=512 is the exact-boundary identity resample: step is exactly 1.0,
    // the last control entry lands exactly ON F-1, and `min` passes it
    // through bit-unchanged (spec edge-case matrix row 4). It sits between
    // the two contamination probe ranges, so pin it explicitly.
    for candidate in [F, 512] {
      let last = Self.vrampLastEntry(frames: candidate)
      // The no-op proof, at the bit level: min(., F-1) must pass the
      // computed value through untouched wherever last <= F-1. If this
      // hardware overshoots at the candidate, the pin cannot run — say
      // so instead of silently passing on the pipeline comparison alone.
      if last <= Float(candidate - 1) {
        #expect(
          min(last, Float(candidate - 1)).bitPattern == last.bitPattern,
          "min clamp altered an in-bounds control entry at F=\(candidate)")
      } else {
        Issue.record(
          Comment(
            rawValue:
              "vDSP_vramp overshoots at F=\(candidate) on this hardware; the bit-identity no-op pin did not execute"
          ))
      }
      // And the full pipeline matches the scalar reference everywhere.
      let features = try Self.spikeRampFeatures(frames: candidate)
      let tensor = try #require(BNNSTechnique.modelInputTensor(from: features))
      let (_, reference) = Self.referencePipeline(data: features.logMelData, frames: candidate)
      for i in 0..<tensor.count {
        #expect(
          abs(tensor[i] - reference[i]) <= 1e-4,
          "tensor element \(i) diverges from scalar reference at F=\(candidate)")
      }
    }
  }
}
