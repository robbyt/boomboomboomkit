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
  /// - Returns: A merged `BPMResult`, or `nil` if `windowResults` is empty.
  static func merge(
    windowResults: [BPMResult],
    candidateCount: Int,
    strategy: CandidateMergeStrategy
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
      return mergeClustered(windowResults, candidateCount: candidateCount, scoring: .weightedAverage)
    case .union:
      return mergeUnion(windowResults, candidateCount: candidateCount)
    case .windowVoting:
      return mergeByWindowVoting(windowResults)
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

  private static func mergeByWindowVoting(_ results: [BPMResult]) -> BPMResult {
    // Group windows by their final disambiguated BPM (within 2% tolerance).
    var groups: [(bpm: Double, indices: [Int])] = []
    for (i, result) in results.enumerated() {
      if let g = groups.firstIndex(where: { isNearMatch(result.bpm, $0.bpm) }) {
        groups[g].indices.append(i)
      } else {
        groups.append((bpm: result.bpm, indices: [i]))
      }
    }

    // Find the largest consensus group (2+ windows required).
    let consensus = groups
      .filter { $0.indices.count >= 2 }
      .max { $0.indices.count < $1.indices.count }

    if let consensus {
      // Pick the highest-confidence window within the consensus group.
      let bestIndex = consensus.indices.max { results[$0].confidence < results[$1].confidence }!
      return results[bestIndex]
    }

    // No consensus: fall back to maxConfidence.
    return mergeMaxConfidence(results)
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
      sorted = clusterWindowCounts
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
