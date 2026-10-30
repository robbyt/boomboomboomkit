//
//  CombPhaseHookInvarianceTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.9: the onset-comb best-phase hook (`BeatGridAnalyzer.combPhaseObserver`)
//  is read only by the develop-only evaluation harness. Binding it must not change
//  any analysis output. Each fixture is decoded once, then analyzed with the
//  observer unbound and bound; the BPM result and the beat grid must be equal, and
//  the bound run must have delivered an observation for every grid it built.
//
//  One decode per fixture, so lossy-decoder variation between reads (see
//  LUFSByteIdentityTests) cannot enter the comparison.
//

import Foundation
import Synchronization
import Testing

@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitTestSupport

@Suite("Comb best-phase hook invariance (Story 15.9)")
struct CombPhaseHookInvarianceTests {

  private static let fixtures: [(name: String, ext: String)] = [
    ("bpm-120-click", "wav"),
    ("bpm-170-click", "wav"),
    ("bpm-120-downbeat", "wav"),
    ("Submerged_Lament", "mp3"),
    ("robbyt_x-ray-30s", "mp3"),
  ]

  private func expectSameBPM(
    _ a: AudioAnalysisResult, _ b: AudioAnalysisResult, _ fixture: String
  ) {
    #expect(a.bpm.bitPattern == b.bpm.bitPattern, "bpm differs on \(fixture)")
    #expect(a.confidence.bitPattern == b.confidence.bitPattern, "confidence differs on \(fixture)")
    #expect(a.candidates.count == b.candidates.count, "candidate count differs on \(fixture)")
    for (x, y) in zip(a.candidates, b.candidates) {
      #expect(x.bpm.bitPattern == y.bpm.bitPattern, "candidate bpm differs on \(fixture)")
      #expect(x.score.bitPattern == y.score.bitPattern, "candidate score differs on \(fixture)")
    }
    #expect(a.effectiveIntensity == b.effectiveIntensity)
    #expect(a.degradationReason == b.degradationReason)
  }

  @Test("analyze output is identical with and without the comb-phase observer bound")
  func analyzeOutputIgnoresTheObserver() throws {
    var refined = AudioAnalysisService.Options()
    refined.refineBeatGridTempo = true
    let optionSets: [(label: String, options: AudioAnalysisService.Options)] = [
      ("default", AudioAnalysisService.Options()),
      ("refineBeatGridTempo", refined),
    ]
    var observedGrids = 0
    for fixture in Self.fixtures {
      let url = try AudioFixtures.url(for: fixture.name, extension: fixture.ext)
      let decoded = try PCMBufferReader.readDecodedAudio(from: url, maxSeconds: 120)
      for (label, options) in optionSets {
        let tag = "\(fixture.name).\(fixture.ext) [\(label)]"
        let plain = try AudioAnalysisService.analyze(decoded: decoded, options: options)

        let seen = Mutex<[BeatGridAnalyzer.CombPhaseObservation]>([])
        let observer: @Sendable (BeatGridAnalyzer.CombPhaseObservation) -> Void = { obs in
          seen.withLock { $0.append(obs) }
        }
        let hooked = try BeatGridAnalyzer.$combPhaseObserver.withValue(observer) {
          try AudioAnalysisService.analyze(decoded: decoded, options: options)
        }
        let observations = seen.withLock { $0 }

        #expect((plain == nil) == (hooked == nil), "result presence differs on \(tag)")
        guard let plain, let hooked else { continue }
        expectSameBPM(plain.bpm, hooked.bpm, tag)
        #expect(plain.beatGrid == hooked.beatGrid, "beat grid differs on \(tag)")

        if let grid = hooked.beatGrid {
          observedGrids += 1
          #expect(observations.count == 1, "expected one observation on \(tag)")
          if let obs = observations.first {
            #expect(obs.tempoBPM == grid.estimatedTempo, "observed tempo differs on \(tag)")
            #expect(obs.phaseSeconds.isFinite)
            #expect(obs.bestPhase.bestBin >= 0 && obs.bestPhase.bestBin < obs.bestPhase.bins)
          }
        }
      }
    }
    #expect(observedGrids > 0, "no fixture produced a beat grid; the hook was never exercised")
  }
}
