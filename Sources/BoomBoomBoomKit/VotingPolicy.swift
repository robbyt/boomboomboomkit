//
//  VotingPolicy.swift
//  BoomBoomBoomKit
//
//  Resolution policy for windowVoting merge strategy.
//

import Foundation

/// Resolution policy used by ``BPMSelectionPolicy/windowVoting`` to choose
/// the consensus window across multiple analysis windows.
///
/// `VotingPolicy` is consulted ONLY when `mergeStrategy == .windowVoting` (where
/// `mergeStrategy` is the ``BPMSelectionPolicy`` value held by
/// ``AudioAnalysisService/Options``). It is NOT a DSP technique, NOT a merge
/// strategy case, and does NOT belong in ``DSPTechnique`` or
/// `BPMSelectionPolicy.allCases`.
///
/// All policies share the same 2% relative BPM tolerance for clustering windows;
/// they differ only in how the winning cluster is chosen and gated. The
/// threshold value (``AudioAnalysisService/Options/votingThreshold``) applies
/// only to ``thresholdGated``; the other two policies ignore it.
public enum VotingPolicy: String, CaseIterable, Sendable, Hashable {
  /// Pick the cluster with the most windows (`indices.count >= 2` required).
  ///
  /// When two or more clusters tie on size, the cluster whose highest-confidence
  /// window has the larger confidence wins; if those tie too, the cluster whose
  /// lowest original window index is smaller wins. Within the chosen cluster,
  /// the highest-confidence window is returned (breaking ties by lowest original
  /// index). Falls back to ``BPMSelectionPolicy/maxConfidence`` over ALL
  /// windows when no cluster has at least two members.
  ///
  /// This is the post-Story-3-3a baseline behavior and the default policy.
  /// ``AudioAnalysisService/Options/votingThreshold`` is ignored.
  case simpleMajority

  /// Pick the cluster with the highest summed confidence across its windows.
  ///
  /// All clusters are scored — singletons included — by `Σ confidence`. Ties on
  /// summed confidence break by (a) the cluster's highest single-window
  /// confidence, then (b) the cluster's lowest original window index. After the
  /// winner is chosen, if it is a singleton (its summed confidence equals one
  /// window's confidence — no consensus benefit) the policy falls back to
  /// ``BPMSelectionPolicy/maxConfidence`` over ALL windows. Otherwise the
  /// highest-confidence window in the winning cluster is returned (breaking
  /// ties by lowest original index).
  ///
  /// Permits a 2-vs-1 input to be decided by confidence sums rather than always
  /// favoring the larger group. ``AudioAnalysisService/Options/votingThreshold``
  /// is ignored.
  case confidenceWeighted

  /// Like ``simpleMajority`` but the chosen cluster's max single-window
  /// confidence must meet ``AudioAnalysisService/Options/votingThreshold``.
  ///
  /// The valid threshold range is `[0.0, 1.0]`. Out-of-range values silently
  /// clamp; non-finite values (NaN, ±Infinity, signaling NaN) silently fall
  /// back to `0.0` (permissive). When the chosen cluster's max confidence is
  /// strictly below the (normalized) threshold, the policy falls back to
  /// ``BPMSelectionPolicy/maxConfidence`` over ALL windows. Cluster
  /// selection and within-cluster window selection use the same explicit
  /// `(higher confidence, lower original index)` tiebreaker chain as
  /// ``simpleMajority``.
  ///
  /// Default threshold `0.0` is permissive (equivalent to ``simpleMajority``);
  /// raising it lets benchmark sweeps reject low-confidence consensus without
  /// recompiling.
  case thresholdGated
}
