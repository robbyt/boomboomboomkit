//
//  DownbeatResult.swift
//  BoomBoomBoomKit
//
//  Tri-state downbeat-detection outcome carried by BeatGrid.
//

// MARK: - DownbeatResult

/// The outcome of downbeat (bar-start) detection for a ``BeatGrid``, as three
/// distinct states.
///
/// The tri-state distinction is the whole point of the type (FR-28): a consumer
/// must be able to tell "we never ran downbeat detection" apart from "we ran it
/// and found nothing".
///
/// - ``notAttempted``: downbeat detection did **not** run (e.g. the caller
///   requested beats only, or the stage was skipped). Absence of an attempt.
/// - ``noneDetected``: downbeat detection **ran** and found no downbeats.
///   A real, negative result — distinct from ``notAttempted``. This is the
///   honest abstain the Story-8.5a estimator returns when the rhythmic evidence
///   is too weak to lock a downbeat phase.
/// - ``detected(estimate:)``: downbeat detection ran and produced a
///   ``DownbeatEstimate`` (the downbeat beats, the assumed meter, an overall
///   confidence, and the locked bar-phase index — all NaN-free by construction).
///
/// ## Conformance
/// Not `CaseIterable`: this is **forced, not chosen** — the compiler suppresses
/// `CaseIterable` synthesis for any enum carrying an associated value (SE-0194),
/// and `.detected`'s payload is unbounded so `.allCases` would be meaningless
/// anyway. Do not hand-roll `allCases`. `Hashable` is sound because the
/// `.detected` payload is NaN-free (``DownbeatEstimate`` clamps its `confidence`
/// and every carried ``BeatTimestamp`` is clamped finite).
public enum DownbeatResult: Sendable, Hashable, Codable, CustomStringConvertible {

  /// Downbeat detection did not run.
  case notAttempted

  /// Downbeat detection ran and found no downbeats.
  case noneDetected

  /// Downbeat detection ran and produced this ``DownbeatEstimate``. The
  /// associated value is labeled `estimate:` so the `Codable` wire-shape is the
  /// stable `{"detected":{"estimate":{…}}}` rather than the positional
  /// `{"detected":{"_0":{…}}}` (DD #9 / SE-0295).
  case detected(estimate: DownbeatEstimate)

  // MARK: CustomStringConvertible

  /// One-line summary. Implemented as an exhaustive `switch` with **no**
  /// `default:` clause, so a future added case (e.g. `.ambiguous`) is a compile
  /// error here rather than a silent fallthrough.
  public var description: String {
    switch self {
    case .notAttempted:
      return "notAttempted"
    case .noneDetected:
      return "noneDetected"
    case .detected(let estimate):
      return "detected(\(estimate.beats.count) downbeats, phase \(estimate.phaseIndex))"
    }
  }

  // MARK: - Codable

  /// Top-level keys = the case names; `encode`/`decode` reproduce the SE-0295
  /// single-key wire shape (`{"detected":{"estimate":{…}}}` etc.) the synthesized
  /// conformance would, so the labeled `estimate:` payload stays stable.
  private enum CodingKeys: String, CodingKey {
    case notAttempted, noneDetected, detected
  }

  /// Nested keys for the ``detected(estimate:)`` payload — the single labeled
  /// `estimate` key (never a positional `_0`).
  private enum DetectedCodingKeys: String, CodingKey {
    case estimate
  }

  /// Decodes the tri-state, **normalizing a structurally-invalid decoded
  /// ``detected(estimate:)`` down to ``noneDetected``**.
  ///
  /// The estimator can never emit an unusable ``detected(estimate:)`` (it guards
  /// every structural invariant before constructing one), so the only source of an
  /// invalid payload — empty `beats`, `meter.beatsPerBar < 1`, or an out-of-range
  /// `phaseIndex` (see ``DownbeatEstimate/isStructurallyUsable``) — is a **stale or
  /// tampered cache**. Rather than hand a consumer a "success" it cannot use, an
  /// invalid `.detected` decodes as ``noneDetected`` — the tri-state already models
  /// "ran, nothing usable", and a corrupt cached success has the same operational
  /// meaning. The same fold covers an **unreadable** `.detected` payload (missing /
  /// `null` / wrong-type / structurally-broken `estimate`, or a non-object value):
  /// ``noneDetected`` rather than a throw. Only a payload with no recognized case key
  /// (or a non-object top-level value) throws. This follows the codebase's
  /// faithful-but-safe decode doctrine: untrusted persistence decodes into safe values,
  /// not errors.
  ///
  /// - Important: The round-trip is intentionally **non-identity for already-broken
  ///   data** — a valid `.detected` round-trips exactly, an invalid or unreadable one
  ///   normalizes to ``noneDetected``. A well-formed estimate from the analyzer is always
  ///   structurally usable, so its round-trip is identity.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.detected) {
      // A recognized `.detected` whose estimate is unreadable (missing / null /
      // wrong-type / non-object payload) OR structurally invalid folds to `.noneDetected`
      // (ran, nothing usable); it never throws.
      let estimate =
        (try? container.nestedContainer(keyedBy: DetectedCodingKeys.self, forKey: .detected))
        .flatMap { try? $0.decode(DownbeatEstimate.self, forKey: .estimate) }
      if let estimate, estimate.isStructurallyUsable {
        self = .detected(estimate: estimate)
      } else {
        self = .noneDetected
      }
    } else if container.contains(.noneDetected) {
      self = .noneDetected
    } else if container.contains(.notAttempted) {
      self = .notAttempted
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription:
            "DownbeatResult: no recognized case key (expected notAttempted / noneDetected / detected)"
        ))
    }
  }

  /// Encodes the SE-0295 single-key wire shape: `{"notAttempted":{}}` /
  /// `{"noneDetected":{}}` / `{"detected":{"estimate":{…}}}` — the labeled
  /// `estimate:` payload, never a positional `_0`.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .notAttempted:
      _ = container.nestedContainer(keyedBy: DetectedCodingKeys.self, forKey: .notAttempted)
    case .noneDetected:
      _ = container.nestedContainer(keyedBy: DetectedCodingKeys.self, forKey: .noneDetected)
    case .detected(let estimate):
      var nested = container.nestedContainer(
        keyedBy: DetectedCodingKeys.self, forKey: .detected)
      try nested.encode(estimate, forKey: .estimate)
    }
  }
}
