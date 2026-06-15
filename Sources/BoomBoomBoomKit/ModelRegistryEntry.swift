//
//  ModelRegistryEntry.swift
//  BoomBoomBoomKit
//
//  Value types for the consumer-facing model catalog: the integrity
//  fingerprint (`ModelDigest`), the capability tag (`ModelCapability`), the
//  catalog row (`ModelRegistryEntry`), and the register-time input
//  (`ModelMetadata`). No CryptoKit import — the fingerprint is plain bytes;
//  CryptoKit only produces those bytes inside `ModelRegistry.computeDigest`.
//

import Foundation

// MARK: - ModelDigest

/// A 32-byte content fingerprint of a model bundle (SHA-256).
///
/// ``ModelDigest`` is the integrity currency of ``ModelRegistry``: a model is
/// registered, the registry hashes its bytes into a ``ModelDigest``, and a
/// consumer can pin a known ``ModelDigest`` to have a silent disk swap surface
/// as a typed ``ModelRegistryError/integrityCheckFailed(expected:actual:)``.
///
/// It is a library-owned type rather than CryptoKit's `SHA256.Digest` because
/// `SHA256.Digest` can only be produced by hashing data — it exposes no
/// initializer from raw bytes or from a hex string. A consumer pinning a model
/// needs exactly that: turn a hash published in a manifest (or one persisted as
/// hex across launches) back into a value to verify against. ``init(hex:)`` is
/// that capability. The 32-byte invariant is enforced at construction.
///
/// Independently `Codable` (canonical lowercase-hex single value) so a consumer
/// can persist the fingerprint directly without persisting a whole
/// ``ModelRegistryEntry`` (which is intentionally not `Codable` — see that
/// type's discussion).
public struct ModelDigest: Sendable, Hashable {

  /// The raw digest bytes. Always exactly 32 (SHA-256 output width).
  public let bytes: [UInt8]

  /// Wraps raw digest bytes, rejecting any length other than 32.
  ///
  /// - Parameter bytes: The digest bytes; must be exactly 32.
  /// - Throws: ``ModelRegistryError/invalidDigest(reason:)`` when `bytes`
  ///   is not 32 elements long.
  public init(bytes: some Collection<UInt8>) throws {
    let array = Array(bytes)
    guard array.count == 32 else {
      throw ModelRegistryError.invalidDigest(
        reason: "SHA-256 digest must be exactly 32 bytes; got \(array.count)")
    }
    self.bytes = array
  }

  /// Parses a 64-character hexadecimal string into a 32-byte digest.
  ///
  /// Case-insensitive; rejects any input that is not exactly 64 ASCII hex
  /// characters. This is the load-bearing capability CryptoKit's
  /// `SHA256.Digest` lacks — it lets a consumer reconstruct a pinned digest
  /// from a published manifest or a persisted hex string.
  ///
  /// - Parameter hex: A 64-character hex string (e.g. the output of
  ///   ``hexString``).
  /// - Throws: ``ModelRegistryError/invalidDigest(reason:)`` on wrong length
  ///   or a non-hex character.
  public init(hex: String) throws {
    let scalars = Array(hex.utf8)
    guard scalars.count == 64 else {
      throw ModelRegistryError.invalidDigest(
        reason: "hex digest must be 64 hex characters; got \(scalars.count)")
    }
    func nibble(_ byte: UInt8) -> UInt8? {
      switch byte {
      case 0x30...0x39: return byte - 0x30  // 0-9
      case 0x61...0x66: return byte - 0x61 + 10  // a-f
      case 0x41...0x46: return byte - 0x41 + 10  // A-F
      default: return nil
      }
    }
    var parsed = [UInt8]()
    parsed.reserveCapacity(32)
    var index = 0
    while index < 64 {
      guard let high = nibble(scalars[index]), let low = nibble(scalars[index + 1]) else {
        throw ModelRegistryError.invalidDigest(
          reason: "hex digest contains a non-hex character")
      }
      parsed.append(high << 4 | low)
      index += 2
    }
    self.bytes = parsed
  }

  /// The digest rendered as a 64-character lowercase hex string — the canonical
  /// display and persistence form (round-trips through ``init(hex:)``).
  public var hexString: String {
    bytes.map { String(format: "%02x", $0) }.joined()
  }
}

extension ModelDigest: Codable {
  /// Decodes from a single canonical lowercase-hex string value.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = try ModelDigest(hex: container.decode(String.self))
  }

  /// Encodes as a single canonical lowercase-hex string value (``hexString``).
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(hexString)
  }
}

// MARK: - ModelCapability

/// What a registered model can do.
///
/// Closed-ish and additively-extensible pre-1.0: new cases land with the story
/// that introduces a consuming code path, not speculatively. Today the library
/// consumes exactly one capability — tempo estimation.
public enum ModelCapability: String, Sendable, Hashable, CaseIterable, Codable {
  /// The model estimates musical tempo (beats per minute).
  case tempoEstimation
}

// MARK: - ModelMetadata

/// The register-time inputs that are NOT derived from the model file: identity,
/// declared capabilities, and attribution.
///
/// The required ``identifier`` is the only non-defaulted field (the rest are
/// optional/defaulted in one struct), giving
/// ``ModelRegistry/register(url:expectedDigest:metadata:)`` its three-parameter
/// shape.
public struct ModelMetadata: Sendable, Hashable {

  /// Stable identifier for the model (e.g. `"bnns_tempo_v1"`). Should match the
  /// ``MLEvaluation/modelIdentifier`` a producing model stamps on its results
  /// so trace logs can be joined back to the registered model.
  public let identifier: String

  /// What this model can do. Empty by default.
  public let capabilities: Set<ModelCapability>

  /// SPDX-style license string for attribution display, or `nil` if unknown.
  public let license: String?

  /// Provenance URL (where the weights came from), or `nil` if unknown.
  public let sourceURL: URL?

  /// Creates register-time metadata.
  ///
  /// - Parameters:
  ///   - identifier: The stable model identifier (required).
  ///   - capabilities: What the model can do. Defaults to empty.
  ///   - license: License string for display. Defaults to `nil`.
  ///   - sourceURL: Provenance URL. Defaults to `nil`.
  public init(
    identifier: String,
    capabilities: Set<ModelCapability> = [],
    license: String? = nil,
    sourceURL: URL? = nil
  ) {
    self.identifier = identifier
    self.capabilities = capabilities
    self.license = license
    self.sourceURL = sourceURL
  }
}

// MARK: - ModelRegistryEntry

/// One registered model: identity, integrity fingerprint, declared
/// capabilities, attribution, and the resolved file URL the digest was computed
/// over.
///
/// Produced by ``ModelRegistry/register(url:expectedDigest:metadata:)``; read
/// back via ``ModelRegistry/entries`` and
/// ``ModelRegistry/lookup(identifier:)``.
///
/// ## Not `Codable` by design
///
/// ``ModelRegistryEntry`` is intentionally NOT `Codable`. Its ``url`` would
/// encode as a bare path string that does not round-trip a security-scoped
/// sandbox file, so a synthesized codec would be a persistence footgun. To
/// persist a registration, store a security-scoped bookmark for the file plus
/// the ``identifier`` and the ``ModelDigest`` hex (``ModelDigest`` IS
/// independently `Codable`), then re-register on next launch.
public struct ModelRegistryEntry: Sendable, Hashable {

  /// Stable identifier for the model.
  ///
  /// The forensic tag a producing model stamps on its ``MLEvaluation``
  /// (``MLEvaluation/modelIdentifier``) should match this registry identifier
  /// so trace logs can be joined to a registered model.
  public let identifier: String

  /// The integrity fingerprint the registry computed (or the pinned digest the
  /// consumer supplied, which equals the computed one — registration throws
  /// otherwise).
  public let digest: ModelDigest

  /// What this model can do.
  public let capabilities: Set<ModelCapability>

  /// License string for attribution display, or `nil`.
  public let license: String?

  /// Provenance URL, or `nil`.
  public let sourceURL: URL?

  /// The standardized file URL the digest was computed over.
  ///
  /// - Note: Not safe to persist as a path — see this type's "Not `Codable` by
  ///   design" discussion. Persist a security-scoped bookmark instead.
  public let url: URL

  /// The digest as a lowercase hex string, for display (e.g. an
  /// `Integrity: verified` badge). Consumers never reach into raw bytes.
  public var digestHexString: String { digest.hexString }

  /// Creates a registry entry. Normally produced by
  /// ``ModelRegistry/register(url:expectedDigest:metadata:)``; public so
  /// consumers and tests can construct one directly.
  public init(
    identifier: String,
    digest: ModelDigest,
    capabilities: Set<ModelCapability>,
    license: String?,
    sourceURL: URL?,
    url: URL
  ) {
    self.identifier = identifier
    self.digest = digest
    self.capabilities = capabilities
    self.license = license
    self.sourceURL = sourceURL
    self.url = url
  }
}
