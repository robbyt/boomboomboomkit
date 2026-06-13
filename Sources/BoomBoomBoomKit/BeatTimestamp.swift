//
//  BeatTimestamp.swift
//  BoomBoomBoomKit
//
//  One detected beat: playback time plus per-beat confidence and strength.
//

// MARK: - BeatTimestamp

/// A single detected beat in a ``BeatGrid``: the playback time at which the
/// beat occurs, plus how confident the tracker is in it and how strong the
/// onset was.
///
/// ## NaN-free by construction
/// Every float field is clamped finite at construction (see ``init(presentationTime:confidence:strength:)``
/// and the `Codable` decode path). This is the precondition that makes the
/// **compiler-synthesized** `Hashable`/`Equatable` sound: `Double.nan`/`Float.nan`
/// break reflexivity (`NaN != NaN`), so a type carrying an unsanitized non-finite
/// float cannot be soundly `Hashable`. Clamping eliminates NaN rather than
/// tolerating it, so there is no hand-written `bitPattern`-based `==` here.
///
/// ## Divergence from `LUFSReport`
/// `LUFSReport` also clamps every non-finite field, yet deliberately drops
/// `Hashable` — not for a reflexivity reason, but because it is never a
/// `Set`/`Dictionary` key and its multi-thousand-element series make hashing
/// pointless. The rule is two separate decisions: (1) any public value type
/// with float fields MUST clamp them finite at every init path; (2) THEN,
/// separately, add `Hashable` for small keyable values (this type) and omit it
/// for large series carriers (`LUFSReport`). Both clamp; they diverge only on
/// step (2). This is one rule with two outcomes, not an inconsistency.
public struct BeatTimestamp: Sendable, Hashable, Codable, CustomStringConvertible {

  // MARK: Stored

  /// Playback time of the beat, in seconds from the start of the analyzed
  /// audio. Always `≥ 0` — playback time is non-negative by definition;
  /// non-finite or negative inputs clamp to `0.0` at construction.
  public let presentationTime: Double

  /// Tracker confidence in this beat, in `[0.0, 1.0]`. Non-finite or
  /// out-of-range inputs clamp to the range (NaN → `0.0`) at construction.
  public let confidence: Float

  /// Normalized onset strength at this beat, in `[0.0, 1.0]`. Non-finite or
  /// out-of-range inputs clamp to the range (NaN → `0.0`) at construction.
  public let strength: Float

  // MARK: Init

  /// Creates a beat timestamp, clamping every float field finite.
  ///
  /// - `presentationTime` (`Double`): non-finite (`NaN`/`±Inf`) or negative →
  ///   `0.0`; positive finite passes through.
  /// - `confidence` / `strength` (`Float`): clamped to `[0.0, 1.0]`, with
  ///   `Float.nan` → `0.0`.
  ///
  /// Never throws and never propagates a non-finite float — the guarantee that
  /// makes synthesized `Hashable`/`Equatable` correct.
  ///
  /// - Parameters:
  ///   - presentationTime: Beat time in seconds (clamped `≥ 0`).
  ///   - confidence: Per-beat confidence (clamped to `[0, 1]`).
  ///   - strength: Per-beat onset strength (clamped to `[0, 1]`).
  public init(presentationTime: Double, confidence: Float, strength: Float) {
    self.presentationTime = BeatGridClamp.clampNonNegative(presentationTime)
    self.confidence = BeatGridClamp.clampUnit(confidence)
    self.strength = BeatGridClamp.clampUnit(strength)
  }

  // MARK: Codable

  /// Decodes raw scalars into locals and constructs `self` through the
  /// clamping ``init(presentationTime:confidence:strength:)`` so a hostile or
  /// out-of-range JSON payload is re-clamped on the way in. It deliberately
  /// does NOT assign decoded values directly to stored properties — that would
  /// bypass the clamp. `encode(to:)` and `CodingKeys` are compiler-synthesized
  /// (keyed by stored-property names); the two halves cannot desync because
  /// neither is hand-rolled.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let presentationTime = try container.decode(Double.self, forKey: .presentationTime)
    let confidence = try container.decode(Float.self, forKey: .confidence)
    let strength = try container.decode(Float.self, forKey: .strength)
    self.init(presentationTime: presentationTime, confidence: confidence, strength: strength)
  }

  // MARK: CustomStringConvertible

  /// One-line summary for logs and trace dumps.
  public var description: String {
    "BeatTimestamp(t: \(presentationTime)s, conf: \(confidence), str: \(strength))"
  }
}

// MARK: - BeatGridClamp

/// Internal precision-matched clamp helpers shared by ``BeatTimestamp`` and
/// ``BeatGrid`` (DD #2 — declared once, reused across both types). Caseless-enum
/// namespace per the project's `MelFilterbank`/`NumericTestHelpers` precedent.
enum BeatGridClamp {
  /// Clamps a `Float` to `[0.0, 1.0]`, mapping non-finite (`NaN`/`±Inf`) to
  /// `0.0`. Used for confidence/strength unit-interval fields.
  static func clampUnit(_ x: Float) -> Float {
    guard x.isFinite else { return 0.0 }
    return min(max(x, 0.0), 1.0)
  }

  /// Returns `x` when it is finite and strictly positive; otherwise `0.0`.
  /// Used for `presentationTime` (`≥ 0` by definition) and `estimatedTempo`
  /// (non-positive is the same "no valid estimate" equivalence class as
  /// absence — DD #8). Non-finite (`NaN`/`±Inf`) also maps to `0.0`.
  static func clampNonNegative(_ x: Double) -> Double {
    guard x.isFinite, x > 0 else { return 0.0 }
    return x
  }
}
