//
//  TempoScanRange.swift
//  BoomBoomBoomKit
//
//  Consumer-specifiable candidate SCAN range for the BPM pipeline (Story 12.1, FR-53).
//

import Foundation

// MARK: - Shared envelope

/// The absolute envelope both consumer-specifiable tempo pairs are normalized into.
///
/// Internal and shared by ``TempoScanRange`` and ``PerceptualTempoWindow`` so the two
/// cannot drift apart. `30...300` brackets the library's regression corpora with
/// headroom on both sides — OA300 ground truth spans 79.99 to 172.99 BPM, and
/// GiantSteps spans 64 to 197 with its secondary `tempo2` annotations reaching 208
/// (measured 2026-08-02) — while keeping every `Int(bpm)` conversion inside the DSP
/// spine far from overflow and every `60 * onsetRate / bpm` lag finite and positive.
enum TempoRangeEnvelope {
  /// Absolute floor for any consumer-supplied bound.
  static let lowerBound: Double = 30.0

  /// Absolute ceiling for any consumer-supplied bound.
  static let upperBound: Double = 300.0
}

// MARK: - TempoScanRange

/// Bounds which tempi the DSP candidate search generates at all.
///
/// This is the **scan** pair — one of the two tempo bounds Story 12.1 made
/// consumer-specifiable (FR-53). It is distinct from ``PerceptualTempoWindow``, and
/// the distinction is load-bearing:
///
/// - `TempoScanRange` bounds candidate *generation*. It sizes the autocorrelation /
///   Fourier-tempogram search grid, so a tempo outside it is never even considered.
///   Widen it to detect very slow (ambient, downtempo) or very fast (hardcore,
///   speedcore) material.
/// - ``PerceptualTempoWindow`` bounds octave *normalization*. It decides which octave
///   of an already-found periodicity gets reported.
///
/// A drum-and-bass consumer asking "stop reporting 70 for my 140 BPM tracks" is asking
/// about the perceptual window, not this type.
///
/// ## Pipeline steps that consume this pair
///
/// Steps 5 (Fourier tempogram), 6 (periodicity fusion), 7 (TPS2 harmonic enhancement),
/// 8 (multi-peak extraction), 10 (octave disambiguation index mapping), 10c (fine-grid
/// refinement), and 12 (confidence) are all indexed off the integer grid derived from
/// this range; the final range guard after step 10c rejects a winner outside
/// `minBPM...maxBPM`.
///
/// ## Fractional bounds are honoured, not truncated
///
/// The candidate grid is integer-valued, so a fractional bound has to become an
/// integer somewhere. It is rounded **inward** — `minBPM.rounded(.up)` and
/// `maxBPM.rounded(.down)` — so every generated candidate satisfies the range the
/// consumer stated. Truncating both bounds instead would put grid slots *below*
/// `minBPM`, and the final `Double` range guard would then reject the winner those
/// slots produced: a `120.5...240` range over a 120 BPM track returned `nil` while
/// `121...240` returned 121 (measured 2026-08-02).
///
/// The default `40...250` is integral, so inward rounding is a no-op there and
/// default-path output is unchanged.
///
/// ## Normalization (never throws)
///
/// Values are normalized at construction, following the ``AudioAnalysisService/Options/votingThreshold``
/// precedent — invalid input is silently corrected, never rejected:
///
/// 1. A non-finite bound (NaN, ±infinity) falls back to its default
///    (``defaultMinBPM`` / ``defaultMaxBPM``).
/// 2. ``minBPM`` clamps into `30...297` — the envelope floor, and a ceiling that
///    leaves room for the minimum span below the envelope ceiling.
/// 3. ``maxBPM`` clamps into `(minBPM + 3)...300`, which subsumes the `min < max`
///    requirement: an inverted or degenerate range widens rather than failing.
///
/// The three-BPM minimum span (``minimumSpanBPM``) is a hard structural requirement,
/// not a taste call. Inward rounding can consume up to one BPM at each end, so a
/// three-BPM span is the narrowest that still guarantees three integer grid slots —
/// what the step-8 local-maximum scan needs, since it reads `[i - 1]` and `[i + 1]`.
///
/// > Note: This pair and ``PerceptualTempoWindow`` are normalized independently and
/// > are NOT cross-constrained. Supplying a scan range that cannot contain any
/// > perceptual-window output (for example scanning `30...90` while normalizing into
/// > `100...200`) makes the final range guard reject every winner and
/// > ``AudioAnalysisService/analyzeBPM(url:options:)`` returns `nil`. Cross-clamping
/// > the two would silently rewrite one of the consumer's two stated intentions, so
/// > the library leaves the pairs orthogonal and documents the interaction instead.
public struct TempoScanRange: Sendable, Hashable {

  /// Slowest tempo the candidate search generates. Always finite, always in `30...297`.
  public let minBPM: Double

  /// Fastest tempo the candidate search generates. Always finite, always in
  /// `(minBPM + 3)...300`.
  public let maxBPM: Double

  /// The shipped default lower bound (40 BPM).
  public static let defaultMinBPM: Double = 40

  /// The shipped default upper bound (250 BPM).
  public static let defaultMaxBPM: Double = 250

  /// Smallest span the scan grid may be narrowed to, in BPM.
  ///
  /// Guarantees at least three integer grid slots after the inward rounding described
  /// in the type's "Fractional bounds" section, which the local-maximum peak scan in
  /// step 8 requires. Rounding can consume up to one BPM at each end, so the floor is
  /// three rather than two.
  public static let minimumSpanBPM: Double = 3.0

  /// The shipped default scan range, `40...250` — the values that were
  /// `private static let minBPM` / `maxBPM` on the analyzer before Story 12.1.
  /// Output at this value is byte-identical to the pre-story pipeline.
  public static let `default` = TempoScanRange(
    minBPM: defaultMinBPM, maxBPM: defaultMaxBPM)

  /// Creates a normalized scan range. Any input produces a usable range; see the
  /// type's Normalization section for the exact rules.
  ///
  /// - Parameters:
  ///   - minBPM: Requested slowest scanned tempo.
  ///   - maxBPM: Requested fastest scanned tempo.
  public init(minBPM: Double, maxBPM: Double) {
    // isFinite FIRST: a NaN would survive every subsequent `min`/`max` comparison
    // (all comparisons against NaN are false), so clamping cannot be the first step.
    let requestedMin = minBPM.isFinite ? minBPM : Self.defaultMinBPM
    let requestedMax = maxBPM.isFinite ? maxBPM : Self.defaultMaxBPM

    let low = Swift.min(
      Swift.max(requestedMin, TempoRangeEnvelope.lowerBound),
      TempoRangeEnvelope.upperBound - Self.minimumSpanBPM)
    self.minBPM = low
    self.maxBPM = Swift.min(
      Swift.max(requestedMax, low + Self.minimumSpanBPM),
      TempoRangeEnvelope.upperBound)
  }

  /// Slowest slot of the integer candidate grid: ``minBPM`` rounded **up**, so no
  /// generated candidate sits below the range the consumer stated.
  var integerLowerBound: Int { Int(minBPM.rounded(.up)) }

  /// Fastest slot of the integer candidate grid: ``maxBPM`` rounded **down**, so no
  /// generated candidate sits above the range the consumer stated.
  ///
  /// ``minimumSpanBPM`` guarantees `integerUpperBound - integerLowerBound >= 2`, i.e.
  /// at least the three grid slots the step-8 local-maximum scan reads.
  var integerUpperBound: Int { Int(maxBPM.rounded(.down)) }
}
