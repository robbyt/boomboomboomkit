//
//  PlayableBeatGrid.swift
//  BoomBoomBoomKit
//
//  The constant-tempo playable grid as a value type with pure ordinal and time
//  queries: one library implementation of
//  `originTime + (60.0 / bpm) * n` (Story 15.10).
//

// MARK: - PlayableBeatGrid

/// A constant-tempo beat grid defined by an origin time and a tempo, with pure
/// queries between beat ordinals and times.
///
/// Beat ordinal `n` sits at `originTime + (60.0 / bpm) * Double(n)`, computed per
/// ordinal and never accumulated, so beat `100_000` carries the same rounding as
/// beat `1`. Ordinal `0` is the origin; negative ordinals lie before it and their
/// times are returned as computed, including negative times. An ordinal is a
/// position on this grid. It is not ``BeatGridAnchor/beatIndex`` (an index into
/// ``BeatGrid/beats``) and not a bar number; ``beatInBar(ofBeat:beatsPerBar:)``
/// maps it into a bar when the caller supplies the meter.
///
/// Build one from a ``BeatGrid`` with ``BeatGrid/playableGrid``, or from stored
/// primitives with ``init(originTime:bpm:)`` (a consumer that persisted only the
/// origin time and tempo can rebuild the same grid). `bpm` is not range-clamped,
/// matching ``BeatGrid/estimatedTempo``.
///
/// ## Total queries
/// No query traps. A query returns `nil` when an input is not finite, when a
/// derived value (a position or a time) is not finite, or when the ordinal it
/// involves exceeds `2^53` in magnitude: past `2^53` a `Double` no longer holds
/// every integer, so the ordinal-to-time map stops being one to one. Integer
/// ordinals are checked as `Int` before any conversion to `Double`.
///
/// The type is not `Codable`: it holds no information beyond its two fields, which
/// a consumer persists in its own format.
public struct PlayableBeatGrid: Sendable, Hashable {

  /// Time of ordinal `0`, in seconds on the decoded-PCM timeline. Finite.
  public let originTime: Double

  /// Tempo in beats per minute. Finite and positive, with a finite positive
  /// ``beatPeriod``.
  public let bpm: Double

  /// The largest ordinal magnitude a query accepts, `2^53`.
  private static let maxOrdinalMagnitude = 1 << 53

  /// Steps each bound of ``beats(in:)`` may move from its estimate.
  private static let maxBoundSteps = 8

  /// Creates a grid, or returns `nil` when `originTime` is not finite, `bpm` is
  /// not finite or not positive, or `60.0 / bpm` is not finite (a `bpm` so small
  /// that the period overflows).
  public init?(originTime: Double, bpm: Double) {
    guard originTime.isFinite, bpm.isFinite, bpm > 0 else { return nil }
    let period = 60.0 / bpm
    guard period.isFinite, period > 0 else { return nil }
    self.originTime = originTime
    self.bpm = bpm
  }

  /// Seconds per beat, `60.0 / bpm`.
  public var beatPeriod: Double { 60.0 / bpm }

  /// Time of beat ordinal `n`: `originTime + (60.0 / bpm) * Double(n)`.
  ///
  /// Returns `nil` when `abs(n) > 2^53` (including `Int.min`) or the time is not
  /// finite. A negative result is returned as computed.
  public func time(ofBeat n: Int) -> Double? {
    guard n >= -Self.maxOrdinalMagnitude, n <= Self.maxOrdinalMagnitude else { return nil }
    let t = originTime + (60.0 / bpm) * Double(n)
    return t.isFinite ? t : nil
  }

  /// The fractional ordinal at `time`: `(time - originTime) / beatPeriod`.
  ///
  /// The inverse of ``time(ofBeat:)`` up to rounding. Returns `nil` when `time` is
  /// not finite or the position is not finite or exceeds `2^53` in magnitude.
  public func beatPosition(at time: Double) -> Double? {
    guard time.isFinite else { return nil }
    let position = (time - originTime) / beatPeriod
    guard position.isFinite, abs(position) <= Double(Self.maxOrdinalMagnitude) else {
      return nil
    }
    return position
  }

  /// The ordinal whose computed time is nearest `time`.
  ///
  /// Starts at the ordinal below `time`'s position and moves to a neighbour while
  /// the neighbour's computed time is strictly nearer, or equally near and lower;
  /// on an exactly equal distance it therefore returns the lower ordinal (the
  /// earlier beat), the same rule ``BeatGrid/repositioningAnchor(to:mode:)``
  /// applies to detected beats. The comparison is on computed times, not on the
  /// position, so a time whose position rounds to exactly `k + 0.5` still resolves
  /// to the beat whose computed time is nearer, and a large ``originTime`` that
  /// collapses several ordinals onto one representable time resolves to the lowest
  /// of them. A neighbour outside the `2^53` ordinal domain, or whose time is not
  /// finite, is never nearer. The walk takes at most 8 steps; if it has not
  /// settled the query returns `nil`. Also returns `nil` under the
  /// ``beatPosition(at:)`` rules, and whenever the chosen ordinal's time is not
  /// defined.
  public func nearestBeat(to time: Double) -> Int? {
    guard let position = beatPosition(at: time) else { return nil }
    func distance(_ ordinal: Int) -> Double? {
      self.time(ofBeat: ordinal).map { abs($0 - time) }
    }
    var n = Int(position.rounded(.down))
    guard var best = distance(n) else { return nil }
    for _ in 0...Self.maxBoundSteps {
      // Up only when strictly nearer, then down when nearer or equal: distance to a
      // monotone sequence of times is unimodal, so this reaches the lowest ordinal
      // at the minimum distance without oscillating.
      if let up = distance(n + 1), up < best {
        n += 1
        best = up
        continue
      }
      if let down = distance(n - 1), down <= best {
        n -= 1
        best = down
        continue
      }
      return n
    }
    return nil
  }

  /// The ordinals whose computed times lie inside `range`, or `nil` when none do
  /// or the bounds are unresolved (see below).
  ///
  /// Membership matches ``time(ofBeat:)`` exactly: the result is
  /// `{ n : range.contains(time(ofBeat: n)!) }` as a closed range. Each bound is
  /// estimated from its position and then moved by whole ordinals until the
  /// computed times agree with it, at most 8 steps per bound. When a large
  /// ``originTime`` collapses many ordinals onto one representable time the walk
  /// may not settle within 8 steps; the query then returns `nil` rather than a
  /// guess. The work is bounded and allocation-free regardless of the range width.
  ///
  /// Returns `nil` when either bound is not finite or its position exceeds `2^53`
  /// in magnitude.
  public func beats(in range: ClosedRange<Double>) -> ClosedRange<Int>? {
    guard let lowerPosition = beatPosition(at: range.lowerBound),
      let upperPosition = beatPosition(at: range.upperBound)
    else { return nil }
    guard
      let first = firstOrdinal(
        atOrAfter: range.lowerBound, from: Int(lowerPosition.rounded(.up))),
      let last = lastOrdinal(
        atOrBefore: range.upperBound, from: Int(upperPosition.rounded(.down)))
    else { return nil }
    return first <= last ? first...last : nil
  }

  /// The position of ordinal `n` within its bar, counting the origin as beat `0`
  /// of a bar: `((n % beatsPerBar) + beatsPerBar) % beatsPerBar`, which is `0` for
  /// the origin and every `beatsPerBar`-th ordinal from it in either direction.
  ///
  /// The caller supplies the meter (for example
  /// ``MeterEstimate/beatsPerBar`` when ``BeatGrid/hasTrustedBarOrigin`` holds).
  /// Returns `nil` when `beatsPerBar < 1` or `abs(n) > 2^53`.
  public func beatInBar(ofBeat n: Int, beatsPerBar: Int) -> Int? {
    guard beatsPerBar >= 1 else { return nil }
    guard n >= -Self.maxOrdinalMagnitude, n <= Self.maxOrdinalMagnitude else { return nil }
    let remainder = n % beatsPerBar
    return remainder < 0 ? remainder + beatsPerBar : remainder
  }

  // MARK: Bound settling

  /// The least ordinal whose time is `>= bound`, walked from `estimate` by at most
  /// ``maxBoundSteps`` steps; `nil` if unsettled or `n`'s own time is undefined.
  /// Times are monotone in the ordinal, so the walk only ever moves one way. A
  /// neighbour outside the ordinal domain (or with no finite time) is not a member,
  /// so the in-domain ordinal settles.
  private func firstOrdinal(atOrAfter bound: Double, from estimate: Int) -> Int? {
    var n = estimate
    for _ in 0...Self.maxBoundSteps {
      guard let t = time(ofBeat: n) else { return nil }
      if t < bound {
        n += 1
        continue
      }
      if let previous = time(ofBeat: n - 1), previous >= bound {
        n -= 1
        continue
      }
      return n
    }
    return nil
  }

  /// The greatest ordinal whose time is `<= bound`, walked from `estimate` by at
  /// most ``maxBoundSteps`` steps; `nil` if unsettled or `n`'s own time is
  /// undefined. A neighbour outside the ordinal domain is not a member.
  private func lastOrdinal(atOrBefore bound: Double, from estimate: Int) -> Int? {
    var n = estimate
    for _ in 0...Self.maxBoundSteps {
      guard let t = time(ofBeat: n) else { return nil }
      if t > bound {
        n -= 1
        continue
      }
      if let next = time(ofBeat: n + 1), next <= bound {
        n += 1
        continue
      }
      return n
    }
    return nil
  }
}
