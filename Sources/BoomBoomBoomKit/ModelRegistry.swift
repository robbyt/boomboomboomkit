//
//  ModelRegistry.swift
//  BoomBoomBoomKit
//
//  Consumer-facing catalog of bundled / user-added / known-reference models
//  with SHA-256 integrity validation at registration time. Standalone — NOT
//  wired into the BPM / LUFS / beat-grid analysis pipeline. This is the ONLY
//  file in the core target that imports CryptoKit.
//

import CryptoKit
import Foundation
import Synchronization

// MARK: - ModelRegistry

/// An in-memory catalog of ML models with integrity validation at registration
/// time.
///
/// A consumer registers a model directory bundle (e.g. a `.mlmodelc`); the
/// registry hashes its contents into a ``ModelDigest`` and records a
/// ``ModelRegistryEntry``. Two registration modes:
///
/// - **Trust-on-first-use (TOFU)** — call
///   ``register(url:expectedDigest:metadata:)`` with `expectedDigest: nil`. The
///   registry computes and records the digest. This is *pin-now-detect-later*,
///   not verified provenance: it records whatever is on disk the first time and
///   can detect a later swap, but it does not vouch for the original.
/// - **Pinned** — pass a known ``ModelDigest`` (reconstructed from a published
///   manifest or persisted hex via ``ModelDigest/init(hex:)``). If the bytes on
///   disk hash to something else, registration throws
///   ``ModelRegistryError/integrityCheckFailed(expected:actual:)`` and the
///   model is NOT registered.
///
/// ## Lifecycle and persistence
///
/// In-memory only — there is no `save`/`load`. Persistence is the consumer's
/// responsibility (e.g. a security-scoped bookmark plus the ``identifier`` and
/// the ``ModelDigest`` hex in `UserDefaults`, re-registering on launch).
///
/// - Important: A pinned-digest check (non-`nil` `expectedDigest`) always
///   recomputes the digest from disk, so it re-verifies on every call and
///   detects an on-disk swap even for a URL registered earlier in the same
///   process. Trust-on-first-use (`expectedDigest: nil`) is
///   cache-on-first-load: the digest is computed once per file URL and reused
///   for subsequent TOFU registrations of the same URL.
///
/// ## Thread safety
///
/// `Sendable` via an internal `Mutex`; concurrent `register` calls from
/// multiple tasks are serialized and never corrupt the entry array.
public final class ModelRegistry: Sendable {

  /// All mutable state, guarded by a single ``Mutex``.
  private struct State {
    var entries: [ModelRegistryEntry] = []
    var digestCache: [URL: ModelDigest] = [:]
    var digestComputationCount: Int = 0
  }

  private let state = Mutex(State())

  /// Chunk size for streaming file reads during digest computation (1 MiB), so a
  /// large weight blob is never materialized into a single buffer.
  private static let digestChunkSize = 1 << 20

  /// Creates an empty registry.
  public init() {}

  // MARK: Reads

  /// A snapshot of all registered entries, in registration order.
  public var entries: [ModelRegistryEntry] {
    state.withLock { $0.entries }
  }

  /// The first registered entry with the given identifier, or `nil`.
  ///
  /// - Note: Identifiers are NOT deduplicated — registering the same identifier
  ///   twice appends a second entry, and this returns the first one. If you
  ///   re-register an identifier with updated bytes, look it up by inspecting
  ///   ``entries`` or use a fresh registry.
  public func lookup(identifier: String) -> ModelRegistryEntry? {
    state.withLock { state in
      state.entries.first { $0.identifier == identifier }
    }
  }

  // MARK: Registration

  /// Registers a model directory bundle after validating its integrity.
  ///
  /// Computes the SHA-256 digest over the bundle's contents. A pinned
  /// `expectedDigest` recomputes from disk on every call (re-verification);
  /// trust-on-first-use (`expectedDigest: nil`) caches the digest per file URL.
  /// If `expectedDigest` is non-`nil` and does not match the computed digest,
  /// throws and leaves ``entries`` unchanged. Otherwise appends and returns the
  /// new entry.
  ///
  /// - Parameters:
  ///   - url: The model directory bundle (e.g. a `.mlmodelc`).
  ///   - expectedDigest: A pinned digest to verify against, or `nil` for
  ///     trust-on-first-use. Defaults to `nil`.
  ///   - metadata: Identity and attribution that are not derived from the file.
  /// - Returns: The registered ``ModelRegistryEntry``.
  /// - Throws: ``ModelRegistryError/modelResourceMissing(_:)`` if the resource
  ///   does not exist; ``ModelRegistryError/unsupportedFormat(reason:)`` if it
  ///   is not a hashable directory bundle;
  ///   ``ModelRegistryError/integrityCheckFailed(expected:actual:)`` on a
  ///   pinned-digest mismatch.
  public func register(
    url: URL,
    expectedDigest: ModelDigest? = nil,
    metadata: ModelMetadata
  ) throws -> ModelRegistryEntry {
    let key = url.standardizedFileURL
    // DD-6: the digest does file I/O; we hold the lock across it so the
    // cache-check / compute / cache-insert / append sequence is atomic.
    // Registration is not a hot path, so the simplicity is worth more than
    // releasing the lock during the read.
    return try state.withLock { state in
      let computedDigest: ModelDigest
      // A pinned check (non-nil expectedDigest) ALWAYS recomputes from disk so a
      // post-registration swap is detected even for a URL cached earlier in this
      // process — re-verification is the pinned path's whole purpose. TOFU
      // (nil) uses cache-on-first-load.
      if expectedDigest == nil, let cached = state.digestCache[key] {
        computedDigest = cached
      } else {
        computedDigest = try Self.computeDigest(forModelAt: key)
        state.digestComputationCount += 1
        state.digestCache[key] = computedDigest
      }

      if let expectedDigest, expectedDigest != computedDigest {
        throw ModelRegistryError.integrityCheckFailed(
          expected: expectedDigest, actual: computedDigest)
      }

      let entry = ModelRegistryEntry(
        identifier: metadata.identifier,
        digest: expectedDigest ?? computedDigest,
        capabilities: metadata.capabilities,
        license: metadata.license,
        sourceURL: metadata.sourceURL,
        url: key)
      state.entries.append(entry)
      return entry
    }
  }

  /// Number of times the SHA-256 digest was actually computed (cache misses).
  /// Internal, `@testable`-visible — proves cache-on-first-load.
  var digestComputationCount: Int {
    state.withLock { $0.digestComputationCount }
  }

  // MARK: Digest (KDD-C5) — the sole CryptoKit touch-point

  /// Computes the integrity digest of a model directory bundle.
  ///
  /// Algorithm: recursively enumerate the regular files under `url`, take each
  /// file's path relative to `url`, and sort ascending by that path's UTF-8
  /// bytes (locale-independent, deterministic across filesystems). Then, for
  /// each file in order, feed an incremental SHA-256 with the file's relative
  /// path, a NUL separator, the file's contents (streamed in chunks, so a large
  /// weight blob is never materialized into a single buffer), and the content
  /// length as an 8-byte big-endian suffix.
  ///
  /// Binding the relative path and length — not just the concatenated contents —
  /// means the digest identifies the bundle *structure*: a rename, a moved
  /// file, an added or removed file (including a zero-byte file), and any byte
  /// change all change the digest, and two different layouts cannot collide via
  /// a shared content byte stream.
  ///
  /// SHA-256 is hardware-accelerated on Apple Silicon (CryptoKit default). The
  /// finalized 32 bytes are wrapped into a ``ModelDigest`` — this is the only
  /// place CryptoKit is touched.
  ///
  /// - Parameter url: The model directory bundle.
  /// - Returns: The 32-byte ``ModelDigest``.
  /// - Throws: ``ModelRegistryError/modelResourceMissing(_:)`` if the resource
  ///   (or one of its files) cannot be read;
  ///   ``ModelRegistryError/unsupportedFormat(reason:)`` if it is not a
  ///   directory or cannot be enumerated.
  static func computeDigest(forModelAt url: URL) throws -> ModelDigest {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      throw ModelRegistryError.modelResourceMissing(url)
    }
    guard isDirectory.boolValue else {
      throw ModelRegistryError.unsupportedFormat(
        reason: "expected a model directory bundle, but "
          + "\(url.lastPathComponent) is a regular file")
    }

    // Integrity code fails closed: an enumeration error aborts the walk (the
    // synchronous handler captures the first error; `nonisolated(unsafe)` is
    // the documented pattern for these in-thread Foundation callbacks). We do
    // NOT hash over a partially-readable bundle.
    nonisolated(unsafe) var enumerationError: (any Error)?
    guard
      let enumerator = fileManager.enumerator(
        at: url,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [],
        errorHandler: { _, error in
          enumerationError = error
          return false
        })
    else {
      throw ModelRegistryError.unsupportedFormat(
        reason: "could not enumerate the contents of \(url.lastPathComponent)")
    }

    let basePath = url.standardizedFileURL.path
    var files: [(relativePath: String, url: URL)] = []
    for case let fileURL as URL in enumerator {
      // Fail closed on an unstatable entry rather than silently dropping it
      // from the hash. A non-regular entry (directory, or a symlink that
      // `.isRegularFileKey` resolves to a directory) is correctly skipped; a
      // symlink resolving to a regular file is hashed as its target bytes.
      let isRegularFile: Bool
      do {
        isRegularFile =
          try fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile ?? false
      } catch {
        throw ModelRegistryError.unsupportedFormat(
          reason: "could not read the attributes of \(fileURL.lastPathComponent)")
      }
      guard isRegularFile else { continue }
      let fullPath = fileURL.standardizedFileURL.path
      let relativePath: String
      if fullPath.hasPrefix(basePath + "/") {
        relativePath = String(fullPath.dropFirst(basePath.count + 1))
      } else {
        // Fallback for a path that does not sit under `basePath` (e.g. a
        // symlinked component the enumerator resolved elsewhere). Use the full
        // standardized path — it is unique per file, so the sort key never
        // collides and the digest stays deterministic.
        relativePath = fullPath
      }
      files.append((relativePath: relativePath, url: fileURL))
    }

    if let enumerationError {
      throw ModelRegistryError.unsupportedFormat(
        reason: "enumeration of \(url.lastPathComponent) failed: \(enumerationError)")
    }

    guard !files.isEmpty else {
      throw ModelRegistryError.unsupportedFormat(
        reason: "\(url.lastPathComponent) contains no regular files to hash")
    }

    // Sort by the relative path's UTF-8 bytes (not String `<`, which folds
    // canonically-equivalent Unicode and is locale-shaped) for a deterministic,
    // cross-filesystem-stable order.
    files.sort { $0.relativePath.utf8.lexicographicallyPrecedes($1.relativePath.utf8) }

    var hasher = SHA256()
    for file in files {
      // Frame each file as: relative-path bytes, a NUL separator (which cannot
      // appear in a POSIX path), the streamed contents, then the content length
      // as an 8-byte big-endian suffix. Binding the path and length makes
      // renames, layout changes, and added/removed (even zero-byte) files all
      // change the digest; streaming never materializes a large blob.
      hasher.update(data: Data(file.relativePath.utf8))
      hasher.update(data: Data([0x00]))
      let handle: FileHandle
      do {
        handle = try FileHandle(forReadingFrom: file.url)
      } catch {
        throw ModelRegistryError.modelResourceMissing(file.url)
      }
      defer { try? handle.close() }
      var contentLength: UInt64 = 0
      while true {
        let chunk: Data
        do {
          chunk = try handle.read(upToCount: Self.digestChunkSize) ?? Data()
        } catch {
          throw ModelRegistryError.modelResourceMissing(file.url)
        }
        if chunk.isEmpty { break }
        hasher.update(data: chunk)
        contentLength += UInt64(chunk.count)
      }
      let lengthSuffix = withUnsafeBytes(of: contentLength.bigEndian) { Data($0) }
      hasher.update(data: lengthSuffix)
    }
    return try ModelDigest(bytes: Array(hasher.finalize()))
  }
}
