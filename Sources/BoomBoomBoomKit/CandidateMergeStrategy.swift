//
//  CandidateMergeStrategy.swift
//  BoomBoomBoomKit
//
//  Strategy for merging BPM candidates across multiple analysis windows.
//  Used by AudioAnalysisService during progressive retry (intensity 6+).
//

import Foundation

/// Strategy for merging BPM candidates from multiple analysis windows.
///
/// Progressive analysis (intensity 6+) runs the pipeline on multiple
/// time windows (30s, 60s, 90s). This enum controls how the per-window
/// candidates are combined into a final result.
///
/// Use `CandidateMergeStrategy.allCases` and the OA300 benchmark to
/// ablate strategies and find the best fit for a given corpus.
public enum CandidateMergeStrategy: String, CaseIterable, Sendable, Hashable {
  /// Pick the single window with the highest confidence. Current default behavior.
  case maxConfidence

  /// Collect all candidates, deduplicate near-matches (within 2% BPM)
  /// keeping the highest score per cluster, re-rank by score.
  case dedup

  /// Group candidates into 2% BPM clusters. Rank by number of windows
  /// containing that cluster, break ties by max score.
  case quorum

  /// Group candidates into 2% BPM clusters. Score = mean of per-window
  /// scores within the cluster.
  case average

  /// Group candidates into 2% BPM clusters. Score = median of per-window
  /// scores within the cluster. Resistant to outlier windows.
  case median

  /// Group candidates into 2% BPM clusters. Score = confidence-weighted
  /// mean of per-window scores. High-confidence windows contribute more.
  case weightedAverage

  /// Pool all candidates from all windows without deduplication.
  /// Sort by raw score, cap at candidateCount.
  case union

  /// Vote on each window's final disambiguated BPM (not raw candidates).
  /// If 2+ windows agree within 2%, use the consensus BPM; otherwise
  /// fall back to maxConfidence.
  case windowVoting
}

// MARK: - Merge Logic

extension CandidateMergeStrategy {

  /// Merges candidates from multiple analysis windows using this strategy.
  ///
  /// - Parameters:
  ///   - windowResults: Per-window `BPMResult` values (from successful windows only).
  ///   - candidateCount: Maximum number of candidates to return.
  ///   - strategy: Strategy for combining window candidates.
  ///   - votingPolicy: Resolution policy for ``CandidateMergeStrategy/windowVoting``.
  ///     Ignored by all other strategies. Default ``VotingPolicy/simpleMajority``
  ///     reproduces the post-Story-3-3a baseline byte-for-byte.
  ///   - votingThreshold: Acceptance threshold for ``VotingPolicy/thresholdGated``
  ///     (range `[0.0, 1.0]`; out-of-range / non-finite values silently normalize
  ///     to a permissive default per DD#9). Ignored by all other strategies and by
  ///     the other two policies.
  /// - Returns: A merged `BPMResult`, or `nil` if `windowResults` is empty.
  static func merge(
    windowResults: [BPMResult],
    candidateCount: Int,
    strategy: CandidateMergeStrategy,
    votingPolicy: VotingPolicy = .simpleMajority,
    votingThreshold: Double = 0.0
  ) -> BPMResult? {
    guard !windowResults.isEmpty else { return nil }

    // Single window: no merging needed regardless of strategy.
    if windowResults.count == 1 {
      return windowResults[0]
    }

    switch strategy {
    case .maxConfidence:
      return mergeMaxConfidence(windowResults)
    case .dedup:
      return mergeClustered(windowResults, candidateCount: candidateCount, scoring: .max)
    case .quorum:
      return mergeClustered(windowResults, candidateCount: candidateCount, scoring: .quorum)
    case .average:
      return mergeClustered(windowResults, candidateCount: candidateCount, scoring: .average)
    case .median:
      return mergeClustered(windowResults, candidateCount: candidateCount, scoring: .median)
    case .weightedAverage:
      return mergeClustered(
        windowResults, candidateCount: candidateCount, scoring: .weightedAverage)
    case .union:
      return mergeUnion(windowResults, candidateCount: candidateCount)
    case .windowVoting:
      return mergeByWindowVoting(
        windowResults, policy: votingPolicy, threshold: votingThreshold)
    }
  }

  // MARK: - Strategy Implementations

  private static func mergeMaxConfidence(_ results: [BPMResult]) -> BPMResult {
    results.max(by: { $0.confidence < $1.confidence })!
  }

  private static func mergeUnion(
    _ results: [BPMResult], candidateCount: Int
  ) -> BPMResult {
    // Track which window produced the best candidate for trace selection.
    let allWithWindow: [(bpm: Double, score: Float, windowIndex: Int)] =
      results.enumerated().flatMap { (i, r) in
        r.candidates.map { (bpm: $0.bpm, score: $0.score, windowIndex: i) }
      }
    let sorted = allWithWindow.sorted { $0.score > $1.score }
    let capped = Array(sorted.prefix(candidateCount))
    let bestConfidence = results.map(\.confidence).max() ?? 0
    let winnerWindowIndex = capped.first?.windowIndex ?? 0
    return BPMResult(
      bpm: capped.first?.bpm ?? results[0].bpm,
      confidence: bestConfidence,
      candidates: capped.map { (bpm: $0.bpm, score: $0.score) },
      trace: results[winnerWindowIndex].trace)
  }

  // MARK: - Window Voting (post-disambiguation)

  /// Window voting (post-disambiguation): cluster windows by 2% BPM tolerance,
  /// then dispatch to a per-policy resolver. Clustering is shared across all
  /// three policies; resolvers differ in how they pick the winning cluster
  /// and (for ``VotingPolicy/thresholdGated``) how they gate it.
  ///
  /// Group insertion order is the original window enumeration order, so
  /// "lowest original index" tiebreakers (DD#16) reduce to comparing
  /// `groups[i].indices.first!` — distinct across groups since each window
  /// joins exactly one cluster.
  ///
  /// - Parameters:
  ///   - results: Per-window results (count >= 2 — single-window short-circuited
  ///     at the dispatcher).
  ///   - policy: Resolution policy. See ``VotingPolicy`` for per-case semantics.
  ///   - threshold: Acceptance threshold for ``VotingPolicy/thresholdGated`` (range
  ///     `[0.0, 1.0]`). Out-of-range / non-finite values silently normalize inside
  ///     the resolver per DD#9. Ignored by ``VotingPolicy/simpleMajority`` and
  ///     ``VotingPolicy/confidenceWeighted``.
  private static func mergeByWindowVoting(
    _ results: [BPMResult],
    policy: VotingPolicy,
    threshold: Double
  ) -> BPMResult {
    assert(
      results.count >= 2,
      "mergeByWindowVoting requires count >= 2; dispatcher must short-circuit count==1")
    // Group windows by their final disambiguated BPM (within 2% tolerance).
    // Insertion order = original window enumeration order — preserved for the
    // "lowest original index" tiebreakers per DD#16.
    var groups: [(bpm: Double, indices: [Int])] = []
    for (i, result) in results.enumerated() {
      if let g = groups.firstIndex(where: { isNearMatch(result.bpm, $0.bpm) }) {
        groups[g].indices.append(i)
      } else {
        groups.append((bpm: result.bpm, indices: [i]))
      }
    }

    switch policy {
    case .simpleMajority:
      return resolveSimpleMajority(results: results, groups: groups)
    case .confidenceWeighted:
      return resolveConfidenceWeighted(results: results, groups: groups)
    case .thresholdGated:
      return resolveThresholdGated(
        results: results, groups: groups, threshold: threshold)
    }
  }

  // MARK: - Window-Voting Resolvers (per VotingPolicy)

  /// Picks the group with the most windows (`indices.count >= 2`). Ties on
  /// size break by (a) max single-window confidence within the group, then
  /// (b) the group's lowest original window index. Returns the highest-
  /// confidence window in the chosen group (breaking ties by lowest original
  /// index per DD#16). Falls back to `mergeMaxConfidence(results)` when no
  /// group has at least two members.
  private static func resolveSimpleMajority(
    results: [BPMResult],
    groups: [(bpm: Double, indices: [Int])]
  ) -> BPMResult {
    guard let consensus = pickLargestCluster(results: results, groups: groups) else {
      return mergeMaxConfidence(results)
    }
    return bestWindow(in: consensus.indices, results: results)
  }

  /// Picks the group with the highest summed confidence across all its
  /// windows (singletons included). Ties on summed confidence break by
  /// (a) max single-window confidence within the group, then (b) the group's
  /// lowest original window index. If the chosen group is a singleton the
  /// policy falls back to `mergeMaxConfidence(results)` per DD#3 (a singleton's
  /// summed confidence equals its lone window's confidence — no consensus
  /// benefit). Otherwise returns the highest-confidence window in the chosen
  /// group (breaking ties by lowest original index per DD#16).
  private static func resolveConfidenceWeighted(
    results: [BPMResult],
    groups: [(bpm: Double, indices: [Int])]
  ) -> BPMResult {
    let scored = groups.map {
      group -> (group: (bpm: Double, indices: [Int]), summed: Double, maxConf: Double) in
      let summed = group.indices.reduce(0.0) { $0 + results[$1].confidence }
      let maxConf = group.indices.map { results[$0].confidence }.max() ?? 0
      return (group: group, summed: summed, maxConf: maxConf)
    }

    guard
      let winner = scored.min(by: { lhs, rhs in
        if lhs.summed != rhs.summed { return lhs.summed > rhs.summed }
        if lhs.maxConf != rhs.maxConf { return lhs.maxConf > rhs.maxConf }
        return (lhs.group.indices.first ?? 0) < (rhs.group.indices.first ?? 0)
      })
    else {
      return mergeMaxConfidence(results)
    }

    // Post-pick singleton fallback per DD#3.
    if winner.group.indices.count == 1 {
      return mergeMaxConfidence(results)
    }
    return bestWindow(in: winner.group.indices, results: results)
  }

  /// Like ``resolveSimpleMajority`` but the chosen cluster's max single-window
  /// confidence must be `>= effectiveThreshold`, where `effectiveThreshold`
  /// silently clamps `threshold` to `[0.0, 1.0]` and normalizes non-finite
  /// values (NaN, ±Infinity, signaling NaN) to `0.0` per DD#9. Falls back to
  /// `mergeMaxConfidence(results)` when no cluster qualifies under the gate.
  private static func resolveThresholdGated(
    results: [BPMResult],
    groups: [(bpm: Double, indices: [Int])],
    threshold: Double
  ) -> BPMResult {
    // DD#9: silent-clamp the threshold inside the helper so the function is
    // self-contained for any caller (current or future).
    let effectiveThreshold: Double =
      threshold.isFinite ? min(max(threshold, 0.0), 1.0) : 0.0

    guard let consensus = pickLargestCluster(results: results, groups: groups) else {
      return mergeMaxConfidence(results)
    }

    let maxConf = consensus.indices.map { results[$0].confidence }.max() ?? 0
    guard maxConf >= effectiveThreshold else {
      return mergeMaxConfidence(results)
    }
    return bestWindow(in: consensus.indices, results: results)
  }

  /// Shared cluster-selection logic for ``resolveSimpleMajority`` and
  /// ``resolveThresholdGated``. Picks the group with the most windows
  /// (`indices.count >= 2` required); ties break by (a) max single-window
  /// confidence within the group, then (b) the group's lowest original
  /// window index (DD#16). Returns nil when no group has two or more members.
  private static func pickLargestCluster(
    results: [BPMResult],
    groups: [(bpm: Double, indices: [Int])]
  ) -> (bpm: Double, indices: [Int])? {
    groups
      .filter { $0.indices.count >= 2 }
      .min { lhs, rhs in
        if lhs.indices.count != rhs.indices.count {
          return lhs.indices.count > rhs.indices.count
        }
        let lMaxConf = lhs.indices.map { results[$0].confidence }.max() ?? 0
        let rMaxConf = rhs.indices.map { results[$0].confidence }.max() ?? 0
        if lMaxConf != rMaxConf { return lMaxConf > rMaxConf }
        return (lhs.indices.first ?? 0) < (rhs.indices.first ?? 0)
      }
  }

  /// Picks the highest-confidence window from a cluster, breaking ties by
  /// lowest original window index (DD#16 explicit chain).
  private static func bestWindow(
    in indices: [Int],
    results: [BPMResult]
  ) -> BPMResult {
    let bestIndex = indices.min { lhs, rhs in
      let lConf = results[lhs].confidence
      let rConf = results[rhs].confidence
      if lConf != rConf { return lConf > rConf }
      return lhs < rhs
    }!
    return results[bestIndex]
  }

  // MARK: - Clustered Merge (dedup, quorum, average, median, weightedAverage)

  private enum ClusterScoring {
    case max, quorum, average, median, weightedAverage
  }

  private static func mergeClustered(
    _ results: [BPMResult],
    candidateCount: Int,
    scoring: ClusterScoring
  ) -> BPMResult {
    let clusters = buildClusters(from: results)

    // Score each cluster according to strategy.
    let scored: [(bpm: Double, score: Float, windowIndex: Int)] = clusters.map { cluster in
      let score: Float
      switch scoring {
      case .max:
        score = cluster.scores.max() ?? 0
      case .quorum:
        score = cluster.scores.max() ?? 0
      case .average:
        score = cluster.scores.reduce(0, +) / Float(max(cluster.scores.count, 1))
      case .median:
        score = medianFloat(cluster.scores)
      case .weightedAverage:
        let totalWeight = cluster.confidences.reduce(0, +)
        if totalWeight > 0 {
          var weightedSum: Double = 0
          for i in 0..<cluster.scores.count {
            weightedSum += Double(cluster.scores[i]) * cluster.confidences[i]
          }
          score = Float(weightedSum / totalWeight)
        } else {
          score = 0
        }
      }
      return (bpm: cluster.bpm, score: score, windowIndex: cluster.bestWindowIndex)
    }

    // For quorum: sort by (windowCount desc, score desc). Others: sort by score desc.
    let sorted: [(bpm: Double, score: Float, windowIndex: Int)]
    if scoring == .quorum {
      let clusterWindowCounts = zip(scored, clusters).map { ($0.0, $0.1.uniqueWindowCount) }
      sorted =
        clusterWindowCounts
        .sorted { lhs, rhs in
          if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
          return lhs.0.score > rhs.0.score
        }
        .map { $0.0 }
    } else {
      sorted = scored.sorted { $0.score > $1.score }
    }

    let capped = Array(sorted.prefix(candidateCount))
    let bestConfidence = results.map(\.confidence).max() ?? 0
    let winnerWindowIndex = capped.first?.windowIndex ?? 0

    return BPMResult(
      bpm: capped.first?.bpm ?? results[0].bpm,
      confidence: bestConfidence,
      candidates: capped.map { (bpm: $0.bpm, score: $0.score) },
      trace: results[winnerWindowIndex].trace)
  }

  // MARK: - Shared Clustering

  private static func buildClusters(from results: [BPMResult]) -> [BPMCluster] {
    var clusters: [BPMCluster] = []
    for (windowIndex, result) in results.enumerated() {
      for candidate in result.candidates {
        if let clusterIndex = clusters.firstIndex(where: {
          isNearMatch(candidate.bpm, $0.bpm)
        }) {
          clusters[clusterIndex].add(
            score: candidate.score,
            bpm: candidate.bpm,
            windowIndex: windowIndex,
            confidence: result.confidence)
        } else {
          var cluster = BPMCluster(bpm: candidate.bpm)
          cluster.add(
            score: candidate.score,
            bpm: candidate.bpm,
            windowIndex: windowIndex,
            confidence: result.confidence)
          clusters.append(cluster)
        }
      }
    }
    return clusters
  }

  // MARK: - Helpers

  /// Two BPMs are near-matches if within 2% (same tolerance as Acc1).
  private static func isNearMatch(_ a: Double, _ b: Double) -> Bool {
    let smaller = min(a, b)
    guard smaller > 0 else { return false }
    return abs(a - b) / smaller <= 0.02
  }

  private static func medianFloat(_ values: [Float]) -> Float {
    guard !values.isEmpty else { return 0 }
    let sorted = values.sorted()
    let mid = sorted.count / 2
    if sorted.count.isMultiple(of: 2) {
      return (sorted[mid - 1] + sorted[mid]) / 2
    }
    return sorted[mid]
  }
}

// MARK: - BPM Cluster

/// Groups near-match candidates across windows for score aggregation.
private struct BPMCluster {
  /// Representative BPM (from highest-scoring entry).
  private(set) var bpm: Double
  /// All scores contributed to this cluster.
  private(set) var scores: [Float] = []
  /// Confidences of the windows that contributed each score.
  private(set) var confidences: [Double] = []
  /// Set of window indices that contributed to this cluster.
  private var windowIndices: Set<Int> = []
  /// Highest score seen (used to track representative BPM).
  private var bestScore: Float = 0
  /// Window index that contributed the highest score.
  private(set) var bestWindowIndex: Int = 0

  init(bpm: Double) {
    self.bpm = bpm
  }

  var uniqueWindowCount: Int { windowIndices.count }

  mutating func add(score: Float, bpm: Double, windowIndex: Int, confidence: Double) {
    scores.append(score)
    confidences.append(confidence)
    windowIndices.insert(windowIndex)
    if score > bestScore {
      bestScore = score
      self.bpm = bpm
      self.bestWindowIndex = windowIndex
    }
  }
}
