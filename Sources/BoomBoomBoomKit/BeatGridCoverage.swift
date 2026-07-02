//
//  BeatGridCoverage.swift
//  BoomBoomBoomKit
//
//  How much of a track the beat grid's *detected* `beats` array spans
//  (Story 8.5, FR-29). Carried on `Options.beatGridCoverage` and recorded on
//  the result as `BeatGrid.coverage`.
//

// MARK: - BeatGridCoverage

/// How much of a track a ``BeatGrid``'s detected ``BeatGrid/beats`` array spans
/// (Story 8.5, FR-29).
///
/// This controls only the *detected-beat* coverage. The Rekordbox-style
/// mid-track contract — ``BeatGrid/gridOrigin`` (an anchor) plus
/// ``BeatGrid/estimatedTempo`` — extrapolates the infinite grid drift-free on
/// constant-tempo material regardless of this setting, so the cheap default is
/// almost always what a beat-math consumer wants.
///
/// - ``analysisWindow`` (**default**): `beats` cover exactly the BPM analysis
///   window the pipeline already computed — **zero extra onset cost** (reuses
///   the in-scope envelope; the Story-8.4 path).
/// - ``window(seconds:)``: an explicit N-second span from the analysis start.
///   Triggers a second onset pass over that span.
/// - ``fullTrack``: every detected beat to the (decoded) file end. Triggers a
///   full-track onset pass — O(track). Bounded by ``Options/maxSeconds`` like
///   every other decode in the library.
///
/// ## Sanitization (the NaN-free→`Hashable` doctrine, enum form)
/// ``window(seconds:)`` carries a `Double`, which `BeatGrid`'s `Hashable`
/// conformance would otherwise make unsound (a `NaN` second-count breaks
/// reflexivity). Rather than drop `Hashable` (the `MLExecutionPolicy`
/// precedent — not an option here because ``BeatGrid`` is `Hashable` and holds
/// a `coverage`), the documented rule **"non-finite / `≤ 0` / absurd
/// (`≥ 1e9 s`) window → ``analysisWindow``"** is folded directly into equality
/// and hashing via ``sanitized``. A hostile `.window(.nan)` is therefore never a
/// distinct, unsound value — it *is* ``analysisWindow`` by the type's own
/// equality. ``BeatGrid`` records the ``sanitized`` form, so a result never
/// reports a degenerate coverage.
public enum BeatGridCoverage: Sendable, Codable, CustomStringConvertible {

  /// `beats` cover the BPM analysis window (default; zero extra onset cost).
  case analysisWindow

  /// `beats` cover an explicit N-second span. Non-finite, non-positive, or
  /// absurd (`≥ 1e9 s`) values are equivalent to ``analysisWindow`` (see
  /// ``sanitized``).
  case window(seconds: Double)

  /// `beats` cover every detected beat to the decoded file end (O(track)).
  case fullTrack

  /// Upper bound above which a `.window` second-count is treated as absurd and
  /// folds to ``analysisWindow`` — mirrors the `Options.maxSeconds` absurd-cap
  /// rule so the two sanitizers agree.
  private static let absurdWindowSeconds: Double = 1.0e9

  /// The documented sanitization: a ``window(seconds:)`` whose second-count is
  /// non-finite, `≤ 0`, or `≥ 1e9` collapses to ``analysisWindow``. The other
  /// two cases pass through unchanged. This is the single source of truth for
  /// "what does this coverage mean", consulted by the service when it routes
  /// coverage and by `==` / `hash(into:)` so the type is NaN-free in effect.
  public var sanitized: BeatGridCoverage {
    switch self {
    case .analysisWindow, .fullTrack:
      return self
    case .window(let seconds):
      guard seconds.isFinite, seconds > 0, seconds < Self.absurdWindowSeconds else {
        return .analysisWindow
      }
      return self
    }
  }

  // MARK: CustomStringConvertible

  /// One-line summary of the **sanitized** coverage (so a degenerate window
  /// renders as `analysisWindow`, matching its semantics).
  public var description: String {
    switch sanitized {
    case .analysisWindow:
      return "analysisWindow"
    case .window(let seconds):
      return "window(\(seconds)s)"
    case .fullTrack:
      return "fullTrack"
    }
  }

  // MARK: - Codable (custom: round-trips the `sanitized` form, NaN-free)

  /// Top-level keys = the case names. `encode` always emits the SE-0295 single-key wire
  /// shape (`{"window":{"seconds":45.5}}`, `{"analysisWindow":{}}`, `{"fullTrack":{}}`).
  /// `decode` is intentionally lenient (priority-ordered, mirroring ``DownbeatResult``): a
  /// malformed multi-key payload resolves to the first recognized case, and only a
  /// no-recognized-key payload throws — the house "decode untrusted persistence into safe
  /// values, do not throw on hostile input" doctrine.
  private enum CodingKeys: String, CodingKey {
    case analysisWindow, window, fullTrack
  }

  /// Nested key for the ``window(seconds:)`` payload — the single labeled `seconds`
  /// key (never a positional `_0`); also the (empty) nested-container key type for
  /// the no-payload cases.
  private enum WindowCodingKeys: String, CodingKey {
    case seconds
  }

  /// Decodes the coverage, **storing the ``sanitized`` form** so a degenerate decoded
  /// `.window` (non-finite, `≤ 0`, or `≥ 1e9`) becomes ``analysisWindow`` rather than
  /// persisting an unsound value. Synthesized `Codable` would faithfully reconstruct a
  /// `.window(.nan)`; this closes that decode hole (the house faithful-but-safe
  /// doctrine — untrusted persistence decodes into safe values). An **unreadable**
  /// `.window` payload (missing / `null` / wrong-type `seconds`, or a non-object value)
  /// also folds to ``analysisWindow`` rather than throwing. Only a payload with no
  /// recognized case key (or a non-object top-level value) throws — a schema-boundary
  /// signal that the cache is not a `BeatGridCoverage` at all.
  ///
  /// - Note: This hardens *decode/encode* only. A `.window(.nan)` remains directly
  ///   constructible in-memory, but its `==` / `hash(into:)` / ``description`` already
  ///   canonicalize it to ``analysisWindow``, and persistence can no longer surface it.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let raw: BeatGridCoverage
    if container.contains(.window) {
      // A recognized `.window` whose seconds is unreadable (missing / null / wrong-type /
      // non-object payload) folds to `.analysisWindow` (via `sanitized` below); never throws.
      let seconds =
        (try? container.nestedContainer(keyedBy: WindowCodingKeys.self, forKey: .window))
        .flatMap { try? $0.decode(Double.self, forKey: .seconds) }
      raw = seconds.map { .window(seconds: $0) } ?? .analysisWindow
    } else if container.contains(.fullTrack) {
      raw = .fullTrack
    } else if container.contains(.analysisWindow) {
      raw = .analysisWindow
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription:
            "BeatGridCoverage: no recognized case key (expected analysisWindow / window / fullTrack)"
        ))
    }
    self = raw.sanitized
  }

  /// Encodes the **sanitized** SE-0295 single-key wire shape — a degenerate window is
  /// never persisted (it serializes as `{"analysisWindow":{}}`).
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch sanitized {
    case .analysisWindow:
      _ = container.nestedContainer(keyedBy: WindowCodingKeys.self, forKey: .analysisWindow)
    case .fullTrack:
      _ = container.nestedContainer(keyedBy: WindowCodingKeys.self, forKey: .fullTrack)
    case .window(let seconds):
      var nested = container.nestedContainer(keyedBy: WindowCodingKeys.self, forKey: .window)
      try nested.encode(seconds, forKey: .seconds)
    }
  }
}

// MARK: - Hashable (NaN-free via `sanitized`)

extension BeatGridCoverage: Hashable {

  /// Equality over the **sanitized** form, so `.window(.nan)` (and any other
  /// degenerate window) equals ``analysisWindow``, never itself-only. The
  /// surviving `.window` second-counts are finite by construction here, so the
  /// `bitPattern` comparison is reflexive (it canonicalizes `±0.0`, but a
  /// sanitized window is always strictly positive anyway).
  public static func == (lhs: BeatGridCoverage, rhs: BeatGridCoverage) -> Bool {
    switch (lhs.sanitized, rhs.sanitized) {
    case (.analysisWindow, .analysisWindow), (.fullTrack, .fullTrack):
      return true
    case (.window(let a), .window(let b)):
      return a.bitPattern == b.bitPattern
    default:
      return false
    }
  }

  public func hash(into hasher: inout Hasher) {
    switch sanitized {
    case .analysisWindow:
      hasher.combine(0)
    case .fullTrack:
      hasher.combine(1)
    case .window(let seconds):
      hasher.combine(2)
      hasher.combine(seconds.bitPattern)
    }
  }
}
