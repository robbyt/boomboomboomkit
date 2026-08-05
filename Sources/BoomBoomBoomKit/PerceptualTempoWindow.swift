//
//  PerceptualTempoWindow.swift
//  BoomBoomBoomKit
//
//  Consumer-specifiable octave-NORMALIZATION window for the BPM pipeline
//  (Story 12.1, FR-53).
//

import Foundation

/// The octave into which every reported tempo is folded.
///
/// This is the **perceptual** pair — the second of the two tempo bounds Story 12.1
/// made consumer-specifiable (FR-53), and the one a genre-constrained consumer
/// usually wants. Where ``TempoScanRange`` decides which periodicities are *found*,
/// this window decides which octave of a found periodicity is *reported*: a value is
/// repeatedly doubled while it sits below ``minBPM`` and halved while it sits above
/// ``maxBPM``.
///
/// A drum-and-bass application that never wants to see 70 for a 140 BPM track sets
/// this window (for example `100...200`) rather than the scan range.
///
/// ## Pipeline steps that consume this pair
///
/// Step 9 (range normalization, applied to every extracted candidate), step 9.7
/// (the duration-derived bar-count hint, which only proposes BPMs inside this
/// window), and step 10b (sub-band peak confirmation, which re-folds a promoted
/// hi-hat tempo). It is also the octave-fold authority for the **ensemble** seam:
/// `AudioAnalysisService` folds a winning `MLEvaluation.bpm` through the same
/// window under ``EnsemblePolicy/mlOnly``, ``EnsemblePolicy/highestConfidence``, and
/// the weighted policies, so moving this window moves ML-influenced output too.
///
/// ## Normalization (never throws)
///
/// Values are normalized at construction, following the
/// ``AudioAnalysisService/Options/votingThreshold`` precedent — invalid input is
/// silently corrected, never rejected:
///
/// 1. A non-finite bound (NaN, ±infinity) falls back to its default
///    (``defaultMinBPM`` / ``defaultMaxBPM``).
/// 2. ``minBPM`` clamps into `30...150` — the envelope floor, and a ceiling of half
///    the envelope ceiling so a full octave always fits above it.
/// 3. ``maxBPM`` clamps into `(2 * minBPM)...300`.
///
/// > Important: Rule 2 means a requested reporting floor above 150 is **lowered**,
/// > not honoured: `PerceptualTempoWindow(minBPM: 160, maxBPM: 300)` yields
/// > `150...300`. This is asymmetric with ``TempoScanRange``, whose minimum is
/// > honoured all the way to 297, and it is a consequence of the one-octave invariant
/// > below: a floor above 150 leaves less than an octave under the 300 BPM envelope
/// > ceiling, so either the floor moves down or the ceiling moves past the envelope.
/// > The floor moves. If you need reported tempi above 150 only, constrain
/// > ``TempoScanRange`` as well — the window alone cannot express it.
///
/// ## Why the one-octave invariant is enforced here
///
/// The fold is two *sequential* loops — double up to the floor, then halve down to
/// the ceiling — with no re-check between them. A window narrower than one octave
/// makes the second loop undo the first and return a value below the stated minimum:
/// with `100...150`, an input of 160 would return 80. That is not a hang, it is a
/// silent contract violation, so `maxBPM >= 2 * minBPM` is made unreachable at
/// construction rather than defended against downstream.
///
/// ## The window is not a hard output clamp
///
/// Step 10c (fine-grid tempogram refinement, active whenever
/// ``DSPTechnique/fineGridRefinement`` is in the technique set — it is in every
/// shipped preset) runs AFTER the fold and re-fits the winner against a continuous
/// grid bounded by the ``TempoScanRange``, not by this window. A winner sitting on a
/// window edge can therefore be reported outside it, in either direction.
///
/// The structural bound on that excursion is the refinement scan half-width: step 10c
/// searches `winner ± 4.0` BPM (clipped to the scan range), so nothing narrower than
/// 4 BPM can be claimed as a guarantee. In practice the excursion is far smaller,
/// because the refit only moves the winner when the fused peak genuinely sits off the
/// integer grid. Measured over the bundled fixtures across twelve windows
/// (2026-08-02), the largest excursion was **0.304 BPM** — a 120 BPM click reported as
/// 60.304 against a `30...60` window. Two other cases: 120.00008 against `60...120`,
/// and 84.861 against `85...170` (below the floor, so the excursion goes both ways).
/// All are well inside the project's 2% accuracy tolerance.
///
/// This is pre-existing pipeline behaviour (the same is true of the `60...200`
/// default), left as-is deliberately — clamping the refined value would change DSP
/// output on the default path, which Story 12.1 is explicitly not permitted to do.
///
/// > Note: This pair and ``TempoScanRange`` are normalized independently and are NOT
/// > cross-constrained, so moving THIS window alone can make individual tracks return
/// > `nil`. Folding pushes a tempo toward this window; the scan range's final guard
/// > then rejects anything outside `TempoScanRange.minBPM...maxBPM`. With the default
/// > `40...250` scan range and a `30...60` window, `Submerged_Lament` folds to roughly
/// > 35 and is rejected, while its neighbours in the same corpus still return values
/// > (measured 2026-08-02). Widen ``TempoScanRange`` alongside this window whenever
/// > the window reaches outside `40...250`. Cross-clamping the two automatically would
/// > silently rewrite one of the consumer's two stated intentions, so the library
/// > leaves the pairs orthogonal and documents the interaction instead.
public struct PerceptualTempoWindow: Sendable, Hashable {

  /// Slowest reportable tempo. Always finite, always in `30...150`.
  ///
  /// A request above 150 is lowered to 150 rather than honoured; see rule 2 of the
  /// type's Normalization section for why.
  public let minBPM: Double

  /// Fastest reportable tempo. Always finite, always in `(2 * minBPM)...300`.
  public let maxBPM: Double

  /// The shipped default lower bound (60 BPM).
  public static let defaultMinBPM: Double = 60

  /// The shipped default upper bound (200 BPM).
  public static let defaultMaxBPM: Double = 200

  /// The shipped default window, `60...200` — the values that were
  /// `private static let perceptualMinBPM` / `perceptualMaxBPM` on the analyzer
  /// before Story 12.1. Output at this value is byte-identical to the pre-story
  /// pipeline.
  public static let `default` = PerceptualTempoWindow(
    minBPM: defaultMinBPM, maxBPM: defaultMaxBPM)

  /// Creates a normalized perceptual window. Any input produces a window at least
  /// one octave wide; see the type's Normalization section for the exact rules.
  ///
  /// - Parameters:
  ///   - minBPM: Requested slowest reportable tempo. Lowered to 150 when the request
  ///     exceeds it, so that a full octave still fits below the 300 BPM envelope
  ///     ceiling.
  ///   - maxBPM: Requested fastest reportable tempo. Raised to `2 * minBPM` when the
  ///     request would make the window narrower than one octave.
  public init(minBPM: Double, maxBPM: Double) {
    // isFinite FIRST: every comparison against NaN is false, so a NaN would survive
    // clamping unchanged and then make the fold loops non-terminating.
    let requestedMin = minBPM.isFinite ? minBPM : Self.defaultMinBPM
    let requestedMax = maxBPM.isFinite ? maxBPM : Self.defaultMaxBPM

    let low = Swift.min(
      Swift.max(requestedMin, TempoRangeEnvelope.lowerBound),
      TempoRangeEnvelope.upperBound / 2.0)
    self.minBPM = low
    self.maxBPM = Swift.min(
      Swift.max(requestedMax, low * 2.0), TempoRangeEnvelope.upperBound)
  }
}
