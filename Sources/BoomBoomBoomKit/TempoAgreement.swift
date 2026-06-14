//
//  TempoAgreement.swift
//  BoomBoomBoomKit
//
//  How the beat grid's tempo relates to the BPM stage's tempo (Story 8.5,
//  KDD-C3 / FR-31). Replaces the Story-8.3 `BeatGrid.tempoAgreedWithBPMStage:
//  Bool?`.
//

// MARK: - TempoAgreement

/// How a ``BeatGrid``'s ``BeatGrid/estimatedTempo`` relates to the tempo the
/// BPM stage resolved for the same audio (Story 8.5, KDD-C3 / FR-31).
///
/// This replaces the Story-8.3 `Bool?` agreement flag. A bare `Bool?` collapses
/// a clean **octave** error (87 vs 174 BPM — perfectly syncable by halving or
/// doubling) into the same `false` as genuine disagreement (120 vs 137 — must
/// be rejected). A DJ-style consumer doing auto-sync needs to tell those apart:
/// the octave case is recoverable, the disagreement case is not. So the four
/// states are explicit, and the octave case **carries the factor** — the
/// library's authoritative octave classification — so the consumer reconciles
/// against the octave WE decided rather than re-deriving one that could disagree
/// at the tolerance boundary (DD #12).
///
/// ## Why `Int`, not `Double`
/// ``octaveEquivalent(factor:)`` carries an `Int` (`∈ {-2, +2}`), not a `Double`
/// ratio. An `Int` is `Hashable`/`Codable`-clean: it cannot be `NaN`, so it does
/// not add a sanitization site to ``BeatGrid``'s NaN-free→`Hashable` doctrine.
/// The exact fractional ratio, if ever needed, stays computable from the two raw
/// tempos a consumer already holds (`CombinedAnalysisResult.bpm.bpm` and
/// `beatGrid.estimatedTempo`) — so nothing is lost by not storing a `Double` here.
///
/// ## 2× only
/// Only a single octave (½× / 2×) is classified as ``octaveEquivalent``. A
/// genuine 4×/0.25× relationship is ``disagree`` on purpose: a track that is
/// four octaves off should prompt the user, not silently auto-sync to a quarter
/// of the tempo.
public enum TempoAgreement: Sendable, Hashable, Codable, CustomStringConvertible {

  /// No comparison was made — the grid was produced standalone (e.g. via
  /// ``AudioAnalysisService/analyzeBeatGrid(url:options:)``) with no BPM result
  /// alongside. This is the value the Story-8.3 `nil` used to mean.
  case notCompared

  /// The grid tempo and the BPM-stage tempo match within ~2% relative
  /// tolerance (the same `isNearMatch` band the BPM selector uses).
  case agree

  /// The grid tempo is an octave (½× or 2×) of the BPM-stage tempo — still
  /// syncable by halving/doubling. `factor` is the library's authoritative
  /// direction: `+2` means the grid tempo is ≈ **2×** the BPM tempo (grid
  /// runs at the faster octave); `-2` means the grid tempo is ≈ **½×** the
  /// BPM tempo (grid runs at the slower octave). No other values are produced.
  case octaveEquivalent(factor: Int)

  /// The tempos are neither within tolerance nor a single octave apart —
  /// reject for auto-sync.
  case disagree

  // MARK: CustomStringConvertible

  /// One-line summary. Exhaustive `switch` with no `default:` so a future added
  /// case is a compile error here rather than a silent fallthrough.
  public var description: String {
    switch self {
    case .notCompared:
      return "notCompared"
    case .agree:
      return "agree"
    case .octaveEquivalent(let factor):
      return "octaveEquivalent(factor: \(factor))"
    case .disagree:
      return "disagree"
    }
  }

  // MARK: - Codable (custom: fold an out-of-range decoded factor to `.disagree`)

  /// Top-level keys = the case names. `encode` emits the SE-0295 single-key form
  /// (`{"agree":{}}`, `{"octaveEquivalent":{"factor":2}}`, …); `decode` is intentionally
  /// lenient (priority-ordered, mirroring ``DownbeatResult``) — a multi-key payload
  /// resolves to the first recognized case, and only a no-recognized-key payload throws.
  private enum CodingKeys: String, CodingKey {
    case notCompared, agree, octaveEquivalent, disagree
  }

  /// Nested key for the ``octaveEquivalent(factor:)`` payload — the single labeled
  /// `factor` key (never a positional `_0`).
  private enum OctaveCodingKeys: String, CodingKey {
    case factor
  }

  /// Decodes the agreement, **folding an out-of-range `octaveEquivalent` factor to
  /// ``disagree``**. The classifier only ever emits `factor ∈ {-2, +2}` (its single
  /// source of truth), so any other value — `{"octaveEquivalent":{"factor":4}}`, `0`,
  /// … — is a stale or tampered cache. ``disagree`` is the operationally-correct fold
  /// (an unknown octave relationship must NOT auto-sync), mirroring ``DownbeatResult``'s
  /// structurally-invalid `.detected` → `.noneDetected`. The fold also covers an
  /// **unreadable** `.octaveEquivalent` payload (missing / `null` / wrong-type `factor`,
  /// or a non-object value) — folded to ``disagree`` rather than thrown. Only a payload
  /// with no recognized case key (or a non-object top-level value) throws — a
  /// schema-boundary signal that the cache is not a `TempoAgreement` at all.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.octaveEquivalent) {
      // A recognized `.octaveEquivalent` whose factor is unreadable (missing / null /
      // wrong-type / non-object payload) OR out-of-range folds to `.disagree` (an octave
      // we can't trust must not auto-sync); it never throws.
      let factor =
        (try? container.nestedContainer(keyedBy: OctaveCodingKeys.self, forKey: .octaveEquivalent))
        .flatMap { try? $0.decode(Int.self, forKey: .factor) }
      if let factor, factor == 2 || factor == -2 {
        self = .octaveEquivalent(factor: factor)
      } else {
        self = .disagree
      }
    } else if container.contains(.agree) {
      self = .agree
    } else if container.contains(.disagree) {
      self = .disagree
    } else if container.contains(.notCompared) {
      self = .notCompared
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription:
            "TempoAgreement: no recognized case key "
            + "(expected notCompared / agree / octaveEquivalent / disagree)"
        ))
    }
  }

  /// Encodes the SE-0295 single-key wire shape with the labeled `factor:` payload
  /// (never a positional `_0`). The classifier only emits `factor ∈ {-2, +2}`; an
  /// out-of-range in-memory factor encodes faithfully and folds to ``disagree`` on the
  /// next decode (mirrors ``DownbeatResult``).
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .notCompared:
      _ = container.nestedContainer(keyedBy: OctaveCodingKeys.self, forKey: .notCompared)
    case .agree:
      _ = container.nestedContainer(keyedBy: OctaveCodingKeys.self, forKey: .agree)
    case .disagree:
      _ = container.nestedContainer(keyedBy: OctaveCodingKeys.self, forKey: .disagree)
    case .octaveEquivalent(let factor):
      var nested = container.nestedContainer(
        keyedBy: OctaveCodingKeys.self, forKey: .octaveEquivalent)
      try nested.encode(factor, forKey: .factor)
    }
  }
}
