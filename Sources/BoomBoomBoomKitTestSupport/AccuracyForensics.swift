//
//  AccuracyForensics.swift
//  BoomBoomBoomKitTestSupport
//
//  Phase 0 forensic accuracy instrumentation (reporting-only). Turns a corpus of
//  (expected, detected, candidates, confidence) rows into an attribution report:
//  candidate-recall oracle, error-type histogram + recall split, confidence
//  reliability curve, BPM-error distribution, per-genre error-type composition, and
//  a per-failure label-policy tag. Pure value types + `Codable` for JSON emission;
//  no audio I/O, no DSP. The harness (`AccuracyForensicsTests`) feeds it analyzer
//  output; this file never touches `Sources/BoomBoomBoomKit/`.
//

import Foundation

// MARK: - Input

/// One analyzed track handed to the forensic builder. `detectedBPM` / `confidence`
/// are `nil` when `analyzeBPM` returned `nil` (non-musical / silent).
public struct ForensicInput: Sendable {
  public let id: String
  public let genre: String?
  public let expectedBPM: Double
  /// A second equally-valid ground-truth annotation (GiantSteps `tempo2` — a track may
  /// carry two perceptually-valid tempi). A detection matching EITHER truth is correct,
  /// mirroring the canonical `mirexHit`. `nil` for single-annotation corpora (OA300).
  public let alternateBPM: Double?
  public let detectedBPM: Double?
  public let confidence: Double?
  public let candidates: [(bpm: Double, score: Float)]
  /// True when ground truth is metronomic (DAW/Bitwig-verified) rather than a
  /// crowdsourced tag that could encode a perceptual half/double tempo.
  public let isMetronomicTruth: Bool

  public init(
    id: String, genre: String?, expectedBPM: Double, alternateBPM: Double? = nil,
    detectedBPM: Double?, confidence: Double?, candidates: [(bpm: Double, score: Float)],
    isMetronomicTruth: Bool
  ) {
    self.id = id
    self.genre = genre
    self.expectedBPM = expectedBPM
    self.alternateBPM = alternateBPM
    self.detectedBPM = detectedBPM
    self.confidence = confidence
    self.candidates = candidates
    self.isMetronomicTruth = isMetronomicTruth
  }
}

// MARK: - Candidate-recall oracle

/// Whether the true tempo (or a harmonic relative) was present in the candidate set,
/// at what rank, with which factor, and how far behind the selected winner it scored.
public struct CandidateRecall: Sendable, Codable {
  /// 1-based rank of the first candidate matching truth at any factor; `nil` = absent.
  public let bestRank: Int?
  /// The factor that matched (`"1x"`, `"2x"`, `"0.5x"`, `"3x"`, `"1/3x"`, `"3:2"`, `"2:3"`).
  /// Exact (`"1x"`) matches across ALL truths are preferred over a harmonic of another truth,
  /// so a candidate equal to an octave `tempo2` reads `"1x"` (vs the primary's `"2x"`).
  public let matchedFactor: String?
  /// Which ground truth the match was against — `"primary"` or `"alternate"` (GiantSteps
  /// `tempo2`); `nil` when absent. Disambiguates `matchedFactor == "1x"` for dual-truth rows.
  public let matchedTruth: String?
  /// `winnerScore - oracleCandidateScore`, where `winnerScore` is the score of the
  /// pre-disambiguation candidate NEAREST the final detected BPM within tolerance — an
  /// APPROXIMATION, because `AudioAnalysisResult` does not expose which candidate the
  /// pipeline selected (`candidates` is the pre-disambiguation list, so `candidates[0]`
  /// is NOT necessarily the winner). SIGNED: a small positive margin = "lost by a hair";
  /// large positive = "buried"; **negative = the selected output scored LOWER than the
  /// true candidate, i.e. post-candidate disambiguation overrode a higher-scored correct
  /// candidate**. `nil` when no candidate corresponds to the detected BPM (or it was
  /// absent / `detectedBPM` was nil).
  public let scoreMargin: Float?
  public let inTop1: Bool
  public let inTop3: Bool
  public let inTop5: Bool
  public let inTop10: Bool
}

// MARK: - Per-track detail

public struct ForensicTrackDetail: Sendable, Codable {
  public let id: String
  public let genre: String?
  public let expectedBPM: Double
  public let detectedBPM: Double?
  public let confidence: Double?
  public let acc1: Bool
  public let acc2: Bool
  /// ``TempoErrorCategory`` raw value, or `"nil-result"` when `analyzeBPM` returned nil.
  public let errorCategory: String
  public let recall: CandidateRecall?
  public let absErrorBPM: Double?
  public let absErrorOctaveNormBPM: Double?
  public let labelPolicy: String
}

// MARK: - Aggregates

public struct ErrorStats: Sendable, Codable {
  public let median: Double
  public let mean: Double
  public let p95: Double
}

/// The split that decides Phase 1's target (selection vs generation).
public struct RecallSplit: Sendable, Codable {
  /// Acc1 miss where the true tempo (or relative) WAS in the top 5 → selection-bound.
  public let missTrueInTop5: Int
  /// Acc1 miss where the true tempo was absent from the candidates → generation-bound.
  public let missTrueAbsent: Int
  /// Acc1 miss where the true tempo was even at rank 1 → lost in post-candidate
  /// disambiguation/rescore (a distinct, smaller failure class).
  public let missTrueAtRank1: Int
}

public struct ConfidenceBin: Sendable, Codable {
  public let lower: Double
  public let upper: Double
  public let count: Int
  public let acc1: Int
  public var acc1Percent: Double { count > 0 ? Double(acc1) / Double(count) * 100 : 0 }
}

public struct GenreForensic: Sendable, Codable {
  public let genre: String
  public let total: Int
  public let acc1: Int
  public let acc2: Int
  public let errorTypeHistogram: [String: Int]
}

public struct ForensicCorpusReport: Sendable, Codable {
  public let corpus: String
  public let total: Int
  public let analyzed: Int
  public let nilCount: Int
  public let acc1: Int
  public let acc2: Int
  public let errorTypeHistogram: [String: Int]
  public let recallSplit: RecallSplit
  public let confidenceReliability: [ConfidenceBin]
  public let maeRawBPM: ErrorStats
  public let maeOctaveNormBPM: ErrorStats
  public let perGenre: [GenreForensic]
  public let labelPolicyHistogram: [String: Int]
  public let details: [ForensicTrackDetail]
}

// MARK: - Builder

public enum AccuracyForensics {

  /// The shared 2% MIREX relative band — the SAME tolerance the corpus benchmarks use,
  /// so forensic categories line up with Acc1/Acc2 exactly.
  public static let tolerance: Double = 0.02

  /// Factors probed by the recall oracle, in label order (octave then triplet).
  private static let recallFactors: [(label: String, factor: Double)] = [
    ("1x", 1.0), ("2x", 2.0), ("0.5x", 0.5), ("3x", 3.0), ("1/3x", 1.0 / 3.0),
    ("3:2", 1.5), ("2:3", 2.0 / 3.0),
  ]

  /// Confidence-reliability bin edges: [0,0.5),[0.5,0.6),…,[0.9,1.0].
  private static let confidenceEdges: [Double] = [0, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0001]

  /// Best-rank presence of ANY ground truth (primary + optional alternate, e.g.
  /// GiantSteps `tempo2`) — or a harmonic relative of one — in the candidate set.
  ///
  /// `detectedBPM` is the pipeline's SELECTED tempo; its score (used for ``scoreMargin``)
  /// is recovered from the candidate nearest it within tolerance, NOT `candidates[0]`
  /// (which is the top *pre-disambiguation* score and may not be the winner). See
  /// ``CandidateRecall/scoreMargin``.
  public static func candidateRecall(
    candidates: [(bpm: Double, score: Float)], truths: [Double], detectedBPM: Double?
  ) -> CandidateRecall {
    let absent = CandidateRecall(
      bestRank: nil, matchedFactor: nil, matchedTruth: nil, scoreMargin: nil,
      inTop1: false, inTop3: false, inTop5: false, inTop10: false)
    // Label each truth: the first is primary, any others are the alternate annotation
    // (GiantSteps `tempo2`). Filter out non-positive truths.
    let labeled: [(value: Double, label: String)] = truths.enumerated().compactMap { idx, t in
      t > 0 ? (t, idx == 0 ? "primary" : "alternate") : nil
    }
    guard !labeled.isEmpty, !candidates.isEmpty else { return absent }
    let winnerScore = selectedCandidateScore(candidates: candidates, detectedBPM: detectedBPM)
    for (idx, cand) in candidates.enumerated() {
      // Factor-outer, truth-inner: prefer an exact (`1x`) match against ANY truth before a
      // harmonic of another truth, so a candidate equal to an octave `tempo2` reads `1x`
      // (alternate) rather than `2x` (primary). The candidate (rank) loop stays outermost,
      // so `bestRank` / `inTopN` / `scoreMargin` are unaffected by this reorder.
      for probe in recallFactors {
        for truth in labeled
        where isAcc1Match(cand.bpm, truth.value * probe.factor, tolerance: tolerance) {
          let rank = idx + 1
          return CandidateRecall(
            bestRank: rank, matchedFactor: probe.label, matchedTruth: truth.label,
            scoreMargin: winnerScore.map { $0 - cand.score },
            inTop1: rank <= 1, inTop3: rank <= 3, inTop5: rank <= 5, inTop10: rank <= 10)
        }
      }
    }
    return absent
  }

  /// Score of the pre-disambiguation candidate corresponding to the SELECTED `detectedBPM`:
  /// the candidate within the 2% band of `detectedBPM`, tie-broken by closest `|Δbpm|` then
  /// highest score. `nil` when none matches (the winner was octave-shifted/refined off the
  /// list, or `detectedBPM` is nil) — callers must NOT substitute `candidates[0]`.
  private static func selectedCandidateScore(
    candidates: [(bpm: Double, score: Float)], detectedBPM: Double?
  ) -> Float? {
    guard let detectedBPM, detectedBPM > 0 else { return nil }
    let inBand = candidates.filter { isAcc1Match($0.bpm, detectedBPM, tolerance: tolerance) }
    return inBand.min { a, b in
      let da = abs(a.bpm - detectedBPM)
      let db = abs(b.bpm - detectedBPM)
      return da != db ? da < db : a.score > b.score
    }?.score
  }

  /// Folds `detected` by octaves (×/÷2) into the √2-neighborhood of `expected`, so the
  /// residual `|folded - expected|` measures error IGNORING the octave choice.
  public static func octaveNormalizedError(detected: Double, expected: Double) -> Double {
    guard detected > 0, expected > 0 else { return abs(detected - expected) }
    var d = detected
    while d < expected / 1.414_213_562 { d *= 2 }
    while d > expected * 1.414_213_562 { d /= 2 }
    return abs(d - expected)
  }

  public static func buildReport(corpus: String, tracks: [ForensicInput]) -> ForensicCorpusReport {
    var details: [ForensicTrackDetail] = []
    var errorHist: [String: Int] = [:]
    var labelHist: [String: Int] = [:]
    var rawErrors: [Double] = []
    var octErrors: [Double] = []
    var acc1 = 0
    var acc2 = 0
    var nilCount = 0
    var missTop5 = 0
    var missAbsent = 0
    var missRank1 = 0
    var binCounts = [Int](repeating: 0, count: confidenceEdges.count - 1)
    var binAcc1 = [Int](repeating: 0, count: confidenceEdges.count - 1)
    var genreAcc: [String: (total: Int, acc1: Int, acc2: Int, hist: [String: Int])] = [:]

    for t in tracks {
      let genreKey = (t.genre?.isEmpty == false) ? t.genre! : "unknown"
      let truths = [t.expectedBPM] + (t.alternateBPM.map { [$0] } ?? [])

      guard let detected = t.detectedBPM else {
        nilCount += 1
        labelHist["nil-result", default: 0] += 1
        details.append(
          ForensicTrackDetail(
            id: t.id, genre: t.genre, expectedBPM: t.expectedBPM, detectedBPM: nil,
            confidence: nil, acc1: false, acc2: false, errorCategory: "nil-result",
            recall: candidateRecall(candidates: t.candidates, truths: truths, detectedBPM: nil),
            absErrorBPM: nil, absErrorOctaveNormBPM: nil, labelPolicy: "nil-result"))
        continue
      }

      // A detection matching EITHER ground-truth annotation is correct (mirrors the
      // canonical `mirexHit`); an Acc1 hit is always categorized `exact`.
      let isA1 = truths.contains { isAcc1Match(detected, $0, tolerance: tolerance) }
      let isA2 = truths.contains { isAcc2Match(detected, $0, tolerance: tolerance) }
      let category =
        isA1
        ? .exact
        : categorizeAgainstTruths(detected, primary: t.expectedBPM, alternate: t.alternateBPM)
      let recall = candidateRecall(candidates: t.candidates, truths: truths, detectedBPM: detected)
      let rawErr = truths.map { abs(detected - $0) }.min() ?? abs(detected)
      let octErr =
        truths.map { octaveNormalizedError(detected: detected, expected: $0) }.min() ?? 0
      let label = labelPolicy(isMetronomic: t.isMetronomicTruth, acc1: isA1, category: category)

      if isA1 { acc1 += 1 }
      if isA2 { acc2 += 1 }
      errorHist[category.rawValue, default: 0] += 1
      labelHist[label, default: 0] += 1
      rawErrors.append(rawErr)
      octErrors.append(octErr)

      if !isA1 {
        if recall.inTop5 { missTop5 += 1 } else if recall.bestRank == nil { missAbsent += 1 }
        if recall.bestRank == 1 { missRank1 += 1 }
      }

      if let conf = t.confidence, let bin = confidenceBinIndex(conf) {
        binCounts[bin] += 1
        if isA1 { binAcc1[bin] += 1 }
      }

      var g = genreAcc[genreKey, default: (0, 0, 0, [:])]
      g.total += 1
      if isA1 { g.acc1 += 1 }
      if isA2 { g.acc2 += 1 }
      g.hist[category.rawValue, default: 0] += 1
      genreAcc[genreKey] = g

      details.append(
        ForensicTrackDetail(
          id: t.id, genre: t.genre, expectedBPM: t.expectedBPM, detectedBPM: detected,
          confidence: t.confidence, acc1: isA1, acc2: isA2, errorCategory: category.rawValue,
          recall: recall, absErrorBPM: rawErr, absErrorOctaveNormBPM: octErr, labelPolicy: label))
    }

    // Deterministic detail order (the aggregates above are order-independent): the harness
    // builds `tracks` in TaskGroup completion order, so sort by id (then expectedBPM, then
    // detectedBPM) to keep the committed JSON diff-stable across identical runs.
    details.sort {
      ($0.id, $0.expectedBPM, $0.detectedBPM ?? -1)
        < ($1.id, $1.expectedBPM, $1.detectedBPM ?? -1)
    }

    let bins = (0..<binCounts.count).map { i in
      ConfidenceBin(
        lower: confidenceEdges[i], upper: min(confidenceEdges[i + 1], 1.0),
        count: binCounts[i], acc1: binAcc1[i])
    }
    let perGenre =
      genreAcc
      .map {
        GenreForensic(
          genre: $0.key, total: $0.value.total, acc1: $0.value.acc1, acc2: $0.value.acc2,
          errorTypeHistogram: $0.value.hist)
      }
      .sorted { $0.total > $1.total || ($0.total == $1.total && $0.genre < $1.genre) }

    return ForensicCorpusReport(
      corpus: corpus, total: tracks.count, analyzed: tracks.count - nilCount, nilCount: nilCount,
      acc1: acc1, acc2: acc2, errorTypeHistogram: errorHist,
      recallSplit: RecallSplit(
        missTrueInTop5: missTop5, missTrueAbsent: missAbsent, missTrueAtRank1: missRank1),
      confidenceReliability: bins,
      maeRawBPM: errorStats(rawErrors), maeOctaveNormBPM: errorStats(octErrors),
      perGenre: perGenre, labelPolicyHistogram: labelHist, details: details)
  }

  // MARK: - Private

  /// Categorizes a MISS against the primary truth, falling back to the alternate when the
  /// primary relation is `other` (a track whose detection is, say, a clean double of the
  /// `tempo2` annotation should read `double`, not `other`). Only reached when `!isA1`.
  private static func categorizeAgainstTruths(
    _ detected: Double, primary: Double, alternate: Double?
  ) -> TempoErrorCategory {
    let c = classifyTempoError(detected, primary, tolerance: tolerance)
    if c != .other { return c }
    if let alternate {
      let ca = classifyTempoError(detected, alternate, tolerance: tolerance)
      if ca != .other { return ca }
    }
    return .other
  }

  /// The label-policy tag is per-FAILURE metadata. An Acc1 hit is `acc1-hit` (so successes do
  /// not swamp the failure signal in the histogram); among MISSES: metronomic ground truth →
  /// `metronomic-label` (a failure against a trusted label); a clean octave (double/half) on a
  /// crowdsourced label → `perceptual-label-suspect` (likely perceptual-vs-metronomic
  /// disagreement); everything else → `ambiguous`.
  private static func labelPolicy(isMetronomic: Bool, acc1: Bool, category: TempoErrorCategory)
    -> String
  {
    if acc1 { return "acc1-hit" }
    if isMetronomic { return "metronomic-label" }
    if category == .double || category == .half { return "perceptual-label-suspect" }
    return "ambiguous"
  }

  private static func confidenceBinIndex(_ confidence: Double) -> Int? {
    guard confidence.isFinite, confidence >= 0 else { return nil }
    for i in 0..<(confidenceEdges.count - 1)
    where confidence >= confidenceEdges[i] && confidence < confidenceEdges[i + 1] {
      return i
    }
    return nil
  }

  private static func errorStats(_ values: [Double]) -> ErrorStats {
    guard !values.isEmpty else { return ErrorStats(median: 0, mean: 0, p95: 0) }
    let sorted = values.sorted()
    let mean = values.reduce(0, +) / Double(values.count)
    let median = percentile(sorted, 0.5)
    let p95 = percentile(sorted, 0.95)
    return ErrorStats(median: median, mean: mean, p95: p95)
  }

  /// Nearest-rank percentile over a pre-sorted array (`0 ≤ q ≤ 1`).
  private static func percentile(_ sorted: [Double], _ q: Double) -> Double {
    guard !sorted.isEmpty else { return 0 }
    let idx = Int((Double(sorted.count - 1) * q).rounded())
    return sorted[min(max(idx, 0), sorted.count - 1)]
  }
}
