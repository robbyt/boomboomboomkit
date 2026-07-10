import BoomBoomBoomKit
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// CI tests over `ModelCatalog`'s CI-testable logic — restore, dedup, empty-state,
// transactional add, URL-keyed identity/selection, source derivation. The
// terminal `BNNSTechnique(modelURL:)` load (macOS 15 + a real compiled model) and
// the SwiftUI picker view are operator/GUI-tested, as in 10.1 AC6.
//
// The `BookmarkPersistence` fake `Codec` seam is injected so `resolveBookmark`
// hands back URLs the test controls; `register`'s pass/fail is driven by a real
// on-disk temp fixture (a directory bundle registers, a plain file throws
// `unsupportedFormat`). Each test uses a unique `UserDefaults(suiteName:)` cleaned
// up via `removePersistentDomain(forName:)` (the Story 5-6 / 10.1 isolation
// pattern). `@MainActor` because `ModelCatalog` is `@MainActor @Observable`.
@MainActor
@Suite("Model catalog")
struct ModelCatalogTests {

  // MARK: - Fixtures

  // A real on-disk `.mlmodelc` directory bundle with one regular file, so the
  // library `register` (which hashes directory bundles) succeeds. Each call
  // makes a unique parent dir so same-named bundles can live in different dirs.
  private func makeBundle(named name: String = "model") throws -> URL {
    let parent = FileManager.default.temporaryDirectory
      .appendingPathComponent("ModelCatalogTests-\(UUID().uuidString)", isDirectory: true)
    let bundle = parent.appendingPathComponent("\(name).mlmodelc", isDirectory: true)
    try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: true)
    try Data("coreml-weights".utf8).write(to: bundle.appendingPathComponent("coremldata.bin"))
    return bundle
  }

  // A plain (non-directory) file, so `register` throws `unsupportedFormat` — the
  // register-failure injection.
  private func makePlainFile() throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("\(UUID().uuidString).mlmodelc")
    try Data("not-a-bundle".utf8).write(to: url)
    return url
  }

  // Round-trip codec: encodes a URL's absoluteString as its bookmark and decodes
  // it back. Never stale, never throws — the happy-path seam (mirrors
  // BookmarkPersistenceTests).
  private func roundTripCodec() -> BookmarkPersistence.Codec {
    BookmarkPersistence.Codec(
      makeBookmark: { url in Data(url.absoluteString.utf8) },
      resolveBookmark: { data in (URL(string: String(decoding: data, as: UTF8.self))!, false) }
    )
  }

  private func storedMap(_ defaults: UserDefaults) -> [String: Data] {
    (defaults.dictionary(forKey: BookmarkPersistence.bookmarksKey) as? [String: Data]) ?? [:]
  }

  private func makeDefaults(_ suffix: String) throws -> (UserDefaults, String) {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.catalog.\(suffix)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    return (defaults, suiteName)
  }

  // MARK: - Restore

  // (1) restore-on-init populates entries from resolveAll().
  @Test("restore on init registers a persisted model as .userAdded")
  func restorePopulatesEntries() throws {
    let (defaults, suiteName) = try makeDefaults("restore")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let bundle = try makeBundle()
    let persistence = BookmarkPersistence(defaults: defaults, codec: roundTripCodec())
    _ = try persistence.store(url: bundle)

    let catalog = ModelCatalog(bookmarks: persistence)

    #expect(catalog.entries.count == 1)
    #expect(!catalog.isEmpty)
    let entry = try #require(catalog.entries.first)
    #expect(entry.url.standardizedFileURL == bundle.standardizedFileURL)
    #expect(catalog.source(for: entry.url) == .userAdded)
  }

  // (2) restore dedups duplicate resolved URLs to one row (W79).
  @Test("restore dedups duplicate resolved URLs to one row")
  func restoreDedupsDuplicateURLs() throws {
    let (defaults, suiteName) = try makeDefaults("restoreDedup")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let bundle = try makeBundle()
    let persistence = BookmarkPersistence(defaults: defaults, codec: roundTripCodec())
    // Two distinct UUIDs, same URL — resolveAll() returns both (W79).
    _ = try persistence.store(url: bundle)
    _ = try persistence.store(url: bundle)
    #expect(storedMap(defaults).count == 2)

    let catalog = ModelCatalog(bookmarks: persistence)
    #expect(catalog.entries.count == 1)
  }

  // (3) restore skips an entry whose register throws, keeps the others, and emits
  // the labeled diagnostic (DD8).
  @Test("restore skips an unhashable entry and keeps the good one")
  func restoreSkipsRegisterFailure() throws {
    let (defaults, suiteName) = try makeDefaults("restoreSkip")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let goodBundle = try makeBundle()
    let badFile = try makePlainFile()  // register throws unsupportedFormat
    let persistence = BookmarkPersistence(defaults: defaults, codec: roundTripCodec())
    _ = try persistence.store(url: goodBundle)
    _ = try persistence.store(url: badFile)

    let catalog = ModelCatalog(bookmarks: persistence)

    #expect(catalog.entries.count == 1)
    #expect(catalog.entries.first?.url.standardizedFileURL == goodBundle.standardizedFileURL)
    #expect(catalog.restoreDiagnostics.contains("Reason: restored-model-unavailable"))
  }

  // MARK: - Add from disk

  // (4) addFromDisk dedups a re-added URL — one entry, labeled reject (W79).
  @Test("addFromDisk dedups a re-added URL with a labeled reject")
  func addFromDiskDedups() throws {
    let (defaults, suiteName) = try makeDefaults("addDedup")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let bundle = try makeBundle()
    let persistence = BookmarkPersistence(defaults: defaults, codec: roundTripCodec())
    let catalog = ModelCatalog(bookmarks: persistence)

    #expect(catalog.addFromDisk(url: bundle).isSuccess)
    let second = catalog.addFromDisk(url: bundle)
    #expect(second.failure == .alreadyAdded)
    #expect(catalog.addFromDisk(url: bundle).failure?.reason == "Reason: model-already-added")
    #expect(catalog.entries.count == 1)
  }

  // (5) addFromDisk register-failure leaves NO persisted bookmark (transactional
  // rollback, DD8 — register FIRST, store only on success).
  @Test("addFromDisk register-failure persists no bookmark")
  func addFromDiskRegisterFailureRollback() throws {
    let (defaults, suiteName) = try makeDefaults("addRollback")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let badFile = try makePlainFile()
    let persistence = BookmarkPersistence(defaults: defaults, codec: roundTripCodec())
    let catalog = ModelCatalog(bookmarks: persistence)

    let result = catalog.addFromDisk(url: badFile)
    #expect(result.failure == .registerFailed)
    #expect(result.failure?.reason == "Reason: model-register-failed")
    #expect(catalog.entries.isEmpty)
    // The bookmark was NEVER stored — register threw before store ran.
    #expect(storedMap(defaults).isEmpty)
  }

  // (6) Two same-named `.mlmodelc` in different dirs yield two distinct URL-keyed
  // rows and `select` resolves the correct URL (DD7 collision guard).
  @Test("same-named bundles in different dirs are distinct URL-keyed rows")
  func sameNameDifferentDirCollision() throws {
    let (defaults, suiteName) = try makeDefaults("collision")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let bundleA = try makeBundle(named: "model")
    let bundleB = try makeBundle(named: "model")
    #expect(bundleA.standardizedFileURL != bundleB.standardizedFileURL)

    let persistence = BookmarkPersistence(defaults: defaults, codec: roundTripCodec())
    let catalog = ModelCatalog(bookmarks: persistence)
    #expect(catalog.addFromDisk(url: bundleA).isSuccess)
    #expect(catalog.addFromDisk(url: bundleB).isSuccess)

    // Two rows despite identical filename-derived identifiers.
    #expect(catalog.entries.count == 2)
    #expect(catalog.entries.allSatisfy { $0.identifier == "model" })

    // select resolves the correct URL, and only that entry is marked selected.
    let resolved = catalog.select(url: bundleB)
    #expect(resolved?.standardizedFileURL == bundleB.standardizedFileURL)
    #expect(catalog.selectedURL?.standardizedFileURL == bundleB.standardizedFileURL)
    let entryB = try #require(
      catalog.entries.first { $0.url.standardizedFileURL == bundleB.standardizedFileURL })
    let entryA = try #require(
      catalog.entries.first { $0.url.standardizedFileURL == bundleA.standardizedFileURL })
    #expect(catalog.isSelected(entryB))
    #expect(!catalog.isSelected(entryA))
  }

  // MARK: - Empty / select / source

  // (7) empty catalog reports isEmpty.
  @Test("fresh catalog with no persisted models is empty")
  func emptyCatalog() throws {
    let (defaults, suiteName) = try makeDefaults("empty")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let persistence = BookmarkPersistence(defaults: defaults, codec: roundTripCodec())
    let catalog = ModelCatalog(bookmarks: persistence)
    #expect(catalog.isEmpty)
    #expect(catalog.entries.isEmpty)
  }

  // (8) select(url:) returns the resolved URL and sets selectedURL; a URL not in
  // the catalog returns nil.
  @Test("select returns the resolved URL and sets selectedURL")
  func selectReturnsURL() throws {
    let (defaults, suiteName) = try makeDefaults("select")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let bundle = try makeBundle()
    let persistence = BookmarkPersistence(defaults: defaults, codec: roundTripCodec())
    let catalog = ModelCatalog(bookmarks: persistence)
    #expect(catalog.addFromDisk(url: bundle).isSuccess)
    #expect(catalog.selectedURL == nil)

    let resolved = catalog.select(url: bundle)
    #expect(resolved?.standardizedFileURL == bundle.standardizedFileURL)
    #expect(catalog.selectedURL?.standardizedFileURL == bundle.standardizedFileURL)

    // A URL not in the catalog resolves to nil and does not change selection.
    let absent = FileManager.default.temporaryDirectory
      .appendingPathComponent("absent.mlmodelc", isDirectory: true)
    #expect(catalog.select(url: absent) == nil)
    #expect(catalog.selectedURL?.standardizedFileURL == bundle.standardizedFileURL)
  }

  // (9) source tag is .userAdded; integrity label is the honest TOFU "recorded".
  @Test("added model is tagged .userAdded with a recorded integrity label")
  func sourceAndIntegrityTags() throws {
    let (defaults, suiteName) = try makeDefaults("source")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let bundle = try makeBundle()
    let persistence = BookmarkPersistence(defaults: defaults, codec: roundTripCodec())
    let catalog = ModelCatalog(bookmarks: persistence)
    #expect(catalog.addFromDisk(url: bundle).isSuccess)

    let entry = try #require(catalog.entries.first)
    #expect(catalog.source(for: entry.url) == .userAdded)
    #expect(catalog.source(for: entry.url).display == "User-added")
    #expect(catalog.integrityLabel(for: entry).hasPrefix("Integrity: recorded "))
  }

  // (10) clearSelection nils the in-use mark — the FR-44 honesty fix for a failed
  // "Use this model" (a load failure clears the technique, so no row may claim
  // Selected: yes).
  @Test("clearSelection clears the in-use mark")
  func clearSelectionClearsMark() throws {
    let (defaults, suiteName) = try makeDefaults("clearSel")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let bundle = try makeBundle()
    let persistence = BookmarkPersistence(defaults: defaults, codec: roundTripCodec())
    let catalog = ModelCatalog(bookmarks: persistence)
    #expect(catalog.addFromDisk(url: bundle).isSuccess)
    _ = catalog.select(url: bundle)
    #expect(catalog.selectedURL != nil)

    catalog.clearSelection()
    #expect(catalog.selectedURL == nil)
  }

  // (11) A store-failure AFTER a successful register leaves NO ghost row and NO
  // persisted bookmark, and the add can be retried cleanly (the mirror is
  // appended only after BOTH register and store commit — DD8 / review patch).
  @Test("addFromDisk store-failure leaves no ghost row and allows retry")
  func addFromDiskStoreFailureNoGhostRow() throws {
    let (defaults, suiteName) = try makeDefaults("storeFail")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let bundle = try makeBundle()
    // makeBookmark throws on the first call (store fails after register succeeds),
    // then succeeds — so the retry must go through cleanly.
    nonisolated(unsafe) var failNextStore = true
    let codec = BookmarkPersistence.Codec(
      makeBookmark: { url in
        if failNextStore {
          failNextStore = false
          throw CocoaError(.fileWriteUnknown)
        }
        return Data(url.absoluteString.utf8)
      },
      resolveBookmark: { data in (URL(string: String(decoding: data, as: UTF8.self))!, false) }
    )
    let persistence = BookmarkPersistence(defaults: defaults, codec: codec)
    let catalog = ModelCatalog(bookmarks: persistence)

    // First add: register OK, store throws -> persistFailed, no row, no bookmark.
    let first = catalog.addFromDisk(url: bundle)
    #expect(first.failure == .persistFailed)
    #expect(first.failure?.reason == "Reason: model-persist-failed")
    #expect(catalog.entries.isEmpty)
    #expect(storedMap(defaults).isEmpty)

    // Retry: store now succeeds -> exactly one row + one persisted bookmark.
    #expect(catalog.addFromDisk(url: bundle).isSuccess)
    #expect(catalog.entries.count == 1)
    #expect(storedMap(defaults).count == 1)
  }
}

// Small `Result` conveniences for the assertions above. `Result<Void, AddError>`
// is NOT `Equatable` (Void isn't), so success/failure are inspected structurally.
extension Result {
  fileprivate var isSuccess: Bool {
    if case .success = self { return true }
    return false
  }
  fileprivate var failure: Failure? {
    if case .failure(let error) = self { return error }
    return nil
  }
}
