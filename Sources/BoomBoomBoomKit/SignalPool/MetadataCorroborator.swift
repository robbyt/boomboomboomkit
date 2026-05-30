//
//  MetadataCorroborator.swift
//  BoomBoomBoomKit
//
//  Post-merge metadata corroboration: boosts candidates that match a tag,
//  re-selects the winner, and applies confidence boost or skepticism penalty.
//

import Foundation

// MARK: - Input

/// Aggregated metadata signal passed to ``MetadataCorroborator/apply(to:input:)``.
///
/// Built once per file by ``AudioAnalysisService/analyzeBPM(url:options:)``
/// after the file-metadata read. Carries:
/// - `consensusBPM`: the agreed-on tag BPM when two or more sources are
///   unanimous within ``MetadataPolicy/consensusTolerance``. `nil` when only
///   one source produced a valid tag, or when intra-file conflict was
///   detected, or when no enabled tag was present.
/// - `participatingTags`: one initial ``MetadataBPMEvidence`` entry per parsed
///   tag, including parse-phase rejections (`sentinel-zero`, `out-of-range`,
///   `non-numeric`). The corroborator updates these entries and emits the
///   final list back to the service.
/// - `conflictDetected`: `true` when two or more valid tags disagreed by more
///   than the consensus tolerance — every valid tag is rejected for decision
///   purposes (per AC #10's all-or-nothing rule).
/// - `policy`: the policy this corroboration runs under.
struct MetadataCorroborationInput: Sendable {
  let consensusBPM: Double?
  let participatingTags: [MetadataBPMEvidence]
  let conflictDetected: Bool
  let policy: MetadataPolicy
}

// MARK: - Corroborator

/// Caseless enum namespace (parallel to `MelFilterbank`, `FileMetadataReader`)
/// that applies tag-driven corroboration to a merged ``BPMResult`` AFTER
/// ``BPMSelectionPolicy/merge(windowResults:candidateCount:strategy:votingPolicy:votingThreshold:)``
/// returns. Lives outside `merge` deliberately so the merge signature stays
/// `BPMResult?` (Codex finding C1: 41 call sites would cascade) and so the
/// `windowResults.count == 1` short-circuit inside `merge` cannot silently
/// bypass metadata at intensity 1-5 (Codex finding C3).
enum MetadataCorroborator {

  /// Applies tag-based corroboration to `result`.
  ///
  /// - Important: **Temporary legacy post-merge adapter (Story 6.4 / KDD-A6
  ///   Stage 3, Part 1).** Retained byte-unchanged until Story 6.5, where this
  ///   boost / skepticism-penalty / winner-reselection math is re-expressed as
  ///   `.present` / `.demoted` votes over the authoritative ``UnifiedSignalPool``
  ///   and this standalone post-merge entry point is removed. Story 6.4b only
  ///   relocated the type into `SignalPool/`; the genuine removal (with its
  ///   semantic replacement) lands in 6.5 — deletion without replacement would
  ///   be churn.
  ///
  /// Boosts every candidate whose BPM matches any participating tag at an
  /// allowed ratio (same-tempo within ``MetadataPolicy/corroborationTolerance``,
  /// optionally octave 1.92-2.08, optionally triplet 1.45-1.55 / 2.85-3.15),
  /// re-selects the winner from the boosted candidate pool, and applies the
  /// confidence boost or skepticism penalty per AC #11 / #14 / #15.
  ///
  /// When `input.participatingTags.isEmpty` (the policy=disabled path and the
  /// no-tags-found path), returns the result with `bpm`/`confidence`/`candidates`
  /// unchanged. When `result.trace != nil`, the trace's `candidatesAfterBoost`
  /// is populated by mirroring `result.candidates` so ``MLTechnique`` conformers
  /// can read the canonical post-pipeline candidate set from a single field;
  /// when `result.trace == nil`, the populator returns nil and the BPMResult's
  /// trace stays nil. Returned evidence is always `[]` on this branch.
  static func apply(
    to result: BPMResult,
    input: MetadataCorroborationInput
  ) -> (BPMResult, [MetadataBPMEvidence]) {

    // No tags → pass through, but populate the trace's
    // ``BPMDiagnosticTrace/candidatesAfterBoost`` with the post-pipeline
    // candidate set so ``MLTechnique`` conformers can always read the
    // canonical featurization surface from a single field — instead of
    // having to special-case the no-tags / disabled-policy paths against
    // ``BPMDiagnosticTrace/rawCandidates``. Mirrors `result.candidates`
    // verbatim; metadata evidence remains empty (no tags participated)
    // and `metadataPolicyUsed` records the policy this run used.
    // Story 4.3 code review (Codex consult thread
    // `019dfa81-a8b9-7bf3-b602-4f8c53916ab0`, 2026-05-05): "absence is
    // metadata-shaped, not candidate-shaped" — keep the candidate
    // collection candidate-shaped. When `result.trace == nil`
    // (`enableTrace == false` AND `mlTechnique == nil`), the populator
    // returns nil and `BPMResult.trace` stays nil — zero behavior change.
    if input.participatingTags.isEmpty {
      let updatedTrace = trace(
        result.trace,
        TracePopulation(
          policy: input.policy,
          evidenceBeforeBoost: [],
          candidatesBefore: result.candidates,
          candidatesAfter: result.candidates,
          finalConfidence: result.confidence))
      return (
        BPMResult(
          bpm: result.bpm, confidence: result.confidence,
          candidates: result.candidates, trace: updatedTrace),
        []
      )
    }

    // Snapshot the trace's pre-boost view (populated below if enableTrace).
    let originalCandidates = result.candidates
    let prevConfidence = result.confidence

    // Intra-file conflict: every valid (non-rejected) tag is marked
    // `intra-file-conflict`. Parse-phase rejections keep their original reason.
    if input.conflictDetected {
      let evidence = input.participatingTags.map { e -> MetadataBPMEvidence in
        if e.rejectionReason != nil {
          return e
        }
        return MetadataBPMEvidence(
          source: e.source, rawValue: e.rawValue, parsedBPM: e.parsedBPM,
          corroboratedWith: nil, ratioMatched: nil,
          boostApplied: 1.0, rejectionReason: "intra-file-conflict")
      }
      let updatedTrace = trace(
        result.trace,
        TracePopulation(
          policy: input.policy,
          evidenceBeforeBoost: input.participatingTags,
          candidatesBefore: originalCandidates,
          candidatesAfter: originalCandidates,
          finalConfidence: prevConfidence))
      return (
        BPMResult(
          bpm: result.bpm, confidence: prevConfidence,
          candidates: originalCandidates, trace: updatedTrace),
        evidence
      )
    }

    // Identify valid (non-rejected) tags for matching.
    let validTagIndices = input.participatingTags.indices.filter {
      input.participatingTags[$0].rejectionReason == nil
    }

    // No valid tags (all parse-rejected) — pass through with parse-rejected evidence.
    if validTagIndices.isEmpty {
      let updatedTrace = trace(
        result.trace,
        TracePopulation(
          policy: input.policy,
          evidenceBeforeBoost: input.participatingTags,
          candidatesBefore: originalCandidates,
          candidatesAfter: originalCandidates,
          finalConfidence: prevConfidence))
      return (
        BPMResult(
          bpm: result.bpm, confidence: prevConfidence,
          candidates: originalCandidates, trace: updatedTrace),
        input.participatingTags
      )
    }

    // For each valid tag, compute matching candidates.
    struct CandidateMatch {
      let candidateIdx: Int
      let tagIdx: Int
      let ratio: HarmonicRatio
    }

    var allMatches: [CandidateMatch] = []
    for tagIdx in validTagIndices {
      // Use the consensus value when unanimous; otherwise the tag's own value.
      let tagBPM = input.consensusBPM ?? input.participatingTags[tagIdx].parsedBPM
      guard tagBPM.isFinite, tagBPM > 0 else { continue }
      for (candIdx, c) in originalCandidates.enumerated() {
        if let r = matchRatio(candidateBPM: c.bpm, tagBPM: tagBPM, policy: input.policy) {
          allMatches.append(.init(candidateIdx: candIdx, tagIdx: tagIdx, ratio: r))
        }
      }
    }

    // Boost matching candidates' scores. Compute in Double, store in Float
    // (per Swift Implementation Pitfall #3 — Float * Double does not auto-widen).
    var boostedScores = originalCandidates.map { $0.score }
    let boostedIdxSet = Set(allMatches.map(\.candidateIdx))
    for idx in boostedIdxSet {
      let original = originalCandidates[idx].score
      boostedScores[idx] = Float(Double(original) * input.policy.corroborationBoost)
    }

    // Re-select the winner from the boosted pool.
    // Tiebreak: higher original score, then lower original index (DD#16 from Story 3.5).
    let winnerIdx: Int
    if originalCandidates.isEmpty {
      // Edge case: no candidates at all. Pass through with current bpm/confidence.
      let updatedTrace = trace(
        result.trace,
        TracePopulation(
          policy: input.policy,
          evidenceBeforeBoost: input.participatingTags,
          candidatesBefore: originalCandidates,
          candidatesAfter: originalCandidates,
          finalConfidence: prevConfidence))
      return (
        BPMResult(
          bpm: result.bpm, confidence: prevConfidence,
          candidates: originalCandidates, trace: updatedTrace),
        input.participatingTags
      )
    }
    var bestIdx = 0
    for i in 1..<originalCandidates.count {
      let lhs = boostedScores[bestIdx]
      let rhs = boostedScores[i]
      if rhs > lhs {
        bestIdx = i
      } else if rhs == lhs {
        let lo = originalCandidates[bestIdx].score
        let ro = originalCandidates[i].score
        if ro > lo {
          bestIdx = i
        }
        // If original scores are also tied, keep lower index (already bestIdx).
      }
    }
    winnerIdx = bestIdx
    let newWinnerBPM = originalCandidates[winnerIdx].bpm

    // Did any tag match the winner?
    let winnerMatchesByTag: [Int: HarmonicRatio] = Dictionary(
      allMatches.filter { $0.candidateIdx == winnerIdx }.map { ($0.tagIdx, $0.ratio) },
      uniquingKeysWith: { first, _ in first }
    )
    let winnerIsCorroborated = !winnerMatchesByTag.isEmpty
    let useConsensus = input.consensusBPM != nil

    // Compute new confidence and the effective multiplier.
    let newConfidence: Double
    let effectiveBoost: Double
    if winnerIsCorroborated {
      // AC #11: boost confidence, clamped at maxBoostedConfidence.
      if prevConfidence.isFinite, prevConfidence > 0 {
        let raw = prevConfidence * input.policy.corroborationBoost
        newConfidence = min(input.policy.maxBoostedConfidence, raw)
        effectiveBoost = newConfidence / prevConfidence
      } else {
        newConfidence = prevConfidence
        effectiveBoost = 1.0
      }
    } else if useConsensus, allMatches.isEmpty {
      // AC #14: unanimous-consensus does not corroborate any candidate → penalty.
      if prevConfidence.isFinite, prevConfidence > 0 {
        newConfidence = prevConfidence * input.policy.skepticismPenalty
        effectiveBoost = input.policy.skepticismPenalty
      } else {
        newConfidence = prevConfidence
        effectiveBoost = 1.0
      }
    } else {
      // AC #15 (single uncorroborated) OR matches existed but the winner
      // was outvoted by an unboosted candidate. No confidence change.
      newConfidence = prevConfidence
      effectiveBoost = 1.0
    }

    // Build the new candidate list with boosted scores carried through.
    let newCandidates: [(bpm: Double, score: Float)] = originalCandidates.enumerated().map {
      idx, c in
      (bpm: c.bpm, score: boostedScores[idx])
    }

    // Build evidence entries.
    var evidence: [MetadataBPMEvidence] = []
    evidence.reserveCapacity(input.participatingTags.count)
    for (tagIdx, originalEvidence) in input.participatingTags.enumerated() {
      if originalEvidence.rejectionReason != nil {
        // Parse-phase rejection passes through unchanged.
        evidence.append(originalEvidence)
        continue
      }
      if let ratio = winnerMatchesByTag[tagIdx] {
        // Corroborated: tag matched the (post-promotion) winner.
        evidence.append(
          MetadataBPMEvidence(
            source: originalEvidence.source,
            rawValue: originalEvidence.rawValue,
            parsedBPM: originalEvidence.parsedBPM,
            corroboratedWith: newWinnerBPM,
            ratioMatched: ratio == .one ? nil : ratio,
            boostApplied: effectiveBoost,
            rejectionReason: nil))
      } else if useConsensus, allMatches.isEmpty {
        // AC #14 path: unanimous-disagrees applies penalty to ALL participating tags.
        evidence.append(
          MetadataBPMEvidence(
            source: originalEvidence.source,
            rawValue: originalEvidence.rawValue,
            parsedBPM: originalEvidence.parsedBPM,
            corroboratedWith: nil,
            ratioMatched: nil,
            boostApplied: effectiveBoost,
            rejectionReason: "dsp-disagreement"))
      } else {
        // AC #15 (single-tag uncorroborated) OR matches-non-empty-but-winner-outvoted.
        evidence.append(
          MetadataBPMEvidence(
            source: originalEvidence.source,
            rawValue: originalEvidence.rawValue,
            parsedBPM: originalEvidence.parsedBPM,
            corroboratedWith: nil,
            ratioMatched: nil,
            boostApplied: 1.0,
            rejectionReason: "uncorroborated-single-tag"))
      }
    }

    let updatedTrace = trace(
      result.trace,
      TracePopulation(
        policy: input.policy,
        evidenceBeforeBoost: input.participatingTags,
        candidatesBefore: originalCandidates,
        candidatesAfter: newCandidates,
        finalConfidence: newConfidence))

    return (
      BPMResult(
        bpm: newWinnerBPM, confidence: newConfidence,
        candidates: newCandidates, trace: updatedTrace),
      evidence
    )
  }

  // MARK: - Story 6.3: Stage 2 signal participation ownership

  /// Produces the file-metadata ``SignalParticipationTraceEntry`` values for the
  /// Stage-2 ``UnifiedSignalPool``, one entry per accepted tag (or a single
  /// `.absent` entry when the policy reads no source / no usable tag survived
  /// parse).
  ///
  /// Per Story 6.3 DD #3(b) this is a function relocation, NOT a transfer of
  /// corroboration authority: ``apply(to:input:)`` still owns the boost /
  /// re-select math and reads ``BPMResult/candidates`` directly. This helper
  /// only moves ownership of the metadata pool-entry production out of the
  /// service-side pool builder — the trace-shaped side-evidence it emits is not
  /// yet consumed by the corroborator. The authority transfer lands Story 6.4
  /// (KDD-A6 Stage 3) when the pool becomes the authoritative candidate-score
  /// carrier. The logic here is a verbatim lift of the former
  /// `AudioAnalysisService.buildStage1SignalPool` file-metadata branch.
  static func signalParticipationEntries(
    for input: MetadataCorroborationInput, weight: Double
  ) -> [SignalParticipationTraceEntry] {
    var entries: [SignalParticipationTraceEntry] = []

    // File metadata: emit one entry per non-rejected participating tag when
    // policy enables I/O; single `.absent` entry otherwise (DD #6).
    if input.policy.enabledSources.isEmpty {
      let participation = SignalParticipation.absent
      entries.append(
        SignalParticipationTraceEntry(
          source: .fileMetadata,
          participation: participation,
          weight: weight,
          contribution: participation.confidence * weight))
    } else {
      let acceptedTags = input.participatingTags.filter {
        $0.rejectionReason == nil
      }
      if acceptedTags.isEmpty {
        // Policy enabled but no usable tag survived parse. Record absent so
        // the per-source contract still holds.
        let participation = SignalParticipation.absent
        entries.append(
          SignalParticipationTraceEntry(
            source: .fileMetadata,
            participation: participation,
            weight: weight,
            contribution: participation.confidence * weight))
      } else {
        for tag in acceptedTags {
          let signal = WeightedSignal(
            bpm: tag.parsedBPM,
            confidence: WeightedSignal.fileMetadataStage1TraceOnlyDefault,
            source: .fileMetadata)
          let participation = SignalParticipation.present(signal)
          entries.append(
            SignalParticipationTraceEntry(
              source: .fileMetadata,
              participation: participation,
              weight: weight,
              contribution: participation.confidence * weight))
        }
      }
    }

    return entries
  }

  // MARK: - Internals

  /// Determines the harmonic ratio at which `tagBPM` corroborates `candidateBPM`,
  /// honoring the policy's tolerance and ratio gates.
  ///
  /// Returns `nil` when no allowed match exists.
  ///
  /// - Note: The 5-case ``HarmonicRatio`` does not have a dedicated 3:1 enum
  ///   entry. The 3:1 ratio window (2.85-3.15) is mapped to ``HarmonicRatio/threeHalf``
  ///   (tag faster than candidate) or ``HarmonicRatio/twoThird`` (candidate
  ///   faster than tag) — both are triplet-family ratios and the trace already
  ///   carries enough numeric detail for consumers that need to disambiguate.
  static func matchRatio(
    candidateBPM: Double, tagBPM: Double, policy: MetadataPolicy
  ) -> HarmonicRatio? {
    guard candidateBPM.isFinite, candidateBPM > 0 else { return nil }
    guard tagBPM.isFinite, tagBPM > 0 else { return nil }

    // Same-tempo (always allowed).
    let absDelta = abs(candidateBPM - tagBPM)
    if absDelta / tagBPM <= policy.corroborationTolerance {
      return .one
    }

    // Octave (gated, default on).
    if policy.allowOctaveCorroboration {
      let r = max(candidateBPM, tagBPM) / min(candidateBPM, tagBPM)
      if r >= 1.92, r <= 2.08 {
        return candidateBPM > tagBPM ? .double : .half
      }
    }

    // Triplet (gated, default off).
    if policy.allowTripletCorroboration {
      let r = max(candidateBPM, tagBPM) / min(candidateBPM, tagBPM)
      if (r >= 1.45 && r <= 1.55) || (r >= 2.85 && r <= 3.15) {
        // tag faster (tagBPM > candidateBPM) → .threeHalf;
        // tag slower → .twoThird.
        return tagBPM > candidateBPM ? .threeHalf : .twoThird
      }
    }

    return nil
  }

  /// Builds the corroborator's view of the diagnostic trace, propagating
  /// metadata-related fields when tracing is enabled. Returns `nil` when
  /// `existing` is `nil` (tracing was off — Story 3.6 keeps the
  /// "trace == nil ↔ enableTrace == false" invariant).
  private struct TracePopulation {
    let policy: MetadataPolicy
    let evidenceBeforeBoost: [MetadataBPMEvidence]
    let candidatesBefore: [(bpm: Double, score: Float)]
    let candidatesAfter: [(bpm: Double, score: Float)]
    let finalConfidence: Double
  }

  private static func trace(
    _ existing: BPMDiagnosticTrace?, _ pop: TracePopulation
  ) -> BPMDiagnosticTrace? {
    guard var t = existing else { return nil }
    t.metadataEvidenceBeforeBoost = pop.evidenceBeforeBoost
    t.candidatesBeforeBoost = pop.candidatesBefore
    t.candidatesAfterBoost = pop.candidatesAfter
    t.metadataPolicyUsed = pop.policy
    t.confidence = pop.finalConfidence
    return t
  }
}
