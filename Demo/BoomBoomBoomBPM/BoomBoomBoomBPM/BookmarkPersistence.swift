import Foundation
import OSLog
import Synchronization

/// Demo-only persistence for security-scoped bookmarks to user-added model
/// files, so a `URL` picked via the model file picker (Story 10.2) keeps
/// resolving after the demo quits and relaunches — without re-prompting.
///
/// Why the demo owns this: the library `ModelRegistry` is an ephemeral,
/// `Mutex`-guarded catalog that is re-registered on every launch and carries
/// no built-in `UUID`/`save`/`load`. So the *persistent* identity of a
/// user-added model is a demo-side construct — `BookmarkPersistence` mints a
/// stable `UUID`, owns the `{uuidString: bookmarkData}` map, and on launch
/// Story 10.2 resolves each bookmark → `URL` → `ModelRegistry.register(url:)`.
/// That is FR-38: the demo owns persistence for user-added models only, never
/// the library. (Story 10.1 DD2.)
///
/// `nonisolated` because the demo target defaults to `@MainActor` isolation
/// (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`); this is a pure helper over
/// `UserDefaults`, not a view model, so it opts out so off-actor unit tests and
/// launch-time callers (e.g. a background-`Task` launch resolve) can drive it.
///
/// A `final class` (not a value type) `@unchecked Sendable`-guarded by a
/// `Mutex`: `store` and `resolveAll` perform a compound read-modify-write of the
/// whole bookmark map, and `UserDefaults`' per-call thread-safety does NOT make
/// that compound transaction atomic — two concurrent mutators could each read
/// the same map and clobber the other's good bookmark. The `Mutex` makes every
/// map read-modify-write a single critical section, so the `Sendable` contract
/// is true rather than merely asserted. The lock wraps ONLY map access, never
/// the codec's bookmark file I/O (see `resolveAll`'s snapshot-classify-merge) —
/// so a re-entrant injected codec can't deadlock the non-recursive `Mutex`. `Mutex` is `~Copyable`, which forces the
/// reference-type shape — mirroring the library's `Mutex`-guarded
/// `ModelRegistry` (a struct + copyable lock would be easy to duplicate
/// accidentally). The lock guards a critical section, not a value, so the
/// thread-safe-but-not-`Sendable` `UserDefaults` handle stays a plain `let`
/// (never crossing the mutex's region boundary) and is touched only inside
/// `withLock`.
nonisolated final class BookmarkPersistence: @unchecked Sendable {

  /// Injectable seam over the real security-scoped bookmark codec.
  ///
  /// The default (`.live`) calls `URL.bookmarkData` / `URL(resolvingBookmarkData:)`
  /// with `.withSecurityScope`. Because a model is a read-only input, the
  /// create path also sets `.securityScopeAllowOnlyReadAccess` (least
  /// privilege — verified against Apple docs: only meaningful combined with
  /// `.withSecurityScope`). App-scoped bookmark → `relativeTo: nil`.
  ///
  /// Tests inject a fake that can force `isStale == true` and `throw`, so the
  /// store / resolve / stale-refresh / drop logic is exercised in an unsigned,
  /// non-sandboxed CI process where real `.withSecurityScope` creation is
  /// unreliable (Story 10.1 DD4).
  struct Codec: Sendable {
    var makeBookmark: @Sendable (URL) throws -> Data
    var resolveBookmark: @Sendable (Data) throws -> (url: URL, isStale: Bool)

    static let live = Codec(
      makeBookmark: { url in
        try url.bookmarkData(
          options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
      },
      resolveBookmark: { data in
        var isStale = false
        let url = try URL(
          resolvingBookmarkData: data,
          options: [.withSecurityScope],
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )
        return (url, isStale)
      }
    )
  }

  /// The per-entry resolution outcome — a small state machine that separates the
  /// *decision* (keep / refresh / drop) from the map mutation it drives, so
  /// `resolveAll` is a flat apply-the-outcome loop instead of nested
  /// `guard`/`do`/`catch`. Computed by the pure `classify(key:data:)`.
  private enum EntryOutcome {
    /// Resolved and current — hand the URL back, leave the stored data as-is.
    case keep(id: UUID, url: URL)
    /// Resolved but stale — re-persist `refreshed` under the same key, hand the
    /// URL back.
    case refresh(id: UUID, url: URL, refreshed: Data)
    /// Unresolvable (or a poisoned key) — drop from the map, emit `reason`.
    case drop(reason: String)
  }

  /// The single `UserDefaults` key holding the whole `{uuidString: Data}`
  /// bookmark map. `UserDefaults` has no prefix scan, so one enumerable,
  /// atomically-written dictionary is cleaner than per-UUID keys + a separate
  /// index (Story 10.1 DD5). The value is plist-native `[String: Data]` — no
  /// Keychain, no file-system sidecar, no JSON wrappers.
  static let bookmarksKey = "modelBookmarks"

  private static let logger = Logger(
    subsystem: "com.robbyt.BoomBoomBoomBPM",
    category: "BookmarkPersistence"
  )

  private let defaults: UserDefaults
  private let codec: Codec

  /// Sink for the labeled drop diagnostic (FR-44 discipline: a labeled
  /// `Reason:` string, never a bare value). Defaults to `os.Logger`; tests
  /// inject a capturing closure to assert the drop path fired.
  private let onDiagnostic: @Sendable (String) -> Void

  /// Critical section guarding the compound read-modify-write of the map. A
  /// `Mutex<Void>` (not `Mutex<UserDefaults>`) so the non-`Sendable` `defaults`
  /// handle is never vended across the mutex's region boundary.
  ///
  /// `static`, not per-instance: the shared resource is the process-global
  /// `bookmarksKey` in `UserDefaults`, so ALL instances over the same domain
  /// mutate the same map. A per-instance lock would leave two instances free to
  /// clobber each other; a single static lock makes the `@unchecked Sendable`
  /// safety hold regardless of how many instances exist. (It over-serializes
  /// instances over *different* suites — irrelevant for a demo whose one
  /// production domain is `.standard`.)
  private static let lock = Mutex(())

  init(
    defaults: UserDefaults,
    codec: Codec = .live,
    onDiagnostic: @escaping @Sendable (String) -> Void = { message in
      BookmarkPersistence.logger.error("\(message, privacy: .public)")
    }
  ) {
    self.defaults = defaults
    self.codec = codec
    self.onDiagnostic = onDiagnostic
  }

  // MARK: - Store

  /// Encode a security-scoped bookmark for `url`, persist it under a freshly
  /// minted stable `UUID`, and return that `UUID` — the demo-owned persistent
  /// identity for this user-added model (AC2). `throws` because bookmark
  /// creation can fail (an unreadable path, a revoked scope).
  @discardableResult
  func store(url: URL) throws -> UUID {
    // Bookmark creation (I/O) stays outside the lock; only the compound
    // read-modify-write of the shared map is the critical section.
    let data = try codec.makeBookmark(url)
    let id = UUID()
    Self.lock.withLock { _ in
      var map = bookmarkMap()
      map[id.uuidString] = data
      writeBookmarkMap(map)
    }
    return id
  }

  // MARK: - Resolve

  /// Resolve every stored bookmark on launch (AC3).
  ///
  /// - A bookmark that resolves with `bookmarkDataIsStale == true` is refreshed
  ///   in place: re-encoded from the resolved `URL` and re-persisted under the
  ///   same `UUID` (Apple's documented stale-bookmark contract).
  /// - A bookmark that fails to resolve is DROPPED from the persisted map with
  ///   the labeled diagnostic `Reason: bookmark-resolution-failed`; the user is
  ///   NOT prompted mid-launch.
  ///
  /// Returns only the entries that resolved, each with the security scope NOT
  /// yet started — the caller brackets its own read via
  /// `withSecurityScopedAccess(to:perform:)` (AC4).
  ///
  /// Locking discipline (snapshot-classify-merge): the lock wraps ONLY the map
  /// snapshot and the write-back merge — never the codec's resolve/refresh file
  /// I/O. So an injected codec (or `onDiagnostic` sink) that re-enters this
  /// instance can't deadlock on the non-recursive `Mutex`. The trade: `classify`
  /// can now run concurrently, so the injected codec must be thread-safe (the
  /// live codec is — `URL.bookmarkData` / `URL(resolvingBookmarkData:)` are).
  /// The merge applies each refresh/drop only when the current stored value
  /// still equals the snapshotted one (compare-and-swap), so a concurrent
  /// `resolveAll` that already refreshed a key is never clobbered by a stale
  /// drop, and a concurrent `store`'s brand-new UUID (absent from the snapshot)
  /// is untouched. Drop diagnostics are emitted after the lock releases.
  func resolveAll() -> [(id: UUID, url: URL)] {
    // (1) Snapshot under the lock; release before any codec / file I/O.
    let snapshot = Self.lock.withLock { _ in bookmarkMap() }
    guard !snapshot.isEmpty else { return [] }

    // (2) Classify every entry OUTSIDE the lock (all codec + security-scope I/O).
    var resolved: [(id: UUID, url: URL)] = []
    var refreshed: [String: Data] = [:]
    var dropped: [String] = []
    var droppedReasons: [String] = []
    for (key, data) in snapshot {
      switch classify(key: key, data: data) {
      case .keep(let id, let url):
        resolved.append((id: id, url: url))
      case .refresh(let id, let url, let refreshedData):
        refreshed[key] = refreshedData
        resolved.append((id: id, url: url))
      case .drop(let reason):
        dropped.append(key)
        droppedReasons.append(reason)
      }
    }

    // (3) Merge under the lock. Apply each outcome only if the current value
    // still matches the snapshot (compare-and-swap) — this defeats a stale drop
    // racing a concurrent refresh of the same key, and re-reading the current
    // map preserves any UUID a concurrent `store` added meanwhile. Writing the
    // filtered `bookmarkMap()` also prunes non-`Data` junk on any write-back.
    if !refreshed.isEmpty || !dropped.isEmpty {
      Self.lock.withLock { _ in
        var map = bookmarkMap()
        var changed = false
        for (key, data) in refreshed where map[key] == snapshot[key] {
          map[key] = data
          changed = true
        }
        for key in dropped where map[key] == snapshot[key] {
          map[key] = nil
          changed = true
        }
        if changed {
          writeBookmarkMap(map)
        }
      }
    }

    // Diagnostics after the lock releases (a re-entrant `onDiagnostic` can't
    // deadlock). Emitted per classified drop, independent of the CAS outcome —
    // the resolution genuinely failed for this launch even if a racing refresh
    // kept the key alive.
    for reason in droppedReasons {
      onDiagnostic(reason)
    }
    return resolved
  }

  /// Pure per-entry decision (no side effects, no map mutation): resolve `data`,
  /// classify the result into `EntryOutcome`. A non-UUID key or a resolve
  /// failure → `.drop`; a stale resolve that re-encodes → `.refresh`; a stale
  /// resolve whose re-encode itself fails keeps the still-resolvable URL and
  /// leaves the stale data to retry next launch (→ `.keep`).
  private func classify(key: String, data: Data) -> EntryOutcome {
    guard let id = UUID(uuidString: key) else {
      // A non-UUID key can only arrive from a corrupted/poisoned domain; drop
      // it so the map self-heals (mirrors the AnalysisViewModel
      // present-but-unusable self-heal discipline).
      return .drop(reason: "Reason: bookmark-resolution-failed (invalid key)")
    }
    do {
      let (url, isStale) = try codec.resolveBookmark(data)
      guard isStale else { return .keep(id: id, url: url) }
      // Re-encode from the resolved URL under active scope. If the re-encode
      // throws, keep the resolvable URL and leave the stale data to retry.
      guard
        let refreshed = try? withSecurityScopedAccess(
          to: url,
          perform: { try codec.makeBookmark(url) }
        )
      else {
        return .keep(id: id, url: url)
      }
      return .refresh(id: id, url: url, refreshed: refreshed)
    } catch {
      // Log the raw error PRIVATELY so an operator can tell an unmounted volume
      // from a deleted file from a sandbox denial. It is NOT folded into the
      // public `Reason:` string because a resolution error can carry a file
      // path / NSError.userInfo, and the default `onDiagnostic` sink logs at
      // `privacy: .public`; the public reason stays labeled and path-free.
      Self.logger.debug(
        "bookmark-resolution-failed (id \(id.uuidString, privacy: .public)): \(String(describing: error), privacy: .private)"
      )
      return .drop(reason: "Reason: bookmark-resolution-failed (id \(id.uuidString))")
    }
  }

  // MARK: - Access bracket

  /// Bracket a read of a resolved security-scoped `URL` (AC4).
  ///
  /// `resolveAll()` hands back URLs with the scope NOT started; every file read
  /// MUST be wrapped here so the start/stop pair can never be unbalanced. A
  /// leaked scope exhausts the process's sandbox extensions until relaunch
  /// (Apple docs). `stop` is issued iff `start` returned `true` (Story 10.1
  /// DD3). Resolving does NOT implicitly start access for a security-scoped
  /// bookmark (`withoutImplicitStartAccessing` is documented as "not applicable
  /// to security-scoped bookmarks"), so this explicit bracket is mandatory.
  func withSecurityScopedAccess<T>(
    to url: URL,
    perform body: () throws -> T
  ) rethrows -> T {
    let started = url.startAccessingSecurityScopedResource()
    defer { if started { url.stopAccessingSecurityScopedResource() } }
    return try body()
  }

  // MARK: - Map storage (call only while holding `lock`)

  /// Read the persisted map defensively: a non-`Data` value (a poisoned domain)
  /// is filtered out of the returned view rather than nulling the whole cast, so
  /// one bad entry can't discard every good bookmark. Filtering affects only the
  /// in-memory view; a poisoned value is pruned from disk on the next
  /// write-back.
  private func bookmarkMap() -> [String: Data] {
    guard let raw = defaults.dictionary(forKey: Self.bookmarksKey) else {
      return [:]
    }
    return raw.compactMapValues { $0 as? Data }
  }

  private func writeBookmarkMap(_ map: [String: Data]) {
    if map.isEmpty {
      defaults.removeObject(forKey: Self.bookmarksKey)
    } else {
      defaults.set(map, forKey: Self.bookmarksKey)
    }
  }
}
