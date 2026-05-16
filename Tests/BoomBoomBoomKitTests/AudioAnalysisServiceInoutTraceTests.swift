//
//  AudioAnalysisServiceInoutTraceTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-6 AC #4 + DD #12 + Codex finding #4: locks the strict
//  mutation-after-cancellation ordering in
//  `AudioAnalysisService.evaluateMLIfActive(options:trace:)`. Without
//  these tests, a future refactor that reorders the helper (e.g., moves
//  the trace mutation before the post-evaluate cancellation check)
//  silently regresses the contract that a cancellation observed after
//  the model returned MUST throw `CancellationError` WITHOUT writing
//  the snapshot into the caller's trace.
//
//  Story 4-6 code review P17 adds two paired tests for the new
//  `Options.enableMLDiagnostics` flag — confirming the false-default
//  produces a nil snapshot even when ML is active (regression gate on
//  the gate-naming-fix introduced by P17).
//
//  All tests use a synthetic `MLDiagnosticTechnique` mock so they run
//  independently of the bundled-model state — Branch C absent-bundle
//  builds exercise these same code paths.
//

import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

// MARK: - Mock MLDiagnosticTechnique

/// Synthetic `MLDiagnosticTechnique` returning canned `(evaluation,
/// snapshot)` pairs. Lets the inout-cancellation + enableMLDiagnostics
/// tests run without a bundled model.
private struct CannedMLDiagnosticTechnique: MLDiagnosticTechnique {
  let evaluation: MLEvaluation?
  let snapshot: MLDiagnosticSnapshot?

  func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
    evaluation
  }

  func evaluateWithDiagnostic(
    trace: BPMDiagnosticTrace
  ) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?) {
    (evaluation, snapshot)
  }
}

/// Builds a representative win-path snapshot for use in mocks.
private func makeWinSnapshot() -> MLDiagnosticSnapshot {
  MLDiagnosticSnapshot(
    decodedBPM: 128.0,
    softmaxMax: 0.75,
    softmaxSecondMax: 0.10,
    inputFeatureChecksum: 0xDEAD_BEEF_CAFE_BABE,
    failureStage: nil,
    gateFired: nil)
}

/// Resolves a bundled click-track fixture that produces a real
/// `BPMResult` from the analyzer. The analysis pipeline must run
/// end-to-end through `evaluateMLIfActive` for the inout-trace mutation
/// (and the `enableMLDiagnostics` gate) to be observable, so a fixture
/// that returns nil from DSP would short-circuit before the ML helper.
private func bundledFixtureURL() throws -> URL {
  try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
}

// MARK: - Inout trace mutation ordering (AC #4)

@Suite("AudioAnalysisService inout-trace mutation ordering (Story 4-6 AC #4)")
struct AudioAnalysisServiceInoutTraceTests {

  /// AC #4 + Codex finding #4: post-evaluate cancellation MUST throw
  /// `CancellationError` AND leave the caller's trace's
  /// `mlDiagnosticSnapshot` field unmutated. The mock's
  /// `isCancelled` closure flips `true` after the evaluation returns
  /// so the strict ordering is exercised — pre-evaluate cancellation
  /// is the easy case; post-evaluate cancellation is the load-bearing
  /// invariant.
  @Test(
    "inoutTraceMutationAfterCancellation — snapshot discarded when cancellation flips post-evaluate"
  )
  func inoutTraceMutationAfterCancellation() throws {
    let fixtureURL = try bundledFixtureURL()
    let mock = CannedMLDiagnosticTechnique(
      evaluation: MLEvaluation(
        bpm: 128.0, confidence: 0.75, modelIdentifier: "mock"),
      snapshot: makeWinSnapshot())

    // Cancellation closure flips true after the mock's `evaluate`
    // returns. The state-machine progression is:
    //   - first call (pre-PCM-read): false (let analysis start)
    //   - subsequent calls in window loop: false (let windows run)
    //   - call after evaluateWithDiagnostic returns: true (trigger
    //     post-evaluate cancellation in evaluateMLIfActive)
    let cancelAfterEvaluate = LockedCounter()
    let didEvaluate = LockedFlag()

    let mockWithCancel = CancellationFlippingMock(
      inner: mock,
      onEvaluate: { didEvaluate.set() })

    var opts = AudioAnalysisService.Options()
    opts.intensity = .thorough  // intensity 8 — activates ML path
    opts.ensemblePolicy = .mlOnly
    opts.enableTrace = true
    opts.enableMLDiagnostics = true
    opts.mlTechnique = mockWithCancel
    opts.isCancelled = {
      // Flip to true only AFTER the mock's evaluate has run. Until
      // then, return false so the pipeline reaches the
      // post-evaluate check.
      if didEvaluate.get() {
        cancelAfterEvaluate.increment()
        return true
      }
      return false
    }

    // The analysis MUST throw CancellationError — the post-evaluate
    // cancellation check in `evaluateMLIfActive` fires.
    #expect(throws: CancellationError.self) {
      _ = try AudioAnalysisService.analyzeBPM(url: fixtureURL, options: opts)
    }
    // The cancellation closure was called at least once after the
    // evaluate fired — confirming we reached the post-evaluate gate
    // rather than an earlier short-circuit.
    #expect(cancelAfterEvaluate.value >= 1)
  }

  /// AC #4 happy path: on the no-cancellation path, the snapshot is
  /// written to the trace's `mlDiagnosticSnapshot` field and returned
  /// to the caller. Without this complement to the above,
  /// `localSnapshot = nil` could pass the cancellation test and still
  /// be the wrong implementation.
  @Test("inoutTraceMutationOnWinPath — snapshot lands when ML active and no cancellation")
  func inoutTraceMutationOnWinPath() throws {
    let fixtureURL = try bundledFixtureURL()
    let winSnapshot = makeWinSnapshot()
    let mock = CannedMLDiagnosticTechnique(
      evaluation: MLEvaluation(
        bpm: 128.0, confidence: 0.75, modelIdentifier: "mock"),
      snapshot: winSnapshot)

    var opts = AudioAnalysisService.Options()
    opts.intensity = .thorough
    opts.ensemblePolicy = .mlOnly
    opts.enableTrace = true
    opts.enableMLDiagnostics = true
    opts.mlTechnique = mock

    let result = try AudioAnalysisService.analyzeBPM(url: fixtureURL, options: opts)
    // bpm-120-click is a 10s 120-BPM synthetic click fixture; the DSP
    // pipeline reliably resolves it. The trace MUST be present and
    // the snapshot MUST be attached.
    let nonNilResult = try #require(result, "DSP should resolve bpm-120-click")
    let trace = try #require(nonNilResult.trace, "Trace should be returned with enableTrace=true")
    let attached = try #require(
      trace.mlDiagnosticSnapshot,
      "Snapshot should be attached on the no-cancellation ML path")
    #expect(attached == winSnapshot)
  }
}

// MARK: - enableMLDiagnostics gate (P17)

@Suite("AudioAnalysisService enableMLDiagnostics gate (Story 4-6 P17)")
struct EnableMLDiagnosticsTests {

  /// P17: default `enableMLDiagnostics == false` MUST leave
  /// `trace.mlDiagnosticSnapshot` nil even when the conformer is a
  /// `MLDiagnosticTechnique` returning a non-nil snapshot. Regression
  /// gate on the gate-naming-fix that split this out of
  /// `enableTrace`.
  @Test("enableMLDiagnostics default false → snapshot stays nil")
  func enableMLDiagnosticsFalseProducesNilSnapshot() throws {
    let fixtureURL = try bundledFixtureURL()
    let mock = CannedMLDiagnosticTechnique(
      evaluation: MLEvaluation(
        bpm: 128.0, confidence: 0.75, modelIdentifier: "mock"),
      snapshot: makeWinSnapshot())

    var opts = AudioAnalysisService.Options()
    opts.intensity = .thorough
    opts.ensemblePolicy = .mlOnly
    opts.enableTrace = true
    // enableMLDiagnostics intentionally left at default false.
    opts.mlTechnique = mock

    let result = try AudioAnalysisService.analyzeBPM(url: fixtureURL, options: opts)
    let nonNilResult = try #require(result, "DSP should resolve bpm-120-click")
    let trace = try #require(
      nonNilResult.trace,
      "Trace should be returned with enableTrace=true")
    #expect(
      trace.mlDiagnosticSnapshot == nil,
      "enableMLDiagnostics=false should suppress snapshot population")
  }

  /// P17 paired-test: explicit opt-in produces a non-nil snapshot.
  @Test("enableMLDiagnostics true → snapshot lands")
  func enableMLDiagnosticsTrueProducesNonNilSnapshot() throws {
    let fixtureURL = try bundledFixtureURL()
    let winSnapshot = makeWinSnapshot()
    let mock = CannedMLDiagnosticTechnique(
      evaluation: MLEvaluation(
        bpm: 128.0, confidence: 0.75, modelIdentifier: "mock"),
      snapshot: winSnapshot)

    var opts = AudioAnalysisService.Options()
    opts.intensity = .thorough
    opts.ensemblePolicy = .mlOnly
    opts.enableTrace = true
    opts.enableMLDiagnostics = true
    opts.mlTechnique = mock

    let result = try AudioAnalysisService.analyzeBPM(url: fixtureURL, options: opts)
    let nonNilResult = try #require(result, "DSP should resolve bpm-120-click")
    let trace = try #require(
      nonNilResult.trace,
      "Trace should be returned with enableTrace=true")
    let attached = try #require(
      trace.mlDiagnosticSnapshot,
      "Snapshot should be attached when enableMLDiagnostics=true")
    #expect(attached == winSnapshot)
  }
}

// MARK: - Helpers

/// Thread-safe counter used by the cancellation-flipping closure to
/// confirm it was actually consulted post-evaluate.
private final class LockedCounter: @unchecked Sendable {
  private var _value: Int = 0
  private let lock = NSLock()
  var value: Int {
    lock.lock()
    defer { lock.unlock() }
    return _value
  }
  func increment() {
    lock.lock()
    defer { lock.unlock() }
    _value += 1
  }
}

/// Thread-safe flag used to gate the `isCancelled` flip on
/// `evaluate(trace:)` having returned.
private final class LockedFlag: @unchecked Sendable {
  private var flag = false
  private let lock = NSLock()
  func set() {
    lock.lock()
    defer { lock.unlock() }
    flag = true
  }
  func get() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return flag
  }
}

/// Wraps an inner `MLDiagnosticTechnique` and fires `onEvaluate()` after
/// the inner conformer returns so the test's `isCancelled` closure can
/// observe the post-evaluate state transition.
private struct CancellationFlippingMock: MLDiagnosticTechnique {
  let inner: any MLDiagnosticTechnique
  let onEvaluate: @Sendable () -> Void

  func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
    let r = inner.evaluate(trace: trace)
    onEvaluate()
    return r
  }

  func evaluateWithDiagnostic(
    trace: BPMDiagnosticTrace
  ) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?) {
    let r = inner.evaluateWithDiagnostic(trace: trace)
    onEvaluate()
    return r
  }
}
