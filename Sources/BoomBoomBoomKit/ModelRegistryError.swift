//
//  ModelRegistryError.swift
//  BoomBoomBoomKit
//
//  Typed failures thrown by ModelRegistry.register and the ModelDigest
//  initializers. No CryptoKit import — these carry the library-owned
//  ModelDigest, not SHA256.Digest.
//

import Foundation

// MARK: - ModelRegistryError

/// Failures surfaced by ``ModelRegistry`` registration and ``ModelDigest``
/// construction.
///
/// These exist so model misuse — corruption, a wrong-version checkpoint, a
/// silent on-disk swap — fails loudly with both digests in hand, rather than
/// flowing through as silently-wrong tempo output.
public enum ModelRegistryError: Error, Sendable {

  /// A pinned ``ModelDigest`` did not match the digest computed over the model
  /// on disk. `expected` is what the consumer pinned; `actual` is what the
  /// bytes hashed to. The registry does NOT register the model in this case —
  /// `entries` is left unchanged.
  case integrityCheckFailed(expected: ModelDigest, actual: ModelDigest)

  /// A ``ModelDigest`` could not be constructed: the byte count was not 32, or
  /// a hex string was not 64 valid hex characters. `reason` describes which
  /// invariant failed.
  case invalidDigest(reason: String)

  /// No model resource exists (or could be read) at the supplied URL.
  ///
  /// - Note: Deliberately mirrors the name of the sibling
  ///   `MLTechniqueError.modelResourceMissing(URL)` — a different enum, no
  ///   conflict; do not conflate them.
  case modelResourceMissing(URL)

  /// The resource at the supplied URL is not a model directory bundle the
  /// registry can hash (e.g. a regular file rather than an `.mlmodelc`
  /// directory), or its contents could not be enumerated. `reason` describes
  /// the specific mismatch.
  case unsupportedFormat(reason: String)
}

// MARK: - CustomStringConvertible

extension ModelRegistryError: CustomStringConvertible {
  /// Human-readable diagnostic; renders both digests as hex for
  /// ``integrityCheckFailed(expected:actual:)``.
  public var description: String {
    switch self {
    case .integrityCheckFailed(let expected, let actual):
      return "ModelRegistryError.integrityCheckFailed("
        + "expected: \(expected.hexString), actual: \(actual.hexString))"
    case .invalidDigest(let reason):
      return "ModelRegistryError.invalidDigest(\(reason))"
    case .modelResourceMissing(let url):
      return "ModelRegistryError.modelResourceMissing(\(url.path))"
    case .unsupportedFormat(let reason):
      return "ModelRegistryError.unsupportedFormat(\(reason))"
    }
  }
}
