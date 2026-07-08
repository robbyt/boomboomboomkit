import Foundation
import Testing

@testable import BoomBoomBoomBPM

// Pure-logic tests over `BookmarkPersistence`'s injected `Codec` seam. No real
// security scope is exercised (`.withSecurityScope` creation is unreliable in an
// unsigned, non-sandboxed CI process — Story 10.1 DD4), so store / resolveAll /
// stale-refresh / drop are driven through a fake codec that can force `isStale`
// and `throw`. The entitlement-is-load-bearing proof is the operator-run AC6
// step under `make demo-build-sandboxed`, not a `swift test` assertion.
//
// Each test uses a unique `UserDefaults(suiteName:)` cleaned up via
// `removePersistentDomain(forName:)` so cases run independently, in parallel,
// without contaminating each other or the operator's `.standard` prefs — the
// Story 5-6 `MergeStrategyPersistenceTests` isolation pattern.
@Suite("Bookmark persistence")
struct BookmarkPersistenceTests {

  // Thread-safe capture for the labeled drop diagnostic. `onDiagnostic` is
  // `@Sendable`, so the sink must be Sendable; the lock keeps it honest even
  // though `resolveAll()` runs synchronously on one thread.
  private final class DiagnosticCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [String] = []
    func record(_ message: String) {
      lock.lock()
      defer { lock.unlock() }
      messages.append(message)
    }
    var all: [String] {
      lock.lock()
      defer { lock.unlock() }
      return messages
    }
  }

  // A fake codec that encodes a URL's absoluteString as its "bookmark" and
  // decodes it back. Never stale, never throws — the happy-path seam.
  private static func roundTripCodec() -> BookmarkPersistence.Codec {
    BookmarkPersistence.Codec(
      makeBookmark: { url in Data(url.absoluteString.utf8) },
      resolveBookmark: { data in
        let string = String(decoding: data, as: UTF8.self)
        return (URL(string: string)!, false)
      }
    )
  }

  private func storedMap(_ defaults: UserDefaults) -> [String: Data] {
    (defaults.dictionary(forKey: BookmarkPersistence.bookmarksKey) as? [String: Data]) ?? [:]
  }

  // (1) store → resolveAll round-trips the URL under a stable UUID.
  @Test("store then resolveAll round-trips the URL under a stable UUID")
  func storeResolveRoundTrip() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.bookmark.roundtrip"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let url = URL(fileURLWithPath: "/tmp/model.mlmodelc")
    let persistence = BookmarkPersistence(defaults: defaults, codec: Self.roundTripCodec())

    let id = try persistence.store(url: url)
    #expect(storedMap(defaults).count == 1)
    #expect(storedMap(defaults)[id.uuidString] != nil)

    let resolved = persistence.resolveAll()
    #expect(resolved.count == 1)
    #expect(resolved.first?.id == id)
    #expect(resolved.first?.url.absoluteString == url.absoluteString)
  }

  // (2) A stale resolve refreshes + re-persists the bookmark under the same UUID.
  @Test("stale resolve re-encodes and re-persists under the same UUID")
  func staleRefreshRepersists() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.bookmark.stale"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let url = URL(fileURLWithPath: "/tmp/model.mlmodelc")
    let staleData = Data("stale-bookmark".utf8)
    let freshData = Data("fresh-bookmark".utf8)

    // Fake: the stale blob resolves stale; re-encode yields the fresh blob.
    let codec = BookmarkPersistence.Codec(
      makeBookmark: { _ in freshData },
      resolveBookmark: { data in (url, data == staleData) }
    )

    let id = UUID()
    defaults.set([id.uuidString: staleData], forKey: BookmarkPersistence.bookmarksKey)

    let persistence = BookmarkPersistence(defaults: defaults, codec: codec)
    let resolved = persistence.resolveAll()

    #expect(resolved.count == 1)
    #expect(resolved.first?.url.path == url.path)
    // The stored Data changed from the stale blob to the freshly re-encoded one.
    #expect(storedMap(defaults)[id.uuidString] == freshData)
  }

  // (3) A resolve failure drops that entry, prunes the map, keeps siblings, and
  // emits the labeled diagnostic — without prompting.
  @Test("resolve failure drops the entry, prunes the map, keeps siblings")
  func resolveFailureDropsAndPrunes() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.bookmark.drop"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    struct ResolveFailure: Error {}
    let goodData = Data("good-bookmark".utf8)
    let badData = Data("bad-bookmark".utf8)
    let goodURL = URL(fileURLWithPath: "/tmp/good.mlmodelc")

    let codec = BookmarkPersistence.Codec(
      makeBookmark: { _ in goodData },
      resolveBookmark: { data in
        if data == badData { throw ResolveFailure() }
        return (goodURL, false)
      }
    )

    let goodID = UUID()
    let badID = UUID()
    defaults.set(
      [goodID.uuidString: goodData, badID.uuidString: badData],
      forKey: BookmarkPersistence.bookmarksKey
    )

    let capture = DiagnosticCapture()
    let persistence = BookmarkPersistence(
      defaults: defaults,
      codec: codec,
      onDiagnostic: { capture.record($0) }
    )

    let resolved = persistence.resolveAll()

    // Only the good entry resolves.
    #expect(resolved.count == 1)
    #expect(resolved.first?.id == goodID)
    // The bad key is pruned; the good sibling survives.
    let map = storedMap(defaults)
    #expect(map[badID.uuidString] == nil)
    #expect(map[goodID.uuidString] == goodData)
    // The labeled diagnostic fired (FR-44: labeled, never a bare value).
    #expect(capture.all.contains { $0.hasPrefix("Reason: bookmark-resolution-failed") })
  }

  // (4) An absent map resolves to an empty array (no precondition crash).
  @Test("absent map resolves to an empty array")
  func absentMapResolvesEmpty() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.bookmark.empty"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let persistence = BookmarkPersistence(defaults: defaults, codec: Self.roundTripCodec())
    #expect(persistence.resolveAll().isEmpty)
  }

  // (5) The access bracket runs the body and propagates its value / errors.
  // A plain file URL is not a real security-scoped resource, so
  // `startAccessingSecurityScopedResource()` returns `false` and `stop` is
  // (correctly) never called — the true-return balancing is proven by the
  // operator-run AC6 sandbox step, not fakeable in CI (DD4).
  @Test("withSecurityScopedAccess runs the body and propagates value and errors")
  func accessBracketRunsAndPropagates() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.bookmark.bracket"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let persistence = BookmarkPersistence(defaults: defaults)
    let url = URL(fileURLWithPath: NSTemporaryDirectory())

    var ran = false
    let result = persistence.withSecurityScopedAccess(to: url) {
      ran = true
      return 42
    }
    #expect(ran)
    #expect(result == 42)

    struct BodyError: Error {}
    #expect(throws: BodyError.self) {
      try persistence.withSecurityScopedAccess(to: url) { throw BodyError() }
    }
  }

  // (6) A non-UUID (poisoned) key is dropped and self-heals the map.
  @Test("non-UUID key is dropped and the map self-heals")
  func nonUUIDKeySelfHeals() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.bookmark.poisonkey"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let goodData = Data("good-bookmark".utf8)
    let goodURL = URL(fileURLWithPath: "/tmp/good.mlmodelc")
    let goodID = UUID()

    let codec = BookmarkPersistence.Codec(
      makeBookmark: { _ in goodData },
      resolveBookmark: { _ in (goodURL, false) }
    )
    defaults.set(
      ["not-a-uuid": goodData, goodID.uuidString: goodData],
      forKey: BookmarkPersistence.bookmarksKey
    )

    let persistence = BookmarkPersistence(defaults: defaults, codec: codec)
    let resolved = persistence.resolveAll()

    #expect(resolved.count == 1)
    #expect(resolved.first?.id == goodID)
    let map = storedMap(defaults)
    #expect(map["not-a-uuid"] == nil)
    #expect(map[goodID.uuidString] == goodData)
  }

  // (7) Concurrent stores don't lose entries — the Mutex makes the map's
  // read-modify-write a real critical section. Without it, `UserDefaults`'
  // per-call thread-safety would still let two stores read the same map and
  // clobber each other's UUID (the race Codex flagged). Each store mints a
  // distinct UUID, so `count == iterations` iff no update was lost.
  @Test("concurrent stores preserve every entry (no lost updates)")
  func concurrentStoresDoNotLoseEntries() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.bookmark.concurrent"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let persistence = BookmarkPersistence(defaults: defaults, codec: Self.roundTripCodec())
    let iterations = 50

    DispatchQueue.concurrentPerform(iterations: iterations) { index in
      _ = try? persistence.store(url: URL(fileURLWithPath: "/tmp/model-\(index).mlmodelc"))
    }

    #expect(storedMap(defaults).count == iterations)
    #expect(persistence.resolveAll().count == iterations)
  }

  // (8) resolveAll() running concurrently with stores loses no entry — the
  // review refactor moved codec I/O out of the lock and merges each outcome via
  // compare-and-swap against the snapshot, so a concurrent store()'s brand-new
  // UUID (absent from resolveAll's snapshot) is never clobbered by the merge
  // write-back. Seeds K, then races N stores against interleaved resolveAll
  // calls; the final map must hold exactly K + N entries.
  @Test("resolveAll racing concurrent stores loses no entry")
  func concurrentResolveDuringStoresLosesNothing() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.bookmark.concurrentResolve"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let persistence = BookmarkPersistence(defaults: defaults, codec: Self.roundTripCodec())

    let seeded = 10
    for i in 0..<seeded {
      _ = try persistence.store(url: URL(fileURLWithPath: "/tmp/seed-\(i).mlmodelc"))
    }

    let newStores = 40
    let resolvers = 10
    DispatchQueue.concurrentPerform(iterations: newStores + resolvers) { index in
      if index < newStores {
        _ = try? persistence.store(url: URL(fileURLWithPath: "/tmp/new-\(index).mlmodelc"))
      } else {
        // Races the stores' read-modify-write via the snapshot-classify-merge path.
        _ = persistence.resolveAll()
      }
    }

    #expect(storedMap(defaults).count == seeded + newStores)
    #expect(persistence.resolveAll().count == seeded + newStores)
  }
}
