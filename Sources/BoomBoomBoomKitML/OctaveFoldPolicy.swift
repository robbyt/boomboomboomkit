//
//  OctaveFoldPolicy.swift
//  BoomBoomBoomKit
//
//  Decode-time octave-fold policy for BNNSTechnique (GH-141).
//

import Foundation

/// Controls whether ``BNNSTechnique`` reconsiders the tempo octave when
/// decoding the model's 256-bin posterior.
///
/// ## Why this exists
///
/// The decode is `bpm = 30 + argmax`. A tempo classifier trained on a
/// fast-music corpus learns "when in doubt, fast", so a 70 BPM track is
/// frequently decoded as 140: the pulse is found, the perceptual octave is
/// wrong. The E0 diagnostic (2026-06-09) measured this on GiantSteps — of
/// the 60 tracks below 100 BPM, **38 decoded to exactly twice the annotated
/// tempo**, and every other tempo band recorded **zero** such errors.
///
/// ## Direction
///
/// Folding is **downward only**, because that is the only direction the
/// diagnostic evidences. No band showed the model decoding half the true
/// tempo, so a symmetric rule would introduce a failure mode with no
/// measurement behind it.
///
/// ## Not `Hashable`
///
/// ``massRatio(threshold:)`` carries an unvalidated `Double`. Validation
/// happens in `BNNSTechnique.init`, so a `.nan` threshold is representable
/// in a policy value that has not yet been handed to a technique, and a NaN
/// payload breaks the `Hashable` invariant. Same reasoning as
/// `MLExecutionPolicy` and `EnsembleDecision`.
@available(macOS 15.0, *)
public enum OctaveFoldPolicy: Sendable, Equatable {

  /// Decode the bare argmax. This is the default and reproduces the
  /// pre-GH-141 output bit for bit.
  case disabled

  /// Decode the fundamental when the posterior mass at half the argmax
  /// tempo reaches `threshold` times the argmax bin's own mass.
  ///
  /// ## Measured result: this did not work on the reference model
  ///
  /// Do not enable this expecting an accuracy gain without measuring your
  /// own model first. Against `giantsteps_v2_seed_42` over all 661
  /// GiantSteps tracks, **every threshold from 0.0 to 1.0 was net negative
  /// on Acc1** (`141-octave-fold-impact.json`). At threshold 0.0 the
  /// sub-100 BPM band recovered exactly the 38 tracks E0 predicted, but at
  /// a cost of 346 harmful folds elsewhere, for a net of −308.
  ///
  /// The reason is that the ratio does not discriminate. Folds that helped
  /// had a median ratio of 0.199; folds that hurt had a median of 0.192,
  /// and 336 of the 346 harmful folds sat above the smallest helpful one.
  /// No threshold separates the two populations. The fundamental is not
  /// starved of mass — it typically carries about a fifth of the argmax's,
  /// median ratio 0.199 where folding helps. The problem is that it carries
  /// the same fifth where folding hurts, median 0.192. The quantity simply
  /// does not correlate with whether the fold is right.
  ///
  /// Scope of that claim: the experiment disproves *this scalar mass-ratio
  /// threshold*, not every posterior-derived rule. What is measured is that
  /// no threshold on this ratio separates the two populations. A richer
  /// posterior feature might; that is untested.
  ///
  /// The knob ships because it costs nothing at the default, because a
  /// differently-calibrated model may behave differently, and because
  /// `make octave-fold-impact-report` re-runs the measurement for any
  /// model. The untried directions are a richer posterior feature, or an
  /// arbiter drawing on evidence from outside the posterior entirely.
  ///
  /// An unconditional prefer-the-fundamental rule is what threshold 0.0
  /// approximates, and its −308 is the measured case against it.
  ///
  /// - Parameter threshold: Fraction in `[0, 1]`. Non-finite values throw
  ///   `MLTechniqueError.invalidThreshold` at technique construction;
  ///   finite values outside the range are clamped, because they carry
  ///   intent. `0.0` folds whenever any mass sits at the half tempo.
  case massRatio(threshold: Double)

  /// The threshold this policy consults, or `nil` when folding is off.
  public var threshold: Double? {
    switch self {
    case .disabled: return nil
    case .massRatio(let t): return t
    }
  }
}
