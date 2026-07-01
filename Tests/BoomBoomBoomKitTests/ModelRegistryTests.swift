//
//  ModelRegistryTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8-6: ModelRegistry + ModelDigest + ModelRegistryEntry +
//  ModelRegistryError. Covers ModelDigest invariants, happy-path / TOFU /
//  mismatch registration, always-recompute (no digest cache, so TOFU detects an
//  on-disk swap), missing/unsupported resources, and Mutex correctness under
//  concurrent registration.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("Story 8-6 ModelRegistry")
struct ModelRegistryTests {

  // MARK: - Fixture URL resolution

  /// `.mlmodelc` fixtures are directories, so resolve via
  /// `Bundle.module.resourceURL` directly (`url(forResource:withExtension:)`
  /// looks for files, not directories).
  private func fixturesURL() throws -> URL {
    let resourceURL = try #require(Bundle.module.resourceURL)
    return resourceURL.appendingPathComponent("Fixtures")
  }

  /// The committed multi-file fixture (nested `weights/` + `analytics/`
  /// subdirs) — exercises the recursive sorted-relative-path enumeration.
  private func customBundledURL() throws -> URL {
    let url = try fixturesURL().appendingPathComponent("CustomBundled.mlmodelc")
    try #require(FileManager.default.fileExists(atPath: url.path))
    return url
  }

  /// The net-new synthetic mismatch fixture.
  private func tamperedURL() throws -> URL {
    let url = try fixturesURL().appendingPathComponent("Models/tampered.mlmodelc")
    try #require(FileManager.default.fileExists(atPath: url.path))
    return url
  }

  /// Creates a temporary `.mlmodelc` directory containing the given
  /// `(relative path, bytes)` files. Caller is responsible for cleanup.
  private func makeTempBundle(_ files: [(path: String, bytes: [UInt8])]) throws -> URL {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("bbbk-bundle-\(UUID().uuidString).mlmodelc")
    for file in files {
      let fileURL = root.appendingPathComponent(file.path)
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      try Data(file.bytes).write(to: fileURL)
    }
    return root
  }

  // MARK: - ModelDigest invariants

  @Test("ModelDigest hex round-trips through hexString")
  func digestHexRoundTrips() throws {
    let hex = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    let digest = try ModelDigest(hex: hex)
    #expect(digest.bytes.count == 32)
    #expect(digest.hexString == hex)
  }

  @Test("ModelDigest hex parsing is case-insensitive and normalizes to lowercase")
  func digestHexIsCaseInsensitive() throws {
    let upper = String(repeating: "AB", count: 32)
    let digest = try ModelDigest(hex: upper)
    #expect(digest.hexString == String(repeating: "ab", count: 32))
  }

  @Test("ModelDigest(bytes:) rejects any length other than 32")
  func digestRejectsWrongByteCount() {
    #expect(throws: ModelRegistryError.self) {
      try ModelDigest(bytes: [UInt8](repeating: 0, count: 16))
    }
    #expect(throws: ModelRegistryError.self) {
      try ModelDigest(bytes: [UInt8](repeating: 0, count: 33))
    }
  }

  @Test("ModelDigest(hex:) rejects wrong length and non-hex characters")
  func digestRejectsBadHex() {
    #expect(throws: ModelRegistryError.self) { try ModelDigest(hex: "abcd") }
    #expect(throws: ModelRegistryError.self) {
      try ModelDigest(hex: String(repeating: "zz", count: 32))
    }
  }

  @Test("ModelDigest is Codable through a single canonical hex value")
  func digestCodableRoundTrips() throws {
    let digest = try ModelDigest(hex: String(repeating: "9f", count: 32))
    let data = try JSONEncoder().encode(digest)
    let decoded = try JSONDecoder().decode(ModelDigest.self, from: data)
    #expect(decoded == digest)
    let json = try #require(String(data: data, encoding: .utf8))
    #expect(json == "\"\(digest.hexString)\"")
  }

  // MARK: - computeDigest determinism

  @Test("computeDigest is deterministic for the same bundle")
  func computeDigestIsDeterministic() throws {
    let url = try customBundledURL()
    let first = try ModelRegistry.computeDigest(forModelAt: url)
    let second = try ModelRegistry.computeDigest(forModelAt: url)
    #expect(first == second)
    #expect(first.bytes.count == 32)
  }

  // MARK: - Registration

  @Test("happy path: register with a matching pinned digest")
  func happyPathMatchingDigest() throws {
    let url = try customBundledURL()
    let registry = ModelRegistry()
    let expected = try ModelRegistry.computeDigest(forModelAt: url)
    let entry = try registry.register(
      url: url,
      expectedDigest: expected,
      metadata: ModelMetadata(
        identifier: "custom-bundled",
        capabilities: [.tempoEstimation],
        license: "Apache-2.0"))
    #expect(entry.digest == expected)
    #expect(entry.identifier == "custom-bundled")
    #expect(entry.capabilities == [.tempoEstimation])
    #expect(entry.license == "Apache-2.0")
    #expect(entry.digestHexString == expected.hexString)
    #expect(registry.entries.count == 1)
    #expect(registry.lookup(identifier: "custom-bundled")?.digest == expected)
    #expect(registry.lookup(identifier: "does-not-exist") == nil)
  }

  @Test("TOFU: nil expectedDigest records the freshly-computed digest")
  func tofuRecordsComputedDigest() throws {
    let url = try customBundledURL()
    let registry = ModelRegistry()
    let entry = try registry.register(
      url: url, metadata: ModelMetadata(identifier: "tofu"))
    let computed = try ModelRegistry.computeDigest(forModelAt: url)
    #expect(entry.digest == computed)
    #expect(registry.entries.count == 1)
  }

  @Test("mismatch: a wrong pinned digest throws and leaves the registry unchanged")
  func mismatchThrowsAndLeavesRegistryUnchanged() throws {
    let url = try tamperedURL()
    let registry = ModelRegistry()
    let wrong = try ModelDigest(hex: String(repeating: "00", count: 32))
    let real = try ModelRegistry.computeDigest(forModelAt: url)
    do {
      _ = try registry.register(
        url: url, expectedDigest: wrong,
        metadata: ModelMetadata(identifier: "tampered"))
      Issue.record("expected .integrityCheckFailed, got success")
    } catch let ModelRegistryError.integrityCheckFailed(expected, actual) {
      #expect(expected == wrong)
      #expect(actual == real)
      #expect(actual != wrong)
    } catch {
      Issue.record("expected .integrityCheckFailed, got \(error)")
    }
    #expect(registry.entries.isEmpty)
  }

  @Test("TOFU: every register on the same URL recomputes the digest (no cache)")
  func tofuRecomputesOnEveryRegister() throws {
    let url = try customBundledURL()
    let registry = ModelRegistry()
    _ = try registry.register(url: url, metadata: ModelMetadata(identifier: "first"))
    _ = try registry.register(url: url, metadata: ModelMetadata(identifier: "second"))
    // No digest cache: both TOFU registers re-hash from disk.
    #expect(registry.digestComputationCount == 2)
    #expect(registry.entries.count == 2)
  }

  @Test("missing resource: registering a non-existent URL throws .modelResourceMissing")
  func missingResourceThrows() throws {
    let registry = ModelRegistry()
    let missing = URL(fileURLWithPath: "/tmp/definitely-not-a-real.mlmodelc")
    do {
      _ = try registry.register(
        url: missing, metadata: ModelMetadata(identifier: "missing"))
      Issue.record("expected .modelResourceMissing, got success")
    } catch let ModelRegistryError.modelResourceMissing(url) {
      #expect(url.standardizedFileURL == missing.standardizedFileURL)
    } catch {
      Issue.record("expected .modelResourceMissing, got \(error)")
    }
    #expect(registry.entries.isEmpty)
  }

  @Test("unsupported format: registering an empty directory throws .unsupportedFormat")
  func unsupportedFormatForEmptyDirectory() throws {
    let emptyDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("bbbk-empty-\(UUID().uuidString).mlmodelc")
    try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: emptyDir) }
    let registry = ModelRegistry()
    do {
      _ = try registry.register(
        url: emptyDir, metadata: ModelMetadata(identifier: "empty"))
      Issue.record("expected .unsupportedFormat, got success")
    } catch ModelRegistryError.unsupportedFormat {
      // expected
    } catch {
      Issue.record("expected .unsupportedFormat, got \(error)")
    }
    #expect(registry.entries.isEmpty)
  }

  @Test("unsupported format: registering a regular file throws .unsupportedFormat")
  func unsupportedFormatForRegularFile() throws {
    let fileURL = try customBundledURL().appendingPathComponent("metadata.json")
    try #require(FileManager.default.fileExists(atPath: fileURL.path))
    let registry = ModelRegistry()
    do {
      _ = try registry.register(
        url: fileURL, metadata: ModelMetadata(identifier: "regular-file"))
      Issue.record("expected .unsupportedFormat, got success")
    } catch ModelRegistryError.unsupportedFormat {
      // expected
    } catch {
      Issue.record("expected .unsupportedFormat, got \(error)")
    }
    #expect(registry.entries.isEmpty)
  }

  // MARK: - Sendable / concurrency

  @Test("Sendable: concurrent registration does not corrupt the entry array")
  func concurrentRegistrationIsSafe() async throws {
    let url = try customBundledURL()
    let registry = ModelRegistry()
    let count = 32
    try await withThrowingTaskGroup(of: Void.self) { group in
      for index in 0..<count {
        group.addTask {
          _ = try registry.register(
            url: url, metadata: ModelMetadata(identifier: "model-\(index)"))
        }
      }
      try await group.waitForAll()
    }
    // No lost updates: every task's entry landed.
    #expect(registry.entries.count == count)
    #expect(Set(registry.entries.map(\.identifier)).count == count)
    // No digest cache: each register recomputes, so the count equals the number
    // of registrations (the Mutex still serializes the compute/append).
    #expect(registry.digestComputationCount == count)
  }

  // MARK: - Digest binds bundle structure (path + length, not just contents)

  @Test("adding a zero-byte file changes the digest")
  func emptyFileChangesDigest() throws {
    let base = try makeTempBundle([(path: "model.bin", bytes: [1, 2, 3])])
    defer { try? FileManager.default.removeItem(at: base) }
    let before = try ModelRegistry.computeDigest(forModelAt: base)
    try Data().write(to: base.appendingPathComponent("EMPTY"))
    let after = try ModelRegistry.computeDigest(forModelAt: base)
    #expect(before != after)
  }

  @Test("renaming a file changes the digest (relative path is bound)")
  func renameChangesDigest() throws {
    let a = try makeTempBundle([(path: "a.bin", bytes: [10, 20, 30])])
    defer { try? FileManager.default.removeItem(at: a) }
    let b = try makeTempBundle([(path: "b.bin", bytes: [10, 20, 30])])
    defer { try? FileManager.default.removeItem(at: b) }
    // Identical content bytes, different file name → different digest.
    #expect(
      try ModelRegistry.computeDigest(forModelAt: a)
        != ModelRegistry.computeDigest(forModelAt: b))
  }

  @Test("redistributing the same bytes across files changes the digest (boundaries bound)")
  func fileBoundaryChangesDigest() throws {
    let split = try makeTempBundle([(path: "x", bytes: [1, 2]), (path: "y", bytes: [3])])
    defer { try? FileManager.default.removeItem(at: split) }
    let merged = try makeTempBundle([(path: "x", bytes: [1, 2, 3]), (path: "y", bytes: [])])
    defer { try? FileManager.default.removeItem(at: merged) }
    // Same concatenated content stream, different file boundaries → different digest.
    #expect(
      try ModelRegistry.computeDigest(forModelAt: split)
        != ModelRegistry.computeDigest(forModelAt: merged))
  }

  // MARK: - Pinned re-verify recomputes on every register

  @Test("pinned re-verify recomputes the digest on every call")
  func pinnedReVerifiesOnEveryRegister() throws {
    let url = try customBundledURL()
    let registry = ModelRegistry()
    let digest = try ModelRegistry.computeDigest(forModelAt: url)
    _ = try registry.register(
      url: url, expectedDigest: digest, metadata: ModelMetadata(identifier: "pinned-1"))
    _ = try registry.register(
      url: url, expectedDigest: digest, metadata: ModelMetadata(identifier: "pinned-2"))
    // Each pinned register re-hashes from disk (re-verification), unlike TOFU.
    #expect(registry.digestComputationCount == 2)
    #expect(registry.entries.count == 2)
  }

  @Test("TOFU then pinned register on the same URL both recompute from disk")
  func tofuAndPinnedBothRecompute() throws {
    let url = try customBundledURL()
    let registry = ModelRegistry()
    _ = try registry.register(url: url, metadata: ModelMetadata(identifier: "tofu"))
    // TOFU recomputes (no cache).
    #expect(registry.digestComputationCount == 1)
    let digest = try ModelRegistry.computeDigest(forModelAt: url)
    _ = try registry.register(
      url: url, expectedDigest: digest, metadata: ModelMetadata(identifier: "pinned"))
    // Pinned recomputes too — both modes always re-hash.
    #expect(registry.digestComputationCount == 2)
  }

  // MARK: - TOFU detects an on-disk swap (no cache)

  @Test("TOFU: re-registering after an on-disk swap recomputes and records the new digest")
  func tofuDetectsOnDiskSwap() throws {
    let bundle = try makeTempBundle([(path: "model.bin", bytes: [1, 2, 3])])
    defer { try? FileManager.default.removeItem(at: bundle) }
    let registry = ModelRegistry()

    let first = try registry.register(
      url: bundle, metadata: ModelMetadata(identifier: "tofu-1"))

    // Swap the bytes on disk at the same URL.
    try Data([9, 8, 7, 6]).write(to: bundle.appendingPathComponent("model.bin"))
    let onDisk = try ModelRegistry.computeDigest(forModelAt: bundle)

    let second = try registry.register(
      url: bundle, metadata: ModelMetadata(identifier: "tofu-2"))

    #expect(second.digest != first.digest)
    #expect(second.digest == onDisk)
    #expect(registry.digestComputationCount == 2)
  }

  @Test("TOFU: a shrinking on-disk swap (fewer bytes) is detected")
  func tofuDetectsShrinkingSwap() throws {
    let bundle = try makeTempBundle([(path: "model.bin", bytes: [1, 2, 3, 4, 5])])
    defer { try? FileManager.default.removeItem(at: bundle) }
    let registry = ModelRegistry()

    let first = try registry.register(
      url: bundle, metadata: ModelMetadata(identifier: "shrink-1"))

    // Overwrite with fewer bytes — computeDigest binds content length.
    try Data([1, 2]).write(to: bundle.appendingPathComponent("model.bin"))
    let onDisk = try ModelRegistry.computeDigest(forModelAt: bundle)

    let second = try registry.register(
      url: bundle, metadata: ModelMetadata(identifier: "shrink-2"))

    #expect(second.digest != first.digest)
    #expect(second.digest == onDisk)
    #expect(registry.digestComputationCount == 2)
  }

  @Test("TOFU: a bundle-structure change (added file) between registers is detected")
  func tofuDetectsStructureChange() throws {
    let bundle = try makeTempBundle([(path: "model.bin", bytes: [1, 2, 3])])
    defer { try? FileManager.default.removeItem(at: bundle) }
    let registry = ModelRegistry()

    let first = try registry.register(
      url: bundle, metadata: ModelMetadata(identifier: "struct-1"))

    // Add a second file — same first file, different bundle layout.
    try Data([4, 5]).write(to: bundle.appendingPathComponent("extra.bin"))
    let onDisk = try ModelRegistry.computeDigest(forModelAt: bundle)

    let second = try registry.register(
      url: bundle, metadata: ModelMetadata(identifier: "struct-2"))

    #expect(second.digest != first.digest)
    #expect(second.digest == onDisk)
    #expect(registry.digestComputationCount == 2)
  }

  @Test("TOFU: a same-bytes rewrite recomputes (count increments) but yields an equal digest")
  func tofuSameBytesRewriteStillRecomputes() throws {
    let bundle = try makeTempBundle([(path: "model.bin", bytes: [1, 2, 3])])
    defer { try? FileManager.default.removeItem(at: bundle) }
    let registry = ModelRegistry()

    let first = try registry.register(
      url: bundle, metadata: ModelMetadata(identifier: "same-1"))

    // Rewrite with identical content — digest must match, but we re-hash
    // (proving we recompute rather than trust a cache).
    try Data([1, 2, 3]).write(to: bundle.appendingPathComponent("model.bin"))

    let second = try registry.register(
      url: bundle, metadata: ModelMetadata(identifier: "same-2"))

    #expect(second.digest == first.digest)
    #expect(registry.digestComputationCount == 2)
  }

  @Test("pinned: a swap-then-pin against a now-stale persisted digest throws .integrityCheckFailed")
  func pinnedAgainstStaleDigestAfterSwapThrows() throws {
    let bundle = try makeTempBundle([(path: "model.bin", bytes: [1, 2, 3])])
    defer { try? FileManager.default.removeItem(at: bundle) }
    let registry = ModelRegistry()

    // Persist the digest of the original bytes (the "future pin").
    let stalePin = try ModelRegistry.computeDigest(forModelAt: bundle)

    // Swap the bytes on disk.
    try Data([9, 8, 7, 6]).write(to: bundle.appendingPathComponent("model.bin"))
    let onDisk = try ModelRegistry.computeDigest(forModelAt: bundle)

    do {
      _ = try registry.register(
        url: bundle, expectedDigest: stalePin,
        metadata: ModelMetadata(identifier: "stale-pin"))
      Issue.record("expected .integrityCheckFailed, got success")
    } catch let ModelRegistryError.integrityCheckFailed(expected, actual) {
      #expect(expected == stalePin)
      #expect(actual == onDisk)
      #expect(actual != stalePin)
    } catch {
      Issue.record("expected .integrityCheckFailed, got \(error)")
    }
    #expect(registry.entries.isEmpty)
  }
}
